"""jetprot_ref.py - an INDEPENDENT Python model of docs/fase3-diseno.md §1 (rules 1-11,
counter commands, invariants, the cell laws P1..P20), written from the design document and
not from jetprot.bend. Used by recheck.py for:
  C5  the certificate re-check: every cell of the Bend model (through bridge.mjs) is compared
      with this model, and every law is re-evaluated here on the Bend-produced next state;
  C2  vacuity / coverage: reachability, hypothesis counts, conclusion falsifiability;
  C6  the mutation score: MUT flags plant defects and the laws must catch them.

State: a tuple (phase, level, dms, plasma, nb, rf). Abstract events: tuples
  ("Advance",) ("Stop", req, dms) ("Local", u) ("HeatOn", u) ("HeatOff", u) ("Plasma", ok)
  ("CommFault", dms) ("Heartbeat",) ("Tick", dms) ("HeatAck",) ("Reset",)
Concrete events: ("XAlarm", t) ("XCommFault",) ("XTick",) and the rest as above with X.
"""
from itertools import product

PHASES = ["Breakdown", "IpRise", "Limiter", "Xpoint", "Heating1", "Heating2", "Termination"]
LEVELS = ["LNone", "LJtt", "LRtps", "LPtn"]
DMSS = ["DmsIdle", "DmsArmed", "DmsFired"]
HEATS = ["Off", "Inhibited", "Ramping", "On"]
WHO = ["Nb", "Rf"]
TRIGS = ["Slow", "Fast", "Mhd", "MhdB", "Mchs", "Dhs", "BothHs"]
HB_MAX, ACK_MAX = 3, 2
RANK = {1: {"LNone": 0, "LJtt": 1, "LRtps": 2, "LPtn": 3}, 2: {"LNone": 0, "LJtt": 2, "LRtps": 1, "LPtn": 3}}
INIT = ("Breakdown", "LNone", "DmsIdle", False, "Off", "Off")

MUT = {k: False for k in ["deescalation", "jtt_no_ramp", "commfault_no_deenergize", "dms_on_soft", "rearm_restarts_ack",
                          "rtps_no_ramp", "deenergize_clears_inhibit", "advance_under_ptn", "reset_while_armed",
                          "heaton_under_rtps", "plasma_false_keeps_heat", "watchdog_off_by_one", "local_touches_level",
                          "dms_never_armed", "commfault_arms_dms", "jtt_stays_in_phase", "rearm_from_fired"]}

EVENTS = [("Advance",), ("Heartbeat",), ("HeatAck",), ("Reset",)]
EVENTS += [(k, u) for u in WHO for k in ("Local", "HeatOn", "HeatOff")]
EVENTS += [("Plasma", b) for b in (True, False)] + [("CommFault", b) for b in (True, False)] + [("Tick", b) for b in (True, False)]
EVENTS += [("Stop", r, b) for r in LEVELS for b in (True, False)]
CEVENTS = [("XAdvance",), ("XHeartbeat",), ("XHeatAck",), ("XReset",), ("XCommFault",), ("XTick",)]
CEVENTS += [(k, u) for u in WHO for k in ("XLocal", "XHeatOn", "XHeatOff")] + [("XPlasma", b) for b in (True, False)]
CEVENTS += [("XAlarm", t) for t in TRIGS]


def all_states():
    return [s for s in product(PHASES, LEVELS, DMSS, (True, False), HEATS, HEATS)]


# The certificate enumerates all four verdict pairs for the five columns where the checker
# cannot discharge the verdicts symbolically (reset_if / arms_now stay stuck on a symbolic
# Fin): both Ticks, Reset, CommFault{True} and Stop{LPtn,True}. 19 x 1 + 5 x 4 = 39 columns.
WIDE = {("Reset",), ("CommFault", True), ("Stop", "LPtn", True)}


def verdicts_for(e):
    wide = e[0] == "Tick" or e in WIDE
    return [(bt, bh) for bt in (True, False) for bh in (True, False)] if wide else [(True, True)]


# --- helpers ---
def heat_win(p):
    return p in ("Heating1", "Heating2")


def deenergize(u):
    if MUT["deenergize_clears_inhibit"] and u == "Inhibited":
        return "Off"
    return "Off" if u in ("On", "Ramping") else u


def ramp(u):
    return "Ramping" if u == "On" else u


def to_ptn(s):
    p, l, d, pl, nb, rf = s
    if MUT["commfault_no_deenergize"]:
        return (p, "LPtn", d, pl, nb, rf)
    return (p, "LPtn", d, pl, deenergize(nb), deenergize(rf))


def arm(s):
    p, l, d, pl, nb, rf = s
    if MUT["dms_never_armed"]:
        return s
    if d == "DmsIdle" or (MUT["rearm_from_fired"] and d == "DmsFired"):
        return (p, l, "DmsArmed", pl, nb, rf)
    return s


