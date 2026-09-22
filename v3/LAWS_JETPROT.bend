# LAWS_JETPROT.bend - the laws of the JET protection-chain model (docs/fase3-diseno.md §2).
# Certificates by computation: finite_check (chosen order), finite_check_alt (the swapped
# order, sensitivity C3 as a theorem), corollaries_check. Every step law is universal over
# the order, the control state, the abstract event and BOTH verdicts, so it holds for every
# configuration and every counter value. The step laws are P1..P21, the demand and frame laws
# D1..D18 and E2..E11, the fidelity laws F1..IP4 (blocker 4), and V1 (verdict_frame_*)
# justifies the certificate's reduced column set.
# Proven in PROOF_JETPROT_FIN.bend, PROOF_JETPROT_FIN_ALT.bend, PROOF_JETPROT_COR.bend and
# PROOF_JETPROT.bend.

import Base
import ./jetprot.bend as S
import ./spec_jetprot.bend as Spec
import ./enum_jetprot.bend as E

# --- certificates decided by computation ---

# C1: for EVERY order, control state, abstract event and pair of counter verdicts, the
# control invariants are preserved, the counter commands have the right shape, and the step
# laws P1..P21, D1..D18, E2..E11 and F1b..IP4 hold (2 x 462 336 cells: 10 752 control states
# x 43 columns)
law finite_check:
  {E.check_fin(S.Ord1{}) == True{} : Bool}

law finite_check_alt:
  {E.check_fin(S.Ord2{}) == True{} : Bool}

# the state corollaries under inv_fin (10 752 states)
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

