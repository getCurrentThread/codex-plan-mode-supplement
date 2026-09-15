"""Counts source lines and writes a summary to .cache/check.txt. Touches no tracked file."""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

lines = sum(len(p.read_text(encoding='utf-8').splitlines()) for p in (ROOT / 'src').glob('*.py'))
out = ROOT / '.cache' / 'check.txt'
out.parent.mkdir(exist_ok=True)
out.write_text(f'source lines: {lines}\n', encoding='utf-8')
print('check ok')
