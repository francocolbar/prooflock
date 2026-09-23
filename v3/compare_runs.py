"""compare_runs.py - leaf-by-leaf comparison of two gate runs (v3/results.json and v3/recheck.json).

What it proves. When it prints IDENTICAL, the two runs recorded the same thing: every leaf value with
its JSON type, every dict's keys in the same ORDER and every list in the same order and length, in
both files, apart from the ignored keys (by default only wall times and run metadata, listed below).
So the verdicts, the minimal counterexamples, the mutants' catching laws and every count agree. It
also confirms that the walk really reached every mutant's caught_by (and caught_by_all, when both runs
used --full) and every differential run, so a truncated or empty file cannot pass vacuously. With a
repository root for the NEW side (inferred, or --root), it checks that the new results were produced
by the files on disk: every provenance.sha256 entry of the new side must match the file under the
root (an ignored entry included; one the baseline records must be present), and, when the new side
is ROOT/v3, ROOT/SHA256SUMS is checked like `sha256sum -c`. It proves nothing about the proofs
themselves (the gate does that) and nothing about speed.

Default ignore rules (a rule is a path of keys from the top of each file; "*" matches one key,
"**" any number of them):
  ** / seconds                                wall times, at any depth
  provenance / timestamp_utc, host, jobs      when, where and how parallel the run was
  provenance / sha256 / v3/run.py, v3/recheck.py, v3/compare_runs.py
                                              the gate scripts, which may change between the runs
                                              without changing a result (the integrity check still
                                              covers them on the new side)

Usage: py -3.14 v3/compare_runs.py NEW OLD [options]
  NEW, OLD   a results directory (holding results.json, and recheck.json if the run wrote it), a
             repository root (its v3/ is used) or, both of them, a single .json file each.
  --root DIR          repository root of the NEW side for the integrity check (default: inferred
                      when NEW is a repository root or its v3/)
  --no-integrity      skip the integrity check
  --ignore JSON       add a rule, as a JSON list of keys, e.g. '["provenance", "bend", "commit"]'
  --ignore-key NAME   add the rule ["**", NAME]
  --no-default-ignores  start from no rules (then only --ignore / --ignore-key apply)
  --expect-mutants N  mutants the C6 bank must hold (default 76; 0: any number)
  --list              list every difference but exit 0 (a report, not a gate)
Exit 0 iff IDENTICAL, coverage complete and INTEGRITY OK (or --list); 2 on a usage or input error.

Example: py -3.14 v3/compare_runs.py v3 path/to/baseline_run
"""
import argparse
import hashlib
import json
import os
import sys

DEFAULT_RULES = [("**", "seconds"),
                 ("provenance", "timestamp_utc"), ("provenance", "host"), ("provenance", "jobs"),
                 ("provenance", "sha256", "v3/run.py"), ("provenance", "sha256", "v3/recheck.py"),
                 ("provenance", "sha256", "v3/compare_runs.py")]
FILES = ("results.json", "recheck.json")
EXPECT_MUTANTS = 76


def file_sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def matches(rule, path):
    """Does the key path (a tuple of dict keys and list indices) match the rule?"""
    if not rule:
        return not path
    head, rest = rule[0], rule[1:]
    if head == "**":
        return any(matches(rest, path[i:]) for i in range(len(path) + 1))
    return bool(path) and (head == "*" or head == str(path[0])) and matches(rest, path[1:])


class Cmp:
    def __init__(self, rules):
        self.rules = rules
        self.leaves = 0
        self.diffs = []
        self.visited = set()   # paths of every node compared (for the coverage confirmations)

    def ignored(self, path, key):
        return any(matches(r, path + (key,)) for r in self.rules)

    @staticmethod
    def fmt(path):
        return "".join(f"[{p!r}]" for p in path) or "<root>"

    def cmp(self, a, b, path=()):
        self.visited.add(path)
        if type(a) is not type(b):
            self.leaves += 1
            self.diffs.append(f"{self.fmt(path)}: type {type(a).__name__} != {type(b).__name__}: {a!r:.200} vs {b!r:.200}")
            return
        if isinstance(a, dict):
            ka = [k for k in a if not self.ignored(path, k)]
            kb = [k for k in b if not self.ignored(path, k)]
            if ka != kb:
                if set(ka) == set(kb):
                    self.diffs.append(f"{self.fmt(path)}: same keys, different ORDER: {ka} vs {kb}")
                else:
                    self.diffs.append(f"{self.fmt(path)}: keys only in new {[k for k in ka if k not in b]}, "
                                      f"only in baseline {[k for k in kb if k not in a]}")
            if not ka and not kb:
                self.leaves += 1   # an empty dict is a leaf
            for k in ka:
                if k in b:
                    self.cmp(a[k], b[k], path + (k,))
            return
        if isinstance(a, list):
            if len(a) != len(b):
                self.diffs.append(f"{self.fmt(path)}: list length {len(a)} != {len(b)}")
            if not a and not b:
                self.leaves += 1   # an empty list is a leaf
            for i, (x, y) in enumerate(zip(a, b)):
                self.cmp(x, y, path + (i,))
            return
        self.leaves += 1
        if a != b:
            self.diffs.append(f"{self.fmt(path)}: {a!r:.300} != {b!r:.300}")


