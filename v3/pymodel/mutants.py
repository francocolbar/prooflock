"""mutants.py - the adversarial mutation suite: 76 defects a careless engineer could plausibly
write, each one a patch over the reference model in jetprot_ref.py (revised 2026-09-21 for the
eight-field state of blocker 4: prog, jtt, level, dms, plasma, ip, nb, rf; the three mutants that
spoke of `Inhibited` now speak of `Reduced`) (62 from two adversarial
reviews, plus 11 defects of the constants and of the oracle added on 2026-09-21, see the third
batch at the end; and 3 defects of the secondary stop response of revision 4, the fourth batch).

Provenance, stated because it matters for what the score means: M01-M37 and N01-N25 were written by
two separate automated adversarial reviews (README §7) whose brief was to break the law set, not to
match it. The 17 flags in `jetprot_ref.MUT` were written alongside the laws and are therefore a
weaker measure: a suite chosen to fit the laws will always score well. When the first bank was
written the law set killed 21 of 37; the demand laws (D1-D18) took it to 36/37 and 14/25; the
round-3 laws (E1-E11, C1, C3, V1) took the combined bank to 61/62. The single survivor, M06, is an
EQUIVALENT mutant: its abstract transition relation (step_fin, upd_hb, upd_tack) differs from the
model's on 0 of 924 672 cells (both orders x 10 752 states x 43 certificate columns), because `arm`
is only ever applied to an already-`to_ptn`'d state, so its added guard is a tautology at every
call site. The gate does not take this from the name: recheck.py C6 compares EVERY surviving mutant
with the model on those 924 672 cells, on 12 042 240 concrete cells for the counter layer
(verdicts, apply, step_st) and on 1 032 192 (instance, control state, plant event) cells for
concretize (C6.equivalence), and accepts a survivor only if it differs on none of them.

Each entry is (name, plausibility 1-5, description, patch) where patch() returns a dict of
jetprot_ref module-level names to override.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jetprot_ref as R

O_step = R.step_fin
O_hb = R.upd_hb
O_tack = R.upd_tack
O_conc = R.concretize
O_step_c = R.step_c
O_reset_ok = R.reset_ok
O_verdicts = R.verdicts
O_soft = R.soft
O_table = R.table
O_arm = R.arm
O_deenergize = R.deenergize
O_ramp = R.ramp
O_to_ptn = R.to_ptn


def _tick_ack_first(o, s, e, bt, bh):
    if e[0] == "Tick":
        p, j, l, d, pl, ip, nb, rf = s
        if d == "DmsArmed" and not bt:
            return (p, j, l, "DmsFired", pl, ip, nb, rf)
        if (not bh) and l != "LPtn":
            s2 = R.to_ptn(s)
            return R.arm(s2) if e[1] else s2
        return s
    return O_step(o, s, e, bt, bh)


def _tick_ack_first_tack(s, e, bt, bh):
    if e[0] == "Tick":
        if s[3] == "DmsArmed" and not bt:
            return "CKeep"
        if (not bh) and s[2] != "LPtn":
            return "CReset" if R.arms_now(e[1], s) else "CKeep"
        return "CInc" if (s[3] == "DmsArmed" and bt) else "CKeep"
    return O_tack(s, e, bt, bh)


def _adv_term_no_ramp(o, s, e, bt, bh):
    if e[0] == "Advance":
        p, j, l, d, pl, ip, nb, rf = s
        if l == "LPtn" or p == "Termination":
            return s
        nxt = R.PHASES[R.PHASES.index(p) + 1]
        if nxt == "Termination":
            return (nxt, j, l, d, pl, ip, nb, rf)                       # <-- ramp forgotten
        if not R.heat_win(nxt):
            return (nxt, j, l, d, pl, ip, R.deenergize(nb), R.deenergize(rf))
        return (nxt, j, l, d, pl, ip, nb, rf)
    return O_step(o, s, e, bt, bh)


def _adv_term_deenergize(o, s, e, bt, bh):
    if e[0] == "Advance":
        p, j, l, d, pl, ip, nb, rf = s
        if l == "LPtn" or p == "Termination":
            return s
        nxt = R.PHASES[R.PHASES.index(p) + 1]
        if nxt == "Termination":
            return (nxt, j, l, d, pl, ip, R.deenergize(nb), R.deenergize(rf))   # <-- off instead of ramp
        if not R.heat_win(nxt):
            return (nxt, j, l, d, pl, ip, R.deenergize(nb), R.deenergize(rf))
        return (nxt, j, l, d, pl, ip, nb, rf)
    return O_step(o, s, e, bt, bh)


def _soft_deenergize(s, req):
    p, j, l, d, pl, ip, nb, rf = s
    nb2, rf2 = R.deenergize(nb), R.deenergize(rf)                # <-- trip instead of ramp down
    return (p, j or req == "LJtt", req, d, pl, ip, nb2, rf2)


def _heatoff_clears_inhibit(o, s, e, bt, bh):
    if e[0] == "HeatOff":
        p, j, l, d, pl, ip, nb, rf = s
        f = lambda u: "Off" if u in ("On", "Ramping") else u          # <-- Reduced is not switched off
        return (p, j, l, d, pl, ip, f(nb), rf) if e[1] == "Nb" else (p, j, l, d, pl, ip, nb, f(rf))
    return O_step(o, s, e, bt, bh)


def _arm_second(s):
    p, j, l, d, pl, ip, nb, rf = s
    if d == "DmsIdle" and l == "LPtn" and ip:  # <-- only the SECOND demand (level already PTN) arms
        return (p, j, l, "DmsArmed", pl, ip, nb, rf)
    return s


def _plasma_true_clears_stop(o, s, e, bt, bh):
    if e[0] == "Plasma" and e[1]:
        p, j, l, d, pl, ip, nb, rf = s
        l2 = "LNone" if l in ("LJtt", "LRtps") else l
        return (p, j, l2, d, True, ip, nb, rf)
    return O_step(o, s, e, bt, bh)


def _plasma_true_rearms(o, s, e, bt, bh):
    if e[0] == "Plasma" and e[1]:
        p, j, l, d, pl, ip, nb, rf = s
        g = lambda u: "On" if u == "Ramping" else u
        return (p, j, l, d, True, ip, g(nb), g(rf))
    return O_step(o, s, e, bt, bh)


def _hb_reset_on(kinds):
    def f(s, e, bh):
        if e[0] in kinds:
            return "CReset"
        return O_hb(s, e, bh)
    return f


def _reset_ok_no_fired(s):
    p, j, l, d, pl, ip, nb, rf = s
    return (l == "LPtn" or R.wave(s) == "Termination") and d == "DmsIdle"


def _reset_ok_term_any(s):
    p, j, l, d, pl, ip, nb, rf = s
    return R.wave(s) == "Termination" or (l == "LPtn" and d != "DmsArmed")


def _hb_as_tack(s, e, bh):
    return O_tack(s, e, True, bh)


def _tack_as_hb(s, e, bt, bh):
    return O_hb(s, e, bh)


def _verdicts_ack_off1(hb, tack):
    return tack + 1 <= R.ACK_MAX, hb + 1 < R.HB_MAX


def _verdicts_hb_late(hb, tack):
    return tack + 1 < R.ACK_MAX, hb < R.HB_MAX


def _conc_col(swap):
    def f(inst, s, c):
        if c[0] == "XAlarm" and c[1] in swap:
            return ("Stop", R.table(inst, s[0], swap[c[1]]), R.dms_req(R.wave(s), c[1]))
        return O_conc(inst, s, c)
    return f


def _conc_heaton_off(inst, s, c):
    if c[0] == "XHeatOn":
        return ("HeatOff", c[1])
    return O_conc(inst, s, c)


def _conc_tick_arms(inst, s, c):
    if c[0] == "XTick":
        return ("Tick", True)
    return O_conc(inst, s, c)


def _heatoff_both(o, s, e, bt, bh):
    if e[0] == "HeatOff":
        p, j, l, d, pl, ip, nb, rf = s
        return (p, j, l, d, pl, ip, R.deenergize(nb), R.deenergize(rf))
    return O_step(o, s, e, bt, bh)


def _local_both(o, s, e, bt, bh):
    if e[0] == "Local":
        p, j, l, d, pl, ip, nb, rf = s
        return (p, j, l, d, pl, ip, R.reduce(nb), R.reduce(rf))
    return O_step(o, s, e, bt, bh)


def _adv_skips(o, s, e, bt, bh):
    if e[0] == "Advance":
        p, j, l, d, pl, ip, nb, rf = s
        if l == "LPtn" or p == "Termination":
            return s
        i = min(R.PHASES.index(p) + 2, 6)                          # <-- off-by-one: skips a phase
        nxt = R.PHASES[i]
        if nxt == "Termination":
            return (nxt, j, l, d, pl, ip, R.ramp(nb), R.ramp(rf))
        if not R.heat_win(nxt):
            return (nxt, j, l, d, pl, ip, R.deenergize(nb), R.deenergize(rf))
        return (nxt, j, l, d, pl, ip, nb, rf)
    return O_step(o, s, e, bt, bh)


def _soft_rtps_term(s, req):
    p, j, l, d, pl, ip, nb, rf = s
    j2 = j or req in ("LJtt", "LRtps")                                # <-- RTPS also switches to the termination waveform
    return (p, j2, req, d, pl, ip, R.ramp(nb), R.ramp(rf))


def _heatack_noop(o, s, e, bt, bh):
    if e[0] == "HeatAck":
        return s
    return O_step(o, s, e, bt, bh)


def _stop_ptn_nodms_noop(o, s, e, bt, bh):
    if e[0] == "Stop" and e[1] == "LPtn" and not e[2]:
        return s                                                   # <-- PTN only latches when wired to the DMS
    return O_step(o, s, e, bt, bh)


def _watchdog_noop_step(o, s, e, bt, bh):
    if e[0] == "Tick":
        p, j, l, d, pl, ip, nb, rf = s
        if d == "DmsArmed" and not bt:
            return (p, j, l, "DmsFired", pl, ip, nb, rf)
        return s                                                   # <-- the watchdog never latches PTN
    return O_step(o, s, e, bt, bh)


def _watchdog_noop_hb(s, e, bh):
    if e[0] == "Tick":
        return "CKeep"
    return O_hb(s, e, bh)


def _watchdog_noop_tack(s, e, bt, bh):
    if e[0] == "Tick":
        return "CInc" if (s[3] == "DmsArmed" and bt) else "CKeep"
    return O_tack(s, e, bt, bh)


def _plasma_false_keeps_flag(o, s, e, bt, bh):
    if e[0] == "Plasma" and not e[1]:
        p, j, l, d, pl, ip, nb, rf = s
        return (p, j, l, d, pl, ip, R.deenergize(nb), R.deenergize(rf))   # <-- flag not cleared
    return O_step(o, s, e, bt, bh)


def _heaton_no_plasma(o, s, e, bt, bh):
    if e[0] == "HeatOn":
        p, j, l, d, pl, ip, nb, rf = s
        ok = R.heat_win(R.wave(s)) and l == "LNone"                # <-- plasma_ok forgotten
        u = nb if e[1] == "Nb" else rf
        if ok and u == "Off":
            return (p, j, l, d, pl, ip, "On", rf) if e[1] == "Nb" else (p, j, l, d, pl, ip, nb, "On")
        return s
    return O_step(o, s, e, bt, bh)


def _commfault_no_arm(o, s, e, bt, bh):
    if e[0] == "CommFault" and e[2]:
        return R.to_ptn(s)                                         # <-- the dms flag ignored
    return O_step(o, s, e, bt, bh)


def _commfault_no_arm_tack(s, e, bt, bh):
    if e[0] == "CommFault":
        return "CKeep"
    return O_tack(s, e, bt, bh)


def _stop_ptn_keeps_inhibit_off(o, s, e, bt, bh):
    """to_ptn on a PTN stop switches off full power and ramp-down only: a Reduced unit stays powered."""
    if e[0] == "Stop" and e[1] == "LPtn":
        p, j, l, d, pl, ip, nb, rf = s
        f = lambda u: "Off" if u in ("On", "Ramping") else u
        s2 = (p, j, "LPtn", d, pl, ip, f(nb), f(rf))
        return R.arm(s2) if e[2] else s2
    return O_step(o, s, e, bt, bh)


def _tack_inc_when_idle(s, e, bt, bh):
    if e[0] == "Tick" and s[3] == "DmsIdle":
        return "CInc"
    return O_tack(s, e, bt, bh)


MUTANTS_M = [
 ("M01_tick_ack_before_watchdog", 5, "Tick: the ack timeout is evaluated BEFORE the watchdog (order of the two if-arms swapped)",
  lambda: {"step_fin": _tick_ack_first, "upd_tack": _tick_ack_first_tack}),
 ("M02_advance_term_no_ramp", 4, "Advance into Termination forgets to ramp the units down",
  lambda: {"step_fin": _adv_term_no_ramp}),
 ("M03_advance_term_deenergize", 4, "Advance into Termination de-energizes (Off) instead of ramping",
  lambda: {"step_fin": _adv_term_deenergize}),
 ("M04_soft_stop_deenergize", 5, "a soft stop (JTT/RTPS) trips the units to Off instead of ramping them down",
  lambda: {"soft": _soft_deenergize}),
 ("M05_heatoff_keeps_reduced", 4, "HeatOff switches off full power only: a unit at partial power stays Reduced",
  lambda: {"step_fin": _heatoff_clears_inhibit}),
 ("M06_dms_arms_on_second_demand", 4, "the DMS arms on the SECOND PTN demand (guard 'level already LPtn')",
  lambda: {"arm": _arm_second}),
 ("M07_plasma_true_clears_stop", 3, "Plasma{True} clears a soft stop (level back to LNone)",
  lambda: {"step_fin": _plasma_true_clears_stop}),
 ("M08_plasma_true_rearms_heat", 3, "Plasma{True} puts a Ramping unit back to On",
  lambda: {"step_fin": _plasma_true_rearms}),
 ("M09_stop_lnone_resets_hb", 3, "a Stop{LNone} (no-response alarm) is treated as proof of life: resets hb",
  lambda: {"upd_hb": _hb_reset_on(("Stop",))}),
 ("M10_advance_resets_hb", 4, "Advance resets the heartbeat counter ('the sequencer is alive')",
  lambda: {"upd_hb": _hb_reset_on(("Advance",))}),
 ("M11_heaton_resets_hb", 3, "HeatOn resets the heartbeat counter",
  lambda: {"upd_hb": _hb_reset_on(("HeatOn",))}),
 ("M12_reset_rejects_fired", 4, "the reset guard also refuses when the DMS has Fired (stricter)",
  lambda: {"reset_ok": _reset_ok_no_fired}),
 ("M13_reset_accepts_term_armed", 5, "the reset guard accepts Termination even with the DMS Armed",
  lambda: {"reset_ok": _reset_ok_term_any}),
 ("M14_counters_swapped", 4, "the hb and t_ack command functions are wired to the wrong counters",
  lambda: {"upd_hb": _hb_as_tack, "upd_tack": _tack_as_hb}),
 ("M15_ack_max_off_by_one", 5, "bt = t_ack+1 <= ack_max (off-by-one in the ack timeout)",
  lambda: {"verdicts": _verdicts_ack_off1}),
 ("M16_hb_verdict_off_by_one_other_way", 4, "bh = hb < hb_max (watchdog verdict reads the old count)",
  lambda: {"verdicts": _verdicts_hb_late}),
 ("M17_concretize_mchs_as_slow", 5, "concretize: the MCHS trigger reads the SLOW column",
  lambda: {"concretize": _conc_col({"Mchs": "Slow"})}),
 ("M18_concretize_dhs_as_mchs", 5, "concretize: the DHS trigger reads the MCHS column",
  lambda: {"concretize": _conc_col({"Dhs": "Mchs"})}),
 ("M19_concretize_heaton_to_heatoff", 3, "concretize: XHeatOn is wired to the abstract HeatOff",
  lambda: {"concretize": _conc_heaton_off}),
 ("M20_concretize_tick_arms_dms", 4, "concretize: XTick carries dms=True (dms_on_watchdog silently on)",
  lambda: {"concretize": _conc_tick_arms}),
 ("M21_heatoff_hits_both_units", 4, "HeatOff{u} de-energizes BOTH units (copy-paste)",
  lambda: {"step_fin": _heatoff_both}),
 ("M22_local_reduces_both_units", 4, "Local{u} reduces BOTH units (copy-paste)",
  lambda: {"step_fin": _local_both}),
 ("M23_advance_skips_a_phase", 4, "Advance jumps two phases (index+2)",
  lambda: {"step_fin": _adv_skips}),
 ("M24_rtps_jumps_to_termination", 4, "an RTPS stop also forces phase := Termination (the JTT rule applied too widely)",
  lambda: {"soft": _soft_rtps_term}),
 ("M25_heatack_never_fires", 4, "HeatAck does not fire the DMS (only the timeout does)",
  lambda: {"step_fin": _heatack_noop}),
 ("M26_stop_ptn_without_dms_is_noop", 5, "Stop{LPtn, False} is the identity: PTN latches only when the stop is wired to the DMS",
  lambda: {"step_fin": _stop_ptn_nodms_noop}),
 ("M27_watchdog_never_latches_ptn", 5, "the heartbeat watchdog never latches PTN; hb simply stops counting",
  lambda: {"step_fin": _watchdog_noop_step, "upd_hb": _watchdog_noop_hb, "upd_tack": _watchdog_noop_tack}),
 ("M28_plasma_false_keeps_flag", 3, "Plasma{False} de-energizes but leaves plasma_ok True",
  lambda: {"step_fin": _plasma_false_keeps_flag}),
 ("M29_heaton_ignores_plasma", 4, "HeatOn does not check plasma_ok",
  lambda: {"step_fin": _heaton_no_plasma}),
 ("M30_commfault_ignores_dms_flag", 4, "CommFault never arms the DMS (the dms payload is dropped)",
  lambda: {"step_fin": _commfault_no_arm, "upd_tack": _commfault_no_arm_tack}),
 ("M31_ptn_keeps_reduced", 4, "to_ptn on a PTN stop switches off full power and ramp-down only; a Reduced unit stays powered",
  lambda: {"step_fin": _stop_ptn_keeps_inhibit_off}),
 ("M32_tack_counts_while_idle", 3, "t_ack increments on every Tick even with the DMS Idle",
  lambda: {"upd_tack": _tack_inc_when_idle}),
]


# --- second batch: corrected M06 and instance-relevant variants ---
def _arm_second_real(o, s, e, bt, bh):
    """The DMS arms only if the PTN was ALREADY latched before this stop (the 'second demand')."""
    if e[0] == "Stop" and e[1] == "LPtn":
        s2 = R.to_ptn(s)
        return R.arm(s2) if (e[2] and s[2] == "LPtn") else s2
    if e[0] == "CommFault" and e[2]:
        s2 = R.to_ptn(s)
        return R.arm(s2) if (e[1] and s[2] == "LPtn") else s2
    return O_step(o, s, e, bt, bh)


def _arm_second_tack(s, e, bt, bh):
    if e[0] == "Stop":
        return "CReset" if (e[1] == "LPtn" and e[2] and s[2] == "LPtn" and R.arms_now(True, s)) else "CKeep"
    if e[0] == "CommFault":
        return "CReset" if (e[2] and e[1] and s[2] == "LPtn" and R.arms_now(True, s)) else "CKeep"
    return O_tack(s, e, bt, bh)


def _watchdog_only_when_dms_step(o, s, e, bt, bh):
    """The watchdog latches PTN only when the tick is wired to the DMS; with dms_on_watchdog=False
    (BOTH certified instances) the heartbeat watchdog does nothing at all."""
    if e[0] == "Tick":
        p, j, l, d, pl, ip, nb, rf = s
        if (not bh) and l != "LPtn":
            if e[1]:
                s2 = R.to_ptn(s)
                return R.arm(s2)
            return s
        if d == "DmsArmed" and not bt:
            return (p, j, l, "DmsFired", pl, ip, nb, rf)
        return s
    return O_step(o, s, e, bt, bh)


def _watchdog_only_when_dms_hb(s, e, bh):
    if e[0] == "Tick":
        return "CInc" if (bh and s[2] != "LPtn") else "CKeep"
    return O_hb(s, e, bh)


def _soft_stop_noop(o, s, e, bt, bh):
    """A soft stop request is recorded nowhere: JTT/RTPS are the identity."""
    if e[0] == "Stop" and e[1] in ("LJtt", "LRtps"):
        return s
    return O_step(o, s, e, bt, bh)


def _heatack_fires_idle(o, s, e, bt, bh):
    if e[0] == "HeatAck":
        p, j, l, d, pl, ip, nb, rf = s
        return (p, j, l, "DmsFired", pl, ip, nb, rf)
    return O_step(o, s, e, bt, bh)


def _stop_ptn_no_arm_when_already_ptn(o, s, e, bt, bh):
    """rule 1's parenthetical dropped: a DMS stop after a comms-fault PTN does not arm."""
    if e[0] == "Stop" and e[1] == "LPtn":
        if s[2] == "LPtn":
            return s
        s2 = R.to_ptn(s)
        return R.arm(s2) if e[2] else s2
    return O_step(o, s, e, bt, bh)


