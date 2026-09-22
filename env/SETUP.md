# Spike environment (pinned versions, 2026-09-18)

| Component | Version | How it was obtained |
|---|---|---|
| Windows | 11 Pro 10.0.26200, no WSL, no clang | — |
| Bend 2 | `bend 2.0.24`, source `github.com/HigherOrderCO/Bend` (alias `bendlang/bend`) commit `e52cda47a58967aa65d1eb26efe8f42a0b0407df` (2026-09-21) in `~/.bend-src`; the pin lives in `env/bend.sh` (`BEND_COMMIT`) and the runner refuses to run with any other commit | `bash env/bend.sh version` (clones the pinned commit if missing; `--update` re-checks it, `--update <commit>` moves the pin) |
| bun | 1.3.11 (`~/.bun/bin/bun`) | already installed |
| node | 22.22.2 | already installed |
| Python | 3.14.3 (`py -3.14`) | already installed |
| jax / numpy | 0.11.2 / 2.4.3 (CPU) | `py -3.14 -m pip install jax` (installed in this spike) |
| sympy | 1.14.0 | already installed (reference for comparing code size) |

## Compiler pin and provenance (2026-09-21)

- Commit `e52cda47a58967aa65d1eb26efe8f42a0b0407df` = `bend 2.0.24`; source tree hash (`git rev-parse HEAD^{tree}`):
  `f741f100c37b268628f4490fd1135a957869e0aa`. Apache 2.0 source, 76 MB without `.git`. The working checkout is `~/.bend-src`
  (`BEND_SRC`); `env/bend.sh` refuses to run with any other commit (exit 2).
- **Upstream**: on 2026-09-21 (~19:40 UTC) `github.com/HigherOrderCO/Bend` started redirecting to `github.com/bendlang/bend`,
  which answers 404 anonymously (private or deleted). The fetch by SHA that `bend.sh` performs on an empty checkout (verified at
  15:30 the same day: 107 MB, 4.3 s) stops working: the script fails with exit 3 without opening credential
  dialogs. Alternative routes, in order: (1) `BEND_SRC` pointing at a checkout of the commit obtained by other means,
  verifiable with `git rev-parse HEAD HEAD^{tree}`; (2) `BEND_BIN=/path/to/bend` with the binary from the official installer
  (`curl -fsSL https://bend-lang.com/install.sh | sh`, Linux/macOS; the site is still online), which must report
  exactly `bend 2.0.24`; (3) vendoring the source tree into the repo (decision pending from the author: the README states
  that the compiler is not vendored).

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
- No native binaries or GPU (needs clang ≥ 14 and POSIX; the C runtime does not compile on Windows). Everything runs on the JS backend, sequentially.
- Effects that work: `IO.print/write`, `IO.get_env` (existing variable), `File.open/write/close`, channels. Not working: `IO.sleep`, `File.read`, sockets, and any `Fail` result (they call libc via `bun:ffi`).
- Paths always with `/` slashes.

## Verification
```bash
bash prooflock/env/check_env.sh      # prints versions and PASS/FAIL for each hello-world
```
The log of the reference run is in `env/check_env.log`.
