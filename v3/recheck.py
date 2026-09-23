"""recheck.py - the method gates that are decided OUTSIDE the Bend checker (docs/phase3-design.md §5):

  C5  re-check of the certificate by re-execution in another language (not an independent
      implementation: docs/phase3-design.md §9a H23): every cell of the Bend model (bridge.mjs)
      is compared with the Python reference model (pymodel/jetprot_ref.py, a port of the Bend
      model) and the 62 cell checks of pymodel/jetprot_laws.py (LAWS) are re-evaluated in Python
      on the Bend-produced next state; the concrete layer (concretize) is compared on every
      (instance, phase, event); the concrete reachable set (Fin, hb, tack) is enumerated and
      checked against inv_all.
  C2  vacuity / coverage: per law, the number of certificate cells and of reachable cells where
      the hypothesis holds (zero = vacuous, below threshold = warning); whether the conclusion is
      falsifiable somewhere in the domain; the cells constrained by no non-frame law; identity
      events; the matrix cells exercised per instance; how the DMS is reached; (phase, level) pairs.
  C3  the behavioural difference between the two urgency orders (cells and reachable cells).
  C6  the mutation score: planted defects in the reference model vs the law set. The laws, the
      invariants and the conformance checks live in pymodel/jetprot_laws.py and read the
      specification constants (pymodel/spec_consts.py), never the model ones, so a mutated
      constant cannot drag the oracle along (that is how HB_MAX = 4 survived before). A mutant
      that survives is accepted only if it is EQUIVALENT, and that is computed: its step_fin,
      upd_hb and upd_tack are compared with the model's on all 924 672 certificate cells, its
      counter layer (verdicts, apply, step_st) on 12 042 240 concrete cells and its concretize
      on 1 032 192 (instance, control state, plant event) cells (C6.equivalence); a single
      differing cell fails the gate.

Usage: py -3.14 v3/recheck.py [--full] [--jobs N]   Writes: recheck.json. Exit 0 iff all gates pass.
       --full also runs every mutant against the WHOLE law set (no early exit) to report how
       many laws catch each one (laws_per_kill); serially the census went from about 540 s to
       5 884 s (runs of 2026-09-22 and 2026-09-23, on different days: the ratio is indicative).
       --jobs N runs C5, C2, C3 and the C6 census in a pool of N processes (default cpu_count - 4);
       --jobs 1 is the serial path. The results are the same, in the same order, either way.
"""
import json
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "pymodel"))
sys.path.insert(0, HERE)
import jetprot_ref as R  # noqa: E402
import spec_consts as C  # noqa: E402
import jetprot_laws as L  # noqa: E402
from bridge_client import Bridge  # noqa: E402

THRESHOLD = 20          # reachable cells below which a law is flagged as nearly vacuous
TIGHTNESS_SAMPLE = 400  # reachable cells sampled for the tightness metric
TIGHTNESS_SEED = 7      # fixed, so the published number is reproducible
CMDS = ("CKeep", "CReset", "CInc")


def catching_laws(early=True):
    """The names of the obligations that FAIL on the current (possibly mutated) model.
    Empty means the model passes the whole law set -- which is what a surviving mutant means."""
    caught = set()

    def hit(n):
        caught.add(n)
        return early

    if R.INIT != C.INIT and hit("S0_init_is_spec"):
        return sorted(caught)
    if not L.inv_all((C.INIT, 0, 0)) and hit("I0_inv_init"):
        return sorted(caught)
    if L.concretize_conforms() and hit("C1_concretize_is_the_configuration"):
        return sorted(caught)
    if L.inst4_second_alarm_ptn() and hit("inst4_second_alarm_ptn"):
        return sorted(caught)
    for o in (1, 2):
        for s in R.all_states():
            for e in R.EVENTS:
                for bt, bh in R.verdicts_for(e):
                    for n in L.check_cell(o, s, e, bt, bh):
                        if hit(n):
                            return sorted(caught)
    for s in R.all_states():
        if L.inv_fin(s):
            for n, (h, c) in L.CORS.items():
                if h(s) and not c(s) and hit("cor_" + n):
                    return sorted(caught)
    # the preservation laws and the trace theorem, over the concrete reachable set
    for inst in C.INSTANCES:
        states, _ = R.reachable_concrete(inst)
        for st in states:
            if not L.inv_all(st) and hit("traces_safe_concrete"):
                return sorted(caught)
    for s in R.all_states():
        for hb in range(C.HB_MAX + 2):
            for tack in range(C.ACK_MAX + 2):
                st = (s, hb, tack)
                if not L.inv_all(st):
                    continue
                for o in (1, 2):
                    for e in R.EVENTS:
                        if not L.inv_all(R.step_st(o, st, e)) and hit("pres_fin/pres_i5/pres_i6"):
                            return sorted(caught)
    # the two whole-domain conformance checks come after the cell laws (V1 0.5 s, C3 4.5 s on
    # this machine): a mutant a cell law catches is reported by that law and never pays for them
    if L.verdict_frame_holds() and hit("V1_verdict_frame"):
        return sorted(caught)
    if L.step_c_conforms() and hit("C3_step_c_is_the_concrete_step"):
        return sorted(caught)
    # last: the model invariant must be the spec invariant (a mutant of the invariant itself is
    # caught here and nowhere else: M72); placed last so that a mutant a LAW catches is reported
    # by that law, not by this comparison
    if L.inv_all_disagrees() and hit("S1_inv_all_is_spec"):
        return sorted(caught)
    return sorted(caught)




