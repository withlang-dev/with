#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VERSION_FILE="${ROOT_DIR}/src/version"

read_fallback_version() {
  if [ ! -f "${VERSION_FILE}" ]; then
    echo "error: missing version file: ${VERSION_FILE}" >&2
    exit 1
  fi

  local version=""
  version="$(sed -n '1{s/[[:space:]]*$//;p;}' "${VERSION_FILE}")"
  if [ -z "${version}" ]; then
    echo "error: empty version in ${VERSION_FILE}" >&2
    exit 1
  fi
  printf '%s\n' "${version}"
}

if [ -n "${WITH_VERSION:-}" ]; then
  printf '%s\n' "${WITH_VERSION}"
  exit 0
fi

fallback_version="$(read_fallback_version)"

if git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  describe="$(git -C "${ROOT_DIR}" describe --tags --dirty --always --match 'v*' 2>/dev/null || true)"
  if [ -n "${describe}" ]; then
    clean_describe="${describe%-dirty}"
    if [[ "${clean_describe}" == v* ]]; then
      if [[ ! "${clean_describe}" =~ -[0-9]+-g[0-9a-f]+$ ]] && [ "${clean_describe}" != "${fallback_version}" ]; then
        echo "error: src/version (${fallback_version}) does not match current tag (${clean_describe})" >&2
        exit 1
      fi
      printf '%s\n' "${describe}"
      exit 0
    fi
  fi

  short_hash="$(git -C "${ROOT_DIR}" rev-parse --short=9 HEAD 2>/dev/null || true)"
  if [ -n "${short_hash}" ]; then
    dirty_suffix=""
    if ! git -C "${ROOT_DIR}" diff --quiet --ignore-submodules=dirty -- || \
       ! git -C "${ROOT_DIR}" diff --cached --quiet --ignore-submodules=dirty --; then
      dirty_suffix="-dirty"
    fi
    printf '%s-g%s%s\n' "${fallback_version}" "${short_hash}" "${dirty_suffix}"
    exit 0
  fi
fi

printf '%s\n' "${fallback_version}"
