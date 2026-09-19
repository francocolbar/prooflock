# PROOF_HEAT.bend - proofs of LAWS_HEAT.bend on top of the Z ring laws.
#
# The four laws about heat_scheme() are closed terms: the checker computes both
# sides and {==} closes them. lin_sound is a structural induction on the
# expression, one lemma per helper of `lin` (dot/unit, dot/zip_add, dot/scale_list,
# lin_add, lin_scale). weights_sum_all and linear_exact are ring identities in Z
# proved by rewriting with LAWS_Z_ADD / LAWS_Z_MUL (LA.*, LM.*) and the helper
# lemmas of their proof files (PA.*, PM.*).

import Base
import ./../num/z.bend as Z
import ./../num/LAWS_Z_ADD.bend as LA
import ./../num/PROOF_Z_ADD.bend as PA
import ./../num/LAWS_Z_MUL.bend as LM
import ./../num/PROOF_Z_MUL.bend as PM
import ./ir.bend as IR
import ./LAWS_HEAT.bend as Laws

# ---------------------------------------------------------------------------
# ring facts flipped so that the term a rewrite must eliminate sits on the RIGHT
# ---------------------------------------------------------------------------

# 0 == a * 0
def zero_mul_r(+a: Z.Z) -> {Z.Zero{} == Z.Z.mul(a, Z.Zero{}) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.mul(a, Z.Zero{}), Z.Zero{}, LM.mul_zero_r(a))

# (x + y) + (a + b) == (x + a) + (y + b)
def swap4_r(+x: Z.Z, +a: Z.Z, +y: Z.Z, +b: Z.Z) -> {Z.Z.add(Z.Z.add(x, y), Z.Z.add(a, b)) == Z.Z.add(Z.Z.add(x, a), Z.Z.add(y, b)) : Z.Z}:
  Equal.sym(Z.Z, Z.Z.add(Z.Z.add(x, a), Z.Z.add(y, b)), Z.Z.add(Z.Z.add(x, y), Z.Z.add(a, b)), PM.add_swap4(x, a, y, b))

# ---------------------------------------------------------------------------
# the computed laws about heat_scheme()
# ---------------------------------------------------------------------------

def Laws.weights_sum():
  {==}

def Laws.weights_symmetric():
  {==}

def Laws.weights_nonneg():
  {==}

def Laws.no_source():
  {==}

# ---------------------------------------------------------------------------
# lin_sound: one lemma per helper of `lin`
# ---------------------------------------------------------------------------

# dot(e_k, env) == env[k]
def dot_unit(k: Nat, env: List<&2, Z.Z>) -> {IR.dot(IR.unit(k), env) == IR.lookup(k, env) : Z.Z}:
  match k env:
    case 0n Nil{}:
      {==}
    case 1n+p Nil{}:
      {==}
    case 0n Con{h, t}:
      LA.add_zero_r(h)
    case 1n+p Con{h, t}:
      dot_unit(p, t)

# dot(cs + ds, env) == dot(cs, env) + dot(ds, env)
def dot_zip(cs: List<&2, Z.Z>, ds: List<&2, Z.Z>, env: List<&2, Z.Z>) -> {IR.dot(IR.zip_add(cs, ds), env) == Z.Z.add(IR.dot(cs, env), IR.dot(ds, env)) : Z.Z}:
  match cs ds env:
    case Nil{} ds2 env2:
      {==}
    case Con{c, ct} Nil{} env2:
      PA.zero_add_r(IR.dot(Con{c, ct}, env2))
    case Con{c, ct} Con{d, dt} Nil{}:
      {==}
    case Con{+c, +ct} Con{+d, +dt} Con{+x, +xt}:
      %swap4_r(Z.Z.mul(c, x), IR.dot(ct, xt), Z.Z.mul(d, x), IR.dot(dt, xt)) : {Z.Z.add(Z.Z.mul(Z.Z.add(c, d), x), IR.dot(IR.zip_add(ct, dt), xt)) == _ : Z.Z}
      %LM.dist_r(c, d, x) : {Z.Z.add(Z.Z.mul(Z.Z.add(c, d), x), IR.dot(IR.zip_add(ct, dt), xt)) == Z.Z.add(_, Z.Z.add(IR.dot(ct, xt), IR.dot(dt, xt))) : Z.Z}
      %dot_zip(ct, dt, xt) : {Z.Z.add(Z.Z.mul(Z.Z.add(c, d), x), IR.dot(IR.zip_add(ct, dt), xt)) == Z.Z.add(Z.Z.mul(Z.Z.add(c, d), x), _) : Z.Z}
      {==}

