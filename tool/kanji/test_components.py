"""Pinned-corpus and stop/part regression tests. Run from the repo root."""
import unittest
import xml.etree.ElementTree as ET

from build_components import build, extract


class ComponentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows, cls.characters = build()

    def test_locked_examples(self):
        examples = {
            '機': [('木', [1, 2, 3, 4]), ('幺', [5, 6, 7]), ('幺', [8, 9, 10]), ('戈', [11, 14, 15, 16]), ('人', [12, 13])],
            '何': [('亻', [1, 2]), ('一', [3]), ('口', [4, 5, 6]), ('亅', [7])],
            '学': [('⺍', [1, 2, 3]), ('冖', [4, 5]), ('子', [6, 7, 8])],
            '森': [('木', [1, 2, 3, 4]), ('木', [5, 6, 7, 8]), ('木', [9, 10, 11, 12])],
            '国': [('囗', [1, 2, 8]), ('玉', [3, 4, 5, 6, 7])],
            '基': [('甘', [1, 2, 3, 4, 5]), (None, [6]), ('八', [7, 8]), ('土', [9, 10, 11])],
            '木': [('木', [1, 2, 3, 4])],
        }
        for char, expected in examples.items():
            with self.subTest(char=char):
                actual = [(r['display_form'], [int(s.rsplit('-s', 1)[1]) for s in r['stroke_ids']]) for r in self.characters[char]]
                self.assertEqual(actual, expected)

    def test_expected_radical_classification(self):
        row = self.characters['機'][3]
        self.assertEqual((row['source_element'], row['source_original']), ('戈', None))
        self.assertEqual(row['radical_id'], 62)
        self.assertEqual(self.characters['学'][0]['radical_id'], 42)

    def test_original_xu_no_longer_hides_the_halberd_radical(self):
        affected = '威幾感憾機減歳蔑滅'
        for char in affected:
            with self.subTest(char=char):
                forms = [row['display_form'] for row in self.characters[char]]
                self.assertNotIn('戌', forms)
        for char in '威幾感憾機減蔑滅':
            with self.subTest(char=char):
                self.assertIn(
                    ('戈', 62),
                    [
                        (row['display_form'], row['radical_id'])
                        for row in self.characters[char]
                    ],
                )

    def test_deterministic_and_complete(self):
        self.assertEqual(len(self.characters), 2136)
        self.assertEqual(build()[0], self.rows)
        for char, rows in self.characters.items():
            self.assertTrue(rows, char)
            self.assertEqual(len({r['occurrence_id'] for r in rows}), len(rows), char)
            ids = [s for r in rows for s in r['stroke_ids']]
            self.assertEqual(len(set(ids)), len(ids), char)

    def test_sort_order_tracks_each_component_first_stroke(self):
        for char, rows in self.characters.items():
            with self.subTest(char=char):
                first_strokes = [
                    int(row['stroke_ids'][0].rsplit('-s', 1)[1])
                    for row in rows
                ]
                self.assertEqual(first_strokes, sorted(first_strokes))
                self.assertEqual(
                    [row['sort_order'] for row in rows],
                    list(range(len(rows))),
                )

        # 囗 is drawn at s1, s2, then s8; it must remain before 玉,
        # which is completed earlier but begins at s3.
        self.assertEqual(
            [row['display_form'] for row in self.characters['国']],
            ['囗', '玉'],
        )
        self.assertEqual(
            [
                int(row['stroke_ids'][0].rsplit('-s', 1)[1])
                for row in self.characters['国']
            ],
            [1, 3],
        )

    def test_interleaved_component_strokes_sort_by_first_stroke(self):
        root = ET.fromstring('''<svg xmlns="http://www.w3.org/2000/svg" xmlns:kvg="http://kanjivg.tagaini.net">
          <g id="StrokePaths"><g id="root" kvg:element="仮">
            <g id="wood-1" kvg:element="木" kvg:part="1"><path id="example-s1"/></g>
            <g id="mouth" kvg:element="口"><path id="example-s2"/><path id="example-s3"/></g>
            <g id="wood-2" kvg:element="木" kvg:part="2"><path id="example-s4"/></g>
          </g></g></svg>''')
        rows = extract(root, {'木': 75, '口': 30}, {'stops': []})

        self.assertEqual(
            [(row['display_form'], row['sort_order']) for row in rows],
            [('木', 0), ('口', 1)],
        )
        self.assertEqual(
            [[int(s.rsplit('-s', 1)[1]) for s in row['stroke_ids']] for row in rows],
            [[1, 4], [2, 3]],
        )

    def test_ambiguous_parts_fail_closed(self):
        root = ET.fromstring('''<svg xmlns="http://www.w3.org/2000/svg" xmlns:kvg="http://kanjivg.tagaini.net">
          <g id="StrokePaths"><g id="root" kvg:element="森">
            <g id="a" kvg:element="木" kvg:part="1"><path id="s1"/></g>
            <g id="b" kvg:element="木" kvg:part="1"><path id="s2"/></g>
          </g></g></svg>''')
        with self.assertRaisesRegex(ValueError, 'ambiguous parts'):
            extract(root, {'木': 75}, {'stops': []})

    def test_parts_from_different_contexts_are_not_merged(self):
        root = ET.fromstring('''<svg xmlns="http://www.w3.org/2000/svg" xmlns:kvg="http://kanjivg.tagaini.net">
          <g id="StrokePaths"><g id="root" kvg:element="仮">
            <g id="left" kvg:element="甲"><g id="a" kvg:element="木" kvg:part="1"><path id="s1"/></g></g>
            <g id="right" kvg:element="乙"><g id="b" kvg:element="木" kvg:part="2"><path id="s2"/></g></g>
          </g></g></svg>''')
        rows = extract(root, {'木': 75}, {'stops': []})
        self.assertEqual([r['stroke_ids'] for r in rows], [['s1'], ['s2']])
        self.assertTrue(all(r['radical_id'] is None for r in rows))


if __name__ == '__main__':
    unittest.main()
