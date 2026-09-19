# bigz.bend - arbitrary-precision INTEGERS as a difference of two bit-list naturals,
# BZ{p, n} meaning p - n. No borrows, no sign logic: add is componentwise, neg is a
# swap, scaling by a Z constant is repeated addition (mirroring Z.mul_pos). The
# representation is not canonical (BZ{[1],[1]} is 0 too); the meaning is BigZ.to_z,
# and every law in LAWS_BIGZ.bend is stated through it.

import Base
import ./z.bend as Z
import ./big.bend as Big

type BigZ is Data:
  BZ{p: List<&2, Bool>, n: List<&2, Bool>}

def BigZ.to_z(a: BigZ) -> Z.Z:
  match a:
    case BZ{p, n}:
      Z.Z.sub(Z.Z.from_nat(Big.Big.to_nat(p)), Z.Z.from_nat(Big.Big.to_nat(n)))

def BigZ.zero() -> BigZ:
  BZ{Nil{}, Nil{}}

def BigZ.add(a: BigZ, b: BigZ) -> BigZ:
  match a b:
    case BZ{p1, n1} BZ{p2, n2}:
      BZ{Big.Big.add(p1, p2), Big.Big.add(n1, n2)}

def BigZ.neg(a: BigZ) -> BigZ:
  match a:
    case BZ{p, n}:
      BZ{n, p}

# (k+1) copies of v, mirroring Z.mul_pos
def BigZ.scale_pos(k: Nat, +v: BigZ) -> BigZ:
  match k:
    case 0n:
      v
    case 1n+p:
      BigZ.add(v, BigZ.scale_pos(p, v))

# c * v for a Z constant c, mirroring Z.mul
def BigZ.scale(c: Z.Z, v: BigZ) -> BigZ:
  match c:
    case Z.Zero{}:
      BigZ.zero()
    case Z.Pos{k}:
      BigZ.scale_pos(k, v)
    case Z.Neg{k}:
      BigZ.neg(BigZ.scale_pos(k, v))

def BigZ.from_z(c: Z.Z) -> BigZ:
  match c:
    case Z.Zero{}:
      BigZ.zero()
    case Z.Pos{k}:
      BZ{Big.Big.from_nat(1n+k), Nil{}}
    case Z.Neg{k}:
      BZ{Nil{}, Big.Big.from_nat(1n+k)}

# I/O: "pbits/nbits", each least-significant-bit first
def BigZ.show(a: BigZ) -> String:
  match a:
    case BZ{p, n}:
      Big.Big.show(p) ++ "/" ++ Big.Big.show(n)

# parse a non-negative bit string into a BigZ
def BigZ.parse_nat(s: String) -> BigZ:
  BZ{Big.Big.parse(s), Nil{}}
