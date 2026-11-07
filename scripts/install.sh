#!/bin/sh
set -eu

repo="withlang-dev/with"
install_dir="${WITH_INSTALL_DIR:-$HOME/.local/bin}"
install_name="${WITH_INSTALL_NAME:-with}"
version="${WITH_VERSION:-latest}"

case "$(uname -s):$(uname -m)" in
    Darwin:arm64|Darwin:aarch64)
        asset="with-darwin-aarch64"
        ;;
    Linux:x86_64)
        asset="with-linux-x86_64"
        ;;
    *)
        echo "error: unsupported platform: $(uname -s)/$(uname -m)" >&2
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

# Every release publishes <asset>.sha256 beside the binary (#3003). Its first
# field is the digest; the second is the path CI hashed, so only the first
# field is compared. A mismatch is a truncated or altered download: it is
# removed, never installed, never run.
curl -fsSL "$url.sha256" -o "$tmp_bin.sha256"
expected="$(cut -d' ' -f1 "$tmp_bin.sha256")"
if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$tmp_bin" | cut -d' ' -f1)"
else
    actual="$(shasum -a 256 "$tmp_bin" | cut -d' ' -f1)"
fi
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    echo "error: checksum mismatch for $asset" >&2
    echo "  published: $expected" >&2
    echo "  downloaded: $actual" >&2
    exit 1
fi

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
