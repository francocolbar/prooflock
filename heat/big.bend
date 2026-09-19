# big.bend - a minimal arbitrary-precision natural number, because Bend's Nat aborts
# at 2^48. Representation: little-endian limbs in base 2^16 (List<&2, Nat>), so a
# limb product (< 2^32) plus carries never approaches the 2^48 limit. Only what the
# exact oracle needs: from_nat, add, mul (schoolbook), and a limb dump for Python.
# Tested against Python's int in run.py; its correctness is NOT proven (see the
# findings document for what proving it would take).

import Base

def Big.base() -> Nat:
  U32.to_nat(65536)

# a carry as a (possibly empty) top limb
def Big.push(carry: Nat) -> List<&2, Nat>:
  match carry:
    case 0n:
      Nil{}
    case 1n+p:
      [1n+p]

# propagate a carry into the remaining limbs of one operand
def Big.carry_into(xs: List<&2, Nat>, carry: Nat) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Big.push(carry)
    case Con{x, xt}:
      +t = Nat.add(x, carry)
      Nat.mod(t, Big.base()) <> Big.carry_into(xt, Nat.div(t, Big.base()))

# xs + ys + carry, recursing on ys (the first parameter shrinks)
def Big.add_go(ys: List<&2, Nat>, xs: List<&2, Nat>, carry: Nat) -> List<&2, Nat>:
  match ys xs:
    case Nil{} xs2:
      Big.carry_into(xs2, carry)
    case Con{y, yt} Nil{}:
      +t = Nat.add(y, carry)
      Nat.mod(t, Big.base()) <> Big.add_go(yt, Nil{}, Nat.div(t, Big.base()))
    case Con{y, yt} Con{x, xt}:
      +t = Nat.add(Nat.add(x, y), carry)
      Nat.mod(t, Big.base()) <> Big.add_go(yt, xt, Nat.div(t, Big.base()))

def Big.add(xs: List<&2, Nat>, ys: List<&2, Nat>) -> List<&2, Nat>:
  Big.add_go(ys, xs, 0n)

# ys * k + carry for a small k (< 2^16)
def Big.mul_small(ys: List<&2, Nat>, +k: Nat, carry: Nat) -> List<&2, Nat>:
  match ys:
    case Nil{}:
      Big.push(carry)
    case Con{y, yt}:
      +t = Nat.add(Nat.mul(y, k), carry)
      Nat.mod(t, Big.base()) <> Big.mul_small(yt, k, Nat.div(t, Big.base()))

# schoolbook: xs * ys = x0 * ys + base * (xs' * ys)
def Big.mul(xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{x, xt}:
      Big.add(Big.mul_small(ys, x, 0n), 0n <> Big.mul(xt, ys))

# a Nat below 2^48 as (at most) `fuel` limbs
def Big.from_go(fuel: Nat, n: Nat) -> List<&2, Nat>:
  match fuel:
    case 0n:
      Nil{}
    case 1n+f:
      +m = n
      Nat.mod(m, Big.base()) <> Big.from_go(f, Nat.div(m, Big.base()))

def Big.from_nat(n: Nat) -> List<&2, Nat>:
  Big.from_go(4n, n)

# limbs, little-endian, ':'-separated (Python reassembles: sum(l << 16*i))
def Big.dump(xs: List<&2, Nat>) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{h, t}:
      Nat.show(h) ++ ":" ++ Big.dump(t)
