"""Download pinned dictionaries, validate and deterministically generate SQL.

Python standard library only. Run from the project root. Generated outputs may
be regenerated; editorial changes belong in curated_vi.json / radicals.tsv.
"""
import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path
import sys
import urllib.request
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
CACHE = HERE / '.cache'
OUT = ROOT / 'assets/kanji'
LOCK = HERE / 'sources.lock.json'
KVG_COMMIT = '55b5ba92a7cad78a62ef04db4be6f9562d949b7f'
KVG_NS = '{http://kanjivg.tagaini.net}'


def download(name, url, locks):
    CACHE.mkdir(exist_ok=True)
    target = HERE / 'sources' / name if name == 'kanjidic2.xml.gz' else CACHE / name
    target.parent.mkdir(exist_ok=True)
    if not target.exists() and (CACHE / name).exists():
        target.write_bytes((CACHE / name).read_bytes())
    if not target.exists():
        print(f'Downloading {name}...', flush=True)
        request = urllib.request.Request(url, headers={'User-Agent': 'JVocab-data-builder/1.0'})
        with urllib.request.urlopen(request, timeout=120) as response:
            target.write_bytes(response.read())
    data = target.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    old = locks.get(name)
    if old and old['sha256'] != digest:
        raise ValueError(f'{name}: checksum changed. Restore the locked snapshot or explicitly update the lock after review.')
    locks[name] = {'url': url, 'sha256': digest}
    return data