MUTANTS_M += [
 ("M33_dms_arms_on_second_demand_v2", 4, "the DMS arms only if the PTN was already latched before the stop (second demand)",
  lambda: {"step_fin": _arm_second_real, "upd_tack": _arm_second_tack}),
 ("M34_watchdog_acts_only_if_wired_to_dms", 5, "the watchdog latches PTN only when dms_on_watchdog is set; in BOTH certified instances it does nothing",
  lambda: {"step_fin": _watchdog_only_when_dms_step, "upd_hb": _watchdog_only_when_dms_hb}),
 ("M35_soft_stop_is_noop", 5, "a JTT/RTPS stop request is the identity (only PTN is implemented)",
  lambda: {"step_fin": _soft_stop_noop}),
 ("M36_heatack_fires_from_idle", 3, "HeatAck fires the DMS even when it was never armed",
  lambda: {"step_fin": _heatack_fires_idle}),
 ("M37_no_rearm_after_commfault_ptn", 4, "a DMS-wired PTN stop arriving when PTN is already latched does nothing (rule 1 parenthetical dropped)",
  lambda: {"step_fin": _stop_ptn_no_arm_when_already_ptn, "upd_tack": lambda s, e, bt, bh: "CKeep" if (e[0] == "Stop" and e[1] == "LPtn" and s[2] == "LPtn") else O_tack(s, e, bt, bh)}),
]

