"""Run every mod Lua file through a real Lua runtime: syntax check plus all test_*.lua suites.

Needs the `lupa` package (`pip install lupa`). A workspace-local copy in .tools/python is used
when present. These tests mock the Unreal API; they do not start the game.
"""
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
local = root / '.tools/python'
if local.exists():
    sys.path.insert(0, str(local))
try:
    from lupa import LuaRuntime
except ImportError:
    sys.exit('lupa is not installed: run  pip install lupa')

scripts = root / 'mod/BodycamOutbreak/Scripts'
files = sorted(scripts.glob('*.lua'))
for path in files:
    LuaRuntime().execute('assert(loadfile(...))', path.as_posix())
total = 0
for path in files:
    if path.name.startswith('test_'):
        count = LuaRuntime(unpack_returned_tuples=True).execute('return dofile(...)', path.as_posix())
        print(f'PASS {path.stem}: {count} assertions')
        total += count
print(f'PASS {total} assertions; {len(files)} files syntax-checked. Unreal/gameplay not tested.')
