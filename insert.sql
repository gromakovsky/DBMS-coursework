-- Users
INSERT INTO Users (user_id, user_name, email, password_hash, status, information) VALUES (1, 'admin', 'admin@example.com', 'aaaaff12', 'Administrator', 'I am administrator of this site.');
INSERT INTO Users (user_id, user_name, email, password_hash, status, information) VALUES (2, 'rabbit', 'rabbit@example.com', 'bb13dd72', 'Moderator', 'I am moderator of this site.');
INSERT INTO Users (user_id, user_name, email, password_hash, status, information) VALUES (101, 'dread', 'dread@example.com', 'bbbb6972', 'User', 'My name is Andrey. I am from Russia.');
INSERT INTO Users (user_id, user_name, email, password_hash, status) VALUES (102, 'devil666', 'devil@example.com', 'ccbb9996', 'User');
INSERT INTO Users (user_id, user_name, email, password_hash, status) VALUES (39040, 'Dinamik', 'dinamik@example.com', '553344cc', 'User');
INSERT INTO Users (user_id, user_name, email, password_hash, status) VALUES (392109, 'GaM', 'GaM@example.com', '578341cc', 'User');

-- Tags
INSERT INTO Tags (tag_key, introduced_by) VALUES ('amenity', 101);
INSERT INTO Tags (tag_key, introduced_by) VALUES ('name', 1);
INSERT INTO Tags (tag_key, introduced_by) VALUES ('railway', 102);
INSERT INTO Tags (tag_key, introduced_by) VALUES ('station', 101);
INSERT INTO Tags (tag_key, introduced_by) VALUES ('transport', 2);
INSERT INTO Tags (tag_key, introduced_by) VALUES ('name:en', 2);
INSERT INTO Tags (tag_key, introduced_by) VALUES ('type', 2);

-- Nodes
INSERT INTO Nodes (node_id, latitude, longitude, user_id) VALUES (100500, 12.343, 123.777, 1);
INSERT INTO Nodes (node_id, latitude, longitude, user_id) VALUES (10500, 12.343, 13.329, 1);

BEGIN;
INSERT INTO Nodes (node_id, latitude, longitude, user_id) VALUES (14, 69.9, 31.56449, 101);
SELECT change_node_coordinates(14, 50, 50);
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('Сбербанк', 14, 'name');
COMMIT;

BEGIN;
INSERT INTO Nodes (node_id, latitude, longitude, user_id) VALUES (1440436739, 59.9356024, 30.3156449, 39040);
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('Адмиралтейская', 1440436739, 'name');
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('station', 1440436739, 'railway');
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('subway', 1440436739, 'station');
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('Admiralteyskaya', 1440436739, 'name:en');
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('subway', 1440436739, 'transport');
COMMIT;

BEGIN;
INSERT INTO Nodes (node_id, latitude, longitude, user_id) VALUES (695136871, 59.8560877, 30.3961166, 392109);
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('Проспект Славы (строится)', 695136871, 'name');
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('subway', 695136871, 'station');
INSERT INTO NodeTags (tag_value, node_id, tag_key) VALUES ('construction', 695136871, 'railway');
COMMIT;

-- Ways
BEGIN;
INSERT INTO Ways (way_id, user_id, node_id) VALUES (250, 1, 10500);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (0, 10500, 250);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (1, 100500, 250);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (2, 10500, 250);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (3, 14, 250);
COMMIT;

BEGIN;
INSERT INTO Ways (way_id, user_id, node_id) VALUES (14, 1, 14);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (0, 14, 14);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (1, 100500, 14);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (2, 14, 14);

INSERT INTO WayTags (tag_value, way_id, tag_key) VALUES ('Route', 14, 'name');
INSERT INTO WayTags (tag_value, way_id, tag_key) VALUES ('subway', 14, 'transport');
COMMIT;

-- Relations
BEGIN;
INSERT INTO Relations (relation_id, user_id) VALUES (13, 1);
INSERT INTO NodesInRelations (role, node_id, relation_id) VALUES ('point', 100500, 13);
INSERT INTO NodesInRelations (role, node_id, relation_id) VALUES ('point', 10500, 13);
COMMIT;

BEGIN;
INSERT INTO Relations (relation_id, user_id) VALUES (130, 101);
INSERT INTO WaysInRelations (role, way_id, relation_id) VALUES ('boundary', 14, 130);
INSERT INTO NodesInRelations (role, node_id, relation_id) VALUES ('point', 10500, 130);

INSERT INTO RelationTags (tag_value, relation_id, tag_key) VALUES ('Bridge', 130, 'type');
COMMIT;

REFRESH MATERIALIZED VIEW NamedSubwayStations;

