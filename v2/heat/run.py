"""run.py (v2) - drives the Phase 1 v2 PoC end to end.

  symbolic (Bend, Z)  ->  generated (kernel_<p>_<q>.py)  ->  numeric (JAX float64 / float32)
                      ->  exact oracle (Bend, big integers)  ->  compared (Python Fraction)

Gates run first: every PROOF file must print "All terms check." and the negative test
(tests/cfl_violation_PROOF.bend) must be REJECTED. Two schemes (r = 1/4 and r = 3/8) and
two horizons (13 and 200 steps). Usage: py -3.14 bend-spike/v2/heat/run.py
Writes: kernel_*.py (generated), results.json.
"""
import json
import math
import os
import subprocess
import sys
import time
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))
V2 = os.path.dirname(HERE)
BEND = ["bash", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "env", "bend.sh")]
TIMES = {}

M = 21                       # bits of the initial condition: round(sin(pi x) 2^M) / 2^M, exact in float64
NX = 10                      # grid points including the two Dirichlet boundaries
ALPHA = 1.0
SCHEMES = [(1, 2), (3, 3)]   # r = p / 2^q : 1/4 and 3/8
STEPS = [13, 200]

PROOFS = ["num/PROOF_Z_ADD.bend", "num/PROOF_Z_MUL.bend", "num/PROOF_BIG.bend", "num/PROOF_BIGZ.bend",
          "heat/PROOF_HEAT.bend", "heat/PROOF_ORACLE.bend"]
SMOKES = ["tests/laws_z_smoke.bend", "tests/laws_heat_smoke.bend"]


def bend(rel, env=None, cwd=None):
    e = dict(os.environ, BEND_NO_TELEMETRY="1")
    e.update(env or {})
    t0 = time.perf_counter()
    r = subprocess.run(BEND + [os.path.basename(rel)], cwd=cwd or os.path.join(V2, os.path.dirname(rel)),
                       env=e, capture_output=True, text=True)
    TIMES[rel] = round(TIMES.get(rel, 0.0) + time.perf_counter() - t0, 2)
    return r.returncode, r.stdout, r.stderr


def bits(s):
    return sum(int(ch) << i for i, ch in enumerate(s))


def to_bits(n):
    return "0" if n == 0 else "".join("1" if (n >> i) & 1 else "0" for i in range(n.bit_length()))


