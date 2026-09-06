"""Generate v2 component occurrences without rewriting deployed v1 migrations."""
import argparse
from collections import Counter
import gzip
import hashlib
import json
import xml.etree.ElementTree as ET
import zipfile

from build_seed import HERE, ROOT, KVG_COMMIT, download, sql, write_json

S = '{http://www.w3.org/2000/svg}'
K = '{http://kanjivg.tagaini.net}'
OUTPUT = ROOT / 'supabase/migrations/202609060002_seed_kanji_component_occurrences.sql'


def extract(root, radical_forms, rules, audit=False):
    stroke_root = next(g for g in root.iter(S+'g') if 'StrokePaths' in g.get('id', ''))
    paths = [p.get('id') for p in stroke_root.iter(S+'path')]
    assert None not in paths and len(set(paths)) == len(paths), 'Missing/duplicate stroke IDs'
    order = {p: i for i, p in enumerate(paths)}
    rows = []
    char = next(g.get(K+'element') for g in stroke_root.iter(S+'g') if g.get(K+'element'))
    groups = {g.get('id'): g for g in stroke_root.iter(S+'g')}
    parents = {child: parent for parent in stroke_root.iter() for child in parent}
    def context(gid):
        parent = parents.get(groups[gid])
        while parent is not None and not parent.get(K+'element'):
            parent = parents.get(parent)
        return parent.get('id') if parent is not None else stroke_root.get('id')
    blocked = set()

    def emit(node, form, rid=None, direct=False):
        ids = [node.get('id')] if direct else [p.get('id') for p in node.iter(S+'path')]
        if not ids:
            return
        rows.append(dict(display_form=form, source_element=node.get(K+'element'),
                         source_original=node.get(K+'original'), radical_id=rid,
                         source_group_ids=[] if direct else [node.get('id')], stroke_ids=ids,
                         _part=node.get(K+'part'), _number=node.get(K+'number')))

    def walk(node):
        if node.tag == S+'path':
            emit(node, None, direct=True)
            return
        form, original = node.get(K+'element'), node.get(K+'original')
        for stop in rules['stops']:
            if all(node.get(K+a) == stop[a] for a in ('element', 'original') if a in stop):
                emit(node, stop['display_form'])
                return
        # An explicit semantic original takes precedence over the visual form.
        rid = radical_forms.get(original) if original else radical_forms.get(form)
        if rid and node.get('id') not in blocked:
            emit(node, form, rid)
            return
        children = list(node)
        if form and node.get('id') not in blocked and not any(g.get(K+'element') for g in node.iter(S+'g') if g is not node):
            emit(node, form)
            return
        for child in children:
            walk(child)

    # A part whose other strokes have already been captured by a larger stop
    # is not a complete radical. Expand its remaining groups, never steal the
    # ancestor's strokes. Iterate because expanding may reveal another part.
    while True:
        rows.clear()
        walk(stroke_root)
        selected = {gid for r in rows for gid in r['source_group_ids']}
        incomplete = set()
        for row in rows:
            if row['_part'] is None:
                continue
            peers = {gid for gid, g in groups.items() if g.get(K+'part') and
                     (g.get(K+'element'),g.get(K+'original'),g.get(K+'number')) ==
                     (row['source_element'],row['source_original'],row['_number'])}
            if not peers <= selected:
                incomplete.update(peers & selected)
        if not incomplete - blocked:
            break
        blocked.update(incomplete)
    expected = set(rules.get('expand_groups', {}).get(char, []))
    if blocked != expected and not audit:
        raise ValueError(f'{char}: review expand_groups={sorted(blocked)} (previously {sorted(expected)})')
    if audit:
        return sorted(blocked)
    # part marks one occurrence split by stroke order. Repeated whole elements
    # (e.g. the two 幺 in 機) never enter this merging step.
    merged, pending = [], {}
    explicit = rules.get('part_groups', {}).get(char, [])
    explicit_ids = {gid for group in explicit for gid in group}
    for row in rows:
        gids = row['source_group_ids']
        if gids and gids[0] in explicit_ids:
            continue
        part = row['_part']
        if part is None:
            merged.append(row)
            continue
        key = (row['source_element'], row['source_original'], row['_number'])
        if part == '1':
            if key in pending:
                raise ValueError(f'{char}: ambiguous parts for {key}; define part_groups override')
            pending[key] = (row, 1)
            merged.append(row)
        else:
            if key not in pending or int(part) != pending[key][1] + 1:
                raise ValueError(f'{char}: orphan/nonconsecutive part {gids}; define part_groups override')
            first, _ = pending[key]
            if context(first['source_group_ids'][0]) != context(gids[0]):
                raise ValueError(f'{char}: parts cross named tree contexts {first["source_group_ids"] + gids}; define part_groups override')
            first['source_group_ids'].extend(gids)
            first['stroke_ids'].extend(row['stroke_ids'])
            pending[key] = (first, int(part))
    for group in explicit:
        selected = [row for row in rows if row['source_group_ids'] and row['source_group_ids'][0] in group]
        assert len(selected) == len(group), f'{char}: stale part_groups override {group}'
        first = selected[0]
        for row in selected[1:]:
            assert row['radical_id'] == first['radical_id'] and row['display_form'] == first['display_form']
            first['stroke_ids'].extend(row['stroke_ids'])
            first['source_group_ids'].extend(row['source_group_ids'])
        merged.append(first)
    merged.sort(key=lambda row: min(order[p] for p in row['stroke_ids']))
    for index, row in enumerate(merged):
        row['stroke_ids'].sort(key=order.get)
        row['occurrence_id'] = (row['source_group_ids'] or row['stroke_ids'])[0]
        row['sort_order'] = index
        del row['_part'], row['_number']
    assert Counter(p for row in merged for p in row['stroke_ids']) == Counter(paths), f'{char}: stroke coverage'
    assert len({r['occurrence_id'] for r in merged}) == len(merged)
    return merged