# ---- N01 Advance into a non-heat-window phase forgets to de-energize
def _n01(o, s, e, bt, bh):
    if e[0] == "Advance":
        p, j, l, d, pl, ip, nb, rf = s
        if l == "LPtn" or p == "Termination":
            return s
        nxt = R.PHASES[R.PHASES.index(p) + 1]
        if nxt == "Termination":
            return (nxt, j, l, d, pl, ip, R.ramp(nb), R.ramp(rf))
        return (nxt, j, l, d, pl, ip, nb, rf)              # <-- deenergize dropped for the non-heat case
    return O_step(o, s, e, bt, bh)


# ---- N02 the heartbeat counter increments on every Tick outside PTN, ignoring the verdict
def _n02(s, e, bh):
    if e[0] == "Tick":
        return "CInc" if s[2] != "LPtn" else "CKeep"     # <-- `bh and` dropped
    return O_hb(s, e, bh)


# ---- N03 t_ack counts while the DMS is Fired as well as Armed
def _n03(s, e, bt, bh):
    if e[0] == "Tick":
        if (not bh) and s[2] != "LPtn":
            return "CReset" if R.arms_now(e[1], s) else "CKeep"
        return "CInc" if (s[3] != "DmsIdle" and bt) else "CKeep"   # <-- != DmsIdle, not == DmsArmed
    return O_tack(s, e, bt, bh)


