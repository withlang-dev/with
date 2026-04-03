#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPILER="$ROOT_DIR/out/bin/with"

if [ ! -x "$COMPILER" ]; then
  echo "error: missing compiler binary at $COMPILER" >&2
  exit 1
fi

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/with-embedded-XXXXXX")"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT INT TERM HUP

cp "$COMPILER" "$tmpdir/with"
cat >"$tmpdir/hello.w" <<'EOF'
fn main:
    print("hello")
EOF

(
  cd "$tmpdir"
  WITH_OUT_DIR="$tmpdir/no-out" ./with build hello.w -o hello >/dev/null
  output="$(./hello)"
  if [ "$output" != "hello" ]; then
    echo "error: embedded runtime extraction regression produced unexpected output: $output" >&2
    exit 1
  fi
)