def soft(s, req):
    p, l, d, pl, nb, rf = s
    skip = (MUT["jtt_no_ramp"] and req == "LJtt") or (MUT["rtps_no_ramp"] and req == "LRtps")
    nb2, rf2 = (nb, rf) if skip else (ramp(nb), ramp(rf))
    p2 = p if (req != "LJtt" or MUT["jtt_stays_in_phase"]) else "Termination"
    return (p2, req, d, pl, nb2, rf2)


def reset_ok(s):
    p, l, d, pl, nb, rf = s
    return (l == "LPtn" or p == "Termination") and (d != "DmsArmed" or MUT["reset_while_armed"])


def step_fin(o, s, e, bt, bh):
    p, l, d, pl, nb, rf = s
    k = e[0]
    if k == "Stop":
        req, dm = e[1], e[2]
        if req == "LPtn":
            s2 = to_ptn(s)
            return arm(s2) if dm else s2
        accept = (req != "LNone") if MUT["deescalation"] else (RANK[o][req] > RANK[o][l])
        if not accept:
            return s
        s2 = soft(s, req)
        return arm(s2) if (dm and MUT["dms_on_soft"]) else s2
    if k == "Local":
        s2 = (p, l, d, pl, "Inhibited", rf) if e[1] == "Nb" else (p, l, d, pl, nb, "Inhibited")
        if MUT["local_touches_level"] and l == "LNone":
            s2 = (s2[0], "LJtt", *s2[2:])
        return s2
    if k == "HeatOn":
        ok = heat_win(p) and pl and (l == "LNone" or (MUT["heaton_under_rtps"] and l == "LRtps"))
        u = nb if e[1] == "Nb" else rf
        if ok and u == "Off":
            return (p, l, d, pl, "On", rf) if e[1] == "Nb" else (p, l, d, pl, nb, "On")
        return s
    if k == "HeatOff":
        return (p, l, d, pl, deenergize(nb), rf) if e[1] == "Nb" else (p, l, d, pl, nb, deenergize(rf))
    if k == "Plasma":
        if e[1] or MUT["plasma_false_keeps_heat"]:
            return (p, l, d, e[1], nb, rf)
        return (p, l, d, False, deenergize(nb), deenergize(rf))
    if k == "Advance":
        if (l == "LPtn" and not MUT["advance_under_ptn"]) or p == "Termination":
            return s
        nxt = PHASES[PHASES.index(p) + 1]
        if nxt == "Termination":
            return (nxt, l, d, pl, ramp(nb), ramp(rf))
        if not heat_win(nxt):
            return (nxt, l, d, pl, deenergize(nb), deenergize(rf))
        return (nxt, l, d, pl, nb, rf)
    if k == "CommFault":
        s2 = to_ptn(s)
        return arm(s2) if (e[1] or MUT["commfault_arms_dms"]) else s2
    if k == "Heartbeat":
        return s
    if k == "Tick":
        if (not bh) and l != "LPtn":
            s2 = to_ptn(s)
            return arm(s2) if e[1] else s2
        if d == "DmsArmed" and not bt:
            return (p, l, "DmsFired", pl, nb, rf)
        return s
    if k == "HeatAck":
        return (p, l, "DmsFired", pl, nb, rf) if d == "DmsArmed" else s
    if k == "Reset":
        return INIT if reset_ok(s) else s
    raise ValueError(e)


def arms_now(dm, s):
    return dm and s[2] == "DmsIdle"


def upd_hb(s, e, bh):
    k = e[0]
    if k == "Tick":
        return "CInc" if (bh and s[1] != "LPtn") else "CKeep"
    if k == "Heartbeat":
        return "CReset"
    if k == "Reset":
        return "CReset" if reset_ok(s) else "CKeep"
    return "CKeep"


def upd_tack(s, e, bt, bh):
    k = e[0]
    if k == "Stop":
        if MUT["rearm_restarts_ack"]:
            return "CReset" if (e[1] == "LPtn" and e[2]) else "CKeep"
        return "CReset" if (e[1] == "LPtn" and arms_now(e[2], s)) else "CKeep"
    if k == "CommFault":
        return "CReset" if arms_now(e[1], s) else "CKeep"
    if k == "Tick":
        if (not bh) and s[1] != "LPtn":
            return "CReset" if arms_now(e[1], s) else "CKeep"
        return "CInc" if (s[2] == "DmsArmed" and bt) else "CKeep"
    if k == "Reset":
        return "CReset" if reset_ok(s) else "CKeep"
    return "CKeep"


def apply(cmd, n):
    return n if cmd == "CKeep" else (0 if cmd == "CReset" else n + 1)


def verdicts(hb, tack):
    bh = (hb + 1 <= HB_MAX) if MUT["watchdog_off_by_one"] else (hb + 1 < HB_MAX)
    return tack + 1 < ACK_MAX, bh


def step_st(o, st, e):
    s, hb, tack = st
    bt, bh = verdicts(hb, tack)
    return (step_fin(o, s, e, bt, bh), apply(upd_hb(s, e, bh), hb), apply(upd_tack(s, e, bt, bh), tack))


