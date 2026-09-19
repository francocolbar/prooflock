# big.bend - arbitrary-precision naturals as little-endian bit lists, with a
# structural meaning (to_nat) so that add/inc/from_nat can be PROVEN correct
# (LAWS_BIG.bend). Nat aborts at 2^48 at run time; a bit list does not.
# Only what the exact oracle needs: add, inc, from_nat, bit-string I/O.

import Base

def Big.bit(b: Bool) -> Nat:
  match b:
    case True{}:
      1n
    case False{}:
      0n

# the meaning: little-endian binary
def Big.to_nat(xs: List<&2, Bool>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{b, t}:
      Nat.add(Big.bit(b), Nat.double(Big.to_nat(t)))

# full adder
def Big.sum3(a: Bool, b: Bool, c: Bool) -> Bool:
  Bool.xor(Bool.xor(a, b), c)

def Big.carry3(+a: Bool, +b: Bool, +c: Bool) -> Bool:
  Bool.or(Bool.and(a, b), Bool.and(c, Bool.xor(a, b)))

# xs + carry
def Big.add_carry(xs: List<&2, Bool>, c: Bool) -> List<&2, Bool>:
  match xs c:
    case Nil{} False{}:
      Nil{}
    case Nil{} True{}:
      [True{}]
    case Con{+x, xt} +c2:
      Bool.xor(x, c2) <> Big.add_carry(xt, Bool.and(x, c2))

# xs + ys + carry, recursing on xs
def Big.add_go(xs: List<&2, Bool>, ys: List<&2, Bool>, c: Bool) -> List<&2, Bool>:
  match xs ys:
    case Nil{} ys2:
      Big.add_carry(ys2, c)
    case Con{x, xt} Nil{}:
      Big.add_carry(x <> xt, c)
    case Con{+x, xt} Con{+y, yt}:
      +c2 = c
      Big.sum3(x, y, c2) <> Big.add_go(xt, yt, Big.carry3(x, y, c2))

def Big.add(xs: List<&2, Bool>, ys: List<&2, Bool>) -> List<&2, Bool>:
  Big.add_go(xs, ys, False{})

def Big.inc(xs: List<&2, Bool>) -> List<&2, Bool>:
  Big.add_carry(xs, True{})

# a small Nat as bits (structural: n increments; only for constants)
def Big.from_nat(n: Nat) -> List<&2, Bool>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Big.inc(Big.from_nat(p))

# I/O: '0'/'1' characters, least significant bit first
def Big.parse(s: String) -> List<&2, Bool>:
  match s:
    case SNil{}:
      Nil{}
    case SCon{h, t}:
      Char.is_eq(h, '1') <> Big.parse(t)

def Big.show(xs: List<&2, Bool>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{True{}, t}:
      "1" ++ Big.show(t)
    case Con{False{}, t}:
      "0" ++ Big.show(t)