def ev_from_json(e):
    k = e["$"]
    if k == "Stop":
        return ("Stop", e["req"], e["dms"])
    if k in ("Local", "HeatOn", "HeatOff"):
        return (k, e["u"])
    if k in ("Plasma", "Ip"):
        return (k, e["ok"])
    if k == "CommFault":
        return ("CommFault", e["dms"], e["en"])
    if k == "Tick":
        return ("Tick", e["dms"])
    return (k,)


def cev_to_json(c):
    k = c[0]
    if k == "XAlarm":
        return {"$": k, "t": c[1]}
    if k in ("XLocal", "XHeatOn", "XHeatOff"):
        return {"$": k, "u": c[1]}
    if k in ("XPlasma", "XIp"):
        return {"$": k, "ok": c[1]}
    return {"$": k}


def fin_from_json(f):
    return (f["prog"], f["jtt"], f["level"], f["dms"], f["plasma"], f["ip"], f["nb"], f["rf"])


def fin_to_json(s):
    return {"prog": s[0], "jtt": s[1], "level": s[2], "dms": s[3], "plasma": s[4], "ip": s[5], "nb": s[6], "rf": s[7]}


def c5(bridge, results):
    """Bend cells == Python cells, laws re-evaluated in Python on Bend's next state."""
    t0 = time.perf_counter()
    mism, lawfail, cells = 0, 0, 0
    for o in (1, 2):
        for ph in R.PHASES:
            rows = bridge.ask({"cells": {"ord": o, "phase": ph}})["rows"]
            for r in rows:
                s, e, bt, bh = fin_from_json(r["f"]), ev_from_json(r["e"]), r["bt"], r["bh"]
                s2b = fin_from_json(r["f2"])
                cells += 1
                if s2b != R.step_fin(o, s, e, bt, bh) or r["hb"] != R.upd_hb(s, e, bh) or r["tack"] != R.upd_tack(s, e, bt, bh) \
                        or r["inv"] != R.inv_fin(s) or r["inv2"] != R.inv_fin(s2b):
                    mism += 1
                    if mism <= 5:
                        print(f"[C5] MISMATCH o={o} s={s} e={e} bt={bt} bh={bh}: bend={s2b} py={R.step_fin(o, s, e, bt, bh)}")
                fails = L.check_cell(o, s, e, bt, bh, s2b)
                if fails:
                    lawfail += 1
                    if lawfail <= 5:
                        print(f"[C5] LAW FAILS on Bend cell o={o} s={s} e={e}: {fails}")
    # the concrete layer: the fields concretize reads (program phase, waveform flag, level in force:
    # which table an alarm reads, revision 4) x the plant events
    cmism = 0
    for inst in C.INSTANCES:
        for ph in R.PHASES:
            for j in (False, True):
                for lv in R.LEVELS:
                    s = (ph, j, lv, "DmsIdle", True, True, "Off", "Off")
                    for c in R.CEVENTS:
                        ev = ev_from_json(bridge.ask({"concretize": {"inst": inst, "fin": fin_to_json(s), "cev": cev_to_json(c)}})["ev"])
                        if ev != R.concretize(inst, s, c):
                            cmism += 1
    # concrete reachability (the Python model, now known to agree with Bend cell by cell)
    reach = {}
    for inst in C.INSTANCES:
        states, edges = R.reachable_concrete(inst)
        reach[inst] = {"states": len(states), "max_hb": max(x[1] for x in states), "max_tack": max(x[2] for x in states),
                       "all_inv_all": all(L.inv_all(x) for x in states),
                       "phase_level_pairs": sorted({(x[0][R.P], x[0][R.L]) for x in states}),
                       "dms_reached": sorted({x[0][R.D] for x in states}),
                       "alarm_cells_exercised": sorted({(ph, c[1], tuple(sorted(evs))) for (ph, c), evs in edges.items() if c[0] == "XAlarm"}),
                       "dms_armed_by": sorted({c[1] for (ph, c), evs in edges.items() if c[0] == "XAlarm" and any(e[0] == "Stop" and e[1] == "LPtn" and e[2] for e in evs)})}
    ok = mism == 0 and lawfail == 0 and cmism == 0 and all(v["all_inv_all"] for v in reach.values())
    results["C5"] = {"cells_compared": cells, "mismatches": mism, "law_failures_on_bend_cells": lawfail,
                     "concretize_mismatches": cmism, "concrete_reachability": reach, "seconds": round(time.perf_counter() - t0, 1), "ok": ok}
    print(f"[C5] {cells} Bend cells vs Python: {mism} mismatches, {lawfail} law failures; concretize mismatches {cmism}; "
          f"concrete reachable inst1={reach[1]['states']} (hb<={reach[1]['max_hb']}, tack<={reach[1]['max_tack']}), "
          f"inst2={reach[2]['states']}, inst3={reach[3]['states']}, inst4={reach[4]['states']}; all satisfy inv_all: {all(v['all_inv_all'] for v in reach.values())}  [{results['C5']['seconds']} s] -> {'ok' if ok else 'FAIL'}")
    return ok