# --- the concrete layer (configuration instances) ---
def lvl_max(o, a, b):
    return b if RANK[o][a] < RANK[o][b] else a


def table_pub(p, t):
    i = PHASES.index(p)
    if t == "Slow":
        return "LRtps" if i in (4, 5) else "LPtn"
    if t == "Mhd":
        return "LNone"
    if t == "Mchs":
        return "LRtps" if i in (4, 5) else ("LPtn" if i == 6 else "LNone")
    if t == "Dhs":
        return "LJtt" if i == 5 else "LPtn"
    return "LNone"


def table1(p, t):
    if t == "Fast":
        return "LPtn"
    if t == "MhdB":
        return table_pub(p, "Mhd")
    if t == "BothHs":
        return lvl_max(1, table_pub(p, "Mchs"), table_pub(p, "Dhs"))
    return table_pub(p, t)


def table(inst, p, t):
    if inst == 2 and t in ("Mhd", "MhdB") and PHASES.index(p) >= 3:
        return "LPtn"
    return table1(p, t)


def dms_req(p, t):
    return t in ("Fast", "Mhd", "MhdB") and PHASES.index(p) >= 3


def concretize(inst, p, c):
    k = c[0]
    if k == "XAlarm":
        return ("Stop", table(inst, p, c[1]), dms_req(p, c[1]))
    if k == "XCommFault":
        return ("CommFault", False)
    if k == "XTick":
        return ("Tick", False)
    return (k[1:],) + tuple(c[1:])


def step_c(inst, st, c):
    return step_st(1, st, concretize(inst, st[0][0], c))



# ---------------------------------------------------------------------------
# The concrete layer under law: `concretize` must be exactly the table lookup. Restated here
# independently of concretize() itself, so a mis-wired column or constructor is caught
# (audit #4 mutants M17/M18/M19: nothing constrained this layer).
# ---------------------------------------------------------------------------

def concretize_expected(inst, p, c):
    k = c[0]
    if k == "XAlarm":
        return ("Stop", table(inst, p, c[1]), dms_req(p, c[1]))
    if k == "XCommFault":
        return ("CommFault", False)     # dms_on_commfault
    if k == "XTick":
        return ("Tick", False)          # dms_on_watchdog
    return (k[1:],) + tuple(c[1:])



# --- invariants ---
def inv_fin(s):
    p, l, d, pl, nb, rf = s
    for u in (nb, rf):
        if u == "On" and not (heat_win(p) and pl and l == "LNone"):
            return False
        if u == "Ramping" and not (pl and l != "LPtn" and (l != "LNone" or p == "Termination")):
            return False
    if l == "LJtt" and p != "Termination":
        return False
    if d != "DmsIdle" and l != "LPtn":
        return False
    return True


def inv_all(st):
    s, hb, tack = st
    return inv_fin(s) and (s[2] != "DmsArmed" or tack < ACK_MAX) and (s[1] == "LPtn" or hb < HB_MAX)


# --- the cell laws as (hypothesis, conclusion) pairs over (o, s, e, bt, bh, s2) ---
def _u(s, w):
    return s[4] if w == "Nb" else s[5]


def unpowered(u):
    return u in ("Off", "Inhibited")


def demands(e, bh, l):
    k = e[0]
    if k == "Stop":
        return e[1] == "LPtn" and e[2]
    if k == "CommFault":
        return e[1]
    if k == "Tick":
        return e[1] and (not bh) and l != "LPtn"
    return False


def _fin_frame(s, s2, w):
    idx = 4 if w == "Nb" else 5
    other = 5 if w == "Nb" else 4
    return s2[idx] == "Inhibited" and s[:4] == s2[:4] and s[other] == s2[other]


def _p5_unit(ok, u, u2):
    acc = ok and u == "Off"
    return ((u2 == "On") == (acc or (u == "On" and not acc))) and (acc or u2 == u)


