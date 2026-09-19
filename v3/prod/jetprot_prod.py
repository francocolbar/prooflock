"""jetprot_prod.py - the "production" implementation of the JET protection-chain logic, in
plain Python, written from the natural-language specification (docs/fase3-fuente.md,
docs/fase3-diseno.md §1) but NOT from jetprot.bend. It carries planted bugs (see BUGS) of the
kind that survive code review:

  deescalation              : a soft stop request replaces the current response without
                              comparing urgency (an RTPS stop can be lowered to JTT)  -> P1
  commfault_leaves_heating  : the communication-fault path latches PTN but does not switch
                              the heating off                                          -> P2
  rtps_keeps_full_power     : an RTPS stop does not take the units out of full power    -> P3
  plasma_ok_clears_inhibit  : recovering plasma conditions releases a local inhibit     -> P8
  watchdog_off_by_one       : the PTN fires when hb+1 > HB_MAX instead of >= HB_MAX     -> I6
  repeated_alarm_restarts_ack: a repeated stop request restarts the acknowledgement wait -> P18

Differential testing (run.py) compares this implementation against the Bend golden model on
random concrete traces and evaluates the Bend invariants on the states it produces.
"""

HB_MAX = 3
ACK_MAX = 2
PHASES = ["Breakdown", "IpRise", "Limiter", "Xpoint", "Heating1", "Heating2", "Termination"]
RANK = {"None": 0, "JTT": 1, "RTPS": 2, "PTN": 3}
BUGS = {"deescalation": False, "commfault_leaves_heating": False, "rtps_keeps_full_power": False,
        "plasma_ok_clears_inhibit": False, "watchdog_off_by_one": False, "repeated_alarm_restarts_ack": False}

# Table 1 of Stephen et al. 2011 (a third, independent transcription) + the assumed cells
_T1 = {
    "Slow": ["PTN", "PTN", "PTN", "PTN", "RTPS", "RTPS", "PTN"],
    "Fast": ["PTN"] * 7,
    "Mhd": ["None"] * 7,
    "MhdB": ["None"] * 7,
    "Mchs": ["None", "None", "None", "None", "RTPS", "RTPS", "PTN"],
    "Dhs": ["PTN", "PTN", "PTN", "PTN", "PTN", "JTT", "PTN"],
}
_T1["BothHs"] = [a if RANK[a] >= RANK[b] else b for a, b in zip(_T1["Mchs"], _T1["Dhs"])]
_T2 = dict(_T1, Mhd=["None", "None", "None", "PTN", "PTN", "PTN", "PTN"])
_T2["MhdB"] = _T2["Mhd"]
TABLES = {1: _T1, 2: _T2}
DMS_TRIGGERS = {"Fast", "Mhd", "MhdB"}
DMS_WINDOW = {"Xpoint", "Heating1", "Heating2", "Termination"}
HEAT_WINDOW = {"Heating1", "Heating2"}


def init():
    return {"phase": "Breakdown", "level": "None", "dms": "Idle", "plasma": False,
            "nb": "Off", "rf": "Off", "hb": 0, "tack": 0}


def deenergize(u):
    return "Off" if u in ("On", "Ramping") else u


def ramp(u):
    return "Ramping" if u == "On" else u


def to_ptn(s):
    return dict(s, level="PTN", nb=deenergize(s["nb"]), rf=deenergize(s["rf"]))


def arm(s):
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
        s = dict(s, phase="Termination")
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
        req = TABLES[inst][e["t"]][PHASES.index(s["phase"])]
        return stop(s, req, e["t"] in DMS_TRIGGERS and s["phase"] in DMS_WINDOW)
    if k == "XLocal":
        return dict(s, **{e["u"].lower(): "Inhibited"})
    if k == "XHeatOn":
        u = e["u"].lower()
        if s[u] == "Off" and s["phase"] in HEAT_WINDOW and s["plasma"] and s["level"] == "None":
            return dict(s, **{u: "On"})
        return s
    if k == "XHeatOff":
        u = e["u"].lower()
        return dict(s, **{u: deenergize(s[u])})
    if k == "XPlasma":
        if e["ok"]:
            s = dict(s, plasma=True)
            if BUGS["plasma_ok_clears_inhibit"]:
                s = dict(s, nb="Off" if s["nb"] == "Inhibited" else s["nb"], rf="Off" if s["rf"] == "Inhibited" else s["rf"])
            return s
        return dict(s, plasma=False, nb=deenergize(s["nb"]), rf=deenergize(s["rf"]))
    if k == "XAdvance":
        if s["level"] == "PTN" or s["phase"] == "Termination":
            return s
        nxt = PHASES[PHASES.index(s["phase"]) + 1]
        if nxt == "Termination":
            return dict(s, phase=nxt, nb=ramp(s["nb"]), rf=ramp(s["rf"]))
        if nxt not in HEAT_WINDOW:
            return dict(s, phase=nxt, nb=deenergize(s["nb"]), rf=deenergize(s["rf"]))
        return dict(s, phase=nxt)
    if k == "XCommFault":
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
        if (s["level"] == "PTN" or s["phase"] == "Termination") and s["dms"] != "Armed":
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
    return {"phase": s["phase"], "level": _LVL[s["level"]], "dms": "Dms" + s["dms"], "plasma": s["plasma"],
            "nb": s["nb"], "rf": s["rf"], "hb": s["hb"], "tack": s["tack"]}


def from_bend(st):
    return {"phase": st["phase"], "level": _LVL_BACK[st["level"]], "dms": st["dms"][3:], "plasma": st["plasma"],
            "nb": st["nb"], "rf": st["rf"], "hb": st["hb"], "tack": st["tack"]}
