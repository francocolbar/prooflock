# Spike environment (pinned versions, 2026-09-18; re-checked 2026-09-23 with the Bend 2.0.25 pin)

| Component | Version | How it was obtained |
|---|---|---|
| Windows | 11 Pro 10.0.26200, no WSL, no clang | — |
| Bend 2 | `bend 2.0.25`, source `github.com/bendlang/bend` (formerly `github.com/HigherOrderCO/Bend`, which redirects there) commit `c65bcb788dbfb298bb434c1d858b47c193841dc0` (tag `v2.0.25`, released 2026-09-21) in `~/.bend-src`; the pin lives in `env/bend.sh` (`BEND_COMMIT`, and `BEND_VERSION` for what it prints) and the runner refuses to run with any other commit | `bash env/bend.sh version` (clones the pinned commit if missing; `--update` re-checks it, `--update <commit>` moves the pin) |
| bun | 1.3.11 (`~/.bun/bin/bun`) | already installed |
| node | 22.22.2 | already installed |
| Python | 3.14.3 (`py -3.14`) | already installed |
| jax / numpy | 0.11.2 / 2.4.3 (CPU) | `py -3.14 -m pip install jax` (installed in this spike) |
| sympy | 1.14.0 | already installed (reference for comparing code size) |

## Compiler pin and provenance (2026-09-23)

- Commit `c65bcb788dbfb298bb434c1d858b47c193841dc0` = tag `v2.0.25` = `bend 2.0.25` (GitHub release "Bend 2.0.25",
  2026-09-21); source tree hash (`git rev-parse HEAD^{tree}`): `b33c22a28fb0c83e209fee7cf6aba81b217bd74e`. Apache 2.0
  source, 76 MB without `.git`. The working checkout is `~/.bend-src` (`BEND_SRC`); `env/bend.sh` refuses to run with
  any other commit (exit 2) and with a `BEND_BIN` binary that does not print `bend 2.0.25` (exit 4). The checkout is
  shared: every project on the machine that runs this `env/bend.sh` with the default `BEND_SRC` uses the same
  `~/.bend-src`, so `--update <commit>` moves the compiler for all of them (it takes only a full 40-hex SHA, exit 5
  otherwise, and rewrites the pin in `env/bend.sh` only after the fetch succeeded: a failed fetch, exit 3, leaves the
  pin unchanged); a project that must stay on another commit needs its own copy of the runner, pinned to that commit,
  and its own checkout (`BEND_SRC`), since this runner refuses any other commit.