LAWS = {
    # name: (hypothesis, conclusion); each takes (o, s, e, bt, bh, s2) with s2 = step_fin(o, s, e, bt, bh)
    "pres": (lambda o, s, e, bt, bh, s2: inv_fin(s), lambda o, s, e, bt, bh, s2: inv_fin(s2)),
    "hb_shape": (lambda o, s, e, bt, bh, s2: s2[1] != "LPtn",
                 lambda o, s, e, bt, bh, s2: {"CReset": True, "CKeep": s[1] != "LPtn", "CInc": bh}[upd_hb(s, e, bh)]),
    "tack_shape": (lambda o, s, e, bt, bh, s2: s2[2] == "DmsArmed",
                   lambda o, s, e, bt, bh, s2: {"CReset": True, "CKeep": s[2] == "DmsArmed", "CInc": bt}[upd_tack(s, e, bt, bh)]),
    "P1_latched": (lambda o, s, e, bt, bh, s2: e[0] != "Reset", lambda o, s, e, bt, bh, s2: RANK[o][s2[1]] >= RANK[o][s[1]]),
    "P2_ptn_deenergizes": (lambda o, s, e, bt, bh, s2: s[1] != "LPtn" and s2[1] == "LPtn",
                           lambda o, s, e, bt, bh, s2: unpowered(s2[4]) and unpowered(s2[5])),
    "P3_stop_reduces_power": (lambda o, s, e, bt, bh, s2: s[1] == "LNone" and s2[1] in ("LJtt", "LRtps"),
                              lambda o, s, e, bt, bh, s2: s2[4] != "On" and s2[5] != "On"),
    "P4_ramping_never_returns": (lambda o, s, e, bt, bh, s2: e[0] != "Reset" and "Ramping" in (s[4], s[5]),
                                 lambda o, s, e, bt, bh, s2: all(not (s[i] == "Ramping" and s2[i] == "On") for i in (4, 5))),
    "P5_heat_permissive": (lambda o, s, e, bt, bh, s2: e[0] == "HeatOn",
                           lambda o, s, e, bt, bh, s2: _p5_unit(heat_win(s[0]) and s[3] and s[1] == "LNone", _u(s, e[1]), _u(s2, e[1]))),
    "P6_stop_overrides_heat": (lambda o, s, e, bt, bh, s2: s[1] != "LNone",
                               lambda o, s, e, bt, bh, s2: all(not (s[i] != "On" and s2[i] == "On") for i in (4, 5))),
    "P7_heat_frame": (lambda o, s, e, bt, bh, s2: any(s2[i] == "On" and s[i] != "On" for i in (4, 5)),
                      lambda o, s, e, bt, bh, s2: e[0] == "HeatOn" and all((not (s2[i] == "On" and s[i] != "On")) or e[1] == w
                                                                          for i, w in ((4, "Nb"), (5, "Rf")))),
    "P8_inhibit_latched": (lambda o, s, e, bt, bh, s2: e[0] != "Reset" and "Inhibited" in (s[4], s[5]),
                           lambda o, s, e, bt, bh, s2: all(not (s[i] == "Inhibited" and s2[i] != "Inhibited") for i in (4, 5))),
    "P9_local_is_local": (lambda o, s, e, bt, bh, s2: e[0] == "Local",
                          lambda o, s, e, bt, bh, s2: _fin_frame(s, s2, e[1]) and upd_hb(s, e, bh) == "CKeep" and upd_tack(s, e, bt, bh) == "CKeep"),
    "P10_no_spurious_stop": (lambda o, s, e, bt, bh, s2: s2[1] != s[1],
                             lambda o, s, e, bt, bh, s2: e[0] in ("Stop", "CommFault", "Reset") or (e[0] == "Tick" and not bh and s[1] != "LPtn")),
    "P12_commfault_ptn": (lambda o, s, e, bt, bh, s2: e[0] == "CommFault", lambda o, s, e, bt, bh, s2: s2[1] == "LPtn"),
    "P14_phase_monotone": (lambda o, s, e, bt, bh, s2: e[0] != "Reset",
                           lambda o, s, e, bt, bh, s2: PHASES.index(s2[0]) >= PHASES.index(s[0])),
    "P15_dms_monotone": (lambda o, s, e, bt, bh, s2: e[0] != "Reset",
                         lambda o, s, e, bt, bh, s2: DMSS.index(s2[2]) >= DMSS.index(s[2])),
    "P16_dms_armed_on_demand": (lambda o, s, e, bt, bh, s2: s[2] == "DmsIdle" and demands(e, bh, s[1]),
                                lambda o, s, e, bt, bh, s2: s2[2] == "DmsArmed"),
    "P17_dms_frame": (lambda o, s, e, bt, bh, s2: s[2] == "DmsIdle" and s2[2] != "DmsIdle",
                      lambda o, s, e, bt, bh, s2: demands(e, bh, s[1])),
    "P18_tack_frame": (lambda o, s, e, bt, bh, s2: s[2] == "DmsArmed" and e[0] not in ("Tick", "Reset"),
                       lambda o, s, e, bt, bh, s2: upd_tack(s, e, bt, bh) == "CKeep"),
    "P19_advance_frozen": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[1] == "LPtn",
                           lambda o, s, e, bt, bh, s2: s2 == s and upd_hb(s, e, bh) == "CKeep" and upd_tack(s, e, bt, bh) == "CKeep"),
    "P20_reset_guarded": (lambda o, s, e, bt, bh, s2: e[0] == "Reset",
                          lambda o, s, e, bt, bh, s2: (s2 == INIT and upd_hb(s, e, bh) == "CReset" and upd_tack(s, e, bt, bh) == "CReset")
                          if reset_ok(s) else (s2 == s and upd_hb(s, e, bh) == "CKeep" and upd_tack(s, e, bt, bh) == "CKeep")),
    "P21_reset_refused_mid_pulse": (lambda o, s, e, bt, bh, s2: e[0] == "Reset" and (s[2] == "DmsArmed" or (s[1] != "LPtn" and s[0] != "Termination")),
                                    lambda o, s, e, bt, bh, s2: s2 == s and upd_hb(s, e, bh) == "CKeep" and upd_tack(s, e, bt, bh) == "CKeep"),
}
FRAME_LAWS = {"P7_heat_frame", "P9_local_is_local", "P10_no_spurious_stop", "P14_phase_monotone", "P15_dms_monotone",
              "P17_dms_frame", "P18_tack_frame", "P19_advance_frozen"}

