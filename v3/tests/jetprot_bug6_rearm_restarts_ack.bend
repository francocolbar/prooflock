import Base
import ./../jetprot.bend as S
import ./../spec_jetprot.bend as Spec
import ./../enum_jetprot.bend as E

# NEGATIVE 6 (H6/H14) - a repeated stop request that restarts the acknowledgement wait: the
# wait-counter command is a Reset even though the DMS was already armed. P18 (tack_frame)
# must be FALSE for this variant.
def upd_tack_bug(f: S.Fin, e: S.Ev, bt: Bool, bh: Bool) -> S.Upd:
  match e:
    case S.Stop{req, dms}:
      S.reset_if(Bool.and(S.is_ptn(req), dms))
    case e2:
      S.upd_tack(f, e2, bt, bh)

def pr_p18_bug(+f: S.Fin, +e: S.Ev, +bt: Bool, +bh: Bool) -> Bool:
  S.implies(Bool.and(S.is_armed(S.dms_of(f)), Bool.and(Bool.not(Spec.is_tick(e)), Bool.not(Spec.is_reset(e)))),
            S.is_keep(upd_tack_bug(f, e, bt, bh)))

def witness() -> S.Fin:
  S.Fin{S.Heating2{}, False{}, S.LPtn{}, S.DmsArmed{}, True{}, True{}, S.Off{}, S.Off{}}

law repeated_stop_keeps_the_wait:
  {pr_p18_bug(witness(), S.Stop{S.LPtn{}, True{}}, True{}, True{}) == True{} : Bool}

def repeated_stop_keeps_the_wait():
  {==}