- **Pin moved on 2026-09-23** from `e52cda47a58967aa65d1eb26efe8f42a0b0407df` (`bend 2.0.24`, tree
  `f741f100c37b268628f4490fd1135a957869e0aa`, pinned on 2026-09-21), the compiler of the serial run of 2026-09-22,
  which was the reference run until that of 2026-09-23. For the checker, 2.0.25 closes two holes in how literals are
  checked (`bend2/bend.ts`; upstream `CHANGELOG.md`): a file that declared its own `Nat` could have `1n` admitted by
  name and derive a closed `Empty` (#941), and an array count past the nat cap made a fractional literal that defeated
  termination (#954). Neither reaches prooflock, on either pin: it declares no `Nat` or `String` of its own and uses
  no arrays. The rest of the release is compiler, effect and loader work. On the new pin, the same day:
  `bash env/check_env.sh` 13 PASS and `py -3.14 v3/run.py quick` ok. The full gate followed:
  `py -3.14 v3/run.py all --full` passed in 1 728.9 s and in 1 299.8 s, again after the edits to comments, docstrings
  and the `concretize` comparison of C6 `equivalence` in 1 199.8 s, and once more after the closing fixes of the day
  (among them the exact Bend version check of `env/check_env.sh` and the `--update` validation of `env/bend.sh`) in
  1 306.1 s, after a further change to `env/bend.sh` (it no longer fetches into a non-empty directory that holds no
  Bend checkout) in 1 226.0 s, and a last time after a comment in the header of `v3/LAWS_JETPROT_LIVE.bend` (the two
  response theorems are checked for the model's limits only) in 1 222.4 s, the committed `v3/results.json`;
  `py -3.14 v3/compare_runs.py` between the latter and the 2.0.24 run of 2026-09-22 found the same verdicts, counts,
  mutant census and differential traces over 6 433 leaves; apart from wall times and run metadata, the two runs differ
  only in the Bend version and commit, the hashes of the files edited in between (the gate scripts included), the new
  C6 `equivalence` field and the descriptions of five mutants whose assumption numbers were corrected. After that run:
  `sha256sum -c SHA256SUMS` 42 OK and `bash env/check_env.sh` 13 PASS, 0 FAIL.
- **Upstream**: on 2026-09-21 (~19:40 UTC) `github.com/HigherOrderCO/Bend` started redirecting to `github.com/bendlang/bend`,
  which then answered 404 anonymously (private or deleted). The fetch by SHA that `bend.sh` performs on an empty checkout (verified at
  15:30 the same day: 107 MB, 4.3 s) stopped working: the script failed with exit 3 without opening credential
  dialogs.
- **2026-09-22**: public again at `github.com/bendlang/bend`. Anonymous `git ls-remote` answered again on both
  `github.com/bendlang/bend` and `github.com/HigherOrderCO/Bend` (the URL `bend.sh` used until 2026-09-23), HEAD
  `ff7a40cc9070…`; the commit then pinned was present, an ancestor of `main`, with tree `f741f100c37b…`; and
  `BEND_SRC=<empty dir> bash env/bend.sh --update` fetched it by SHA again (exit 0, 7 s, 107 MB, HEAD `e52cda47…`, tree
  `f741f100…`).
- **2026-09-23**: `env/bend.sh` fetches from `BEND_REPO=https://github.com/bendlang/bend`, whatever remote the checkout
  has; `github.com/HigherOrderCO/Bend` answers 301 to it. Anonymous `git ls-remote` answers on both (HEAD
  `ff7a40cc9070…`; tag `v2.0.25` at `c65bcb78…`, an ancestor of `main`, 4 commits behind it), and
  `BEND_SRC=<empty dir> bash env/bend.sh --update` fetches the pinned commit by SHA (exit 0, 6.3 s, 107 MB, HEAD
  `c65bcb78…`, tree `b33c22a2…`).
- **If the upstream becomes unreachable again** (`--update` then fails with exit 3), the alternative routes are, in order:
  1. `BEND_SRC` pointing at a checkout of the commit obtained by other means (a copy of an existing checkout such as
     this machine's `~/.bend-src`, a mirror, a fork), verified with `git rev-parse HEAD HEAD^{tree}` against the two
     hashes above. The runner fetches only when `bend2/main.ts` is missing, so it then needs no network.
  2. `BEND_BIN=/path/to/bend` with a binary from the official installer, Linux/macOS only
     (`curl -fsSL https://bend-lang.com/install.sh | sh`), which must report exactly `bend 2.0.25`. On 2026-09-23 that
     script installs 2.0.25 (`VER="2.0.25"`), but it downloads the archive from the GitHub releases of
     `bendlang/bend`: this route needs those files reachable, or a binary installed beforehand. It covers
     `bash env/bend.sh` only: `v3/bridge_client.py` (C5 and every differential run, `quick` included) loads
     `bend2/main.ts` from `BEND_SRC`, `env/check_env.sh` checks that checkout (the pin and interop C checks) and the
     provenance block of `v3/run.py` records its commit, so `v3/run.py` still needs route 1 or 3 (and refuses to start
     while `BEND_BIN` is set).
  3. Vendoring the source tree into the repo (decision pending from the author: the README states that the compiler
     is not vendored).

## How to run Bend here
There is no native `bend` on Windows. Everything goes through the portable runner, which executes the compiler with bun from the checkout:

```bash
export BEND_NO_TELEMETRY=1
alias bend='bash env/bend.sh'   # the runner lives in the repo
bend archivo.bend            # checks types/termination/proofs and runs main (JS backend)
bend PROOF.bend              # gate: must print the literal line "All terms check."
bend archivo.bend -o out.js  # emits JS (runs with node or bun)
```

Limitations of this machine (documented in the skill, verified today):
- No native binaries or GPU (needs clang ≥ 14 and POSIX; the C runtime does not compile on Windows). Everything runs on the JS backend, each check sequentially; `v3/run.py --jobs` runs up to 8 checks at once, as separate processes.
- Effects that work: `IO.print/write`, `IO.get_env` (existing variable), `File.open/write/close`, channels. Not working: `IO.sleep`, `File.read`, sockets, and any `Fail` result (they call libc via `bun:ffi`).
- Paths always with `/` slashes.

## Verification
```bash
bash env/check_env.sh      # from the repo root: prints the versions, then PASS/FAIL for each of the 13 checks
```
The log of the reference run (2026-09-23, `bend 2.0.25`, 13 PASS) is in `env/check_env.log`, which is not
committed (`.gitignore`).
