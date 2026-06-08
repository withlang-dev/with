#!/bin/sh
set -eu

asset="with-linux-x86_64"
compiler="${WITH_RELEASE_COMPILER:-out/release/bin/with}"
release_dir="${WITH_RELEASE_DIR:-out/release}"

if [ "${WITH_VERSION:-}" = "" ]; then
    echo "error: set WITH_VERSION, for example WITH_VERSION=v0.14.3" >&2
    exit 1
fi

source_version="$(sed -n '1{s/[[:space:]]*$//;p;}' src/version)"
if [ "$source_version" != "$WITH_VERSION" ]; then
    echo "error: src/version is '$source_version', expected '$WITH_VERSION'" >&2
    echo "update src/version and build the release from that committed version" >&2
    exit 1
fi

case "$(uname -s):$(uname -m)" in
    Linux:x86_64) ;;
    *)
        echo "error: this package script creates only Linux x86_64 artifacts" >&2
        exit 1
        ;;
esac

if [ ! -x "$compiler" ]; then
    echo "error: missing compiler: $compiler" >&2
    exit 1
fi

output="$release_dir/$asset"
mkdir -p "$release_dir"
cp "$compiler" "$output"
chmod +x "$output"

version_output="$("$output" version)"
if [ "$version_output" != "with $WITH_VERSION" ]; then
    echo "error: release binary reported '$version_output', expected 'with $WITH_VERSION'" >&2
    exit 1
fi

if ldd "$output" | grep -E 'clang|LLVM|libz|libxml2|zstd|libstdc\+\+|libgcc_s' >/dev/null 2>&1; then
    echo "error: release binary has forbidden dynamic compiler/support dependency" >&2
    ldd "$output" >&2
    exit 1
fi

if ! nm -g "$output" | grep 'clang_createIndex' >/dev/null 2>&1; then
    echo "error: release binary does not contain static libclang symbols" >&2
    exit 1
fi

llvm_version="${LLVM_VERSION:-22.1.6}"
llvm_prefix="${LLVM_PREFIX:-.deps/llvm-${llvm_version}-linux-x86_64}"
llvm_strip="${LLVM_STRIP:-$llvm_prefix/bin/llvm-strip}"
if [ ! -x "$llvm_strip" ]; then
    echo "error: missing With-owned llvm-strip: $llvm_strip" >&2
    echo "run with build :deps or build/package the static SDK first" >&2
    exit 1
fi
"$llvm_strip" "$output"

if ldd "$output" | grep -E 'clang|LLVM|libz|libxml2|zstd|libstdc\+\+|libgcc_s' >/dev/null 2>&1; then
    echo "error: stripped release binary has forbidden dynamic compiler/support dependency" >&2
    ldd "$output" >&2
    exit 1
fi

cp scripts/install.sh "$release_dir/install.sh"
chmod +x "$release_dir/install.sh"

sha256sum "$output"
