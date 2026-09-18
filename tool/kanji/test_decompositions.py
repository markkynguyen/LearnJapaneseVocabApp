"""Hierarchy semantics, exact root-relative strokes, deterministic full corpus."""
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
from build_decompositions import build, extract


class DecompositionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = build()
        cls.trees = {chr(r['kanji_id']): r['tree'] for r in cls.rows}

    def forms(self, node):
        return [c['display_form'] for c in node['children']]

    def test_large_components_first(self):
        for char, forms in {'想': ['相', '心'], '謝': ['言', '射'],
                            '森': ['木', '林'], '語': ['言', '五', '口'],
                            '機': ['木', '幾'], '憾': ['忄', '感']}.items():
            self.assertEqual(self.forms(self.trees[char]), forms)
        self.assertEqual(self.forms(self.trees['想']['children'][0]), ['木', '目'])
        self.assertEqual(self.forms(self.trees['謝']['children'][1]), ['身', '寸'])
        self.assertNotIn('咸', self.forms(self.trees['憾']['children'][1]))

    def test_radicals_stop_and_repeated_occurrences_are_distinct(self):
        woods = self.trees['森']['children'][1]['children']
        self.assertEqual(self.forms(self.trees['森']['children'][1]), ['木', '木'])
        self.assertNotEqual(woods[0]['id'], woods[1]['id'])
        self.assertFalse(set(woods[0]['stroke_ids']) & set(woods[1]['stroke_ids']))
        for wood in woods:
            self.assertEqual(wood['kind'], 'radical')
            self.assertEqual(wood['children'], [])
        self.assertEqual(self.trees['木']['children'], [])

    def test_split_parts_keep_original_stroke_ids(self):
        five = self.trees['語']['children'][1]
        two = next(n for n in five['children'] if n['display_form'] == '二')
        self.assertEqual(two['stroke_ids'], ['kvg:08a9e-s8', 'kvg:08a9e-s11'])
        self.assertEqual(len(two['source_group_ids']), 2)

    def test_deterministic_full_corpus(self):
        # build validates coverage, unique node IDs and ordering.
        self.assertEqual(len(self.rows), 2136)
        self.assertEqual(build(), self.rows)

    def test_ui_overlap_groups_are_complete_while_statistics_stay_strict(self):
        from build_taxonomy import build as taxonomy, nodes
        rules = json.loads((Path(__file__).parent /
                            'component_rules.json').read_text(encoding='utf8'))
        data, trees, leaves, statistics = taxonomy()
        by_character = {chr(row['kanji_id']): row['tree'] for row in trees}
        overlap = rules['ui_overlap_groups']
        self.assertEqual((len(overlap), sum(map(len, overlap.values()))), (113, 148))
        for char, group_ids in overlap.items():
            used = {group_id for node in nodes(by_character[char])
                    for group_id in node['source_group_ids']}
            self.assertTrue(set(group_ids) <= used, char)
        well = by_character['井']['children']
        self.assertEqual([node['display_form'] for node in well], ['二', '廾'])
        self.assertEqual(set(well[0]['stroke_ids']) & set(well[1]['stroke_ids']),
                         {'kvg:04e95-s2'})
        enclosure = next(node for node in by_character['囲']['children']
                         if node['display_form'] == '井')
        self.assertEqual([node['display_form'] for node in enclosure['children']],
                         ['二', '廾'])
        self.assertEqual(leaves, json.loads((Path(__file__).parent /
                                              '.cache/component_occurrences.json').read_text(encoding='utf8')))
        self.assertEqual(statistics, json.loads((Path(__file__).parent /
                                                  '.cache/radical_stat_components.json').read_text(encoding='utf8')))
        self.assertIn((ord('井'), 7, '二'),
                      {(row['kanji_id'], row['radical_id'], row['component_form'])
                       for row in data['components']})
        self.assertIn((ord('井'), 55, '廾'),
                      {(row['kanji_id'], row['radical_id'], row['component_form'])
                       for row in data['components']})

    def test_shared_tree_projection_and_editorial_catalog(self):
        from build_taxonomy import build as taxonomy, occurrences, nodes
        from build_components import build as flat
        data, trees, leaves, statistics = taxonomy()
        self.assertEqual(leaves, flat()[0])
        self.assertEqual(taxonomy(), (data, trees, leaves, statistics))
        self.assertTrue(all(k['meaning_vi'] and k['han_viet'] for k in data['kanji']))
        for row in trees:
            for node in nodes(row['tree']):
                if node['kind'] == 'radical':
                    self.assertEqual(node['radical']['id'], node['radical_id'])
                    self.assertEqual(node['radical']['name_vi'], node['radical_name'])
                self.assertEqual([n['occurrence_id'] for n in occurrences(row['tree'])],
                             [n['id'] for n in sorted((n for n in nodes(row['tree']) if not n['children']),
                              key=lambda n: row['tree']['stroke_ids'].index(n['stroke_ids'][0]))])

    def test_statistics_projection_keeps_nested_radicals_out_of_ui_tree(self):
        from build_taxonomy import build as taxonomy
        _, trees, _, statistics = taxonomy()
        components = {}
        for component in statistics:
            components.setdefault(chr(component['kanji_id']), []).append(
                (component['component_form'], component['radical_id'], component['occurrence_count']))

        self.assertEqual(
            components['員'], [('口', 30, 1), ('貝', 154, 1), ('目', 109, 1), ('八', 12, 1)])
        self.assertEqual(
            components['損'], [('扌', 64, 1), ('口', 30, 1), ('貝', 154, 1), ('目', 109, 1), ('八', 12, 1)])
        self.assertEqual(components['森'], [('木', 75, 3)])
        self.assertEqual(components['佳'], [('亻', 9, 1), ('土', 32, 2)])
        self.assertEqual(components['王'], [('王', 96, 1)])
        self.assertEqual(components['縁'], [('糸', 120, 1), ('彑', 58, 1), ('⺕', 58, 1)])

        by_character = {chr(row['kanji_id']): row['tree'] for row in trees}
        self.assertEqual(self.forms(by_character['員']), ['口', '貝'])
        self.assertEqual(by_character['員']['children'][1]['children'], [])

    def test_partial_metadata_does_not_override_radical(self):
        svg = ET.fromstring('''<svg xmlns="http://www.w3.org/2000/svg" xmlns:kvg="http://kanjivg.tagaini.net">
          <g id="StrokePaths"><g id="root" kvg:element="想">
            <g id="a" kvg:element="木" kvg:partial="true"><path id="s1"/></g>
            <path id="s2"/>
          </g></g></svg>''')
        tree = extract(svg, {'木': 75}, {75: 'Mộc'}, {'stops': []})
        self.assertEqual(tree['children'][0]['kind'], 'radical')
        self.assertEqual(tree['children'][0]['radical_id'], 75)
        self.assertTrue(tree['children'][0]['source_partial'])

    def test_taxonomy_and_variants(self):
        from taxonomy import classify, dictionary, radical_catalog
        _, forms = radical_catalog()
        joyo = {e.findtext('literal') for e in dictionary()}
        self.assertEqual(classify('儿', '儿', '八', forms, joyo), ('radical', 10))
        self.assertEqual(classify('耂', '耂', '老', forms, joyo), ('radical', 125))
        self.assertEqual(classify('⺍', '⺍', None, forms, joyo), ('radical', 42))
        self.assertEqual(classify('?', '冫', '水', forms, joyo), ('radical', 15))
        self.assertEqual(classify('?', '?', '卩', forms, joyo), ('radical', 26))
        self.assertEqual(classify('王', '王', '玉', forms, joyo), ('radical', 96))
        self.assertEqual(classify('良', '良', None, forms, joyo), ('kanji', None))
        self.assertEqual(self.forms(self.trees['孝']), ['耂', '子'])
        self.assertEqual(self.trees['孝']['children'][0]['radical_name'], 'Lão')
        self.assertEqual(self.forms(self.trees['座']), ['广', '人', '人', '土'])
        humans = self.trees['座']['children'][1:3]
        self.assertNotEqual(humans[0]['id'], humans[1]['id'])
        self.assertFalse(set(humans[0]['stroke_ids']) & set(humans[1]['stroke_ids']))
        self.assertEqual(self.trees['王']['kind'], 'radical')
        self.assertEqual(self.trees['良']['kind'], 'kanji')

    def test_ambiguous_parts_rejected(self):
        svg = ET.fromstring('''<svg xmlns="http://www.w3.org/2000/svg" xmlns:kvg="http://kanjivg.tagaini.net">
          <g id="StrokePaths"><g id="root" kvg:element="想">
            <g id="a" kvg:element="木" kvg:part="1"><path id="s1"/></g>
            <g id="b" kvg:element="木" kvg:part="1"><path id="s2"/></g>
          </g></g></svg>''')
        with self.assertRaisesRegex(ValueError, 'ambiguous parts'):
            extract(svg, {'木': 75}, {75: 'Mộc'}, {'stops': []})


if __name__ == '__main__':
    unittest.main()
