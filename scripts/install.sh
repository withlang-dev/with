#!/bin/sh
set -eu

repo="withlang-dev/with"
asset="with-darwin-aarch64"
install_dir="${WITH_INSTALL_DIR:-$HOME/.local/bin}"
install_name="${WITH_INSTALL_NAME:-with}"
version="${WITH_VERSION:-latest}"

case "$(uname -s)" in
    Darwin) ;;
    *)
        echo "error: this installer currently supports macOS only" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    arm64|aarch64) ;;
    *)
        echo "error: this installer currently supports Darwin arm64 only" >&2
        exit 1
        ;;
esac

if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl is required" >&2
    exit 1
fi

if [ "$version" = "latest" ]; then
    url="https://github.com/$repo/releases/latest/download/$asset"
else
    url="https://github.com/$repo/releases/download/$version/$asset"
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/with-install.XXXXXX")"
tmp_bin="$tmp_dir/$install_name"
trap 'rm -rf "$tmp_dir"' EXIT INT TERM

mkdir -p "$install_dir"

echo "downloading $url"
curl -fsSL "$url" -o "$tmp_bin"
chmod +x "$tmp_bin"
mv "$tmp_bin" "$install_dir/$install_name"

echo "installed $install_dir/$install_name"
"$install_dir/$install_name" version

case ":$PATH:" in
    *":$install_dir:"*) ;;
    *)
        echo "note: add $install_dir to PATH to run '$install_name' from any shell" >&2
        ;;
esac
