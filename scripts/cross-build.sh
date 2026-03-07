#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "usage: $0 <target-triple> <source.w> [output-binary]" >&2
  exit 2
fi

TARGET_TRIPLE="$1"
SOURCE_PATH="$2"
OUTPUT_BIN="${3:-}"

if [ ! -f "$SOURCE_PATH" ]; then
  echo "error: source file not found: $SOURCE_PATH" >&2
  exit 1
fi

if [ -x "${ROOT_DIR}/out/bin/with-stage2" ]; then
  COMPILER="${ROOT_DIR}/out/bin/with-stage2"
elif [ -x "${ROOT_DIR}/out/bin/with" ]; then
  COMPILER="${ROOT_DIR}/out/bin/with"
else
  echo "error: compiler not found (expected out/bin/with-stage2 or out/bin/with)" >&2
  exit 1
fi

if ! command -v zig >/dev/null 2>&1; then
  echo "error: zig is required for cross-build" >&2
  exit 1
fi

ARCH="${TARGET_TRIPLE%%-*}"
case "$ARCH" in
  x86_64|amd64)
    ASM_ARCH="x86_64"
    ;;
  aarch64|arm64)
    ASM_ARCH="aarch64"
    ;;
  *)
    echo "error: unsupported target arch '$ARCH' (supported: x86_64, aarch64)" >&2
    exit 1
    ;;
esac

RUNTIME_DIR="${ROOT_DIR}/runtime"
ASM_FILE="${RUNTIME_DIR}/fiber_asm_${ASM_ARCH}.s"
if [ ! -f "$ASM_FILE" ]; then
  echo "error: missing runtime assembly file: $ASM_FILE" >&2
  exit 1
fi

SOURCE_BASE="$(basename "$SOURCE_PATH")"
SOURCE_STEM="${SOURCE_BASE%.*}"
SANITIZED_TARGET="${TARGET_TRIPLE//\//_}"
SANITIZED_TARGET="${SANITIZED_TARGET//:/_}"
SANITIZED_TARGET="${SANITIZED_TARGET//-/_}"

mkdir -p "${ROOT_DIR}/.with/build/cross"
C_OUT="${ROOT_DIR}/.with/build/cross/${SOURCE_STEM}.${SANITIZED_TARGET}.c"

if [ -z "$OUTPUT_BIN" ]; then
  OUTPUT_BIN="${ROOT_DIR}/.with/build/cross/${SOURCE_STEM}.${SANITIZED_TARGET}"
fi

echo "[cross-build] compiler: $COMPILER"
echo "[cross-build] target:   $TARGET_TRIPLE"
echo "[cross-build] source:   $SOURCE_PATH"
echo "[cross-build] emit-c:   $C_OUT"
echo "[cross-build] output:   $OUTPUT_BIN"

"$COMPILER" build --emit-c "$SOURCE_PATH" -o "$C_OUT"

zig cc -std=c11 -Wall -Werror \
  -target "$TARGET_TRIPLE" \
  -I "$RUNTIME_DIR" \
  "$C_OUT" \
  "${RUNTIME_DIR}/with_runtime.c" \
  "${RUNTIME_DIR}/helpers.c" \
  "${RUNTIME_DIR}/fiber.c" \
  "$ASM_FILE" \
  -o "$OUTPUT_BIN"

echo "[cross-build] built: $OUTPUT_BIN"
