# LAWS.bend - what the symbolic layer must never break. Proven in PROOF.bend;
# `bend PROOF.bend` must print "All terms check.".

import Base
import ./ir.bend as IR

# LAW: the simplifier keeps the exact meaning of every expression under every window
law simplify_sound:
  for  e: IR.Expr
  for +env: List<&2, Nat>
  {IR.eval(IR.simplify(e), env) == IR.eval(e, env) : Nat}

# LAW (decided by computation): the weights of the chosen scheme sum to the
# denominator D. Nat.sub saturates, so this fails for any scheme with r > 1/2:
# it doubles as the CFL certificate of the scheme.
law weights_sum:
  {IR.sum(IR.weights(IR.heat_scheme())) == IR.den(IR.heat_scheme()) : Nat}

# LAW (decided by computation): the stencil is symmetric, i.e. its first moment
# vanishes: the space discretization is second-order consistent.
law weights_symmetric:
  {IR.lookup(0n, IR.weights(IR.heat_scheme())) == IR.lookup(2n, IR.weights(IR.heat_scheme())) : Nat}

# LAW: the stencil is exact on linear data. For any window [a, a+b, a+2b] the
# numerator it produces is D * (a+b): a linear profile (u_xx = 0) is a fixed point
# of the update, for all a and b, not just for tested values.
law linear_exact:
  for +a: Nat
  for +b: Nat
  {IR.eval(IR.stencil(IR.heat_scheme()), [a, Nat.add(a, b), Nat.add(a, Nat.mul(2n, b))]) == Nat.mul(IR.den(IR.heat_scheme()), Nat.add(a, b)) : Nat}
