# LAWS_JETPROT.bend - the laws of the JET protection-chain model (docs/fase3-diseno.md §2).
# Certificates by computation: finite_check (chosen order), finite_check_alt (the swapped
# order, sensitivity C3 as a theorem), corollaries_check. Every step law is universal over
# the order, the control state, the abstract event and BOTH verdicts, so it holds for every
# configuration and every counter value. The step laws are P1..P21, the demand and frame laws
# D1..D18 and E1..E11, and V1 (verdict_frame_*) justifies the certificate's reduced column set.
# Proven in PROOF_JETPROT_FIN.bend, PROOF_JETPROT_FIN_ALT.bend, PROOF_JETPROT_COR.bend and
# PROOF_JETPROT.bend.

import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec
import ./enum_jetprot.bend as E

# --- certificates decided by computation ---

# C1: for EVERY order, control state, abstract event and pair of counter verdicts, the
# control invariants are preserved, the counter commands have the right shape, and the step
# laws P1..P20 hold (2 x 80 640 cells)
law finite_check:
  {E.check_fin(S.Ord1{}) == True{} : Bool}

law finite_check_alt:
  {E.check_fin(S.Ord2{}) == True{} : Bool}

# the state corollaries under inv_fin (2688 states)
law corollaries_check:
  {E.check_cor() == True{} : Bool}

# --- the invariants, for every order, state and event ---

law inv_init:
  {S.inv_all(S.init()) == True{} : Bool}

# I1-I4 (the control invariants) are preserved by every step
law pres_fin:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.inv_fin(S.fin_of(S.step_o(o, s, e))) == True{} : Bool}

# I5: while the DMS is armed the wait counter stays below the limit
law pres_i5:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.i5_ack(S.step_o(o, s, e)) == True{} : Bool}

# I6: while the PTN is not latched the missed heartbeats stay below the limit
law pres_i6:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.inv_all(s) == True{} : Bool}
  for +e: S.Ev
  {S.i6_hb(S.step_o(o, s, e)) == True{} : Bool}

# P21, the theorem: every trace over the abstract alphabet (any configuration) stays safe
law traces_safe:
  for +o: S.Ord
  for +trace: List<&2, S.Ev>
  {S.inv_all(S.run_o(o, trace, S.init())) == True{} : Bool}

# the same over the concrete alphabet through either configuration instance
law traces_safe_concrete:
  for +i: S.Inst
  for +trace: List<&2, S.CEv>
  {S.inv_all(S.run_c(i, trace, S.init())) == True{} : Bool}

# --- the step laws (P1..P20), universal over the cell (order, state, event, verdicts) ---