# ---- N04 a heartbeat is ignored once the PTN is latched
def _n04(s, e, bh):
    if e[0] == "Heartbeat":
        return "CReset" if s[2] != "LPtn" else "CKeep"   # <-- "in PTN the watchdog no longer matters"
    return O_hb(s, e, bh)


# ---- N05 the alarm matrix is read against the phase the sequencer is about to enter
def _n05(inst, st, c):
    s = st[0]
    return R.step_st(1, st, R.concretize(inst, (R.succ_phase(s[0]),) + s[1:], c))


# ---- N06 the concrete layer of both instances runs on urgency order 2
def _n06(inst, st, c):
    return R.step_st(2, st, R.concretize(inst, st[0], c))


# ---- N07 the concrete layer always looks the alarm up in instance 1's matrix
def _n07(inst, st, c):
    return R.step_st(1, st, R.concretize(1, st[0], c))


# ---- N08 loss of plasma inhibits the units instead of de-energizing them
def _n08(o, s, e, bt, bh):
    if e[0] == "Plasma" and not e[1]:
        p, j, l, d, pl, ip, nb, rf = s
        f = lambda u: "Reduced" if u in ("On", "Ramping") else u
        return (p, j, l, d, False, ip, f(nb), f(rf))
    return O_step(o, s, e, bt, bh)


