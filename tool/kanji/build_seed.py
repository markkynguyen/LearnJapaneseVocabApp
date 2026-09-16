"""Download pinned dictionaries, validate and deterministically generate SQL.

Python standard library only. Run from the project root. Generated outputs may
be regenerated; editorial changes belong in curated_vi.json / radicals.tsv.
"""
import hashlib
import json
from pathlib import Path
import urllib.request

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



if __name__ == '__main__':
    from build_taxonomy import main as generate
    generate()