def c6_bank(doc):
    """(path prefix, bank) of the C6 bank: under "recheck" in results.json, at the top in recheck.json."""
    for prefix in (("recheck",), ()):
        node = doc
        for p in prefix:
            node = node.get(p) if isinstance(node, dict) else None
        if isinstance(node, dict) and isinstance(node.get("C6"), dict) and isinstance(node["C6"].get("bank"), dict):
            return prefix, node["C6"]["bank"]
    return None, None


def coverage(c, new, old, label, expect_mutants):
    """Every mutant's caught_by (and caught_by_all when both runs used --full) and every
    differential run must have been compared. Returns True iff complete."""
    ok = True
    prefix, bank = c6_bank(new)
    _, old_bank = c6_bank(old)
    if bank is not None:
        names = list(bank)
        base = prefix + ("C6", "bank")
        cb = sum(1 for n in names if base + (n, "caught_by") in c.visited)
        line = f"  {label}: caught_by compared for {cb}/{len(names)} mutants"
        ok &= cb == len(names) and (not expect_mutants or len(names) == expect_mutants)
        if expect_mutants and len(names) != expect_mutants:
            line += f" (the bank must hold {expect_mutants})"
        full_new = bool(names) and all(isinstance(r, dict) and "caught_by_all" in r for r in bank.values())
        full_old = bool(old_bank) and all(isinstance(r, dict) and "caught_by_all" in r for r in old_bank.values())
        if full_new and full_old:
            cba = sum(1 for n in names if base + (n, "caught_by_all") in c.visited)
            line += f", caught_by_all for {cba}/{len(names)}"
            ok &= cba == len(names)
        else:
            line += "; caught_by_all not checked (not both runs --full)"
        print(line)
    elif old_bank is not None:
        print(f"  {label}: the baseline has a C6 bank, the new run has none")
        ok = False
    if isinstance(new.get("diff"), list):
        runs = len(new["diff"])
        seen = sum(1 for i in range(runs) if ("diff", i) in c.visited)
        print(f"  {label}: differential runs compared: {seen}/{runs}")
        ok &= seen == runs and runs > 0
    elif isinstance(old.get("diff"), list):
        print(f"  {label}: the baseline has differential runs, the new run has none")
        ok = False
    return ok


def integrity_provenance(new, old, root, rules, label):
    """Every provenance.sha256 entry of the NEW side must match the file under root; an entry the
    rules ignore in the comparison must be present when the baseline records it. Returns problems."""
    prov = new.get("provenance") if isinstance(new, dict) else None
    if not isinstance(prov, dict) or not isinstance(prov.get("sha256"), dict) or not prov["sha256"]:
        return [f"{label}: no provenance.sha256 block on the new side"]
    table, probs = prov["sha256"], []
    old_table = ((old.get("provenance") or {}).get("sha256") or {}) if isinstance(old, dict) else {}
    for relp in old_table:
        if relp not in table and any(matches(r, ("provenance", "sha256", relp)) for r in rules):
            probs.append(f"{label}: provenance.sha256 has no entry for {relp} (ignored in the comparison, recorded by the baseline)")
    checked = 0
    for relp, recorded in table.items():
        p = os.path.join(root, *relp.split("/"))
        if not os.path.isfile(p):
            probs.append(f"{label}: provenance.sha256[{relp!r}]: file missing on disk ({p})")
            continue
        checked += 1
        actual = file_sha256(p)
        if actual != recorded:
            probs.append(f"{label}: provenance.sha256[{relp!r}] = {recorded[:12]}... but the file on disk is {actual[:12]}... (stale)")
    print(f"  {label}: integrity: {checked}/{len(table)} provenance.sha256 entries hashed against {root}, {len(probs)} problem(s)")
    return probs


def integrity_sums(root):
    """ROOT/SHA256SUMS, checked like `sha256sum -c`. Returns problems."""
    path = os.path.join(root, "SHA256SUMS")
    if not os.path.isfile(path):
        return [f"SHA256SUMS: missing ({path})"]
    probs, n = [], 0
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if not line.strip():
                continue
            digest, _, relp = line.partition("  ")
            p = os.path.join(root, *relp.split("/"))
            n += 1
            if not os.path.isfile(p):
                probs.append(f"SHA256SUMS: {relp}: file missing")
            elif file_sha256(p) != digest:
                probs.append(f"SHA256SUMS: {relp}: FAILED")
    print(f"SHA256SUMS: {n} lines checked against {root}, {len(probs)} FAILED/missing")
    if n == 0:
        probs.append("SHA256SUMS: empty")
    return probs


def results_dir(p):
    """A results directory: p itself, or p/v3 when p is a repository root."""
    if os.path.isfile(os.path.join(p, "results.json")):
        return p
    if os.path.isfile(os.path.join(p, "v3", "results.json")):
        return os.path.join(p, "v3")
    print(f"compare_runs: no results.json in {p} or {os.path.join(p, 'v3')}", file=sys.stderr)
    raise SystemExit(2)


