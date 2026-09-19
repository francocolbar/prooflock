# LAWS_SEQ.bend - the safety of the discharge sequencer, for EVERY trace of events.
# Proven in PROOF_SEQ.bend. The six invariant components are stated one by one
# (each proof spends only the hypotheses it needs); traces_safe puts them together.

import Base
import ./seq.bend as S

# the initial state satisfies every invariant (decided by computation)
law inv_init:
  {S.inv_all(S.init()) == True{} : Bool}

# --- preservation: if every invariant holds in s, each one holds in step(s, e) ---

# L1: gas or plasma in the vessel only with vacuum and field
law pres_l1:
  for +s: S.St
  for h1: {S.l1_field(s) == True{} : Bool}
  for h2: {S.l2_heat(s) == True{} : Bool}
  for h3: {S.l3_cs(s) == True{} : Bool}
  for h4: {S.l4_gas(s) == True{} : Bool}
  for h5: {S.l5_flat(s) == True{} : Bool}
  for h6: {S.l6_hb(s) == True{} : Bool}
  for +e: S.Ev
  {S.l1_field(S.step(s, e)) == True{} : Bool}

# L2: heating only in flat-top with the density in its window
law pres_l2:
  for +s: S.St
  for h1: {S.l1_field(s) == True{} : Bool}
  for h2: {S.l2_heat(s) == True{} : Bool}
  for h3: {S.l3_cs(s) == True{} : Bool}
  for h4: {S.l4_gas(s) == True{} : Bool}
  for h5: {S.l5_flat(s) == True{} : Bool}
  for h6: {S.l6_hb(s) == True{} : Bool}
  for +e: S.Ev
  {S.l2_heat(S.step(s, e)) == True{} : Bool}

# L3: the solenoid is energized only in breakdown / flat-top / ramp-down
law pres_l3:
  for +s: S.St
  for h1: {S.l1_field(s) == True{} : Bool}
  for h2: {S.l2_heat(s) == True{} : Bool}
  for h3: {S.l3_cs(s) == True{} : Bool}
  for h4: {S.l4_gas(s) == True{} : Bool}
  for h5: {S.l5_flat(s) == True{} : Bool}
  for h6: {S.l6_hb(s) == True{} : Bool}
  for +e: S.Ev
  {S.l3_cs(S.step(s, e)) == True{} : Bool}

# L4: the prefill valve is open only during prefill
law pres_l4:
  for +s: S.St
  for h1: {S.l1_field(s) == True{} : Bool}
  for h2: {S.l2_heat(s) == True{} : Bool}
  for h3: {S.l3_cs(s) == True{} : Bool}
  for h4: {S.l4_gas(s) == True{} : Bool}
  for h5: {S.l5_flat(s) == True{} : Bool}
  for h6: {S.l6_hb(s) == True{} : Bool}
  for +e: S.Ev
  {S.l4_gas(S.step(s, e)) == True{} : Bool}

# L5: the flat-top counter stays below the pulse-length limit
law pres_l5:
  for +s: S.St
  for h1: {S.l1_field(s) == True{} : Bool}
  for h2: {S.l2_heat(s) == True{} : Bool}
  for h3: {S.l3_cs(s) == True{} : Bool}
  for h4: {S.l4_gas(s) == True{} : Bool}
  for h5: {S.l5_flat(s) == True{} : Bool}
  for h6: {S.l6_hb(s) == True{} : Bool}
  for +e: S.Ev
  {S.l5_flat(S.step(s, e)) == True{} : Bool}

# L6: in a watched phase the heartbeat counter stays below the watchdog limit
law pres_l6:
  for +s: S.St
  for h1: {S.l1_field(s) == True{} : Bool}
  for h2: {S.l2_heat(s) == True{} : Bool}
  for h3: {S.l3_cs(s) == True{} : Bool}
  for h4: {S.l4_gas(s) == True{} : Bool}
  for h5: {S.l5_flat(s) == True{} : Bool}
  for h6: {S.l6_hb(s) == True{} : Bool}
  for +e: S.Ev
  {S.l6_hb(S.step(s, e)) == True{} : Bool}

# --- the theorem: every trace of events from the initial state stays safe ---
law traces_safe:
  for +trace: List<&2, S.Ev>
  {S.inv_all(S.run(trace, S.init())) == True{} : Bool}

# --- corollary: the safe state has every actuator off (follows from L2, L3, L4) ---
law shutdown_safe:
  for +s: S.St
  for h2: {S.l2_heat(s) == True{} : Bool}
  for h3: {S.l3_cs(s) == True{} : Bool}
  for h4: {S.l4_gas(s) == True{} : Bool}
  {S.l7_safe(s) == True{} : Bool}

# --- step-level: a disruption or an abort ALWAYS lands in Shutdown, from any state ---
law disruption_shuts_down:
  for +s: S.St
  {S.is_shutdown(S.phase_of(S.step(s, S.Disruption{}))) == True{} : Bool}

law abort_shuts_down:
  for +s: S.St
  {S.is_shutdown(S.phase_of(S.step(s, S.Abort{}))) == True{} : Bool}
