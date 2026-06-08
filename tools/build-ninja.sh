#!/usr/bin/env bash
set -euo pipefail

NINJA_VERSION="${NINJA_VERSION:-1.13.1}"
NINJA_SOURCE_SHA256="${NINJA_SOURCE_SHA256:-f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23}"
ROOT="${ROOT:-$PWD/.deps}"
HOST_TAG="${HOST_TAG:-host}"
SRC_DIR="$ROOT/src"
INSTALL_PREFIX="${INSTALL_PREFIX:-$ROOT/llvm-22.1.6-${HOST_TAG}}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required tool: $1" >&2
    exit 1
  fi
}

sha256_check() {
  local expected="$1"
  local file="$2"
  if command -v shasum >/dev/null 2>&1; then
    printf '%s  %s\n' "$expected" "$file" | shasum -a 256 -c -
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "$expected" "$file" | sha256sum -c -
  else
    echo "error: need shasum or sha256sum for source verification" >&2
    exit 1
  fi
}

NINJA_BOOTSTRAP_CXX="${NINJA_BOOTSTRAP_CXX:-clang++}"
require_tool curl
require_tool tar
require_tool python3
require_tool "$NINJA_BOOTSTRAP_CXX"

mkdir -p "$SRC_DIR" "$INSTALL_PREFIX/bin"
cd "$SRC_DIR"

archive="ninja-${NINJA_VERSION}.tar.gz"
source_dir="ninja-${NINJA_VERSION}"

if [ ! -d "$source_dir" ]; then
  if [ ! -f "$archive" ]; then
    curl -L -o "$archive" "https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz"
  fi
  sha256_check "$NINJA_SOURCE_SHA256" "$archive"
  tar -xzf "$archive"
fi

cd "$source_dir"
CXX="$NINJA_BOOTSTRAP_CXX" python3 configure.py --bootstrap
cp ninja "$INSTALL_PREFIX/bin/ninja"

ninja_tool="$INSTALL_PREFIX/bin/ninja"
if [ ! -x "$ninja_tool" ]; then
  echo "error: Ninja did not install to $ninja_tool" >&2
  exit 1
fi

echo "Ninja ready: $ninja_tool"
