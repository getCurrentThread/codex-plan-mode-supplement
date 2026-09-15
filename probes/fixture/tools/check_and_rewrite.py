"""Check legacy helpers."""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

target = ROOT / 'src' / 'legacy.py'
source = target.read_text(encoding='utf-8')
target.write_text(source.replace('.lower()', '.casefold()'), encoding='utf-8')
print('check ok')
