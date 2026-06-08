#!/bin/sh
set -eu

# Package the With-owned static LLVM/Clang/lld SDK as a per-platform release
# asset. A release reuses this; it never rebuilds LLVM from source (that is the
# bootstrap runbook's job) and never trusts a system LLVM.
#
# The asset contains the With-owned LLVM/Clang tools/resources required by
# bootstrap and by the compiler *build*:
#   - lib/*.a                  static LLVM/Clang/lld archives (the bulk)
#   - lib/clang/<v>/include/   clang builtin headers (also the embed source, #312)
#   - bin/clang                C driver for emitted-C bootstrap on every host
#   - bin/cmake                With-owned CMake for repeat SDK production
#   - bin/ninja                With-owned CMake generator backend
#   - bin/lld (+ driver symlinks ld.lld/ld64.lld/...) and LLVM utility tools
# It deliberately omits the LLVM C++ include/ tree (the bridges are .w extern
# decls). Normal self-host builds link via lld and do not invoke clang, but
# emitted-C bootstrap must use this With-owned clang, not GCC/MSVC/system LLVM.
#
# Output: out/release/with-llvm-sdk-<llvm-ver>-<platform>.tar.zst
# The archive's top-level dir is the SDK prefix basename (llvm-<ver>-<host-tag>),
# so a fetch can extract it straight into .deps/.

llvm_version="${LLVM_VERSION:-22.1.6}"
release_dir="${WITH_RELEASE_DIR:-out/release}"

case "$(uname -s):$(uname -m)" in
    Darwin:arm64|Darwin:aarch64) platform="darwin-aarch64"; host_tag="darwin-arm64" ;;
    Linux:x86_64)                platform="linux-x86_64";   host_tag="linux-x86_64" ;;
    *)
        echo "error: unsupported SDK packaging host: $(uname -s)/$(uname -m)" >&2
        exit 1
        ;;
esac

prefix="${LLVM_PREFIX:-.deps/llvm-${llvm_version}-${host_tag}}"
sdk_base="llvm-${llvm_version}-${host_tag}"
asset="$release_dir/with-llvm-sdk-${llvm_version}-${platform}.tar.zst"
build_cache="${LLVM_BUILD_CACHE:-.deps/build/llvm-${llvm_version}-${host_tag}/CMakeCache.txt}"

if [ ! -f "$prefix/lib/libclang.a" ]; then
    echo "error: static SDK not found at $prefix/lib/libclang.a" >&2
    echo "build it first (bootstrap): HOST_TAG=$host_tag tools/build-static-llvm.sh" >&2
    exit 1
fi
if [ ! -f "$build_cache" ]; then
    echo "error: missing SDK build cache: $build_cache" >&2
    echo "package only SDKs built by tools/build-static-llvm.sh in this checkout" >&2
    exit 1
fi
if ! grep -E '^CMAKE_C_COMPILER:[^=]+=.*clang([^/]*$|-[0-9.]+$)' "$build_cache" >/dev/null ||
   ! grep -E '^CMAKE_CXX_COMPILER:[^=]+=.*clang\+\+([^/]*$|-[0-9.]+$)' "$build_cache" >/dev/null; then
    echo "error: refusing to package SDK not built with clang/clang++" >&2
    grep -E '^CMAKE_(C|CXX)_COMPILER:' "$build_cache" >&2 || true
    exit 1
fi
if [ ! -x "$prefix/bin/clang" ]; then
    echo "error: static SDK is missing clang driver: $prefix/bin/clang" >&2
    echo "rebuild the SDK: HOST_TAG=$host_tag tools/build-static-llvm.sh" >&2
    exit 1
fi
if [ ! -x "$prefix/bin/clang++" ]; then
    echo "error: static SDK is missing clang++ driver: $prefix/bin/clang++" >&2
    echo "rebuild the SDK: HOST_TAG=$host_tag tools/build-static-llvm.sh" >&2
    exit 1
fi
if [ ! -x "$prefix/bin/cmake" ]; then
    echo "error: static SDK is missing CMake: $prefix/bin/cmake" >&2
    echo "build it first: HOST_TAG=$host_tag tools/build-cmake.sh" >&2
    exit 1
