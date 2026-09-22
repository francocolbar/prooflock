"""spec_consts.py - what the SPECIFICATION fixes, transcribed from the requirements layer
(v3/docs/fase3-fuente.md, R-n / A-n) and NOT from the model.

Imported by the oracle only: jetprot_laws.py (the law set, the invariants, the C1/C3/V1
conformance checks) and recheck.py. NEVER imported by jetprot_ref.py: the model keeps its own
copies of these values, so a mutant that changes a model constant (HB_MAX = 4, a wrong initial
state, a wider heating window, a tie in the urgency order) is judged against THESE values and
no longer drags the oracle along with it (docs/STATUS_2026-09-21.md, blocker 2; the old bank
let five such mutants survive because the laws read the model constants).

Every value here is duplicated on purpose. If the model and this file disagree, the mutation
gate fails; that is the point.

Revision for blocker 4 (2026-09-21): the state has eight fields (program phase, termination
waveform flag, level, DMS, plasma, DMV current threshold, two units), the units have a
partial-power value `Reduced` (R-9) and no `Inhibited` value (A-26), the triggers include the blind stop alarm (R-13, A-25), and
each instance carries a mask for the two reliability checks (R-13, A-21).
"""

# R-1: the pulse programme, in order (the PROGRAM phase, the one Level-1 times and Table 1 reads: A-24)
PHASES = ["Breakdown", "IpRise", "Limiter", "Xpoint", "Heating1", "Heating2", "Termination"]
# A-1: the response levels; RANK gives the urgency order of each certified instance
# (Ord1: JTT below RTPS, Ord2: RTPS below JTT; PTN is always the top, None the bottom)
LEVELS = ["LNone", "LJtt", "LRtps", "LPtn"]
RANK = {1: {"LNone": 0, "LJtt": 1, "LRtps": 2, "LPtn": 3},
        2: {"LNone": 0, "LJtt": 2, "LRtps": 1, "LPtn": 3}}
# R-11..R-13: the mitigation sequence and the heating units (R-9: a unit may deliver partial power)
DMSS = ["DmsIdle", "DmsArmed", "DmsFired"]
HEATS = ["Off", "Ramping", "Reduced", "On"]
WHO = ["Nb", "Rf"]
# R-2: the seven stop triggers, plus the blind stop alarm of R-13 (A-25)
TRIGS = ["Slow", "Fast", "Mhd", "MhdB", "Mchs", "Dhs", "BothHs", "Blind"]

# the state tuple: (prog, jtt, level, dms, plasma, ip, nb, rf)
P, J, L, D, PL, IP, NB, RF = range(8)

# A-11, A-13: the watchdog and acknowledgement limits (in ticks)
HB_MAX, ACK_MAX = 3, 2

# R-5: the initial state (Breakdown, no termination waveform, no response, DMS idle, no plasma,
# current below the DMV threshold, both units off)
INIT = ("Breakdown", False, "LNone", "DmsIdle", False, False, "Off", "Off")

# A-6: the phases in which a heating unit may be energized (read on the waveform phase, A-24)
HEAT_WIN = {"Heating1", "Heating2"}

# R-13 / [S6]: the triggers wired to the DMS and the phase window in which they arm it
DMS_TRIG = {"Fast", "Mhd", "MhdB"}
DMS_WINDOW = {"Xpoint", "Heating1", "Heating2", "Termination"}

# Table 1 of [S1] per instance, one row per trigger, one column per phase (in PHASES order).
# Instance 2 differs from instance 1 only in the MHD rows (A-10: the override starts at Xpoint).
# Instance 3 is instance 1 with both reliability checks masked out (A-21). The Blind row is A-25.
TABLE = {
    1: {"Slow":   ["LPtn", "LPtn", "LPtn", "LPtn", "LRtps", "LRtps", "LPtn"],
        "Fast":   ["LPtn"] * 7,
        "Mhd":    ["LNone"] * 7,
        "MhdB":   ["LNone"] * 7,
        "Mchs":   ["LNone", "LNone", "LNone", "LNone", "LRtps", "LRtps", "LPtn"],
        "Dhs":    ["LPtn", "LPtn", "LPtn", "LPtn", "LPtn", "LJtt", "LPtn"],
        "BothHs": ["LPtn", "LPtn", "LPtn", "LPtn", "LPtn", "LRtps", "LPtn"],
        "Blind":  ["LPtn"] * 7},
}
TABLE[2] = dict(TABLE[1], Mhd=["LNone", "LNone", "LNone", "LPtn", "LPtn", "LPtn", "LPtn"])
TABLE[2]["MhdB"] = TABLE[2]["Mhd"]
TABLE[3] = dict(TABLE[1])

# R-13 / A-21: which reliability checks each instance enables: (communication fault, blind alarms)
MASKS = {1: (True, True), 2: (True, True), 3: (False, False)}

# A-1: every certified instance runs the chosen urgency order
ORD_OF_INSTANCE = {1: 1, 2: 1, 3: 1}

# the wiring of the two synthetic stops (dms_on_commfault / dms_on_watchdog): neither arms the DMS
DMS_ON_COMMFAULT = False
DMS_ON_WATCHDOG = False