def c2(results):
    """Vacuity and coverage on the Python model (validated by C5)."""
    t0 = time.perf_counter()
    reach = {o: R.reachable_abstract(o) for o in (1, 2)}
    per = {}
    for name, (h, c) in L.LAWS.items():
        cells = reach_cells = 0
        for o in (1,):
            for s in R.all_states():
                for e in R.EVENTS:
                    for bt, bh in R.verdicts_for(e):
                        s2 = R.step_fin(o, s, e, bt, bh)
                        if h(o, s, e, bt, bh, s2):
                            cells += 1
                            if s in reach[o]:
                                reach_cells += 1

        per[name] = {"cert_cells": cells, "reachable_cells": reach_cells,
                     "vacuous": cells == 0 or reach_cells == 0, "below_threshold": reach_cells < THRESHOLD}
    # corollaries: states under inv_fin with the antecedent true
    cor = {}
    for name, (h, c) in L.CORS.items():
        n = sum(1 for s in R.all_states() if L.inv_fin(s) and h(s))
        nr = sum(1 for s in reach[1] if L.inv_fin(s) and h(s))
        cor[name] = {"states": n, "reachable_states": nr, "vacuous": n == 0 or nr == 0}
    # How tightly the laws pin the model: on a reachable cell, how many of the 10 752 control states
    # does the law set admit as the next one? This replaces "cells constrained by no non-frame
    # law", which was identically zero by construction (P1/P14/P15 have hypothesis `e != Reset`,
    # so every cell was trivially "covered"). A law set that admits many successors proves little,
    # however many laws it has: before the demand laws this number was 15 successors on average.
    rng = random.Random(TIGHTNESS_SEED)
    # sorted: `reach[1]` is a set of tuples of str, whose iteration order changes with Python's
    # per-process hash seed, so the seeded sample was not reproducible across runs before
    cells = [(s, e, bt, bh) for s in sorted(reach[1]) for e in R.EVENTS for bt, bh in R.verdicts_for(e)]
    sample = rng.sample(cells, min(TIGHTNESS_SAMPLE, len(cells)))
    pinned, admissible = 0, 0
    cmd_pinned, cmd_admissible = 0, 0
    REAL_HB, REAL_TACK = R.upd_hb, R.upd_tack
    # A law earns its place only if some candidate successor exists that it REFUTES. Evaluating the
    # conclusion on the model's own successor cannot show this: an exact two-sided law is true there
    # by construction. So the refutation test rides along with the tightness sweep.
    refutes = {n: False for n in L.LAWS}
    for s, e, bt, bh in sample:
        adm = 0
        for cand in R.all_states():
            ok_all = True
            for n, (h, c) in L.LAWS.items():
                if h(1, s, e, bt, bh, cand) and not c(1, s, e, bt, bh, cand):
                    refutes[n] = True
                    ok_all = False
            adm += ok_all
        admissible += adm
        pinned += (adm == 1)
        # second sweep, over the counter commands: the control-state candidates above cannot
        # refute a law about upd_hb / upd_tack, so those laws would look idle without this.
        s2 = R.step_fin(1, s, e, bt, bh)
        real_hb, real_tack = R.upd_hb(s, e, bh), R.upd_tack(s, e, bt, bh)
        adm_cmd = 0
        for hb_cmd in CMDS:
            for tack_cmd in CMDS:
                R.upd_hb, R.upd_tack = (lambda *_a, _v=hb_cmd: _v), (lambda *_a, _v=tack_cmd: _v)
                try:
                    ok_all = True
                    for n, (h, c) in L.LAWS.items():
                        if h(1, s, e, bt, bh, s2) and not c(1, s, e, bt, bh, s2):
                            refutes[n] = True
                            ok_all = False
                    adm_cmd += ok_all
                finally:
                    R.upd_hb, R.upd_tack = REAL_HB, REAL_TACK
        cmd_pinned += (adm_cmd == 1)
        cmd_admissible += adm_cmd
    never_refutes = sorted(n for n, v in refutes.items() if not v)
    tight = {"sample": len(sample), "pinned": pinned, "pinned_fraction": round(pinned / len(sample), 3),
             "mean_admissible_successors": round(admissible / len(sample), 2), "of_states": len(R.all_states()),
             "counter_commands_pinned": cmd_pinned, "counter_commands_pinned_fraction": round(cmd_pinned / len(sample), 3),
             "mean_admissible_command_pairs": round(cmd_admissible / len(sample), 2), "of_command_pairs": len(CMDS) ** 2}
    identity = [e for e in R.EVENTS if all(R.step_fin(1, s, e, bt, bh) == s for s in reach[1] for bt, bh in R.verdicts_for(e))]
    ok = not any(v["vacuous"] for v in per.values()) and not any(v["vacuous"] for v in cor.values())
    warn = [n for n, v in per.items() if v["below_threshold"]]
    results["C2"] = {"reachable_abstract_states": {o: len(r) for o, r in reach.items()}, "laws": per, "corollaries": cor,
                     "tightness": tight,
                     "identity_events_on_reachable": [list(e) for e in identity], "warnings_below_threshold": warn,
                     "laws_that_refute_nothing_in_the_sample": never_refutes,
                     "seconds": round(time.perf_counter() - t0, 1), "ok": ok}
    print(f"[C2] reachable abstract states: {len(reach[1])}; laws vacuous: {[n for n, v in per.items() if v['vacuous']]}; "
          f"below threshold ({THRESHOLD}): {warn}; refute nothing in the sample: {never_refutes}; "
          f"tightness: {tight['pinned']}/{tight['sample']} reachable cells pin the successor "
          f"({100*tight['pinned_fraction']:.0f}%), mean {tight['mean_admissible_successors']} admissible of {tight['of_states']}; "
          f"counter commands pinned on {tight['counter_commands_pinned']}/{tight['sample']} (mean {tight['mean_admissible_command_pairs']} of 9); "
          f"identity events: {identity}  [{results['C2']['seconds']} s] -> {'ok' if ok else 'FAIL'}")
    for n, v in per.items():
        print(f"      {n:26} cert cells {v['cert_cells']:7}  reachable cells {v['reachable_cells']:6}")
    return ok


