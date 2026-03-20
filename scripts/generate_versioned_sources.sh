#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OUT_ARG="${1:-out}"

if [[ "${OUT_ARG}" = /* ]]; then
  OUT_DIR="${OUT_ARG}"
else
  OUT_DIR="${ROOT_DIR}/${OUT_ARG}"
fi

GEN_DIR="${OUT_DIR}/gen"
VERSION_FILE="${OUT_DIR}/gen/version.txt"
VERSION="$("${ROOT_DIR}/scripts/resolve_version.sh")"
PLACEHOLDER="WITH_VERSION_PLACEHOLDER"

mkdir -p "${GEN_DIR}"
rm -rf "${GEN_DIR}/src"

escape_for_sed() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//\//\\/}"
  value="${value//\"/\\\"}"
  printf '%s' "${value}"
}

generate_entry() {
  local src_rel="$1"
  local dst_name="$2"
  local escaped_version=""

  escaped_version="$(escape_for_sed "${VERSION}")"
  sed "s/${PLACEHOLDER}/${escaped_version}/g" "${ROOT_DIR}/${src_rel}" > "${GEN_DIR}/${dst_name}"
}
generate_entry "src/main.w" "main.w"
generate_entry "src/bootstrap_main.w" "bootstrap_main.w"
generate_entry "src/main_emit_temp.w" "main_emit_temp.w"
printf '%s\n' "${VERSION}" > "${VERSION_FILE}"