# dot(c * cs, env) == c * dot(cs, env)
def dot_scale(+c: Z.Z, cs: List<&2, Z.Z>, env: List<&2, Z.Z>) -> {IR.dot(IR.scale_list(c, cs), env) == Z.Z.mul(c, IR.dot(cs, env)) : Z.Z}:
  match cs env:
    case Nil{} env2:
      zero_mul_r(c)
    case Con{d, dt} Nil{}:
      zero_mul_r(c)
    case Con{+d, +dt} Con{+x, +xt}:
      %PM.add_mul_l(c, Z.Z.mul(d, x), IR.dot(dt, xt)) : {Z.Z.add(Z.Z.mul(Z.Z.mul(c, d), x), IR.dot(IR.scale_list(c, dt), xt)) == _ : Z.Z}
      %LM.mul_assoc(c, d, x) : {Z.Z.add(_, IR.dot(IR.scale_list(c, dt), xt)) == Z.Z.add(Z.Z.mul(c, Z.Z.mul(d, x)), Z.Z.mul(c, IR.dot(dt, xt))) : Z.Z}
      %dot_scale(c, dt, xt) : {Z.Z.add(Z.Z.mul(c, Z.Z.mul(d, x)), IR.dot(IR.scale_list(c, dt), xt)) == Z.Z.add(Z.Z.mul(c, Z.Z.mul(d, x)), _) : Z.Z}
      {==}

# eval_lin(l1 + l2) == eval_lin(l1) + eval_lin(l2), for Lin VALUES (lin(a) is stuck while a is symbolic)
def lin_add_sound(l1: IR.Lin, l2: IR.Lin, +env: List<&2, Z.Z>) -> {IR.eval_lin(IR.lin_add(l1, l2), env) == Z.Z.add(IR.eval_lin(l1, env), IR.eval_lin(l2, env)) : Z.Z}:
  match l1 l2:
    case IR.Lin{+cs, +k1} IR.Lin{+ds, +k2}:
      %swap4_r(IR.dot(cs, env), k1, IR.dot(ds, env), k2) : {Z.Z.add(IR.dot(IR.zip_add(cs, ds), env), Z.Z.add(k1, k2)) == _ : Z.Z}
      %dot_zip(cs, ds, env) : {Z.Z.add(IR.dot(IR.zip_add(cs, ds), env), Z.Z.add(k1, k2)) == Z.Z.add(_, Z.Z.add(k1, k2)) : Z.Z}
      {==}

# eval_lin(c * l) == c * eval_lin(l)
def lin_scale_sound(+c: Z.Z, l: IR.Lin, +env: List<&2, Z.Z>) -> {IR.eval_lin(IR.lin_scale(c, l), env) == Z.Z.mul(c, IR.eval_lin(l, env)) : Z.Z}:
  match l:
    case IR.Lin{+cs, +k}:
      %PM.add_mul_l(c, IR.dot(cs, env), k) : {Z.Z.add(IR.dot(IR.scale_list(c, cs), env), Z.Z.mul(c, k)) == _ : Z.Z}
      %dot_scale(c, cs, env) : {Z.Z.add(IR.dot(IR.scale_list(c, cs), env), Z.Z.mul(c, k)) == Z.Z.add(_, Z.Z.mul(c, k)) : Z.Z}
      {==}

def Laws.lin_sound(e, env):
  match e:
    case IR.Var{+k}:
      %PA.zero_add_r(IR.dot(IR.unit(k), env)) : {_ == IR.lookup(k, env) : Z.Z}
      dot_unit(k, env)
    case IR.Const{c}:
      {==}
    case IR.Add{+a, +b}:
      %Laws.lin_sound(a, env) : {IR.eval_lin(IR.lin_add(IR.lin(a), IR.lin(b)), env) == Z.Z.add(_, IR.eval(b, env)) : Z.Z}
      %Laws.lin_sound(b, env) : {IR.eval_lin(IR.lin_add(IR.lin(a), IR.lin(b)), env) == Z.Z.add(IR.eval_lin(IR.lin(a), env), _) : Z.Z}
      lin_add_sound(IR.lin(a), IR.lin(b), env)
    case IR.Scale{+c, +e2}:
      %Laws.lin_sound(e2, env) : {IR.eval_lin(IR.lin_scale(c, IR.lin(e2)), env) == Z.Z.mul(c, _) : Z.Z}
      lin_scale_sound(c, IR.lin(e2), env)

