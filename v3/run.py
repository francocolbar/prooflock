"""run.py (Fase 3) - the gate of the JET protection-chain case study, one subcommand per stage.

  quick    ~ 30 s    PROOF_JETPROT_CONF + PROOF_JETPROT_SOUND, one negative test, the runtime
                     smoke, differential testing (guided generator, 200 traces, no bugs and one
                     planted bug) and the provenance block. The CI gate. Writes nothing unless
                     --json is given.
  proofs   ~ 20 min  every PROOF file prints "All terms check." (PROOF_JETPROT_LIVE, which
                     imports the 462 336-cell certificates and the reflection proof, takes
                     11-18 min on the JS checker), the smoke, and the 10 negative tests are
                     REJECTED by the checker with a counterexample.
  diff     ~ 3 min   Hypothesis: 60 runs (2 generators x 3 instances x 10 bug configurations)
                     of --max-examples traces each with a fixed --seed; no counterexample
                     without planted bugs, one for every planted bug, shrunk to a minimal trace.
  recheck  ~ 2 min   C5 (every Bend cell == the Python model, every law re-evaluated on the
                     Bend-produced next state), C2 vacuity / tightness, C3 order sensitivity.
  mutants  ~ 5 min   C6: the 73-mutant bank and the 17 model flags against the spec-side
                     oracle (pymodel/jetprot_laws.py + spec_consts.py). --full (about 40 min
                     more) also records how many laws catch each mutant.
  all      ~ 40 min  everything above; writes v3/results.json, v3/recheck.json and SHA256SUMS
                     at the repo root: the committed reference run. Re-run it and compare.

Every results file carries a `provenance` block: tool versions, the pinned Bend commit, the
seed, the SHA-256 of every input file and the host. Times are for the reference machine
(Windows 11, Bend 2.0.24 through bun, Python 3.14, no native toolchain).
"""
import argparse
import datetime
import glob
import hashlib
import json
import os
import platform
import random
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
BEND = ["bash", os.path.join(ROOT, "env", "bend.sh")]
BEND_SRC = os.environ.get("BEND_SRC", os.path.expanduser("~/.bend-src"))
sys.path.insert(0, os.path.join(HERE, "prod"))
sys.path.insert(0, HERE)
import jetprot_prod as prod  # noqa: E402
from bridge_client import Bridge  # noqa: E402

# PROOF_JETPROT_LIVE imports PROOF_JETPROT (which imports FIN, FIN_ALT and COR), so one check covers the
# reflection proofs, the two bounded-response theorems and the certificates
PROOFS = ["PROOF_JETPROT_LIVE.bend", "PROOF_JETPROT_CONF.bend", "PROOF_JETPROT_SOUND.bend"]
QUICK_PROOFS = ["PROOF_JETPROT_CONF.bend", "PROOF_JETPROT_SOUND.bend"]
SMOKE_LINES = 7            # verdict lines the runtime smoke must print
DEFAULT_SEED = 20260921
DEFAULT_MAX_EXAMPLES = 3000
QUICK_MAX_EXAMPLES = 200
# the inputs whose SHA-256 goes into the provenance block: model, spec, laws, proofs, certificate,
# negative tests, the Python re-check, the production implementation and the two gate scripts
INPUTS = (sorted(glob.glob(os.path.join(HERE, "*.bend"))) + sorted(glob.glob(os.path.join(HERE, "tests", "*.bend")))
          + sorted(glob.glob(os.path.join(HERE, "pymodel", "*.py")))
          + [os.path.join(HERE, "prod", "jetprot_prod.py"), os.path.join(HERE, "bridge.mjs"), os.path.join(HERE, "bridge_client.py"),
             os.path.join(HERE, "recheck.py"), os.path.join(HERE, "run.py"),
             os.path.join(ROOT, "env", "bend.sh"), os.path.join(ROOT, "env", "check_env.sh")])
