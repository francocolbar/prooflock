"""run.py (Phase 3) - the gate of the JET protection-chain case study, one subcommand per stage.

  stage    what it does
  quick    PROOF_JETPROT_CONF + PROOF_JETPROT_SOUND, one negative test, the runtime smoke, differential
           testing (guided generator, 200 traces, no bugs and one planted bug) and the provenance block.
           Meant as the CI gate (none is configured yet). Writes nothing unless --json is given.
  proofs   every PROOF file prints "All terms check." (PROOF_JETPROT_LIVE imports the 462 336-cell
           certificates and the reflection proof: it is the longest check), the smoke, and the 12
           negative tests are REJECTED by the checker: a refuted Bool naming the test's law (each test
           evaluates a predicate at a cell written into it, or, negative 8, the certificate).
  diff     Hypothesis: 88 runs (2 generators x 4 instances x 11 bug configurations) of --max-examples
           traces each with a fixed --seed; no counterexample without planted bugs, and for every
           planted bug a counterexample from some generator in every instance that can show it (none
           in the five bug x instance pairs declared in UNOBSERVABLE), shrunk to a minimal trace.
  recheck  C5 (every Bend cell == the Python model, the 62 cell checks of the Python oracle re-evaluated
           on the Bend-produced next state), C2 vacuity / tightness, C3 order sensitivity.
  mutants  C6: the 76-mutant bank and the 17 model flags against the spec-side oracle
           (pymodel/jetprot_laws.py + spec_consts.py). A survivor passes only as an equivalent mutant,
           computed: its transition relation must equal the model's on all 924 672 certificate cells,
           its counter layer (verdicts, apply, step_st) on 12 042 240 concrete cells and its concretize
           on 1 032 192 (instance, control state, plant event) cells.
           --full also records how many laws catch each mutant (the longest part of the gate).
  all      everything above; writes v3/results.json, v3/recheck.json and SHA256SUMS at the repo root:
           the committed reference run (with --full). Re-run and compare with compare_runs.py.

Measured times (reference machine: Windows 11, 8 cores / 16 threads, 32 GB, Bend through bun,
Python 3.14, no native toolchain). The committed run's own times are in v3/results.json ("seconds",
"gates", provenance) and README §4; this text does not quote them, because editing run.py changes an
input hash and so calls for a new run.
  all --full --jobs 12  1728.9 s and 1299.8 s (two runs on 2026-09-23, Bend 2.0.25): PROOF_JETPROT_LIVE
                        1728.2 s and 1299.2 s beside the pool; every Python stage had ended by 1637.4 s
                        and 1262.5 s. Same verdicts, counts, census and traces as the serial run
                        (compare_runs.py).
  all --full --jobs 1   7305.5 s (serial reference run, 2026-09-22, Bend 2.0.24). Of it: the C6 census
                        with --full 5884.4 s, PROOF_JETPROT_LIVE 795.8 s, the 88 differential runs
                        161.9 s, C2 66.4 s, C5 20.3 s.
  all --full --jobs 12  1535.5 s (2026-09-23, Bend 2.0.24, the parallel design before the abort fix and
                        the computed equivalence, in an isolated copy on a machine loaded by other
                        work). All of it is PROOF_JETPROT_LIVE (1534.8 s beside the pool); the
                        Python stages ended earlier (seconds from the start: C5 1385.8, C3 1386.5,
                        C2 1458.1, C6 1474.6, diff 1483.4). The results files were identical to the
                        serial run's leaf by leaf over 6 433 leaves, apart from wall times and run
                        metadata (compare_runs.py).
  all --full --jobs 12  1816.5 s and 2103.4 s (Bend 2.0.24) with an earlier design, a pool of 12
                        normal-priority workers beside the Bend checks: PROOF_JETPROT_LIVE took
                        1815.8 s and 2102.5 s while the Python stages ended at 1008-1230 s. Hence the
                        capped, below-normal pool described below.
  quick                 36.6 s with --jobs 1 and 35.2 s with --jobs 12 on Bend 2.0.25 (2026-09-23; one
                        earlier run with --jobs 12 took 86.6 s); 46.5 s (--jobs 1) and 43.2 s
                        (--jobs 12) on Bend 2.0.24 (2026-09-23).
The other stages were not timed on their own. With --jobs > 1 `all` prints the wall-clock of each
stage ([time]); the serial path prints each check's own time.

Every results file carries a `provenance` block: tool versions, the pinned Bend commit, the
seed, the number of parallel jobs, the SHA-256 of every input file and the host.

--jobs N (default: cpu_count - 4, 12 on the reference machine) runs the stages in parallel: the Bend
checks in a thread pool of at most min(N, 8) `bend` processes, longest (PROOF_JETPROT_LIVE) first; the
C6 census, the 17 model flags, C5, C2, C3 and the 88 differential runs in a spawn process pool that
receives indices only. Alone (diff, recheck, mutants) the pool has N workers. Beside the Bend checks
(quick, proofs, all) it has min(N, physical cores - 1) workers at below-normal priority (the node
bridges they start inherit it; the bash/bun checks stay normal), so PROOF_JETPROT_LIVE, the
critical path, is not starved by hyper-thread siblings and the scheduler serves it first. Every result
is assembled in the serial order, so the results files are the same as with --jobs 1, which is
exactly the serial code path. A worker exception fails the gate; nothing is silently dropped. On an
abort the Bend checks still queued are cancelled before the running ones are killed, so none starts.
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
import threading
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
LONGEST = "PROOF_JETPROT_LIVE.bend"   # started first by the parallel gates: it is the critical path
SMOKE = "tests/laws_jetprot_smoke.bend"
SMOKE_LINES = 7            # verdict lines the runtime smoke must print
MAX_BEND_PROCS = 8         # Bend checks at once in the parallel gates (each is one bun process)
DEFAULT_SEED = 20260921
DEFAULT_MAX_EXAMPLES = 3000
QUICK_MAX_EXAMPLES = 200
# the inputs whose SHA-256 goes into the provenance block: model, spec, laws, proofs, certificate,
# negative tests, the Python re-check, the production implementation, the two gate scripts and the
# results comparator
INPUTS = (sorted(glob.glob(os.path.join(HERE, "*.bend"))) + sorted(glob.glob(os.path.join(HERE, "tests", "*.bend")))
          + sorted(glob.glob(os.path.join(HERE, "pymodel", "*.py")))
          + [os.path.join(HERE, "prod", "jetprot_prod.py"), os.path.join(HERE, "bridge.mjs"), os.path.join(HERE, "bridge_client.py"),
             os.path.join(HERE, "recheck.py"), os.path.join(HERE, "run.py"), os.path.join(HERE, "compare_runs.py"),
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
# a planted bug that the instance's configuration makes unobservable: the communication check is
# masked out in instance 3, so the path the bug lives on is never taken (that is F3); the secondary
# table of instances 1-3 IS their primary entry, so ignoring it changes nothing there (revision 4);
# and in instance 4 every alarm under a stop asks for the PTN or for nothing, so no soft request
# ever meets a stop in force and a missing urgency comparison (deescalation) cannot show
UNOBSERVABLE = {("commfault_leaves_heating", 3), ("secondary_ignored_during_stop", 1),
                ("secondary_ignored_during_stop", 2), ("secondary_ignored_during_stop", 3),
                ("deescalation", 4)}


def default_jobs():
    return max(1, (os.cpu_count() or 1) - 4)


def physical_cores():
    """Physical cores (psutil if present; otherwise assume 2 hardware threads per core)."""
    try:
        import psutil
        n = psutil.cpu_count(logical=False)
        if n:
            return n
    except Exception:
        pass
    return max(1, (os.cpu_count() or 2) // 2)


def pool_size(jobs, beside_gates):
    """Python workers of the parallel scheduler. Beside the Bend checks, at most physical cores - 1:
    PROOF_JETPROT_LIVE is the critical path, and a full pool of hyper-threads slows it ~2.5x."""
    return max(1, min(jobs, physical_cores() - 1)) if beside_gates else jobs


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


def provenance(seed, max_examples, jobs):
    """Everything a third party needs to reproduce a run, or to explain a difference."""
    import hypothesis
    bun = sh(["bun", "--version"])
    if bun.startswith("unavailable"):
        bun = sh([os.path.expanduser("~/.bun/bin/bun"), "--version"])
    return {
        "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "bend": {"version": sh(BEND + ["version"]), "commit": sh(["git", "-C", BEND_SRC, "rev-parse", "HEAD"]), "src": BEND_SRC},
        "bun": bun, "node": sh(["node", "--version"]), "python": sys.version.split()[0], "hypothesis": hypothesis.__version__,
        "seed": seed, "max_examples": max_examples, "jobs": jobs,
        "sha256": {rel(p): sha256(p) for p in INPUTS if os.path.exists(p)},
        "host": {"os": platform.platform(), "machine": platform.machine(), "cpu": platform.processor()},
    }


# ---------------------------------------------------------------------------------------------
# Gates: the Bend checks
# ---------------------------------------------------------------------------------------------
def gate_items(proofs, negatives=None):
    """(path, kind) of every Bend check of the stage, in the order the results record them:
    the proof files, the smoke, then the negative tests (sorted by name)."""
    paths = sorted(glob.glob(os.path.join(HERE, "tests", "jetprot_bug*.bend")))
    if negatives is not None:
        paths = paths[:negatives]
    return [(r, "proof") for r in proofs] + [(SMOKE, "smoke")] + [("tests/" + os.path.basename(p), "negative") for p in paths]


def judge(gates_, rel_, kind, code, out, err, dt):
    """Record the verdict of one Bend check in gates_[rel_]; return (passed, report line).
    Proof files print "All terms check."; the smoke prints its ok lines; negative tests are REJECTED."""
    if kind == "proof":
        passed = "All terms check." in out
        gates_[rel_] = {"result": (out.strip().splitlines() or [""])[-1] if passed else (out + err).strip()[-400:],
                        "seconds": round(dt, 1)}
        return passed, f"[gate] {rel_:32} -> {gates_[rel_]['result']}  ({dt:.1f} s)"
    if kind == "smoke":
        oks = [ln for ln in out.splitlines() if ln.startswith("ok ")]
        passed = code == 0 and len(oks) == SMOKE_LINES and not any(ln.startswith("FALSE") for ln in out.splitlines())
        gates_[rel_] = "all ok" if passed else (out + err)[-400:]
        return passed, f"[gate] tests/laws_jetprot_smoke.bend     -> {gates_[rel_]}"
    # a rejection only counts if the checker refuted a BOOL (a false law), not if the file
    # failed to typecheck: a Bend type error prints the same "expected/observed" tokens
    blob = out + err
    law = law_name_of(os.path.join(HERE, "tests", os.path.basename(rel_)))
    rejected = (code != 0
                and re.search(r"- expected : (True|False)\{\}", blob) is not None
                and re.search(r"- observed : (True|False)\{\}", blob) is not None
                and (law is None or law in blob))
    gates_[rel_] = "REJECTED (as it must be)" if rejected else f"NOT rejected: exit {code}"
    return rejected, f"[gate] {rel_:40} -> {gates_[rel_]}"


def gates(results, proofs, negatives=None):
    """The serial gates (--jobs 1): one Bend check after the other, in gate_items order."""
    ok = True
    results.setdefault("gates", {})
    for rel_, kind in gate_items(proofs, negatives):
        t0 = time.perf_counter()
        code, out, err = bend(rel_)
        passed, line = judge(results["gates"], rel_, kind, code, out, err, time.perf_counter() - t0)
        ok &= passed
        print(line)
    return ok


# The parallel gates' state, so an abort can stop them: the Bend processes running, the futures of
# the checks (queued ones are cancelled) and a flag every check tests, under _GATE_LOCK, before it
# starts its process. A check therefore either starts before the abort (and is killed) or never.
_RUNNING = set()
_PENDING = []
_ABORT = threading.Event()
_GATE_LOCK = threading.Lock()


class GatesAborted(RuntimeError):
    """The parallel gates were aborted: no verdict."""


def _abort_gates():
    """Cancel the queued Bend checks first, so nothing new starts, then kill the running ones."""
    with _GATE_LOCK:
        _ABORT.set()
        for f in _PENDING:
            f.cancel()   # only a check not yet started can be cancelled
        running = list(_RUNNING)
    for p in running:
        try:
            if os.name == "nt":   # bash -> bun: kill the whole tree
                subprocess.run(["taskkill", "/T", "/F", "/PID", str(p.pid)], capture_output=True)
            else:
                p.kill()
        except Exception:
            pass


def _timed_bend(rel_):
    """bend() for the thread pool: the same command, cwd and environment, plus its wall time."""
    t0 = time.perf_counter()
    with _GATE_LOCK:
        if _ABORT.is_set():
            raise GatesAborted(rel_)
        p = subprocess.Popen(BEND + [os.path.basename(rel_)], cwd=os.path.join(HERE, os.path.dirname(rel_)) if os.path.dirname(rel_) else HERE,
                             env=dict(os.environ, BEND_NO_TELEMETRY="1"), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             text=True, encoding="utf-8")
        _RUNNING.add(p)
    try:
        out, err = p.communicate()
    finally:
        with _GATE_LOCK:
            _RUNNING.discard(p)
    return p.returncode, out, err, time.perf_counter() - t0


def gates_parallel(results, proofs, negatives, jobs, say):
    """The gates with at most min(jobs, 8) Bend processes at once, PROOF_JETPROT_LIVE first;
    results["gates"] gets exactly the serial keys, values and order."""
    from concurrent.futures import ThreadPoolExecutor, as_completed
    items = gate_items(proofs, negatives)
    order = sorted(items, key=lambda it: it[0] != LONGEST)   # stable: LIVE first, the rest as listed
    done = {}
    with ThreadPoolExecutor(max_workers=max(1, min(jobs, MAX_BEND_PROCS, len(items)))) as ex:
        futs = {}
        for rel_, kind in order:
            fut = ex.submit(_timed_bend, rel_)
            futs[fut] = (rel_, kind)
            with _GATE_LOCK:
                _PENDING.append(fut)
                if _ABORT.is_set():   # aborted while submitting: this one too
                    fut.cancel()
        for fut in as_completed(futs):
            if _ABORT.is_set():   # the verdicts of killed or cancelled checks mean nothing
                raise GatesAborted("parallel gates aborted")
            rel_, kind = futs[fut]
            code, out, err, dt = fut.result()
            one = {}
            passed, line = judge(one, rel_, kind, code, out, err, dt)
            done[rel_] = (passed, one[rel_])
            say(f"{line}  [{len(done)}/{len(items)}]")
    ok = True
    results.setdefault("gates", {})
    for rel_, kind in items:
        passed, verdict = done[rel_]
        results["gates"][rel_] = verdict
        ok &= passed
    return ok


# ---------------------------------------------------------------------------------------------
# Differential testing
# ---------------------------------------------------------------------------------------------
def diff_strategies():
    from hypothesis import strategies as st
    plain = st.lists(st.sampled_from(EVENTS), min_size=0, max_size=40)
    guided = st.builds(lambda k, rest: HAPPY[:k] + rest, st.integers(0, len(HAPPY)), st.lists(st.sampled_from(EVENTS), min_size=0, max_size=30))
    return {"random": plain, "guided": guided}


def diff_plan(quick=False):
    """(generator, instance, configuration, bugs) of every differential run, in the serial order."""
    generators = ["guided"] if quick else ["random", "guided"]
    instances = (1,) if quick else (1, 2, 3, 4)
    configs = [("no bugs", {})] + [(b, {b: True}) for b in prod.BUGS] + [("all bugs", {b: True for b in prod.BUGS})]
    if quick:
        configs = configs[:2]
    return [(gen_name, inst, cfg_name, bugs) for gen_name in generators for inst in instances for cfg_name, bugs in configs]


def diff_failure(bridge, trace, inst):
    golden = bridge.ask({"trace": trace, "inst": inst})
    mine = prod.run(trace, inst)
    traj = [prod.from_bend(s) for s in golden["states"]] != mine
    invs = bridge.ask({"check": [prod.to_bend(s) for s in mine]})["invs"]
    return traj, not all(invs)


def diff_run(bridge, traces, gen_name, inst, cfg_name, bugs, seed, max_examples):
    """One differential run: its own Random from the seed and the run's name, no database."""
    from hypothesis import find, settings, HealthCheck
    from hypothesis.errors import NoSuchExample
    for b in prod.BUGS:
        prod.BUGS[b] = bugs.get(b, False)
    calls0, t0 = bridge.calls, time.perf_counter()
    # one Random per run, derived from the seed and the run's name: the same seed
    # reproduces the same traces and the same minimal counterexamples
    rng = random.Random(f"{seed}:{gen_name}:{inst}:{cfg_name}")
    try:
        minimal = find(traces, lambda tr: any(diff_failure(bridge, tr, inst)),
                       settings=settings(max_examples=max_examples, database=None, deadline=None, suppress_health_check=list(HealthCheck)),
                       random=rng)
        traj, inv = diff_failure(bridge, minimal, inst)
        rec = {"config": cfg_name, "generator": gen_name, "instance": inst, "found": True,
               "minimal_trace": [e["$"][1:] + ("" if len(e) == 1 else ":" + str(list(e.values())[1])) for e in minimal],
               "trajectory_differs": traj, "invariant_violated": inv, "final_prod_state": prod.run(minimal, inst)[-1] if minimal else prod.init()}
        expected = bool(bugs) and (cfg_name, inst) not in UNOBSERVABLE
    except NoSuchExample:
        rec = {"config": cfg_name, "generator": gen_name, "instance": inst, "found": False}
        expected = (not bugs) or (cfg_name, inst) in UNOBSERVABLE
    rec["seconds"] = round(time.perf_counter() - t0, 1)
    rec["bridge_calls"] = bridge.calls - calls0
    rec["as_expected"] = expected
    return rec


