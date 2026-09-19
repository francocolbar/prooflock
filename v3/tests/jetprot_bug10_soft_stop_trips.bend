import Base
import ./../jetprot.bend as S

# NEGATIVE 10 (the adversarial audit's mutant M04) - a soft stop that TRIPS the heating units
# to Off instead of ramping them down. It preserves every invariant (I1 and I2 constrain
# Ramping but never require it), and the old law set could not see it: P3 only said the units
# are not left at full power. It is a fidelity defect too: [S2] says the RTPS ramps the
# heating power down for a softer landing, and [S6] gives the engineering reason (beam duct
# pressure, antenna lines). D2 (soft_stop_ramps) is the law that catches it.
def soft_apply_bug(+req: S.Level, f: S.Fin) -> S.Fin:
  match f:
    case S.Fin{p, l, d, pl, nb, rf}:
      S.Fin{S.jtt_phase(req, p), req, d, pl, S.deenergize(nb), S.deenergize(rf)}

def witness() -> S.Fin:
  S.Fin{S.Heating1{}, S.LNone{}, S.DmsIdle{}, True{}, S.On{}, S.On{}}

law soft_stop_ramps_when_it_trips:
  {S.pr_d2(S.Ord1{}, witness(), S.Stop{S.LRtps{}, False{}}, soft_apply_bug(S.LRtps{}, witness())) == True{} : Bool}

def soft_stop_ramps_when_it_trips():
  {==}
