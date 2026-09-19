# ir.bend - the symbolic layer of the 1D heat-equation PoC.
#
#   u_t = alpha u_xx   ->  centred second difference in space + explicit Euler in time
#   u_i' = u_i + r (u_{i-1} - 2 u_i + u_{i+1}),   r = alpha dt / dx^2
#
# With r = p / 2^q (a dyadic rational) and 2p <= 2^q (the CFL condition r <= 1/2) the
# update is a NON-NEGATIVE integer combination over the common denominator D = 2^q:
#
#   D u_i' = p u_{i-1} + (D - 2p) u_i + p u_{i+1}
#
# That is what lets the whole symbolic layer live in Nat: the IR below has exact
# integer semantics (`eval`), a simplifier (`simplify`) whose soundness is a law in
# LAWS.bend, a printer to JAX (`py`) used by emit.bend, and the same `eval` is the
# exact oracle used by oracle.bend.

import Base

# ---------------------------------------------------------------------------
# Expression IR
# ---------------------------------------------------------------------------

# Var{k}: the k-th value of the local window [u_{i-1}, u_i, u_{i+1}] (k = 0, 1, 2).
# Const{c}: a non-negative integer coefficient.
type Expr is Data:
  Var{k: Nat}
  Const{c: Nat}
  Add{a: Expr, b: Expr}
  Mul{a: Expr, b: Expr}

# total lookup: out-of-range reads 0 (keeps eval total and simple to reason about)
def lookup(k: Nat, env: List<&2, Nat>) -> Nat:
  match k env:
    case _ Nil{}:
      0n
    case 0n Con{h, t}:
      h
    case 1n+p Con{h, t}:
      lookup(p, t)

# exact semantics over Nat
def eval(e: Expr, +env: List<&2, Nat>) -> Nat:
  match e:
    case Var{k}:
      lookup(k, env)
    case Const{c}:
      c
    case Add{a, b}:
      Nat.add(eval(a, env), eval(b, env))
    case Mul{a, b}:
      Nat.mul(eval(a, env), eval(b, env))

# ---------------------------------------------------------------------------
# Simplifier: constant folding + identity/annihilator elimination.
# Every helper matches ONE parameter, so each one gets its own soundness lemma
# in PROOF.bend that mirrors it exactly.
# ---------------------------------------------------------------------------

# x + b, where b is known NOT to be a constant
def add_cl_go(x: Nat, b: Expr) -> Expr:
  match x:
    case 0n:
      b
    case 1n+p:
      Add{Const{1n+p}, b}

# x + b (x a constant)
def add_cl(x: Nat, b: Expr) -> Expr:
  match b:
    case Const{y}:
      Const{Nat.add(x, y)}
    case b2:
      add_cl_go(x, b2)

# a + y, where a is known NOT to be a constant
def add_rc(a: Expr, y: Nat) -> Expr:
  match y:
    case 0n:
      a
    case 1n+p:
      Add{a, Const{1n+p}}

# a + b, where a is known NOT to be a constant
def add_r(a: Expr, b: Expr) -> Expr:
  match b:
    case Const{y}:
      add_rc(a, y)
    case b2:
      Add{a, b2}

def smart_add(a: Expr, b: Expr) -> Expr:
  match a:
    case Const{x}:
      add_cl(x, b)
    case a2:
      add_r(a2, b)

# x * b, where b is known NOT to be a constant: 0 * b = 0, 1 * b = b
def mul_cl_go(x: Nat, b: Expr) -> Expr:
  match x:
    case 0n:
      Const{0n}
    case 1n:
      b
    case 2n+p:
      Mul{Const{2n+p}, b}

# x * b (x a constant)
def mul_cl(x: Nat, b: Expr) -> Expr:
  match b:
    case Const{y}:
      Const{Nat.mul(x, y)}
    case b2:
      mul_cl_go(x, b2)

