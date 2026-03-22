#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MODE="${1:-stage2}"

cd "${ROOT_DIR}"

case "${MODE}" in
  stage1)
    exec make stage1
    ;;
  stage2)
    exec make stage2
    ;;
  stage3|all)
    exec make stage3
    ;;
  *)
    echo "usage: $0 [stage1|stage2|stage3|all]" >&2
    exit 2
    ;;
esac