def c3(results):
    """The behavioural difference between the two urgency orders."""
    reach = R.reachable_abstract(1)
    diff, diff_reach = [], []
    for s in R.all_states():
        for e in R.EVENTS:
            for bt, bh in R.verdicts_for(e):
                a, b = R.step_fin(1, s, e, bt, bh), R.step_fin(2, s, e, bt, bh)
                if a != b:
                    diff.append((s, e))
                    if s in reach:
                        diff_reach.append({"state": s, "event": e, "ord1": a, "ord2": b})
    results["C3"] = {"cells_differing": len(diff), "reachable_cells_differing": len(diff_reach), "reachable_examples": diff_reach[:10]}
    print(f"[C3] step differs between the two orders on {len(diff)} cells, {len(diff_reach)} of them reachable")
    for d in diff_reach[:6]:
        print(f"      {d['state']} + {d['event']}: Ord1 -> {d['ord1']}  |  Ord2 -> {d['ord2']}")
    return True


def c6(results, full=False, jobs=1):
    """Mutation score against the ADVERSARIAL bank of 76 defects: 62 written by two separate
    automated reviews (README §7) whose brief was to break the law set, 11 defects of the constants
    and of the oracle itself (M63-M73, blocker 2) and 3 of the secondary stop response (W01-W03,
    revision 4); plus the 17 flags that were written alongside the laws. The flag number is
    the weaker measure and is reported as such. Every public symbol of the model is restored after
    each mutant, so a patch may replace constants as well as functions.
    jobs > 1 runs the census in a process pool (c6_tasks / c6_assemble); jobs == 1 is the serial loop."""
    if jobs > 1:
        t0 = time.perf_counter()
        parts = {}
        run_pool(c6_tasks(full), jobs, lambda tag, res: c6_progress(parts, tag, res))
        return c6_assemble(results, parts, full, t0)
    import mutants
    t0 = time.perf_counter()
    ORIG = {k: getattr(R, k) for k in dir(R) if not k.startswith("_")}
    bank, equivalence = {}, {}
    for entry in mutants.MUTANTS:
        name, rec, eq = run_mutant(entry, full, ORIG)
        bank[name] = rec
        if eq is not None:
            equivalence[name] = eq
    flags = {}
    for m in R.MUT:
        try:
            R.MUT[m] = True
            flags[m] = catching_laws()
        finally:
            R.MUT[m] = False
    return c6_summary(results, bank, flags, full, t0, equivalence=equivalence)


