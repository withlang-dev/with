#!/bin/sh
set -eu

# Package the With-owned static LLVM/Clang/lld SDK as a per-platform release
# asset. A release reuses this; it never rebuilds LLVM from source (that is the
# bootstrap runbook's job) and never trusts a system LLVM.
#
# The asset contains only what the compiler *build* links against:
#   - lib/*.a                  static LLVM/Clang/lld archives (the bulk)
#   - lib/clang/<v>/include/   clang builtin headers (also the embed source, #312)
#   - bin/lld (+ driver symlinks ld.lld/ld64.lld/...) and bin/llvm-nm
# It deliberately omits bin/clang (the normal build links via lld, never the
# clang driver) and the LLVM C++ include/ tree (the bridges are .w extern decls).
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

if [ ! -f "$prefix/lib/libclang.a" ]; then
    echo "error: static SDK not found at $prefix/lib/libclang.a" >&2
    echo "build it first (bootstrap): HOST_TAG=$host_tag tools/build-static-llvm.sh" >&2
    exit 1
fi

stage_root="$release_dir/.sdk-stage"
stage="$stage_root/$sdk_base"
rm -rf "$stage_root"
mkdir -p "$stage/lib" "$stage/bin"

# Archives + clang builtin headers.
cp "$prefix"/lib/*.a "$stage/lib/"
cp -R "$prefix/lib/clang" "$stage/lib/clang"

# Linker (lld) and its driver symlinks, plus llvm-nm. -P keeps symlinks as-is so
# ld.lld/ld64.lld stay pointing at lld inside the archive.
cp -P "$prefix/bin/lld" "$stage/bin/"
for tool in ld.lld ld64.lld lld-link wasm-ld llvm-nm; do
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
rm -f "$listing"

echo "packaged static LLVM SDK: $asset"
du -h "$asset" | awk '{print "  size: "$1}'
if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$asset"
else
    sha256sum "$asset"
fi
