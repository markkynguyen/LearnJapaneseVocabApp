"""Fetch the pinned standalone PostgreSQL/WASM test engine, not production data."""
import hashlib
from pathlib import Path
import tarfile
import urllib.request

cache = Path(__file__).resolve().parent / '.cache'
cache.mkdir(exist_ok=True)
target = cache / 'pglite.tgz'
if not target.exists():
    urllib.request.urlretrieve('https://registry.npmjs.org/@electric-sql/pglite/-/pglite-0.3.14.tgz', target)
assert hashlib.sha1(target.read_bytes()).hexdigest() == 'ea464c0bc52435ceba710d3ebd33917e91d893cf'
with tarfile.open(target) as archive:
    archive.extractall(cache, filter='data')
print('PGlite ready. Run: node tool/kanji/test_database.mjs')
