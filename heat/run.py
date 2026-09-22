"""run.py - drives the Phase 1 PoC end to end.

  symbolic (Bend)  ->  generated (kernel_heat.py)  ->  numeric (JAX float64)  ->  verified
                                                        exact oracle (Bend, Nat)  ->  compared

Usage:  py -3.14 bend-spike/heat/run.py            (from anywhere; needs bun + ~/.bend-src)
Writes: kernel_heat.py (generated), results.json (numbers quoted in docs/phase1-findings.md)
"""
import json
import math
import os
import subprocess
import sys
import time
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))
TIMES = {}   # seconds spent in each bend invocation (bun startup + check + run)
BEND = ["bash", os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "env", "bend.sh")]

M = 21          # bits of the initial condition: u_i(0) = round(sin(pi x_i) * 2^M) / 2^M, exact in float64
N = 13          # time steps: M + N * log2(D) must stay below 48 (Nat limit of Bend's runtime)
N_BIG = 200     # time steps for the plan-B oracle (big.bend numerators, no 48-bit cap)
NX = 10         # grid points including the two Dirichlet boundaries
ALPHA = 1.0


def bend(file, env=None, check=True):
    e = dict(os.environ, BEND_NO_TELEMETRY="1")
    e.update(env or {})
    t0 = time.perf_counter()
    r = subprocess.run(BEND + [file], cwd=HERE, env=e, capture_output=True, text=True)
    TIMES[file] = TIMES.get(file, 0.0) + time.perf_counter() - t0
    if check and r.returncode != 0:
        sys.exit(f"bend {file} failed (exit {r.returncode}):\n{r.stdout}\n{r.stderr}")
    return r.stdout