# state corollaries (under inv_fin)
CORS = {
    "ptn_no_heat": (lambda s: s[1] == "LPtn", lambda s: unpowered(s[4]) and unpowered(s[5])),
    "dms_no_heat": (lambda s: s[2] != "DmsIdle", lambda s: unpowered(s[4]) and unpowered(s[5])),
    "stop_no_full_power": (lambda s: s[1] != "LNone", lambda s: s[4] != "On" and s[5] != "On"),
    "termination_no_full_power": (lambda s: s[0] == "Termination", lambda s: s[4] != "On" and s[5] != "On"),
}


# ---------------------------------------------------------------------------
# Demand and frame laws (audit #4). The laws above say nothing bad happens; these say the
# sequencer does its job. Each is a STEP law and must hold on every cell of the domain, so
# any guard an invariant would give us is written into the hypothesis instead.
# ---------------------------------------------------------------------------

def lub(o, a, b):
    return a if RANK[o][a] >= RANK[o][b] else b


def succ_phase(p):
    i = PHASES.index(p)
    return PHASES[i + 1] if i + 1 < len(PHASES) else p


DEMAND_LAWS = {
    # D1 a stop request is honoured: the level becomes the least upper bound of the current
    # response and the requested one. Two-sided where P1 is one-sided.
    "D1_stop_honoured": (lambda o, s, e, bt, bh, s2: e[0] == "Stop",
                         lambda o, s, e, bt, bh, s2: s2[1] == lub(o, s[1], e[1])),
    # D2 an accepted soft stop takes a unit at full power into ramp-down (R-4, H16)
    "D2_soft_stop_ramps": (lambda o, s, e, bt, bh, s2: e[0] == "Stop" and e[1] in ("LJtt", "LRtps")
                           and RANK[o][e[1]] > RANK[o][s[1]] and "On" in (s[4], s[5]),
                           lambda o, s, e, bt, bh, s2: all(s2[i] == "Ramping" for i in (4, 5) if s[i] == "On")),
    # D3 the natural end of the programme also ramps down
    "D3_advance_to_termination_ramps": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[1] != "LPtn"
                                        and s[0] == "Heating2" and "On" in (s[4], s[5]),
                                        lambda o, s, e, bt, bh, s2: all(s2[i] == "Ramping" for i in (4, 5) if s[i] == "On")),
    # D4 the watchdog latches the PTN whatever the instance wires to the DMS
    "D4_watchdog_latches": (lambda o, s, e, bt, bh, s2: e[0] == "Tick" and not bh and s[1] != "LPtn",
                            lambda o, s, e, bt, bh, s2: s2[1] == "LPtn"),
    # D5 the heartbeat counter counts while the PTN is not latched (positive dual of I6)
    "D5_hb_counts": (lambda o, s, e, bt, bh, s2: e[0] == "Tick" and bh and s[1] != "LPtn",
                     lambda o, s, e, bt, bh, s2: upd_hb(s, e, bh) == "CInc"),
    # D6 only a heartbeat (or the accepted end of pulse) may reset the watchdog
    "D6_hb_frame": (lambda o, s, e, bt, bh, s2: upd_hb(s, e, bh) == "CReset",
                    lambda o, s, e, bt, bh, s2: e[0] == "Heartbeat" or (e[0] == "Reset" and reset_ok(s))),
    # D7 the acknowledgement timeout fires the DMS (guarded by level = PTN: with the DMS armed
    # and the PTN not latched -- a state I4 excludes -- the watchdog clause would run instead)
    "D7_ack_timeout_fires": (lambda o, s, e, bt, bh, s2: s[2] == "DmsArmed" and s[1] == "LPtn" and e[0] == "Tick" and not bt,
                             lambda o, s, e, bt, bh, s2: s2[2] == "DmsFired"),
    # D8 and it counts up while below the limit (positive dual of I5)
    "D8_ack_counts": (lambda o, s, e, bt, bh, s2: s[2] == "DmsArmed" and s[1] == "LPtn" and e[0] == "Tick" and bt,
                      lambda o, s, e, bt, bh, s2: upd_tack(s, e, bt, bh) == "CInc"),
    # D9 the acknowledgement from the heating plant fires the DMS
    "D9_heatack_fires": (lambda o, s, e, bt, bh, s2: s[2] == "DmsArmed" and e[0] == "HeatAck",
                         lambda o, s, e, bt, bh, s2: s2[2] == "DmsFired"),
    # D10 the end of pulse IS accepted when the pulse has ended and no mitigation is armed.
    # The guard is spelled out, not taken from the model's own reset_ok -- that self-reference
    # is why P20 cannot detect a wrong guard (audit #1 finding).
    "D10_reset_accepted_when_safe": (lambda o, s, e, bt, bh, s2: e[0] == "Reset"
                                     and (s[1] == "LPtn" or s[0] == "Termination") and s[2] != "DmsArmed",
                                     lambda o, s, e, bt, bh, s2: s2 == INIT and upd_hb(s, e, bh) == "CReset"
                                     and upd_tack(s, e, bt, bh) == "CReset"),
    # D11 the programme advances exactly one phase
    "D11_advance_is_one_step": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[1] != "LPtn" and s[0] != "Termination",
                                lambda o, s, e, bt, bh, s2: s2[0] == succ_phase(s[0])),
    # D12 nothing else moves the phase
    "D12_phase_frame": (lambda o, s, e, bt, bh, s2: s2[0] != s[0],
                        lambda o, s, e, bt, bh, s2: e[0] in ("Advance", "Reset") or (e[0] == "Stop" and e[1] == "LJtt")),
    # D13 the plasma conditions are an input, and only that input (or the end of pulse) moves them
    "D13_plasma_is_input": (lambda o, s, e, bt, bh, s2: e[0] == "Plasma",
                            lambda o, s, e, bt, bh, s2: s2[3] == e[1]),
    "D14_plasma_frame": (lambda o, s, e, bt, bh, s2: s2[3] != s[3],
                         lambda o, s, e, bt, bh, s2: e[0] == "Plasma" or (e[0] == "Reset" and reset_ok(s))),
    # D15 a heating command touches its own unit and nothing else (the mirror of P9)
    "D15_heatoff_is_local": (lambda o, s, e, bt, bh, s2: e[0] == "HeatOff",
                             lambda o, s, e, bt, bh, s2: _one_unit(s, s2, e[1], deenergize(_u(s, e[1])), bt, bh, e)),
    "D16_heaton_is_local": (lambda o, s, e, bt, bh, s2: e[0] == "HeatOn",
                            lambda o, s, e, bt, bh, s2: _frame_but_units(s, s2) and _u(s2, _other(e[1])) == _u(s, _other(e[1]))
                            and upd_hb(s, e, bh) == "CKeep" and upd_tack(s, e, bt, bh) == "CKeep"),
    # D17 an acknowledgement moves the DMS and nothing else
    "D17_heatack_frame": (lambda o, s, e, bt, bh, s2: e[0] == "HeatAck",
                          lambda o, s, e, bt, bh, s2: s2[0] == s[0] and s2[1] == s[1] and s2[3] == s[3]
                          and s2[4] == s[4] and s2[5] == s[5]
                          and upd_hb(s, e, bh) == "CKeep" and upd_tack(s, e, bt, bh) == "CKeep"),
    # D18 a heartbeat touches the counter and nothing else
    "D18_heartbeat_frame": (lambda o, s, e, bt, bh, s2: e[0] == "Heartbeat",
                            lambda o, s, e, bt, bh, s2: s2 == s and upd_tack(s, e, bt, bh) == "CKeep"),
}


