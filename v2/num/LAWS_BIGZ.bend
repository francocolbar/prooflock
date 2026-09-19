# LAWS_BIGZ.bend - the big integers mean what Z says. Proven in PROOF_BIGZ.bend using
# PROOF_Z_ADD / PROOF_Z_MUL / PROOF_BIG.

import Base
import ./z.bend as Z
import ./big.bend as Big
import ./bigz.bend as BigZ

law add_sound:
  for +a: BigZ.BigZ
  for +b: BigZ.BigZ
  {BigZ.BigZ.to_z(BigZ.BigZ.add(a, b)) == Z.Z.add(BigZ.BigZ.to_z(a), BigZ.BigZ.to_z(b)) : Z.Z}

law neg_sound:
  for +a: BigZ.BigZ
  {BigZ.BigZ.to_z(BigZ.BigZ.neg(a)) == Z.Z.neg(BigZ.BigZ.to_z(a)) : Z.Z}

law scale_sound:
  for +c: Z.Z
  for +v: BigZ.BigZ
  {BigZ.BigZ.to_z(BigZ.BigZ.scale(c, v)) == Z.Z.mul(c, BigZ.BigZ.to_z(v)) : Z.Z}

law from_z_sound:
  for +c: Z.Z
  {BigZ.BigZ.to_z(BigZ.BigZ.from_z(c)) == c : Z.Z}

law zero_sound:
  {BigZ.BigZ.to_z(BigZ.BigZ.zero()) == Z.Zero{} : Z.Z}
