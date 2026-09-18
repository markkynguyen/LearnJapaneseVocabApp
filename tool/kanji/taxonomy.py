"""Single, source-only taxonomy for all Kanji generators (never read caches)."""
import gzip
import hashlib
import json
import xml.etree.ElementTree as ET

from build_seed import HERE

S = '{http://www.w3.org/2000/svg}'
K = '{http://kanjivg.tagaini.net}'
STRUCTURE_VERSION = 3
COMPONENT_VERSION = 3
STATISTICS_VERSION = 4


def dictionary():
    data = (HERE/'sources/kanjidic2.xml.gz').read_bytes()
    lock = json.loads((HERE/'sources.lock.json').read_text(encoding='utf-8'))
    assert hashlib.sha256(data).hexdigest() == lock['kanjidic2.xml.gz']['sha256']
    entries = [e for e in ET.fromstring(gzip.decompress(data)).findall('character')
               if int(e.findtext('misc/grade') or 0) in (1, 2, 3, 4, 5, 6, 8)]
    assert len(entries) == len({e.findtext('literal') for e in entries}) == 2136
    return entries


def radical_catalog():
    rows, forms = [], {}
    for line in (HERE/'radicals.tsv').read_text(encoding='utf-8').splitlines():
        if not line or line.startswith('#'):
            continue
        rid, char, name, meaning, count, variants = line.split('\t')
        rows.append(dict(id=int(rid), character=char, name_vi=name,
                         meaning_vi=meaning, stroke_count=int(count),
                         variants=list(variants), positions=[]))
        for form in char + variants:
            assert form not in forms, f'Ambiguous radical form: {form}'
            forms[form] = int(rid)
    assert [r['id'] for r in rows] == list(range(1, 215))
    # Explicit product rule; no semantic original may override a matched form.
    forms['⺍'] = forms['小']
    if '⺍' not in rows[forms['小']-1]['variants']:
        rows[forms['小']-1]['variants'].append('⺍')
    return rows, forms


def classify(display, element, original, forms, joyo):
    for candidate in (display, element, original):
        if candidate in forms:
            return 'radical', forms[candidate]
    if display in joyo:
        return 'kanji', None
    return 'supplementary', None
