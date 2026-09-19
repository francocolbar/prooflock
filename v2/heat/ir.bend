# ir.bend (v2) - the symbolic layer over Z.
#
#   u_t = alpha u_xx, centred second difference + explicit Euler, r = alpha dt / dx^2 = p / 2^q.
#   Written the way physics writes it, with a common denominator D = 2^q:
#
#       D u_i' = D u_i + p (u_{i-1} - 2 u_i + u_{i+1})
#
# The IR is LINEAR BY CONSTRUCTION (Scale{c, e} is the only product), so every
# expression has a normal form Lin{coeffs, const} = sum_k coeffs_k * u_k + const.
# `lin` computes it; LAWS_HEAT.bend states that it keeps the exact meaning (`eval`).
# The kernel is printed from the normal form; the oracle evaluates the raw tree.

import Base
import ./../num/z.bend as Z

# ---------------------------------------------------------------------------
# Expressions and their meaning
# ---------------------------------------------------------------------------

type Expr is Data:
  Var{k: Nat}
  Const{c: Z.Z}
  Add{a: Expr, b: Expr}
  Scale{c: Z.Z, e: Expr}

# total lookup: out-of-window reads 0
def lookup(k: Nat, env: List<&2, Z.Z>) -> Z.Z:
  match k env:
    case _ Nil{}:
      Z.Zero{}
    case 0n Con{h, t}:
      h
    case 1n+p Con{h, t}:
      lookup(p, t)

def eval(e: Expr, +env: List<&2, Z.Z>) -> Z.Z:
  match e:
    case Var{k}:
      lookup(k, env)
    case Const{c}:
      c
    case Add{a, b}:
      Z.Z.add(eval(a, env), eval(b, env))
    case Scale{c, e2}:
      Z.Z.mul(c, eval(e2, env))

# ---------------------------------------------------------------------------
# Linear normal form
# ---------------------------------------------------------------------------

type Lin is Data:
  Lin{coeffs: List<&2, Z.Z>, const: Z.Z}

# sum_k cs_k * xs_k; a missing entry on either side is 0
def dot(cs: List<&2, Z.Z>, xs: List<&2, Z.Z>) -> Z.Z:
  match cs xs:
    case Nil{} _:
      Z.Zero{}
    case Con{c, ct} Nil{}:
      Z.Zero{}
    case Con{c, ct} Con{x, xt}:
      Z.Z.add(Z.Z.mul(c, x), dot(ct, xt))

def eval_lin(l: Lin, env: List<&2, Z.Z>) -> Z.Z:
  match l:
    case Lin{cs, k}:
      Z.Z.add(dot(cs, env), k)

# the unit vector e_k
def unit(k: Nat) -> List<&2, Z.Z>:
  match k:
    case 0n:
      [Z.Pos{0n}]
    case 1n+p:
      Z.Zero{} <> unit(p)

def zip_add(cs: List<&2, Z.Z>, ds: List<&2, Z.Z>) -> List<&2, Z.Z>:
  match cs ds:
    case Nil{} ds2:
      ds2
    case Con{c, ct} Nil{}:
      c <> ct
    case Con{c, ct} Con{d, dt}:
      Z.Z.add(c, d) <> zip_add(ct, dt)

def scale_list(+c: Z.Z, cs: List<&2, Z.Z>) -> List<&2, Z.Z>:
  match cs:
    case Nil{}:
      Nil{}
    case Con{d, dt}:
      Z.Z.mul(c, d) <> scale_list(c, dt)

def lin_add(l1: Lin, l2: Lin) -> Lin:
  match l1 l2:
    case Lin{cs, k1} Lin{ds, k2}:
      Lin{zip_add(cs, ds), Z.Z.add(k1, k2)}

def lin_scale(+c: Z.Z, l: Lin) -> Lin:
  match l:
    case Lin{cs, k}:
      Lin{scale_list(c, cs), Z.Z.mul(c, k)}

def lin(e: Expr) -> Lin:
  match e:
    case Var{k}:
      Lin{unit(k), Z.Zero{}}
    case Const{c}:
      Lin{Nil{}, c}
    case Add{a, b}:
      lin_add(lin(a), lin(b))
    case Scale{c, e2}:
      lin_scale(c, lin(e2))

def coeffs_of(l: Lin) -> List<&2, Z.Z>:
  match l:
    case Lin{cs, k}:
      cs

def const_of(l: Lin) -> Z.Z:
  match l:
    case Lin{cs, k}:
      k

def sum(cs: List<&2, Z.Z>) -> Z.Z:
  match cs:
    case Nil{}:
      Z.Zero{}
    case Con{c, t}:
      Z.Z.add(c, sum(t))

def all_nonneg(cs: List<&2, Z.Z>) -> Bool:
  match cs:
    case Nil{}:
      True{}
    case Con{c, t}:
      Bool.and(Z.Z.is_nonneg(c), all_nonneg(t))

# ---------------------------------------------------------------------------
# The scheme, as physics writes it
# ---------------------------------------------------------------------------

type Scheme is Data:
  Scheme{p: Nat, q: Nat}

def heat_scheme() -> Scheme:
  Scheme{1n, 2n}

def den_nat(s: Scheme) -> Nat:
  match s:
    case Scheme{p, q}:
      Nat.pow(2n, q)

def den(s: Scheme) -> Z.Z:
  Z.Z.from_nat(den_nat(s))

def p_of(s: Scheme) -> Nat:
  match s:
    case Scheme{p, q}:
      p

# D u_i' = D * u_i + p * (u_{i-1} + (-2) * u_i + u_{i+1})
def stencil(s: Scheme) -> Expr:
  match s:
    case Scheme{p, q}:
      Add{Scale{Z.Z.from_nat(Nat.pow(2n, q)), Var{1n}},
          Scale{Z.Z.from_nat(p), Add{Var{0n}, Add{Scale{Z.Neg{1n}, Var{1n}}, Var{2n}}}}}

def weights(s: Scheme) -> List<&2, Z.Z>:
  coeffs_of(lin(stencil(s)))

# ---------------------------------------------------------------------------
# Printers
# ---------------------------------------------------------------------------

def show(e: Expr) -> String:
  match e:
    case Var{k}:
      "Var " ++ Nat.show(k)
    case Const{c}:
      "Const " ++ Z.Z.show(c)
    case Add{a, b}:
      "Add(" ++ show(a) ++ ", " ++ show(b) ++ ")"
    case Scale{c, e2}:
      "Scale(" ++ Z.Z.show(c) ++ ", " ++ show(e2) ++ ")"

def show_zs(cs: List<&2, Z.Z>) -> String:
  match cs:
    case Nil{}:
      ""
    case Con{c, t}:
      Z.Z.show(c) ++ " " ++ show_zs(t)

def show_lin(l: Lin) -> String:
  match l:
    case Lin{cs, k}:
      "Lin{[" ++ show_zs(cs) ++ "], " ++ Z.Z.show(k) ++ "}"

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

# the JAX expression of a normal form: (c0.0) * u[:-2] + (c1.0) * u[1:-1] + ... + (k.0)
def py_terms(cs: List<&2, Z.Z>, +k: Nat) -> String:
  match cs:
    case Nil{}:
      ""
    case Con{c, t}:
      "(" ++ Z.Z.show(c) ++ ".0) * " ++ py_var(k) ++ " + " ++ py_terms(t, 1n+k)

def py_lin(l: Lin) -> String:
  match l:
    case Lin{cs, k}:
      py_terms(cs, 0n) ++ "(" ++ Z.Z.show(k) ++ ".0)"
