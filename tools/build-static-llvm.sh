#!/usr/bin/env bash
set -euo pipefail

LLVM_VERSION="${LLVM_VERSION:-22.1.6}"
LLVM_TAG="llvmorg-${LLVM_VERSION}"
LLVM_SOURCE_SHA256="${LLVM_SOURCE_SHA256:-6e0b376a1f6d9873e7dfb09ae6e04b9c7024400f01733fa4c29be69d5c138bc2}"

TARGETS="${LLVM_TARGETS_TO_BUILD:-AArch64;X86}"
ROOT="${ROOT:-$PWD/.deps}"
HOST_TAG="${HOST_TAG:-host}"
SRC_DIR="$ROOT/src"
BUILD_DIR="$ROOT/build/llvm-${LLVM_VERSION}-${HOST_TAG}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$ROOT/llvm-${LLVM_VERSION}-${HOST_TAG}}"

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

require_tool curl
require_tool tar
LLVM_BOOTSTRAP_CC="${LLVM_BOOTSTRAP_CC:-clang}"
LLVM_BOOTSTRAP_CXX="${LLVM_BOOTSTRAP_CXX:-clang++}"
LLVM_BOOTSTRAP_LD="${LLVM_BOOTSTRAP_LD:-ld.lld}"
require_tool "$LLVM_BOOTSTRAP_CC"
require_tool "$LLVM_BOOTSTRAP_CXX"
require_tool "$LLVM_BOOTSTRAP_LD"

SDK_CMAKE="${SDK_CMAKE:-$INSTALL_PREFIX/bin/cmake}"
if [ -x "$SDK_CMAKE" ]; then
  CMAKE_TOOL="$SDK_CMAKE"
else
  echo "error: missing SDK CMake: $SDK_CMAKE" >&2
  echo "build it first: HOST_TAG=$HOST_TAG tools/build-cmake.sh" >&2
  exit 1
fi

mkdir -p "$SRC_DIR" "$BUILD_DIR"
cd "$SRC_DIR"

archive="llvm-project-${LLVM_VERSION}.src.tar.xz"
source_dir="llvm-project-${LLVM_VERSION}.src"

if [ ! -d "$source_dir" ]; then
  if [ ! -f "$archive" ]; then
    curl -L -O "https://github.com/llvm/llvm-project/releases/download/${LLVM_TAG}/${archive}"
  fi
  sha256_check "$LLVM_SOURCE_SHA256" "$archive"
  tar -xf "$archive"
fi

extra_cmake_args=()

case "$(uname -s)" in
  Darwin)
    require_tool xcrun
    sdkroot="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
    extra_cmake_args+=(
      "-DCMAKE_OSX_SYSROOT=${sdkroot}"
      "-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-11.0}"
    )
    case "$(uname -m)" in
      arm64) extra_cmake_args+=("-DCMAKE_OSX_ARCHITECTURES=arm64") ;;
      x86_64) extra_cmake_args+=("-DCMAKE_OSX_ARCHITECTURES=x86_64") ;;
      *) echo "error: unsupported macOS arch: $(uname -m)" >&2; exit 1 ;;
    esac
    ;;
  Linux)
    ;;
  *)
    echo "error: unsupported host OS: $(uname -s)" >&2
    exit 1
    ;;
esac

CMAKE_ARGS=(
  -S "$SRC_DIR/$source_dir/llvm"
  -B "$BUILD_DIR"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_C_COMPILER="$LLVM_BOOTSTRAP_CC"
  -DCMAKE_CXX_COMPILER="$LLVM_BOOTSTRAP_CXX"
  -DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=lld"
  -DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=lld"
  -DCMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=lld"
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
  -DLLVM_ENABLE_PROJECTS="clang;lld"
  -DLLVM_TARGETS_TO_BUILD="$TARGETS"
  -DLIBCLANG_BUILD_STATIC=ON
  -DLLVM_ENABLE_PIC=ON
  -DBUILD_SHARED_LIBS=OFF
  -DLLVM_BUILD_LLVM_DYLIB=OFF
  -DLLVM_LINK_LLVM_DYLIB=OFF
  -DCLANG_LINK_CLANG_DYLIB=OFF
  -DLLVM_INCLUDE_TESTS=OFF
  -DLLVM_INCLUDE_BENCHMARKS=OFF
  -DLLVM_INCLUDE_EXAMPLES=OFF
  -DCLANG_INCLUDE_TESTS=OFF
  -DCLANG_BUILD_EXAMPLES=OFF
  -DLLVM_ENABLE_ZLIB=OFF
  -DLLVM_ENABLE_ZSTD=OFF
  "${extra_cmake_args[@]}"
)
if [ -n "${LLVM_CMAKE_GENERATOR:-}" ]; then
  CMAKE_ARGS=(-G "$LLVM_CMAKE_GENERATOR" "${CMAKE_ARGS[@]}")
fi
"$CMAKE_TOOL" "${CMAKE_ARGS[@]}"

if [ -n "${PARALLEL_JOBS:-}" ]; then
  "$CMAKE_TOOL" --build "$BUILD_DIR" --target install --parallel "$PARALLEL_JOBS"
else
  "$CMAKE_TOOL" --build "$BUILD_DIR" --target install --parallel
fi

libclang="$INSTALL_PREFIX/lib/libclang.a"
if [ ! -f "$libclang" ]; then
  echo "error: static libclang archive was not installed: $libclang" >&2
  exit 1
fi

clang_tool="$INSTALL_PREFIX/bin/clang"
if [ ! -x "$clang_tool" ]; then
  echo "error: missing clang driver in static SDK: $clang_tool" >&2
  exit 1
fi

clangxx_tool="$INSTALL_PREFIX/bin/clang++"
if [ ! -x "$clangxx_tool" ]; then
  echo "error: missing clang++ driver in static SDK: $clangxx_tool" >&2
  exit 1
fi

nm_tool="$INSTALL_PREFIX/bin/llvm-nm"
if [ ! -x "$nm_tool" ]; then
  echo "error: missing llvm-nm in static SDK: $nm_tool" >&2
  exit 1
fi

nm_output="$(mktemp)"
trap 'rm -f "$nm_output"' EXIT
"$nm_tool" -g "$libclang" >"$nm_output"

if ! grep -q 'clang_createIndex' "$nm_output"; then
  echo "error: $libclang does not export clang_createIndex" >&2
  exit 1
fi

echo "static LLVM SDK ready: $INSTALL_PREFIX"
echo "export LLVM_PREFIX=\"$INSTALL_PREFIX\""
echo "export WITH_LIBCLANG=\"$libclang\""
