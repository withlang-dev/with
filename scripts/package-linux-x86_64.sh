#!/bin/sh
set -eu

asset="with-linux-x86_64"
compiler="${WITH_RELEASE_COMPILER:-out/bin/with}"
release_dir="${WITH_RELEASE_DIR:-out/release}"

if [ "${WITH_VERSION:-}" = "" ]; then
    echo "error: set WITH_VERSION, for example WITH_VERSION=v0.14.3" >&2
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

cp scripts/install.sh "$release_dir/install.sh"
chmod +x "$release_dir/install.sh"

sha256sum "$output"
