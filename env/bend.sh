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
#        bash env/bend.sh version                  prints the pinned version (BEND_VERSION below)
#        bash env/bend.sh --update                 fetch and check out the pinned commit
#        bash env/bend.sh --update <commit>        move the pin to <commit>, a full 40-hex SHA (exit 5 otherwise): fetch
#                                                  and check it out, then rewrite this file (a failed fetch, exit 3,
#                                                  leaves the pin unchanged)
#        BEND_SRC=/path/to/checkout bash env/bend.sh ...   (default: ~/.bend-src)
#        BEND_BIN=/path/to/bend bash env/bend.sh ...        use an installed `bend` binary instead of the source
#                                                           checkout (the official installer, curl -fsSL
#                                                           https://bend-lang.com/install.sh | sh, on Linux/macOS);
#                                                           it must report exactly BEND_VERSION or the runner refuses
#
# The pin is enforced: if $BEND_SRC exists at another commit the runner refuses to run (exit 2)
# and says how to fix it. It creates a missing checkout (BEND_SRC absent, empty, or a repository
# with no commit left by a failed fetch), refuses to fetch into any other directory without
# bend2/main.ts (exit 2), and moves an existing checkout only when asked to (`--update`); that
# checkout may be shared with other projects (env/SETUP.md). env/check_env.sh reports a checkout
# at another commit as a FAIL.
#
# Why the cd: main.ts resolves Base's effect files relative to the current directory when
# paths carry backslashes, so it must run from inside bend2/. File arguments are made
# absolute first so they still resolve from the caller's directory.
set -eu
BEND_VERSION="bend 2.0.25"   # what the pinned commit prints; --update warns when the two differ
if [ -n "${BEND_BIN:-}" ]; then
  got=$("$BEND_BIN" version 2>/dev/null | tail -1 || true)
  if [ "$got" != "$BEND_VERSION" ]; then
    echo "bend.sh: BEND_BIN=$BEND_BIN reports '$got', this repository pins '$BEND_VERSION'." >&2; exit 4
  fi
  export BEND_NO_TELEMETRY=1
  exec "$BEND_BIN" "$@"
fi
BEND_COMMIT=c65bcb788dbfb298bb434c1d858b47c193841dc0   # pinned by --update on 2026-09-23
BEND_REPO=https://github.com/bendlang/bend   # formerly github.com/HigherOrderCO/Bend, which redirects here
SRC=${BEND_SRC:-$HOME/.bend-src}
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
export BEND_NO_TELEMETRY=1
if ! command -v bun >/dev/null 2>&1; then
  if [ -x "$HOME/.bun/bin/bun" ]; then PATH="$HOME/.bun/bin:$PATH"; else
    echo "bend.sh: bun is required (https://bun.sh: curl -fsSL https://bun.sh/install | bash, or on Windows: powershell -c \"irm bun.sh/install.ps1 | iex\")" >&2; exit 1; fi
fi

head_of() { git -C "$SRC" rev-parse -q --verify HEAD 2>/dev/null || echo none; }   # none: no repository, or no commit yet

fetch_pin() { # create the checkout if missing, then fetch exactly the pinned commit and check it out.
  # The fetch goes to BEND_REPO, whatever remote an existing checkout has. Anonymous, never interactive:
  # no terminal prompt and no credential helper, so an upstream that answers 401/404 fails here with a
  # message instead of opening a login dialog on every call. (Upstream went private on 2026-09-21 and
  # has been public again at bendlang/bend since 2026-09-22; an anonymous fetch by SHA works.)
  if [ ! -d "$SRC/.git" ]; then
    echo "bend.sh: fetching Bend $BEND_COMMIT into $SRC" >&2
    mkdir -p "$SRC" && git -C "$SRC" init -q && git -C "$SRC" remote add origin "$BEND_REPO"
  fi
  if ! GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= git -C "$SRC" -c credential.helper= fetch -q --depth 1 "$BEND_REPO" "$BEND_COMMIT"; then
    echo "bend.sh: could not fetch Bend $BEND_COMMIT from $BEND_REPO anonymously." >&2
    echo "bend.sh: if upstream is private or gone, point BEND_SRC at a checkout of that commit ($BEND_VERSION) obtained" >&2
    echo "bend.sh: elsewhere; env/SETUP.md records the commit and the tree hash to verify it against." >&2
    exit 3
  fi
  git -C "$SRC" checkout -q --detach "$BEND_COMMIT"
}

if [ "${1:-}" = "--update" ]; then
  if [ -n "${2:-}" ]; then
    new=$2
    # only a full SHA: a tag or a short SHA never equals head_of, so every later call would refuse (exit 2)
    case $new in *[!0-9a-f]*) new=bad ;; esac
    if [ "${#new}" -ne 40 ]; then
      echo "bend.sh: --update needs a full 40-hex commit SHA, got '$2'; the pin is unchanged." >&2; exit 5
    fi
    BEND_COMMIT=$new
    fetch_pin   # exits 3 if the commit cannot be fetched, before this file is touched
    tmp=$(mktemp)
    sed "s/^BEND_COMMIT=.*/BEND_COMMIT=$new   # pinned by --update on $(date +%F)/" "$SELF" > "$tmp" && cat "$tmp" > "$SELF" && rm -f "$tmp"
    echo "bend.sh: pin moved to $new (also set BEND_VERSION in this file, update env/SETUP.md and re-run the gates)" >&2
  else
    fetch_pin
  fi
  got=$(cd "$SRC/bend2" && bun main.ts version 2>/dev/null | tail -1 || true)
  echo "bend.sh: $SRC at $(head_of), which prints '$got'" >&2
  if [ "$got" != "$BEND_VERSION" ]; then
    echo "bend.sh: this file says BEND_VERSION='$BEND_VERSION': set it to '$got' if that commit is the one intended" >&2
  fi
  exit 0
fi
if [ ! -f "$SRC/bend2/main.ts" ]; then
  # create a checkout, never take over a directory that holds something else (a mistyped BEND_SRC
  # pointing at a project would otherwise get Bend fetched into it and its HEAD detached)
  if [ -n "$(ls -A "$SRC" 2>/dev/null)" ] && ! { [ -d "$SRC/.git" ] && [ "$(head_of)" = none ]; }; then
    echo "bend.sh: $SRC is not empty and has no bend2/main.ts, so it was left untouched." >&2
    echo "bend.sh: set BEND_SRC to a checkout of Bend $BEND_COMMIT, or to a missing or empty directory to fetch one there;" >&2
    echo "bend.sh: 'bash env/bend.sh --update' checks the pin out into $SRC anyway." >&2
    exit 2
  fi
  fetch_pin
fi
if [ "$(head_of)" != "$BEND_COMMIT" ]; then
  echo "bend.sh: $SRC is at $(head_of | cut -c1-12) but this repository pins Bend $BEND_COMMIT ($BEND_VERSION)." >&2
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