# ---- N09 the heating permissive also requires a healthy watchdog
def _n09(o, s, e, bt, bh):
    if e[0] == "HeatOn" and not bh:
        return s                                    # <-- refused while the watchdog is about to expire
    return O_step(o, s, e, bt, bh)


# ---- N10 a comms fault without a DMS demand is dropped while the watchdog is late
def _n10(o, s, e, bt, bh):
    if e[0] == "CommFault" and not e[1] and not bh:
        return s
    return O_step(o, s, e, bt, bh)


# ---- N11 Advance restarts the acknowledgement timer while the DMS is idle
def _n11(s, e, bt, bh):
    if e[0] == "Advance" and s[3] == "DmsIdle":
        return "CReset"
    return O_tack(s, e, bt, bh)


# ---- N12 a no-response alarm restarts the acknowledgement timer while the DMS is idle
def _n12(s, e, bt, bh):
    if e[0] == "Stop" and e[1] == "LNone" and s[3] == "DmsIdle":
        return "CReset"
    return O_tack(s, e, bt, bh)


# ---- N13 instance 2's MHD override window starts one phase late
def _n13(inst, p, t):
    if inst == 2 and t in ("Mhd", "MhdB") and R.PHASES.index(p) >= 4:
        return "LPtn"
    return R.table1(p, t)