def run_mutant(entry, full, ORIG):
    """One mutant of the bank, the same code in the serial loop and in a pool worker: patch the
    model, run the law set, restore every public symbol. A SURVIVOR (no law catches it) is then
    compared with the unmutated model cell by cell (step_relation_diff); a caught mutant needs no
    comparison, and its third value is None."""
    name, plaus, desc, patch = entry
    over = patch()
    try:
        for k, v in over.items():
            assert k in ORIG, (name, k)
            setattr(R, k, v)
        rec = {"plausibility": plaus, "description": desc, "caught_by": catching_laws()}
        if full:
            rec["caught_by_all"] = catching_laws(early=False)
    finally:
        vars(R).update(ORIG)
    eq = None if rec["caught_by"] else step_relation_diff(over, ORIG)
    return name, rec, eq


def step_relation_diff(over, ORIG):
    """How many cells of the certificate domain -- both urgency orders x the 10 752 control states x
    the 43 certificate columns (every event, with the four verdict pairs exactly where the
    certificate takes them: verdicts_for), 924 672 cells -- give a different step_fin, upd_hb or
    upd_tack once the patch `over` is applied. 0 means the mutant's transition relation IS the
    model's, so no law can tell them apart: an equivalent mutant, now computed rather than accepted
    by name. The domain is the unmutated model's (ORIG); the patch is applied per control state and
    the model restored before the reference values are computed, so memory stays flat.
    The counter layer (verdicts, apply, step_st) is compared on 12 042 240 concrete cells: both
    orders x 10 752 states x hb 0..HB_MAX+1 x tack 0..ACK_MAX+1 x the 28 events, where the
    verdicts come from the counters, not from verdicts_for (C3 cannot pin this layer: it checks
    step_c against the model's own step_st, which moves with the mutant). concretize is compared on
    every instance x control state x plant event, 1 032 192 cells (C1 checks it on 112 control
    states per instance only, and C3 against the mutant's own concretize); S0 pins INIT, S1 the
    invariant, C3 step_c = step_st o concretize."""
    states, events, verdicts_for = ORIG["all_states"](), ORIG["EVENTS"], ORIG["verdicts_for"]
    cols = [(e, bt, bh) for e in events for bt, bh in verdicts_for(e)]
    cells = differing = 0
    try:
        for o in (1, 2):
            for s in states:
                for k, v in over.items():
                    setattr(R, k, v)
                try:
                    mut = [(R.step_fin(o, s, e, bt, bh), R.upd_hb(s, e, bh), R.upd_tack(s, e, bt, bh)) for e, bt, bh in cols]
                finally:
                    vars(R).update(ORIG)
                ref = [(R.step_fin(o, s, e, bt, bh), R.upd_hb(s, e, bh), R.upd_tack(s, e, bt, bh)) for e, bt, bh in cols]
                cells += len(cols)
                differing += sum(1 for a, b in zip(mut, ref) if a != b)
    finally:
        vars(R).update(ORIG)
    counters = [(hb, tack) for hb in range(ORIG["HB_MAX"] + 2) for tack in range(ORIG["ACK_MAX"] + 2)]
    ccells = cdiff = 0
    try:
        for o in (1, 2):
            for s in states:
                for k, v in over.items():
                    setattr(R, k, v)
                try:
                    mut = [R.step_st(o, (s, hb, tack), e) for hb, tack in counters for e in events]
                finally:
                    vars(R).update(ORIG)
                ref = [R.step_st(o, (s, hb, tack), e) for hb, tack in counters for e in events]
                ccells += len(ref)
                cdiff += sum(1 for a, b in zip(mut, ref) if a != b)
    finally:
        vars(R).update(ORIG)
    kcells = kdiff = 0
    try:
        for s in states:
            for k, v in over.items():
                setattr(R, k, v)
            try:
                mut = [R.concretize(i, s, c) for i in C.INSTANCES for c in ORIG["CEVENTS"]]
            finally:
                vars(R).update(ORIG)
            ref = [R.concretize(i, s, c) for i in C.INSTANCES for c in ORIG["CEVENTS"]]
            kcells += len(ref)
            kdiff += sum(1 for a, b in zip(mut, ref) if a != b)
    finally:
        vars(R).update(ORIG)
    return {"cells": cells, "differing": differing, "concrete_cells": ccells, "concrete_differing": cdiff,
            "concretize_cells": kcells, "concretize_differing": kdiff}


