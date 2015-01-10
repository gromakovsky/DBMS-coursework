DROP TABLE IF EXISTS Nodes, Ways, Relations, Tags, Users CASCADE;
DROP TABLE IF EXISTS NodesInRelations, NodesInWays, WaysInRelations, NodeTags, WayTags, RelationTags CASCADE;

DROP FUNCTION IF EXISTS relation_size(bigint);
DROP FUNCTION IF EXISTS add_user(int, text, text, text);
DROP FUNCTION IF EXISTS check_relation_content();
DROP FUNCTION IF EXISTS check_timestamp_and_version();

DROP VIEW IF EXISTS TagValuesCount, NamedSubwayStations;

