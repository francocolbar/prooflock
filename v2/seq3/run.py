"""run.py (seq3) - the Phase 2 driver on the redesigned model: gates (reflection proofs,
finite certificate, equivalence with seq/seq.bend, exhaustive smoke) + the same differential testing.
Original: ../seq/run.py. """
"""seq3 driver: gates + differential testing of the Bend golden model
against the Python "production" sequencer (prod/sequencer_prod.py) with planted bugs.

  gates : every PROOF file prints "All terms check."; the exhaustive runtime grid has no
          FALSE line; the negative test (tests/seq_bug_PROOF.bend) is REJECTED.
  diff  : Hypothesis generates random event traces; for each configuration of planted
          bugs it searches for a trace on which (a) the production trajectory differs
          from the golden model's, or (b) the Bend invariants (inv_all, evaluated by
          Bend on the production states) are violated. Hypothesis shrinks the failing
          trace to a minimal one. With no bugs, N examples must pass.

Usage: py -3.14 bend-spike/v2/seq/run.py            Writes: results.json
"""
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
V2 = os.path.dirname(HERE)
BEND = ["bash", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "env", "bend.sh")]
LOADER = "file:///" + os.path.expanduser("~/.bend-src/bend2/main.ts").replace("\\", "/").lstrip("/")
sys.path.insert(0, os.path.join(HERE, "prod"))
import sequencer_prod as prod  # noqa: E402

EVENTS = ([{"$": "Tick"}] * 4 + [{"$": "Heartbeat"}] * 3 +
          [{"$": "Vac", "ok": True}, {"$": "Vac", "ok": False}, {"$": "Tf", "ok": True}, {"$": "Tf", "ok": False},
           {"$": "Dens", "ok": True}, {"$": "Dens", "ok": False}, {"$": "CmdCharge"}, {"$": "CmdPuff"},
           {"$": "CmdBreakdown"}, {"$": "CmdFlatTop"}, {"$": "CmdHeatOn"}, {"$": "CmdHeatOff"},
           {"$": "CmdRampDown"}, {"$": "Disruption"}, {"$": "Abort"}, {"$": "Reset"}])
PROOFS = ["seq3/PROOF_SEQ3.bend", "seq3/PROOF_SEQ3_SAME.bend"]   # PROOF_SEQ3_FIN is imported by PROOF_SEQ3
MAX_EXAMPLES = 3000


class Bridge:
    """A persistent node process running the Bend model through the JS loader."""

    def __init__(self):
        self.p = subprocess.Popen(["node", "--import", LOADER, "bridge.mjs"], cwd=HERE, stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
        self.calls = 0

    def ask(self, req):
        self.p.stdin.write(json.dumps(req) + "\n")
        self.p.stdin.flush()
        line = self.p.stdout.readline()
        if not line:
            sys.exit("bridge died: " + self.p.stderr.read())
        self.calls += 1
        return json.loads(line)

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=10)