def build(audit=False):
    locks = json.loads((HERE/'sources.lock.json').read_text(encoding='utf8'))
    kd = (HERE/'sources/kanjidic2.xml.gz').read_bytes()
    vg = download('kanjivg.zip', locks['kanjivg.zip']['url'], dict(locks))
    assert hashlib.sha256(kd).hexdigest() == locks['kanjidic2.xml.gz']['sha256']
    assert hashlib.sha256(vg).hexdigest() == locks['kanjivg.zip']['sha256']
    rules = json.loads((HERE/'component_rules.json').read_text(encoding='utf8'))
    assert rules['component_version'] == 2
    forms = {}
    for line in (HERE/'radicals.tsv').read_text(encoding='utf8').splitlines():
        if not line or line.startswith('#'):
            continue
        rid, form, _, _, _, variants = line.split('\t')
        for v in form+variants:
            forms.setdefault(v, int(rid))
    assert set(forms.values()) == set(range(1, 215)), 'Expected 214 radicals'
    # Additional modern equivalents already supported by the v1 catalog.
    for variant, canonical in {'糹':'糸','纟':'糸','訁':'言','讠':'言','釒':'金','钅':'金','飠':'食','饣':'食','贝':'貝','车':'車','鱼':'魚','鸟':'鳥','竜':'龍','麦':'麥','黄':'黃','黒':'黑','歯':'齒','亀':'龜','青':'靑','斉':'齊','戸':'戶','艹':'艸','辶':'辵','礻':'示','衤':'衣','丬':'爿'}.items():
        forms[variant] = forms[canonical]
    archive = zipfile.ZipFile(HERE/'.cache/kanjivg.zip')
    dictionary = ET.fromstring(gzip.decompress(kd))
    occurrences, characters, errors = [], {}, []
    for entry in dictionary.findall('character'):
        if int(entry.findtext('misc/grade') or 0) not in (1,2,3,4,5,6,8):
            continue
        char = entry.findtext('literal'); kid = ord(char)
        root = ET.fromstring(archive.read(f'kanjivg-{KVG_COMMIT}/kanji/{kid:05x}.svg'))
        try:
            rows = extract(root, forms, rules, audit=audit)
        except (ValueError, AssertionError) as error:
            errors.append(str(error))
            continue
        if audit:
            if rows:
                characters[char] = rows
            continue
        for row in rows:
            row.update(kanji_id=kid, component_version=2, kanjivg_commit=KVG_COMMIT)
        characters[char] = rows
        occurrences.extend(rows)
    if audit:
        return characters
    if errors:
        raise ValueError('\n'.join(errors))
    assert len(characters) == 2136 and all(characters.values())
    for key in ('part_groups', 'expand_groups'):
        assert set(rules.get(key, {})) <= set(characters), f'Stale {key} character override'
    occurrences.sort(key=lambda r: (r['kanji_id'],r['sort_order']))
    return occurrences, characters


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--validate-only', action='store_true')
    parser.add_argument('--cache-only', action='store_true', help='Prepare corpus test data without rewriting deployed migrations.')
    parser.add_argument('--audit', action='store_true')
    args = parser.parse_args()
    if args.audit:
        write_json(HERE/'.cache/proposed_expand_groups.json', build(audit=True))
        print('Review .cache/proposed_expand_groups.json before updating component_rules.json')
        return
    rows, characters = build()
    samples = {char: [{'form': r['display_form'], 'strokes': r['stroke_ids']} for r in characters[char]] for char in '機何学森国基'}
    report = dict(component_version=2, kanji_count=len(characters), occurrence_count=len(rows),
                  supplementary_count=sum(r['radical_id'] is None for r in rows), coverage='Every SVG stroke belongs to exactly one terminal occurrence', samples=samples)
    if args.cache_only:
        write_json(HERE/'.cache/component_occurrences.json', rows)
        args.validate_only = True
    if not args.validate_only:
        columns = list(rows[0])
        statements = ['-- Generated by tool/kanji/build_components.py. Same pinned KanjiVG; licences: assets/kanji/ATTRIBUTION.md.', 'begin;']
        statements.append('delete from public.kanji_component_occurrences;')
        for start in range(0,len(rows),250):
            values = ',\n'.join('('+','.join(sql(r[c]) for c in columns)+')' for r in rows[start:start+250])
            statements.append(f"insert into public.kanji_component_occurrences ({','.join(columns)}) values\n{values};")
        statements.extend([
            'delete from public.kanji_components;',
            "insert into public.kanji_components(kanji_id,radical_id,component_form,sort_order) select kanji_id,radical_id,display_form,min(sort_order) from public.kanji_component_occurrences where radical_id is not null group by kanji_id,radical_id,display_form;",
            (HERE/'stats_v2.sql').read_text(encoding='utf8'),
            'commit;\n'])
        OUTPUT.write_text('\n\n'.join(statements),encoding='utf8')
        write_json(HERE/'component_validation_report.json',report)
        write_json(HERE/'.cache/component_occurrences.json',rows)
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__ == '__main__':
    main()