def main():
    results = {"M": M, "NX": NX, "alpha": ALPHA, "gates": {}, "runs": []}
    ok_all = True

    # 0. gates: proofs must check, smoke grids must be all-ok, the negative test must fail
    for rel in PROOFS:
        code, out, err = bend(rel)
        last = (out.strip().splitlines() or [""])[-1]
        passed = os.path.exists(os.path.join(V2, rel)) and "All terms check." in out
        results["gates"][rel] = last if os.path.exists(os.path.join(V2, rel)) else "MISSING"
        ok_all &= passed
        print(f"[gate] {rel:28} -> {results['gates'][rel]}")
    for rel in SMOKES:
        code, out, err = bend(rel)
        passed = code == 0 and "ok" in out and not any(ln.startswith("FALSE") for ln in out.splitlines())
        results["gates"][rel] = "all ok" if passed else out.strip()[-300:]
        ok_all &= passed
        print(f"[gate] {rel:28} -> {results['gates'][rel]}")
    code, out, err = bend("tests/cfl_violation_PROOF.bend")
    rejected = code != 0 and "True{}" in (out + err) and "False{}" in (out + err)
    results["gates"]["tests/cfl_violation_PROOF.bend"] = "REJECTED (as it must be)" if rejected else f"NOT rejected: exit {code}"
    ok_all &= rejected
    print(f"[gate] tests/cfl_violation_PROOF.bend -> {results['gates']['tests/cfl_violation_PROOF.bend']}")

    # initial condition: sin(pi x) quantized to 2^-M, boundaries 0 (exact in float64)
    dx = 1.0 / (NX - 1)
    xs = [i * dx for i in range(NX)]
    ic_num = [round(math.sin(math.pi * x) * 2 ** M) for x in xs]
    ic_num[0] = 0
    ic_num[-1] = 0
    ic_exact = [Fraction(n, 2 ** M) for n in ic_num]
    ic_bits = ",".join(to_bits(n) for n in ic_num)

    sys.path.insert(0, HERE)
    import jax  # noqa: E402
    import jax.numpy as jnp  # noqa: E402
    import importlib  # noqa: E402

    for (p, q) in SCHEMES:
        d = 2 ** q
        r = Fraction(p, d)
        env = {"BEND_P": str(p), "BEND_Q": str(q)}
        # 1. symbolic -> generated
        code, src, err = bend("heat/emit.bend", env)
        if code != 0:
            sys.exit(f"emit failed: {src}{err}")
        name = f"kernel_{p}_{q}"
        with open(os.path.join(HERE, name + ".py"), "w", encoding="utf-8", newline="\n") as f:
            f.write(src)
        kernel = importlib.import_module(name)
        # exact reference in Python for the same scheme (an independent check of the Bend oracle)
        w = [Fraction(p), Fraction(d - 2 * p), Fraction(p)]
        for n_steps in STEPS:
            u64 = jnp.array([float(v) for v in ic_exact], dtype=jnp.float64)
            u32 = jnp.array([float(v) for v in ic_exact], dtype=jnp.float32)
            for _ in range(n_steps):
                u64 = kernel.step(u64)
                u32 = kernel.step(u32)
            u64, u32 = u64.tolist(), u32.tolist()
            # 4. exact oracle (Bend, big integers, RAW tree)
            code, out, err = bend("heat/oracle.bend", dict(env, BEND_IC=ic_bits, BEND_N=str(n_steps)))
            if code != 0:
                sys.exit(f"oracle failed: {out}{err}")
            lines = out.strip().splitlines()
            _, pp, dd = lines[0].split()
            assert (int(pp), int(dd)) == (p, d)
            nums = [bits(tok.split("/")[0]) - bits(tok.split("/")[1]) for tok in lines[1].split()]
            assert len(nums) == NX
            exact = [Fraction(n, 2 ** M * d ** n_steps) for n in nums]
            # independent Python Fraction reference
            ref = list(ic_exact)
            for _ in range(n_steps):
                inner = [(w[0] * ref[i - 1] + w[1] * ref[i] + w[2] * ref[i + 1]) / d for i in range(1, NX - 1)]
                ref = [ref[0]] + inner + [ref[-1]]
            oracle_matches_python = (ref == exact)
            # 5. compare
            dt = float(r) * dx * dx / ALPHA
            t = n_steps * dt
            analytic = [math.exp(-ALPHA * math.pi ** 2 * t) * math.sin(math.pi * x) for x in xs]
            g = 1.0 - 4.0 * float(r) * math.sin(math.pi * dx / 2) ** 2
            discrete = [g ** n_steps * math.sin(math.pi * x) for x in xs]
            umax = max(abs(v) for v in exact)
            e64 = max(abs(Fraction(x) - y) for x, y in zip(u64, exact))
            e32 = max(abs(Fraction(x) - y) for x, y in zip(u32, exact))
            run = {
                "p": p, "q": q, "r": str(r), "N": n_steps, "t": t, "decay": math.exp(-math.pi ** 2 * t),
                "max_numerator_bits": max(abs(n) for n in nums).bit_length(),
                "oracle_matches_python_fraction": oracle_matches_python,
                "err_jax64_vs_exact": float(e64), "rel_jax64_vs_exact": float(e64 / umax),
                "err_jax32_vs_exact": float(e32), "rel_jax32_vs_exact": float(e32 / umax),
                "N_eps64": n_steps * 2.0 ** -52, "N_eps32": n_steps * 2.0 ** -23,
                "err_jax64_vs_analytic": max(abs(x - y) for x, y in zip(u64, analytic)),
                "err_exact_vs_analytic": max(abs(float(x) - y) for x, y in zip(exact, analytic)),
                "err_exact_vs_discrete_closed_form": max(abs(float(x) - y) for x, y in zip(exact, discrete)),
                "max_u": float(umax),
            }
            ok_all &= oracle_matches_python
            results["runs"].append(run)
            print(f"[run] r = {r}, N = {n_steps:3}, t = {t:.3f}, max|u| = {run['max_u']:.2e}, numerators {run['max_numerator_bits']} bits, "
                  f"oracle == Fraction: {oracle_matches_python}")
            print(f"      f64 vs exact {run['err_jax64_vs_exact']:.2e} (rel {run['rel_jax64_vs_exact']:.1e}, N*eps {run['N_eps64']:.1e}) | "
                  f"f32 vs exact {run['err_jax32_vs_exact']:.2e} (rel {run['rel_jax32_vs_exact']:.1e}) | "
                  f"vs analytic f64 {run['err_jax64_vs_analytic']:.2e} exact {run['err_exact_vs_analytic']:.2e} | "
                  f"exact vs closed form {run['err_exact_vs_discrete_closed_form']:.1e}")

    results["bend_seconds"] = TIMES
    results["all_gates_and_checks_ok"] = bool(ok_all)
    with open(os.path.join(HERE, "results.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"[done] all gates and checks ok: {ok_all}; seconds per bend file: {TIMES}")
    sys.exit(0 if ok_all else 1)


if __name__ == "__main__":
    main()