def diff_report(rec, max_examples):
    name = f"{rec['config']} / {rec['generator']} / inst{rec['instance']}"
    if rec["found"]:
        return (f"[diff] {name:44} -> BUG FOUND, minimal trace ({len(rec['minimal_trace'])} events): {' '.join(rec['minimal_trace'])}\n"
                f"       trajectory differs: {rec['trajectory_differs']}; Bend invariant violated on prod states: {rec['invariant_violated']}  [{rec['seconds']} s, {rec['bridge_calls']} calls]")
    return f"[diff] {name:44} -> no counterexample in {max_examples} traces  [{rec['seconds']} s, {rec['bridge_calls']} calls]"


def diff_finish(results, plan, recs, seed, max_examples, out=print):
    """The verdict of the differential stage from its runs (in plan order), into results."""
    ok = True
    results["diff"] = recs
    results["max_examples"] = max_examples
    results["seed"] = seed
    found_by = {}
    for (gen_name, inst, cfg_name, bugs), rec in zip(plan, recs, strict=True):
        assert (rec["generator"], rec["instance"], rec["config"]) == (gen_name, inst, cfg_name), (rec, gen_name, inst, cfg_name)
        if rec["found"]:
            ok &= bool(bugs) and (cfg_name, inst) not in UNOBSERVABLE  # no bug, or an unobservable one: a false positive
        key = (cfg_name, inst)
        found_by[key] = found_by.get(key, False) or rec["found"]
    for (cfg_name, inst), found in sorted(found_by.items()):
        must = cfg_name != "no bugs" and (cfg_name, inst) not in UNOBSERVABLE
        ok &= (found == must)
        out(f"[diff] {cfg_name:28} inst{inst} -> {'found' if found else 'not found'} by some generator; expected {'found' if must else 'not found'}")
    results["found_by_some_generator"] = {f"{k[0]} / inst{k[1]}": v for k, v in found_by.items()}
    results["unobservable_configs"] = [f"{c} / inst{i}" for c, i in sorted(UNOBSERVABLE)]
    return ok