def infer_root(new_dir):
    """The repository root of a results directory named v3 inside a repository, else None."""
    d = os.path.abspath(new_dir)
    if os.path.basename(d) == "v3" and os.path.isfile(os.path.join(d, "run.py")):
        return os.path.dirname(d)
    return None


def load(p):
    """A results file, or exit 2 (an input error, not a difference) if it cannot be read as JSON."""
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError) as e:
        print(f"compare_runs: cannot read {p}: {e}", file=sys.stderr)
        raise SystemExit(2)


def main(argv=None):
    ap = argparse.ArgumentParser(prog="compare_runs.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("new", help="the new run: results directory, repository root or .json file")
    ap.add_argument("old", help="the baseline: results directory, repository root or .json file")
    ap.add_argument("--root", default=None, help="repository root of the new side, for the integrity check")
    ap.add_argument("--no-integrity", action="store_true", help="skip the integrity check")
    ap.add_argument("--ignore", action="append", default=[], metavar="JSON", help="an extra ignore rule, a JSON list of keys")
    ap.add_argument("--ignore-key", action="append", default=[], metavar="NAME", help="ignore this key at any depth")
    ap.add_argument("--no-default-ignores", action="store_true", help="drop the default ignore rules")
    ap.add_argument("--expect-mutants", type=int, default=EXPECT_MUTANTS, metavar="N", help=f"mutants in the C6 bank (default {EXPECT_MUTANTS}; 0: any)")
    ap.add_argument("--list", action="store_true", help="list the differences and exit 0")
    args = ap.parse_args(argv)

    rules = [] if args.no_default_ignores else [tuple(r) for r in DEFAULT_RULES]
    for r in args.ignore:
        try:
            rule = json.loads(r)
        except ValueError as e:
            ap.error(f"--ignore {r!r}: not JSON ({e})")
        if not isinstance(rule, list) or not rule or not all(isinstance(k, str) for k in rule):
            ap.error(f"--ignore {r!r}: must be a non-empty JSON list of strings")
        rules.append(tuple(rule))
    rules += [("**", k) for k in args.ignore_key]

    new_dir = None
    if os.path.isfile(args.new) and os.path.isfile(args.old):
        pairs = [(args.new, args.old, os.path.basename(args.new))]
    elif os.path.isdir(args.new) and os.path.isdir(args.old):
        new_dir, old_dir = results_dir(args.new), results_dir(args.old)
        pairs = [(os.path.join(new_dir, f), os.path.join(old_dir, f), f) for f in FILES
                 if os.path.isfile(os.path.join(new_dir, f)) or os.path.isfile(os.path.join(old_dir, f))]
    else:
        ap.error("NEW and OLD must be two directories or two .json files")

    root = None
    if not args.no_integrity:
        root = os.path.abspath(args.root) if args.root else (infer_root(new_dir) if new_dir else None)

    total_leaves, all_diffs, cover_ok, integ = 0, [], True, []
    for new, old, label in pairs:
        print(f"comparing {label}:\n  new      {new}\n  baseline {old}")
        missing = [p for p in (new, old) if not os.path.isfile(p)]
        if missing:
            all_diffs.append(f"{label}: present on one side only (missing: {', '.join(missing)})")
            print(f"  {label}: present on one side only")
            continue
        a, b = load(new), load(old)
        c = Cmp(rules)
        c.cmp(a, b)
        print(f"  {label}: {c.leaves} leaves compared, {len(c.diffs)} differences")
        cover_ok &= coverage(c, a, b, label, args.expect_mutants)
        if root:
            integ += integrity_provenance(a, b, root, rules, label)
        total_leaves += c.leaves
        all_diffs += [f"{label} {d}" for d in c.diffs]
    if root and new_dir and os.path.abspath(new_dir) == os.path.join(root, "v3"):
        integ += integrity_sums(root)

    print(f"TOTAL: {total_leaves} leaves compared over {len(pairs)} file pair(s); coverage checks {'complete' if cover_ok else 'INCOMPLETE'}")
    print("ignored: " + ("; ".join(" / ".join(r) for r in rules) if rules else "nothing"))
    if not root:
        print("integrity: not checked" + (" (--no-integrity)" if args.no_integrity else " (no repository root for the new side; pass --root)"))
    elif integ:
        print(f"INTEGRITY FAILED ({len(integ)}):")
        for d in integ:
            print("  " + d)
    else:
        print("INTEGRITY OK")
    if all_diffs:
        print(f"DIFFERENCES ({len(all_diffs)}):")
        for d in all_diffs:
            print("  " + d)
    if not cover_ok:
        print("coverage incomplete (see above)")
    if all_diffs or not cover_ok or integ:
        verdict = "NOT IDENTICAL" if all_diffs or not cover_ok else "IDENTICAL CONTENT, BUT INTEGRITY FAILED"
        print(verdict + (" (--list: exit 0)" if args.list else ""))
        return 0 if args.list else 1
    print("IDENTICAL")
    return 0


if __name__ == "__main__":
    sys.exit(main())
