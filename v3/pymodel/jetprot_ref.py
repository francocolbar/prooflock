"""jetprot_ref.py - a Python re-execution of the model of docs/phase3-design.md §1 (rules 1-12,
counter commands, the model invariant), written from the design document. This module is the
MODEL only: the laws, the state corollaries and the conformance checks live in jetprot_laws.py
and read spec_consts.py; this file must never import spec_consts (blocker 2). Used by recheck.py for:
  C5  the certificate re-check: every cell of the Bend model (through bridge.mjs) is compared
      with this model, and every law is re-evaluated here on the Bend-produced next state;
  C2  vacuity / coverage: reachability, hypothesis counts, conclusion falsifiability;
  C6  the mutation score: MUT flags and mutants.py plant defects and the laws must catch them.

Revision 2026-09-21 (blocker 4 of docs/STATUS_2026-09-21.md): the control state gained the
program/waveform split of F1 (`prog` indexes Table 1, `jtt` says the termination waveform is
running), the partial-power unit state `Reduced` of F2 (and lost `Inhibited`, which no pulse event
produces once a local alarm reduces instead of latching: the pre-pulse disabling of R-10 is
configuration, A-26), the DMV current threshold `ip` (R-14, formerly A-22) and the configuration
masks of F3 (carried by the CommFault event, `en`).

State: a tuple (prog, jtt, level, dms, plasma, ip, nb, rf); indices P, J, L, D, PL, IP, NB, RF.
Abstract events: tuples
  ("Advance",) ("Stop", req, dms) ("Local", u) ("HeatOn", u) ("HeatOff", u) ("Plasma", ok)
  ("Ip", ok) ("CommFault", dms, en) ("Heartbeat",) ("Tick", dms) ("HeatAck",) ("Reset",)
Concrete events: ("XAlarm", t) ("XCommFault",) ("XTick",) ("XIp", ok) and the rest as above with X.
"""
from itertools import product

PHASES = ["Breakdown", "IpRise", "Limiter", "Xpoint", "Heating1", "Heating2", "Termination"]
LEVELS = ["LNone", "LJtt", "LRtps", "LPtn"]
DMSS = ["DmsIdle", "DmsArmed", "DmsFired"]
HEATS = ["Off", "Ramping", "Reduced", "On"]
WHO = ["Nb", "Rf"]
TRIGS = ["Slow", "Fast", "Mhd", "MhdB", "Mchs", "Dhs", "BothHs", "Blind"]
HB_MAX, ACK_MAX = 3, 2
RANK = {1: {"LNone": 0, "LJtt": 1, "LRtps": 2, "LPtn": 3}, 2: {"LNone": 0, "LJtt": 2, "LRtps": 1, "LPtn": 3}}
P, J, L, D, PL, IP, NB, RF = range(8)
INIT = ("Breakdown", False, "LNone", "DmsIdle", False, False, "Off", "Off")
# the masks of the three configuration instances: (comm check enabled, blind alarms enabled)
MASKS = {1: (True, True), 2: (True, True), 3: (False, False)}

MUT = {k: False for k in ["deescalation", "jtt_no_ramp", "commfault_no_deenergize", "dms_on_soft", "rearm_restarts_ack",
                          "rtps_no_ramp", "deenergize_keeps_reduced", "advance_under_ptn", "reset_while_armed",
                          "heaton_under_rtps", "plasma_false_keeps_heat", "watchdog_off_by_one", "local_touches_level",
                          "dms_never_armed", "commfault_arms_dms", "jtt_stays_in_phase", "rearm_from_fired"]}

EVENTS = [("Advance",), ("Heartbeat",), ("HeatAck",), ("Reset",)]
EVENTS += [(k, u) for u in WHO for k in ("Local", "HeatOn", "HeatOff")]
EVENTS += [("Plasma", b) for b in (True, False)] + [("Ip", b) for b in (True, False)]
EVENTS += [("CommFault", d, en) for d in (True, False) for en in (True, False)] + [("Tick", b) for b in (True, False)]
EVENTS += [("Stop", r, b) for r in LEVELS for b in (True, False)]
CEVENTS = [("XAdvance",), ("XHeartbeat",), ("XHeatAck",), ("XReset",), ("XCommFault",), ("XTick",)]
CEVENTS += [(k, u) for u in WHO for k in ("XLocal", "XHeatOn", "XHeatOff")]
CEVENTS += [("XPlasma", b) for b in (True, False)] + [("XIp", b) for b in (True, False)]
CEVENTS += [("XAlarm", t) for t in TRIGS]


def all_states():
    return [s for s in product(PHASES, (False, True), LEVELS, DMSS, (True, False), (True, False), HEATS, HEATS)]


