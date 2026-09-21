#!/usr/bin/env bash
# bend.sh - the repo's Bend 2 runner: runs the compiler with bun from a source checkout PINNED
# to one commit, so every gate in this repository is decided by the same compiler. Works on
# Windows (Git Bash, no WSL), Linux and macOS without a native toolchain: check, prove
# (`PROOF*.bend`), pure mains, IO mains on the JS backend, `-o file.js`, `bend base`, `bend
# guide`. Not available this way: native `-o bin` and the GPU (need clang + a POSIX C runtime).
# On Windows the JS effects that reach libc through bun:ffi fail (IO.sleep, File.read, sockets,
# any Fail result); print, get_env of an existing var, now, spawn, channels and File.write work.
# Always pass forward-slash paths.
#
# Usage: bash env/bend.sh <any bend arguments>     e.g. bash env/bend.sh v3/PROOF_JETPROT.bend
#        bash env/bend.sh version                  prints "bend 2.0.24"
#        bash env/bend.sh --update                 fetch and check out the pinned commit
#        bash env/bend.sh --update <commit>        move the pin to <commit> (rewrites this file) and check it out
#        BEND_SRC=/path/to/checkout bash env/bend.sh ...   (default: ~/.bend-src)
#        BEND_BIN=/path/to/bend bash env/bend.sh ...        use an installed `bend` binary instead of the source
#                                                           checkout (the official installer, curl -fsSL
#                                                           https://bend-lang.com/install.sh | sh, on Linux/macOS);
#                                                           it must report exactly "bend 2.0.24" or the runner refuses
#
# The pin is enforced: if $BEND_SRC exists at another commit the runner refuses to run (exit 2)
# and says how to fix it; it never moves a checkout it did not create. env/check_env.sh reports
# the same mismatch as a FAIL.
#
# Why the cd: main.ts resolves Base's effect files relative to the current directory when
# paths carry backslashes, so it must run from inside bend2/. File arguments are made
# absolute first so they still resolve from the caller's directory.
set -eu
BEND_VERSION="bend 2.0.24"
if [ -n "${BEND_BIN:-}" ]; then
  got=$("$BEND_BIN" version 2>/dev/null | tail -1 || true)
  if [ "$got" != "$BEND_VERSION" ]; then
    echo "bend.sh: BEND_BIN=$BEND_BIN reports '$got', this repository pins '$BEND_VERSION'." >&2; exit 4
  fi
  export BEND_NO_TELEMETRY=1
  exec "$BEND_BIN" "$@"
fi
BEND_COMMIT=e52cda47a58967aa65d1eb26efe8f42a0b0407df   # bend 2.0.24 (2026-09-21); moved only by --update <commit>
BEND_REPO=https://github.com/HigherOrderCO/Bend
SRC=${BEND_SRC:-$HOME/.bend-src}
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
export BEND_NO_TELEMETRY=1
if ! command -v bun >/dev/null 2>&1; then
  if [ -x "$HOME/.bun/bin/bun" ]; then PATH="$HOME/.bun/bin:$PATH"; else
    echo "bend.sh: bun is required (https://bun.sh: curl -fsSL https://bun.sh/install | bash, or on Windows: powershell -c \"irm bun.sh/install.ps1 | iex\")" >&2; exit 1; fi
fi

head_of() { git -C "$SRC" rev-parse HEAD 2>/dev/null || echo none; }

fetch_pin() { # create the checkout if missing, then fetch exactly the pinned commit and check it out.
  # Anonymous, never interactive: no terminal prompt and no credential helper, so an upstream that
  # answers 401/404 (the repository went private on 2026-09-21) fails here with a message instead
  # of opening a login dialog on every call.
  if [ ! -d "$SRC/.git" ]; then
    echo "bend.sh: fetching Bend $BEND_COMMIT into $SRC" >&2
    mkdir -p "$SRC" && git -C "$SRC" init -q && git -C "$SRC" remote add origin "$BEND_REPO"
  fi
  if ! GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= git -C "$SRC" -c credential.helper= fetch -q --depth 1 origin "$BEND_COMMIT"; then
    echo "bend.sh: could not fetch Bend $BEND_COMMIT from $BEND_REPO anonymously." >&2
    echo "bend.sh: if upstream is private or gone, point BEND_SRC at a checkout of that commit (bend 2.0.24) obtained" >&2
    echo "bend.sh: elsewhere; env/SETUP.md records the commit and the tree hash to verify it against." >&2
    exit 3
  fi
  git -C "$SRC" checkout -q --detach "$BEND_COMMIT"
}

if [ "${1:-}" = "--update" ]; then
  if [ -n "${2:-}" ]; then
    new=$2
    tmp=$(mktemp)
    sed "s/^BEND_COMMIT=.*/BEND_COMMIT=$new   # pinned by --update on $(date +%F)/" "$SELF" > "$tmp" && cat "$tmp" > "$SELF" && rm -f "$tmp"
    BEND_COMMIT=$new
    echo "bend.sh: pin moved to $new (also update env/SETUP.md, env/check_env.sh and re-run the gates)" >&2
  fi
  fetch_pin
  echo "bend.sh: $SRC at $(head_of)" >&2
  exit 0
fi
if [ ! -f "$SRC/bend2/main.ts" ]; then
  fetch_pin
fi
if [ "$(head_of)" != "$BEND_COMMIT" ]; then
  echo "bend.sh: $SRC is at $(head_of | cut -c1-12) but this repository pins Bend $BEND_COMMIT (bend 2.0.24)." >&2
  echo "bend.sh: run 'bash env/bend.sh --update' to check the pin out there, or set BEND_SRC to another checkout." >&2
  exit 2
fi
abs() { # absolute path of $1 relative to the caller's directory (file need not exist)
  case "$1" in /*|[A-Za-z]:*) printf '%s' "$1" ;; *) printf '%s/%s' "$PWD" "$1" ;; esac
}
args=(); prev=""
for a in "$@"; do
  if [ "$prev" = "-o" ] || [ -e "$a" ]; then args+=("$(abs "$a")"); else args+=("$a"); fi
  prev=$a
done
cd "$SRC/bend2"
exec bun main.ts "${args[@]}"
