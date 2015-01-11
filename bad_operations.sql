-- It's assumed to be used after insert.sql

-- Invalid latitude
INSERT INTO Nodes (node_id, latitude, longitude, user_id) VALUES (2000, 100, 50, 1);

-- Way without nodes
INSERT INTO Ways (way_id, user_id, node_id) VALUES (345456456, 1, 10500);

-- Incorrect indicies in way
BEGIN;
INSERT INTO Ways (way_id, user_id, node_id) VALUES (1136, 1, 10500);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (0, 10500, 1136);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (1, 100500, 1136);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (9, 10500, 1136);
COMMIT;

-- Same subsequent nodes in a way
BEGIN;
INSERT INTO Ways (way_id, user_id, node_id) VALUES (1137, 1, 10500);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (0, 10500, 1137);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (1, 100500, 1137);
INSERT INTO NodesInWays (node_index, node_id, way_id) VALUES (2, 100500, 1137);
COMMIT;

-- Relation contains not enough items
BEGIN;
INSERT INTO Relations (relation_id, user_id) VALUES (132, 1);
INSERT INTO NodesInRelations (role, node_id, relation_id) VALUES ('point', 100500, 132);
COMMIT;

-- Another way to violate it is to remove items from good relation
DELETE FROM WaysInRelations WHERE relation_id = 130;

-- Update node but leave old version
UPDATE Nodes SET latitude = 0, timestamp = CURRENT_TIMESTAMP WHERE node_id = 100500;

