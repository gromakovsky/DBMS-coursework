DROP TABLE IF EXISTS Nodes, Ways, Relations, Tags, Users CASCADE;
DROP TABLE IF EXISTS NodesInRelations, NodesInWays, WaysInRelations, NodeTags, WayTags, RelationTags CASCADE;

DROP FUNCTION IF EXISTS relation_size(bigint);
DROP FUNCTION IF EXISTS add_user(int, text, text, text);
DROP FUNCTION IF EXISTS add_tag(text, int);
DROP FUNCTION IF EXISTS way_coordinates(bigint);
DROP FUNCTION IF EXISTS change_node_coordinates(bigint, double precision, double precision);
DROP FUnCTION IF EXISTS tag_values(text);
DROP FUNCTION IF EXISTS check_relation_content();
DROP FUNCTION IF EXISTS check_erasing_from_relation();
DROP FUNCTION IF EXISTS check_timestamp_and_version();
DROP FUNCTION IF EXISTS check_node_in_way();

DROP VIEW IF EXISTS TagValuesCount, SubwayStations, UsersContribution;
DROP MATERIALIZED VIEW IF EXISTS NamedSubwayStations;
DROP MATERIALIZED VIEW IF EXISTS NamedFuels;
DROP MATERIALIZED VIEW IF EXISTS NamedPrimaryHighways;