def c6_summary(results, bank, flags, full, t0, t_end=None, equivalence=None):
    """The C6 verdict and its record, from the bank (in mutants.MUTANTS order), the flags (in R.MUT
    order) and the cell comparison of every survivor with the model (equivalence, by name)."""
    survivors = [n for n, v in bank.items() if not v["caught_by"]]
    flag_survivors = [n for n, v in flags.items() if not v]
    # A survivor is accepted only as an EQUIVALENT mutant, and that is computed, not assumed from its
    # name: its step_fin, upd_hb and upd_tack must equal the model's on every one of the 924 672
    # certificate cells, its step_st on every one of the 12 042 240 concrete cells and its
    # concretize on every one of the 1 032 192 (instance, control state, plant event) cells
    # (step_relation_diff). A survivor that differs on even one cell fails C6.
    equivalence = {n: (equivalence or {}).get(n) for n in survivors}
    missing = [n for n, v in equivalence.items() if v is None]
    if missing:
        raise RuntimeError(f"C6: no cell comparison for the survivors {missing}")
    equivalent = [n for n in survivors
                  if all(equivalence[n][k] == 0 for k in ("differing", "concrete_differing", "concretize_differing"))]
    ok = set(survivors) <= set(equivalent) and not flag_survivors
    batches = {"M01-M37 (review 1)": [n for n in bank if n[:3] <= "M37"], "N01-N25 (review 2)": [n for n in bank if n.startswith("N")],
               "M63-M73 (constants and oracle)": [n for n in bank if n.startswith("M6") or n.startswith("M7")],
               "W01-W03 (revision 4, secondary)": [n for n in bank if n.startswith("W")]}
    by_batch = {b: {"killed": sum(1 for n in ns if bank[n]["caught_by"]), "total": len(ns)} for b, ns in batches.items()}
    results["C6"] = {"bank": bank, "killed": len(bank) - len(survivors), "total": len(bank),
                     "by_batch": by_batch, "survivors": survivors, "known_equivalent": equivalent,
                     "equivalence": equivalence,
                     "flags_killed": len(flags) - len(flag_survivors), "flags_total": len(flags),
                     "flag_survivors": flag_survivors, "seconds": round((t_end or time.perf_counter()) - t0, 1), "ok": ok}
    if full:
        per = {n: len(v["caught_by_all"]) for n, v in bank.items() if v["caught_by_all"]}
        hist = {}
        for k in per.values():
            hist[k] = hist.get(k, 0) + 1
        results["C6"]["laws_per_kill"] = {"per_mutant": per, "histogram": dict(sorted(hist.items())),
                                          "killed_by_a_single_law": sorted(n for n, k in per.items() if k == 1)}
    batch_txt = "; ".join(f"{b}: {v['killed']}/{v['total']}" for b, v in by_batch.items())
    eq_txt = ", ".join(f"{n} differs from the model on {v['differing']} of {v['cells']} cells,"
                       f" {v['concrete_differing']} of {v['concrete_cells']} concrete cells"
                       f" and {v['concretize_differing']} of {v['concretize_cells']} concretize cells"
                       for n, v in equivalence.items())
    print(f"[C6] adversarial bank: {len(bank) - len(survivors)}/{len(bank)} killed ({batch_txt})"
          f"{'; survivors ' + str(survivors) + ' (' + eq_txt + '; equivalent: ' + str(equivalent) + ')' if survivors else ''}; "
          f"model flags: {len(flags) - len(flag_survivors)}/{len(flags)} -> {'ok' if ok else 'FAIL'}")
    return ok


