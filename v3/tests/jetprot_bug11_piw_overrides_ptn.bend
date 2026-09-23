import Base
import ./../jetprot.bend as S
import ./../spec_jetprot.bend as Spec

# NEGATIVE 11 (revision 4) - a PIW request pre-empts a latched PTN: the soft branch applies any
# non-None request without looking at the level in force, so an RTPS request after a PTN
# lowers the response to RTPS and puts both units into ramp-down. [N1] p.13 calls a PIW
# request after a PTN stop an "invalid task", and p.14 says "a PIW stop can never preempt a
# PTN stop". The named law piw_after_ptn_is_noop (mixed: [N1]'s "invalid task" plus our no-op
# formalisation, A-14) must be FALSE on this cell: the checker must reject.
def stop_fin_bug(f: S.Fin, req: S.Level, d: Bool) -> S.Fin:
  match req:
    case S.LPtn{}:
      S.arm_if(d, S.to_ptn(f))
    case S.LNone{}:
      f
    case r2:
      S.soft_apply(r2, f)

def witness() -> S.Fin:
  S.Fin{S.Heating1{}, False{}, S.LPtn{}, S.DmsIdle{}, True{}, True{}, S.Off{}, S.Off{}}

law piw_after_ptn_is_noop_survives_override:
  {Spec.pr_piw_noop(witness(), S.Stop{S.LRtps{}, False{}}, True{}, True{}, stop_fin_bug(witness(), S.LRtps{}, False{})) == True{} : Bool}

def piw_after_ptn_is_noop_survives_override():
  {==}
