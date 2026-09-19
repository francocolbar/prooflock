# LAWS_ORACLE.bend - the big-integer evaluator means what the Z evaluator means, for
# every expression and every window. Proven in PROOF_ORACLE.bend using LAWS_BIGZ.

import Base
import ./../num/z.bend as Z
import ./../num/bigz.bend as BigZ
import ./ir.bend as IR
import ./oracle_core.bend as O

law lookup_big_sound:
  for +k: Nat
  for +env: List<&2, BigZ.BigZ>
  {BigZ.BigZ.to_z(O.lookup_big(k, env)) == IR.lookup(k, O.map_to_z(env)) : Z.Z}

law eval_big_sound:
  for +e: IR.Expr
  for +env: List<&2, BigZ.BigZ>
  {BigZ.BigZ.to_z(O.eval_big(e, env)) == IR.eval(e, O.map_to_z(env)) : Z.Z}

# LAW: one big-integer time step is one Z time step (boundaries scaled by D included)
law step_sound:
  for +xs: List<&2, BigZ.BigZ>
  for +e: IR.Expr
  for +d: Z.Z
  {O.map_to_z(O.step(xs, e, d)) == O.step_z(O.map_to_z(xs), e, d) : List<&2, Z.Z>}

# LAW: n big-integer steps are n Z steps: the whole oracle run means what the Z
# specification means. Only parsing and printing stay outside the laws.
law iterate_sound:
  for +n: Nat
  for +xs: List<&2, BigZ.BigZ>
  for +e: IR.Expr
  for +d: Z.Z
  {O.map_to_z(O.iterate(n, xs, e, d)) == O.iterate_z(n, O.map_to_z(xs), e, d) : List<&2, Z.Z>}
