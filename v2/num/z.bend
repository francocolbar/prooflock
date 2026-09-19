# z.bend - canonical integers for SPECIFICATION and small constants.
#
# Zero{} is 0, Pos{n} is n+1, Neg{n} is -(n+1): exactly one representation per
# integer, so propositional equality {a == b : Z} is structural equality and {==}
# closes goals. Every operation is defined through succ/pred so that every law in
# LAWS_Z.bend is a structural induction on a Nat. This makes Z.add O(|a|) at run
# time: Z is the meaning of programs, not their engine (see big.bend / bigz.bend
# for execution at scale).

import Base

type Z is Data:
  Zero{}
  Pos{n: Nat}
  Neg{n: Nat}

# succ of Neg{n}
def Z.succ_neg(n: Nat) -> Z:
  match n:
    case 0n:
      Zero{}
    case 1n+p:
      Neg{p}

def Z.succ(a: Z) -> Z:
  match a:
    case Zero{}:
      Pos{0n}
    case Pos{n}:
      Pos{1n+n}
    case Neg{n}:
      Z.succ_neg(n)

# pred of Pos{n}
def Z.pred_pos(n: Nat) -> Z:
  match n:
    case 0n:
      Zero{}
    case 1n+p:
      Pos{p}

def Z.pred(a: Z) -> Z:
  match a:
    case Zero{}:
      Neg{0n}
    case Pos{n}:
      Z.pred_pos(n)
    case Neg{n}:
      Neg{1n+n}

def Z.neg(a: Z) -> Z:
  match a:
    case Zero{}:
      Zero{}
    case Pos{n}:
      Neg{n}
    case Neg{n}:
      Pos{n}

# succ applied n+1 times to b, i.e. (n+1) + b
def Z.add_pos(n: Nat, b: Z) -> Z:
  match n:
    case 0n:
      Z.succ(b)
    case 1n+p:
      Z.succ(Z.add_pos(p, b))

# pred applied n+1 times to b, i.e. -(n+1) + b
def Z.add_neg(n: Nat, b: Z) -> Z:
  match n:
    case 0n:
      Z.pred(b)
    case 1n+p:
      Z.pred(Z.add_neg(p, b))

def Z.add(a: Z, b: Z) -> Z:
  match a:
    case Zero{}:
      b
    case Pos{n}:
      Z.add_pos(n, b)
    case Neg{n}:
      Z.add_neg(n, b)

def Z.sub(a: Z, b: Z) -> Z:
  Z.add(a, Z.neg(b))

# b added n+1 times, i.e. (n+1) * b
def Z.mul_pos(n: Nat, +b: Z) -> Z:
  match n:
    case 0n:
      b
    case 1n+p:
      Z.add(b, Z.mul_pos(p, b))

def Z.mul(a: Z, b: Z) -> Z:
  match a:
    case Zero{}:
      Zero{}
    case Pos{n}:
      Z.mul_pos(n, b)
    case Neg{n}:
      Z.neg(Z.mul_pos(n, b))

def Z.from_nat(n: Nat) -> Z:
  match n:
    case 0n:
      Zero{}
    case 1n+p:
      Pos{p}

# |a| as a Nat
def Z.abs(a: Z) -> Nat:
  match a:
    case Zero{}:
      0n
    case Pos{n}:
      1n+n
    case Neg{n}:
      1n+n

def Z.is_nonneg(a: Z) -> Bool:
  match a:
    case Zero{}:
      True{}
    case Pos{n}:
      True{}
    case Neg{n}:
      False{}

def Z.is_eq(a: Z, b: Z) -> Bool:
  match a b:
    case Zero{} Zero{}:
      True{}
    case Pos{n} Pos{m}:
      Nat.is_eq(n, m)
    case Neg{n} Neg{m}:
      Nat.is_eq(n, m)
    case _ _:
      False{}

def Z.show(a: Z) -> String:
  match a:
    case Zero{}:
      "0"
    case Pos{n}:
      Nat.show(1n+n)
    case Neg{n}:
      "-" ++ Nat.show(1n+n)
