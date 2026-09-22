"""jetprot_prod.py - the "production" implementation of the JET protection-chain logic, in
plain Python, written from the natural-language specification (docs/phase3-sources.md,
docs/phase3-design.md §1) but NOT from jetprot.bend. It carries planted bugs (see BUGS) of the
kind that survive code review:

  deescalation              : a soft stop request replaces the current response without
                              comparing urgency (an RTPS stop can be lowered to JTT)  -> P1
  commfault_leaves_heating  : the communication-fault path latches PTN but does not switch
                              the heating off                                          -> P2
  rtps_keeps_full_power     : an RTPS stop does not take the units out of full power    -> P3
  plasma_ok_restores_reduced: recovering plasma conditions puts a reduced unit back to
                              full power                                                -> F2d
  watchdog_off_by_one       : the PTN fires when hb+1 > HB_MAX instead of >= HB_MAX     -> I6
  repeated_alarm_restarts_ack: a repeated stop request restarts the acknowledgement wait -> P18
  jtt_moves_program_phase   : an accepted JTT rewrites the program phase, so later alarms
                              read the Termination row of Table 1                       -> F1
  arms_below_threshold      : the DMS arms whatever the plasma current                   -> IP1

Differential testing (run.py) compares this implementation against the Bend golden model on
random concrete traces and evaluates the Bend invariants on the states it produces.

Revision 2026-09-21 (blocker 4): program phase + termination-waveform flag, partial power
(`Reduced`), the DMV current threshold (`ip`, input XIp), the blind stop alarm and the masks
of the two reliability checks per instance.
"""

HB_MAX = 3
ACK_MAX = 2
PHASES = ["Breakdown", "IpRise", "Limiter", "Xpoint", "Heating1", "Heating2", "Termination"]
RANK = {"None": 0, "JTT": 1, "RTPS": 2, "PTN": 3}
BUGS = {"deescalation": False, "commfault_leaves_heating": False, "rtps_keeps_full_power": False,
        "plasma_ok_restores_reduced": False, "watchdog_off_by_one": False, "repeated_alarm_restarts_ack": False,
        "jtt_moves_program_phase": False, "arms_below_threshold": False}

# Table 1 of Stephen et al. 2011 (a third, independent transcription) + the assumed cells + the blind row
_T1 = {
    "Slow": ["PTN", "PTN", "PTN", "PTN", "RTPS", "RTPS", "PTN"],
    "Fast": ["PTN"] * 7,
    "Mhd": ["None"] * 7,
    "MhdB": ["None"] * 7,
    "Mchs": ["None", "None", "None", "None", "RTPS", "RTPS", "PTN"],
    "Dhs": ["PTN", "PTN", "PTN", "PTN", "PTN", "JTT", "PTN"],
    "Blind": ["PTN"] * 7,
}
_T1["BothHs"] = [a if RANK[a] >= RANK[b] else b for a, b in zip(_T1["Mchs"], _T1["Dhs"])]
_T2 = dict(_T1, Mhd=["None", "None", "None", "PTN", "PTN", "PTN", "PTN"])
_T2["MhdB"] = _T2["Mhd"]
TABLES = {1: _T1, 2: _T2, 3: _T1}
# which reliability checks each instance enables: (communication fault, blind alarms)
MASKS = {1: (True, True), 2: (True, True), 3: (False, False)}
DMS_TRIGGERS = {"Fast", "Mhd", "MhdB"}
DMS_WINDOW = {"Xpoint", "Heating1", "Heating2", "Termination"}
HEAT_WINDOW = {"Heating1", "Heating2"}


def init():
    return {"prog": "Breakdown", "jtt": False, "level": "None", "dms": "Idle", "plasma": False, "ip": False,
            "nb": "Off", "rf": "Off", "hb": 0, "tack": 0}


def wave(s):
    """the waveform phase: Termination once the JTT switched to it, the program phase otherwise"""
    return "Termination" if s["jtt"] else s["prog"]


def deenergize(u):
    return "Off" if u in ("On", "Ramping", "Reduced") else u


def ramp(u):
    return "Ramping" if u in ("On", "Reduced") else u


def reduce(u):
    return "Reduced" if u == "On" else u


def to_ptn(s):
    return dict(s, level="PTN", nb=deenergize(s["nb"]), rf=deenergize(s["rf"]))


def arm(s):
    if not (s["ip"] or BUGS["arms_below_threshold"]):
        return s
    if s["dms"] == "Idle":
        return dict(s, dms="Armed", tack=0)
    if BUGS["repeated_alarm_restarts_ack"]:
        return dict(s, tack=0)
    return s


