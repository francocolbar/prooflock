# seq_bug_PROOF.bend - a NEGATIVE test. A variant of the interlock with the same bug
# as the production implementation (RampDown is not treated as a plasma phase), and a
# claim that L1 survives losing the vacuum during ramp-down. The claim is FALSE (the
# machine stays in RampDown with vac = False), so the checker must REJECT this file
# with: expected False{} (what l1_field computes) / observed True{}.

import Base
import ./../seq/seq.bend as S

# the buggy predicate: RampDown missing
def is_plasma_bug(p: S.Phase) -> Bool:
  match p:
    case S.Prefill{}:
      True{}
    case S.Breakdown{}:
      True{}
    case S.FlatTop{}:
      True{}
    case _:
      False{}

def interlock_bug(s: S.St) -> S.St:
  match s:
    case S.St{+phase, +vac, +tf, dens, gas, cs, heat, t, hb}:
      S.guard(is_plasma_bug(phase), Bool.and(vac, tf), S.St{phase, vac, tf, dens, gas, cs, heat, t, hb})

def on_vac_bug(s: S.St, ok: Bool) -> S.St:
  match s:
    case S.St{phase, vac, tf, dens, gas, cs, heat, t, hb}:
      interlock_bug(S.St{phase, ok, tf, dens, gas, cs, heat, t, hb})

# ramping down with plasma, vacuum lost: L1 must still hold after the sensor update
law l1_after_vac_loss_in_rampdown:
  {S.l1_field(on_vac_bug(S.St{S.RampDown{}, True{}, True{}, True{}, False{}, True{}, False{}, 2n, 0n}, False{})) == True{} : Bool}

def l1_after_vac_loss_in_rampdown():
  {==}
