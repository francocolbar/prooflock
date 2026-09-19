import Base
import ./../jetprot.bend as S
import ./../enum_jetprot.bend as E

# NEGATIVE 2 (regression of H2/H16) - a JTT that moves the phase to Termination without
# taking the heating out of full power. The next state has a unit On in Termination, so the
# control invariant (I1) is not preserved: pr_pres must be FALSE.
def soft_apply_bug(req: S.Level, f: S.Fin) -> S.Fin:
  match f:
    case S.Fin{p, l, d, pl, nb, rf}:
      S.Fin{S.jtt_phase(req, p), S.LJtt{}, d, pl, nb, rf}

def witness() -> S.Fin:
  S.Fin{S.Heating2{}, S.LNone{}, S.DmsIdle{}, True{}, S.On{}, S.Off{}}

law inv_survives_jtt_without_ramp:
  {S.pr_pres(witness(), soft_apply_bug(S.LJtt{}, witness())) == True{} : Bool}

def inv_survives_jtt_without_ramp():
  {==}
