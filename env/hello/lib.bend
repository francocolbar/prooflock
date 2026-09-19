import Base

type Expr is Data:
  Var{}
  Lit{n: Nat}
  Add{a: Expr, b: Expr}
  Mul{a: Expr, b: Expr}

def show(e: Expr) -> String:
  match e:
    case Var{}:
      "x"
    case Lit{n}:
      Nat.show(n)
    case Add{a, b}:
      "(" ++ show(a) ++ " + " ++ show(b) ++ ")"
    case Mul{a, b}:
      "(" ++ show(a) ++ " * " ++ show(b) ++ ")"

def sample() -> Expr:
  Add{Mul{Lit{2n}, Var{}}, Lit{3n}}
