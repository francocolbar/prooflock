"""jetprot_laws.py - the ORACLE side of the Python re-check: the invariants, the cell laws
P1..P21 / D1..D18 / E1..E11 / F1..F3 / IP1..IP4 and the state corollaries as (hypothesis,
conclusion) pairs, the C1 / C3 / V1 conformance checks and `check_cell`. Separate from
jetprot_ref.py (blocker 2 of docs/STATUS_2026-09-21.md) so that the laws read the specification
constants (spec_consts.py) and never the model ones.

What still refers to the model on purpose, because the Bend law does too: `R.upd_hb` /
`R.upd_tack` (the commands under test), `R.step_fin` / `R.concretize` / `R.step_c` (the
functions the laws constrain) and `R.reset_ok` in P20, D6 and D14 (the self-reference of P20
is documented; D10 and E8 spell the guard out). `ramp`, `reduce` and `deenergize` are the spec's.

Revision for blocker 4 (2026-09-21): the state is (prog, jtt, level, dms, plasma, ip, nb, rf);
`wave(s)` is the waveform phase (Termination once an accepted JTT switched to it). Table 1 is
indexed by `prog` (F1); a local alarm REDUCES a unit at full power instead of inhibiting it (F2; `Inhibited`, P8 and E1
are gone: no pulse event produced it any more, A-26);
a masked communication check is the identity (F3); the DMS arms only above the DMV current
threshold `ip` (R-14). Laws whose statement changed are marked "(b4)".

Everything in this module is evaluated by recheck.py (C2, C5, C6) and by the mutation
oracle `recheck.catching_laws`; it is what a mutant has to fool.
"""
import spec_consts as C
import jetprot_ref as R

P, J, L, D, PL, IP, NB, RF = C.P, C.J, C.L, C.D, C.PL, C.IP, C.NB, C.RF


def wave(s):
    return "Termination" if s[J] else s[P]


def heat_win(p):
    return p in C.HEAT_WIN


def deenergize(u):
    """what the spec expects a de-energize to do: any power goes to Off"""
    return "Off" if u in ("On", "Ramping", "Reduced") else u


def ramp(u):
    """what the spec expects a ramp-down to do: full or partial power goes to Ramping, nothing else moves"""
    return "Ramping" if u in ("On", "Reduced") else u


def reduce(u):
    """what the spec expects a local alarm to do to its unit: full power becomes partial (R-9), nothing else moves"""
    return "Reduced" if u == "On" else u


def hot(u):
    """delivering power, full or partial"""
    return u in ("On", "Reduced")


def unpowered(u):
    return u == "Off"


# --- the invariants (the spec's copy) ---
def inv_fin(s):
    w = wave(s)
    for u in (s[NB], s[RF]):
        if hot(u) and not (heat_win(w) and s[PL] and s[L] == "LNone"):
            return False
        if u == "Ramping" and not (s[PL] and s[L] != "LPtn" and (s[L] != "LNone" or w == "Termination")):
            return False
    if s[L] == "LJtt" and w != "Termination":
        return False
    if s[D] != "DmsIdle" and s[L] != "LPtn":
        return False
    return True


def inv_all(st):
    s, hb, tack = st
    return inv_fin(s) and (s[D] != "DmsArmed" or tack < C.ACK_MAX) and (s[L] == "LPtn" or hb < C.HB_MAX)


# --- the cell laws as (hypothesis, conclusion) pairs over (o, s, e, bt, bh, s2) ---
def _u(s, w):
    return s[NB] if w == "Nb" else s[RF]


def _other(w):
    return "Rf" if w == "Nb" else "Nb"


def demands(e, bh, l):
    """does this event demand the DMS: a PTN stop wired to it, an enabled comm fault wired to it, or
    a watchdog expiry wired to it (the current threshold is a separate hypothesis, IP1/P16)"""
    k = e[0]
    if k == "Stop":
        return e[1] == "LPtn" and e[2]
    if k == "CommFault":
        return e[1] and e[2]
    if k == "Tick":
        return e[1] and (not bh) and l != "LPtn"
    return False


