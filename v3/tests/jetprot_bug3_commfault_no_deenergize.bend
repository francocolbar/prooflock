import Base
import ./../jetprot.bend as S
import ./../enum_jetprot.bend as E

# NEGATIVE 3 (regression of H2) - a communication fault that latches PTN without
# de-energizing (a to_ptn that forgets the units). P2 must be FALSE.
def to_ptn_bug(f: S.Fin) -> S.Fin:
  match f:
    case S.Fin{p, l, d, pl, nb, rf}:
      S.Fin{p, S.LPtn{}, d, pl, nb, rf}

def witness() -> S.Fin:
  S.Fin{S.Heating1{}, S.LNone{}, S.DmsIdle{}, True{}, S.On{}, S.Off{}}

law ptn_deenergizes_on_commfault:
  {S.pr_p2(witness(), to_ptn_bug(witness())) == True{} : Bool}

def ptn_deenergizes_on_commfault():
  {==}
