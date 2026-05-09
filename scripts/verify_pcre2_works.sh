#!/bin/bash
# verify_pcre2_works.sh — run the upstream PCRE2 regression suite against the
# migrated 8-bit pcre2test binary built by `make regex-build`.
#
# This is the definitive success criterion for "the migrated PCRE2 works."
# A hand-picked corpus is useful for smoke coverage, but it is not enough to
# claim compatibility. The real check is the upstream testdata corpus as driven
# by PCRE2's own RunTest script, which handles locale variants, link-size-
# specific expectations, DFA/JIT variants, and width-specific skips.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PCRE2_BUILD_DIR="$ROOT_DIR/out/pcre2_build"
PCRE2TEST_BIN="$PCRE2_BUILD_DIR/bin/pcre2test"
RUNTEST_DIR="${PCRE2_REF_DIR:-$ROOT_DIR/out/pcre2_reference/pcre2-10.47}"

RUNTEST_WORKDIR=""

WITH_BIN="${WITH_BIN:-$ROOT_DIR/out/bin/with}"

die() {
    echo "error: $*" >&2
    exit 1
}

cleanup() {
    if [ -n "$RUNTEST_WORKDIR" ] && [ -d "$RUNTEST_WORKDIR" ]; then
        rm -rf "$RUNTEST_WORKDIR"
    fi
}
trap cleanup EXIT INT TERM

require() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
    done
}

require "$WITH_BIN" bash
[ -x "$WITH_BIN" ] || die "with binary not built: $WITH_BIN (run 'make build' first)"
[ -d "$PCRE2_BUILD_DIR" ] || die "missing PCRE2 build dir: $PCRE2_BUILD_DIR (run 'make regex-build' first)"
[ -d "$RUNTEST_DIR" ] || die "missing upstream PCRE2 source dir: $RUNTEST_DIR"
[ -x "$PCRE2TEST_BIN" ] || die "missing built migrated pcre2test: $PCRE2TEST_BIN (run 'make regex-build' first)"

RUNTEST_WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/pcre2-runtest.XXXXXX")"

echo "==> running upstream RunTest corpus (8-bit + heap)"
(
    cd "$RUNTEST_WORKDIR"
    srcdir="$RUNTEST_DIR" pcre2test="$PCRE2TEST_BIN" bash "$RUNTEST_DIR/RunTest" -8 0-29 heap
)

echo "VERIFIED: migrated pcre2test passes upstream RunTest for the 8-bit corpus"
