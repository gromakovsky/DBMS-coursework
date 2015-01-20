-- Sizes of relations
CREATE OR REPLACE VIEW NodesInRelationsCounts AS
    SELECT relation_id, count(*) AS nodes_count FROM Relations NATURAL JOIN NodesInRelations GROUP BY relation_id;

CREATE OR REPLACE VIEW WaysInRelationsCounts AS
    SELECT relation_id, count(*) AS ways_count FROM Relations NATURAL JOIN WaysInRelations GROUP BY relation_id;

CREATE OR REPLACE FUNCTION my_sum(a bigint, b bigint) RETURNS int AS
$$
BEGIN
    IF a IS NULL THEN
        RETURN b;
    END IF;
    IF b IS NULL THEN
        RETURN a;
    END IF;
    RETURN a + b;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW RelationsSizes AS
    SELECT relation_id, my_sum(nodes_count, ways_count) AS relation_size FROM NodesInRelationsCounts FULL JOIN WaysInRelationsCounts USING (relation_id);

-- Tags values
CREATE OR REPLACE VIEW NodeTagsValues AS
    SELECT tag_key AS key, string_agg(DISTINCT tag_value, ', ') AS values FROM NodeTags GROUP BY tag_key;

CREATE OR REPLACE VIEW WayTagsValues AS
    SELECT tag_key AS key, string_agg(DISTINCT tag_value, ', ') AS values FROM WayTags GROUP BY tag_key;

CREATE OR REPLACE VIEW RelationTagsValues AS
    SELECT tag_key AS key, string_agg(DISTINCT tag_value, ', ') AS values FROM RelationTags GROUP BY tag_key;

CREATE OR REPLACE VIEW TagsValues AS
    SELECT key, NodeTagsValues.values AS nodes_values, WayTagsValues.values AS ways_values, RelationTagsValues.values AS relations_values FROM NodeTagsValues NATURAL FULL JOIN WayTagsValues NATURAL FULL JOIN RelationTagsValues;

-- filtered nodes
CREATE OR REPLACE VIEW FilteredNodes AS
    SELECT Nodes.node_id FROM Nodes INNER JOIN NodeTags USING (node_id) WHERE NodeTags.tag_key = 'station' AND NodeTags.tag_value = 'subway';

-- filtered ways
CREATE OR REPLACE VIEW FilteredWays AS
    SELECT Ways.way_id FROM Ways INNER JOIN WayTags USING (way_id) WHERE WayTags.tag_key = 'highway' AND wayTags.tag_value = 'primary';