SUMMED = INPUTS + [os.path.join(HERE, "results.json"), os.path.join(HERE, "recheck.json")]
TRIGS = ["Slow", "Fast", "Mhd", "MhdB", "Mchs", "Dhs", "BothHs", "Blind"]
EVENTS = ([{"$": "XTick"}] * 4 + [{"$": "XHeartbeat"}] * 3 + [{"$": "XAdvance"}] * 3 +
          [{"$": "XAlarm", "t": t} for t in TRIGS] +
          [{"$": k, "u": u} for u in ("Nb", "Rf") for k in ("XLocal", "XHeatOn", "XHeatOff")] +
          [{"$": "XPlasma", "ok": True}, {"$": "XPlasma", "ok": False}, {"$": "XIp", "ok": True}, {"$": "XIp", "ok": False},
           {"$": "XCommFault"}, {"$": "XHeatAck"}, {"$": "XReset"}])
HAPPY = [{"$": "XPlasma", "ok": True}, {"$": "XIp", "ok": True}, {"$": "XAdvance"}, {"$": "XAdvance"}, {"$": "XAdvance"}, {"$": "XAdvance"},
         {"$": "XHeatOn", "u": "Nb"}, {"$": "XHeartbeat"}, {"$": "XTick"}, {"$": "XHeatOn", "u": "Rf"}, {"$": "XAdvance"}]


def law_name_of(path):
    """The law a negative test declares, so a rejection can be attributed to it."""
    m = re.search(r"^law ([a-z_0-9]+):", open(path, encoding="utf-8").read(), re.M)
    return m.group(1) if m else None


def bend(rel_, cwd=HERE):
    r = subprocess.run(BEND + [os.path.basename(rel_)], cwd=os.path.join(HERE, os.path.dirname(rel_)) if os.path.dirname(rel_) else cwd,
                       env=dict(os.environ, BEND_NO_TELEMETRY="1"), capture_output=True, text=True, encoding="utf-8")
    return r.returncode, r.stdout, r.stderr


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def rel(path):
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def sh(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=120)
        return (r.stdout.strip().splitlines() or [""])[-1]
    except (OSError, subprocess.SubprocessError) as e:
        return "unavailable (" + e.__class__.__name__ + ")"


def provenance(seed, max_examples):
    """Everything a third party needs to reproduce a run, or to explain a difference."""
    import hypothesis
    bun = sh(["bun", "--version"])
    if bun.startswith("unavailable"):
        bun = sh([os.path.expanduser("~/.bun/bin/bun"), "--version"])
    return {
        "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "bend": {"version": sh(BEND + ["version"]), "commit": sh(["git", "-C", BEND_SRC, "rev-parse", "HEAD"]), "src": BEND_SRC},
        "bun": bun, "node": sh(["node", "--version"]), "python": sys.version.split()[0], "hypothesis": hypothesis.__version__,
        "seed": seed, "max_examples": max_examples,
        "sha256": {rel(p): sha256(p) for p in INPUTS if os.path.exists(p)},
        "host": {"os": platform.platform(), "machine": platform.machine(), "cpu": platform.processor()},
    }


def gates(results, proofs, negatives=None):
    """Proof files print "All terms check."; the smoke prints its ok lines; negative tests are REJECTED."""
    ok = True
    results.setdefault("gates", {})
    for rel_ in proofs:
        t0 = time.perf_counter()
        code, out, err = bend(rel_)
        dt = time.perf_counter() - t0
        passed = "All terms check." in out
        results["gates"][rel_] = {"result": (out.strip().splitlines() or [""])[-1] if passed else (out + err).strip()[-400:],
                                  "seconds": round(dt, 1)}
        ok &= passed
        print(f"[gate] {rel_:32} -> {results['gates'][rel_]['result']}  ({dt:.1f} s)")
    code, out, err = bend("tests/laws_jetprot_smoke.bend")
    oks = [ln for ln in out.splitlines() if ln.startswith("ok ")]
    passed = code == 0 and len(oks) == SMOKE_LINES and not any(ln.startswith("FALSE") for ln in out.splitlines())
    results["gates"]["tests/laws_jetprot_smoke.bend"] = "all ok" if passed else (out + err)[-400:]
    ok &= passed
    print(f"[gate] tests/laws_jetprot_smoke.bend     -> {results['gates']['tests/laws_jetprot_smoke.bend']}")
    paths = sorted(glob.glob(os.path.join(HERE, "tests", "jetprot_bug*.bend")))
    if negatives is not None:
        paths = paths[:negatives]
    for path in paths:
        rel_ = "tests/" + os.path.basename(path)
        code, out, err = bend(rel_)
        # a rejection only counts if the checker refuted a BOOL (a false law), not if the file
        # failed to typecheck: a Bend type error prints the same "expected/observed" tokens
        blob = out + err
        law = law_name_of(path)
        rejected = (code != 0
                    and re.search(r"- expected : (True|False)\{\}", blob) is not None
                    and re.search(r"- observed : (True|False)\{\}", blob) is not None
                    and (law is None or law in blob))
        results["gates"][rel_] = "REJECTED (as it must be)" if rejected else f"NOT rejected: exit {code}"
        ok &= rejected
        print(f"[gate] {rel_:40} -> {results['gates'][rel_]}")
    return ok