def sql(value):
    if value is None:
        return 'null'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, int):
        return str(value)
    if isinstance(value, list):
        return 'array[' + ','.join(sql(v) for v in value) + ']::text[]'
    return "'" + str(value).replace("'", "''") + "'"


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--validate-only', action='store_true')
    parser.add_argument('--release', action='store_true', help='Require human-approved Vietnamese data for all characters.')
    args = parser.parse_args()
    locks = json.loads(LOCK.read_text(encoding='utf-8')) if LOCK.exists() else {}
    kd = download('kanjidic2.xml.gz', 'https://www.edrdg.org/kanjidic/kanjidic2.xml.gz', locks)
    kvg = download('kanjivg.zip', f'https://codeload.github.com/KanjiVG/kanjivg/zip/{KVG_COMMIT}', locks)
    tree = ET.fromstring(gzip.decompress(kd))
    archive = zipfile.ZipFile(io.BytesIO(kvg))
    radicals = []
    form_map = {}
    for line in (HERE / 'radicals.tsv').read_text(encoding='utf-8').splitlines():
        if not line or line.startswith('#'):
            continue
        fields = line.split('\t')
        rid, char, name, meaning, strokes, variants = fields
        item = dict(id=int(rid), character=char, name_vi=name, meaning_vi=meaning,
                    stroke_count=int(strokes), variants=list(variants), positions=[])
        radicals.append(item)
        # Ambiguous forms (月/肉, 阝/邑/阜) are resolved by kvg:original.
        form_map.setdefault(char, int(rid))
        for form in variants:
            form_map.setdefault(form, int(rid))
    assert len(radicals) == 214 and [r['id'] for r in radicals] == list(range(1, 215))
    assert len({r['character'] for r in radicals}) == 214
    # Japanese modern forms representing canonical Kangxi radicals.
    for form, original in {'糸':'糸','糹':'糸','纟':'糸','言':'言','訁':'言','讠':'言','金':'金','釒':'金','钅':'金','飠':'食','饣':'食','見':'見','贝':'貝','车':'車','鱼':'魚','鸟':'鳥','竜':'龍','麦':'麥','黄':'黃','黒':'黑','歯':'齒','亀':'龜','青':'靑','斉':'齊','戸':'戶','艹':'艸','辶':'辵','礻':'示','衤':'衣','丬':'爿'}.items():
        if original in form_map:
            form_map[form] = form_map[original]
    curated = json.loads((HERE / 'curated_vi.json').read_text(encoding='utf-8'))
    translated = set()
    for line in (HERE / 'meanings_vi.tsv').read_text(encoding='utf-8').splitlines():
        if line and not line.startswith('#'):
            char, meaning = line.split('\t')
            assert char not in translated and len(char) == 1 and meaning.strip(), f'Invalid/duplicate translation: {char}'
            translated.add(char)
            curated.setdefault(char, {}).setdefault('meaning_vi', meaning)
    kanji = []
    components = []
    fallback_components = []
    missing_vi = []
    missing_hanviet = []
    for entry in tree.findall('character'):
        grade = int(entry.findtext('misc/grade') or 0)
        if grade not in (1, 2, 3, 4, 5, 6, 8):
            continue
        char = entry.findtext('literal')
        kid = ord(char)
        readings = entry.findall('reading_meaning/rmgroup/reading')
        words = entry.findall('reading_meaning/rmgroup/meaning')
        en = [w.text for w in words if not w.get('m_lang')]
        vi = curated.get(char, {})
        hanviet = vi.get('han_viet') or ' · '.join(r.text for r in readings if r.get('r_type') == 'vietnam')
        if not vi.get('meaning_vi'):
            missing_vi.append(char)
        if not hanviet:
            missing_hanviet.append(char)
        principal = int(next(r.text for r in entry.findall('radical/rad_value') if r.get('rad_type') == 'classical'))
        item = dict(id=kid, character=char, han_viet=hanviet or None,
                    onyomi=[r.text for r in readings if r.get('r_type') == 'ja_on'],
                    kunyomi=[r.text for r in readings if r.get('r_type') == 'ja_kun'],
                    meaning_vi=vi.get('meaning_vi'), meaning_en='; '.join(en),
                    stroke_count=int(entry.findtext('misc/stroke_count')),
                    grade=grade, primary_radical_id=principal,
                    translation_reviewed=vi.get('review_status') == 'approved')
        kanji.append(item)
        svg_name = f'kanjivg-{KVG_COMMIT}/kanji/{kid:05x}.svg'
        doc = ET.fromstring(archive.read(svg_name))
        found = {}
        for group in doc.iter('{http://www.w3.org/2000/svg}g'):
            form = group.get(KVG_NS + 'element')
            original = group.get(KVG_NS + 'original')
            rid = form_map.get(original) if original else form_map.get(form)
            # Exclude the whole character unless it itself is a radical.
            if not rid or not form or len(form) != 1:
                continue
            position = group.get(KVG_NS + 'position')
            label = {'left':'Trái','right':'Phải','top':'Trên','bottom':'Dưới',
                     'tare':'Trên và trái','nyou':'Dưới và trái','kamae':'Bao quanh'}.get(position)
            if label and label not in radicals[rid - 1]['positions']:
                radicals[rid - 1]['positions'].append(label)
            found.setdefault((rid, form), len(found))
        if not found:
            # Explicitly recorded fallback: only the dictionary radical is known.
            form = radicals[principal - 1]['character']
            found[(principal, form)] = 0
            fallback_components.append(char)
        for (rid, form), order in found.items():
            radical = radicals[rid - 1]
            if form != radical['character'] and form not in radical['variants']:
                radical['variants'].append(form)
            components.append(dict(kanji_id=kid, radical_id=rid, component_form=form, sort_order=order))
    kanji.sort(key=lambda k: k['id'])
    components.sort(key=lambda c: (c['kanji_id'], c['sort_order']))
    assert len(kanji) == 2136, f'Expected 2136 Joyo; got {len(kanji)}'
    assert len({k['id'] for k in kanji}) == 2136
    assert len({c['kanji_id'] for c in components}) == 2136
    for component in components:
        radical = radicals[component['radical_id'] - 1]
        assert component['component_form'] in [radical['character'], *radical['variants']]
    report = dict(kanji_count=len(kanji), radical_count=len(radicals), component_count=len(components),
                  kanjidic_date=tree.findtext('header/date_of_creation'),
                  missing_meaning_vi=missing_vi, missing_han_viet=missing_hanviet,
                  dictionary_radical_fallback=fallback_components,
                  approved_translations=sum(k['translation_reviewed'] for k in kanji),
                  review_note='Machine validation only. Human linguistic approval is tracked per character in curated_vi.json.')
    if args.release and (missing_vi or missing_hanviet or report['approved_translations'] != 2136):
        raise ValueError('Release gate failed: Vietnamese data requires complete human approval. See validation_report.json.')
    if not args.validate_only:
        write_json(LOCK, locks)
        write_json(OUT / 'sources.json', dict(kanjivg_commit=KVG_COMMIT, kanjidic_date=report['kanjidic_date'], sources=locks))
        write_json(HERE / 'validation_report.json', report)
        write_json(CACHE / 'catalog.json', dict(kanji=kanji, radicals=radicals, components=components))
        samples = {'休', '先', '生', '森', '都', '院', '月', '服', '𠮟', '剝', '鬱', '飛', '龍'}
        for grade in (1, 2, 3, 4, 5, 6, 8):
            batch = [k for k in kanji if k['grade'] == grade]
            samples.update(k['character'] for k in [*batch[:3], batch[len(batch)//2], batch[-1]])
        lines = ['# Mẫu kiểm duyệt học liệu', '',
                 'Sinh tự động, chưa phải biên bản duyệt của con người. Ghi kết quả theo ký tự trong `curated_vi.json`; không sửa trực tiếp bảng này.', '',
                 'Duyệt nghĩa theo cách dùng tiếng Nhật, âm Hán Việt, bộ chính và thành phần (đặc biệt 月/肉, 阝/邑/阜, dạng mới/cũ, ký tự ngoài BMP). Duyệt từng lô trong toàn bộ danh mục; các mẫu dưới đây chỉ là điểm bắt đầu.', '',
                 '| Chữ | Lớp | Hán Việt | Nghĩa nháp | Thành phần | Trạng thái |',
                 '|---|---|---|---|---|---|']
        for k in kanji:
            if k['character'] not in samples:
                continue
            forms = ' '.join(f"{c['component_form']}→{radicals[c['radical_id']-1]['character']}" for c in components if c['kanji_id'] == k['id'])
            status = 'Đã duyệt' if k['translation_reviewed'] else 'Chờ người duyệt'
            lines.append(f"| {k['character']} | {k['grade']} | {k['han_viet']} | {k['meaning_vi']} | {forms} | {status} |")
        (HERE / 'review_samples.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
        status = 'REVIEWED' if report['approved_translations'] == 2136 else 'DRAFT: human linguistic review is pending; not approved for production release.'
        statements = ['-- Generated by tool/kanji/build_seed.py. Data licences: assets/kanji/ATTRIBUTION.md.', f'-- {status}', 'begin;']
        for table, rows in [('radicals', radicals), ('kanji', kanji), ('kanji_components', components)]:
            columns = list(rows[0])
            keys = ['kanji_id','radical_id','component_form'] if table == 'kanji_components' else ['id']
            for start in range(0, len(rows), 250):
                values = ',\n'.join('(' + ','.join(sql(row[col]) for col in columns) + ')' for row in rows[start:start+250])
                updates = ','.join(f'{col}=excluded.{col}' for col in columns if col not in keys)
                statements.append(f"insert into public.{table} ({','.join(columns)}) values\n{values}\non conflict ({','.join(keys)}) do update set {updates};")
        statements.append('commit;\n')
        (ROOT / 'supabase/migrations/202609050003_seed_kanji_catalog.sql').write_text('\n\n'.join(statements), encoding='utf-8')
    print(json.dumps({key: value if not isinstance(value, list) else len(value) for key, value in report.items()}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
