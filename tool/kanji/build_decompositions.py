"""Normalize original SVG groups into the three-kind component tree."""
from collections import Counter, defaultdict
import io
import json
import xml.etree.ElementTree as ET
import zipfile

from build_seed import HERE, KVG_COMMIT, download
from taxonomy import S, K, STRUCTURE_VERSION, classify, dictionary, radical_catalog

def extract(root, forms, radical_names, rules, joyo=None, radical_meanings=None,
            include_statistics=False, allow_ui_overlap=False):
    if joyo is None:
        joyo = {e.findtext('literal') for e in dictionary()}
    radical_meanings = radical_meanings or {}
    drawing = next(g for g in root.iter(S+'g') if 'StrokePaths' in g.get('id', ''))
    original = next(g for g in drawing.iter(S+'g') if g.get(K+'element'))
    char = original.get(K+'element')
    strokes = [p.get('id') for p in original.iter(S+'path')]
    assert None not in strokes and len(set(strokes)) == len(strokes)
    order = {s: i for i, s in enumerate(strokes)}
    groups = {g.get('id'): g for g in original.iter(S+'g')}
    parents = {child: parent for parent in original.iter() for child in parent}
    def part_key(g):
        parent = parents.get(g)
        while parent is not None and not parent.get(K+'element'):
            parent = parents.get(parent)
        return (g.get(K+'element'), g.get(K+'original'), g.get(K+'number'),
                parent.get('id') if parent is not None else None)
    parts = defaultdict(list)
    for gid, g in groups.items():
        if g.get(K+'part'):
            parts[part_key(g)].append(gid)
    explicit = rules.get('part_groups', {}).get(char, [])
    overlap_groups = set(rules.get('ui_overlap_groups', {}).get(char, []))
    overlap_explicit = rules.get('ui_overlap_part_groups', {}).get(char, [])

    def overlap_peers(gid):
        override = next((p for p in overlap_explicit if gid in p), None)
        if override is not None:
            return override
        group = groups[gid]
        signature = (group.get(K+'element'), group.get(K+'original'))
        peers = [candidate.get('id') for candidate in groups.values()
                 if candidate.get(K+'part') and
                 (candidate.get(K+'element'), candidate.get(K+'original')) == signature]
        numbers = [int(groups[p].get(K+'part')) for p in peers]
        if (len(peers) < 2 or len(set(numbers)) != len(numbers) or
                sorted(numbers) != list(range(1, len(peers)+1))):
            raise ValueError(f'{char}: ambiguous UI overlap parts for {gid}: {peers}')
        return sorted(peers, key=lambda p: int(groups[p].get(K+'part')))

    def ids(node):
        return [node.get('id')] if node.tag == S+'path' else [p.get('id') for p in node.iter(S+'path')]

    def ancestors(gid):
        result = []
        current = groups[gid]
        while current is not None:
            if current.get('id'):
                result.append(current.get('id'))
            current = parents.get(current)
        return list(reversed(result))

    # Some KanjiVG parts belong to one complete component but sit below a
    # different sibling.  Surface that complete component at the lowest common
    # ancestor and stop expanding the borrowed branches below it.  This keeps
    # the UI concise while allowing the complete component to share strokes
    # with its siblings.
    overlap_nodes = defaultdict(list)
    hidden_at_scope = defaultdict(set)
    blocked_subtrees = set()
    seen_overlap_parts = set()
    if allow_ui_overlap:
        def display_scope(scope):
            group = groups[scope]
            if not group.get(K+'part'):
                return scope
            override = next((p for p in explicit if scope in p), None)
            peers = override or parts[part_key(group)]
            numbers = [int(groups[p].get(K+'part')) for p in peers]
            if sorted(numbers) != list(range(1, len(peers)+1)):
                return scope
            return peers[numbers.index(1)]

        descriptors = []
        for gid in sorted(overlap_groups):
            pids = tuple(overlap_peers(gid))
            if pids in seen_overlap_parts:
                continue
            seen_overlap_parts.add(pids)
            paths = [ancestors(pid) for pid in pids]
            scope = paths[0][0]
            for common in zip(*paths):
                if len(set(common)) != 1:
                    break
                scope = common[0]
            scope_path = ancestors(scope)
            while not groups[scope].get(K+'element'):
                scope = scope_path[scope_path.index(scope) - 1]
            descriptors.append([pids, scope])

        # An overlap nested in a branch borrowed by another overlap is shown
        # at the closest ancestor that remains navigable.  Otherwise its full
        # node would be hidden when the borrowed branch is deliberately made a
        # leaf to avoid reintroducing fragments.
        while True:
            blocked_subtrees = {
                group_id
                for pids, scope in descriptors
                for pid in pids
                for group_id in ancestors(pid)[ancestors(pid).index(scope) + 1:]
            }
            moved = False
            for descriptor in descriptors:
                if descriptor[1] not in blocked_subtrees:
                    continue
                scope_path = ancestors(descriptor[1])
                if len(scope_path) == 1:
                    continue
                descriptor[1] = scope_path[-2]
                moved = True
            if not moved:
                break
        for pids, scope in descriptors:
            scope = display_scope(scope)
            overlap_nodes[scope].append(pids)
            hidden_at_scope[scope].update(pids)

    def frontier(elements):
        result = []
        for e in elements:
            if e.tag == S+'path' or e.get(K+'element'):
                if ids(e):
                    result.append(e)
            else:
                result.extend(frontier(list(e)))
        return result

    def children(elements, stop_at_radical, scope):
        candidates = [e for e in frontier(elements)
                      if e.get('id') not in hidden_at_scope[scope]]
        # A split fragment cannot claim a complete character when another part
        # is hidden in a different named component. Expand that fragment only.
        while True:
            selected = {e.get('id') for e in candidates}
            expand = set()
            for e in candidates:
                if not e.get(K+'part'):
                    continue
                gid = e.get('id')
                peers = next((p for p in explicit if gid in p), None)
                if peers is None:
                    peers = parts[part_key(e)]
                numbers = [int(groups[p].get(K+'part')) for p in peers]
                incomplete_sequence = (len(set(numbers)) == len(numbers) and
                                       numbers != list(range(1, len(peers)+1)))
                if len(peers) < 2 or not set(peers) <= selected or incomplete_sequence:
                    expand.add(gid)
            if not expand:
                break
            candidates = [n for e in candidates for n in
                          (frontier(list(e)) if e.get('id') in expand else [e])]
        selected = {e.get('id'): e for e in candidates}
        consumed = set()
        result = [node for pids in overlap_nodes[scope]
                  for node in make([groups[p] for p in pids], stop_at_radical,
                                   force_leaf=True)]
        for e in candidates:
            gid = e.get('id')
            if gid in consumed:
                continue
            peers = [e]
            if e.get(K+'part'):
                override = next((p for p in explicit if gid in p), None)
                pids = override or parts[part_key(e)]
                peers = [selected[p] for p in pids]
                numbers = [int(p.get(K+'part')) for p in peers]
                if sorted(numbers) != list(range(1, len(peers)+1)):
                    raise ValueError(f'{char}: ambiguous parts {pids}; review explicit grouping')
            if e.get(K+'part'):
                consumed.update(p for p in pids if p in selected)
            else:
                consumed.add(gid)
            result.extend(make(peers, stop_at_radical))
        result.sort(key=lambda n: order[n['stroke_ids'][0]])
        return result

    def make(elements, stop_at_radical, force_leaf=False):
        first = elements[0]
        form, semantic = first.get(K+'element'), first.get(K+'original')
        stroke_ids = sorted((s for e in elements for s in ids(e)), key=order.get)
        display = form
        kind, rid = classify(display, form, semantic, forms, joyo)
        node = dict(id=first.get('id'), kind=kind, display_form=display,
                    source_element=form, source_original=semantic,
                    radical_id=rid, radical_name=radical_names.get(rid),
                    radical_meaning=radical_meanings.get(rid),
                    source_partial=any(e.get(K+'partial') == 'true' for e in elements),
                    source_positions=[e.get(K+'position') for e in elements if e.get(K+'position')],
                    source_group_ids=[e.get('id') for e in elements if e.tag == S+'g'],
                    stroke_ids=stroke_ids, children=[])
        if (not force_leaf and first.get('id') not in blocked_subtrees and
                (kind != 'radical' or not stop_at_radical)):
            node['children'] = children(
                [c for e in elements for c in e], stop_at_radical,
                first.get('id'))
            if kind == 'supplementary' and node['children']:
                return node['children']
            # Metadata wrappers with identical coverage add no navigable level.
            while (kind != 'radical' and len(node['children']) == 1 and
                   node['children'][0]['display_form'] == display):
                node['children'] = node['children'][0]['children']
        return [node]

    roots = make([original], True)
    assert len(roots) == 1, f'{char}: root must be Joyo or radical'
    tree = roots[0]
    validate(tree, strokes, allow_overlap=allow_ui_overlap)
    if not include_statistics:
        return tree

    all_roots = make([original], False)
    assert len(all_roots) == 1, f'{char}: full root must be unique'
    full_tree = all_roots[0]
    validate(full_tree, strokes)
    statistics = []

    def collect(node, radical_ancestors=()):
        if node['kind'] == 'radical':
            duplicate_wrapper = any(
                parent['radical_id'] == node['radical_id'] and
                parent['display_form'] == node['display_form'] and
                parent['stroke_ids'] == node['stroke_ids']
                for parent in radical_ancestors
            )
            if not duplicate_wrapper:
                statistics.append(node)
            radical_ancestors = radical_ancestors + (node,)
        for child in node['children']:
            collect(child, radical_ancestors)

    collect(full_tree)
    return tree, statistics