# P3: the step that starts a soft stop takes every unit out of power, full or partial (F2c)
law stop_reduces_power:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p3(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P4: a ramping unit never returns to power, full or partial
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

# P6: with a stop in force nothing acquires power
law stop_overrides_heat:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p6(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P7: no unit acquires power without its command
law heat_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p7(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P9: a local alarm reduces its unit (full power -> partial, R-9: F2a + F2b) and changes nothing
# else (control and counters)
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

# P12: an ENABLED communication check is a PTN stop from any state (F3a)
law commfault_ptn:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p12(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P14: neither the program phase nor the waveform phase rewinds
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

# P16: a demand wired to the DMS arms it when the current is above the DMV threshold (IP2, abstract form)
law dms_armed_on_demand:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_p16(f, e, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# P17: nothing else arms the DMS, and nothing does below the threshold
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

# P21: a Reset while the DMS is armed, or before the pulse ended (no PTN and no termination
# waveform), leaves the control AND both counter commands unchanged
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

# D2: an accepted soft stop takes every unit delivering power (full or partial) into ramp-down
law d2_soft_stop_ramps:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d2(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D3: the natural end of the programme (Advance out of Heating 2, program phase) also ramps down
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

# D11: the programme advances exactly one program phase
law d11_advance_is_one_step:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_d11(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# D12: nothing but Advance or Reset moves the PROGRAM phase (a JTT moves the waveform: F1)
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

# --- the remaining DEMAND and FRAME laws (E2..E11, audit #5; E1 went with `Inhibited`, A-26) ---
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

# E2: the DMS fires only on the plant acknowledgement or on the acknowledgement timeout
law e2_dms_fire_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_e2(f, e, bt, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# E3: a stop moves the WAVEFORM phase to Termination exactly when an accepted JTT asks for it
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

# --- the fidelity laws of blocker 4 (docs/STATUS_2026-09-21.md): F1 the two views of time
# ([S2] 3.4, A-24), F2 partial power (R-9), F3 the masked reliability checks (R-13, A-21), IP
# the DMV current threshold (R-14). F1b, F1d, F2a, F3b, IP1, IP3, IP4 are cell laws decided by
# the certificate (group g_f, with F1e, F2d and F4); F1a, F1c and IP2 are proven directly. ---

# F1a: a concrete alarm reads Table 1 on the PROGRAM phase, whatever the waveform flag and
# the rest of the state (A-24). Stated against the enumerator's independent transcription of
# the matrix and the masks, so a read on the waveform phase, a wrong cell or an ignored mask
# all refute it.
law f1a_table_reads_prog:
  for +i: S.Inst
  for +f: S.Fin
  for +t: S.Trig
  {Spec.lvl_eq(Spec.ev_req(S.concretize(i, f, S.XAlarm{t})), E.m_alarm(i, S.prog_of(f), t)) == True{} : Bool}

# F1b: a stop request never moves the program phase (the JTT switches the waveform)
law f1b_stop_keeps_prog:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_f1b(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# F1c: the waveform phase is never behind the program phase (I7; by construction of wave_of)
law f1c_wave_ahead:
  for +f: S.Fin
  {Spec.phase_le(S.prog_of(f), S.wave_of(f)) == True{} : Bool}

# F1d: the waveform phase moves only with the programme, an accepted JTT, or the end of pulse
law f1d_wave_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_f1d(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# F1e: the waveform flag is exactly determined: set by an accepted JTT, cleared by the end of
# pulse, kept otherwise (the tightness metric found two states that differed only in the flag)
law f1e_jtt_exact:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_f1e(o, f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# F4: the units move only with their commands, a plasma loss, the programme, the end of pulse, or a
# step that changes the response (frame; the tightness metric found nothing pinned them under Ip)
law f4_units_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_f4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# F2a: a local alarm takes a unit at full power to PARTIAL power, never off (R-9); the frame
# (nothing else moves) is P9
law f2a_local_reduces:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_f2a(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# F2d: a unit at partial power never returns to full power in the pulse (R-9 as modelled, A-6)
law f2d_reduced_never_returns:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_f2d(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# F3b: a communication check the instance disables is the identity, counters included (A-21);
# the enabled check is P12
law f3b_commfault_masked_is_noop:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_f3b(f, e, bt, bh, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# IP1: below the DMV current threshold the DMS never arms, whatever the event (R-14)
law ip1_low_never_arms:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_ip1(f, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# IP2 (demand, concrete form): with the current above the threshold, the DMS idle, and a
# concrete alarm that the instance maps to PTN and wires to the DMS inside the window, the
# alarm arms the DMS in the same step. The abstract form is P16.
law ip2_arms_on_demand:
  for +i: S.Inst
  for +f: S.Fin
  for +t: S.Trig
  for +h_ip: {S.ip_of(f) == True{} : Bool}
  for +h_idle: {S.is_idle(S.dms_of(f)) == True{} : Bool}
  for +h_ptn: {S.is_ptn(S.masked_table(i, S.prog_of(f), t)) == True{} : Bool}
  for +h_req: {S.dms_req(S.wave_of(f), t) == True{} : Bool}
  {S.is_armed(S.dms_of(S.fin_of(S.step_c(i, S.St{f, 0n, 0n}, S.XAlarm{t})))) == True{} : Bool}

# IP3: the current verdict is an input -- Ip{ok} writes ok ...
law ip3_ip_is_input:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_ip3(e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# IP4: ... and only that input, or an accepted end of pulse, moves it
law ip4_ip_frame:
  for +o: S.Ord
  for +f: S.Fin
  for +e: S.Ev
  for +bt: Bool
  for +bh: Bool
  {Spec.pr_ip4(f, e, S.step_fin(o, f, e, bt, bh)) == True{} : Bool}

# --- V1: the verdict domain of the certificate (audit #5, H13 as a theorem) ---
#
# enum_jetprot.bend enumerates the four (bt, bh) pairs for only 5 of its 28 event columns and
# certifies the other 23 at (True, True) alone. That is sound because nothing outside the Tick
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

# (blocker 4: "no full power" became "no power, full or partial")
law stop_no_full_power:
  for +f: S.Fin
  for +h: {S.inv_fin(f) == True{} : Bool}
  {S.implies(Bool.not(S.is_none(S.level_of(f))), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f))))) == True{} : Bool}

law termination_no_full_power:
  for +f: S.Fin
  for +h: {S.inv_fin(f) == True{} : Bool}
  {S.implies(S.is_term(S.wave_of(f)), Bool.and(Bool.not(S.is_hot(S.nb_of(f))), Bool.not(S.is_hot(S.rf_of(f))))) == True{} : Bool}
