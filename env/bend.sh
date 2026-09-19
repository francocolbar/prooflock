#!/usr/bin/env bash
# bend_portable.sh - run the Bend 2 compiler straight from a source checkout with bun.
# For machines without the official launcher (Windows/Git Bash without WSL, locked-down
# hosts). Works: check, prove (`PROOF.bend`), pure mains, IO mains on the JS backend,
# `-o file.js`, `-o file.c`, `bend base`, `bend guide`. Not available this way: native
# `-o bin` and the GPU (need clang + a POSIX C runtime). On Windows additionally the JS
# effects that reach libc through bun:ffi fail (`Failed to open library "libc.so.6"`):
# IO.sleep, File.read, TCP/UDP, and any Fail result (e.g. IO.get_env on a missing var);
# print, get_env of an existing var, now, spawn, channels, fork/join and File.write work.
# Always pass forward-slash paths.
#
# Usage: bash bend_portable.sh <any bend arguments>       e.g. bash bend_portable.sh main.bend
#        bash bend_portable.sh --update                   pull the latest source
#        BEND_SRC=/path/to/checkout bash bend_portable.sh ... (default: ~/.bend-src)
# Tip: alias bend="bash <repo>/env/bend.sh"
#
# Why the cd: main.ts resolves Base's effect files relative to the current directory when
# paths carry backslashes, so it must run from inside bend2/. File arguments are made
# absolute first so they still resolve from the caller's directory.
set -eu
SRC=${BEND_SRC:-$HOME/.bend-src}
if ! command -v bun >/dev/null 2>&1; then
  if [ -x "$HOME/.bun/bin/bun" ]; then PATH="$HOME/.bun/bin:$PATH"; else
    echo "bend_portable: bun is required (https://bun.sh: curl -fsSL https://bun.sh/install | bash, or on Windows: powershell -c \"irm bun.sh/install.ps1 | iex\")" >&2; exit 1; fi
fi
if [ "${1:-}" = "--update" ]; then
  if [ -d "$SRC/.git" ]; then git -C "$SRC" pull --ff-only; else git clone --depth 1 https://github.com/HigherOrderCO/Bend "$SRC"; fi
  exit 0
fi
if [ ! -f "$SRC/bend2/main.ts" ]; then
  echo "bend_portable: fetching the Bend source into $SRC" >&2
  git clone --depth 1 --quiet https://github.com/HigherOrderCO/Bend "$SRC"
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
