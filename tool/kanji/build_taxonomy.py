"""Generate UI tree v3, strict occurrences v3 and statistics mapping v4."""
import argparse
from collections import Counter
import json

from build_seed import HERE, ROOT, KVG_COMMIT, sql, write_json
from taxonomy import COMPONENT_VERSION, STATISTICS_VERSION, dictionary, radical_catalog

OUTPUT = ROOT/'supabase/migrations/202609180001_kanji_ui_overlap_v3.sql'


def catalog():
    curated = json.loads((HERE/'curated_vi.json').read_text(encoding='utf-8'))
    for line in (HERE/'meanings_vi.tsv').read_text(encoding='utf-8').splitlines():
        if line and not line.startswith('#'):
            char, meaning = line.split('\t')
            curated.setdefault(char, {}).setdefault('meaning_vi', meaning)
    rows = []
    for entry in dictionary():
        char = entry.findtext('literal')
        vi = curated.get(char, {})
        readings = entry.findall('reading_meaning/rmgroup/reading')
        words = entry.findall('reading_meaning/rmgroup/meaning')
        rows.append(dict(
            id=ord(char), character=char,
            han_viet=vi.get('han_viet') or ' · '.join(r.text for r in readings if r.get('r_type') == 'vietnam') or None,
            onyomi=[r.text for r in readings if r.get('r_type') == 'ja_on'],
            kunyomi=[r.text for r in readings if r.get('r_type') == 'ja_kun'],
            meaning_vi=vi.get('meaning_vi'),
            meaning_en='; '.join(w.text for w in words if not w.get('m_lang')),
            stroke_count=int(entry.findtext('misc/stroke_count')),
            grade=int(entry.findtext('misc/grade')),
            primary_radical_id=int(next(r.text for r in entry.findall('radical/rad_value') if r.get('rad_type') == 'classical')),
            translation_reviewed=vi.get('review_status') == 'approved'))
    return sorted(rows, key=lambda r: r['id'])


def nodes(node):
    yield node
    for child in node['children']:
        yield from nodes(child)


def occurrences(tree):
    order = {s: i for i, s in enumerate(tree['stroke_ids'])}
    leaves = sorted((n for n in nodes(tree) if not n['children']),
                    key=lambda n: order[n['stroke_ids'][0]])
    return [dict(occurrence_id=n['id'], sort_order=i, kind=n['kind'],
                 display_form=n['display_form'], source_element=n['source_element'],
                 source_original=n['source_original'], radical_id=n['radical_id'],
                 source_partial=n['source_partial'], source_group_ids=n['source_group_ids'],
                 stroke_ids=n['stroke_ids']) for i, n in enumerate(leaves)]


def statistic_components(row):
    """Aggregate every recognized radical in the hidden full SVG projection.

    The UI tree deliberately stops at radicals, while this projection retains
    nested radicals and their multiplicity for statistics only.
    """
    order = {s: i for i, s in enumerate(row['tree']['stroke_ids'])}
    components = {}
    for node in row['statistics']:
        key = (row['kanji_id'], node['radical_id'], node['display_form'])
        item = components.setdefault(key, dict(
            kanji_id=row['kanji_id'], radical_id=node['radical_id'],
            component_form=node['display_form'], occurrence_count=0,
            sort_order=order[node['stroke_ids'][0]],
        ))
        item['occurrence_count'] += 1
        item['sort_order'] = min(item['sort_order'], order[node['stroke_ids'][0]])
    return sorted(components.values(), key=lambda item: item['sort_order'])


