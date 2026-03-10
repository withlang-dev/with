#!/usr/bin/env bash
set -euo pipefail

# Compile runtime C sources into out/lib/ and build static LLVM bridge.
# Called by `make build` before the stage chain runs.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OUT_LIB="${ROOT_DIR}/out/lib"
RUNTIME_SRC="${ROOT_DIR}/runtime"
EMBEDDED_STDLIB_INC="${OUT_LIB}/embedded_stdlib.inc.h"

mkdir -p "${OUT_LIB}"
python3 "${ROOT_DIR}/scripts/generate_embedded_stdlib.py" "${ROOT_DIR}" "${EMBEDDED_STDLIB_INC}"

# Compile C runtime objects from source.
sdk_path="$(xcrun --show-sdk-path 2>/dev/null || true)"
compile() {
  local src="$1" dst="$2"
  if [ -n "${sdk_path}" ]; then
    cc -isysroot "${sdk_path}" -c "${src}" -o "${dst}" 2>/dev/null
  else
    cc -c "${src}" -o "${dst}" 2>/dev/null
  fi
}

compile "${RUNTIME_SRC}/helpers.c" "${OUT_LIB}/helpers.o" || true
compile "${RUNTIME_SRC}/support_runtime.c" "${OUT_LIB}/support_runtime.o" || true
compile "${RUNTIME_SRC}/with_runtime.c" "${OUT_LIB}/with_runtime.o" || true
compile "${RUNTIME_SRC}/fiber.c" "${OUT_LIB}/fiber.o" || true

# Assemble fiber context switch.
arch="$(uname -m)"
case "$arch" in
  arm64|aarch64) asm_file="${RUNTIME_SRC}/fiber_asm_aarch64.s" ;;
  x86_64|amd64)  asm_file="${RUNTIME_SRC}/fiber_asm_x86_64.s" ;;
  *) asm_file="" ;;
esac
if [ -n "$asm_file" ] && [ -f "$asm_file" ]; then
  compile "$asm_file" "${OUT_LIB}/fiber_asm.o" || true
fi

# ── Static LLVM bridge ──────────────────────────────────────────────────
# Statically link LLVM into the compiler binary (like Zig does).
# Requires LLVM installed at LLVM_PREFIX (default: /usr/local/llvm).

LLVM_PREFIX="${LLVM_PREFIX:-/usr/local/llvm}"
LLVM_CC="${LLVM_PREFIX}/bin/clang"
LLVM_CONFIG="${LLVM_PREFIX}/bin/llvm-config"

if [ -x "$LLVM_CC" ] && [ -x "$LLVM_CONFIG" ]; then
  # Compile llvm_bridge.c with LLVM's clang against LLVM headers.
  if [ -n "${sdk_path}" ]; then
    "$LLVM_CC" -isysroot "${sdk_path}" -I"${LLVM_PREFIX}/include" \
      -c "${RUNTIME_SRC}/llvm_bridge.c" -o "${OUT_LIB}/llvm_bridge.o" 2>/dev/null || true
  else
    "$LLVM_CC" -I"${LLVM_PREFIX}/include" \
      -c "${RUNTIME_SRC}/llvm_bridge.c" -o "${OUT_LIB}/llvm_bridge.o" 2>/dev/null || true
  fi

  # Generate response file with LLVM static libs + system deps.
  if [ -f "${OUT_LIB}/llvm_bridge.o" ]; then
    "$LLVM_CONFIG" --link-static --libfiles \
      core support analysis passes \
      aarch64codegen aarch64asmparser aarch64desc aarch64info aarch64utils \
      codegen mc mcparser target targetparser bitwriter \
      objcarcopts linker selectiondag asmprinter globalisel \
      scalaropts instcombine ipo transformutils vectorize \
      instrumentation cfguard aggressiveinstcombine \
      irprinter hipstdpar coroutines sandboxir \
      frontendopenmp frontenddirective frontendatomic frontendoffloading \
      objectyaml cgdata codegentypes bitreader irreader asmparser \
      profiledata symbolize debuginfobtf debuginfopdb debuginfomsf \
      debuginfocodeview debuginfogsym debuginfodwarf debuginfodwarflowlevel \
      object textapi remarks bitstreamreader binaryformat \
      frontendhlsl demangle \
      2>/dev/null | tr ' ' '\n' > "${OUT_LIB}/llvm_link.rsp"

    # Append sysroot and system deps (lld needs explicit sysroot on macOS).
    {
      if [ -n "${sdk_path}" ]; then
        echo "-isysroot"
        echo "${sdk_path}"
      fi
      echo "-lm"
      echo "-lz"
      # Use static zstd if available, otherwise dynamic.
      if [ -f /opt/homebrew/lib/libzstd.a ]; then
        echo "/opt/homebrew/lib/libzstd.a"
      else
        echo "-lzstd"
      fi
      echo "-lxml2"
      echo "-lc++"
    } >> "${OUT_LIB}/llvm_link.rsp"

    # Write the LLVM clang path for Link.w to read.
    echo "${LLVM_CC}" > "${OUT_LIB}/llvm_cc"

    echo "static LLVM bridge: ${OUT_LIB}/llvm_bridge.o ($(wc -l < "${OUT_LIB}/llvm_link.rsp") link entries)"
  fi
else
  # No LLVM installation found — fall back to dylib from seed.
  if [ ! -f "${OUT_LIB}/libwith_llvm_bridge.dylib" ]; then
    with_bin="${WITH:-$(command -v with 2>/dev/null || true)}"
    if [ -n "$with_bin" ] && [ -x "$with_bin" ]; then
      seed_dir="$(cd "$(dirname "$with_bin")" && pwd -P)"
      for cand in \
        "${seed_dir}/runtime/libwith_llvm_bridge.dylib" \
        "${seed_dir}/../lib/libwith_llvm_bridge.dylib"; do
        if [ -f "$cand" ]; then
          cp "$cand" "${OUT_LIB}/libwith_llvm_bridge.dylib"
          break
        fi
      done
    fi
  fi
  if [ ! -f "${OUT_LIB}/libwith_llvm_bridge.dylib" ] && [ ! -f "${OUT_LIB}/llvm_bridge.o" ]; then
    echo "warning: no LLVM bridge available — install LLVM at ${LLVM_PREFIX} or provide libwith_llvm_bridge.dylib" >&2
  fi
fi
