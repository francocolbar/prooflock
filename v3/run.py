"""run.py (Fase 3) - the single gate of the JET protection-chain case study.

  gates    : every PROOF file prints "All terms check." (the reflection proofs, the conformance
             laws; the three certificates are imported); the runtime smoke has no FALSE line;
             every NEGATIVE test is REJECTED by the checker with a counterexample.
  recheck  : C5 independent re-check (Bend cells == Python cells, laws re-evaluated), C2 vacuity /
             coverage, C3 order sensitivity, C6 mutation score (recheck.py).
  diff     : Hypothesis generates random concrete event traces; for each configuration of planted
             bugs in prod/jetprot_prod.py it searches for a trace on which (a) the production
             trajectory differs from the golden model's, or (b) the Bend invariants, evaluated by
             Bend on the production states, are violated; the failing trace is shrunk to a
             minimal one. With no bugs, N examples must pass.

Usage: py -3.14 bend-spike/v3/run.py            Writes: results.json (exit 0 iff everything holds)
"""
import glob
import json
import re
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BEND = ["bash", os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "env", "bend.sh")]
sys.path.insert(0, os.path.join(HERE, "prod"))
sys.path.insert(0, HERE)
import jetprot_prod as prod  # noqa: E402
from bridge_client import Bridge  # noqa: E402

PROOFS = ["PROOF_JETPROT.bend", "PROOF_JETPROT_CONF.bend"]   # FIN, FIN_ALT and COR are imported by PROOF_JETPROT
SMOKE_LINES = 6            # verdict lines the runtime smoke must print


def law_name_of(path):
    """The law a negative test declares, so a rejection can be attributed to it."""
    m = re.search(r"^law ([a-z_0-9]+):", open(path, encoding="utf-8").read(), re.M)
    return m.group(1) if m else None
MAX_EXAMPLES = 3000
TRIGS = ["Slow", "Fast", "Mhd", "MhdB", "Mchs", "Dhs", "BothHs"]
EVENTS = ([{"$": "XTick"}] * 4 + [{"$": "XHeartbeat"}] * 3 + [{"$": "XAdvance"}] * 3 +
          [{"$": "XAlarm", "t": t} for t in TRIGS] +
          [{"$": k, "u": u} for u in ("Nb", "Rf") for k in ("XLocal", "XHeatOn", "XHeatOff")] +
          [{"$": "XPlasma", "ok": True}, {"$": "XPlasma", "ok": False}, {"$": "XCommFault"}, {"$": "XHeatAck"}, {"$": "XReset"}])
HAPPY = [{"$": "XPlasma", "ok": True}, {"$": "XAdvance"}, {"$": "XAdvance"}, {"$": "XAdvance"}, {"$": "XAdvance"},
         {"$": "XHeatOn", "u": "Nb"}, {"$": "XHeartbeat"}, {"$": "XTick"}, {"$": "XHeatOn", "u": "Rf"}, {"$": "XAdvance"}]


def bend(rel, cwd=HERE):
    r = subprocess.run(BEND + [os.path.basename(rel)], cwd=os.path.join(HERE, os.path.dirname(rel)) if os.path.dirname(rel) else cwd,
                       env=dict(os.environ, BEND_NO_TELEMETRY="1"), capture_output=True, text=True, encoding="utf-8")
    return r.returncode, r.stdout, r.stderr


def gates(results):
    ok = True
    for rel in PROOFS:
        t0 = time.perf_counter()
        code, out, err = bend(rel)
        dt = time.perf_counter() - t0
        passed = "All terms check." in out
        results["gates"][rel] = {"result": (out.strip().splitlines() or [""])[-1] if passed else (out + err).strip()[-400:],
                                 "seconds": round(dt, 1)}
        ok &= passed
        print(f"[gate] {rel:32} -> {results['gates'][rel]['result']}  ({dt:.1f} s)")
    code, out, err = bend("tests/laws_jetprot_smoke.bend")
    oks = [ln for ln in out.splitlines() if ln.startswith("ok ")]
    passed = code == 0 and len(oks) == SMOKE_LINES and not any(ln.startswith("FALSE") for ln in out.splitlines())
    results["gates"]["tests/laws_jetprot_smoke.bend"] = "all ok" if passed else (out + err)[-400:]
    ok &= passed
    print(f"[gate] tests/laws_jetprot_smoke.bend     -> {results['gates']['tests/laws_jetprot_smoke.bend']}")
    for path in sorted(glob.glob(os.path.join(HERE, "tests", "jetprot_bug*.bend"))):
        rel = "tests/" + os.path.basename(path)
        code, out, err = bend(rel)
        # a rejection only counts if the checker refuted a BOOL (a false law), not if the file
        # failed to typecheck: a Bend type error prints the same "expected/observed" tokens
        blob = out + err
        law = law_name_of(path)
        rejected = (code != 0
                    and re.search(r"- expected : (True|False)\{\}", blob) is not None
                    and re.search(r"- observed : (True|False)\{\}", blob) is not None
                    and (law is None or law in blob))
        results["gates"][rel] = "REJECTED (as it must be)" if rejected else f"NOT rejected: exit {code}"
        ok &= rejected
        print(f"[gate] {rel:40} -> {results['gates'][rel]}")
    return ok


