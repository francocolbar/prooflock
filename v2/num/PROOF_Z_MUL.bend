# PROOF_Z_MUL.bend - proofs of LAWS_Z_MUL.bend, built on the addition laws.
# Every proof is a structural induction on the Nat inside Pos{n} / Neg{n},
# mirroring Z.mul_pos; the ring facts about Z.add come from LAWS_Z_ADD
# (LA.name) and its helper lemmas (PA.name).

import Base
import ./z.bend as Z
import ./LAWS_Z_ADD.bend as LA
import ./PROOF_Z_ADD.bend as PA
import ./LAWS_Z_MUL.bend as Laws

# ---------------------------------------------------------------------------
# addition facts in the orientation the rewrites below need
# (the term a rewrite must eliminate sits on the RIGHT)
# ---------------------------------------------------------------------------

# (a + b) + c == a + (b + c)
def assoc_r(+a: Z.Z, +b: Z.Z, +c: Z.Z) -> {Z.Z.add(Z.Z.add(a, b), c) == Z.Z.add(a, Z.Z.add(b, c)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(a, Z.Z.add(b, c)), Z.Z.add(Z.Z.add(a, b), c), LA.add_assoc(a, b, c))

# 0 == x + (-x)
def zero_add_neg(+x: Z.Z) -> {Z.Zero{} == Z.Z.add(x, Z.Z.neg(x)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(x, Z.Z.neg(x)), Z.Zero{}, LA.add_neg_r(x))

# (-a) + (-b) == -(a + b)
def add_neg_neg(+a: Z.Z, +b: Z.Z) -> {Z.Z.add(Z.Z.neg(a), Z.Z.neg(b)) == Z.Z.neg(Z.Z.add(a, b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.neg(Z.Z.add(a, b)), Z.Z.add(Z.Z.neg(a), Z.Z.neg(b)), LA.neg_add(a, b))

# a + (y + b) == y + (a + b)
def add_swap(+a: Z.Z, +y: Z.Z, +b: Z.Z) -> {Z.Z.add(a, Z.Z.add(y, b)) == Z.Z.add(y, Z.Z.add(a, b)) : Z.Z}:
  %assoc_r(y, a, b) : {Z.Z.add(a, Z.Z.add(y, b)) == _ : Z.Z}
  %LA.add_comm(a, y) : {Z.Z.add(a, Z.Z.add(y, b)) == Z.Z.add(_, b) : Z.Z}
  %LA.add_assoc(a, y, b) : {Z.Z.add(a, Z.Z.add(y, b)) == _ : Z.Z}
  {==}

# (x + a) + (y + b) == (x + y) + (a + b)
def add_swap4(+x: Z.Z, +a: Z.Z, +y: Z.Z, +b: Z.Z) -> {Z.Z.add(Z.Z.add(x, a), Z.Z.add(y, b)) == Z.Z.add(Z.Z.add(x, y), Z.Z.add(a, b)) : Z.Z}:
  %LA.add_assoc(x, y, Z.Z.add(a, b)) : {Z.Z.add(Z.Z.add(x, a), Z.Z.add(y, b)) == _ : Z.Z}
  %LA.add_assoc(x, a, Z.Z.add(y, b)) : {_ == Z.Z.add(x, Z.Z.add(y, Z.Z.add(a, b))) : Z.Z}
  %add_swap(a, y, b) : {Z.Z.add(x, Z.Z.add(a, Z.Z.add(y, b))) == Z.Z.add(x, _) : Z.Z}
  {==}

# ---------------------------------------------------------------------------
# mul_zero_r, mul_one_l, mul_one_r
# ---------------------------------------------------------------------------

def mul_pos_zero(n: Nat) -> {Z.Zero{} == Z.Z.mul_pos(n, Z.Zero{}) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      mul_pos_zero(p)

def Laws.mul_zero_r(a):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      %mul_pos_zero(n) : {_ == Z.Zero{} : Z.Z}
      {==}
    case Z.Neg{n}:
      %mul_pos_zero(n) : {Z.Z.neg(_) == Z.Zero{} : Z.Z}
      {==}

def Laws.mul_one_l(b):
  {==}

def mul_pos_one(n: Nat) -> {Z.Pos{n} == Z.Z.mul_pos(n, Z.Pos{0n}) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %mul_pos_one(p) : {Z.Pos{1n+p} == Z.Z.succ(_) : Z.Z}
      {==}

def Laws.mul_one_r(a):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      %mul_pos_one(n) : {_ == Z.Pos{n} : Z.Z}
      {==}
    case Z.Neg{n}:
      %mul_pos_one(n) : {Z.Z.neg(_) == Z.Neg{n} : Z.Z}
      {==}

# flipped: b == b * 1
def one_mul_r(+b: Z.Z) -> {b == Z.Z.mul(b, Z.Pos{0n}) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(b, Z.Pos{0n}), b, Laws.mul_one_r(b))

# ---------------------------------------------------------------------------
# negation
# ---------------------------------------------------------------------------

def Laws.mul_neg_l(a, b):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      {==}
    case Z.Neg{+n}:
      Equal.sym(Z.Z, Z.Z.neg(Z.Z.neg(Z.Z.mul_pos(n, b))), Z.Z.mul_pos(n, b), LA.neg_neg(Z.Z.mul_pos(n, b)))

# flipped: -(a * b) == (-a) * b
def neg_mul_l(+a: Z.Z, +b: Z.Z) -> {Z.Z.neg(Z.Z.mul(a, b)) == Z.Z.mul(Z.Z.neg(a), b) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(Z.Z.neg(a), b), Z.Z.neg(Z.Z.mul(a, b)), Laws.mul_neg_l(a, b))

def mul_pos_neg(n: Nat, +b: Z.Z) -> {Z.Z.mul_pos(n, Z.Z.neg(b)) == Z.Z.neg(Z.Z.mul_pos(n, b)) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %add_neg_neg(b, Z.Z.mul_pos(p, b)) : {Z.Z.add(Z.Z.neg(b), Z.Z.mul_pos(p, Z.Z.neg(b))) == _ : Z.Z}
      %mul_pos_neg(p, b) : {Z.Z.add(Z.Z.neg(b), Z.Z.mul_pos(p, Z.Z.neg(b))) == Z.Z.add(Z.Z.neg(b), _) : Z.Z}
      {==}

def Laws.mul_neg_r(a, b):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      mul_pos_neg(n, b)
    case Z.Neg{+n}:
      %mul_pos_neg(n, b) : {Z.Z.neg(Z.Z.mul_pos(n, Z.Z.neg(b))) == Z.Z.neg(_) : Z.Z}
      {==}

# flipped: -(a * b) == a * (-b)
def neg_mul_r(+a: Z.Z, +b: Z.Z) -> {Z.Z.neg(Z.Z.mul(a, b)) == Z.Z.mul(a, Z.Z.neg(b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(a, Z.Z.neg(b)), Z.Z.neg(Z.Z.mul(a, b)), Laws.mul_neg_r(a, b))

# ---------------------------------------------------------------------------
# left distributivity
# ---------------------------------------------------------------------------

def mul_pos_add(n: Nat, +x: Z.Z, +y: Z.Z) -> {Z.Z.add(Z.Z.mul_pos(n, x), Z.Z.mul_pos(n, y)) == Z.Z.mul_pos(n, Z.Z.add(x, y)) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %mul_pos_add(p, x, y) : {Z.Z.add(Z.Z.add(x, Z.Z.mul_pos(p, x)), Z.Z.add(y, Z.Z.mul_pos(p, y))) == Z.Z.add(Z.Z.add(x, y), _) : Z.Z}
      add_swap4(x, Z.Z.mul_pos(p, x), y, Z.Z.mul_pos(p, y))

def Laws.dist_l(c, x, y):
  match c:
    case Z.Zero{}:
      {==}
    case Z.Pos{+n}:
      Equal.sym(Z.Z, Z.Z.add(Z.Z.mul_pos(n, x), Z.Z.mul_pos(n, y)), Z.Z.mul_pos(n, Z.Z.add(x, y)), mul_pos_add(n, x, y))
    case Z.Neg{+n}:
      %LA.neg_add(Z.Z.mul_pos(n, x), Z.Z.mul_pos(n, y)) : {Z.Z.neg(Z.Z.mul_pos(n, Z.Z.add(x, y))) == _ : Z.Z}
      %mul_pos_add(n, x, y) : {Z.Z.neg(_) == Z.Z.neg(Z.Z.add(Z.Z.mul_pos(n, x), Z.Z.mul_pos(n, y))) : Z.Z}
      {==}

# flipped: c*x + c*y == c * (x + y)
def add_mul_l(+c: Z.Z, +x: Z.Z, +y: Z.Z) -> {Z.Z.add(Z.Z.mul(c, x), Z.Z.mul(c, y)) == Z.Z.mul(c, Z.Z.add(x, y)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(c, Z.Z.add(x, y)), Z.Z.add(Z.Z.mul(c, x), Z.Z.mul(c, y)), Laws.dist_l(c, x, y))

# ---------------------------------------------------------------------------
# multiplying by succ / pred on the left
# ---------------------------------------------------------------------------

def mul_succ_neg(n: Nat, +x: Z.Z) -> {Z.Z.mul(Z.Z.succ_neg(n), x) == Z.Z.add(x, Z.Z.neg(Z.Z.mul_pos(n, x))) : Z.Z}:
  match n:
    case 0n:
      zero_add_neg(x)
    case 1n++p:
      %add_neg_neg(x, Z.Z.mul_pos(p, x)) : {Z.Z.neg(Z.Z.mul_pos(p, x)) == Z.Z.add(x, _) : Z.Z}
      %assoc_r(x, Z.Z.neg(x), Z.Z.neg(Z.Z.mul_pos(p, x))) : {Z.Z.neg(Z.Z.mul_pos(p, x)) == _ : Z.Z}
      %zero_add_neg(x) : {Z.Z.neg(Z.Z.mul_pos(p, x)) == Z.Z.add(_, Z.Z.neg(Z.Z.mul_pos(p, x))) : Z.Z}
      {==}

def mul_succ_l(+a: Z.Z, +x: Z.Z) -> {Z.Z.mul(Z.Z.succ(a), x) == Z.Z.add(x, Z.Z.mul(a, x)) : Z.Z}:
  match a:
    case Z.Zero{}:
      PA.zero_add_r(x)
    case Z.Pos{n}:
      {==}
    case Z.Neg{n}:
      mul_succ_neg(n, x)

# flipped: x + a*x == succ(a) * x
def succ_mul_l(+a: Z.Z, +x: Z.Z) -> {Z.Z.add(x, Z.Z.mul(a, x)) == Z.Z.mul(Z.Z.succ(a), x) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(Z.Z.succ(a), x), Z.Z.add(x, Z.Z.mul(a, x)), mul_succ_l(a, x))

def mul_pred_pos(n: Nat, +x: Z.Z) -> {Z.Z.mul(Z.Z.pred_pos(n), x) == Z.Z.add(Z.Z.neg(x), Z.Z.mul_pos(n, x)) : Z.Z}:
  match n:
    case 0n:
      %LA.add_comm(x, Z.Z.neg(x)) : {Z.Zero{} == _ : Z.Z}
      zero_add_neg(x)
    case 1n++p:
      %assoc_r(Z.Z.neg(x), x, Z.Z.mul_pos(p, x)) : {Z.Z.mul_pos(p, x) == _ : Z.Z}
      %LA.add_comm(x, Z.Z.neg(x)) : {Z.Z.mul_pos(p, x) == Z.Z.add(_, Z.Z.mul_pos(p, x)) : Z.Z}
      %zero_add_neg(x) : {Z.Z.mul_pos(p, x) == Z.Z.add(_, Z.Z.mul_pos(p, x)) : Z.Z}
      {==}

def mul_pred_l(+a: Z.Z, +x: Z.Z) -> {Z.Z.mul(Z.Z.pred(a), x) == Z.Z.add(Z.Z.neg(x), Z.Z.mul(a, x)) : Z.Z}:
  match a:
    case Z.Zero{}:
      PA.zero_add_r(Z.Z.neg(x))
    case Z.Pos{n}:
      mul_pred_pos(n, x)
    case Z.Neg{n}:
      LA.neg_add(x, Z.Z.mul_pos(n, x))

# flipped: (-x) + a*x == pred(a) * x
def pred_mul_l(+a: Z.Z, +x: Z.Z) -> {Z.Z.add(Z.Z.neg(x), Z.Z.mul(a, x)) == Z.Z.mul(Z.Z.pred(a), x) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(Z.Z.pred(a), x), Z.Z.add(Z.Z.neg(x), Z.Z.mul(a, x)), mul_pred_l(a, x))

# ---------------------------------------------------------------------------
# right distributivity
# ---------------------------------------------------------------------------

def dist_r_pos(n: Nat, +b: Z.Z, +x: Z.Z) -> {Z.Z.mul(Z.Z.add_pos(n, b), x) == Z.Z.add(Z.Z.mul_pos(n, x), Z.Z.mul(b, x)) : Z.Z}:
  match n:
    case 0n:
      mul_succ_l(b, x)
    case 1n++p:
      %succ_mul_l(Z.Z.add_pos(p, b), x) : {_ == Z.Z.add(Z.Z.add(x, Z.Z.mul_pos(p, x)), Z.Z.mul(b, x)) : Z.Z}
      %LA.add_assoc(x, Z.Z.mul_pos(p, x), Z.Z.mul(b, x)) : {Z.Z.add(x, Z.Z.mul(Z.Z.add_pos(p, b), x)) == _ : Z.Z}
      %dist_r_pos(p, b, x) : {Z.Z.add(x, Z.Z.mul(Z.Z.add_pos(p, b), x)) == Z.Z.add(x, _) : Z.Z}
      {==}

def dist_r_neg(n: Nat, +b: Z.Z, +x: Z.Z) -> {Z.Z.mul(Z.Z.add_neg(n, b), x) == Z.Z.add(Z.Z.neg(Z.Z.mul_pos(n, x)), Z.Z.mul(b, x)) : Z.Z}:
  match n:
    case 0n:
      mul_pred_l(b, x)
    case 1n++p:
      %pred_mul_l(Z.Z.add_neg(p, b), x) : {_ == Z.Z.add(Z.Z.neg(Z.Z.add(x, Z.Z.mul_pos(p, x))), Z.Z.mul(b, x)) : Z.Z}
      %add_neg_neg(x, Z.Z.mul_pos(p, x)) : {Z.Z.add(Z.Z.neg(x), Z.Z.mul(Z.Z.add_neg(p, b), x)) == Z.Z.add(_, Z.Z.mul(b, x)) : Z.Z}
      %LA.add_assoc(Z.Z.neg(x), Z.Z.neg(Z.Z.mul_pos(p, x)), Z.Z.mul(b, x)) : {Z.Z.add(Z.Z.neg(x), Z.Z.mul(Z.Z.add_neg(p, b), x)) == _ : Z.Z}
      %dist_r_neg(p, b, x) : {Z.Z.add(Z.Z.neg(x), Z.Z.mul(Z.Z.add_neg(p, b), x)) == Z.Z.add(Z.Z.neg(x), _) : Z.Z}
      {==}

def Laws.dist_r(a, b, x):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      dist_r_pos(n, b, x)
    case Z.Neg{n}:
      dist_r_neg(n, b, x)

# flipped: a*x + b*x == (a + b) * x
def add_mul_r(+a: Z.Z, +b: Z.Z, +x: Z.Z) -> {Z.Z.add(Z.Z.mul(a, x), Z.Z.mul(b, x)) == Z.Z.mul(Z.Z.add(a, b), x) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(Z.Z.add(a, b), x), Z.Z.add(Z.Z.mul(a, x), Z.Z.mul(b, x)), Laws.dist_r(a, b, x))

# ---------------------------------------------------------------------------
# associativity
# ---------------------------------------------------------------------------

def mul_pos_assoc(n: Nat, +b: Z.Z, +c: Z.Z) -> {Z.Z.mul_pos(n, Z.Z.mul(b, c)) == Z.Z.mul(Z.Z.mul_pos(n, b), c) : Z.Z}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %add_mul_r(b, Z.Z.mul_pos(p, b), c) : {Z.Z.add(Z.Z.mul(b, c), Z.Z.mul_pos(p, Z.Z.mul(b, c))) == _ : Z.Z}
      %mul_pos_assoc(p, b, c) : {Z.Z.add(Z.Z.mul(b, c), Z.Z.mul_pos(p, Z.Z.mul(b, c))) == Z.Z.add(Z.Z.mul(b, c), _) : Z.Z}
      {==}

def Laws.mul_assoc(a, b, c):
  match a:
    case Z.Zero{}:
      {==}
    case Z.Pos{n}:
      mul_pos_assoc(n, b, c)
    case Z.Neg{+n}:
      %neg_mul_l(Z.Z.mul_pos(n, b), c) : {Z.Z.neg(Z.Z.mul_pos(n, Z.Z.mul(b, c))) == _ : Z.Z}
      %mul_pos_assoc(n, b, c) : {Z.Z.neg(Z.Z.mul_pos(n, Z.Z.mul(b, c))) == Z.Z.neg(_) : Z.Z}
      {==}

# ---------------------------------------------------------------------------
# commutativity
# ---------------------------------------------------------------------------

# a + a*x == a * succ(x)   (succ(x) is add(Pos{0n}, x) definitionally)
def mul_succ_r(+a: Z.Z, +x: Z.Z) -> {Z.Z.add(a, Z.Z.mul(a, x)) == Z.Z.mul(a, Z.Z.succ(x)) : Z.Z}:
  %add_mul_l(a, Z.Pos{0n}, x) : {Z.Z.add(a, Z.Z.mul(a, x)) == _ : Z.Z}
  %one_mul_r(a) : {Z.Z.add(a, Z.Z.mul(a, x)) == Z.Z.add(_, Z.Z.mul(a, x)) : Z.Z}
  {==}

def mul_pos_comm(n: Nat, +b: Z.Z) -> {Z.Z.mul_pos(n, b) == Z.Z.mul(b, Z.Pos{n}) : Z.Z}:
  match n:
    case 0n:
      one_mul_r(b)
    case 1n++p:
      %mul_succ_r(b, Z.Pos{p}) : {Z.Z.add(b, Z.Z.mul_pos(p, b)) == _ : Z.Z}
      %mul_pos_comm(p, b) : {Z.Z.add(b, Z.Z.mul_pos(p, b)) == Z.Z.add(b, _) : Z.Z}
      {==}

def Laws.mul_comm(a, b):
  match a:
    case Z.Zero{}:
      %Laws.mul_zero_r(b) : {_ == Z.Z.mul(b, Z.Zero{}) : Z.Z}
      {==}
    case Z.Pos{n}:
      mul_pos_comm(n, b)
    case Z.Neg{+n}:
      %neg_mul_r(b, Z.Pos{n}) : {Z.Z.neg(Z.Z.mul_pos(n, b)) == _ : Z.Z}
      %mul_pos_comm(n, b) : {Z.Z.neg(Z.Z.mul_pos(n, b)) == Z.Z.neg(_) : Z.Z}
      {==}
