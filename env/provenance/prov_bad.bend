import Base

# Provenance as a type index: a Field is tagged (at the type level) with the
# code version and the geometry id it was computed from. -ver/-geom are erased:
# they cost nothing at runtime and exist only for the checker.
type Field<-ver: Nat, -geom: Nat> is Data:
  Mk{values: List<&2, Nat>}

def geom_a() -> Nat:
  7n

def geom_b() -> Nat:
  8n

# a solver at code version 3 over geometry g
def solve(-g: Nat, +seed: Nat) -> Field<3n, g>:
  Mk{[seed, Nat.add(seed, 1n)]}

# a diagnostic that only accepts fields from version 3 AND geometry geom_a()
def diag(f: Field<3n, geom_a()>) -> Nat:
  match f:
    case Mk{vs}:
      List.length(&2, Nat, vs)

def ok() -> Nat:
  diag(solve(geom_a(), 1n))

# uncomment to see the checker reject a geometry mismatch:
def bad() -> Nat:
  diag(solve(geom_b(), 1n))

def main() -> Nat:
  ok()