def _frame_but_units(s, s2):
    return s2[P] == s[P] and s2[J] == s[J] and s2[L] == s[L] and s2[D] == s[D] and s2[PL] == s[PL] and s2[IP] == s[IP]


def _fin_frame(s, s2, w):
    """P9 (b4): unit w is reduced (full power -> partial, anything else unchanged), everything else equal"""
    return _u(s2, w) == reduce(_u(s, w)) and _frame_but_units(s, s2) and _u(s2, _other(w)) == _u(s, _other(w))


def _p5_unit(ok, u, u2):
    acc = ok and u == "Off"
    return ((u2 == "On") == (acc or (u == "On" and not acc))) and (acc or u2 == u)


def _one_unit(s, s2, w, expected, bt, bh, e):
    """unit w becomes `expected`, everything else (including the counters) is unchanged"""
    return (_u(s2, w) == expected and _u(s2, _other(w)) == _u(s, _other(w)) and _frame_but_units(s, s2)
            and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep")


def lub(o, a, b):
    return a if C.RANK[o][a] >= C.RANK[o][b] else b


def succ_phase(p):
    i = C.PHASES.index(p)
    return C.PHASES[i + 1] if i + 1 < len(C.PHASES) else p


def adv_unit(s, u):
    """what an Advance does to one unit (E4): ramp into Termination, close a shut window."""
    nxt = succ_phase(s[P])
    if nxt == "Termination":
        return ramp(u)
    return u if heat_win(nxt) else deenergize(u)


def reset_accepted_by_spec(s):
    """the end-of-pulse guard, spelled out (D10, E8, IP4): pulse ended and no mitigation armed"""
    return (s[L] == "LPtn" or wave(s) == "Termination") and s[D] != "DmsArmed"


LAWS = {
    # name: (hypothesis, conclusion); each takes (o, s, e, bt, bh, s2) with s2 = step_fin(o, s, e, bt, bh)
    "pres": (lambda o, s, e, bt, bh, s2: inv_fin(s), lambda o, s, e, bt, bh, s2: inv_fin(s2)),
    "hb_shape": (lambda o, s, e, bt, bh, s2: s2[L] != "LPtn",
                 lambda o, s, e, bt, bh, s2: {"CReset": True, "CKeep": s[L] != "LPtn", "CInc": bh}[R.upd_hb(s, e, bh)]),
    "tack_shape": (lambda o, s, e, bt, bh, s2: s2[D] == "DmsArmed",
                   lambda o, s, e, bt, bh, s2: {"CReset": True, "CKeep": s[D] == "DmsArmed", "CInc": bt}[R.upd_tack(s, e, bt, bh)]),
    "P1_latched": (lambda o, s, e, bt, bh, s2: e[0] != "Reset", lambda o, s, e, bt, bh, s2: C.RANK[o][s2[L]] >= C.RANK[o][s[L]]),
    "P2_ptn_deenergizes": (lambda o, s, e, bt, bh, s2: s[L] != "LPtn" and s2[L] == "LPtn",
                           lambda o, s, e, bt, bh, s2: unpowered(s2[NB]) and unpowered(s2[RF])),
    # (b4) out of power, full or partial
    "P3_stop_reduces_power": (lambda o, s, e, bt, bh, s2: s[L] == "LNone" and s2[L] in ("LJtt", "LRtps"),
                              lambda o, s, e, bt, bh, s2: not hot(s2[NB]) and not hot(s2[RF])),
    # (b4) never returns to power, full or partial
    "P4_ramping_never_returns": (lambda o, s, e, bt, bh, s2: e[0] != "Reset" and "Ramping" in (s[NB], s[RF]),
                                 lambda o, s, e, bt, bh, s2: all(not (s[i] == "Ramping" and hot(s2[i])) for i in (NB, RF))),
    # (b4) the window is read on the waveform phase
    "P5_heat_permissive": (lambda o, s, e, bt, bh, s2: e[0] == "HeatOn",
                           lambda o, s, e, bt, bh, s2: _p5_unit(heat_win(wave(s)) and s[PL] and s[L] == "LNone", _u(s, e[1]), _u(s2, e[1]))),
    # (b4) with a stop in force nothing acquires power
    "P6_stop_overrides_heat": (lambda o, s, e, bt, bh, s2: s[L] != "LNone",
                               lambda o, s, e, bt, bh, s2: all(not (not hot(s[i]) and hot(s2[i])) for i in (NB, RF))),
    # (b4) no unit acquires power without its command
    "P7_heat_frame": (lambda o, s, e, bt, bh, s2: any(hot(s2[i]) and not hot(s[i]) for i in (NB, RF)),
                      lambda o, s, e, bt, bh, s2: e[0] == "HeatOn" and all((not (hot(s2[i]) and not hot(s[i]))) or e[1] == w
                                                                          for i, w in ((NB, "Nb"), (RF, "Rf")))),
    # (b4) a local alarm reduces its unit (F2b: the frame; F2a below: the reduction)
    "P9_local_is_local": (lambda o, s, e, bt, bh, s2: e[0] == "Local",
                          lambda o, s, e, bt, bh, s2: _fin_frame(s, s2, e[1]) and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep"),
    "P10_no_spurious_stop": (lambda o, s, e, bt, bh, s2: s2[L] != s[L],
                             lambda o, s, e, bt, bh, s2: e[0] in ("Stop", "CommFault", "Reset") or (e[0] == "Tick" and not bh and s[L] != "LPtn")),
    # (b4) F3a: an ENABLED communication check is a PTN stop from any state
    "P12_commfault_ptn": (lambda o, s, e, bt, bh, s2: e[0] == "CommFault" and e[2], lambda o, s, e, bt, bh, s2: s2[L] == "LPtn"),
    # (b4) neither the program phase nor the waveform phase rewinds
    "P14_phase_monotone": (lambda o, s, e, bt, bh, s2: e[0] != "Reset",
                           lambda o, s, e, bt, bh, s2: C.PHASES.index(s2[P]) >= C.PHASES.index(s[P])
                           and C.PHASES.index(wave(s2)) >= C.PHASES.index(wave(s))),
    "P15_dms_monotone": (lambda o, s, e, bt, bh, s2: e[0] != "Reset",
                         lambda o, s, e, bt, bh, s2: C.DMSS.index(s2[D]) >= C.DMSS.index(s[D])),
    # (b4) a demand arms the DMS when the current is above the DMV threshold (IP2, abstract form)
    "P16_dms_armed_on_demand": (lambda o, s, e, bt, bh, s2: s[D] == "DmsIdle" and s[IP] and demands(e, bh, s[L]),
                                lambda o, s, e, bt, bh, s2: s2[D] == "DmsArmed"),
    # (b4) nothing else arms it, and never below the threshold
    "P17_dms_frame": (lambda o, s, e, bt, bh, s2: s[D] == "DmsIdle" and s2[D] != "DmsIdle",
                      lambda o, s, e, bt, bh, s2: s[IP] and demands(e, bh, s[L])),
    "P18_tack_frame": (lambda o, s, e, bt, bh, s2: s[D] == "DmsArmed" and e[0] not in ("Tick", "Reset"),
                       lambda o, s, e, bt, bh, s2: R.upd_tack(s, e, bt, bh) == "CKeep"),
    "P19_advance_frozen": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[L] == "LPtn",
                           lambda o, s, e, bt, bh, s2: s2 == s and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep"),
    "P20_reset_guarded": (lambda o, s, e, bt, bh, s2: e[0] == "Reset",
                          lambda o, s, e, bt, bh, s2: (s2 == C.INIT and R.upd_hb(s, e, bh) == "CReset" and R.upd_tack(s, e, bt, bh) == "CReset")
                          if R.reset_ok(s) else (s2 == s and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep")),
    # (b4) "before the pulse ended" reads the waveform phase
    "P21_reset_refused_mid_pulse": (lambda o, s, e, bt, bh, s2: e[0] == "Reset" and (s[D] == "DmsArmed" or (s[L] != "LPtn" and wave(s) != "Termination")),
                                    lambda o, s, e, bt, bh, s2: s2 == s and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep"),
}
FRAME_LAWS = {"P7_heat_frame", "P9_local_is_local", "P10_no_spurious_stop", "P14_phase_monotone", "P15_dms_monotone",
              "P17_dms_frame", "P18_tack_frame", "P19_advance_frozen"}

# state corollaries (under inv_fin); (b4) "no full power" became "no power, full or partial"
CORS = {
    "ptn_no_heat": (lambda s: s[L] == "LPtn", lambda s: unpowered(s[NB]) and unpowered(s[RF])),
    "dms_no_heat": (lambda s: s[D] != "DmsIdle", lambda s: unpowered(s[NB]) and unpowered(s[RF])),
    "stop_no_full_power": (lambda s: s[L] != "LNone", lambda s: not hot(s[NB]) and not hot(s[RF])),
    "termination_no_full_power": (lambda s: wave(s) == "Termination", lambda s: not hot(s[NB]) and not hot(s[RF])),
}


DEMAND_LAWS = {
    # D1 a stop request is honoured: the level becomes the least upper bound of the current
    # response and the requested one. Two-sided where P1 is one-sided.
    "D1_stop_honoured": (lambda o, s, e, bt, bh, s2: e[0] == "Stop",
                         lambda o, s, e, bt, bh, s2: s2[L] == lub(o, s[L], e[1])),
    # D2 (b4) an accepted soft stop takes every unit delivering power into ramp-down (R-4, H16; F2c)
    "D2_soft_stop_ramps": (lambda o, s, e, bt, bh, s2: e[0] == "Stop" and e[1] in ("LJtt", "LRtps")
                           and C.RANK[o][e[1]] > C.RANK[o][s[L]] and any(hot(s[i]) for i in (NB, RF)),
                           lambda o, s, e, bt, bh, s2: all(s2[i] == "Ramping" for i in (NB, RF) if hot(s[i]))),
    # D3 (b4) the natural end of the programme also ramps down (program phase)
    "D3_advance_to_termination_ramps": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[L] != "LPtn"
                                        and s[P] == "Heating2" and any(hot(s[i]) for i in (NB, RF)),
                                        lambda o, s, e, bt, bh, s2: all(s2[i] == "Ramping" for i in (NB, RF) if hot(s[i]))),
    # D4 the watchdog latches the PTN whatever the instance wires to the DMS
    "D4_watchdog_latches": (lambda o, s, e, bt, bh, s2: e[0] == "Tick" and not bh and s[L] != "LPtn",
                            lambda o, s, e, bt, bh, s2: s2[L] == "LPtn"),
    # D5 the heartbeat counter counts while the PTN is not latched (positive dual of I6)
    "D5_hb_counts": (lambda o, s, e, bt, bh, s2: e[0] == "Tick" and bh and s[L] != "LPtn",
                     lambda o, s, e, bt, bh, s2: R.upd_hb(s, e, bh) == "CInc"),
    # D6 only a heartbeat (or the accepted end of pulse) may reset the watchdog
    "D6_hb_frame": (lambda o, s, e, bt, bh, s2: R.upd_hb(s, e, bh) == "CReset",
                    lambda o, s, e, bt, bh, s2: e[0] == "Heartbeat" or (e[0] == "Reset" and R.reset_ok(s))),
    # D7 the acknowledgement timeout fires the DMS (guarded by level = PTN: with the DMS armed
    # and the PTN not latched -- a state I4 excludes -- the watchdog clause would run instead)
    "D7_ack_timeout_fires": (lambda o, s, e, bt, bh, s2: s[D] == "DmsArmed" and s[L] == "LPtn" and e[0] == "Tick" and not bt,
                             lambda o, s, e, bt, bh, s2: s2[D] == "DmsFired"),
    # D8 and it counts up while below the limit (positive dual of I5)
    "D8_ack_counts": (lambda o, s, e, bt, bh, s2: s[D] == "DmsArmed" and s[L] == "LPtn" and e[0] == "Tick" and bt,
                      lambda o, s, e, bt, bh, s2: R.upd_tack(s, e, bt, bh) == "CInc"),
    # D9 the acknowledgement from the heating plant fires the DMS
    "D9_heatack_fires": (lambda o, s, e, bt, bh, s2: s[D] == "DmsArmed" and e[0] == "HeatAck",
                         lambda o, s, e, bt, bh, s2: s2[D] == "DmsFired"),
    # D10 (b4) the end of pulse IS accepted when the pulse has ended (PTN, or the termination
    # waveform running) and no mitigation is armed. The guard is spelled out, not taken from
    # the model's own reset_ok -- that self-reference is why P20 cannot detect a wrong guard.
    "D10_reset_accepted_when_safe": (lambda o, s, e, bt, bh, s2: e[0] == "Reset" and reset_accepted_by_spec(s),
                                     lambda o, s, e, bt, bh, s2: s2 == C.INIT and R.upd_hb(s, e, bh) == "CReset"
                                     and R.upd_tack(s, e, bt, bh) == "CReset"),
    # D11 (b4) the programme advances exactly one phase (the program phase)
    "D11_advance_is_one_step": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[L] != "LPtn" and s[P] != "Termination",
                                lambda o, s, e, bt, bh, s2: s2[P] == succ_phase(s[P])),
    # D12 (b4) nothing but Advance or Reset moves the program phase (a JTT moves the WAVEFORM: F1)
    "D12_phase_frame": (lambda o, s, e, bt, bh, s2: s2[P] != s[P],
                        lambda o, s, e, bt, bh, s2: e[0] in ("Advance", "Reset")),
    # D13 the plasma conditions are an input, and only that input (or the end of pulse) moves them
    "D13_plasma_is_input": (lambda o, s, e, bt, bh, s2: e[0] == "Plasma",
                            lambda o, s, e, bt, bh, s2: s2[PL] == e[1]),
    "D14_plasma_frame": (lambda o, s, e, bt, bh, s2: s2[PL] != s[PL],
                         lambda o, s, e, bt, bh, s2: e[0] == "Plasma" or (e[0] == "Reset" and R.reset_ok(s))),
    # D15 a heating command touches its own unit and nothing else (the mirror of P9)
    "D15_heatoff_is_local": (lambda o, s, e, bt, bh, s2: e[0] == "HeatOff",
                             lambda o, s, e, bt, bh, s2: _one_unit(s, s2, e[1], deenergize(_u(s, e[1])), bt, bh, e)),
    "D16_heaton_is_local": (lambda o, s, e, bt, bh, s2: e[0] == "HeatOn",
                            lambda o, s, e, bt, bh, s2: _frame_but_units(s, s2) and _u(s2, _other(e[1])) == _u(s, _other(e[1]))
                            and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep"),
    # D17 an acknowledgement moves the DMS and nothing else
    "D17_heatack_frame": (lambda o, s, e, bt, bh, s2: e[0] == "HeatAck",
                          lambda o, s, e, bt, bh, s2: all(s2[i] == s[i] for i in (P, J, L, PL, IP, NB, RF))
                          and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep"),
    # D18 a heartbeat touches the counter and nothing else
    "D18_heartbeat_frame": (lambda o, s, e, bt, bh, s2: e[0] == "Heartbeat",
                            lambda o, s, e, bt, bh, s2: s2 == s and R.upd_tack(s, e, bt, bh) == "CKeep"),
}

LAWS.update(DEMAND_LAWS)
FRAME_LAWS |= {"D6_hb_frame", "D12_phase_frame", "D14_plasma_frame", "D15_heatoff_is_local",
               "D16_heaton_is_local", "D17_heatack_frame", "D18_heartbeat_frame"}


EXTRA_LAWS = {
    # E2 the DMS fires only on the plant acknowledgement or on the acknowledgement timeout
    "E2_dms_fire_frame": (lambda o, s, e, bt, bh, s2: s[D] == "DmsArmed" and s2[D] == "DmsFired",
                          lambda o, s, e, bt, bh, s2: e[0] == "HeatAck" or (e[0] == "Tick" and not bt)),
    # E3 (b4) a stop moves the WAVEFORM phase to Termination exactly when an accepted JTT asks for it
    "E3_stop_phase_exact": (lambda o, s, e, bt, bh, s2: e[0] == "Stop",
                            lambda o, s, e, bt, bh, s2: wave(s2) == ("Termination" if (e[1] == "LJtt" and C.RANK[o][e[1]] > C.RANK[o][s[L]]) else wave(s))),
    # E4 the units after an Advance are fully determined (D3 covered only one of the six)
    "E4_advance_units": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[L] != "LPtn" and s[P] != "Termination",
                         lambda o, s, e, bt, bh, s2: s2[NB] == adv_unit(s, s[NB]) and s2[RF] == adv_unit(s, s[RF])),
    # E5 a heartbeat always restarts the watchdog counter
    "E5_heartbeat_resets_hb": (lambda o, s, e, bt, bh, s2: e[0] == "Heartbeat",
                               lambda o, s, e, bt, bh, s2: R.upd_hb(s, e, bh) == "CReset"),
    # E6 the watchdog counter on a Tick is exactly determined (two-sided D5)
    "E6_hb_tick_exact": (lambda o, s, e, bt, bh, s2: e[0] == "Tick",
                         lambda o, s, e, bt, bh, s2: R.upd_hb(s, e, bh) == ("CInc" if (bh and s[L] != "LPtn") else "CKeep")),
    # E7 only a Tick with the DMS armed and the wait below the limit may increment it
    "E7_tack_inc_frame": (lambda o, s, e, bt, bh, s2: R.upd_tack(s, e, bt, bh) == "CInc",
                          lambda o, s, e, bt, bh, s2: e[0] == "Tick" and s[D] == "DmsArmed" and bt),
    # E8 (b4) only a demand that actually arms (idle, above the threshold), or the accepted end of
    # pulse, restarts the wait (the guard is spelled out, not taken from the model's own reset_ok)
    "E8_tack_reset_frame": (lambda o, s, e, bt, bh, s2: R.upd_tack(s, e, bt, bh) == "CReset",
                            lambda o, s, e, bt, bh, s2: (e[0] == "Reset" and reset_accepted_by_spec(s))
                            or (demands(e, bh, s[L]) and s[IP] and s[D] == "DmsIdle")),
    # E11 the acknowledgement is two-sided (replaces the one-sided D9)
    "E11_heatack_exact": (lambda o, s, e, bt, bh, s2: e[0] == "HeatAck",
                          lambda o, s, e, bt, bh, s2: s2[D] == ("DmsFired" if s[D] == "DmsArmed" else s[D])),
}

LAWS.update(EXTRA_LAWS)
FRAME_LAWS |= {"E2_dms_fire_frame", "E7_tack_inc_frame", "E8_tack_reset_frame"}


# ---------------------------------------------------------------------------
# Blocker 4 (fidelity): F1 program/waveform, F2 partial power, F3 masks, IP the DMV threshold
# ---------------------------------------------------------------------------
FIDELITY_LAWS = {
    # F1b a stop request never moves the PROGRAM phase (the JTT switches the waveform: A-24)
    "F1b_stop_keeps_prog": (lambda o, s, e, bt, bh, s2: e[0] == "Stop",
                            lambda o, s, e, bt, bh, s2: s2[P] == s[P]),
    # F1d the waveform phase moves only with the programme, an accepted JTT, or the end of pulse
    "F1d_wave_frame": (lambda o, s, e, bt, bh, s2: wave(s2) != wave(s),
                       lambda o, s, e, bt, bh, s2: e[0] in ("Advance", "Reset") or (e[0] == "Stop" and e[1] == "LJtt")),
    # F1e the termination-waveform flag is exactly determined: set by an accepted JTT, cleared by the
    # end of pulse, kept otherwise (found by the tightness metric: two states with prog = Termination
    # differing only in jtt were indistinguishable)
    "F1e_jtt_exact": (lambda o, s, e, bt, bh, s2: e[0] != "Reset",
                      lambda o, s, e, bt, bh, s2: s2[J] == (s[J] or (e[0] == "Stop" and e[1] == "LJtt" and C.RANK[o]["LJtt"] > C.RANK[o][s[L]]))),
    # F4 the units move only with their own commands, a plasma loss, the programme, the end of pulse,
    # or a step that changes the response level (frame; found by the tightness metric)
    "F4_units_frame": (lambda o, s, e, bt, bh, s2: s2[L] == s[L] and e[0] not in ("Local", "HeatOn", "HeatOff", "Advance", "Reset")
                       and not (e[0] == "Plasma" and not e[1]) and not (e[0] == "Stop" and e[1] == "LPtn") and not (e[0] == "CommFault" and e[2]),
                       lambda o, s, e, bt, bh, s2: s2[NB] == s[NB] and s2[RF] == s[RF]),
    # F2a a local alarm takes its unit from full to PARTIAL power, never off (R-9)
    "F2a_local_reduces": (lambda o, s, e, bt, bh, s2: e[0] == "Local" and _u(s, e[1]) == "On",
                          lambda o, s, e, bt, bh, s2: _u(s2, e[1]) == "Reduced"),
    # F2d a unit at partial power never returns to full power in the pulse (R-9 as modelled, A-6)
    "F2d_reduced_never_returns": (lambda o, s, e, bt, bh, s2: e[0] != "Reset" and "Reduced" in (s[NB], s[RF]),
                                  lambda o, s, e, bt, bh, s2: all(not (s[i] == "Reduced" and s2[i] == "On") for i in (NB, RF))),
    # F3b a communication check that the instance disables is the identity, counters included (A-21)
    "F3b_commfault_masked_is_noop": (lambda o, s, e, bt, bh, s2: e[0] == "CommFault" and not e[2],
                                     lambda o, s, e, bt, bh, s2: s2 == s and R.upd_hb(s, e, bh) == "CKeep" and R.upd_tack(s, e, bt, bh) == "CKeep"),
    # IP1 below the DMV current threshold the DMS never arms, whatever the event (R-14)
    "IP1_ip_low_never_arms": (lambda o, s, e, bt, bh, s2: not s[IP] and s[D] == "DmsIdle",
                              lambda o, s, e, bt, bh, s2: s2[D] == "DmsIdle"),
    # IP3 the current verdict is an input ...
    "IP3_ip_is_input": (lambda o, s, e, bt, bh, s2: e[0] == "Ip",
                        lambda o, s, e, bt, bh, s2: s2[IP] == e[1]),
    # IP4 ... and only that input, or the accepted end of pulse, moves it
    "IP4_ip_frame": (lambda o, s, e, bt, bh, s2: s2[IP] != s[IP],
                     lambda o, s, e, bt, bh, s2: e[0] == "Ip" or (e[0] == "Reset" and reset_accepted_by_spec(s))),
}

LAWS.update(FIDELITY_LAWS)
FRAME_LAWS |= {"F1b_stop_keeps_prog", "F1d_wave_frame", "F1e_jtt_exact", "F4_units_frame", "F3b_commfault_masked_is_noop", "IP1_ip_low_never_arms", "IP4_ip_frame"}

# Laws that are DERIVED rather than independent evidence, and why. Reported by the gates so
# the write-up cannot present them as independent (audit #5 §5, §8).
DERIVED = {
    "D3_advance_to_termination_ramps": "subsumed by E4_advance_units (which covers all six advances)",
    "D5_hb_counts": "one half of E6_hb_tick_exact",
    "D9_heatack_fires": "one half of E11_heatack_exact",
    "D10_reset_accepted_when_safe": "pointwise implied by P20_reset_guarded; its job is to break P20's "
                                    "self-reference (P20 quotes the model's own reset_ok, D10 spells the guard out)",
    "F1b_stop_keeps_prog": "the Stop case of D12_phase_frame; kept as the named statement of A-24",
    "F2a_local_reduces": "the reduction half of P9_local_is_local; kept as the named statement of R-9",
}


# ---------------------------------------------------------------------------
# Outside the cell property: the concrete layer and the verdict domain
# ---------------------------------------------------------------------------

def concretize_conforms(limit=20):
    """C1: `concretize` is the configuration, value by value: Table 1 read on the PROGRAM phase
    (F1a), the DMS window on the waveform phase, the blind row and the masks of the instance (F3),
    the current verdict as an input. Returns the offending cells, at most `limit`."""
    bad = []
    for i in (1, 2, 3):
        for p in C.PHASES:
            for j in (False, True):
                for ip in (True, False):
                    s = (p, j, "LNone", "DmsIdle", True, ip, "Off", "Off")
                    w = "Termination" if j else p
                    for c in R.CEVENTS:
                        if c[0] == "XAlarm":
                            lvl = "LNone" if (c[1] == "Blind" and not C.MASKS[i][1]) else C.TABLE[i][c[1]][C.PHASES.index(p)]
                            want = ("Stop", lvl, c[1] in C.DMS_TRIG and w in C.DMS_WINDOW)
                        elif c[0] == "XCommFault":
                            want = ("CommFault", C.DMS_ON_COMMFAULT, C.MASKS[i][0])
                        elif c[0] == "XTick":
                            want = ("Tick", C.DMS_ON_WATCHDOG)
                        else:
                            want = (c[0][1:],) + tuple(c[1:])
                        if R.concretize(i, s, c) != want:
                            bad.append((i, s, c))
                            if len(bad) >= limit:
                                return bad
    return bad


def step_c_conforms(limit=20):
    """C3: step_c is the abstract step, under the instance's declared order, on the state BEFORE
    the transition, through that instance's configuration."""
    bad = []
    for i in (1, 2, 3):
        for s in R.all_states():
            for hb in range(C.HB_MAX + 2):
                for tack in range(C.ACK_MAX + 2):
                    st = (s, hb, tack)
                    for c in R.CEVENTS:
                        want = R.step_st(C.ORD_OF_INSTANCE[i], st, R.concretize(i, s, c))
                        if R.step_c(i, st, c) != want:
                            bad.append((i, st, c))
                            if len(bad) >= limit:
                                return bad
    return bad


def verdict_frame_holds(limit=20):
    """V1: outside the Tick arm neither the step nor the counter commands read the verdicts."""
    bad = []
    for o in (1, 2):
        for s in R.all_states():
            for e in R.EVENTS:
                if e[0] == "Tick":
                    continue
                for bt in (True, False):
                    for bh in (True, False):
                        if (R.step_fin(o, s, e, bt, bh) != R.step_fin(o, s, e, True, True)
                                or R.upd_hb(s, e, bh) != R.upd_hb(s, e, True)
                                or R.upd_tack(s, e, bt, bh) != R.upd_tack(s, e, True, True)):
                            bad.append((o, s, e, bt, bh))
                            if len(bad) >= limit:
                                return bad
    return bad


def check_cell(o, s, e, bt, bh, s2=None):
    """Which laws FAIL on this cell (s2 defaults to this model's step)."""
    s2 = R.step_fin(o, s, e, bt, bh) if s2 is None else s2
    return [n for n, (h, c) in LAWS.items() if h(o, s, e, bt, bh, s2) and not c(o, s, e, bt, bh, s2)]


def inv_all_disagrees(limit=20):
    """S1: the invariant of the model (jetprot_ref.inv_all) and the one of the spec (inv_all
    above) must agree on every (state, hb, tack) of the counter domain; a mutant of the model
    invariant is caught here and nowhere else, which is the point (mutant M72)."""
    bad = []
    for s in R.all_states():
        for hb in range(C.HB_MAX + 2):
            for tack in range(C.ACK_MAX + 2):
                st = (s, hb, tack)
                if R.inv_all(st) != inv_all(st):
                    bad.append(st)
                    if len(bad) >= limit:
                        return bad
    return bad