# The certificate enumerates all four verdict pairs for the columns where the checker cannot
# discharge the verdicts symbolically (reset_if / arms_now stay stuck on a symbolic Fin): both
# Ticks, Reset, CommFault{True, True} and Stop{LPtn, True}. 23 x 1 + 5 x 4 = 43 columns.
WIDE = {("Reset",), ("CommFault", True, True), ("Stop", "LPtn", True)}


def verdicts_for(e):
    wide = e[0] == "Tick" or e in WIDE
    return [(bt, bh) for bt in (True, False) for bh in (True, False)] if wide else [(True, True)]


# --- helpers ---
def wave(s):
    """the waveform phase: Termination once an accepted JTT switched to it, the program phase otherwise"""
    return "Termination" if s[J] else s[P]


def heat_win(p):
    return p in ("Heating1", "Heating2")


def succ_phase(p):
    i = PHASES.index(p)
    return PHASES[i + 1] if i + 1 < len(PHASES) else p


def deenergize(u):
    if MUT["deenergize_keeps_reduced"] and u == "Reduced":
        return "Reduced"
    return "Off" if u in ("On", "Ramping", "Reduced") else u


def ramp(u):
    return "Ramping" if u in ("On", "Reduced") else u


def reduce(u):
    return "Reduced" if u == "On" else u


def to_ptn(s):
    p, j, l, d, pl, ip, nb, rf = s
    if MUT["commfault_no_deenergize"]:
        return (p, j, "LPtn", d, pl, ip, nb, rf)
    return (p, j, "LPtn", d, pl, ip, deenergize(nb), deenergize(rf))


def arm(s):
    """arm the DMS from Idle, only while the plasma current is above the DMV threshold (R-14)"""
    p, j, l, d, pl, ip, nb, rf = s
    if MUT["dms_never_armed"] or not ip:
        return s
    if d == "DmsIdle" or (MUT["rearm_from_fired"] and d == "DmsFired"):
        return (p, j, l, "DmsArmed", pl, ip, nb, rf)
    return s


def soft(s, req):
    p, j, l, d, pl, ip, nb, rf = s
    skip = (MUT["jtt_no_ramp"] and req == "LJtt") or (MUT["rtps_no_ramp"] and req == "LRtps")
    nb2, rf2 = (nb, rf) if skip else (ramp(nb), ramp(rf))
    j2 = j or (req == "LJtt" and not MUT["jtt_stays_in_phase"])
    return (p, j2, req, d, pl, ip, nb2, rf2)


def reset_ok(s):
    p, j, l, d, pl, ip, nb, rf = s
    return (l == "LPtn" or wave(s) == "Termination") and (d != "DmsArmed" or MUT["reset_while_armed"])


def step_fin(o, s, e, bt, bh):
    p, j, l, d, pl, ip, nb, rf = s
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
        s2 = (p, j, l, d, pl, ip, reduce(nb), rf) if e[1] == "Nb" else (p, j, l, d, pl, ip, nb, reduce(rf))
        if MUT["local_touches_level"] and l == "LNone":
            s2 = (s2[0], s2[1], "LJtt", *s2[3:])
        return s2
    if k == "HeatOn":
        ok = heat_win(wave(s)) and pl and (l == "LNone" or (MUT["heaton_under_rtps"] and l == "LRtps"))
        u = nb if e[1] == "Nb" else rf
        if ok and u == "Off":
            return (p, j, l, d, pl, ip, "On", rf) if e[1] == "Nb" else (p, j, l, d, pl, ip, nb, "On")
        return s
    if k == "HeatOff":
        return (p, j, l, d, pl, ip, deenergize(nb), rf) if e[1] == "Nb" else (p, j, l, d, pl, ip, nb, deenergize(rf))
    if k == "Plasma":
        if e[1] or MUT["plasma_false_keeps_heat"]:
            return (p, j, l, d, e[1], ip, nb, rf)
        return (p, j, l, d, False, ip, deenergize(nb), deenergize(rf))
    if k == "Ip":
        return (p, j, l, d, pl, e[1], nb, rf)
    if k == "Advance":
        if (l == "LPtn" and not MUT["advance_under_ptn"]) or p == "Termination":
            return s
        nxt = PHASES[PHASES.index(p) + 1]
        if nxt == "Termination":
            return (nxt, j, l, d, pl, ip, ramp(nb), ramp(rf))
        if not heat_win(nxt):
            return (nxt, j, l, d, pl, ip, deenergize(nb), deenergize(rf))
        return (nxt, j, l, d, pl, ip, nb, rf)
    if k == "CommFault":
        dm, en = e[1], e[2]
        if not en:
            return s
        s2 = to_ptn(s)
        return arm(s2) if (dm or MUT["commfault_arms_dms"]) else s2
    if k == "Heartbeat":
        return s
    if k == "Tick":
        if (not bh) and l != "LPtn":
            s2 = to_ptn(s)
            return arm(s2) if e[1] else s2
        if d == "DmsArmed" and not bt:
            return (p, j, l, "DmsFired", pl, ip, nb, rf)
        return s
    if k == "HeatAck":
        return (p, j, l, "DmsFired", pl, ip, nb, rf) if d == "DmsArmed" else s
    if k == "Reset":
        return INIT if reset_ok(s) else s
    raise ValueError(e)