# a * y, where a is known NOT to be a constant
def mul_rc(a: Expr, y: Nat) -> Expr:
  match y:
    case 0n:
      Const{0n}
    case 1n:
      a
    case 2n+p:
      Mul{a, Const{2n+p}}

# a * b, where a is known NOT to be a constant
def mul_r(a: Expr, b: Expr) -> Expr:
  match b:
    case Const{y}:
      mul_rc(a, y)
    case b2:
      Mul{a, b2}

def smart_mul(a: Expr, b: Expr) -> Expr:
  match a:
    case Const{x}:
      mul_cl(x, b)
    case a2:
      mul_r(a2, b)

# bottom-up: simplify the children, then rebuild through the smart constructors
def simplify(e: Expr) -> Expr:
  match e:
    case Var{k}:
      Var{k}
    case Const{c}:
      Const{c}
    case Add{a, b}:
      smart_add(simplify(a), simplify(b))
    case Mul{a, b}:
      smart_mul(simplify(a), simplify(b))

# ---------------------------------------------------------------------------
# The PDE discretization: r = p / 2^q
# ---------------------------------------------------------------------------

type Scheme is Data:
  Scheme{p: Nat, q: Nat}

# the scheme of this PoC: r = 1/4
def heat_scheme() -> Scheme:
  Scheme{1n, 2n}

def den(s: Scheme) -> Nat:
  match s:
    case Scheme{p, q}:
      Nat.pow(2n, q)

# stencil weights [w_{-1}, w_0, w_{+1}] = [p, D - 2p, p]; Nat.sub saturates, so a
# scheme with 2p > D (r > 1/2) yields weights that do not sum to D: the law
# `weights_sum` in LAWS.bend is therefore also the CFL certificate.
def weights(s: Scheme) -> List<&2, Nat>:
  match s:
    case Scheme{+p, q}:
      +d = Nat.pow(2n, q)
      [p, Nat.sub(d, Nat.mul(2n, p)), p]

def sum(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{h, t}:
      Nat.add(h, sum(t))

# the stencil as a naive expression tree: a fold producing
#   Add(Mul(Const w0, Var 0), Add(Mul(Const w1, Var 1), Add(Mul(Const w2, Var 2), Const 0)))
# so that the simplifier has real work to do (Mul by 1, Add 0, Mul by 0 when r = 1/2).
def stencil_go(ws: List<&2, Nat>, +k: Nat) -> Expr:
  match ws:
    case Nil{}:
      Const{0n}
    case Con{w, t}:
      Add{Mul{Const{w}, Var{k}}, stencil_go(t, 1n+k)}

def stencil(s: Scheme) -> Expr:
  stencil_go(weights(s), 0n)

# ---------------------------------------------------------------------------
# Printers
# ---------------------------------------------------------------------------

# the IR itself (for comments and the findings document)
def show(e: Expr) -> String:
  match e:
    case Var{k}:
      "Var " ++ Nat.show(k)
    case Const{c}:
      "Const " ++ Nat.show(c)
    case Add{a, b}:
      "Add(" ++ show(a) ++ ", " ++ show(b) ++ ")"
    case Mul{a, b}:
      "Mul(" ++ show(a) ++ ", " ++ show(b) ++ ")"

# Python/JAX: the window variables become slices of the whole grid vector
def py_var(k: Nat) -> String:
  match k:
    case 0n:
      "u[:-2]"
    case 1n:
      "u[1:-1]"
    case 2n:
      "u[2:]"
    case 3n+p:
      "u_out_of_window"

def py(e: Expr) -> String:
  match e:
    case Var{k}:
      py_var(k)
    case Const{c}:
      Nat.show(c) ++ ".0"
    case Add{a, b}:
      "(" ++ py(a) ++ " + " ++ py(b) ++ ")"
    case Mul{a, b}:
      "(" ++ py(a) ++ " * " ++ py(b) ++ ")"
