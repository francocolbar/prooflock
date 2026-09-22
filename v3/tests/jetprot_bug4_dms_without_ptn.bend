import Base
import ./../jetprot.bend as S
import ./../spec_jetprot.bend as Spec
import ./../enum_jetprot.bend as E

# NEGATIVE 4 - the DMS armed by a soft stop (no PTN). The next state has the DMS armed with
# level RTPS, so I4 (dms only under PTN) is not preserved: pr_pres must be FALSE.
def stop_fin_bug(f: S.Fin, req: S.Level, d: Bool) -> S.Fin:
  match req:
    case S.LPtn{}:
      S.arm_if(d, S.to_ptn(f))
    case r2:
      S.arm_if(d, S.soft_apply(r2, f))

def witness() -> S.Fin:
  S.Fin{S.Heating1{}, False{}, S.LNone{}, S.DmsIdle{}, True{}, True{}, S.Off{}, S.Off{}}

law inv_survives_soft_arming:
  {Spec.pr_pres(witness(), stop_fin_bug(witness(), S.LRtps{}, True{})) == True{} : Bool}

def inv_survives_soft_arming():
  {==}