def diff(results, seed, max_examples, quick=False):
    """Differential testing of prod/jetprot_prod.py against the Bend model, with a fixed seed."""
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
    generators = [("guided", guided)] if quick else [("random", plain), ("guided", guided)]
    instances = (1,) if quick else (1, 2, 3)
    configs = [("no bugs", {})] + [(b, {b: True}) for b in prod.BUGS] + [("all bugs", {b: True for b in prod.BUGS})]
    if quick:
        configs = configs[:2]
    # a planted bug that the instance's configuration makes unobservable: the communication check is
    # masked out in instance 3, so the path the bug lives on is never taken (that is F3)
    unobservable = {("commfault_leaves_heating", 3)}
    results["diff"] = []
    results["max_examples"] = max_examples
    results["seed"] = seed
    found_by = {}
    for gen_name, traces in generators:
        for inst in instances:
            for cfg_name, bugs in configs:
                name = f"{cfg_name} / {gen_name} / inst{inst}"
                for b in prod.BUGS:
                    prod.BUGS[b] = bugs.get(b, False)
                calls0, t0 = bridge.calls, time.perf_counter()
                # one Random per run, derived from the seed and the run's name: the same seed
                # reproduces the same traces and the same minimal counterexamples
                rng = random.Random(f"{seed}:{gen_name}:{inst}:{cfg_name}")
                try:
                    minimal = find(traces, lambda tr: any(failure(tr, inst)),
                                   settings=settings(max_examples=max_examples, database=None, deadline=None, suppress_health_check=list(HealthCheck)),
                                   random=rng)
                    traj, inv = failure(minimal, inst)
                    rec = {"config": cfg_name, "generator": gen_name, "instance": inst, "found": True,
                           "minimal_trace": [e["$"][1:] + ("" if len(e) == 1 else ":" + str(list(e.values())[1])) for e in minimal],
                           "trajectory_differs": traj, "invariant_violated": inv, "final_prod_state": prod.run(minimal, inst)[-1] if minimal else prod.init()}
                    expected = bool(bugs) and (cfg_name, inst) not in unobservable
                except NoSuchExample:
                    rec = {"config": cfg_name, "generator": gen_name, "instance": inst, "found": False}
                    expected = (not bugs) or (cfg_name, inst) in unobservable
                rec["seconds"] = round(time.perf_counter() - t0, 1)
                rec["bridge_calls"] = bridge.calls - calls0
                rec["as_expected"] = expected
                if rec["found"]:
                    ok &= bool(bugs) and (cfg_name, inst) not in unobservable  # no bug, or an unobservable one: a false positive
                key = (cfg_name, inst)
                found_by[key] = found_by.get(key, False) or rec["found"]
                results["diff"].append(rec)
                if rec["found"]:
                    print(f"[diff] {name:44} -> BUG FOUND, minimal trace ({len(rec['minimal_trace'])} events): {' '.join(rec['minimal_trace'])}")
                    print(f"       trajectory differs: {rec['trajectory_differs']}; Bend invariant violated on prod states: {rec['invariant_violated']}  [{rec['seconds']} s, {rec['bridge_calls']} calls]")
                else:
                    print(f"[diff] {name:44} -> no counterexample in {max_examples} traces  [{rec['seconds']} s, {rec['bridge_calls']} calls]")
    bridge.close()
    for b in prod.BUGS:
        prod.BUGS[b] = False
    for (cfg_name, inst), found in sorted(found_by.items()):
        must = cfg_name != "no bugs" and (cfg_name, inst) not in unobservable
        ok &= (found == must)
        print(f"[diff] {cfg_name:28} inst{inst} -> {'found' if found else 'not found'} by some generator; expected {'found' if must else 'not found'}")
    results["found_by_some_generator"] = {f"{k[0]} / inst{k[1]}": v for k, v in found_by.items()}
    results["unobservable_configs"] = [f"{c} / inst{i}" for c, i in sorted(unobservable)]
    return ok