# ---- N14 the DMS trigger set ignores the phase window
def _n14(p, t):
    return t in ("Fast", "Mhd", "MhdB")


# ---- N15 arming goes straight to Fired
def _n15(s):
    p, j, l, d, pl, ip, nb, rf = s
    if d == "DmsIdle" and ip:
        return (p, j, l, "DmsFired", pl, ip, nb, rf)
    return s


# ---- N16 the PTN de-energizes only the neutral beam
def _n16(s):
    p, j, l, d, pl, ip, nb, rf = s
    return (p, j, "LPtn", d, pl, ip, R.deenergize(nb), rf)


# ---- N17 the heating acknowledgement also latches the PTN
def _n17(o, s, e, bt, bh):
    if e[0] == "HeatAck" and s[3] == "DmsArmed":
        p, j, l, d, pl, ip, nb, rf = s
        return (p, j, "LPtn", "DmsFired", pl, ip, R.deenergize(nb), R.deenergize(rf))
    return O_step(o, s, e, bt, bh)


# ---- N18 a heartbeat also restarts the acknowledgement timer
def _n18(s, e, bt, bh):
    if e[0] == "Heartbeat":
        return "CReset"
    return O_tack(s, e, bt, bh)


# ---- N19 plasma present is treated as proof of life
def _n19(s, e, bh):
    if e[0] == "Plasma" and e[1]:
        return "CReset"
    return O_hb(s, e, bh)


# ---- N20 arms_now drops the idle test (a repeat demand restarts the ack timer)
def _n20(dm, s):
    return dm and s[5]


# ---- N21 the two counter limits are swapped in the verdicts
def _n21(hb, tack):
    return tack + 1 < R.HB_MAX, hb + 1 < R.ACK_MAX


# ---- N22 the stop acceptance test is >= instead of >
def _n22(o, s, e, bt, bh):
    if e[0] == "Stop":
        req, dm = e[1], e[2]
        if req == "LPtn":
            s2 = R.to_ptn(s)
            return R.arm(s2) if dm else s2
        if R.RANK[o][req] < R.RANK[o][s[2]]:          # <-- >= accepted, not >
            return s
        s2 = R.soft(s, req)
        return s2
    return O_step(o, s, e, bt, bh)


# ---- N23 the acceptance comparison is hard-wired to urgency order 1
def _n23(o, s, e, bt, bh):
    if e[0] == "Stop":
        req, dm = e[1], e[2]
        if req == "LPtn":
            s2 = R.to_ptn(s)
            return R.arm(s2) if dm else s2
        if not (R.RANK[1][req] > R.RANK[1][s[2]]):     # <-- RANK[1], not RANK[o]
            return s
        return R.soft(s, req)
    return O_step(o, s, e, bt, bh)


# ---- N24 the watchdog branch drops the "PTN not already latched" test
def _n24(o, s, e, bt, bh):
    if e[0] == "Tick":
        p, j, l, d, pl, ip, nb, rf = s
        if not bh:
            s2 = R.to_ptn(s)
            return R.arm(s2) if e[1] else s2           # <-- runs even when l is already LPtn
        if d == "DmsArmed" and not bt:
            return (p, j, l, "DmsFired", pl, ip, nb, rf)
        return s
    return O_step(o, s, e, bt, bh)


def _n24_tack(s, e, bt, bh):
    if e[0] == "Tick":
        if not bh:
            return "CReset" if R.arms_now(e[1], s) else "CKeep"
        return "CInc" if (s[3] == "DmsArmed" and bt) else "CKeep"
    return O_tack(s, e, bt, bh)


# ---- N25 an accepted end of pulse clears the responses but keeps the phase
def _n25(o, s, e, bt, bh):
    if e[0] == "Reset":
        if R.reset_ok(s):
            return (s[0], False, "LNone", "DmsIdle", False, False, "Off", "Off")
        return s
    return O_step(o, s, e, bt, bh)