# ---------------------------------------------------------------------------------------------
# Parallel execution (--jobs N > 1). Tasks go to a spawn-safe process pool as (function, args)
# with picklable arguments only: a mutant or a flag is named by its INDEX (mutants.MUTANTS holds
# closures). Each worker imports the modules once and keeps its own ORIG snapshot, taken exactly
# as the serial loop takes it (after `import mutants`, before any patch), and restores it after
# every mutant. The parent assembles every result in the canonical serial order; any worker
# exception stops the pool and propagates, so a mutant can never be silently dropped.
# ---------------------------------------------------------------------------------------------
_WORKER = {}


def default_jobs():
    return max(1, (os.cpu_count() or 1) - 4)


def _census_state():
    if "ORIG" not in _WORKER:
        import mutants
        _WORKER["mutants"] = mutants
        _WORKER["ORIG"] = {k: getattr(R, k) for k in dir(R) if not k.startswith("_")}
    return _WORKER["mutants"], _WORKER["ORIG"]


def mutant_task(i, full):
    """Worker: mutant number i of mutants.MUTANTS, exactly one iteration of the serial loop
    (run_mutant): (name, record, cell comparison if it survives else None)."""
    mutants, ORIG = _census_state()
    return run_mutant(mutants.MUTANTS[i], full, ORIG)


def flag_task(j):
    """Worker: model flag number j of R.MUT, exactly one iteration of the serial flag loop."""
    _census_state()
    m = list(R.MUT)[j]
    try:
        R.MUT[m] = True
        caught = catching_laws()
    finally:
        R.MUT[m] = False
    return m, caught


def check_task(which):
    """Worker: C5, C2 or C3 on its own, with its printed report captured and handed back."""
    import contextlib
    import io
    buf, sub = io.StringIO(), {}
    with contextlib.redirect_stdout(buf):
        if which == "C5":
            bridge = Bridge()
            ok = c5(bridge, sub)
            bridge.close()
        elif which == "C2":
            ok = c2(sub)
        else:
            ok = c3(sub)
    return which, sub[which], ok, buf.getvalue()


def mutant_tasks(full):
    """The 76 mutants as pool tasks (the long ones: submit them first)."""
    import mutants
    return [(mutant_task, (i, full), ("mut", i)) for i in range(len(mutants.MUTANTS))]


def flag_tasks():
    """The 17 model flags as pool tasks."""
    return [(flag_task, (j,), ("flag", j)) for j in range(len(R.MUT))]


def c6_tasks(full):
    return mutant_tasks(full) + flag_tasks()


def c6_progress(parts, tag, res):
    """Store one census result and print progress ([C6] k/76)."""
    import mutants
    kind, i = tag
    if kind == "mut":
        name, rec, eq = res
        assert name == mutants.MUTANTS[i][0], (i, name)
        parts[tag] = res
        k, n = sum(1 for t in parts if t[0] == "mut"), len(mutants.MUTANTS)
        say(f"[C6] {k}/{n} {name} -> {'caught by ' + str(len(rec['caught_by'])) + ' law(s)' if rec['caught_by'] else 'SURVIVES'}"
            + (f", {len(rec['caught_by_all'])} of the whole set" if "caught_by_all" in rec else "")
            + (f"; differs from the model on {eq['differing']} of {eq['cells']} cells, {eq['concrete_differing']}"
               f" of {eq['concrete_cells']} concrete cells and {eq['concretize_differing']} of"
               f" {eq['concretize_cells']} concretize cells" if eq is not None else ""))
    else:
        m, caught = res
        assert m == list(R.MUT)[i], (i, m)
        parts[tag] = res
        k, n = sum(1 for t in parts if t[0] == "flag"), len(R.MUT)
        say(f"[C6] flag {k}/{n} {m} -> {'caught' if caught else 'SURVIVES'}")


def c6_assemble(results, parts, full, t0, t_end=None):
    """The bank in mutants.MUTANTS order and the flags in R.MUT order, then the serial summary."""
    import mutants
    n, nf = len(mutants.MUTANTS), len(R.MUT)
    missing = [i for i in range(n) if ("mut", i) not in parts] + [f"flag{j}" for j in range(nf) if ("flag", j) not in parts]
    if missing:
        raise RuntimeError(f"C6 census incomplete, missing {missing}")
    bank, equivalence = {}, {}
    for i in range(n):
        name, rec, eq = parts[("mut", i)]
        bank[name] = rec
        if eq is not None:
            equivalence[name] = eq
    flags = {}
    for j in range(nf):
        m, caught = parts[("flag", j)]
        flags[m] = caught
    if len(bank) != n or len(flags) != nf:
        raise RuntimeError("C6 census: duplicate mutant or flag names")
    return c6_summary(results, bank, flags, full, t0, t_end, equivalence=equivalence)


