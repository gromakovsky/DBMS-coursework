-- Entities

CREATE TABLE IF NOT EXISTS Nodes
(
    node_id         bigint              PRIMARY KEY,
    version         int                 NOT NULL DEFAULT 1,
    latitude        double precision    NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude       double precision    NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    timestamp       timestamp           NOT NULL DEFAULT CURRENT_TIMESTAMP,

    user_id         int                 NOT NULL
);

CREATE TABLE IF NOT EXISTS Ways
(
    way_id          bigint              PRIMARY KEY,
    version         int                 NOT NULL DEFAULT 1,
    timestamp       timestamp           NOT NULL DEFAULT CURRENT_TIMESTAMP,

    user_id         int                 NOT NULL,
    node_id         bigint              NOT NULL,
    node_index      int                 NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Relations
(
    relation_id     bigint              PRIMARY KEY,
    version         int                 NOT NULL DEFAULT 1,
    timestamp       timestamp           NOT NULL DEFAULT CURRENT_TIMESTAMP,

    user_id         int                 NOT NULL
);

CREATE TABLE IF NOT EXISTS Tags
(
    tag_key         text                PRIMARY KEY,
    introduced_date date                NOT NULL DEFAULT CURRENT_DATE,
    description     text                ,

    introduced_by   int                 NOT NULL
);

CREATE TABLE IF NOT EXISTS Users
(
    user_id         int                 PRIMARY KEY,
    user_name       text                NOT NULL,
    email           text                NOT NULL,
    password_hash   text                NOT NULL,
    status          text                NOT NULL,
    information     text
);

-- Relationships

ALTER TABLE Nodes ADD FOREIGN KEY(user_id) REFERENCES Users(user_id);
ALTER TABLE Ways ADD FOREIGN KEY(user_id) REFERENCES Users(user_id);
ALTER TABLE Relations  ADD FOREIGN KEY(user_id) REFERENCES Users(user_id);
ALTER TABLE Tags  ADD FOREIGN KEY(introduced_by) REFERENCES Users(user_id);

-- Associations

CREATE TABLE IF NOT EXISTS NodesInRelations
(
    role            text                NOT NULL,

    node_id         bigint              NOT NULL REFERENCES Nodes(node_id),
    relation_id     bigint              NOT NULL REFERENCES Relations(relation_id),

    UNIQUE(node_id, relation_id)
);

CREATE TABLE IF NOT EXISTS NodesInWays
(
    node_index      int                 NOT NULL,

    node_id         bigint              NOT NULL REFERENCES Nodes(node_id),
    way_id          bigint              NOT NULL REFERENCES Ways(way_id),

    UNIQUE(node_index, node_id, way_id)
);

ALTER TABLE Ways ADD FOREIGN KEY(node_id, way_id, node_index) REFERENCES NodesInWays(node_id, way_id, node_index) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE IF NOT EXISTS WaysInRelations
(
    role            text                NOT NULL,

    way_id          bigint              NOT NULL REFERENCES Ways(way_id),
    relation_id     bigint              NOT NULL REFERENCES Relations(relation_id),

    UNIQUE(way_id, relation_id)
);

CREATE TABLE IF NOT EXISTS NodeTags
(
    tag_value       text                NOT NULL,

    node_id         bigint              NOT NULL REFERENCES Nodes(node_id),
    tag_key         text                NOT NULL REFERENCES Tags(tag_key),

    UNIQUE(node_id, tag_key)
);

CREATE TABLE IF NOT EXISTS WayTags
(
    tag_value       text                NOT NULL,

    way_id          bigint              NOT NULL REFERENCES Ways(way_id),
    tag_key         text                NOT NULL REFERENCES Tags(tag_key),

    UNIQUE(way_id, tag_key)
);

CREATE TABLE IF NOT EXISTS RelationTags
(
    tag_value       text                NOT NULL,

    relation_id     bigint              NOT NULL REFERENCES Relations(relation_id),
    tag_key         text                NOT NULL REFERENCES Tags(tag_key),

    UNIQUE(relation_id, tag_key)
);

-- Useful functions
CREATE OR REPLACE FUNCTION relation_size(id relations.relation_id%TYPE) RETURNS int AS
$relation_size_definition$
DECLARE
    nodes_count int;
    ways_count int;
BEGIN
    SELECT count(*) FROM NodesInRelations WHERE relation_id = id
        INTO nodes_count;
    SELECT count(*) FROM WaysInRelations WHERE relation_id = id
        INTO ways_count;
    RETURN nodes_count + ways_count;
END;
$relation_size_definition$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_user(id Users.user_id%TYPE, name Users.user_name%TYPE, email Users.email%TYPE, password_hash Users.password_hash%TYPE) RETURNS void AS
$add_user_definition$
BEGIN
    IF NOT EXISTS(SELECT * FROM Users WHERE Users.user_id = id) THEN
        INSERT INTO Users (user_id, user_name, email, password_hash, status) VALUES (id, name, email, password_hash, 'User');
    END IF;
END;
$add_user_definition$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_tag(tag_key Tags.tag_key%TYPE, user_id Users.user_id%TYPE) RETURNS void AS
$add_tag_definition$
BEGIN
    IF NOT EXISTS(SELECT * FROM Tags WHERE Tags.tag_key = add_tag.tag_key) THEN
        INSERT INTO Tags (tag_key, introduced_by) VALUES (tag_key, user_id);
    END IF;
END;
$add_tag_definition$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION way_coordinates(id Ways.way_id%TYPE) RETURNS TABLE(lat Nodes.latitude%TYPE, lon Nodes.longitude%TYPE) AS
$way_coordinates_definition$
BEGIN
    RETURN QUERY SELECT latitude, longitude from Ways INNER JOIN NodesInWays USING (way_id)
                                                 INNER JOIN Nodes ON (NodesInWays.node_id = Nodes.node_id)
                                                 WHERE Ways.way_id = id
                                                 ORDER BY node_index;
    RETURN;
END;
$way_coordinates_definition$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION change_node_coordinates(id Nodes.node_id%TYPE, lat Nodes.latitude%TYPE, lon Nodes.longitude%TYPE) RETURNS void AS
$change_node_coordinates_definiton$
DECLARE
    old Nodes%ROWTYPE;
BEGIN
    UPDATE Nodes SET version = version + 1, latitude = lat, longitude = lon, timestamp = CURRENT_TIMESTAMP WHERE node_id = id;
END;
$change_node_coordinates_definiton$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tag_values(tag_key Tags.tag_key%TYPE) RETURNS SETOF NodeTags.tag_value%TYPE AS
$tag_values_definition$
DECLARE
BEGIN
    RETURN QUERY SELECT tag_value FROM NodeTags WHERE NodeTags.tag_key = tag_values.tag_key
           UNION SELECT tag_value FROM WayTags WHERE WayTags.tag_key = tag_values.tag_key
           UNION SELECT tag_value FROM RelationTags WHERE RelationTags.tag_key = tag_values.tag_key;
    RETURN;
END;
$tag_values_definition$
LANGUAGE plpgsql;

-- Other constraints

-- 1. Relation contains at least two elements
CREATE OR REPLACE FUNCTION check_relation_content() RETURNS trigger AS
$check_relation_content_definition$
DECLARE
    count int;
BEGIN
    count := relation_size(NEW.relation_id);
    IF count < 2 THEN
        RAISE EXCEPTION 'Added relation (%) must contain at least two elements', NEW.relation_id;
    END IF;
    RETURN NEW;
END;
$check_relation_content_definition$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_relation_content_trigger AFTER INSERT OR UPDATE ON Relations
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE check_relation_content();

-- It's impossible to modify node_id or way_id if it is referenced
-- But it is possible to delete from NodesInRelations or WaysInRelations, so let's add triggers

CREATE OR REPLACE FUNCTION check_erasing_from_relation() RETURNS trigger AS
$check_erasing_node_from_relation_definition$
DECLARE
    count int;
BEGIN
    count := relation_size(OLD.relation_id);
    IF count < 2 THEN
        RAISE EXCEPTION 'At least two elements must be left in relation';
    END IF;
    RETURN NEW;
END;
$check_erasing_node_from_relation_definition$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_erasing_node_from_relation_trigger AFTER DELETE OR UPDATE ON NodesInRelations
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE check_erasing_from_relation();

CREATE CONSTRAINT TRIGGER check_erasing_way_from_relation_trigger AFTER DELETE OR UPDATE ON WaysInRelations
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE check_erasing_from_relation();

-- 2. Update of every primitive must increment it's timestamp and version
CREATE OR REPLACE FUNCTION check_timestamp_and_version() RETURNS trigger AS
$check_timestamp_and_version_definition$
BEGIN
    IF OLD.version >= NEW.version OR OLD.timestamp >= NEW.timestamp THEN
        RAISE EXCEPTION 'Update must increment version and timestamp';
    END IF;
    RETURN NEW;
END;
$check_timestamp_and_version_definition$
LANGUAGE plpgsql;

CREATE TRIGGER check_node_timestamp_and_version_trigger BEFORE UPDATE ON Nodes
    FOR EACH ROW EXECUTE PROCEDURE check_timestamp_and_version();

CREATE TRIGGER check_way_timestamp_and_version_trigger BEFORE UPDATE ON Ways
    FOR EACH ROW EXECUTE PROCEDURE check_timestamp_and_version();

CREATE TRIGGER check_relation_timestamp_and_version_trigger BEFORE UPDATE ON Relations
    FOR EACH ROW EXECUTE PROCEDURE check_timestamp_and_version();

-- 3. I-th node can be inserted in way only if it already contains (i - 1) nodes. It should not be the same as the previous one

CREATE OR REPLACE FUNCTION check_node_in_way() RETURNS trigger AS
$check_node_in_way_definition$
DECLARE
    prev NodesInWays%ROWTYPE;
BEGIN
    IF NEW.node_index = 0 THEN
        RETURN NEW;
    END IF;
    SELECT * FROM NodesInWays WHERE node_index = NEW.node_index - 1 AND
                                    way_id = NEW.way_id
             INTO prev;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid node index';
    END IF;
    IF prev.node_id = NEW.node_id THEN
        RAISE EXCEPTION 'Two subsequent nodes can not be the same';
    END IF;
    RETURN NEW;
END;
$check_node_in_way_definition$
LANGUAGE plpgsql;

CREATE TRIGGER check_node_in_way_trigger BEFORE INSERT OR UPDATE ON NodesInWays
    FOR EACH ROW EXECUTE PROCEDURE check_node_in_way();

-- Views

CREATE OR REPLACE VIEW TagValuesCount AS
    SELECT tag_key, count(*) FROM
        (SELECT DISTINCT tag_key, tag_value FROM Tags INNER JOIN NodeTags USING (tag_key)
        UNION
        SELECT DISTINCT tag_key, tag_value FROM Tags INNER JOIN WayTags USING (tag_key)
        UNION
        SELECT DISTINCT tag_key, tag_value FROM Tags INNER JOIN RelationTags USING (tag_key)) AS Pairs
        GROUP BY tag_key;

CREATE OR REPLACE VIEW SubwayStations AS
    SELECT node_id FROM Nodes INNER JOIN NodeTags USING (node_id) WHERE tag_key = 'station' AND tag_value = 'subway';

CREATE MATERIALIZED VIEW NamedSubwayStations AS
    SELECT node_id, tag_value AS name FROM
        (SELECT node_id FROM SubwayStations) AS node_ids NATURAL INNER JOIN NodeTags
        WHERE tag_key = 'name';

CREATE OR REPLACE VIEW UsersContribution AS
    SELECT user_id, count(*) FROM
        (SELECT user_id FROM Users NATURAL INNER JOIN Nodes
        UNION ALL
        SELECT user_id FROM Users NATURAL INNER JOIN Ways
        UNION ALL
        SELECT user_id FROM Users NATURAL INNER JOIN Relations
        UNION ALL
        SELECT user_id FROM Users INNER JOIN Tags ON (user_id = introduced_by)) AS Ids
        GROUP BY user_id;
