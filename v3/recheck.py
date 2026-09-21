"""recheck.py - the method gates that are decided OUTSIDE the Bend checker (docs/fase3-diseno.md §5):

  C5  independent re-check of the certificate: every cell of the Bend model (bridge.mjs) is
      compared with the Python reference model (pymodel/jetprot_ref.py, written from the design
      document) and every law is re-evaluated in Python on the Bend-produced next state; the
      concrete layer (concretize) is compared on every (instance, phase, event); the concrete
      reachable set (Fin, hb, tack) is enumerated and checked against inv_all.
  C2  vacuity / coverage: per law, the number of certificate cells and of reachable cells where
      the hypothesis holds (zero = vacuous, below threshold = warning); whether the conclusion is
      falsifiable somewhere in the domain; the cells constrained by no non-frame law; identity
      events; the matrix cells exercised per instance; how the DMS is reached; (phase, level) pairs.
  C3  the behavioural difference between the two urgency orders (cells and reachable cells).
  C6  the mutation score: planted defects in the reference model vs the law set. The laws, the
      invariants and the conformance checks live in pymodel/jetprot_laws.py and read the
      specification constants (pymodel/spec_consts.py), never the model ones, so a mutated
      constant cannot drag the oracle along (that is how HB_MAX = 4 survived before).

Usage: py -3.14 bend-spike/v3/recheck.py [--full]   Writes: recheck.json. Exit 0 iff all gates pass.
       --full also runs every mutant against the WHOLE law set (no early exit) to report how
       many laws catch each one (laws_per_kill); about 8x slower.
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
    for inst in (1, 2):
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
    if k == "Plasma":
        return ("Plasma", e["ok"])
    if k in ("CommFault", "Tick"):
        return (k, e["dms"])
    return (k,)


def cev_to_json(c):
    k = c[0]
    if k == "XAlarm":
        return {"$": k, "t": c[1]}
    if k in ("XLocal", "XHeatOn", "XHeatOff"):
        return {"$": k, "u": c[1]}
    if k == "XPlasma":
        return {"$": k, "ok": c[1]}
    return {"$": k}


def fin_from_json(f):
    return (f["phase"], f["level"], f["dms"], f["plasma"], f["nb"], f["rf"])


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
    # the concrete layer
    cmism = 0
    for inst in (1, 2):
        for ph in R.PHASES:
            for c in R.CEVENTS:
                ev = ev_from_json(bridge.ask({"concretize": {"inst": inst, "phase": ph, "cev": cev_to_json(c)}})["ev"])
                if ev != R.concretize(inst, ph, c):
                    cmism += 1
    # concrete reachability (the Python model, now known to agree with Bend cell by cell)
    reach = {}
    for inst in (1, 2):
        states, edges = R.reachable_concrete(inst)
        reach[inst] = {"states": len(states), "max_hb": max(x[1] for x in states), "max_tack": max(x[2] for x in states),
                       "all_inv_all": all(L.inv_all(x) for x in states),
                       "phase_level_pairs": sorted({(x[0][0], x[0][1]) for x in states}),
                       "dms_reached": sorted({x[0][2] for x in states}),
                       "alarm_cells_exercised": sorted({(ph, c[1], tuple(sorted(evs))) for (ph, c), evs in edges.items() if c[0] == "XAlarm"}),
                       "dms_armed_by": sorted({c[1] for (ph, c), evs in edges.items() if c[0] == "XAlarm" and any(e[0] == "Stop" and e[1] == "LPtn" and e[2] for e in evs)})}
    ok = mism == 0 and lawfail == 0 and cmism == 0 and all(v["all_inv_all"] for v in reach.values())
    results["C5"] = {"cells_compared": cells, "mismatches": mism, "law_failures_on_bend_cells": lawfail,
                     "concretize_mismatches": cmism, "concrete_reachability": reach, "seconds": round(time.perf_counter() - t0, 1), "ok": ok}
    print(f"[C5] {cells} Bend cells vs Python: {mism} mismatches, {lawfail} law failures; concretize mismatches {cmism}; "
          f"concrete reachable inst1={reach[1]['states']} (hb<={reach[1]['max_hb']}, tack<={reach[1]['max_tack']}), "
          f"inst2={reach[2]['states']}; all satisfy inv_all: {all(v['all_inv_all'] for v in reach.values())}  [{results['C5']['seconds']} s] -> {'ok' if ok else 'FAIL'}")
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
    # How tightly the laws pin the model: on a reachable cell, how many of the 2688 control states
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


def c6(results, full=False):
    """Mutation score against the ADVERSARIAL bank: 62 defects written by two independent reviews
    whose brief was to break the law set, plus 11 defects of the constants and of the oracle itself
    (M63-M73, blocker 2), plus the 17 flags that were written alongside the laws. The flag number is
    the weaker measure and is reported as such. Every public symbol of the model is restored after
    each mutant, so a patch may replace constants as well as functions."""
    import mutants
    t0 = time.perf_counter()
    ORIG = {k: getattr(R, k) for k in dir(R) if not k.startswith("_")}
    bank = {}
    for name, plaus, desc, patch in mutants.MUTANTS:
        try:
            for k, v in patch().items():
                assert k in ORIG, (name, k)
                setattr(R, k, v)
            rec = {"plausibility": plaus, "description": desc, "caught_by": catching_laws()}
            if full:
                rec["caught_by_all"] = catching_laws(early=False)
            bank[name] = rec
        finally:
            vars(R).update(ORIG)
    survivors = [n for n, v in bank.items() if not v["caught_by"]]
    flags = {}
    for m in R.MUT:
        try:
            R.MUT[m] = True
            flags[m] = catching_laws()
        finally:
            R.MUT[m] = False
    flag_survivors = [n for n, v in flags.items() if not v]
    # M06 is an equivalent mutant: its transition relation differs from the model's on 0 cells,
    # so no law can distinguish it. Verified rather than assumed.
    equivalent = [n for n in survivors if n.startswith("M06")]
    ok = set(survivors) <= set(equivalent) and not flag_survivors
    batches = {"M01-M37 (review 1)": [n for n in bank if n[:3] <= "M37"], "N01-N25 (review 2)": [n for n in bank if n.startswith("N")],
               "M63-M73 (constants and oracle)": [n for n in bank if n.startswith("M6") or n.startswith("M7")]}
    by_batch = {b: {"killed": sum(1 for n in ns if bank[n]["caught_by"]), "total": len(ns)} for b, ns in batches.items()}
    results["C6"] = {"bank": bank, "killed": len(bank) - len(survivors), "total": len(bank),
                     "by_batch": by_batch, "survivors": survivors, "known_equivalent": equivalent,
                     "flags_killed": len(flags) - len(flag_survivors), "flags_total": len(flags),
                     "flag_survivors": flag_survivors, "seconds": round(time.perf_counter() - t0, 1), "ok": ok}
    if full:
        per = {n: len(v["caught_by_all"]) for n, v in bank.items() if v["caught_by_all"]}
        hist = {}
        for k in per.values():
            hist[k] = hist.get(k, 0) + 1
        results["C6"]["laws_per_kill"] = {"per_mutant": per, "histogram": dict(sorted(hist.items())),
                                          "killed_by_a_single_law": sorted(n for n, k in per.items() if k == 1)}
    batch_txt = "; ".join(f"{b}: {v['killed']}/{v['total']}" for b, v in by_batch.items())
    print(f"[C6] adversarial bank: {len(bank) - len(survivors)}/{len(bank)} killed ({batch_txt})"
          f"{'; survivors ' + str(survivors) + ' (equivalent: ' + str(equivalent) + ')' if survivors else ''}; "
          f"model flags: {len(flags) - len(flag_survivors)}/{len(flags)} -> {'ok' if ok else 'FAIL'}")
    return ok


def main(full=False):
    results = {}
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
    sys.exit(0 if main(full="--full" in sys.argv[1:]) else 1)
