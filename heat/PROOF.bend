# PROOF.bend - proofs of LAWS.bend. Lemmas are stated with the term to eliminate
# on the RIGHT (rewrite convention: `%e : P` replaces the right side of e).

import Base
import ./ir.bend as IR
import ./LAWS.bend as Laws

# ---------------------------------------------------------------------------
# Nat lemmas (Base ships none of these)
# ---------------------------------------------------------------------------

def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def mul_zero(a: Nat) -> {Nat.mul(a, 0n) == 0n : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      mul_zero(p)

def mul_one(a: Nat) -> {Nat.mul(a, 1n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %mul_one(p) : {1n+Nat.mul(p, 1n) == 1n+_ : Nat}
      {==}

# ---------------------------------------------------------------------------
# The smart constructors are sound (each lemma mirrors one helper of ir.bend)
# ---------------------------------------------------------------------------

def add_cl_go_sound(x: Nat, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.add(x, IR.eval(b, env)) == IR.eval(IR.add_cl_go(x, b), env) : Nat}:
  match x:
    case 0n:
      {==}
    case 1n+p:
      {==}

def add_cl_sound(x: Nat, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.add(x, IR.eval(b, env)) == IR.eval(IR.add_cl(x, b), env) : Nat}:
  match b:
    case IR.Const{y}:
      {==}
    case IR.Var{k}:
      add_cl_go_sound(x, IR.Var{k}, env)
    case IR.Add{c, d}:
      add_cl_go_sound(x, IR.Add{c, d}, env)
    case IR.Mul{c, d}:
      add_cl_go_sound(x, IR.Mul{c, d}, env)

def add_rc_sound(a: IR.Expr, y: Nat, +env: List<&2, Nat>) -> {Nat.add(IR.eval(a, env), y) == IR.eval(IR.add_rc(a, y), env) : Nat}:
  match y:
    case 0n:
      add_zero(IR.eval(a, env))
    case 1n+p:
      {==}

def add_r_sound(a: IR.Expr, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.add(IR.eval(a, env), IR.eval(b, env)) == IR.eval(IR.add_r(a, b), env) : Nat}:
  match b:
    case IR.Const{y}:
      add_rc_sound(a, y, env)
    case IR.Var{k}:
      {==}
    case IR.Add{c, d}:
      {==}
    case IR.Mul{c, d}:
      {==}

def smart_add_sound(a: IR.Expr, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.add(IR.eval(a, env), IR.eval(b, env)) == IR.eval(IR.smart_add(a, b), env) : Nat}:
  match a:
    case IR.Const{x}:
      add_cl_sound(x, b, env)
    case IR.Var{k}:
      add_r_sound(IR.Var{k}, b, env)
    case IR.Add{c, d}:
      add_r_sound(IR.Add{c, d}, b, env)
    case IR.Mul{c, d}:
      add_r_sound(IR.Mul{c, d}, b, env)

def mul_cl_go_sound(x: Nat, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.mul(x, IR.eval(b, env)) == IR.eval(IR.mul_cl_go(x, b), env) : Nat}:
  match x:
    case 0n:
      {==}
    case 1n:
      add_zero(IR.eval(b, env))
    case 2n+p:
      {==}

def mul_cl_sound(x: Nat, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.mul(x, IR.eval(b, env)) == IR.eval(IR.mul_cl(x, b), env) : Nat}:
  match b:
    case IR.Const{y}:
      {==}
    case IR.Var{k}:
      mul_cl_go_sound(x, IR.Var{k}, env)
    case IR.Add{c, d}:
      mul_cl_go_sound(x, IR.Add{c, d}, env)
    case IR.Mul{c, d}:
      mul_cl_go_sound(x, IR.Mul{c, d}, env)

def mul_rc_sound(a: IR.Expr, y: Nat, +env: List<&2, Nat>) -> {Nat.mul(IR.eval(a, env), y) == IR.eval(IR.mul_rc(a, y), env) : Nat}:
  match y:
    case 0n:
      mul_zero(IR.eval(a, env))
    case 1n:
      mul_one(IR.eval(a, env))
    case 2n+p:
      {==}

def mul_r_sound(a: IR.Expr, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.mul(IR.eval(a, env), IR.eval(b, env)) == IR.eval(IR.mul_r(a, b), env) : Nat}:
  match b:
    case IR.Const{y}:
      mul_rc_sound(a, y, env)
    case IR.Var{k}:
      {==}
    case IR.Add{c, d}:
      {==}
    case IR.Mul{c, d}:
      {==}

def smart_mul_sound(a: IR.Expr, b: IR.Expr, +env: List<&2, Nat>) -> {Nat.mul(IR.eval(a, env), IR.eval(b, env)) == IR.eval(IR.smart_mul(a, b), env) : Nat}:
  match a:
    case IR.Const{x}:
      mul_cl_sound(x, b, env)
    case IR.Var{k}:
      mul_r_sound(IR.Var{k}, b, env)
    case IR.Add{c, d}:
      mul_r_sound(IR.Add{c, d}, b, env)
    case IR.Mul{c, d}:
      mul_r_sound(IR.Mul{c, d}, b, env)

# ---------------------------------------------------------------------------
# The laws
# ---------------------------------------------------------------------------

# induction on the expression; each compound case folds the smart constructor's
# lemma, then the two induction hypotheses
def Laws.simplify_sound(e, env):
  match e:
    case IR.Var{k}:
      {==}
    case IR.Const{c}:
      {==}
    case IR.Add{+a, +b}:
      %smart_add_sound(IR.simplify(a), IR.simplify(b), env) : {_ == Nat.add(IR.eval(a, env), IR.eval(b, env)) : Nat}
      %Laws.simplify_sound(a, env) : {Nat.add(IR.eval(IR.simplify(a), env), IR.eval(IR.simplify(b), env)) == Nat.add(_, IR.eval(b, env)) : Nat}
      %Laws.simplify_sound(b, env) : {Nat.add(IR.eval(IR.simplify(a), env), IR.eval(IR.simplify(b), env)) == Nat.add(IR.eval(IR.simplify(a), env), _) : Nat}
      {==}
    case IR.Mul{+a, +b}:
      %smart_mul_sound(IR.simplify(a), IR.simplify(b), env) : {_ == Nat.mul(IR.eval(a, env), IR.eval(b, env)) : Nat}
      %Laws.simplify_sound(a, env) : {Nat.mul(IR.eval(IR.simplify(a), env), IR.eval(IR.simplify(b), env)) == Nat.mul(_, IR.eval(b, env)) : Nat}
      %Laws.simplify_sound(b, env) : {Nat.mul(IR.eval(IR.simplify(a), env), IR.eval(IR.simplify(b), env)) == Nat.mul(IR.eval(IR.simplify(a), env), _) : Nat}
      {==}

# closed claims: the checker computes both sides
def Laws.weights_sum():
  {==}

def Laws.weights_symmetric():
  {==}

# ---------------------------------------------------------------------------
# Nat lemmas for linear_exact (orientation: the term to eliminate on the right)
# ---------------------------------------------------------------------------

# a == a + 0 : eliminates a stuck Nat.add(x, 0n) in the goal
def add_zero_sym(a: Nat) -> {a == Nat.add(a, 0n) : Nat}:
  Equal.sym(Nat, Nat.add(a, 0n), a, add_zero(a))

def add_succ(a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {2n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def add_swap(x: Nat, +y: Nat, +z: Nat) -> {Nat.add(x, Nat.add(y, z)) == Nat.add(y, Nat.add(x, z)) : Nat}:
  match x:
    case 0n:
      {==}
    case 1n+q:
      %add_succ(y, Nat.add(q, z)) : {1n+Nat.add(q, Nat.add(y, z)) == _ : Nat}
      %add_swap(q, y, z) : {1n+Nat.add(q, Nat.add(y, z)) == 1n+_ : Nat}
      {==}

def add_assoc(+a: Nat, +b: Nat, +c: Nat) -> {Nat.add(a, Nat.add(b, c)) == Nat.add(Nat.add(a, b), c) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_assoc(p, b, c) : {1n+Nat.add(p, Nat.add(b, c)) == 1n+_ : Nat}
      {==}

# the stencil unfolds to pure Nat.add algebra over a and b (S = a + b):
#   (a+0) + ((S + (S+0)) + ((a + (b + (b+0))) + 0))  ==  S + (S + (S + (S+0)))
# strip the zeros, reassociate, and commute the summands into the same order
def Laws.linear_exact(a, b):
  # 1. strip the five Nat.add(_, 0n) left by Mul{Const 1, _}, Mul{Const 2, _} and the trailing Const 0
  %add_zero_sym(a) : {Nat.add(_, Nat.add(Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), 0n)), Nat.add(Nat.add(Nat.add(a, Nat.add(b, Nat.add(b, 0n))), 0n), 0n))) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), 0n)))) : Nat}
  %add_zero_sym(Nat.add(a, b)) : {Nat.add(a, Nat.add(Nat.add(Nat.add(a, b), _), Nat.add(Nat.add(Nat.add(a, Nat.add(b, Nat.add(b, 0n))), 0n), 0n))) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), _))) : Nat}
  %add_zero_sym(b) : {Nat.add(a, Nat.add(Nat.add(Nat.add(a, b), Nat.add(a, b)), Nat.add(Nat.add(Nat.add(a, Nat.add(b, _)), 0n), 0n))) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, b)))) : Nat}
  %add_zero_sym(Nat.add(a, Nat.add(b, b))) : {Nat.add(a, Nat.add(Nat.add(Nat.add(a, b), Nat.add(a, b)), Nat.add(_, 0n))) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, b)))) : Nat}
  %add_zero_sym(Nat.add(a, Nat.add(b, b))) : {Nat.add(a, Nat.add(Nat.add(Nat.add(a, b), Nat.add(a, b)), _)) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, b)))) : Nat}
  # 2. left side: a + ((S + S) + (a + 2b))  ->  S + (S + (a + (a + 2b)))
  %add_assoc(Nat.add(a, b), Nat.add(a, b), Nat.add(a, Nat.add(b, b))) : {Nat.add(a, _) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, b)))) : Nat}
  %add_swap(Nat.add(a, b), a, Nat.add(Nat.add(a, b), Nat.add(a, Nat.add(b, b)))) : {_ == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, b)))) : Nat}
  %add_swap(Nat.add(a, b), a, Nat.add(a, Nat.add(b, b))) : {Nat.add(Nat.add(a, b), _) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, b)))) : Nat}
  # 3. right side: S + S = (a + b) + (a + b)  ->  a + (b + (a + b))  ->  a + (a + (b + b))
  %add_assoc(a, b, Nat.add(a, b)) : {Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, Nat.add(a, Nat.add(b, b))))) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), _)) : Nat}
  %add_swap(a, b, b) : {Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, Nat.add(a, Nat.add(b, b))))) == Nat.add(Nat.add(a, b), Nat.add(Nat.add(a, b), Nat.add(a, _))) : Nat}
  {==}