def bend(rel):
    r = subprocess.run(BEND + [os.path.basename(rel)], cwd=os.path.join(V2, os.path.dirname(rel)),
                       env=dict(os.environ, BEND_NO_TELEMETRY="1"), capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


def main():
    results = {"gates": {}, "diff": [], "max_examples": MAX_EXAMPLES}
    ok_all = True

    # --- gates ---
    for rel in PROOFS:
        t0 = time.perf_counter()
        code, out, err = bend(rel)
        dt = time.perf_counter() - t0
        exists = os.path.exists(os.path.join(V2, rel))
        passed = exists and "All terms check." in out
        results["gates"][rel] = {"result": (out.strip().splitlines() or [""])[-1] if exists else "MISSING", "seconds": round(dt, 2)}
        ok_all &= passed
        print(f"[gate] {rel:28} -> {results['gates'][rel]['result']}  ({dt:.1f} s)")
    code, out, err = bend("tests/laws_seq3_smoke.bend")
    passed = code == 0 and "ok" in out and not any(ln.startswith("FALSE") for ln in out.splitlines())
    results["gates"]["tests/laws_seq3_smoke.bend"] = "all ok" if passed else out[-300:]
    ok_all &= passed
    print(f"[gate] tests/laws_seq3_smoke.bend   -> {results['gates']['tests/laws_seq3_smoke.bend']}")
    code, out, err = bend("tests/seq_bug_PROOF.bend")
    rejected = code != 0 and "True{}" in (out + err) and "False{}" in (out + err)
    results["gates"]["tests/seq_bug_PROOF.bend"] = "REJECTED (as it must be)" if rejected else f"NOT rejected: exit {code}"
    ok_all &= rejected
    print(f"[gate] tests/seq_bug_PROOF.bend      -> {results['gates']['tests/seq_bug_PROOF.bend']}")

    # --- differential testing ---
    from hypothesis import strategies as st, find, settings, HealthCheck  # noqa: E402
    from hypothesis.errors import NoSuchExample  # noqa: E402

    bridge = Bridge()
    # sanity: the bridge and the production model agree on the initial state
    assert prod.from_bend(bridge.ask({"init": True})["state"]) == prod.init()

    def failure(trace):
        """Which oracle fails on this trace with the current BUGS: 'trajectory', 'invariant', both, or none."""
        golden = bridge.ask({"trace": trace})
        mine = prod.run(trace)
        traj = [prod.from_bend(s) for s in golden["states"]] != mine
        invs = bridge.ask({"check": [prod.to_bend(s) for s in mine]})["invs"]
        inv = not all(invs)
        return traj, inv

    # two generators: plain random traces, and "guided" ones that start with a prefix of the
    # happy path (so deep phases such as RampDown are actually reached) followed by random events
    happy = [{"$": "Vac", "ok": True}, {"$": "CmdCharge"}, {"$": "Tf", "ok": True}, {"$": "CmdPuff"},
             {"$": "CmdBreakdown"}, {"$": "CmdFlatTop"}, {"$": "Dens", "ok": True}, {"$": "CmdHeatOn"},
             {"$": "CmdRampDown"}]
    plain = st.lists(st.sampled_from(EVENTS), min_size=0, max_size=40)
    guided = st.builds(lambda k, rest: happy[:k] + rest, st.integers(0, len(happy)),
                       st.lists(st.sampled_from(EVENTS), min_size=0, max_size=30))
    generators = [("random", plain), ("guided", guided)]
    configs = [
        ("no bugs", {"watchdog_off_by_one": False, "rampdown_not_plasma": False}),
        ("watchdog_off_by_one", {"watchdog_off_by_one": True, "rampdown_not_plasma": False}),
        ("rampdown_not_plasma", {"watchdog_off_by_one": False, "rampdown_not_plasma": True}),
        ("both bugs", {"watchdog_off_by_one": True, "rampdown_not_plasma": True}),
    ]
    found_by = {}
    for gen_name, traces in generators:
      for cfg_name, bugs in configs:
          name = f"{cfg_name} / {gen_name}"
          prod.BUGS.update(bugs)
          calls0 = bridge.calls
          t0 = time.perf_counter()
          try:
              minimal = find(traces, lambda tr: any(failure(tr)),
                             settings=settings(max_examples=MAX_EXAMPLES, database=None, deadline=None,
                                               suppress_health_check=list(HealthCheck)))
              traj, inv = failure(minimal)
              rec = {"config": cfg_name, "generator": gen_name, "found": True, "minimal_trace": [e["$"] + ("" if "ok" not in e else ("+" if e["ok"] else "-")) for e in minimal],
                     "trajectory_differs": traj, "invariant_violated": inv,
                     "final_prod_state": prod.run(minimal)[-1] if minimal else prod.init()}
              expected = any(bugs.values())
          except NoSuchExample:
              rec = {"config": cfg_name, "generator": gen_name, "found": False}
              expected = not any(bugs.values())
          rec["seconds"] = round(time.perf_counter() - t0, 1)
          rec["bridge_calls"] = bridge.calls - calls0
          rec["as_expected"] = expected
          # a false positive (a "bug" found with no bugs planted) fails the gate; a bug that one
          # generator misses is a finding, judged per config below (some generator must find it)
          if rec["found"]:
              ok_all &= any(bugs.values())
          found_by[cfg_name] = found_by.get(cfg_name, False) or rec["found"]
          results["diff"].append(rec)
          if rec["found"]:
              print(f"[diff] {name:32} -> BUG FOUND, minimal trace ({len(rec['minimal_trace'])} events): {' '.join(rec['minimal_trace'])}")
              print(f"       trajectory differs: {traj}; Bend invariant violated on prod states: {inv}; "
                    f"final prod state: {rec['final_prod_state']['phase']} hb={rec['final_prod_state']['hb']} "
                    f"vac={rec['final_prod_state']['vac']} tf={rec['final_prod_state']['tf']}  [{rec['seconds']} s, {rec['bridge_calls']} bridge calls]")
          else:
              print(f"[diff] {name:32} -> no counterexample in {MAX_EXAMPLES} traces  [{rec['seconds']} s, {rec['bridge_calls']} bridge calls]")
    bridge.close()
    for cfg_name, bugs in configs:
        must = any(bugs.values())
        ok_all &= (found_by[cfg_name] == must)
        print(f"[diff] {cfg_name:22} -> {'found' if found_by[cfg_name] else 'not found'} by some generator; expected {'found' if must else 'not found'}")
    results["found_by_some_generator"] = found_by

    results["all_ok"] = bool(ok_all)
    with open(os.path.join(HERE, "results.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, default=str)
    print(f"[done] all gates and checks ok: {ok_all}")
    sys.exit(0 if ok_all else 1)


if __name__ == "__main__":
    main()
