#!/bin/bash
# verify_dedup.sh — audit migrated PCRE2 for duplicated top-level declarations.
#
# The migrator must emit each C header declaration exactly once across the
# whole project: if the same name appears at module scope in more than one
# .w file, it is a migration bug. This script is the definitive check.
#
# Categories (from D3 diagnosis of migrated PCRE2):
#   1. enum/macro `let` declarations (e.g. `let ucp_C: c_uint = 0`)
#   2. `type` declarations (structs, typedefs, type aliases)
#   3. `fn` declarations from function-like C macros
#   4. `extern fn` declarations (header-sourced prototypes)
#   5. `extern var` declarations
#   6. `extern let` declarations
#
# By default the script audits the checked output from `make regex-build`
# (out/pcre2_build/lib/std/re). It never stages over lib/std/re.
#
# Override with:
#   DEDUP_DIR=<path>   — audit <path> directly, skip staging
#
# Exit:
#   0 — all six counts are exactly 0. No duplicates.
#   1 — any count is non-zero. Baseline establishes the gap to close.
#   2 — setup error (missing input dir, etc.)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_RE_DIR="$ROOT_DIR/out/pcre2_build/lib/std/re"
AUDIT_DIR="${DEDUP_DIR:-$BUILD_RE_DIR}"

if [ -z "${DEDUP_DIR:-}" ]; then
    [ -d "$BUILD_RE_DIR" ] || { echo "error: $BUILD_RE_DIR missing (run 'make regex-build' first)" >&2; exit 2; }
fi

[ -d "$AUDIT_DIR" ] || { echo "error: $AUDIT_DIR does not exist" >&2; exit 2; }

count_category() {
    local pattern="$1"
    python3 - "$AUDIT_DIR" "$pattern" <<'PY'
import re, sys
from pathlib import Path
from collections import defaultdict
d = Path(sys.argv[1])
pat = re.compile(sys.argv[2])
occ = defaultdict(set)
for f in sorted(d.glob("*.w")):
    if f.name == "defs.w":
        continue
    for line in f.read_text().splitlines():
        m = pat.match(line)
        if m:
            occ[m.group(1)].add(f.name)
dupes = sorted(n for n, mods in occ.items() if len(mods) >= 2)
print(len(dupes))
PY
}

let_count=$(count_category       '^let (\w+)')
type_count=$(count_category      '^type (\w+)')
fn_count=$(count_category        '^fn (\w+)')
extern_fn_count=$(count_category '^extern fn (\w+)')
extern_var_count=$(count_category '^extern var (\w+)')
extern_let_count=$(count_category '^extern let (\w+)')

cat <<EOF
dedup audit in $AUDIT_DIR
  enum/macro let duplicated across modules: $let_count
  type           duplicated across modules: $type_count
  fn (macro)     duplicated across modules: $fn_count
  extern fn      duplicated across modules: $extern_fn_count
  extern var     duplicated across modules: $extern_var_count
  extern let     duplicated across modules: $extern_let_count
EOF

total=$((let_count + type_count + fn_count + extern_fn_count + extern_var_count + extern_let_count))
if [ "$total" -ne 0 ]; then
    echo "FAIL: $total total duplicated names across 6 categories"
    exit 1
fi
echo "VERIFIED: no duplicated declarations across modules in $AUDIT_DIR"
