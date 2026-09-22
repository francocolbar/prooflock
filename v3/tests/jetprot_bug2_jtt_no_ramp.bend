import Base
import ./../jetprot.bend as S
import ./../spec_jetprot.bend as Spec
import ./../enum_jetprot.bend as E

# NEGATIVE 2 (regression of H2/H16) - a JTT that switches to the termination waveform without
# taking the heating out of full power. The next state has a unit On under a JTT, so the
# control invariant (I1) is not preserved: pr_pres must be FALSE.
def soft_apply_bug(req: S.Level, f: S.Fin) -> S.Fin:
  match f:
    case S.Fin{p, j, l, d, pl, ip, nb, rf}:
      S.Fin{p, True{}, S.LJtt{}, d, pl, ip, nb, rf}

def witness() -> S.Fin:
  S.Fin{S.Heating2{}, False{}, S.LNone{}, S.DmsIdle{}, True{}, True{}, S.On{}, S.Off{}}

law inv_survives_jtt_without_ramp:
  {Spec.pr_pres(witness(), soft_apply_bug(S.LJtt{}, witness())) == True{} : Bool}

def inv_survives_jtt_without_ramp():
  {==}
