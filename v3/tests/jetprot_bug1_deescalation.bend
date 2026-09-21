import Base
import ./../jetprot.bend as S
import ./../spec_jetprot.bend as Spec
import ./../enum_jetprot.bend as E

# NEGATIVE 1 - de-escalation: a soft request replaces the level without the comparison.
# Witness: an RTPS stop in progress in Heating 2, a JTT request arrives -> the buggy variant
# LOWERS the level to JTT. P1 (latched) must be FALSE on this cell: the checker must reject.
def stop_fin_bug(f: S.Fin, req: S.Level, d: Bool) -> S.Fin:
  match req:
    case S.LPtn{}:
      S.arm_if(d, S.to_ptn(f))
    case r2:
      S.soft_apply(r2, f)

def witness() -> S.Fin:
  S.Fin{S.Heating2{}, S.LRtps{}, S.DmsIdle{}, True{}, S.Ramping{}, S.Off{}}

law latched_survives_deescalation:
  {Spec.pr_p1(S.Ord1{}, witness(), S.Stop{S.LJtt{}, False{}}, stop_fin_bug(witness(), S.LJtt{}, False{})) == True{} : Bool}

def latched_survives_deescalation():
  {==}
