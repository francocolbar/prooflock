# PROOF_Z_ADD.bend - proofs of LAWS_Z_ADD.bend.
# Every proof is a structural induction on the Nat inside Pos{n} / Neg{n},
# mirroring Z.succ_neg / Z.pred_pos / Z.add_pos / Z.add_neg.

import Base
import ./z.bend as Z
import ./LAWS_Z_ADD.bend as Laws

# ---------------------------------------------------------------------------
# succ / pred are inverse
# ---------------------------------------------------------------------------

def succ_pred_pos(n: Nat) -> {Z.Z.succ(Z.Z.pred_pos(n)) == Z.Pos{n} : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def pred_succ_neg(n: Nat) -> {Z.Z.pred(Z.Z.succ_neg(n)) == Z.Neg{n} : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def Laws.succ_pred(a):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      succ_pred_pos(n)
    case Z.Neg{n}:
      {==}

def Laws.pred_succ(a):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      {==}
    case Z.Neg{n}:
      pred_succ_neg(n)

# succ(pred(x)) == pred(succ(x)) in both orientations
def sp_ps(+x: Z.Z) -> {Z.Z.succ(Z.Z.pred(x)) == Z.Z.pred(Z.Z.succ(x)) : Z.Z}:
  Equal.trans(Z.Z, Z.Z.succ(Z.Z.pred(x)), x, Z.Z.pred(Z.Z.succ(x)),
    Laws.succ_pred(x),
    Equal.sym(Z.Z, Z.Z.pred(Z.Z.succ(x)), x, Laws.pred_succ(x)))

def ps_sp(+x: Z.Z) -> {Z.Z.pred(Z.Z.succ(x)) == Z.Z.succ(Z.Z.pred(x)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.succ(Z.Z.pred(x)), Z.Z.pred(Z.Z.succ(x)), sp_ps(x))

# ---------------------------------------------------------------------------
# shifting the right argument through add_pos / add_neg
# ---------------------------------------------------------------------------

def add_pos_succ(n: Nat, +b: Z.Z) -> {Z.Z.add_pos(n, Z.Z.succ(b)) == Z.Z.succ(Z.Z.add_pos(n, b)) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_pos_succ(p, b) : {Z.Z.succ(Z.Z.add_pos(p, Z.Z.succ(b))) == Z.Z.succ(_) : Z.Z}
      {==}

def add_pos_pred(n: Nat, +b: Z.Z) -> {Z.Z.add_pos(n, Z.Z.pred(b)) == Z.Z.pred(Z.Z.add_pos(n, b)) : Z.Z}:
  match n:
    case 0n:
      sp_ps(b)
    case 1n++p:
      %sp_ps(Z.Z.add_pos(p, b)) : {Z.Z.succ(Z.Z.add_pos(p, Z.Z.pred(b))) == _ : Z.Z}
      %add_pos_pred(p, b) : {Z.Z.succ(Z.Z.add_pos(p, Z.Z.pred(b))) == Z.Z.succ(_) : Z.Z}
      {==}

def add_neg_succ(n: Nat, +b: Z.Z) -> {Z.Z.add_neg(n, Z.Z.succ(b)) == Z.Z.succ(Z.Z.add_neg(n, b)) : Z.Z}:
  match n:
    case 0n:
      ps_sp(b)
    case 1n++p:
      %ps_sp(Z.Z.add_neg(p, b)) : {Z.Z.pred(Z.Z.add_neg(p, Z.Z.succ(b))) == _ : Z.Z}
      %add_neg_succ(p, b) : {Z.Z.pred(Z.Z.add_neg(p, Z.Z.succ(b))) == Z.Z.pred(_) : Z.Z}
      {==}

def add_neg_pred(n: Nat, +b: Z.Z) -> {Z.Z.add_neg(n, Z.Z.pred(b)) == Z.Z.pred(Z.Z.add_neg(n, b)) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_neg_pred(p, b) : {Z.Z.pred(Z.Z.add_neg(p, Z.Z.pred(b))) == Z.Z.pred(_) : Z.Z}
      {==}

def Laws.add_succ_r(a, b):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      add_pos_succ(n, b)
    case Z.Neg{n}:
      add_neg_succ(n, b)

def Laws.add_pred_r(a, b):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      add_pos_pred(n, b)
    case Z.Neg{n}:
      add_neg_pred(n, b)

# flipped orientations (the stuck add(.., succ ..) on the right)
def succ_add_r(+a: Z.Z, +b: Z.Z) -> {Z.Z.succ(Z.Z.add(a, b)) == Z.Z.add(a, Z.Z.succ(b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(a, Z.Z.succ(b)), Z.Z.succ(Z.Z.add(a, b)), Laws.add_succ_r(a, b))

def pred_add_r(+a: Z.Z, +b: Z.Z) -> {Z.Z.pred(Z.Z.add(a, b)) == Z.Z.add(a, Z.Z.pred(b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(a, Z.Z.pred(b)), Z.Z.pred(Z.Z.add(a, b)), Laws.add_pred_r(a, b))

def pred_add_pos(+n: Nat, +b: Z.Z) -> {Z.Z.pred(Z.Z.add_pos(n, b)) == Z.Z.add_pos(n, Z.Z.pred(b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add_pos(n, Z.Z.pred(b)), Z.Z.pred(Z.Z.add_pos(n, b)), add_pos_pred(n, b))

def succ_add_neg(+n: Nat, +b: Z.Z) -> {Z.Z.succ(Z.Z.add_neg(n, b)) == Z.Z.add_neg(n, Z.Z.succ(b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add_neg(n, Z.Z.succ(b)), Z.Z.succ(Z.Z.add_neg(n, b)), add_neg_succ(n, b))

# ---------------------------------------------------------------------------
# shifting the left argument
# ---------------------------------------------------------------------------

def add_succ_neg(n: Nat, +b: Z.Z) -> {Z.Z.add(Z.Z.succ_neg(n), b) == Z.Z.succ(Z.Z.add_neg(n, b)) : Z.Z}:
  match n:
    case 0n:
      %Laws.succ_pred(b) : {_ == Z.Z.succ(Z.Z.pred(b)) : Z.Z}
      {==}
    case 1n++p:
      %Laws.succ_pred(Z.Z.add_neg(p, b)) : {_ == Z.Z.succ(Z.Z.pred(Z.Z.add_neg(p, b))) : Z.Z}
      {==}

def add_pred_pos(n: Nat, +b: Z.Z) -> {Z.Z.add(Z.Z.pred_pos(n), b) == Z.Z.pred(Z.Z.add_pos(n, b)) : Z.Z}:
  match n:
    case 0n:
      %Laws.pred_succ(b) : {_ == Z.Z.pred(Z.Z.succ(b)) : Z.Z}
      {==}
    case 1n++p:
      %Laws.pred_succ(Z.Z.add_pos(p, b)) : {_ == Z.Z.pred(Z.Z.succ(Z.Z.add_pos(p, b))) : Z.Z}
      {==}

def Laws.add_succ_l(a, b):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      {==}
    case Z.Neg{n}:
      add_succ_neg(n, b)

def Laws.add_pred_l(a, b):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      add_pred_pos(n, b)
    case Z.Neg{n}:
      {==}

def succ_add_l(+a: Z.Z, +b: Z.Z) -> {Z.Z.succ(Z.Z.add(a, b)) == Z.Z.add(Z.Z.succ(a), b) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(Z.Z.succ(a), b), Z.Z.succ(Z.Z.add(a, b)), Laws.add_succ_l(a, b))

def pred_add_l(+a: Z.Z, +b: Z.Z) -> {Z.Z.pred(Z.Z.add(a, b)) == Z.Z.add(Z.Z.pred(a), b) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(Z.Z.pred(a), b), Z.Z.pred(Z.Z.add(a, b)), Laws.add_pred_l(a, b))

# ---------------------------------------------------------------------------
# neutral element
# ---------------------------------------------------------------------------

def add_pos_zero(n: Nat) -> {Z.Z.add_pos(n, Z.Zero{}) == Z.Pos{n} : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_pos_zero(p) : {Z.Z.succ(Z.Z.add_pos(p, Z.Zero{})) == Z.Z.succ(_) : Z.Z}
      {==}

def add_neg_zero(n: Nat) -> {Z.Z.add_neg(n, Z.Zero{}) == Z.Neg{n} : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_neg_zero(p) : {Z.Z.pred(Z.Z.add_neg(p, Z.Zero{})) == Z.Z.pred(_) : Z.Z}
      {==}

def Laws.add_zero_r(a):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      add_pos_zero(n)
    case Z.Neg{n}:
      add_neg_zero(n)

# flipped: the stuck add(b, Zero) on the right
def zero_add_r(+b: Z.Z) -> {b == Z.Z.add(b, Z.Zero{}) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(b, Z.Zero{}), b, Laws.add_zero_r(b))

# ---------------------------------------------------------------------------
# commutativity
# ---------------------------------------------------------------------------

def add_pos_comm(n: Nat, +b: Z.Z) -> {Z.Z.add_pos(n, b) == Z.Z.add(b, Z.Pos{n}) : Z.Z}:
  match n:
    case 0n:
      %succ_add_r(b, Z.Zero{}) : {Z.Z.succ(b) == _ : Z.Z}
      %zero_add_r(b) : {Z.Z.succ(b) == Z.Z.succ(_) : Z.Z}
      {==}
    case 1n++p:
      %succ_add_r(b, Z.Pos{p}) : {Z.Z.succ(Z.Z.add_pos(p, b)) == _ : Z.Z}
      %add_pos_comm(p, b) : {Z.Z.succ(Z.Z.add_pos(p, b)) == Z.Z.succ(_) : Z.Z}
      {==}

def add_neg_comm(n: Nat, +b: Z.Z) -> {Z.Z.add_neg(n, b) == Z.Z.add(b, Z.Neg{n}) : Z.Z}:
  match n:
    case 0n:
      %pred_add_r(b, Z.Zero{}) : {Z.Z.pred(b) == _ : Z.Z}
      %zero_add_r(b) : {Z.Z.pred(b) == Z.Z.pred(_) : Z.Z}
      {==}
    case 1n++p:
      %pred_add_r(b, Z.Neg{p}) : {Z.Z.pred(Z.Z.add_neg(p, b)) == _ : Z.Z}
      %add_neg_comm(p, b) : {Z.Z.pred(Z.Z.add_neg(p, b)) == Z.Z.pred(_) : Z.Z}
      {==}

def Laws.add_comm(a, b):
  match a:
    case Z.Zero{}:
      zero_add_r(b)
    case Z.Pos{n}:
      add_pos_comm(n, b)
    case Z.Neg{n}:
      add_neg_comm(n, b)

# ---------------------------------------------------------------------------
# associativity
# ---------------------------------------------------------------------------

def add_pos_assoc(n: Nat, +b: Z.Z, +c: Z.Z) -> {Z.Z.add_pos(n, Z.Z.add(b, c)) == Z.Z.add(Z.Z.add_pos(n, b), c) : Z.Z}:
  match n:
    case 0n:
      succ_add_l(b, c)
    case 1n++p:
      %succ_add_l(Z.Z.add_pos(p, b), c) : {Z.Z.succ(Z.Z.add_pos(p, Z.Z.add(b, c))) == _ : Z.Z}
      %add_pos_assoc(p, b, c) : {Z.Z.succ(Z.Z.add_pos(p, Z.Z.add(b, c))) == Z.Z.succ(_) : Z.Z}
      {==}

def add_neg_assoc(n: Nat, +b: Z.Z, +c: Z.Z) -> {Z.Z.add_neg(n, Z.Z.add(b, c)) == Z.Z.add(Z.Z.add_neg(n, b), c) : Z.Z}:
  match n:
    case 0n:
      pred_add_l(b, c)
    case 1n++p:
      %pred_add_l(Z.Z.add_neg(p, b), c) : {Z.Z.pred(Z.Z.add_neg(p, Z.Z.add(b, c))) == _ : Z.Z}
      %add_neg_assoc(p, b, c) : {Z.Z.pred(Z.Z.add_neg(p, Z.Z.add(b, c))) == Z.Z.pred(_) : Z.Z}
      {==}

def Laws.add_assoc(a, b, c):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      add_pos_assoc(n, b, c)
    case Z.Neg{n}:
      add_neg_assoc(n, b, c)

# ---------------------------------------------------------------------------
# negation
# ---------------------------------------------------------------------------

def Laws.neg_neg(a):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      {==}
    case Z.Neg{n}:
      {==}

# stated with Zero on the left so the IH rewrites the stuck call on the right
def add_pos_neg(n: Nat) -> {Z.Zero{} == Z.Z.add_pos(n, Z.Neg{n}) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %pred_add_pos(p, Z.Neg{p}) : {Z.Zero{} == Z.Z.succ(_) : Z.Z}
      %add_pos_neg(p) : {Z.Zero{} == Z.Z.succ(Z.Z.pred(_)) : Z.Z}
      {==}

def add_neg_pos(n: Nat) -> {Z.Zero{} == Z.Z.add_neg(n, Z.Pos{n}) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %succ_add_neg(p, Z.Pos{p}) : {Z.Zero{} == Z.Z.pred(_) : Z.Z}
      %add_neg_pos(p) : {Z.Zero{} == Z.Z.pred(Z.Z.succ(_)) : Z.Z}
      {==}

def Laws.add_neg_r(a):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      %add_pos_neg(n) : {_ == Z.Zero{} : Z.Z}
      {==}
    case Z.Neg{n}:
      %add_neg_pos(n) : {_ == Z.Zero{} : Z.Z}
      {==}

# neg commutes with succ / pred (the neg(succ ..) / neg(pred ..) on the right)
def neg_succ_neg(n: Nat) -> {Z.Z.pred_pos(n) == Z.Z.neg(Z.Z.succ_neg(n)) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def neg_pred_pos(n: Nat) -> {Z.Z.succ_neg(n) == Z.Z.neg(Z.Z.pred_pos(n)) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def neg_succ(a: Z.Z) -> {Z.Z.pred(Z.Z.neg(a)) == Z.Z.neg(Z.Z.succ(a)) : Z.Z}:
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      {==}
    case Z.Neg{n}:
      neg_succ_neg(n)

def neg_pred(a: Z.Z) -> {Z.Z.succ(Z.Z.neg(a)) == Z.Z.neg(Z.Z.pred(a)) : Z.Z}:
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      neg_pred_pos(n)
    case Z.Neg{n}:
      {==}

def neg_add_pos(n: Nat, +b: Z.Z) -> {Z.Z.neg(Z.Z.add_pos(n, b)) == Z.Z.add_neg(n, Z.Z.neg(b)) : Z.Z}:
  match n:
    case 0n:
      %neg_succ(b) : {_ == Z.Z.pred(Z.Z.neg(b)) : Z.Z}
      {==}
    case 1n++p:
      %neg_succ(Z.Z.add_pos(p, b)) : {_ == Z.Z.pred(Z.Z.add_neg(p, Z.Z.neg(b))) : Z.Z}
      %neg_add_pos(p, b) : {Z.Z.pred(Z.Z.neg(Z.Z.add_pos(p, b))) == Z.Z.pred(_) : Z.Z}
      {==}

def neg_add_neg(n: Nat, +b: Z.Z) -> {Z.Z.neg(Z.Z.add_neg(n, b)) == Z.Z.add_pos(n, Z.Z.neg(b)) : Z.Z}:
  match n:
    case 0n:
      %neg_pred(b) : {_ == Z.Z.succ(Z.Z.neg(b)) : Z.Z}
      {==}
    case 1n++p:
      %neg_pred(Z.Z.add_neg(p, b)) : {_ == Z.Z.succ(Z.Z.add_pos(p, Z.Z.neg(b))) : Z.Z}
      %neg_add_neg(p, b) : {Z.Z.succ(Z.Z.neg(Z.Z.add_neg(p, b))) == Z.Z.succ(_) : Z.Z}
      {==}

def Laws.neg_add(a, b):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      neg_add_pos(n, b)
    case Z.Neg{n}:
      neg_add_neg(n, b)

# ---------------------------------------------------------------------------
# from_nat is a homomorphism
# ---------------------------------------------------------------------------

def succ_from_nat(b: Nat) -> {Z.Pos{b} == Z.Z.succ(Z.Z.from_nat(b)) : Z.Z}:
  match b:
    case 0n:
      {==}
    case 1n+q:
      {==}

def from_nat_add_pos(p: Nat, +b: Nat) -> {Z.Pos{Nat.add(p, b)} == Z.Z.add_pos(p, Z.Z.from_nat(b)) : Z.Z}:
  match p:
    case 0n:
      succ_from_nat(b)
    case 1n++q:
      %from_nat_add_pos(q, b) : {Z.Pos{1n+Nat.add(q, b)} == Z.Z.succ(_) : Z.Z}
      {==}

def Laws.from_nat_add(a, b):
  match a:
    case 0n:
      {==}
    case 1n+p:
      from_nat_add_pos(p, b)