def main():
    results = {"M": M, "N": N, "NX": NX, "alpha": ALPHA}

    # 0. the proofs are the gate
    proof = bend("PROOF.bend", check=False)
    results["proof"] = proof.strip().splitlines()[-1] if proof.strip() else ""
    print(f"[0] bend PROOF.bend -> {results['proof']}")

    # 1. symbolic -> generated: Bend prints the kernel module to stdout
    src = bend("emit.bend")
    kernel_path = os.path.join(HERE, "kernel_heat.py")
    with open(kernel_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(src)
    print(f"[1] emitted {os.path.relpath(kernel_path, HERE)} ({len(src.splitlines())} lines)")

    # 2. initial condition: sin(pi x) quantized to 2^-M, boundaries 0 (exactly representable in float64)
    dx = 1.0 / (NX - 1)
    xs = [i * dx for i in range(NX)]
    ic_num = [round(math.sin(math.pi * x) * 2 ** M) for x in xs]
    ic_num[0] = 0
    ic_num[-1] = 0
    ic_exact = [Fraction(n, 2 ** M) for n in ic_num]

    # 3. numeric: run the generated kernel in JAX float64 (and float32, for contrast)
    sys.path.insert(0, HERE)
    import jax  # noqa: E402
    import jax.numpy as jnp  # noqa: E402
    import kernel_heat  # noqa: E402  (the file Bend just wrote)

    u64 = jnp.array([float(v) for v in ic_exact], dtype=jnp.float64)
    assert all(Fraction(float(a)) == b for a, b in zip(u64.tolist(), ic_exact)), "IC not exact in float64"
    u32 = jnp.array([float(v) for v in ic_exact], dtype=jnp.float32)
    for _ in range(N):
        u64 = kernel_heat.step(u64)
        u32 = kernel_heat.step(u32)
    assert u64.dtype == jnp.float64 and u32.dtype == jnp.float32
    u64 = u64.tolist()
    u32 = u32.tolist()
    print(f"[2] JAX ran {N} steps in float64 and float32 (jax {jax.__version__})")

    # 4. exact oracle: the same scheme over Nat numerators
    out = bend("oracle.bend", {"BEND_IC": ",".join(map(str, ic_num)), "BEND_N": str(N)})
    lines = out.strip().splitlines()
    _, p, d = lines[0].split()
    p, d = int(p), int(d)
    nums = [int(t) for t in lines[1].split()]
    assert len(nums) == NX, f"oracle returned {len(nums)} values"
    assert max(nums) < 2 ** 48, "oracle numerators would overflow Bend's Nat"
    exact = [Fraction(n, 2 ** M * d ** N) for n in nums]
    r = Fraction(p, d)
    results["scheme"] = {"p": p, "D": d, "r": str(r), "max_numerator_bits": max(nums).bit_length()}
    print(f"[3] oracle: r = {r}, final numerators over 2^{M} * {d}^{N}; largest needs {max(nums).bit_length()} bits (< 48)")

    # 5. compare
    dt = float(r) * dx * dx / ALPHA
    t = N * dt
    analytic = [math.exp(-ALPHA * math.pi ** 2 * t) * math.sin(math.pi * x) for x in xs]
    # closed form of the DISCRETE scheme for the sin(pi x) mode (eigenvector of the discrete Laplacian):
    g = 1.0 - 4.0 * float(r) * math.sin(math.pi * dx / 2) ** 2
    discrete_mode = [g ** N * math.sin(math.pi * x) for x in xs]

    def maxabs(a, b):
        return max(abs(float(x) - float(y)) for x, y in zip(a, b))

    e_jax64_vs_exact = max(abs(Fraction(x) - y) for x, y in zip(u64, exact))
    e_jax32_vs_exact = max(abs(Fraction(x) - y) for x, y in zip(u32, exact))
    results.update({
        "dx": dx, "dt": dt, "t_final": t,
        "err_jax64_vs_exact": float(e_jax64_vs_exact),
        "err_jax32_vs_exact": float(e_jax32_vs_exact),
        "rel_jax64_vs_exact": float(e_jax64_vs_exact / max(abs(v) for v in exact)),
        "rel_jax32_vs_exact": float(e_jax32_vs_exact / max(abs(v) for v in exact)),
        "err_jax64_vs_analytic": maxabs(u64, analytic),
        "err_exact_vs_analytic": maxabs(exact, analytic),
        "err_exact_vs_discrete_mode": maxabs(exact, discrete_mode),
        "ic_quantization": 2.0 ** -(M + 1),
        "eps64_times_N": N * 2.0 ** -52,
        "eps32_times_N": N * 2.0 ** -23,
        "u_final_jax64": u64,
        "u_final_exact": [str(v) for v in exact],
    })
    print("[4] max abs errors over the grid after N steps:")
    print(f"    JAX float64 vs exact oracle      : {results['err_jax64_vs_exact']:.3e}  rel {results['rel_jax64_vs_exact']:.2e}  (N*eps64 = {results['eps64_times_N']:.1e})")
    print(f"    JAX float32 vs exact oracle      : {results['err_jax32_vs_exact']:.3e}  rel {results['rel_jax32_vs_exact']:.2e}  (N*eps32 = {results['eps32_times_N']:.1e})")
    print(f"    JAX float64 vs analytic          : {results['err_jax64_vs_analytic']:.3e}")
    print(f"    exact oracle vs analytic         : {results['err_exact_vs_analytic']:.3e}   (discretization error, O(dx^2)+O(dt))")
    print(f"    exact oracle vs discrete closed form: {results['err_exact_vs_discrete_mode']:.3e}   (IC quantization = {results['ic_quantization']:.1e})")
    print(f"    dx = {dx:.4f}, dt = {dt:.5f}, t = {t:.4f}, decay factor e^(-pi^2 t) = {math.exp(-math.pi**2*t):.4f}")

    # 6. plan B: the same circuit with the bignum oracle and many more steps
    u64b = jnp.array([float(v) for v in ic_exact], dtype=jnp.float64)
    u32b = jnp.array([float(v) for v in ic_exact], dtype=jnp.float32)
    for _ in range(N_BIG):
        u64b = kernel_heat.step(u64b)
        u32b = kernel_heat.step(u32b)
    u64b = u64b.tolist()
    u32b = u32b.tolist()
    out = bend("oracle_big.bend", {"BEND_IC": ",".join(map(str, ic_num)), "BEND_N": str(N_BIG)})
    lines = out.strip().splitlines()
    _, pb, db = lines[0].split()
    pb, db = int(pb), int(db)
    assert (pb, db) == (p, d)

    def limbs(dump):
        return sum(int(l) << (16 * i) for i, l in enumerate(t for t in dump.split(":") if t))

    nums_b = [limbs(tok) for tok in lines[1].split()]
    assert len(nums_b) == NX
    exact_b = [Fraction(n, 2 ** M * db ** N_BIG) for n in nums_b]
    # cross-check plan B against Python's own exact arithmetic (Fraction) on the same scheme
    py_exact = list(ic_exact)
    for _ in range(N_BIG):
        inner = [(py_exact[i - 1] + 2 * py_exact[i] + py_exact[i + 1]) / 4 for i in range(1, NX - 1)]
        py_exact = [py_exact[0]] + inner + [py_exact[-1]]
    assert py_exact == exact_b, "plan-B oracle disagrees with Python Fraction"
    tb = N_BIG * dt
    analytic_b = [math.exp(-ALPHA * math.pi ** 2 * tb) * math.sin(math.pi * x) for x in xs]
    discrete_b = [g ** N_BIG * math.sin(math.pi * x) for x in xs]
    e64b = max(abs(Fraction(x) - y) for x, y in zip(u64b, exact_b))
    e32b = max(abs(Fraction(x) - y) for x, y in zip(u32b, exact_b))
    results["planB"] = {
        "N": N_BIG, "t_final": tb, "max_numerator_bits": max(nums_b).bit_length(),
        "err_jax64_vs_exact": float(e64b), "err_jax32_vs_exact": float(e32b),
        "rel_jax64_vs_exact": float(e64b / max(abs(v) for v in exact_b)),
        "rel_jax32_vs_exact": float(e32b / max(abs(v) for v in exact_b)),
        "max_exact": float(max(abs(v) for v in exact_b)),
        "err_jax64_vs_analytic": maxabs(u64b, analytic_b), "err_exact_vs_analytic": maxabs(exact_b, analytic_b),
        "err_exact_vs_discrete_mode": maxabs(exact_b, discrete_b),
        "eps64_times_N": N_BIG * 2.0 ** -52, "eps32_times_N": N_BIG * 2.0 ** -23,
        "decay": math.exp(-math.pi ** 2 * tb), "python_fraction_agrees": True,
    }
    print(f"[6] plan B (big.bend oracle), N = {N_BIG}, t = {tb:.3f}, decay e^(-pi^2 t) = {results['planB']['decay']:.4f}, largest numerator {results['planB']['max_numerator_bits']} bits")
    print(f"    plan-B oracle == Python Fraction on the same scheme: True")
    print(f"    JAX float64 vs exact oracle      : {float(e64b):.3e}  rel {results['planB']['rel_jax64_vs_exact']:.2e}  (N*eps64 = {results['planB']['eps64_times_N']:.1e}; max|u| = {results['planB']['max_exact']:.2e})")
    print(f"    JAX float32 vs exact oracle      : {float(e32b):.3e}  rel {results['planB']['rel_jax32_vs_exact']:.2e}  (N*eps32 = {results['planB']['eps32_times_N']:.1e})")
    print(f"    JAX float64 vs analytic          : {results['planB']['err_jax64_vs_analytic']:.3e}")
    print(f"    exact oracle vs analytic         : {results['planB']['err_exact_vs_analytic']:.3e}")
    print(f"    exact oracle vs discrete closed form: {results['planB']['err_exact_vs_discrete_mode']:.3e}")

    results["bend_seconds"] = {k: round(v, 2) for k, v in TIMES.items()}
    print("[7] seconds per bend invocation (bun start + check + run): " + ", ".join(f"{k} {v:.1f}" for k, v in results["bend_seconds"].items()))
    with open(os.path.join(HERE, "results.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print("[8] wrote results.json")


if __name__ == "__main__":
    main()
