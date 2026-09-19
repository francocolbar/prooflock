# PROOF_BIGZ.bend - proofs of LAWS_BIGZ.bend: the big integers mean what Z says.
# Every BigZ law reduces, after one match on BZ{p, n}, to a fact about Z.add / Z.neg /
# Z.from_nat (PROOF_Z_ADD) and Big.to_nat (PROOF_BIG). The PROOF files are imported so
# that the laws they fill are usable (an unfilled law is a dead claim).

import Base
import ./z.bend as Z
import ./big.bend as Big
import ./bigz.bend as BigZ
import ./LAWS_Z_ADD.bend as LA
import ./PROOF_Z_ADD.bend as PA
import ./LAWS_BIG.bend as LBig
import ./PROOF_BIG.bend as PBig
import ./LAWS_BIGZ.bend as Laws

# ---------------------------------------------------------------------------
# Flipped orientations of the imported laws: `%e : P` eliminates the RIGHT side of e,
# so a law stated `f(op(..)) == spec(..)` must be flipped to unfold f(op(..)) in a goal.
# ---------------------------------------------------------------------------

def neg_add_f(+a: Z.Z, +b: Z.Z) -> {Z.Z.add(Z.Z.neg(a), Z.Z.neg(b)) == Z.Z.neg(Z.Z.add(a, b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.neg(Z.Z.add(a, b)), Z.Z.add(Z.Z.neg(a), Z.Z.neg(b)), LA.neg_add(a, b))

def neg_neg_f(+a: Z.Z) -> {a == Z.Z.neg(Z.Z.neg(a)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.neg(Z.Z.neg(a)), a, LA.neg_neg(a))

def add_assoc_f(+a: Z.Z, +b: Z.Z, +c: Z.Z) -> {Z.Z.add(Z.Z.add(a, b), c) == Z.Z.add(a, Z.Z.add(b, c)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(a, Z.Z.add(b, c)), Z.Z.add(Z.Z.add(a, b), c), LA.add_assoc(a, b, c))

def from_nat_add_f(+a: Nat, +b: Nat) -> {Z.Z.add(Z.Z.from_nat(a), Z.Z.from_nat(b)) == Z.Z.from_nat(Nat.add(a, b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.from_nat(Nat.add(a, b)), Z.Z.add(Z.Z.from_nat(a), Z.Z.from_nat(b)), LA.from_nat_add(a, b))

def big_add_f(+xs: List<&2, Bool>, +ys: List<&2, Bool>) -> {Nat.add(Big.Big.to_nat(xs), Big.Big.to_nat(ys)) == Big.Big.to_nat(Big.Big.add(xs, ys)) : Nat}:
  Equal.sym(Nat, Big.Big.to_nat(Big.Big.add(xs, ys)), Nat.add(Big.Big.to_nat(xs), Big.Big.to_nat(ys)), LBig.add_sound(xs, ys))

def big_from_nat_f(+n: Nat) -> {n == Big.Big.to_nat(Big.Big.from_nat(n)) : Nat}:
  Equal.sym(Nat, Big.Big.to_nat(Big.Big.from_nat(n)), n, LBig.from_nat_sound(n))

# ---------------------------------------------------------------------------
# Z-level facts
# ---------------------------------------------------------------------------

# y - x == -(x - y)
def neg_sub(+x: Z.Z, +y: Z.Z) -> {Z.Z.add(y, Z.Z.neg(x)) == Z.Z.neg(Z.Z.add(x, Z.Z.neg(y))) : Z.Z}:
  %neg_add_f(x, Z.Z.neg(y)) : {Z.Z.add(y, Z.Z.neg(x)) == _ : Z.Z}
  %neg_neg_f(y) : {Z.Z.add(y, Z.Z.neg(x)) == Z.Z.add(Z.Z.neg(x), _) : Z.Z}
  LA.add_comm(y, Z.Z.neg(x))

# (a + b) + (c + d) == (a + c) + (b + d)
def add4(+a: Z.Z, +b: Z.Z, +c: Z.Z, +d: Z.Z) -> {Z.Z.add(Z.Z.add(a, b), Z.Z.add(c, d)) == Z.Z.add(Z.Z.add(a, c), Z.Z.add(b, d)) : Z.Z}:
  %LA.add_assoc(a, c, Z.Z.add(b, d)) : {Z.Z.add(Z.Z.add(a, b), Z.Z.add(c, d)) == _ : Z.Z}
  %LA.add_assoc(a, b, Z.Z.add(c, d)) : {_ == Z.Z.add(a, Z.Z.add(c, Z.Z.add(b, d))) : Z.Z}
  %add_assoc_f(c, b, d) : {Z.Z.add(a, Z.Z.add(b, Z.Z.add(c, d))) == Z.Z.add(a, _) : Z.Z}
  %LA.add_comm(b, c) : {Z.Z.add(a, Z.Z.add(b, Z.Z.add(c, d))) == Z.Z.add(a, Z.Z.add(_, d)) : Z.Z}
  %LA.add_assoc(b, c, d) : {Z.Z.add(a, Z.Z.add(b, Z.Z.add(c, d))) == Z.Z.add(a, _) : Z.Z}
  {==}

# (P1 + P2) - (N1 + N2) == (P1 - N1) + (P2 - N2)
def add_sound_z(+p1: Z.Z, +n1: Z.Z, +p2: Z.Z, +n2: Z.Z) -> {Z.Z.add(Z.Z.add(p1, p2), Z.Z.neg(Z.Z.add(n1, n2))) == Z.Z.add(Z.Z.add(p1, Z.Z.neg(n1)), Z.Z.add(p2, Z.Z.neg(n2))) : Z.Z}:
  %neg_add_f(n1, n2) : {Z.Z.add(Z.Z.add(p1, p2), _) == Z.Z.add(Z.Z.add(p1, Z.Z.neg(n1)), Z.Z.add(p2, Z.Z.neg(n2))) : Z.Z}
  add4(p1, p2, Z.Z.neg(n1), Z.Z.neg(n2))

# the same through from_nat
def add_sound_n(+a1: Nat, +b1: Nat, +a2: Nat, +b2: Nat) -> {Z.Z.add(Z.Z.from_nat(Nat.add(a1, a2)), Z.Z.neg(Z.Z.from_nat(Nat.add(b1, b2)))) == Z.Z.add(Z.Z.add(Z.Z.from_nat(a1), Z.Z.neg(Z.Z.from_nat(b1))), Z.Z.add(Z.Z.from_nat(a2), Z.Z.neg(Z.Z.from_nat(b2)))) : Z.Z}:
  %from_nat_add_f(a1, a2) : {Z.Z.add(_, Z.Z.neg(Z.Z.from_nat(Nat.add(b1, b2)))) == Z.Z.add(Z.Z.add(Z.Z.from_nat(a1), Z.Z.neg(Z.Z.from_nat(b1))), Z.Z.add(Z.Z.from_nat(a2), Z.Z.neg(Z.Z.from_nat(b2)))) : Z.Z}
  %from_nat_add_f(b1, b2) : {Z.Z.add(Z.Z.add(Z.Z.from_nat(a1), Z.Z.from_nat(a2)), Z.Z.neg(_)) == Z.Z.add(Z.Z.add(Z.Z.from_nat(a1), Z.Z.neg(Z.Z.from_nat(b1))), Z.Z.add(Z.Z.from_nat(a2), Z.Z.neg(Z.Z.from_nat(b2)))) : Z.Z}
  add_sound_z(Z.Z.from_nat(a1), Z.Z.from_nat(b1), Z.Z.from_nat(a2), Z.Z.from_nat(b2))

# ---------------------------------------------------------------------------
# The laws
# ---------------------------------------------------------------------------

def Laws.zero_sound():
  {==}

def Laws.neg_sound(a):
  match a:
    case BigZ.BZ{+p, +n}:
      neg_sub(Z.Z.from_nat(Big.Big.to_nat(p)), Z.Z.from_nat(Big.Big.to_nat(n)))

def Laws.add_sound(a, b):
  match a b:
    case BigZ.BZ{+p1, +n1} BigZ.BZ{+p2, +n2}:
      %big_add_f(p1, p2) : {Z.Z.add(Z.Z.from_nat(_), Z.Z.neg(Z.Z.from_nat(Big.Big.to_nat(Big.Big.add(n1, n2))))) == Z.Z.add(Z.Z.add(Z.Z.from_nat(Big.Big.to_nat(p1)), Z.Z.neg(Z.Z.from_nat(Big.Big.to_nat(n1)))), Z.Z.add(Z.Z.from_nat(Big.Big.to_nat(p2)), Z.Z.neg(Z.Z.from_nat(Big.Big.to_nat(n2))))) : Z.Z}
      %big_add_f(n1, n2) : {Z.Z.add(Z.Z.from_nat(Nat.add(Big.Big.to_nat(p1), Big.Big.to_nat(p2))), Z.Z.neg(Z.Z.from_nat(_))) == Z.Z.add(Z.Z.add(Z.Z.from_nat(Big.Big.to_nat(p1)), Z.Z.neg(Z.Z.from_nat(Big.Big.to_nat(n1)))), Z.Z.add(Z.Z.from_nat(Big.Big.to_nat(p2)), Z.Z.neg(Z.Z.from_nat(Big.Big.to_nat(n2))))) : Z.Z}
      add_sound_n(Big.Big.to_nat(p1), Big.Big.to_nat(n1), Big.Big.to_nat(p2), Big.Big.to_nat(n2))

# flipped orientations of the two BigZ laws above (used by scale_sound)
def add_sound_f(+a: BigZ.BigZ, +b: BigZ.BigZ) -> {Z.Z.add(BigZ.BigZ.to_z(a), BigZ.BigZ.to_z(b)) == BigZ.BigZ.to_z(BigZ.BigZ.add(a, b)) : Z.Z}:
  Equal.sym(Z.Z, BigZ.BigZ.to_z(BigZ.BigZ.add(a, b)), Z.Z.add(BigZ.BigZ.to_z(a), BigZ.BigZ.to_z(b)), Laws.add_sound(a, b))

def neg_sound_f(+a: BigZ.BigZ) -> {Z.Z.neg(BigZ.BigZ.to_z(a)) == BigZ.BigZ.to_z(BigZ.BigZ.neg(a)) : Z.Z}:
  Equal.sym(Z.Z, BigZ.BigZ.to_z(BigZ.BigZ.neg(a)), Z.Z.neg(BigZ.BigZ.to_z(a)), Laws.neg_sound(a))

# scale_pos mirrors Z.mul_pos: induction on k
def scale_pos_sound(k: Nat, +v: BigZ.BigZ) -> {BigZ.BigZ.to_z(BigZ.BigZ.scale_pos(k, v)) == Z.Z.mul_pos(k, BigZ.BigZ.to_z(v)) : Z.Z}:
  match k:
    case 0n:
      {==}
    case 1n++p:
      %add_sound_f(v, BigZ.BigZ.scale_pos(p, v)) : {_ == Z.Z.add(BigZ.BigZ.to_z(v), Z.Z.mul_pos(p, BigZ.BigZ.to_z(v))) : Z.Z}
      %scale_pos_sound(p, v) : {Z.Z.add(BigZ.BigZ.to_z(v), BigZ.BigZ.to_z(BigZ.BigZ.scale_pos(p, v))) == Z.Z.add(BigZ.BigZ.to_z(v), _) : Z.Z}
      {==}

def Laws.scale_sound(c, v):
  match c:
    case Z.Zero{}:
      {==}
    case Z.Pos{k}:
      scale_pos_sound(k, v)
    case Z.Neg{+k}:
      %neg_sound_f(BigZ.BigZ.scale_pos(k, v)) : {_ == Z.Z.neg(Z.Z.mul_pos(k, BigZ.BigZ.to_z(v))) : Z.Z}
      %scale_pos_sound(k, v) : {Z.Z.neg(BigZ.BigZ.to_z(BigZ.BigZ.scale_pos(k, v))) == Z.Z.neg(_) : Z.Z}
      {==}

def Laws.from_z_sound(c):
  match c:
    case Z.Zero{}:
      {==}
    case Z.Pos{+k}:
      %big_from_nat_f(1n+k) : {Z.Z.add(Z.Z.from_nat(_), Z.Zero{}) == Z.Pos{k} : Z.Z}
      LA.add_zero_r(Z.Pos{k})
    case Z.Neg{+k}:
      %big_from_nat_f(1n+k) : {Z.Z.neg(Z.Z.from_nat(_)) == Z.Neg{k} : Z.Z}
      {==}
