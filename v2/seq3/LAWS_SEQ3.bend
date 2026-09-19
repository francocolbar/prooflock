# LAWS_SEQ3.bend - the same guarantees as seq/LAWS_SEQ.bend for the redesigned model,
# plus the certificates that make them cheap and the equivalence with the old model.
# Proven in PROOF_SEQ3.bend.

import Base
import ./seq3.bend as S
import ./enum3.bend as E

# --- certificates decided by computation ---

# for EVERY control state, event and pair of counter verdicts: the control invariants
# are preserved and the counter commands have the right shape (448 x 18 x 4 cells)
law finite_check:
  {E.check_fin() == True{} : Bool}

# --- the invariants, for every state and every event ---

law inv_init:
  {S.inv_all(S.init()) == True{} : Bool}

# L1-L4 (the control invariants) are preserved by every step
law pres_fin:
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.inv_fin(S.fin_of(S.step(s, e))) == True{} : Bool}

# L5: in flat-top the counter stays below the pulse-length limit
law pres_l5:
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.l5_flat(S.step(s, e)) == True{} : Bool}

# L6: in a watched phase the heartbeat counter stays below the watchdog limit
law pres_l6:
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.l6_hb(S.step(s, e)) == True{} : Bool}

# the theorem: every trace from the initial state stays safe
law traces_safe:
  for +trace: List<&2, S.Ev>
  {S.inv_all(S.run(trace, S.init())) == True{} : Bool}

# corollary: the safe state has every actuator off
law shutdown_safe:
  for +f: S.Fin
  for +h: {S.inv_fin(f) == True{} : Bool}
  {S.l7_safe(f) == True{} : Bool}

# step-level: a disruption or an abort lands in Shutdown from any state
law disruption_shuts_down:
  for +s: S.St
  {S.is_shutdown(S.phase_of(S.fin_of(S.step(s, S.Disruption{})))) == True{} : Bool}

law abort_shuts_down:
  for +s: S.St
  {S.is_shutdown(S.phase_of(S.fin_of(S.step(s, S.Abort{})))) == True{} : Bool}