fi
if [ ! -x "$prefix/bin/ninja" ]; then
    echo "error: static SDK is missing Ninja: $prefix/bin/ninja" >&2
    echo "build it first: HOST_TAG=$host_tag tools/build-ninja.sh" >&2
    exit 1
fi
if [ ! -x "$prefix/bin/llvm-strip" ]; then
    echo "error: static SDK is missing llvm-strip: $prefix/bin/llvm-strip" >&2
    echo "rebuild the SDK: HOST_TAG=$host_tag tools/build-static-llvm.sh" >&2
    exit 1
fi

stage_root="$release_dir/.sdk-stage"
stage="$stage_root/$sdk_base"
rm -rf "$stage_root"
mkdir -p "$stage/lib" "$stage/bin"

# Archives + clang builtin headers.
cp "$prefix"/lib/*.a "$stage/lib/"
cp -R "$prefix/lib/clang" "$stage/lib/clang"

# Clang driver, CMake, Ninja, linker (lld) and its driver symlinks, plus LLVM
# utility tools. -P keeps symlinks as-is so ld.lld/ld64.lld stay pointing at
# lld inside the archive.
cp -P "$prefix/bin/clang" "$stage/bin/"
if [ -e "$prefix/bin/clang++" ] || [ -L "$prefix/bin/clang++" ]; then
    cp -P "$prefix/bin/clang++" "$stage/bin/"
fi
cp -P "$prefix/bin/cmake" "$stage/bin/"
cp -P "$prefix/bin/ninja" "$stage/bin/"
for tool in ctest cpack; do
    if [ -e "$prefix/bin/$tool" ] || [ -L "$prefix/bin/$tool" ]; then
        cp -P "$prefix/bin/$tool" "$stage/bin/"
    fi
done
cp -P "$prefix/bin/lld" "$stage/bin/"
for tool in ld.lld ld64.lld lld-link wasm-ld llvm-nm llvm-readobj llvm-strip; do
    if [ -e "$prefix/bin/$tool" ] || [ -L "$prefix/bin/$tool" ]; then
        cp -P "$prefix/bin/$tool" "$stage/bin/"
    fi
done

mkdir -p "$release_dir"
( cd "$stage_root" && tar -cf - "$sdk_base" ) | zstd -19 -T0 -o "$asset" -f
rm -rf "$stage_root"

# Sanity: the archive must contain the static libclang and the builtin headers.
# List the full archive once to a file (streaming into `grep -q` would SIGPIPE
# the decompressor on its early exit).
listing="$(mktemp)"
zstd -dc "$asset" | tar -tf - > "$listing"
if ! grep -q "$sdk_base/lib/libclang.a" "$listing"; then
    echo "error: packaged SDK is missing lib/libclang.a" >&2
    rm -f "$listing"
    exit 1
fi
if ! grep -q "$sdk_base/lib/clang/.*/include/stddef.h" "$listing"; then
    echo "error: packaged SDK is missing clang builtin headers (lib/clang/<v>/include)" >&2
    rm -f "$listing"
    exit 1
fi
if ! grep -q "$sdk_base/bin/clang" "$listing"; then
    echo "error: packaged SDK is missing bin/clang" >&2
    rm -f "$listing"
    exit 1
fi
if ! grep -q "$sdk_base/bin/clang++" "$listing"; then
    echo "error: packaged SDK is missing bin/clang++" >&2
    rm -f "$listing"
    exit 1
fi
if ! grep -q "$sdk_base/bin/cmake" "$listing"; then
    echo "error: packaged SDK is missing bin/cmake" >&2
    rm -f "$listing"
    exit 1
fi
if ! grep -q "$sdk_base/bin/ninja" "$listing"; then
    echo "error: packaged SDK is missing bin/ninja" >&2
    rm -f "$listing"
    exit 1
fi
if ! grep -q "$sdk_base/bin/llvm-strip" "$listing"; then
    echo "error: packaged SDK is missing bin/llvm-strip" >&2
    rm -f "$listing"
    exit 1
fi
rm -f "$listing"

echo "packaged static LLVM SDK: $asset"
du -h "$asset" | awk '{print "  size: "$1}'
if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$asset"
else
    sha256sum "$asset"
fi