def arms_now(dm, s):
    return dm and s[IP] and s[D] == "DmsIdle"


def upd_hb(s, e, bh):
    k = e[0]
    if k == "Tick":
        return "CInc" if (bh and s[L] != "LPtn") else "CKeep"
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
        return "CReset" if (e[2] and arms_now(e[1], s)) else "CKeep"
    if k == "Tick":
        if (not bh) and s[L] != "LPtn":
            return "CReset" if arms_now(e[1], s) else "CKeep"
        return "CInc" if (s[D] == "DmsArmed" and bt) else "CKeep"
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
    if t == "Blind":
        return "LPtn"          # a blind stop alarm (loss of a critical signal) is a PTN stop in every phase (A-25)
    if t == "MhdB":
        return table_pub(p, "Mhd")
    if t == "BothHs":
        return lvl_max(1, table_pub(p, "Mchs"), table_pub(p, "Dhs"))
    return table_pub(p, t)


def table(inst, p, t):
    if inst == 2 and t in ("Mhd", "MhdB") and PHASES.index(p) >= 3:
        return "LPtn"
    return table1(p, t)


def mask(inst):
    return MASKS[inst]


def masked_table(inst, p, t):
    """the table row a concrete alarm reads, with the blind-alarm check masked out when the instance disables it"""
    if t == "Blind" and not mask(inst)[1]:
        return "LNone"
    return table(inst, p, t)


def dms_req(p, t):
    return t in ("Fast", "Mhd", "MhdB") and PHASES.index(p) >= 3


def concretize(inst, s, c):
    """the abstract event of a concrete one, through the instance: Table 1 is indexed by the PROGRAM
    phase (A-24), the DMS window by the waveform phase, the checks by the instance's masks"""
    k = c[0]
    if k == "XAlarm":
        return ("Stop", masked_table(inst, s[P], c[1]), dms_req(wave(s), c[1]))
    if k == "XCommFault":
        return ("CommFault", False, mask(inst)[0])
    if k == "XTick":
        return ("Tick", False)
    return (k[1:],) + tuple(c[1:])


def step_c(inst, st, c):
    return step_st(1, st, concretize(inst, st[0], c))


# --- the model's own invariants (the oracle has its own copy in jetprot_laws.py) ---
def inv_fin(s):
    p, j, l, d, pl, ip, nb, rf = s
    w = wave(s)
    for u in (nb, rf):
        if u in ("On", "Reduced") and not (heat_win(w) and pl and l == "LNone"):
            return False
        if u == "Ramping" and not (pl and l != "LPtn" and (l != "LNone" or w == "Termination")):
            return False
    if l == "LJtt" and w != "Termination":
        return False
    if d != "DmsIdle" and l != "LPtn":
        return False
    return True


def inv_all(st):
    s, hb, tack = st
    return inv_fin(s) and (s[D] != "DmsArmed" or tack < ACK_MAX) and (s[L] == "LPtn" or hb < HB_MAX)


# The law set, the state corollaries and the conformance checks live in jetprot_laws.py
# (the oracle); this module is the MODEL only and reads none of spec_consts.py.


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


def reachable_concrete(inst, cap=32):
    """Full states (Fin, hb, tack) reachable through instance `inst` over the concrete alphabet.
    A state whose hb or tack exceeds `cap` is recorded but not expanded: a mutant whose counter
    never stops (M32: t_ack counts while the DMS is idle) would otherwise make this sweep
    infinite; the model itself never passes HB_MAX / ACK_MAX, so the cap is inert on it."""
    st0 = (INIT, 0, 0)
    seen, todo, edges = {st0}, [st0], {}
    while todo:
        st = todo.pop()
        if st[1] > cap or st[2] > cap:
            continue
        for c in CEVENTS:
            st2 = step_c(inst, st, c)
            edges.setdefault((st[0][P], c), set()).add(concretize(inst, st[0], c))
            if st2 not in seen:
                seen.add(st2); todo.append(st2)
    return seen, edges