def diff(results):
    from hypothesis import strategies as st, find, settings, HealthCheck
    from hypothesis.errors import NoSuchExample

    bridge = Bridge()
    assert prod.from_bend(bridge.ask({"init": True})["state"]) == prod.init()
    ok = True

    def failure(trace, inst):
        golden = bridge.ask({"trace": trace, "inst": inst})
        mine = prod.run(trace, inst)
        traj = [prod.from_bend(s) for s in golden["states"]] != mine
        invs = bridge.ask({"check": [prod.to_bend(s) for s in mine]})["invs"]
        return traj, not all(invs)

    plain = st.lists(st.sampled_from(EVENTS), min_size=0, max_size=40)
    guided = st.builds(lambda k, rest: HAPPY[:k] + rest, st.integers(0, len(HAPPY)), st.lists(st.sampled_from(EVENTS), min_size=0, max_size=30))
    generators = [("random", plain), ("guided", guided)]
    configs = [("no bugs", {})] + [(b, {b: True}) for b in prod.BUGS] + [("all bugs", {b: True for b in prod.BUGS})]
    found_by = {}
    for gen_name, traces in generators:
        for inst in (1, 2):
            for cfg_name, bugs in configs:
                name = f"{cfg_name} / {gen_name} / inst{inst}"
                for b in prod.BUGS:
                    prod.BUGS[b] = bugs.get(b, False)
                calls0, t0 = bridge.calls, time.perf_counter()
                try:
                    minimal = find(traces, lambda tr: any(failure(tr, inst)),
                                   settings=settings(max_examples=MAX_EXAMPLES, database=None, deadline=None, suppress_health_check=list(HealthCheck)))
                    traj, inv = failure(minimal, inst)
                    rec = {"config": cfg_name, "generator": gen_name, "instance": inst, "found": True,
                           "minimal_trace": [e["$"][1:] + ("" if len(e) == 1 else ":" + str(list(e.values())[1])) for e in minimal],
                           "trajectory_differs": traj, "invariant_violated": inv, "final_prod_state": prod.run(minimal, inst)[-1] if minimal else prod.init()}
                    expected = bool(bugs)
                except NoSuchExample:
                    rec = {"config": cfg_name, "generator": gen_name, "instance": inst, "found": False}
                    expected = not bugs
                rec["seconds"] = round(time.perf_counter() - t0, 1)
                rec["bridge_calls"] = bridge.calls - calls0
                rec["as_expected"] = expected
                if rec["found"]:
                    ok &= bool(bugs)  # a counterexample with no bug planted is a false positive
                key = (cfg_name, inst)
                found_by[key] = found_by.get(key, False) or rec["found"]
                results["diff"].append(rec)
                if rec["found"]:
                    print(f"[diff] {name:44} -> BUG FOUND, minimal trace ({len(rec['minimal_trace'])} events): {' '.join(rec['minimal_trace'])}")
                    print(f"       trajectory differs: {rec['trajectory_differs']}; Bend invariant violated on prod states: {rec['invariant_violated']}  [{rec['seconds']} s, {rec['bridge_calls']} calls]")
                else:
                    print(f"[diff] {name:44} -> no counterexample in {MAX_EXAMPLES} traces  [{rec['seconds']} s, {rec['bridge_calls']} calls]")
    bridge.close()
    for b in prod.BUGS:
        prod.BUGS[b] = False
    for (cfg_name, inst), found in sorted(found_by.items()):
        must = cfg_name != "no bugs"
        ok &= (found == must)
        print(f"[diff] {cfg_name:28} inst{inst} -> {'found' if found else 'not found'} by some generator; expected {'found' if must else 'not found'}")
    results["found_by_some_generator"] = {f"{k[0]} / inst{k[1]}": v for k, v in found_by.items()}
    return ok


def main():
    results = {"gates": {}, "diff": [], "max_examples": MAX_EXAMPLES}
    ok = gates(results)
    import recheck
    ok &= recheck.main()
    results["recheck"] = json.load(open(os.path.join(HERE, "recheck.json"), encoding="utf-8"))
    ok &= diff(results)
    results["all_ok"] = bool(ok)
    with open(os.path.join(HERE, "results.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=1, default=str)
    print(f"[done] all gates and checks ok: {ok}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