_SAY_LOCK = []


def say(msg):
    """print() from several threads without interleaving: one locked write per line."""
    if not _SAY_LOCK:
        import threading
        _SAY_LOCK.append(threading.Lock())
    with _SAY_LOCK[0]:
        sys.stdout.write(msg if msg.endswith("\n") else msg + "\n")
        sys.stdout.flush()


def low_priority():
    """Pool initializer: run this worker (and the node bridges it starts, which inherit the class)
    below normal priority, so the Bend checks running beside the pool get the CPU first. Only the
    scheduling changes, never a result; if the OS refuses, the worker just runs at normal priority."""
    try:
        if os.name == "nt":
            import ctypes
            from ctypes import wintypes
            k32 = ctypes.WinDLL("kernel32", use_last_error=True)
            # declared types: an undeclared restype truncates the pseudo-handle (-1) on 64-bit Windows
            k32.GetCurrentProcess.restype = wintypes.HANDLE
            k32.SetPriorityClass.argtypes = (wintypes.HANDLE, wintypes.DWORD)
            k32.SetPriorityClass.restype = wintypes.BOOL
            k32.SetPriorityClass(k32.GetCurrentProcess(), 0x4000)   # BELOW_NORMAL_PRIORITY_CLASS
        else:
            os.nice(5)
    except Exception:
        pass


def run_pool(tasks, jobs, on_result, low_prio=False):
    """Run (function, args, tag) tasks in a spawn process pool of min(jobs, len(tasks)) workers,
    submitted in list order (put the long ones first). on_result(tag, result) runs in the calling
    thread as each task completes. A worker exception, or a worker that dies, kills the pool and
    is re-raised: the gate fails loudly rather than lose a result. low_prio: every worker runs
    below normal priority (run.py sets it when the Bend checks run beside the pool)."""
    import multiprocessing
    from concurrent.futures import ProcessPoolExecutor, as_completed
    if not tasks:
        return
    pool = ProcessPoolExecutor(max_workers=min(jobs, len(tasks)), mp_context=multiprocessing.get_context("spawn"),
                               initializer=low_priority if low_prio else None)
    try:
        futs = {pool.submit(fn, *args): tag for fn, args, tag in tasks}
        for fut in as_completed(futs):
            tag = futs[fut]
            try:
                res = fut.result()
            except BaseException as e:
                say(f"[FAIL] worker task {tag} raised {e.__class__.__name__}: {e}")
                raise
            on_result(tag, res)
    except BaseException:
        for p in list((getattr(pool, "_processes", None) or {}).values()):
            try:
                p.terminate()
            except Exception:
                pass
        pool.shutdown(wait=False, cancel_futures=True)
        raise
    pool.shutdown(wait=True)


def main(full=False, jobs=1):
    results = {}
    if jobs > 1:
        # C5, C2, C3 and the census in one pool; the results keep the serial key order
        t0 = time.perf_counter()
        parts, checks = {}, {}

        def on_result(tag, res):
            if tag[0] == "chk":
                which, rec, ok_, text = res
                checks[which] = (rec, ok_)
                say(text)
            else:
                c6_progress(parts, tag, res)
        run_pool(mutant_tasks(full) + [(check_task, (w,), ("chk", w)) for w in ("C2", "C5", "C3")] + flag_tasks(),
                 jobs, on_result)
        ok = True
        for w in ("C5", "C2", "C3"):
            results[w] = checks[w][0]
            if w != "C3":
                ok &= checks[w][1]
        ok &= c6_assemble(results, parts, full, t0)
    else:
        bridge = Bridge()
        ok = c5(bridge, results)
        bridge.close()
        ok &= c2(results)
        c3(results)
        ok &= c6(results, full=full)
    results["all_ok"] = bool(ok)
    with open(os.path.join(HERE, "recheck.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=1, default=str)
    print(f"[done] recheck ok: {ok}")
    return ok


if __name__ == "__main__":
    import argparse
    _ap = argparse.ArgumentParser(prog="recheck.py")
    _ap.add_argument("--full", action="store_true")
    _ap.add_argument("--jobs", type=int, default=default_jobs(), help="worker processes (default: cpu_count - 4; 1 = the serial path)")
    _a = _ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(line_buffering=True)
    sys.exit(0 if main(full=_a.full, jobs=max(1, _a.jobs)) else 1)