def validate(tree, strokes, allow_overlap=False):
    seen = set()
    order = {s: i for i, s in enumerate(strokes)}
    def visit(node):
        assert node['id'] and node['id'] not in seen, f'duplicate node {node["id"]}'
        seen.add(node['id'])
        ids = node['stroke_ids']
        assert ids and len(set(ids)) == len(ids) and set(ids) <= set(strokes)
        assert ids == sorted(ids, key=order.get)
        children = node['children']
        if children:
            child_strokes = [s for c in children for s in c['stroke_ids']]
            if allow_overlap:
                assert set(child_strokes) == set(ids), node['id']
            else:
                assert Counter(child_strokes) == Counter(ids), node['id']
            assert [order[c['stroke_ids'][0]] for c in children] == sorted(order[c['stroke_ids'][0]] for c in children)
        for child in children:
            visit(child)
    visit(tree)
    assert tree['stroke_ids'] == strokes


def build():
    locks = json.loads((HERE/'sources.lock.json').read_text(encoding='utf-8'))
    vg = download('kanjivg.zip', locks['kanjivg.zip']['url'], dict(locks))
    archive = zipfile.ZipFile(io.BytesIO(vg))
    radicals, forms = radical_catalog()
    names = {r['id']: r['name_vi'] for r in radicals}
    meanings = {r['id']: r['meaning_vi'] for r in radicals}
    entries = dictionary()
    joyo = {e.findtext('literal') for e in entries}
    rules = json.loads((HERE/'component_rules.json').read_text(encoding='utf-8'))
    rows = []
    for entry in entries:
        char = entry.findtext('literal')
        root = ET.fromstring(archive.read(f'kanjivg-{KVG_COMMIT}/kanji/{ord(char):05x}.svg'))
        tree = extract(
            root, forms, names, rules, joyo, meanings, allow_ui_overlap=True)
        partition_tree, statistics = extract(
            root, forms, names, rules, joyo, meanings, include_statistics=True)
        rows.append(dict(kanji_id=ord(char), structure_version=STRUCTURE_VERSION,
                         kanjivg_commit=KVG_COMMIT, tree=tree,
                         partition_tree=partition_tree,
                         statistics=statistics))
    rows.sort(key=lambda r: r['kanji_id'])
    assert len(rows) == 2136
    return rows



if __name__ == '__main__':
    from build_taxonomy import main as generate
    generate()