# P1: stops never degrade (e != Reset => level' >= level)
law latched:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P2: the step that reaches PTN leaves no unit powered
law ptn_deenergizes:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p2(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P3: the step that starts a soft stop takes every unit out of full power
law stop_reduces_power:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p3(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P4: a ramping unit never returns to full power
law ramping_never_returns:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P5: HeatOn turns a unit on iff Off, in the window, with plasma and no stop
law heat_permissive:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p5(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P6: with a stop in force nothing switches on
law stop_overrides_heat:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p6(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P7: no unit energizes without its command
law heat_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p7(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P8: a local inhibit lasts the pulse
law inhibit_latched:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p8(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P9: a local alarm inhibits its unit and changes nothing else (control and counters)
law local_is_local:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p9(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P10: the level changes only on Stop, CommFault, Reset, or a Tick with the watchdog expired
law no_spurious_stop:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p10(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P12: a communication fault is a PTN stop from any state
law commfault_ptn:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p12(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P14: the program never rewinds
law phase_monotone:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p14(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P15: the DMS never disarms or un-fires
law dms_monotone:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p15(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P16: a stop wired to the DMS that reaches PTN arms it
law dms_armed_on_demand:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p16(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P17: nothing else arms the DMS
law dms_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p17(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P18: while armed, only Tick and Reset touch the wait counter
law tack_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p18(f, e, bt, bh) == True{} : Bool}

# P19: under PTN, Advance is the identity
law advance_frozen:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p19(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P20: an end of pulse is accepted (to init, counters reset) or refused (identity)
law reset_guarded:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p20(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P21: a Reset while the DMS is armed, or before the pulse ended (no PTN and not in
# Termination), leaves the control AND both counter commands unchanged
law reset_refused_mid_pulse:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p21(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# --- the DEMAND and FRAME laws (D1..D18, audit #4): the sequencer does its job ---

# D1: a stop request is honoured -- the level becomes the more urgent of the one in force and the requested one
law d1_stop_honoured:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d1(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D2: an accepted soft stop takes every unit at full power into ramp-down
law d2_soft_stop_ramps:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d2(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D3: the natural end of the programme (Advance out of Heating 2) also ramps down
law d3_advance_to_termination_ramps:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d3(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D4: an expired watchdog latches the PTN, whatever the instance wires to the DMS
law d4_watchdog_latches:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d4(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D5: the heartbeat counter counts while the PTN is not latched (positive dual of I6)
law d5_hb_counts:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d5(f, e, bh) == True{} : Bool}

# D6: only a heartbeat, or an accepted end of pulse, may reset the watchdog counter
law d6_hb_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d6(f, e, bh) == True{} : Bool}

# D7: the acknowledgement timeout fires the DMS
law d7_ack_timeout_fires:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d7(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D8: the acknowledgement wait counts up while below the limit (positive dual of I5)
law d8_ack_counts:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d8(f, e, bt, bh) == True{} : Bool}

# D9: the acknowledgement from the heating plant fires the DMS
law d9_heatack_fires:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d9(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D10: an end of pulse IS accepted when the pulse has ended and no mitigation is armed
law d10_reset_accepted_when_safe:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d10(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D11: the programme advances exactly one phase
law d11_advance_is_one_step:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D12: nothing but Advance, Reset or a JTT stop moves the phase
law d12_phase_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d12(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D13: the plasma conditions are an input -- Plasma{ok} writes ok
law d13_plasma_is_input:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d13(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D14: and only that input, or an accepted end of pulse, moves them
law d14_plasma_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d14(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D15: a heating-off command de-energizes its own unit and touches nothing else
law d15_heatoff_is_local:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d15(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D16: a heating-on command touches its own unit only
law d16_heaton_is_local:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d16(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D17: an acknowledgement moves the DMS and nothing else
law d17_heatack_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d17(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D18: a heartbeat touches the heartbeat counter and nothing else
law d18_heartbeat_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d18(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# --- the remaining DEMAND and FRAME laws (E1..E11, audit #5) ---
#
# These close the eight holes D1..D18 still left open (eleven of twenty-five new mutants survived
# them). Five of the laws above are DERIVED rather than independent evidence and are kept only so
# the earlier write-up stays checkable; a report must not present them as independent (audit #5
# sections 5 and 8; the list is `DERIVED` in pymodel/jetprot_ref.py):
#   D3_advance_to_termination_ramps  subsumed by e4_advance_units (which covers all six advances)
#   D5_hb_counts                     one half of e6_hb_tick_exact
#   D9_heatack_fires                 one half of e11_heatack_exact
#   D10_reset_accepted_when_safe     pointwise implied by P20_reset_guarded; its job is to break
#                                    P20's self-reference (P20 quotes the model's own reset_ok,
#                                    D10 spells the guard out)
#   D12_phase_frame                  its Stop clause is subsumed by e3_stop_phase_exact

# E1: only a local alarm creates an inhibit (nothing else may LATCH a unit)
law e1_inhibit_source:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e1(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# E2: the DMS fires only on the plant acknowledgement or on the acknowledgement timeout
law e2_dms_fire_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e2(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# E3: a stop moves the phase to Termination exactly when an accepted JTT asks for it
law e3_stop_phase_exact:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e3(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# E4: the units after an Advance are fully determined (all six advances, not just the last)
law e4_advance_units:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# E5: a heartbeat ALWAYS restarts the watchdog counter
law e5_heartbeat_resets_hb:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e5(f, e, bh) == True{} : Bool}

# E6: the watchdog counter on a Tick is exactly determined (two-sided D5)
law e6_hb_tick_exact:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e6(f, e, bh) == True{} : Bool}

# E7: only a Tick with the DMS armed and the wait below the limit may increment it
law e7_tack_inc_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e7(f, e, bt, bh) == True{} : Bool}

# E8: only a demand that actually arms, or the accepted end of pulse, restarts the wait
law e8_tack_reset_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e8(f, e, bt, bh) == True{} : Bool}

# E11: the acknowledgement is two-sided (D9 is its positive half)
law e11_heatack_exact:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# --- V1: the verdict domain of the certificate (audit #5, H13 as a theorem) ---
#
# enum_jetprot.bend enumerates the four (bt, bh) pairs for only 5 of its 24 event columns and
# certifies the other 19 at (True, True) alone. That is sound because nothing outside the Tick
# arm reads the verdicts. These three laws say exactly that, for the step and for both counter
# commands, so the reduced column set is a theorem and no longer a mechanical side check.

law verdict_frame_step:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +h: {Spec.is_tick(e) == False{} : Bool}
  for +bt: Bool
  for +bh: Bool
  {S.step_fin(o, f, e, bt, bh) == S.step_fin(o, f, e, True{}, True{}) : S.Fin}

law verdict_frame_hb:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +h: {Spec.is_tick(e) == False{} : Bool}
  for +bt: Bool
  for +bh: Bool
  {S.upd_hb(f, e, bh) == S.upd_hb(f, e, True{}) : S.Upd}

law verdict_frame_tack:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +h: {Spec.is_tick(e) == False{} : Bool}
  for +bt: Bool
  for +bh: Bool
  {S.upd_tack(f, e, bt, bh) == S.upd_tack(f, e, True{}, True{}) : S.Upd}

# --- P20 on states ---

law reset_accepted:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.reset_ok(S.fin_of(s)) == True{} : Bool}
  {S.step_o(o, s, S.Reset{}) == S.init() : S.St}

law reset_refused:
  for +o: S.Ord
  for +s: S.St
  for +h: {S.reset_ok(S.fin_of(s)) == False{} : Bool}
  {S.step_o(o, s, S.Reset{}) == s : S.St}

# --- the state corollaries, universal (from corollaries_check by reflection) ---

law ptn_no_heat:
  for +f: S.Fin
  for +h: {S.inv_fin(f) == True{} : Bool}
  {S.implies(S.is_ptn(S.level_of(f)), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))) == True{} : Bool}

law dms_no_heat:
  for +f: S.Fin
  for +h: {S.inv_fin(f) == True{} : Bool}
  {S.implies(Bool.not(S.is_idle(S.dms_of(f))), Bool.and(S.unpowered(S.nb_of(f)), S.unpowered(S.rf_of(f)))) == True{} : Bool}

law stop_no_full_power:
  for +f: S.Fin
  for +h: {S.inv_fin(f) == True{} : Bool}
  {S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(Bool.not(S.is_on(S.nb_of(f))), Bool.not(S.is_on(S.rf_of(f))))) == True{} : Bool}

law termination_no_full_power:
  for +f: S.Fin
  for +h: {S.inv_fin(f) == True{} : Bool}
  {S.implies(S.is_term(S.phase_of(f)), Bool.and(Bool.not(S.is_on(S.nb_of(f))), Bool.not(S.is_on(S.rf_of(f))))) == True{} : Bool}