MUTANTS_N = [
 ("N01_advance_nonheat_keeps_power", 4, "Advance into a non-heating phase no longer de-energizes the units",
  lambda: {"step_fin": _n01}),
 ("N02_hb_counts_ignoring_verdict", 4, "upd_hb increments on every Tick outside PTN, the bh verdict is not read",
  lambda: {"upd_hb": _n02}),
 ("N03_tack_counts_while_fired", 3, "t_ack keeps counting once the DMS has Fired (dms != Idle instead of == Armed)",
  lambda: {"upd_tack": _n03}),
 ("N04_heartbeat_ignored_under_ptn", 4, "a heartbeat does not reset the watchdog counter once the PTN is latched",
  lambda: {"upd_hb": _n04}),
 ("N05_concretize_against_next_phase", 5, "step_c reads the alarm matrix at the phase the sequencer is entering",
  lambda: {"step_c": _n05}),
 ("N06_concrete_layer_order2", 5, "both instances run the abstract step with urgency order 2",
  lambda: {"step_c": _n06}),
 ("N07_concrete_layer_ignores_instance", 5, "step_c always uses instance 1's alarm matrix",
  lambda: {"step_c": _n07}),
 ("N08_plasma_loss_reduces", 3, "loss of plasma leaves the units at partial power instead of de-energizing them",
  lambda: {"step_fin": _n08}),
 ("N09_heaton_needs_healthy_watchdog", 3, "HeatOn is refused whenever the watchdog verdict bh is false",
  lambda: {"step_fin": _n09}),
 ("N10_commfault_dropped_when_hb_late", 4, "CommFault{False} is ignored while the watchdog verdict bh is false",
  lambda: {"step_fin": _n10}),
 ("N11_advance_restarts_ack_timer", 3, "Advance restarts t_ack while the DMS is Idle",
  lambda: {"upd_tack": _n11}),
 ("N12_stop_lnone_restarts_ack_timer", 3, "a Stop{LNone} restarts t_ack while the DMS is Idle",
  lambda: {"upd_tack": _n12}),
 ("N13_instance2_window_off_by_one", 5, "instance 2's MHD override starts at Heating1 instead of Xpoint",
  lambda: {"table": _n13}),
 ("N14_dms_req_ignores_phase_window", 5, "dms_req drops the phase window: FAST/MHD arm the DMS in every phase",
  lambda: {"dms_req": _n14}),
 ("N15_arm_goes_straight_to_fired", 4, "arming the DMS sets DmsFired directly",
  lambda: {"arm": _n15}),
 ("N16_ptn_deenergizes_nb_only", 5, "to_ptn de-energizes the neutral beam and forgets the RF",
  lambda: {"to_ptn": _n16}),
 ("N17_heatack_also_latches_ptn", 3, "the heating acknowledgement also latches the PTN and trips the units",
  lambda: {"step_fin": _n17}),
 ("N18_heartbeat_restarts_ack_timer", 4, "a heartbeat also restarts the DMS acknowledgement timer",
  lambda: {"upd_tack": _n18}),
 ("N19_plasma_true_resets_hb", 3, "Plasma{True} is treated as proof of life and resets the watchdog",
  lambda: {"upd_hb": _n19}),
 ("N20_arms_now_drops_idle_test", 4, "arms_now returns the payload alone, so a repeat demand restarts t_ack",
  lambda: {"arms_now": _n20}),
 ("N21_counter_limits_swapped", 4, "the verdicts read hb against ack_max and t_ack against hb_max",
  lambda: {"verdicts": _n21}),
 ("N22_stop_accept_ge", 3, "the stop acceptance test is >= instead of > (a repeat request re-runs the ramp)",
  lambda: {"step_fin": _n22}),
 ("N23_accept_hardwired_order1", 5, "the acceptance comparison is hard-wired to urgency order 1",
  lambda: {"step_fin": _n23}),
 ("N24_watchdog_ignores_latched_ptn", 4, "the watchdog branch runs even when the PTN is already latched, pre-empting the ack timeout",
  lambda: {"step_fin": _n24, "upd_tack": _n24_tack}),
 ("N25_reset_keeps_phase", 4, "an accepted end of pulse clears the responses but leaves the phase where it was",
  lambda: {"step_fin": _n25}),
]

MUTANTS = MUTANTS_M + MUTANTS_N


# ---------------------------------------------------------------------------
# Third batch (2026-09-21, blocker 2 of docs/STATUS_2026-09-21.md): the CONSTANTS and the oracle
# itself. The first two batches only ever patched functions; the laws read the model constants,
# so a wrong constant dragged the oracle along with it and survived (HB_MAX = 4, ACK_MAX = 3, a
# wrong initial state, a wider heating window: reproduced 2026-09-21 before spec_consts.py).
# Same convention: (name, plausibility 1-5, description, patch) with patch() a dict of
# jetprot_ref names, now constants as well as functions (recheck.c6 restores every public name).
# ---------------------------------------------------------------------------
O_RANK = R.RANK


def _s67_heat_win(p):
    return p in ("Xpoint", "Heating1", "Heating2")                  # <-- window one phase too wide


def _s68_dms_req(p, t):
    return t in ("Fast", "Mhd", "MhdB") and R.PHASES.index(p) in (3, 4, 5)   # <-- Termination dropped