def _u(s, w):
    return s[4] if w == "Nb" else s[5]


def _other(w):
    return "Rf" if w == "Nb" else "Nb"


def _frame_but_units(s, s2):
    return s2[0] == s[0] and s2[1] == s[1] and s2[2] == s[2] and s2[3] == s[3]


def _one_unit(s, s2, w, expected, bt, bh, e):
    """unit w becomes `expected`, everything else (including the counters) is unchanged"""
    return (_u(s2, w) == expected and _u(s2, _other(w)) == _u(s, _other(w)) and _frame_but_units(s, s2)
            and upd_hb(s, e, bh) == "CKeep" and upd_tack(s, e, bt, bh) == "CKeep")


LAWS.update(DEMAND_LAWS)
FRAME_LAWS |= {"D6_hb_frame", "D12_phase_frame", "D14_plasma_frame", "D15_heatoff_is_local",
               "D16_heaton_is_local", "D17_heatack_frame", "D18_heartbeat_frame"}



# ---------------------------------------------------------------------------
# Round 3 (audit #5): the demand laws above still left eight holes, and 11 of 25 new mutants
# survived them. These close the ones that are cell laws; the concrete layer (step_c) and the
# verdict domain are closed below, outside the cell property.
# ---------------------------------------------------------------------------

def adv_unit(s, u):
    """what an Advance does to one unit (E4): ramp into Termination, close a shut window."""
    nxt = succ_phase(s[0])
    if nxt == "Termination":
        return ramp(u)
    return u if heat_win(nxt) else deenergize(u)