def build():
    from build_decompositions import build as trees
    kanji = catalog()
    radicals, _ = radical_catalog()
    source_trees = trees()
    flat, relations, statistics = [], {}, []
    joyo = {k['character'] for k in kanji}
    for row in source_trees:
        for node in nodes(row['tree']):
            assert node['kind'] in ('kanji', 'radical', 'supplementary')
            if node['kind'] == 'kanji':
                assert node['display_form'] in joyo
            elif node['kind'] == 'radical':
                assert node['radical_id'] in range(1, 215) and not node['children']
                radical = radicals[node['radical_id']-1]
                for position in node['source_positions']:
                    label = {'left':'Trái','right':'Phải','top':'Trên','bottom':'Dưới',
                             'tare':'Trên và trái','nyou':'Dưới và trái','kamae':'Bao quanh'}.get(position)
                    if label and label not in radical['positions']:
                        radical['positions'].append(label)
            else:
                assert not node['children'] and node['radical_id'] is None
        # Occurrences remain the strict, non-overlapping projection used by
        # existing stroke data and statistics.
        leaves = occurrences(row['partition_tree'])
        assert Counter(s for n in leaves for s in n['stroke_ids']) == Counter(row['tree']['stroke_ids'])
        for leaf in leaves:
            leaf.update(kanji_id=row['kanji_id'], component_version=COMPONENT_VERSION, kanjivg_commit=KVG_COMMIT)
            flat.append(leaf)
        # Related Kanji follows the new UI leaves, where two components may
        # intentionally share a stroke.
        for leaf in occurrences(row['tree']):
            rid, form = leaf['radical_id'], leaf['display_form']
            if rid is None:
                continue
            relations.setdefault((row['kanji_id'], rid, form), dict(
                kanji_id=row['kanji_id'], radical_id=rid, component_form=form, sort_order=leaf['sort_order']))
            radical = radicals[rid-1]
            # Catalog browsing includes actually used forms. Recognition NEVER
            # consumes these inferred entries: only the source TSV + explicit rule.
            if form != radical['character'] and form not in radical['variants']:
                radical['variants'].append(form)
        for component in statistic_components(row):
            statistics.append(component)
            radical = radicals[component['radical_id']-1]
            form = component['component_form']
            # Snapshot form counts must have a catalog entry even when the form
            # appears only below a UI radical stop.
            if form != radical['character'] and form not in radical['variants']:
                radical['variants'].append(form)
    decompositions = [
        {key: value for key, value in row.items()
         if key not in ('statistics', 'partition_tree')}
        for row in source_trees
    ]
    for row in decompositions:
        for node in nodes(row['tree']):
            if node['radical_id'] is not None:
                # Linked canonical metadata, separate from the SVG display form.
                node['radical'] = radicals[node['radical_id']-1]
    return (dict(kanji=kanji, radicals=radicals, components=list(relations.values()),
                 statistic_components=statistics), decompositions, flat, statistics)


def insert(table, rows):
    columns = list(rows[0])
    statements = []
    for start in range(0, len(rows), 200):
        values = ',\n'.join('('+','.join(
            sql(json.dumps(r[c], ensure_ascii=False, separators=(',', ':')))+'::jsonb'
            if c == 'tree' else sql(r[c]) for c in columns)+')'
            for r in rows[start:start+200])
        statements.append(f"insert into public.{table} ({','.join(columns)}) values\n{values};")
    return statements


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validate-only', action='store_true')
    parser.add_argument('--cache-only', action='store_true')
    parser.add_argument('--release', action='store_true')
    args = parser.parse_args()
    data, trees, flat, statistics = build()
    if args.release and any(not k['translation_reviewed'] or not k['meaning_vi'] or not k['han_viet'] for k in data['kanji']):
        raise ValueError('Release requires complete human-approved Vietnamese data.')
    report = dict(structure_version=3, occurrence_version=COMPONENT_VERSION,
                  statistics_version=STATISTICS_VERSION, kanji_count=len(trees),
                  node_counts=dict(Counter(n['kind'] for r in trees for n in nodes(r['tree']))),
                  occurrence_count=len(flat), relation_count=len(data['components']),
                  statistic_component_count=len(statistics))
    if not args.validate_only:
        for name, content in [('catalog', data), ('decompositions', trees),
                              ('component_occurrences', flat),
                              ('radical_stat_components', statistics)]:
            write_json(HERE/f'.cache/{name}.json', content)
        write_json(HERE/'taxonomy_validation_report.json', report)
    if not args.validate_only and not args.cache_only:
        statements = [(HERE/'ui_overlap_migration.sql').read_text(encoding='utf-8')]
        for table, rows in [('kanji_decompositions', trees),
                            ('kanji_components', data['components'])]:
            statements.extend(insert(table, rows))
        statements.append('commit;\n')
        OUTPUT.write_text('\n\n'.join(statements), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
