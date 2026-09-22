import Base
import ./../jetprot.bend as S
import ./../spec_jetprot.bend as Spec
import ./../enum_jetprot.bend as E

# NEGATIVE 7 (H15) - an RTPS stop with no effect on the heating (the principal hazard
# without a law in revision 2). P3 (stop_reduces_power) must be FALSE.
def soft_apply_bug(req: S.Level, f: S.Fin) -> S.Fin:
  match f:
    case S.Fin{p, j, l, d, pl, ip, nb, rf}:
      S.Fin{p, j, S.LRtps{}, d, pl, ip, nb, rf}

def witness() -> S.Fin:
  S.Fin{S.Heating1{}, False{}, S.LNone{}, S.DmsIdle{}, True{}, True{}, S.On{}, S.Off{}}

law rtps_stop_reduces_power:
  {Spec.pr_p3(witness(), soft_apply_bug(S.LRtps{}, witness())) == True{} : Bool}

def rtps_stop_reduces_power():
  {==}
