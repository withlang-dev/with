#!/bin/sh
set -eu

asset="with-darwin-aarch64"
compiler="${WITH_RELEASE_COMPILER:-out/bin/with-stage2}"
source="${WITH_RELEASE_SOURCE:-out/gen/main.w}"
release_dir="${WITH_RELEASE_DIR:-out/release}"

if [ "${WITH_VERSION:-}" = "" ]; then
    echo "error: set WITH_VERSION, for example WITH_VERSION=v0.14.0" >&2
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

if [ ! -f "$source" ]; then
    echo "error: missing generated compiler source: $source" >&2
    echo "hint: run 'WITH_VERSION=$WITH_VERSION with build' first" >&2
    exit 1
fi

if [ ! -d out/lib ]; then
    echo "error: missing out/lib" >&2
    echo "hint: run 'WITH_VERSION=$WITH_VERSION with build' first" >&2
    exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/with-release.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT INT TERM

mkdir -p "$release_dir" "$tmp_dir/out"
cp -R out/lib "$tmp_dir/out/lib"

# The public bootstrap compiler must not require libclang at process startup.
# Keep the weak c_import stubs and static LLVM pieces, but omit the optional
# clang bridge object and its dynamic libclang link inputs.
rm -f "$tmp_dir/out/lib/clang_bridge.o"
awk 'index($0, "libclang") == 0 && index($0, "-rpath") == 0 { print }' \
    out/lib/llvm_link.rsp > "$tmp_dir/out/lib/llvm_link.rsp"

output="$release_dir/$asset"
WITH_OUT_DIR="$tmp_dir/out" "$compiler" build "$source" -o "$output"
chmod +x "$output"

version_output="$("$output" version)"
if [ "$version_output" != "with $WITH_VERSION" ]; then
    echo "error: release binary reported '$version_output', expected 'with $WITH_VERSION'" >&2
    exit 1
fi

if otool -L "$output" | grep -q 'libclang'; then
    echo "error: release binary links libclang dynamically" >&2
    otool -L "$output" >&2
    exit 1
fi

if nm -u "$output" | grep -E 'clang|LLVM' >/dev/null 2>&1; then
    echo "error: release binary has unresolved clang/LLVM symbols" >&2
    nm -u "$output" | grep -E 'clang|LLVM' >&2
    exit 1
fi

cp scripts/install.sh "$release_dir/install.sh"
chmod +x "$release_dir/install.sh"

shasum -a 256 "$output"