def diff(results, seed, max_examples, quick=False):
    """Differential testing of prod/jetprot_prod.py against the Bend model, with a fixed seed (serial)."""
    bridge = Bridge()
    assert prod.from_bend(bridge.ask({"init": True})["state"]) == prod.init()
    traces = diff_strategies()
    plan = diff_plan(quick)
    recs = []
    for gen_name, inst, cfg_name, bugs in plan:
        rec = diff_run(bridge, traces[gen_name], gen_name, inst, cfg_name, bugs, seed, max_examples)
        recs.append(rec)
        print(diff_report(rec, max_examples))
    bridge.close()
    for b in prod.BUGS:
        prod.BUGS[b] = False
    return diff_finish(results, plan, recs, seed, max_examples)


_DIFF_WORKER = {}


def diff_task(i, seed, max_examples, quick):
    """Worker: differential run number i of diff_plan(quick), on this worker's own bridge."""
    if "bridge" not in _DIFF_WORKER:
        from multiprocessing import util
        bridge = Bridge()
        assert prod.from_bend(bridge.ask({"init": True})["state"]) == prod.init()
        util.Finalize(None, bridge.close, exitpriority=10)
        _DIFF_WORKER["bridge"], _DIFF_WORKER["traces"] = bridge, diff_strategies()
    gen_name, inst, cfg_name, bugs = diff_plan(quick)[i]
    try:
        return diff_run(_DIFF_WORKER["bridge"], _DIFF_WORKER["traces"][gen_name], gen_name, inst, cfg_name, bugs, seed, max_examples)
    finally:
        for b in prod.BUGS:
            prod.BUGS[b] = False


