"""Prepare a static Godot export; generated engine files remain out of source Git."""
import argparse
import gzip
import shutil
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('export_dir', type=Path)
args = parser.parse_args()
root = args.export_dir
wasm = root / 'index.wasm'
if not wasm.exists():
    raise SystemExit('Export the Web preset to index.html first')
raw = wasm.read_bytes()
compressed = gzip.compress(raw, compresslevel=9, mtime=0)
(root / 'index.wasm.gz').write_bytes(compressed)
assert gzip.decompress(compressed) == raw
wasm.unlink()
shutil.copyfile(Path(__file__).with_name('wasm-loader.js'), root / 'wasm-loader.js')
(root / '_headers').write_text('/*\n  Cache-Control: no-cache\n')
assert (root / 'index.html').exists() and (root / 'index.pck').stat().st_size > 1000
for file in root.iterdir():
    if file.is_file() and file.stat().st_size > 25 * 1024 * 1024:
        raise SystemExit(f'Static asset exceeds hosting limit: {file.name}')
print(f'Web export prepared: engine {len(raw):,} bytes compressed to {len(compressed):,} bytes')
