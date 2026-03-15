#!/usr/bin/env bash
set -euo pipefail

# Download the seed compiler binary from the latest GitHub release.
# Usage: ./scripts/download_seed.sh [version]
#   version: release tag (default: latest)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${ROOT_DIR}/src/main"
REPO="QuixiAI/with"

if [ -x "$DEST" ]; then
  echo "seed binary already exists: $DEST"
  echo "remove it first if you want to re-download"
  exit 0
fi

VERSION="${1:-}"

if [ -n "$VERSION" ]; then
  URL="https://github.com/${REPO}/releases/download/${VERSION}/main"
else
  # Find the latest release that has the seed binary
  URL="$(gh release list --repo "$REPO" --limit 10 --json tagName,assets \
    -q '[.[] | select(.assets | map(.name) | index("main"))] | .[0].tagName' 2>/dev/null || true)"
  if [ -z "$URL" ]; then
    echo "error: could not find a release with seed binary" >&2
    echo "install gh CLI and authenticate, or specify a version:" >&2
    echo "  $0 v0.5.2-uaf" >&2
    exit 1
  fi
  echo "latest seed release: $URL"
  URL="https://github.com/${REPO}/releases/download/${URL}/main"
fi

echo "downloading seed from: $URL"
curl -fSL -o "$DEST" "$URL"
chmod +x "$DEST"
echo "seed installed: $DEST"