# ---------------------------------------------------------------------------------------------
# Re-check (serial) and the parallel scheduler
# ---------------------------------------------------------------------------------------------
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


def run_parallel(stage, results, seed, max_examples, full, jobs):
    """--jobs N > 1: the Bend checks in a thread pool, concurrently with every Python task in one
    process pool (longest first: the 76 mutants, C2, C5, C3, the 17 flags, the differential runs).
    The results dict is then filled in the serial key order, whatever the completion order."""
    import recheck
    from concurrent.futures import ThreadPoolExecutor
    say = recheck.say
    T0 = time.perf_counter()
    quick = stage == "quick"
    want_gates = stage in ("quick", "proofs", "all")
    checks = ("C5", "C2", "C3") if stage in ("recheck", "all") else ()
    want_c6 = stage in ("mutants", "all")
    plan = diff_plan(quick) if stage in ("quick", "diff", "all") else []
    marks = {}

    gthread = gfut = None
    gate_res = {}
    with _GATE_LOCK:   # a fresh start for the abort machinery (before the gates thread exists)
        _ABORT.clear()
        _PENDING.clear()
    if want_gates:
        def run_gates():
            try:
                return gates_parallel(gate_res, QUICK_PROOFS if quick else PROOFS, 1 if quick else None, jobs, say)
            finally:
                marks["proofs"] = time.perf_counter() - T0
        gthread = ThreadPoolExecutor(max_workers=1)
        gfut = gthread.submit(run_gates)

    tasks = []
    if want_c6:
        tasks += recheck.mutant_tasks(full)
    tasks += [(recheck.check_task, (w,), ("chk", w)) for w in ("C2", "C5", "C3") if w in checks]
    if want_c6:
        tasks += recheck.flag_tasks()
    tasks += [(diff_task, (i, seed, max_examples, quick), ("diff", i)) for i in range(len(plan))]
    n_c6 = sum(1 for t in tasks if t[2][0] in ("mut", "flag"))
    parts, chk, recs = {}, {}, {}

    def on_result(tag, res):
        kind = tag[0]
        if kind in ("mut", "flag"):
            recheck.c6_progress(parts, tag, res)
            if len(parts) == n_c6:
                marks["C6"] = time.perf_counter() - T0
        elif kind == "chk":
            which, rec, ok_, text = res
            chk[which] = (rec, ok_)
            marks[which] = time.perf_counter() - T0
            say(text)
        else:
            recs[tag[1]] = res
            say(diff_report(res, max_examples) + f"  [{len(recs)}/{len(plan)}]")
            if len(recs) == len(plan):
                marks["diff"] = time.perf_counter() - T0

    # beside the Bend checks the pool is capped and runs below normal priority (so do the node
    # bridges its workers start); the bash/bun processes of the checks keep normal priority
    npool = pool_size(jobs, want_gates)
    if tasks:
        say(f"[pool] {min(npool, len(tasks))} Python worker(s)"
            + (f", below normal priority, beside at most {min(jobs, MAX_BEND_PROCS)} Bend check(s)" if want_gates else ""))
    try:
        recheck.run_pool(tasks, npool, on_result, low_prio=want_gates)
        gates_ok = gfut.result() if gfut else True
    except BaseException:
        say("[FAIL] parallel gate aborted: cancelling the queued Bend checks, killing the running ones")
        _abort_gates()
        raise
    finally:
        if gthread:
            gthread.shutdown(wait=False)

    ok = True
    if want_gates:
        ok &= gates_ok
        results["gates"] = gate_res["gates"]
    if checks or want_c6:
        rc = results.setdefault("recheck", {})
        rok = True
        for w in ("C5", "C2", "C3"):
            if w in checks:
                rc[w] = chk[w][0]
                if w != "C3":   # C3 is a report, not a gate (as in the serial path)
                    rok &= chk[w][1]
        if want_c6:
            rok &= recheck.c6_assemble(rc, parts, full, T0, T0 + marks["C6"])   # the census's own wall time
        rc["all_ok"] = bool(rok)
        ok &= rok
    if plan:
        ok &= diff_finish(results, plan, [recs[i] for i in range(len(plan))], seed, max_examples, say)
    say("[time] wall-clock from the start of the stages, jobs " + str(jobs) + ": "
        + ", ".join(f"{k} {marks[k]:.1f} s" for k in ("proofs", "C5", "C2", "C3", "C6", "diff") if k in marks))
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
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(line_buffering=True)   # progress stays visible when stdout is a file
    ap = argparse.ArgumentParser(prog="run.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stage", choices=["quick", "proofs", "diff", "recheck", "mutants", "all"],
                    help="the stage to run (the text above says what each one does and the measured times)")
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED, help=f"Hypothesis seed for the differential runs (default {DEFAULT_SEED})")
    ap.add_argument("--max-examples", type=int, default=None, help=f"traces per differential run (default {DEFAULT_MAX_EXAMPLES}; quick: {QUICK_MAX_EXAMPLES})")
    ap.add_argument("--json", metavar="PATH", default=None, help="write this stage's results to PATH (all: v3/results.json by default)")
    ap.add_argument("--full", action="store_true", help="mutants / all: also count how many laws catch each mutant (the longest part of the gate)")
    ap.add_argument("--jobs", type=int, default=default_jobs(),
                    help=f"parallel jobs (default cpu_count - 4 = {default_jobs()} here; 1 = the serial path)")
    args = ap.parse_args(argv)
    if os.environ.get("BEND_BIN"):
        # env/bend.sh would run the Bend checks on that binary, while the bridge (C5 and the differential
        # runs) loads the source checkout and the provenance block records BEND_SRC's commit
        ap.error("unset BEND_BIN: the gate's Bend checks and its bridge must both use the pinned source "
                 "checkout (BEND_SRC), the one the provenance block records")
    stage = args.stage
    jobs = max(1, args.jobs)
    max_examples = args.max_examples or (QUICK_MAX_EXAMPLES if stage == "quick" else DEFAULT_MAX_EXAMPLES)
    t0 = time.perf_counter()
    results = {"stage": stage, "provenance": provenance(args.seed, max_examples, jobs)}
    prov = results["provenance"]
    print(f"[prov] {prov['bend']['version']} @ {prov['bend']['commit'][:12]}, python {prov['python']}, "
          f"hypothesis {prov['hypothesis']}, seed {args.seed}, max_examples {max_examples}, jobs {jobs}")
    ok = True
    if jobs > 1:
        ok &= run_parallel(stage, results, args.seed, max_examples, args.full, jobs)
    elif stage == "quick":
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
