"""Report split occurrences crossing named parents for structural review."""
import json
import xml.etree.ElementTree as ET
import zipfile
from build_components import HERE, KVG_COMMIT, K, S

rows = json.loads((HERE/'.cache/component_occurrences.json').read_text(encoding='utf8'))
archive = zipfile.ZipFile(HERE/'.cache/kanjivg.zip')
for row in rows:
    if len(row['source_group_ids']) < 2:
        continue
    kid = row['kanji_id']
    root = ET.fromstring(archive.read(f'kanjivg-{KVG_COMMIT}/kanji/{kid:05x}.svg'))
    parents = {c: p for p in root.iter() for c in p}
    groups = {g.get('id'): g for g in root.iter(S+'g')}
    details = []
    for gid in row['source_group_ids']:
        node = groups[gid]
        p = parents[node]
        while p in parents and not p.get(K+'element'):
            p = parents[p]
        details.append(dict(id=gid, element=node.get(K+'element'), original=node.get(K+'original'),
                            part=node.get(K+'part'), number=node.get(K+'number'),
                            context=p.get('id'), parent=p.get(K+'element')))
    if len({d['context'] for d in details}) > 1:
        print(json.dumps(dict(character=chr(kid), groups=details), ensure_ascii=False))