EXTRA_LAWS = {
    # E1 only a local alarm creates an inhibit. Without it, losing the plasma could LATCH the
    # units instead of de-energizing them -- a permanent availability loss no operator action
    # clears -- and every law would still pass, because they all say only `unpowered(u')`.
    "E1_inhibit_source": (lambda o, s, e, bt, bh, s2: e[0] != "Local",
                          lambda o, s, e, bt, bh, s2: all(not (s[i] != "Inhibited" and s2[i] == "Inhibited") for i in (4, 5))),
    # E2 the DMS fires only on the plant acknowledgement or on the acknowledgement timeout
    "E2_dms_fire_frame": (lambda o, s, e, bt, bh, s2: s[2] == "DmsArmed" and s2[2] == "DmsFired",
                          lambda o, s, e, bt, bh, s2: e[0] == "HeatAck" or (e[0] == "Tick" and not bt)),
    # E3 a stop moves the phase to Termination exactly when an accepted JTT asks for it
    "E3_stop_phase_exact": (lambda o, s, e, bt, bh, s2: e[0] == "Stop",
                            lambda o, s, e, bt, bh, s2: s2[0] == ("Termination" if (e[1] == "LJtt" and RANK[o][e[1]] > RANK[o][s[1]]) else s[0])),
    # E4 the units after an Advance are fully determined (D3 covered only one of the six)
    "E4_advance_units": (lambda o, s, e, bt, bh, s2: e[0] == "Advance" and s[1] != "LPtn" and s[0] != "Termination",
                         lambda o, s, e, bt, bh, s2: s2[4] == adv_unit(s, s[4]) and s2[5] == adv_unit(s, s[5])),
    # E5 a heartbeat always restarts the watchdog counter. Nothing demanded this: D18 framed the
    # control and t_ack and forgot hb, and D6 only PERMITS a heartbeat to reset.
    "E5_heartbeat_resets_hb": (lambda o, s, e, bt, bh, s2: e[0] == "Heartbeat",
                               lambda o, s, e, bt, bh, s2: upd_hb(s, e, bh) == "CReset"),
    # E6 the watchdog counter on a Tick is exactly determined (two-sided D5): without the
    # verdict guard the counter runs past its limit and no law sees it, because the step that
    # would have exposed it latches the PTN and vacates every hypothesis.
    "E6_hb_tick_exact": (lambda o, s, e, bt, bh, s2: e[0] == "Tick",
                         lambda o, s, e, bt, bh, s2: upd_hb(s, e, bh) == ("CInc" if (bh and s[1] != "LPtn") else "CKeep")),
    # E7 only a Tick with the DMS armed and the wait below the limit may increment it
    "E7_tack_inc_frame": (lambda o, s, e, bt, bh, s2: upd_tack(s, e, bt, bh) == "CInc",
                          lambda o, s, e, bt, bh, s2: e[0] == "Tick" and s[2] == "DmsArmed" and bt),
    # E8 only a demand that actually arms, or the accepted end of pulse, restarts the wait
    # (the guard is spelled out, not taken from the model's own reset_ok -- same discipline as D10)
    "E8_tack_reset_frame": (lambda o, s, e, bt, bh, s2: upd_tack(s, e, bt, bh) == "CReset",
                            lambda o, s, e, bt, bh, s2: (e[0] == "Reset" and (s[1] == "LPtn" or s[0] == "Termination") and s[2] != "DmsArmed")
                            or (demands(e, bh, s[1]) and s[2] == "DmsIdle")),
    # E11 the acknowledgement is two-sided (replaces the one-sided D9)
    "E11_heatack_exact": (lambda o, s, e, bt, bh, s2: e[0] == "HeatAck",
                          lambda o, s, e, bt, bh, s2: s2[2] == ("DmsFired" if s[2] == "DmsArmed" else s[2])),
}

LAWS.update(EXTRA_LAWS)
FRAME_LAWS |= {"E1_inhibit_source", "E2_dms_fire_frame", "E7_tack_inc_frame", "E8_tack_reset_frame"}

# Laws that are DERIVED rather than independent evidence, and why. Reported by the gates so
# the write-up cannot present them as independent (audit #5 §5, §8).
DERIVED = {
    "D3_advance_to_termination_ramps": "subsumed by E4_advance_units (which covers all six advances)",
    "D5_hb_counts": "one half of E6_hb_tick_exact",
    "D9_heatack_fires": "one half of E11_heatack_exact",
    "D10_reset_accepted_when_safe": "pointwise implied by P20_reset_guarded; its job is to break P20's "
                                    "self-reference (P20 quotes the model's own reset_ok, D10 spells the guard out)",
    "D12_phase_frame": "its Stop clause is subsumed by E3_stop_phase_exact",
}


# ---------------------------------------------------------------------------
# Outside the cell property: the concrete layer and the verdict domain
# ---------------------------------------------------------------------------

