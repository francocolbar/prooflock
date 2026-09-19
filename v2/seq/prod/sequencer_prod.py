"""sequencer_prod.py - the "production" implementation of the discharge sequencer, in
plain Python, written from the same natural-language spec as seq.bend but NOT from
it. It carries planted bugs (see BUGS) of the kind that survive code review:

  watchdog_off_by_one : the watchdog fires when hb+1 > HB_MAX instead of >= HB_MAX,
                        so a watched phase can reach hb == HB_MAX (violates L6).
  rampdown_not_plasma : the sensor interlock does not treat RampDown as a plasma
                        phase, so losing vacuum or field during ramp-down does not
                        shut down (violates L1).

Differential testing (run.py) compares this implementation against the Bend golden
model on random traces and evaluates the Bend invariants on the states it produces.
"""

T_MAX = 4
HB_MAX = 3
PHASES = ["Idle", "Charged", "Prefill", "Breakdown", "FlatTop", "RampDown", "Shutdown"]
BUGS = {"watchdog_off_by_one": True, "rampdown_not_plasma": True}


def init():
    return {"phase": "Idle", "vac": False, "tf": False, "dens": False,
            "gas": False, "cs": False, "heat": False, "t_flat": 0, "hb": 0}


def is_plasma(phase):
    plasma = ["Prefill", "Breakdown", "FlatTop"]
    if not BUGS["rampdown_not_plasma"]:
        plasma.append("RampDown")
    return phase in plasma


def is_watched(phase):
    return phase not in ("Idle", "Shutdown")


def shutdown(s):
    return dict(s, phase="Shutdown", gas=False, cs=False, heat=False)


def interlock(s):
    if is_plasma(s["phase"]) and not (s["vac"] and s["tf"]):
        return shutdown(s)
    if not s["dens"]:
        s = dict(s, heat=False)
    return s


def tick(s):
    if is_watched(s["phase"]):
        limit_hit = (s["hb"] + 1 > HB_MAX) if BUGS["watchdog_off_by_one"] else (s["hb"] + 1 >= HB_MAX)
        if limit_hit:
            return shutdown(s)
        s = dict(s, hb=s["hb"] + 1)
    if s["phase"] == "FlatTop":
        if s["t_flat"] + 1 < T_MAX:
            s = dict(s, t_flat=s["t_flat"] + 1)
        else:
            s = dict(s, phase="RampDown", heat=False)
    return s


def step(s, e):
    k = e["$"]
    if k == "Tick":
        return tick(s)
    if k == "Heartbeat":
        return dict(s, hb=0)
    if k == "Vac":
        return interlock(dict(s, vac=e["ok"]))
    if k == "Tf":
        return interlock(dict(s, tf=e["ok"]))
    if k == "Dens":
        return interlock(dict(s, dens=e["ok"]))
    if k == "CmdCharge":
        return dict(s, phase="Charged", hb=0) if s["phase"] == "Idle" and s["vac"] else s
    if k == "CmdPuff":
        return dict(s, phase="Prefill", gas=True) if s["phase"] == "Charged" and s["vac"] and s["tf"] else s
    if k == "CmdBreakdown":
        return dict(s, phase="Breakdown", gas=False, cs=True) if s["phase"] == "Prefill" and s["vac"] and s["tf"] else s
    if k == "CmdFlatTop":
        return dict(s, phase="FlatTop", t_flat=0) if s["phase"] == "Breakdown" else s
    if k == "CmdHeatOn":
        return dict(s, heat=True) if s["phase"] == "FlatTop" and s["dens"] else s
    if k == "CmdHeatOff":
        return dict(s, heat=False)
    if k == "CmdRampDown":
        return dict(s, phase="RampDown", heat=False) if s["phase"] in ("FlatTop", "Breakdown") else s
    if k in ("Disruption", "Abort"):
        return shutdown(s)
    if k == "Reset":
        return dict(s, phase="Idle", gas=False, cs=False, heat=False, t_flat=0, hb=0) if s["phase"] in ("RampDown", "Shutdown") else s
    raise ValueError(k)


def run(trace, s=None):
    s = init() if s is None else s
    out = []
    for e in trace:
        s = step(s, e)
        out.append(s)
    return out


def to_bend(s):
    """The same state in the shape the Bend model uses (for the bridge's `check`)."""
    return {"$": "St", "phase": {"$": s["phase"]}, "vac": s["vac"], "tf": s["tf"], "dens": s["dens"],
            "gas": s["gas"], "cs": s["cs"], "heat": s["heat"], "t_flat": s["t_flat"], "hb": s["hb"]}


def from_bend(st):
    return {"phase": st["phase"]["$"], "vac": st["vac"], "tf": st["tf"], "dens": st["dens"],
            "gas": st["gas"], "cs": st["cs"], "heat": st["heat"], "t_flat": st["t_flat"], "hb": st["hb"]}
