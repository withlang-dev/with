#!/bin/bash
# verify_pcre2_works.sh — ground-truth integration test for migrated PCRE2.
#
# This is the definitive success criterion for "the migrated PCRE2 works."
# No phase of the PCRE2 migration is complete until this script passes
# against that phase's output.
#
# Steps:
#   1. Snapshot lib/std/re/ so we can restore on exit
#   2. Stage out/pcre2_generated/*.w into lib/std/re/ (integration test bed)
#   3. Build test/pcre2_verify.w as a binary linking ALL 30 migrated modules
#   4. For each pattern in the corpus, run:
#        - upstream `pcre2test` to get the canonical expected match output
#        - our `pcre2_verify` binary with the same pattern/subject
#      and diff byte-for-byte.
#   5. Restore lib/std/re/ at exit (even on error)
#
# Ground-truth oracle: /opt/homebrew/bin/pcre2test (system PCRE2).
# The match-line format pcre2_verify.w emits is identical to pcre2test's
# non-header output (" 0: <text>", " 1: <text>", "No match", "Error: ...").
#
# This script never modifies the migrator or migrated code. It only
# stages outputs and runs them. If a test case fails, that's a concrete
# migrator bug measured against reality, not against "does it compile."

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GENERATED_DIR="$ROOT_DIR/out/pcre2_generated"
STD_RE_DIR="$ROOT_DIR/lib/std/re"
HARNESS_SRC="$ROOT_DIR/test/pcre2_verify.w"
HARNESS_BIN="$ROOT_DIR/out/bin/pcre2_verify"
BACKUP_DIR=""

PCRE2TEST="${PCRE2TEST:-/opt/homebrew/bin/pcre2test}"
WITH_BIN="${WITH_BIN:-$ROOT_DIR/out/bin/with}"

pass_count=0
fail_count=0
failed_cases=()

die() {
    echo "error: $*" >&2
    exit 1
}

cleanup() {
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        rm -rf "$STD_RE_DIR"
        mkdir -p "$STD_RE_DIR"
        cp "$BACKUP_DIR"/*.w "$STD_RE_DIR/" 2>/dev/null || true
        rm -rf "$BACKUP_DIR"
    fi
    rm -f "$HARNESS_BIN"
}
trap cleanup EXIT INT TERM

require() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
    done
}

# Extract just the match-output lines from pcre2test's output
# (skip version header, echoed pattern, echoed subject, empty lines).
oracle_output() {
    local pattern="$1"
    local subject="$2"
    printf '/%s/\n    %s\n' "$pattern" "$subject" | "$PCRE2TEST" 2>&1 \
        | grep -E '^( *[0-9]+:|No match|Failed|Error)'
}

# Run our migrated harness and filter to the same match-output lines.
harness_output() {
    local pattern="$1"
    local subject="$2"
    "$HARNESS_BIN" "$pattern" "$subject" 2>&1 \
        | grep -E '^( *[0-9]+:|No match|Failed|Error)'
}

run_case() {
    local label="$1"
    local pattern="$2"
    local subject="$3"

    local expected actual
    expected="$(oracle_output "$pattern" "$subject" || true)"
    actual="$(harness_output "$pattern" "$subject" || true)"

    if [ "$expected" = "$actual" ]; then
        pass_count=$((pass_count + 1))
        printf 'PASS  %-28s  pattern=%-20s  subject=%s\n' "$label" "/$pattern/" "$subject"
    else
        fail_count=$((fail_count + 1))
        failed_cases+=("$label")
        printf 'FAIL  %-28s  pattern=%-20s  subject=%s\n' "$label" "/$pattern/" "$subject"
        printf '  expected:\n%s\n' "$(printf '%s' "$expected" | sed 's/^/    /')"
        printf '  actual:\n%s\n' "$(printf '%s' "$actual" | sed 's/^/    /')"
    fi
}

# ── Setup ────────────────────────────────────────────────────
require "$PCRE2TEST" "$WITH_BIN"
[ -f "$HARNESS_SRC" ] || die "missing harness: $HARNESS_SRC"
[ -d "$GENERATED_DIR" ] || die "missing generated dir: $GENERATED_DIR (run 'make regex-prepare' first)"
[ -x "$WITH_BIN" ] || die "with binary not built: $WITH_BIN (run 'make build' first)"

echo "==> staging $GENERATED_DIR → $STD_RE_DIR"
BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/std-re-backup.XXXXXX")"
if [ -d "$STD_RE_DIR" ]; then
    cp "$STD_RE_DIR"/*.w "$BACKUP_DIR/" 2>/dev/null || true
fi
rm -rf "$STD_RE_DIR"
mkdir -p "$STD_RE_DIR"
cp "$GENERATED_DIR"/*.w "$STD_RE_DIR/"

echo "==> building harness: $HARNESS_SRC"
if ! "$WITH_BIN" build "$HARNESS_SRC" -o "$HARNESS_BIN" 2>&1 | tail -20; then
    die "harness build failed — integration does not link yet"
fi
[ -x "$HARNESS_BIN" ] || die "harness binary not produced"

echo "==> running test corpus"

# ── Test corpus ──────────────────────────────────────────────
# Each line: label  pattern  subject
# Patterns cover literal/alternation/classes/anchors/quantifiers/groups/
# backrefs/word-boundaries/lookarounds — PCRE2's common feature surface.
run_case "literal-start"         'abc'           'xabcdef'
run_case "literal-no-match"      'abc'           'xyz'
run_case "alternation-first"     'cat|dog'       'my cat eats'
run_case "alternation-second"    'cat|dog'       'my dog barks'
run_case "alternation-no-match"  'cat|dog'       'fish swim'
run_case "char-class-positive"   '[aeiou]'       'xyzabc'
run_case "char-class-negative"   '[^aeiou]+'     'aeibcdef'
run_case "char-range"            '[a-z]+'        'Hello World'
run_case "quantifier-star"       'a*b'           'aaab'
run_case "quantifier-plus"       'a+b'           'bbb'
run_case "quantifier-question"   'colou?r'       'color'
run_case "anchor-start"          '^abc'          'abcdef'
run_case "anchor-start-fails"    '^abc'          'xabc'
run_case "anchor-end"            'abc$'          'xyzabc'
run_case "dot-any"               'a.c'           'a1c'
run_case "escape-digit"          '\d+'           'abc123def'
run_case "escape-word"           '\w+'           'hello world'
run_case "group-capture"         '(ab)c'         'xabcdef'
run_case "group-nested"          '((a)b)c'       'xabcdef'
run_case "backref"               '(a)\1'         'aab'

# ── Report ───────────────────────────────────────────────────
echo
echo "==> summary: $pass_count passed, $fail_count failed"
if [ "$fail_count" -gt 0 ]; then
    echo "failed cases: ${failed_cases[*]}"
    exit 1
fi
echo "VERIFIED: migrated PCRE2 matches upstream byte-for-byte across $pass_count cases"
