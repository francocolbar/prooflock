#!/usr/bin/env bash
# check_env.sh - verifies the toolchain the Bend 2 spike relies on and re-runs every
# hello-world in env/. Run from anywhere (Git Bash on Windows, bash on Linux/macOS):
#   bash bend-spike/env/check_env.sh
#   PY=python3.14 bash bend-spike/env/check_env.sh     # the Python launcher (default: py -3.14)
# Every line starting with PASS/FAIL is a check; the exit code is the number of FAILs, so a Bend
# checkout at the wrong commit, or the wrong bend version, is a hard failure.
set -u
export BEND_NO_TELEMETRY=1
HERE="$(cd "$(dirname "$0")" && pwd)"
BEND=(bash "$HERE/bend.sh")   # array: $HERE contains a space in this repo path
SRC="${BEND_SRC:-$HOME/.bend-src}"
PY=${PY:-py -3.14}
PIN=$(grep -m1 '^BEND_COMMIT=' "$HERE/bend.sh" | cut -d= -f2 | cut -d' ' -f1)
BEND_VERSION="bend 2.0.24"
fails=0
check() { # check <name> <expected-substring> <actual-text>
  if [[ "$3" == *"$2"* ]]; then echo "PASS $1"; else echo "FAIL $1 (expected '$2', got: $(echo "$3" | tail -3 | tr '\n' '|'))"; fails=$((fails+1)); fi
}

echo "== versions =="
echo "bend:   $("${BEND[@]}" version 2>&1 | tail -1)  (source $(git -C "$SRC" rev-parse --short HEAD 2>/dev/null), $(git -C "$SRC" log -1 --format=%cd 2>/dev/null); pinned $PIN)"
echo "bun:    $(bun --version 2>/dev/null || "$HOME/.bun/bin/bun" --version)"
echo "node:   $(node --version)"
echo "python: $($PY --version 2>&1)"
echo "jax:    $($PY -c "import jax, jax.numpy as jnp, numpy; jax.config.update('jax_enable_x64', True); print(jax.__version__, 'numpy', numpy.__version__, 'x64 dtype', jnp.array([1.0]).dtype, jax.devices())" 2>&1 | tail -1)"
cl="$(clang --version 2>/dev/null | head -1)"; echo "clang:  ${cl:-absent (no native builds, no GPU)}"
ws="$(wsl -l -q 2>/dev/null | tr -d '\000\r' | grep -v -i 'not installed' | head -1)"; echo "wsl:    ${ws:-absent}"

echo "== checks =="
check "bend version"              "$BEND_VERSION"     "$("${BEND[@]}" version 2>&1)"
check "bend source at the pinned commit" "$PIN"      "$(git -C "$SRC" rev-parse HEAD 2>/dev/null)"
check "hypothesis importable"     "hypothesis"        "$($PY -c "import hypothesis; print('hypothesis', hypothesis.__version__)" 2>&1)"
cd "$HERE/hello"
check "jax float64 enabled"       "float64"           "$($PY -c "import jax, jax.numpy as jnp; jax.config.update('jax_enable_x64', True); print(jnp.array([1.0]).dtype)" 2>&1)"
check "Nat capped at 2^48-1 (IO)" "past the largest immediate 2^48-1" "$("${BEND[@]}" nat_io.bend 2>&1)"
check "Nat capped (checker)"      "stack overflowed"  "$("${BEND[@]}" nat_pure.bend 2>&1)"
"${BEND[@]}" emit_hello.bend > hello_kernel_a.py 2>/dev/null
check "interop A: stdout -> .py -> python" "hello from a Bend-emitted kernel [0.5]" "$($PY hello_kernel_a.py 2>&1)"
rm -f hello_kernel_b.py; BEND_OUT="$HERE/hello/hello_kernel_b.py" "${BEND[@]}" emit_file.bend >/dev/null 2>&1
check "interop B: File.write -> python" "hello from a Bend-written kernel file [0.5]" "$($PY hello_kernel_b.py 2>&1)"
check "interop C: node --import loader" "((2 * x) + 3)" "$(node --import "file:///$(cd "$SRC/bend2" && pwd -W 2>/dev/null || pwd)/main.ts" app.mjs 2>&1)"
cd "$HERE/interlock"
check "interlock: main runs"      "Idle{}"            "$("${BEND[@]}" fsm.bend 2>&1)"
check "interlock: both laws proven" "All terms check." "$("${BEND[@]}" fsm_PROOF.bend 2>&1)"
cd "$HERE/provenance"
check "provenance: matching index accepted" "2n"      "$("${BEND[@]}" prov.bend 2>&1)"
check "provenance: mismatch rejected" "observed : Field<3n, 8n>" "$("${BEND[@]}" prov_bad.bend 2>&1)"
echo "== $fails FAIL(s) =="
exit $fails
