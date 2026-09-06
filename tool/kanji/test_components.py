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
            '機': [('木', [1, 2, 3, 4]), ('幺', [5, 6, 7]), ('幺', [8, 9, 10]), ('戌', [11, 12, 13, 14, 15, 16])],
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

    def test_exceptions_are_not_radicals(self):
        row = self.characters['機'][-1]
        self.assertEqual((row['source_element'], row['source_original']), ('戍', '戌'))
        self.assertIsNone(row['radical_id'])
        self.assertIsNone(self.characters['学'][0]['radical_id'])

    def test_deterministic_and_complete(self):
        self.assertEqual(len(self.characters), 2136)
        self.assertEqual(build()[0], self.rows)
        for char, rows in self.characters.items():
            self.assertTrue(rows, char)
            self.assertEqual(len({r['occurrence_id'] for r in rows}), len(rows), char)
            ids = [s for r in rows for s in r['stroke_ids']]
            self.assertEqual(len(set(ids)), len(ids), char)

    def test_ambiguous_parts_fail_closed(self):
        root = ET.fromstring('''<svg xmlns="http://www.w3.org/2000/svg" xmlns:kvg="http://kanjivg.tagaini.net">
          <g id="StrokePaths"><g id="root" kvg:element="森">
            <g id="a" kvg:element="木" kvg:part="1"><path id="s1"/></g>
            <g id="b" kvg:element="木" kvg:part="1"><path id="s2"/></g>
          </g></g></svg>''')
        with self.assertRaisesRegex(ValueError, 'ambiguous parts'):
            extract(root, {'木': 75}, {'stops': []})

    def test_parts_from_different_contexts_require_explicit_override(self):
        root = ET.fromstring('''<svg xmlns="http://www.w3.org/2000/svg" xmlns:kvg="http://kanjivg.tagaini.net">
          <g id="StrokePaths"><g id="root" kvg:element="仮">
            <g id="left" kvg:element="甲"><g id="a" kvg:element="木" kvg:part="1"><path id="s1"/></g></g>
            <g id="right" kvg:element="乙"><g id="b" kvg:element="木" kvg:part="2"><path id="s2"/></g></g>
          </g></g></svg>''')
        with self.assertRaisesRegex(ValueError, 'tree contexts'):
            extract(root, {'木': 75}, {'stops': []})


if __name__ == '__main__':
    unittest.main()
