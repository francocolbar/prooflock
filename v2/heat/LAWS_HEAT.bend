# LAWS_HEAT.bend - what the symbolic layer guarantees. Proven in PROOF_HEAT.bend
# (using the Z laws). Laws about heat_scheme() are decided by computation; the
# quantified ones are theorems about every window / every scheme.

import Base
import ./../num/z.bend as Z
import ./ir.bend as IR

# LAW: the normal form keeps the exact meaning of every expression under every window
law lin_sound:
  for +e: IR.Expr
  for +env: List<&2, Z.Z>
  {IR.eval_lin(IR.lin(e), env) == IR.eval(e, env) : Z.Z}

# LAW (computed): the weights of the chosen scheme sum to D: a constant profile is a
# fixed point (consistency of order 0 / conservation of the constant mode)
law weights_sum:
  {IR.sum(IR.weights(IR.heat_scheme())) == IR.den(IR.heat_scheme()) : Z.Z}

# LAW (computed): the stencil is symmetric: the first moment vanishes (second order)
law weights_symmetric:
  {IR.lookup(0n, IR.weights(IR.heat_scheme())) == IR.lookup(2n, IR.weights(IR.heat_scheme())) : Z.Z}

# LAW (computed): every weight is non-negative: the update is a convex combination,
# i.e. the scheme is monotone (max principle) - equivalent to the CFL bound r <= 1/2.
# For Scheme{3n, 2n} (r = 3/4) the central weight is -2 and this claim is false.
law weights_nonneg:
  {IR.all_nonneg(IR.weights(IR.heat_scheme())) == True{} : Bool}

# LAW (computed): no source term
law no_source:
  {IR.const_of(IR.lin(IR.stencil(IR.heat_scheme()))) == Z.Zero{} : Z.Z}

# LAW: for EVERY dyadic r = p / 2^q the weights sum to D (consistency is not a
# coincidence of r = 1/4)
law weights_sum_all:
  for +p: Nat
  for +q: Nat
  {IR.sum(IR.weights(IR.Scheme{p, q})) == IR.den(IR.Scheme{p, q}) : Z.Z}

# LAW: the chosen scheme is exact on linear profiles: for every window
# [a, a+b, a+2b] the numerator is D * (a+b), so u_xx = 0 is preserved exactly
law linear_exact:
  for +a: Z.Z
  for +b: Z.Z
  {IR.eval(IR.stencil(IR.heat_scheme()), [a, Z.Z.add(a, b), Z.Z.add(a, Z.Z.add(b, b))]) == Z.Z.mul(IR.den(IR.heat_scheme()), Z.Z.add(a, b)) : Z.Z}