def _s70_step_c(inst, st, c):
    if c[0] == "XHeatAck" and st[0][0] == "Termination":
        return st                                                    # <-- the acknowledgement is ignored in Termination
    return O_step_c(inst, st, c)


def _s71_reset_ok(s):
    p, j, l, d, pl, ip, nb, rf = s
    return (l == "LPtn" or R.wave(s) == "Termination") and d != "DmsArmed" and (d != "DmsFired" or not pl)   # <-- an extra guard


def _s72_inv_all(st):
    s, hb, tack = st
    return R.inv_fin(s) and (s[3] != "DmsArmed" or tack < R.ACK_MAX) and (s[2] == "LPtn" or hb <= R.HB_MAX)   # <-- <= instead of <


def _s73_table(inst, p, t):
    if inst == 1 and p == "Xpoint" and t == "Slow":
        return "LRtps"                                               # <-- one cell of the matrix wrong
    return O_table(inst, p, t)


MUTANTS_S = [
 ("M63_hb_max_4", 5, "HB_MAX = 4: the watchdog tolerates one missed heartbeat more than A-12 allows",
  lambda: {"HB_MAX": 4}),
 ("M64_ack_max_3", 5, "ACK_MAX = 3: the acknowledgement timeout is one tick later than A-11 allows",
  lambda: {"ACK_MAX": 3}),
 ("M65_init_plasma_true", 4,
  "the initial state has plasma_ok = True (the model starts at Breakdown, A-5, A-12, before any Plasma event: no plasma yet)",
  lambda: {"INIT": ("Breakdown", False, "LNone", "DmsIdle", True, False, "Off", "Off")}),
 ("M66_init_iprise", 3, "the initial phase is IpRise instead of Breakdown",
  lambda: {"INIT": ("IpRise", False, "LNone", "DmsIdle", False, False, "Off", "Off")}),
 ("M67_heat_win_xpoint", 4, "the heating window also admits Xpoint (A-5, A-27: Heating1 and Heating2 only)",
  lambda: {"heat_win": _s67_heat_win}),
 ("M68_dms_window_no_term", 4,
  "the DMS arming window drops Termination (the model's window includes it, A-10 / R-14; "
  "[S6] closes it \"generally\" at the end of the post-heating phase)",
  lambda: {"dms_req": _s68_dms_req}),
 ("M69_rank2_jtt_ge_rtps", 4, "urgency order 2 ranks JTT and RTPS equal (a tie: neither pre-empts the other)",
  lambda: {"RANK": {1: dict(O_RANK[1]), 2: {"LNone": 0, "LJtt": 1, "LRtps": 1, "LPtn": 3}}}),
 ("M70_heatack_ignored_in_term", 3, "the concrete layer drops XHeatAck while the phase is Termination",
  lambda: {"step_c": _s70_step_c}),
 ("M71_reset_fired_needs_plasma_false", 3, "the end of pulse with the DMS Fired is accepted only once the plasma is gone",
  lambda: {"reset_ok": _s71_reset_ok}),
 ("M72_inv_all_hb_le", 4, "the MODEL invariant reads hb <= HB_MAX instead of hb < HB_MAX (the oracle side is what is mutated)",
  lambda: {"inv_all": _s72_inv_all}),
 ("M73_table_one_cell", 5, "one wrong cell in the alarm matrix (instance 1, Xpoint, Slow: RTPS for PTN), concretize wired correctly",
  lambda: {"table": _s73_table}),
]

MUTANTS = MUTANTS_M + MUTANTS_N + MUTANTS_S


# ---------------------------------------------------------------------------
# Fourth batch (revision 4, 2026-09-22): the secondary stop response of the concrete layer
# (sec_table; instance 4 is the illustrative PTN-preferred one, A-35). Same convention.
# ---------------------------------------------------------------------------
def _w01_concretize(inst, s, c):
    if c[0] == "XAlarm":
        return ("Stop", R.masked_table(inst, s[R.P], c[1]), R.dms_req(R.wave(s), c[1]))   # <-- secondary never read
    return O_conc(inst, s, c)


def _w02_concretize(inst, s, c):
    if c[0] == "XAlarm":
        return ("Stop", R.sec_table(inst, s[R.P], c[1]), R.dms_req(R.wave(s), c[1]))      # <-- secondary read with no stop in force
    return O_conc(inst, s, c)


def _w03_concretize(inst, s, c):
    if c[0] == "XAlarm" and s[R.L] != "LNone":
        return ("Stop", R.sec_table(inst, R.wave(s), c[1]), R.dms_req(R.wave(s), c[1]))   # <-- secondary read at the waveform phase
    return O_conc(inst, s, c)


MUTANTS_W = [
 ("W01_inst4_secondary_ignored", 5, "concretize reads the primary table also under a stop: instance 4's secondary table is never read",
  lambda: {"concretize": _w01_concretize}),
 ("W02_secondary_read_without_stop", 4, "concretize reads the secondary table also when no stop is in force",
  lambda: {"concretize": _w02_concretize}),
 ("W03_secondary_read_at_wave_phase", 4, "under a stop, the secondary table is read at the waveform phase instead of the programme phase",
  lambda: {"concretize": _w03_concretize}),
]

MUTANTS = MUTANTS_M + MUTANTS_N + MUTANTS_S + MUTANTS_W
