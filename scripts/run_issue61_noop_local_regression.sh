#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
source "${ROOT_DIR}/scripts/selfhost_runner.sh"

SELFHOST_BIN="./out/bin/with-stage2"
CHECK_TIMEOUT_SECS="${PARITY_CHECK_TIMEOUT_SECS:-60}"

echo "rebuilding self-host compiler for issue61 noop-local regression..."
make stage2 >/dev/null

if [[ ! -x "$SELFHOST_BIN" ]]; then
  echo "error: missing self-host compiler: $SELFHOST_BIN" >&2
  exit 1
fi

SELFHOST_BIN="$(prepare_selfhost_runner "$ROOT_DIR" "$SELFHOST_BIN")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; cleanup_selfhost_runner' EXIT

repo_copy="${tmpdir}/issue61-noop-local"
mkdir -p "$repo_copy"
cp -R "$ROOT_DIR/src" "$repo_copy/src"
ln -s "$ROOT_DIR/lib" "$repo_copy/lib"

python3 - "$repo_copy/src/SemaCheck.w" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
needle = "    // Check all arguments (with expected-type propagation for Atomic ordering params)\n"
insert = needle + "    var mc_issue61_padding_local: i32 = 0\n"
text = path.read_text()
if needle not in text:
    raise SystemExit(f"missing insertion point in {path}")
path.write_text(text.replace(needle, insert, 1))
PY

if ! grep -q "mc_issue61_padding_local" "$repo_copy/src/SemaCheck.w"; then
  echo "error: failed to inject noop local into copied SemaCheck.w" >&2
  exit 1
fi

out="${tmpdir}/issue61.out"
err="${tmpdir}/issue61.err"

if ! runner_exec_capture "$CHECK_TIMEOUT_SECS" "$out" "$err" env RUNNER_BIN="$SELFHOST_BIN" RUNNER_DIR="$repo_copy" bash -lc 'cd "$RUNNER_DIR" && "$RUNNER_BIN" check src/main.w'; then
  echo "FAIL(issue61-noop-local-selfhost-check)" >&2
  cat "$err" >&2
  exit 1
fi

if ! grep -qx "ok" "$out"; then
  echo "FAIL(issue61-noop-local-selfhost-output)" >&2
  cat "$out" >&2
  exit 1
fi

echo "issue61 noop-local selfhost regression: PASS"
