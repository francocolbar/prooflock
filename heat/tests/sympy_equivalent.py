"""sympy_equivalent.py - what the SAME pipeline looks like in plain Python + sympy + Fraction,
with NO proofs: symbolic stencil, simplification, kernel printing, exact oracle. Written only
to compare code size honestly with the Bend version (ir.bend + emit.bend + oracle_big.bend
+ big.bend, minus LAWS/PROOF which have no Python counterpart).
Run: py -3.14 tests/sympy_equivalent.py
"""
from fractions import Fraction
import sympy as sp

# --- the scheme: r = p / D with D = 2^q, weights [p, D - 2p, p] ---------------------------
p, q = 1, 2
D = 2 ** q
weights = [p, D - 2 * p, p]
assert sum(weights) == D                      # CFL / consistency check (a runtime assert, not a law)

# --- symbolic stencil (a naive tree, like stencil_go in ir.bend) ----------------------------
w = sp.symbols("w0 w1 w2")                    # the window u_{i-1}, u_i, u_{i+1}
raw = sp.Add(*[sp.Mul(sp.Integer(c), v, evaluate=False) for c, v in zip(weights, w)], sp.Integer(0), evaluate=False)
simplified = sp.simplify(raw)                 # sympy's simplifier: unspecified, unverified

# --- kernel printing --------------------------------------------------------------------
py_vars = {"w0": "u[:-2]", "w1": "u[1:-1]", "w2": "u[2:]"}
expr_src = sp.pycode(simplified)
for k, v in py_vars.items():
    expr_src = expr_src.replace(k, v)
kernel_src = f"""import jax
import jax.numpy as jnp
jax.config.update('jax_enable_x64', True)
D = {D}.0
@jax.jit
def step(u):
    inner = ({expr_src}) / D
    return u.at[1:-1].set(inner)
"""

# --- exact oracle (Fraction is unbounded: no bignum to write) --------------------------------
def step_exact(u):
    inner = [Fraction(weights[0] * u[i - 1] + weights[1] * u[i] + weights[2] * u[i + 1], D) for i in range(1, len(u) - 1)]
    return [u[0]] + inner + [u[-1]]

def oracle(u0, n):
    u = list(u0)
    for _ in range(n):
        u = step_exact(u)
    return u

if __name__ == "__main__":
    print("raw       :", raw)
    print("simplified:", simplified)
    print(kernel_src)
    print("oracle 2 steps of [0,4,8,4,0]/2^m:", [str(v) for v in oracle([Fraction(v) for v in (0, 4, 8, 4, 0)], 2)])
