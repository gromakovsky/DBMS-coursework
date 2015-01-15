import xml.etree.cElementTree as ET

all_users = set()
all_tags = set()


def iterparse(fileobj):
    """
    Return root object and iterparser for given ``fileobj``.
    """
    context = ET.iterparse(fileobj, events=("start", "end"))
    context = iter(context)
    _event, root = context.next()
    return root, context


def process_user(uid, user_name):
    if uid in all_users:
        return
    all_users.add(uid)
    user_name = unicode(user_name)
    email = user_name + u'@example.com'
    password = unicode(hash((uid, user_name)))[-8:]
    print u"""SELECT add_user({uid}, $${user_name}$$, $${email}$$, $${password}$$);""".format(**locals()).encode('utf-8')


def process_tag(tag_key, uid=1):
    if tag_key in all_tags:
        return
    all_tags.add(tag_key)
    print u"""SELECT add_tag($${tag_key}$$, {uid});""".format(**locals()).encode('utf-8')


def process_node(node_id, version, lat, lon, timestamp, uid, tags):
    print 'BEGIN;'
    # Node
    print """INSERT INTO Nodes (node_id, version, latitude, longitude, timestamp, user_id)
  VALUES ({node_id}, {version}, {lat}, {lon}, $${timestamp}$$, {uid});""".format(**locals())

    # Tags of node
    for tag in tags.iteritems():
        tag_key_unicode = unicode(tag[0])
        tag_value_unicode = unicode(tag[1])
        print u"""INSERT INTO NodeTags (node_id, tag_key, tag_value)
  VALUES ({node_id}, $${tag_key_unicode}$$, $${tag_value_unicode}$$);""".format(**locals()).encode('utf-8')
    print 'COMMIT;'


def process_way(way_id, version, timestamp, uid, refs, tags):
    print 'BEGIN;'
    # Way
    node_id = refs[0]
    print """INSERT INTO Ways (way_id, version, timestamp, user_id, node_id)
  VALUES ({way_id}, {version}, $${timestamp}$$, {uid}, {node_id});""".format(**locals())

    # Nodes in way
    for node_index, node_id in enumerate(refs):
        print """INSERT INTO NodesInWays (node_index, node_id, way_id)
  VALUES ({node_index}, {node_id}, {way_id});""".format(**locals())

    # Tags of way
    for tag in tags.iteritems():
        tag_key_unicode = unicode(tag[0])
        tag_value_unicode = unicode(tag[1])
        print u"""INSERT INTO WayTags (way_id, tag_key, tag_value)
  VALUES ({way_id}, $${tag_key_unicode}$$, $${tag_value_unicode}$$);""".format(**locals()).encode('utf-8')
    print 'COMMIT;'


def process_relation(relation_id, version, timestamp, uid, members, tags):
    print 'BEGIN;'
    # Relation
    print """INSERT INTO Relations (relation_id, version, timestamp, user_id)
  VALUES ({relation_id}, {version}, $${timestamp}$$, {uid});""".format(**locals())

    # Members of relation
    for ref, member_type, role in members:
        unicode_role = unicode(role)
        print u"""INSERT INTO {member_type}sInRelations (role, {member_type}_id, relation_id)
  VALUES ($${unicode_role}$$, {ref}, {relation_id});""".format(**locals()).encode('utf-8')

    # Tags of relation
    for tag in tags.iteritems():
        tag_key_unicode = unicode(tag[0])
        tag_value_unicode = unicode(tag[1])
        print u"""INSERT INTO RelationTags (relation_id, tag_key, tag_value)
  VALUES ({relation_id}, $${tag_key_unicode}$$, $${tag_value_unicode}$$);""".format(**locals()).encode('utf-8')
    print 'COMMIT;'


def generate_queries(xml_file):
    tags = {}
    refs = []
    members = []
    root, context = iterparse(xml_file)

    process_user(1, 'dummy')
    for event, elem in context:
        if event == 'start':
            continue
        if elem.tag == 'tag':
            tags[elem.attrib['k']] = elem.attrib['v']
            process_tag(elem.attrib['k'])
        elif elem.tag == 'node':
            node_id = int(elem.attrib['id'])
            version = int(elem.attrib['version'])
            lat, lon = float(elem.attrib['lat']), float(elem.attrib['lon'])
            uid = int(elem.attrib['uid'])
            timestamp = (elem.attrib['timestamp'])
            process_user(uid, elem.attrib['user'])
            process_node(node_id, version, lat, lon, timestamp, uid, tags)
            tags = {}
        elif elem.tag == 'nd':
            refs.append(int(elem.attrib['ref']))
        elif elem.tag == 'member':
            if elem.attrib['type'] in ('way', 'node'):
                members.append((int(elem.attrib['ref']), elem.attrib['type'], elem.attrib['role']))
        elif elem.tag == 'way':
            way_id = int(elem.attrib['id'])
            version = int(elem.attrib['version'])
            timestamp = (elem.attrib['timestamp'])
            uid = int(elem.attrib['uid'])
            process_user(uid, elem.attrib['user'])
            process_way(way_id, version, timestamp, uid, refs, tags)
            refs = []
            tags = {}
        elif elem.tag == 'relation':
            relation_id = int(elem.attrib['id'])
            version = int(elem.attrib['version'])
            timestamp = (elem.attrib['timestamp'])
            uid = int(elem.attrib['uid'])
            process_user(uid, elem.attrib['user'])
            if len(members) > 1:
                process_relation(relation_id, version, timestamp, uid, members, tags)
            members = []
            tags = {}

        root.clear()


with open('SPE-full.xml') as f:
    generate_queries(f)

print 'REFRESH MATERIALIZED VIEW NamedSubwayStations;'
print 'REFRESH MATERIALIZED VIEW NamedFuels;'
print 'REFRESH MATERIALIZED VIEW NamedPrimaryHighways;'