def recheck_stage(results, which, full=False):
    """The Python-side gates of recheck.py (C5, C2, C3, C6), into results["recheck"]."""
    import recheck
    rc = results.setdefault("recheck", {})
    ok = True
    if "c5" in which:
        bridge = Bridge()
        ok &= recheck.c5(bridge, rc)
        bridge.close()
    if "c2" in which:
        ok &= recheck.c2(rc)
    if "c3" in which:
        recheck.c3(rc)
    if "c6" in which:
        ok &= recheck.c6(rc, full=full)
    rc["all_ok"] = bool(ok)
    return ok


def write_json(obj, path):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=1, default=str)
    print(f"[write] {rel(path)}")


def write_sums():
    """SHA256SUMS at the repo root, in `sha256sum -c` format, over the inputs and the two results files."""
    path = os.path.join(ROOT, "SHA256SUMS")
    present = [p for p in SUMMED if os.path.exists(p)]
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for p in present:
            f.write(sha256(p) + "  " + rel(p) + "\n")
    print(f"[write] SHA256SUMS ({len(present)} files); verify with: sha256sum -c SHA256SUMS")


def main(argv=None):
    ap = argparse.ArgumentParser(prog="run.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stage", choices=["quick", "proofs", "diff", "recheck", "mutants", "all"],
                    help="the stage to run (the table above says what each one does and how long it takes)")
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED, help=f"Hypothesis seed for the differential runs (default {DEFAULT_SEED})")
    ap.add_argument("--max-examples", type=int, default=None, help=f"traces per differential run (default {DEFAULT_MAX_EXAMPLES}; quick: {QUICK_MAX_EXAMPLES})")
    ap.add_argument("--json", metavar="PATH", default=None, help="write this stage's results to PATH (all: v3/results.json by default)")
    ap.add_argument("--full", action="store_true", help="mutants / all: also count how many laws catch each mutant (about 10 min more)")
    args = ap.parse_args(argv)
    stage = args.stage
    max_examples = args.max_examples or (QUICK_MAX_EXAMPLES if stage == "quick" else DEFAULT_MAX_EXAMPLES)
    t0 = time.perf_counter()
    results = {"stage": stage, "provenance": provenance(args.seed, max_examples)}
    prov = results["provenance"]
    print(f"[prov] bend {prov['bend']['version']} @ {prov['bend']['commit'][:12]}, python {prov['python']}, "
          f"hypothesis {prov['hypothesis']}, seed {args.seed}, max_examples {max_examples}")
    ok = True
    if stage == "quick":
        ok &= gates(results, QUICK_PROOFS, negatives=1)
        ok &= diff(results, args.seed, max_examples, quick=True)
    elif stage == "proofs":
        ok &= gates(results, PROOFS)
    elif stage == "diff":
        ok &= diff(results, args.seed, max_examples)
    elif stage == "recheck":
        ok &= recheck_stage(results, ("c5", "c2", "c3"))
    elif stage == "mutants":
        ok &= recheck_stage(results, ("c6",), full=args.full)
    elif stage == "all":
        ok &= gates(results, PROOFS)
        ok &= recheck_stage(results, ("c5", "c2", "c3", "c6"), full=args.full)
        ok &= diff(results, args.seed, max_examples)
    results["all_ok"] = bool(ok)
    results["seconds"] = round(time.perf_counter() - t0, 1)
    if stage == "all":
        rc = dict(results["recheck"])
        rc["provenance"] = results["provenance"]
        write_json(rc, os.path.join(HERE, "recheck.json"))
        write_json(results, args.json or os.path.join(HERE, "results.json"))
        write_sums()
    elif args.json:
        write_json(results, args.json)
    print(f"[done] {stage}: {'ok' if ok else 'FAILED'} in {results['seconds']} s")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