# The alarm matrix, dms wiring and phase window, transcribed a FOURTH time as constants, so
# that the concrete-layer check stops being self-referential: `concretize_conforms` compared
# concretize against an expectation built from the same table() and dms_req(), so it detected a
# mis-wired column but NOT a wrong table value or a wrong window (audit #5 §4).
_TBL = {
    1: {"Slow": ["LPtn", "LPtn", "LPtn", "LPtn", "LRtps", "LRtps", "LPtn"],
        "Fast": ["LPtn"] * 7,
        "Mhd": ["LNone"] * 7,
        "MhdB": ["LNone"] * 7,
        "Mchs": ["LNone", "LNone", "LNone", "LNone", "LRtps", "LRtps", "LPtn"],
        "Dhs": ["LPtn", "LPtn", "LPtn", "LPtn", "LPtn", "LJtt", "LPtn"],
        "BothHs": ["LPtn", "LPtn", "LPtn", "LPtn", "LPtn", "LRtps", "LPtn"]},
}
_TBL[2] = dict(_TBL[1], Mhd=["LNone", "LNone", "LNone", "LPtn", "LPtn", "LPtn", "LPtn"])
_TBL[2]["MhdB"] = _TBL[2]["Mhd"]
_TRIG = {"Fast", "Mhd", "MhdB"}
_WIN = {"Xpoint", "Heating1", "Heating2", "Termination"}
_ORD_OF_INSTANCE = {1: 1, 2: 1}     # both certified instances run the chosen urgency order (A-1)


def concretize_conforms():
    """C1: `concretize` is the configuration, value by value (not just the right plumbing)."""
    bad = []
    for i in (1, 2):
        for p in PHASES:
            for c in CEVENTS:
                if c[0] == "XAlarm":
                    want = ("Stop", _TBL[i][c[1]][PHASES.index(p)], c[1] in _TRIG and p in _WIN)
                elif c[0] == "XCommFault":
                    want = ("CommFault", False)
                elif c[0] == "XTick":
                    want = ("Tick", False)
                else:
                    want = (c[0][1:],) + tuple(c[1:])
                if concretize(i, p, c) != want:
                    bad.append((i, p, c))
    return bad


def step_c_conforms():
    """C3: step_c is the abstract step, under the instance's declared order, on the phase the
    state is in BEFORE the transition, through that instance's configuration. Nothing else
    constrained step_c: reading instance 1's matrix from instance 2, or the next phase, or the
    other urgency order, were all invisible (audit #5 mutants N05/N06/N07)."""
    bad = []
    for i in (1, 2):
        for s in all_states():
            for hb in range(HB_MAX + 2):
                for tack in range(ACK_MAX + 2):
                    st = (s, hb, tack)
                    for c in CEVENTS:
                        want = step_st(_ORD_OF_INSTANCE[i], st, concretize(i, s[0], c))
                        if step_c(i, st, c) != want:
                            bad.append((i, st, c))
    return bad


def verdict_frame_holds():
    """V1: outside the Tick arm neither the step nor the counter commands read the verdicts.
    The certificate checks 19 of the 24 columns at (True, True) only; this turns that
    assumption (H13, a one-off mechanical check) into a checked property."""
    bad = []
    for o in (1, 2):
        for s in all_states():
            for e in EVENTS:
                if e[0] == "Tick":
                    continue
                for bt in (True, False):
                    for bh in (True, False):
                        if (step_fin(o, s, e, bt, bh) != step_fin(o, s, e, True, True)
                                or upd_hb(s, e, bh) != upd_hb(s, e, True)
                                or upd_tack(s, e, bt, bh) != upd_tack(s, e, True, True)):
                            bad.append((o, s, e, bt, bh))
    return bad


def check_cell(o, s, e, bt, bh, s2=None):
    """Which laws FAIL on this cell (s2 defaults to this model's step)."""
    s2 = step_fin(o, s, e, bt, bh) if s2 is None else s2
    return [n for n, (h, c) in LAWS.items() if h(o, s, e, bt, bh, s2) and not c(o, s, e, bt, bh, s2)]


def reachable_abstract(o):
    """Control states reachable from init over the abstract alphabet with free verdicts."""
    seen, todo = {INIT}, [INIT]
    while todo:
        s = todo.pop()
        for e in EVENTS:
            for bt, bh in verdicts_for(e):
                s2 = step_fin(o, s, e, bt, bh)
                if s2 not in seen:
                    seen.add(s2); todo.append(s2)
    return seen


def reachable_concrete(inst):
    """Full states (Fin, hb, tack) reachable through instance `inst` over the concrete alphabet."""
    st0 = (INIT, 0, 0)
    seen, todo, edges = {st0}, [st0], {}
    while todo:
        st = todo.pop()
        for c in CEVENTS:
            st2 = step_c(inst, st, c)
            edges.setdefault((st[0][0], c), set()).add(concretize(inst, st[0][0], c))
            if st2 not in seen:
                seen.add(st2); todo.append(st2)
    return seen, edges
