#!/bin/sh
set -eu

asset="with-darwin-aarch64"
compiler="${WITH_RELEASE_COMPILER:-out/release/bin/with}"
release_dir="${WITH_RELEASE_DIR:-out/release}"

if [ "${WITH_VERSION:-}" = "" ]; then
    echo "error: set WITH_VERSION, for example WITH_VERSION=v0.14.0" >&2
    exit 1
fi

source_version="$(sed -n '1{s/[[:space:]]*$//;p;}' src/version)"
if [ "$source_version" != "$WITH_VERSION" ]; then
    echo "error: src/version is '$source_version', expected '$WITH_VERSION'" >&2
    echo "update src/version and build the release from that committed version" >&2
    exit 1
fi

case "$(uname -s)" in
    Darwin) ;;
    *)
        echo "error: Darwin release packaging must run on macOS" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    arm64|aarch64) ;;
    *)
        echo "error: this package script creates only Darwin arm64 artifacts" >&2
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

if otool -L "$output" | grep -E 'clang|LLVM|libz|libxml2|zstd' >/dev/null 2>&1; then
    echo "error: release binary has forbidden dynamic LLVM/Clang/support dependency" >&2
    otool -L "$output" >&2
    exit 1
fi

if ! nm -g "$output" | grep '_clang_createIndex' >/dev/null 2>&1; then
    echo "error: release binary does not contain static libclang symbols" >&2
    exit 1
fi

cp scripts/install.sh "$release_dir/install.sh"
chmod +x "$release_dir/install.sh"

shasum -a 256 "$output"
