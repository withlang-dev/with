#!/usr/bin/env bash
set -euo pipefail

CMAKE_VERSION="${CMAKE_VERSION:-4.2.3}"
CMAKE_SOURCE_SHA256="${CMAKE_SOURCE_SHA256:-7efaccde8c5a6b2968bad6ce0fe60e19b6e10701a12fce948c2bf79bac8a11e9}"
ROOT="${ROOT:-$PWD/.deps}"
HOST_TAG="${HOST_TAG:-host}"
SRC_DIR="$ROOT/src"
BUILD_DIR="$ROOT/build/cmake-${CMAKE_VERSION}-${HOST_TAG}"
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

CMAKE_BOOTSTRAP_CC="${CMAKE_BOOTSTRAP_CC:-clang}"
CMAKE_BOOTSTRAP_CXX="${CMAKE_BOOTSTRAP_CXX:-clang++}"
SDK_NINJA="${SDK_NINJA:-$INSTALL_PREFIX/bin/ninja}"
require_tool curl
require_tool tar
require_tool "$CMAKE_BOOTSTRAP_CC"
require_tool "$CMAKE_BOOTSTRAP_CXX"
if [ ! -x "$SDK_NINJA" ]; then
  echo "error: missing SDK Ninja: $SDK_NINJA" >&2
  echo "build it first: HOST_TAG=$HOST_TAG tools/build-ninja.sh" >&2
  exit 1
fi

mkdir -p "$SRC_DIR" "$BUILD_DIR"
cd "$SRC_DIR"

archive="cmake-${CMAKE_VERSION}.tar.gz"
source_dir="cmake-${CMAKE_VERSION}"

if [ ! -d "$source_dir" ]; then
  if [ ! -f "$archive" ]; then
    curl -L -O "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${archive}"
  fi
  sha256_check "$CMAKE_SOURCE_SHA256" "$archive"
  tar -xzf "$archive"
fi

cd "$BUILD_DIR"
CC="$CMAKE_BOOTSTRAP_CC" CXX="$CMAKE_BOOTSTRAP_CXX" "$SRC_DIR/$source_dir/bootstrap" \
  --prefix="$INSTALL_PREFIX" \
  --parallel="${PARALLEL_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}" \
  --generator=Ninja \
  -- \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_MAKE_PROGRAM="$SDK_NINJA" \
  -DCMAKE_USE_OPENSSL=OFF

"$SDK_NINJA" -j "${PARALLEL_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
"$SDK_NINJA" install

cmake_tool="$INSTALL_PREFIX/bin/cmake"
if [ ! -x "$cmake_tool" ]; then
  echo "error: CMake did not install to $cmake_tool" >&2
  exit 1
fi

echo "CMake ready: $cmake_tool"
