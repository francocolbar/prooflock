"""Cross-checks tests/big_smoke.bend against Python ints. Run: py -3.14 tests/run_big_smoke.py"""
import os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
BEND = ["bash", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "env", "bend.sh")]
r = subprocess.run(BEND + ["big_smoke.bend"], cwd=HERE, env=dict(os.environ, BEND_NO_TELEMETRY="1"), capture_output=True, text=True)
if r.returncode != 0:
    sys.exit(r.stdout + r.stderr)
def bits(s):  # LSB first
    return sum(int(ch) << i for i, ch in enumerate(s))
got = {}
for line in r.stdout.strip().splitlines():
    parts = line.split()
    got[" ".join(parts[:-1]) if len(parts) > 2 else parts[0]] = parts[-1]
want = {
    "13": lambda v: bits(v) == 13, "13+29": lambda v: bits(v) == 42, "255+1": lambda v: bits(v) == 256,
    "0+7": lambda v: bits(v) == 7, "7+0": lambda v: bits(v) == 7, "inc 15": lambda v: bits(v) == 16,
    "parse 1011": lambda v: v == "13", "to_nat 200": lambda v: v == "200",
    "z 5+-8": lambda v: v == "-3", "z -3*7": lambda v: v == "-21", "z 3*-7": lambda v: v == "-21",
    "z 0*-7": lambda v: v == "0", "z neg -9": lambda v: v == "9",
    "show 5+-8": lambda v: bits(v.split("/")[0]) - bits(v.split("/")[1]) == -3,
}
bad = [k for k, f in want.items() if k not in got or not f(got[k])]
for k in want:
    print(f"{'OK ' if k not in bad else 'BAD'} {k:12} {got.get(k)}")
sys.exit(1 if bad else 0)
