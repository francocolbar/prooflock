# LAWS_Z_MUL.bend - multiplication on Z. Proven in PROOF_Z_MUL.bend (which may use PROOF_Z_ADD.bend).

import Base
import ./z.bend as Z

# multiplication
law mul_zero_r:
  for +a: Z.Z
  {Z.Z.mul(a, Z.Zero{}) == Z.Zero{} : Z.Z}

law mul_one_l:
  for +b: Z.Z
  {Z.Z.mul(Z.Pos{0n}, b) == b : Z.Z}

law mul_one_r:
  for +a: Z.Z
  {Z.Z.mul(a, Z.Pos{0n}) == a : Z.Z}

law mul_neg_l:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.mul(Z.Z.neg(a), b) == Z.Z.neg(Z.Z.mul(a, b)) : Z.Z}

law mul_neg_r:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.mul(a, Z.Z.neg(b)) == Z.Z.neg(Z.Z.mul(a, b)) : Z.Z}

law dist_l:
  for +c: Z.Z
  for +x: Z.Z
  for +y: Z.Z
  {Z.Z.mul(c, Z.Z.add(x, y)) == Z.Z.add(Z.Z.mul(c, x), Z.Z.mul(c, y)) : Z.Z}

law dist_r:
  for +a: Z.Z
  for +b: Z.Z
  for +x: Z.Z
  {Z.Z.mul(Z.Z.add(a, b), x) == Z.Z.add(Z.Z.mul(a, x), Z.Z.mul(b, x)) : Z.Z}

law mul_assoc:
  for +a: Z.Z
  for +b: Z.Z
  for +c: Z.Z
  {Z.Z.mul(a, Z.Z.mul(b, c)) == Z.Z.mul(Z.Z.mul(a, b), c) : Z.Z}

law mul_comm:
  for +a: Z.Z
  for +b: Z.Z
  {Z.Z.mul(a, b) == Z.Z.mul(b, a) : Z.Z}