def soft_stop(s, req):
    s = dict(s, level=req)
    if not (BUGS["rtps_keeps_full_power"] and req == "RTPS"):
        s = dict(s, nb=ramp(s["nb"]), rf=ramp(s["rf"]))
    if req == "JTT":
        s = dict(s, jtt=True)
        if BUGS["jtt_moves_program_phase"]:
            s = dict(s, prog="Termination")
    return s


def stop(s, req, dms):
    if req == "PTN":
        s = to_ptn(s)
        return arm(s) if dms else s
    accept = (req != "None") if BUGS["deescalation"] else (RANK[req] > RANK[s["level"]])
    return soft_stop(s, req) if accept else s


def step(s, e, inst=1):
    k = e["$"]
    if k == "XAlarm":
        t = e["t"]
        if t == "Blind" and not MASKS[inst][1]:
            return s
        req = TABLES[inst][t][PHASES.index(s["prog"])]
        return stop(s, req, t in DMS_TRIGGERS and wave(s) in DMS_WINDOW)
    if k == "XLocal":
        u = e["u"].lower()
        return dict(s, **{u: reduce(s[u])})
    if k == "XHeatOn":
        u = e["u"].lower()
        if s[u] == "Off" and wave(s) in HEAT_WINDOW and s["plasma"] and s["level"] == "None":
            return dict(s, **{u: "On"})
        return s
    if k == "XHeatOff":
        u = e["u"].lower()
        return dict(s, **{u: deenergize(s[u])})
    if k == "XPlasma":
        if e["ok"]:
            s = dict(s, plasma=True)
            if BUGS["plasma_ok_restores_reduced"]:
                s = dict(s, nb="On" if s["nb"] == "Reduced" else s["nb"], rf="On" if s["rf"] == "Reduced" else s["rf"])
            return s
        return dict(s, plasma=False, nb=deenergize(s["nb"]), rf=deenergize(s["rf"]))
    if k == "XIp":
        return dict(s, ip=e["ok"])
    if k == "XAdvance":
        if s["level"] == "PTN" or s["prog"] == "Termination":
            return s
        nxt = PHASES[PHASES.index(s["prog"]) + 1]
        if nxt == "Termination":
            return dict(s, prog=nxt, nb=ramp(s["nb"]), rf=ramp(s["rf"]))
        if nxt not in HEAT_WINDOW:
            return dict(s, prog=nxt, nb=deenergize(s["nb"]), rf=deenergize(s["rf"]))
        return dict(s, prog=nxt)
    if k == "XCommFault":
        if not MASKS[inst][0]:
            return s
        return dict(s, level="PTN") if BUGS["commfault_leaves_heating"] else to_ptn(s)
    if k == "XHeartbeat":
        return dict(s, hb=0)
    if k == "XTick":
        bh = (s["hb"] + 1 <= HB_MAX) if BUGS["watchdog_off_by_one"] else (s["hb"] + 1 < HB_MAX)
        bt = s["tack"] + 1 < ACK_MAX
        if not bh and s["level"] != "PTN":
            return to_ptn(s)
        if bh and s["level"] != "PTN":
            s = dict(s, hb=s["hb"] + 1)
        if s["dms"] == "Armed":
            s = dict(s, tack=s["tack"] + 1) if bt else dict(s, dms="Fired")
        return s
    if k == "XHeatAck":
        return dict(s, dms="Fired") if s["dms"] == "Armed" else s
    if k == "XReset":
        if (s["level"] == "PTN" or wave(s) == "Termination") and s["dms"] != "Armed":
            return init()
        return s
    raise ValueError(k)


def run(trace, inst=1, s=None):
    s = init() if s is None else s
    out = []
    for e in trace:
        s = step(s, e, inst)
        out.append(s)
    return out


_LVL = {"None": "LNone", "JTT": "LJtt", "RTPS": "LRtps", "PTN": "LPtn"}
_LVL_BACK = {v: k for k, v in _LVL.items()}


def to_bend(s):
    """The same state in the flat shape the bridge uses (for `check`)."""
    return {"prog": s["prog"], "jtt": s["jtt"], "level": _LVL[s["level"]], "dms": "Dms" + s["dms"], "plasma": s["plasma"],
            "ip": s["ip"], "nb": s["nb"], "rf": s["rf"], "hb": s["hb"], "tack": s["tack"]}


def from_bend(st):
    return {"prog": st["prog"], "jtt": st["jtt"], "level": _LVL_BACK[st["level"]], "dms": st["dms"][3:], "plasma": st["plasma"],
            "ip": st["ip"], "nb": st["nb"], "rf": st["rf"], "hb": st["hb"], "tack": st["tack"]}
