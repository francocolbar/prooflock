"""Checks tests/big_test.bend against Python ints. Run: py -3.14 tests/run_big_test.py"""
import os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
BEND = ["bash", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "env", "bend.sh")]
out = subprocess.run(BEND + ["big_test.bend"], cwd=HERE, env=dict(os.environ, BEND_NO_TELEMETRY="1"), capture_output=True, text=True)
if out.returncode != 0:
    sys.exit(out.stdout + out.stderr)
def val(limbs):
    return sum(int(l) << (16 * i) for i, l in enumerate(t for t in limbs.split(":") if t))
got = {}
for line in out.stdout.strip().splitlines():
    name, limbs = line.split()
    got[name] = val(limbs)
a = 2**32 - 1
b = 4000000000 * 65536
want = {"a": a, "b": b, "a+b": a + b, "a*b": a * b, "b*b": b * b, "b*b*b": b * b * b, "a*3": a * 3, "0+a": a, "a+0": a}
bad = [k for k in want if got.get(k) != want[k]]
for k in want:
    print(f"{'OK ' if k not in bad else 'BAD'} {k:6} = {got.get(k)}")
sys.exit(1 if bad else 0)