# ---------------------------------------------------------------------------
# weights_sum_all: for every p, q the weights sum to D = 2^q
# ---------------------------------------------------------------------------

# After unfolding lin(stencil(Scheme{p, q})) the weights are
#   [D*0 + P*1, D*1 + P*(-1), P*1]   with D = from_nat(2^q), P = from_nat(p)
# (Z.mul is stuck on the symbolic D and P), and the goal is their sum == D.
def Laws.weights_sum_all(p, q):
  +D = Z.Z.from_nat(Nat.pow(2n, q))
  +P = Z.Z.from_nat(p)
  %zero_mul_r(D) : {Z.Z.add(Z.Z.add(_, Z.Z.mul(P, Z.Pos{0n})), Z.Z.add(Z.Z.add(Z.Z.mul(D, Z.Pos{0n}), Z.Z.mul(P, Z.Neg{1n})), Z.Z.add(Z.Z.mul(P, Z.Pos{0n}), Z.Zero{}))) == D : Z.Z}
  %PM.one_mul_r(P) : {Z.Z.add(_, Z.Z.add(Z.Z.add(Z.Z.mul(D, Z.Pos{0n}), Z.Z.mul(P, Z.Neg{1n})), Z.Z.add(_, Z.Zero{}))) == D : Z.Z}
  %PM.one_mul_r(D) : {Z.Z.add(P, Z.Z.add(Z.Z.add(_, Z.Z.mul(P, Z.Neg{1n})), Z.Z.add(P, Z.Zero{}))) == D : Z.Z}
  %PA.zero_add_r(P) : {Z.Z.add(P, Z.Z.add(Z.Z.add(D, Z.Z.mul(P, Z.Neg{1n})), _)) == D : Z.Z}
  %PM.neg_mul_r(P, Z.Pos{1n}) : {Z.Z.add(P, Z.Z.add(Z.Z.add(D, _), P)) == D : Z.Z}
  %PM.mul_succ_r(P, Z.Pos{0n}) : {Z.Z.add(P, Z.Z.add(Z.Z.add(D, Z.Z.neg(_)), P)) == D : Z.Z}
  %PM.one_mul_r(P) : {Z.Z.add(P, Z.Z.add(Z.Z.add(D, Z.Z.neg(Z.Z.add(P, _))), P)) == D : Z.Z}
  +X = Z.Z.neg(Z.Z.add(P, P))
  %LA.add_comm(P, Z.Z.add(D, X)) : {Z.Z.add(P, _) == D : Z.Z}
  %PM.add_swap(D, P, X) : {Z.Z.add(P, _) == D : Z.Z}
  %PM.add_swap(D, P, Z.Z.add(P, X)) : {_ == D : Z.Z}
  %PM.assoc_r(P, P, X) : {Z.Z.add(D, _) == D : Z.Z}
  %PM.zero_add_neg(Z.Z.add(P, P)) : {Z.Z.add(D, _) == D : Z.Z}
  LA.add_zero_r(D)

# ---------------------------------------------------------------------------
# linear_exact: the residual a + (-(S+S) + (a + (b+b))) vanishes, S = a + b
# ---------------------------------------------------------------------------

# 0 == a + (-(S + S) + (a + (b + b)))
def zero_res(+a: Z.Z, +b: Z.Z) -> {Z.Zero{} == Z.Z.add(a, Z.Z.add(Z.Z.neg(Z.Z.add(Z.Z.add(a, b), Z.Z.add(a, b))), Z.Z.add(a, Z.Z.add(b, b)))) : Z.Z}:
  +S2 = Z.Z.add(Z.Z.add(a, b), Z.Z.add(a, b))
  +N = Z.Z.neg(S2)
  %PM.add_swap(N, a, Z.Z.add(a, Z.Z.add(b, b))) : {Z.Zero{} == _ : Z.Z}
  %PM.assoc_r(a, a, Z.Z.add(b, b)) : {Z.Zero{} == Z.Z.add(N, _) : Z.Z}
  %PM.add_swap4(a, b, a, b) : {Z.Zero{} == Z.Z.add(N, _) : Z.Z}
  %LA.add_comm(S2, N) : {Z.Zero{} == _ : Z.Z}
  PM.zero_add_neg(S2)

def Laws.linear_exact(a, b):
  +T = Z.Z.mul(Z.Pos{3n}, Z.Z.add(a, b))
  %zero_res(a, b) : {Z.Z.add(T, _) == T : Z.Z}
  LA.add_zero_r(T)
