SHELL := /bin/bash

.PHONY: all build stage1 stage2 stage3 runtime selfcheck smoke test fixpoint install install-user update-seed clean seed print-version FORCE \
	__build __stage1 __stage2 __stage3 __runtime __selfcheck __smoke __test __fixpoint __install __install-user __update-seed __clean __seed

ROOT_DIR := $(CURDIR)
REPO_FULL_NAME ?= QuixiAI/with

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DESTDIR ?=
OUT ?= out

LLVM_PREFIX ?= /usr/local/llvm
LLVM_CC_BIN := $(LLVM_PREFIX)/bin/clang
LLVM_CONFIG_BIN := $(LLVM_PREFIX)/bin/llvm-config
HOST_CC ?= cc
SDK_PATH := $(shell xcrun --show-sdk-path 2>/dev/null || true)
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

OUT_BIN_DIR := $(OUT)/bin
OUT_LIB_DIR := $(OUT)/lib
OUT_LOG_DIR := $(OUT)/log
OUT_TMP_DIR := $(OUT)/tmp
OUT_GEN_DIR := $(OUT)/gen

GEN_MAIN_ENTRY := $(OUT_GEN_DIR)/main.w
GEN_BOOTSTRAP_ENTRY := $(OUT_GEN_DIR)/bootstrap_main.w
GEN_EMIT_TEMP_ENTRY := $(OUT_GEN_DIR)/main_emit_temp.w
GEN_VERSION_FILE := $(OUT_GEN_DIR)/version.txt
GEN_STAMP := $(OUT_GEN_DIR)/.generated-stamp

RUNTIME_LINK := $(OUT_BIN_DIR)/runtime
EMBEDDED_STDLIB_RUNTIME_SRC := $(OUT_GEN_DIR)/embedded_stdlib_runtime.w
COMPAT_RUNTIME_SRC := $(OUT_GEN_DIR)/compat_runtime.w
EMBEDDED_OBJECTS_ASM := $(OUT_LIB_DIR)/embedded_objects.s
HELPERS_OBJ := $(OUT_LIB_DIR)/helpers.o
COMPAT_RUNTIME_OBJ := $(OUT_LIB_DIR)/compat_runtime.o
PANIC_RUNTIME_OBJ := $(OUT_LIB_DIR)/panic_runtime.o
FIBER_STUBS_OBJ := $(OUT_LIB_DIR)/fiber_stubs.o
CHANNEL_RUNTIME_OBJ := $(OUT_LIB_DIR)/channel_runtime.o
FIBER_RUNTIME_OBJ := $(OUT_LIB_DIR)/fiber_runtime.o
FIBER_OBJ := $(OUT_LIB_DIR)/fiber.o
FIBER_ASM_OBJ := $(OUT_LIB_DIR)/fiber_asm.o
EMBEDDED_OBJECTS_OBJ := $(OUT_LIB_DIR)/embedded_objects.o
LLVM_BRIDGE_OBJ := $(OUT_LIB_DIR)/llvm_bridge.o
CLANG_BRIDGE_OBJ := $(OUT_LIB_DIR)/clang_bridge.o
LLVM_LINK_RSP := $(OUT_LIB_DIR)/llvm_link.rsp
LLVM_CC_FILE := $(OUT_LIB_DIR)/llvm_cc
LLVM_LINK_STAMP := $(OUT_LIB_DIR)/.llvm-link-ready
RUNTIME_C_ALLOWLIST_STAMP := $(OUT_GEN_DIR)/.runtime-c-allowlist

STAGE1_BIN := $(OUT_BIN_DIR)/with-stage1
STAGE2_BIN := $(OUT_BIN_DIR)/with-stage2
STAGE3_BIN := $(OUT_BIN_DIR)/with-stage3
CANONICAL_BIN := $(OUT_BIN_DIR)/with
STAGE1_TMP := $(OUT_BIN_DIR)/with-stage1-build
STAGE_BUILD_TMP := $(OUT_BIN_DIR)/with-stage-build

USER_BINDIR ?= $(HOME)/.local/bin
USER_LIBDIR := $(USER_BINDIR)/runtime

VERSION_SOURCE_FILE := src/version
VERSION_PLACEHOLDER := WITH_VERSION_PLACEHOLDER
SEED_PATH := src/main
SEED_VERSION ?=

# Seed compiler: WITH env var, local build outputs, `with` on PATH, or
# src/main (downloaded). Preferring local stage outputs keeps smoke/fixpoint
# on the freshly built compiler instead of a potentially stale installed one.
WITH ?= $(shell \
	if [ -x "$(CANONICAL_BIN)" ]; then \
		printf '%s\n' "$(CANONICAL_BIN)"; \
	elif [ -x "$(STAGE2_BIN)" ]; then \
		printf '%s\n' "$(STAGE2_BIN)"; \
	elif command -v with >/dev/null 2>&1; then \
		command -v with; \
	elif [ -x "$(SEED_PATH)" ]; then \
		printf '%s\n' "$(SEED_PATH)"; \
	fi)

INSTALL_BINDIR := $(DESTDIR)$(BINDIR)
INSTALL_LIBDIR := $(INSTALL_BINDIR)/runtime

ifeq ($(filter $(UNAME_M),arm64 aarch64),$(UNAME_M))
FIBER_ASM_SRC := runtime/fiber_asm_aarch64.s
endif
ifeq ($(filter $(UNAME_M),x86_64 amd64),$(UNAME_M))
FIBER_ASM_SRC := runtime/fiber_asm_x86_64.s
endif
ifeq ($(UNAME_S),Darwin)
FIBER_CORE_SRC := rt/fiber_core_darwin.w
endif

LIBCLANG_FILE := $(firstword $(wildcard $(LLVM_PREFIX)/lib/libclang.dylib) $(wildcard $(LLVM_PREFIX)/lib/libclang.so))

# libc-free runtime objects for user programs
RT_CORE_OBJ := $(OUT_LIB_DIR)/rt_core.o
RT_DARWIN_AARCH64_OBJ := $(OUT_LIB_DIR)/rt_darwin_aarch64.o

# Core runtime artifacts needed by the compiler itself.
RUNTIME_ARTIFACTS := \
	$(HELPERS_OBJ) \
	$(COMPAT_RUNTIME_OBJ) \
	$(PANIC_RUNTIME_OBJ) \
	$(FIBER_STUBS_OBJ) \
	$(CHANNEL_RUNTIME_OBJ) \
	$(FIBER_RUNTIME_OBJ) \
	$(FIBER_OBJ) \
	$(FIBER_ASM_OBJ) \
	$(EMBEDDED_OBJECTS_OBJ) \
	$(LLVM_BRIDGE_OBJ) \
	$(CLANG_BRIDGE_OBJ) \
	$(LLVM_LINK_STAMP)

# With-language runtime objects (compiled by the With compiler, built after stage2)
RT_WITH_ARTIFACTS := $(RT_CORE_OBJ) $(RT_DARWIN_AARCH64_OBJ)
RT_WITH_REFRESH_STAMP := $(OUT_GEN_DIR)/.runtime-with-refresh

# Version resolution:
#   Source of truth: src/version (e.g., "v0.12.0")
#   Git provides: commit count + short hash for dev builds
#   Override: WITH_VERSION env var
# No --dirty flag: version reflects committed state only.
# No commit required: base version always works.
define RESOLVE_VERSION_SH
set -euo pipefail; \
base="$$(sed -n '1{s/[[:space:]]*$$//;p;}' "$(VERSION_SOURCE_FILE)")"; \
if [ -z "$$base" ]; then \
	echo "error: empty or missing version in $(VERSION_SOURCE_FILE)" >&2; \
	exit 1; \
fi; \
if [ -n "$${WITH_VERSION:-}" ]; then \
	printf '%s\n' "$${WITH_VERSION}"; \
	exit 0; \
fi; \
if git -C "$(ROOT_DIR)" rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
	short_hash="$$(git -C "$(ROOT_DIR)" rev-parse --short=9 HEAD 2>/dev/null || true)"; \
	commit_count="$$(git -C "$(ROOT_DIR)" rev-list --count HEAD 2>/dev/null || true)"; \
	if [ -n "$$short_hash" ] && [ -n "$$commit_count" ]; then \
		printf '%s-%s-g%s\n' "$$base" "$$commit_count" "$$short_hash"; \
		exit 0; \
	fi; \
fi; \
printf '%s\n' "$$base"
endef

define HOST_COMPILE
	@set -euo pipefail; \
	sdk="$(SDK_PATH)"; \
	if [ -n "$$sdk" ]; then \
		$(HOST_CC) -isysroot "$$sdk" $(1) -c "$<" -o "$@"; \
	else \
		$(HOST_CC) $(1) -c "$<" -o "$@"; \
	fi
endef

define LLVM_COMPILE
	@set -euo pipefail; \
	if [ ! -x "$(LLVM_CC_BIN)" ]; then \
		echo "error: missing LLVM clang at $(LLVM_CC_BIN)" >&2; \
		exit 1; \
	fi; \
	sdk="$(SDK_PATH)"; \
	if [ -n "$$sdk" ]; then \
		"$(LLVM_CC_BIN)" -isysroot "$$sdk" -I"$(LLVM_PREFIX)/include" $(1) -c "$<" -o "$@"; \
	else \
		"$(LLVM_CC_BIN)" -I"$(LLVM_PREFIX)/include" $(1) -c "$<" -o "$@"; \
	fi
endef

all: build

REPO_SERIAL_LOCK := $(OUT_TMP_DIR)/repo-serial.lock

define WITH_REPO_LOCK
	@set -euo pipefail; \
	lock="$(REPO_SERIAL_LOCK)"; \
	owner_file="$$lock/owner"; \
	if mkdir "$$lock" 2>/dev/null; then \
		trap 'rm -rf "$$lock"' EXIT INT TERM HUP; \
		printf 'target=%s pid=%s started=%s\n' "$@" "$$" "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$$owner_file"; \
		$(1); \
	else \
		if [ -f "$$owner_file" ]; then \
			owner="$$(cat "$$owner_file")"; \
		else \
			owner="target=<unknown> pid=<unknown> started=<unknown>"; \
		fi; \
		echo "error: another top-level build/check/test/install target is already running: $$owner" >&2; \
		echo "run build, selfcheck, smoke, test, fixpoint, install, and clean serially" >&2; \
		exit 1; \
	fi
endef

build: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __build)

stage1: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __stage1)

stage2: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __stage2)

stage3: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __stage3)

runtime: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __runtime)

selfcheck: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __selfcheck)

smoke: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __smoke)

print-version:
	@$(RESOLVE_VERSION_SH)

seed: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __seed)

__build: $(CANONICAL_BIN)

__stage1: $(STAGE1_BIN)

__stage2: $(STAGE2_BIN)

__stage3: $(STAGE3_BIN)

__runtime: $(RUNTIME_LINK)

__selfcheck: $(STAGE2_BIN)
	./out/bin/with-stage2 check src/main.w

__smoke: $(STAGE2_BIN)
	./out/bin/with-stage2 check src/main.w

__seed:
	@set -euo pipefail; \
	dest="$(SEED_PATH)"; \
	repo="$(REPO_FULL_NAME)"; \
	if [ -x "$$dest" ]; then \
		echo "seed binary already exists: $$dest"; \
		echo "remove it first if you want to re-download"; \
		exit 0; \
	fi; \
	tag="$(SEED_VERSION)"; \
	if [ -z "$$tag" ]; then \
		tag="$$(gh release list --repo "$$repo" --limit 10 --json tagName,assets -q '[.[] | select(.assets | map(.name) | index("main"))] | .[0].tagName' 2>/dev/null || true)"; \
		if [ -z "$$tag" ]; then \
			echo "error: could not find a release with seed binary" >&2; \
			echo "install gh CLI and authenticate, or specify one:" >&2; \
			echo "  make seed SEED_VERSION=v0.5.2-uaf" >&2; \
			exit 1; \
		fi; \
		echo "latest seed release: $$tag"; \
	fi; \
	url="https://github.com/$$repo/releases/download/$$tag/main"; \
	echo "downloading seed from: $$url"; \
	curl -fSL -o "$$dest" "$$url"; \
	chmod +x "$$dest"; \
	echo "seed installed: $$dest"

$(OUT_BIN_DIR) $(OUT_LIB_DIR) $(OUT_LOG_DIR) $(OUT_TMP_DIR) $(OUT_GEN_DIR):
	@mkdir -p "$@"

$(GEN_STAMP): FORCE | $(OUT_BIN_DIR) $(OUT_LIB_DIR) $(OUT_LOG_DIR) $(OUT_TMP_DIR) $(OUT_GEN_DIR)
	@set -euo pipefail; \
	version="$$( $(MAKE) --no-print-directory -s print-version )"; \
	escaped="$$version"; \
	escaped="$${escaped//\\/\\\\}"; \
	escaped="$${escaped//&/\\&}"; \
	escaped="$${escaped//\//\\/}"; \
	escaped="$${escaped//\"/\\\"}"; \
	sed "s/$(VERSION_PLACEHOLDER)/$$escaped/g" "$(ROOT_DIR)/src/main.w" > "$(GEN_MAIN_ENTRY)"; \
	sed "s/$(VERSION_PLACEHOLDER)/$$escaped/g" "$(ROOT_DIR)/src/bootstrap_main.w" > "$(GEN_BOOTSTRAP_ENTRY)"; \
	sed "s/$(VERSION_PLACEHOLDER)/$$escaped/g" "$(ROOT_DIR)/src/main_emit_temp.w" > "$(GEN_EMIT_TEMP_ENTRY)"; \
	printf '%s\n' "$$version" > "$(GEN_VERSION_FILE)"; \
	touch "$@"

STD_SOURCES := $(shell find lib/std -name '*.w' 2>/dev/null)
$(EMBEDDED_STDLIB_RUNTIME_SRC): scripts/generate_embedded_stdlib.py $(STD_SOURCES) | $(OUT_GEN_DIR)
	@python3 "$(ROOT_DIR)/scripts/generate_embedded_stdlib.py" "$(ROOT_DIR)" "$@"

$(COMPAT_RUNTIME_SRC): rt/compat_runtime.w $(EMBEDDED_STDLIB_RUNTIME_SRC) | $(OUT_GEN_DIR)
	@cat "$(ROOT_DIR)/rt/compat_runtime.w" "$(EMBEDDED_STDLIB_RUNTIME_SRC)" > "$@"

$(RUNTIME_C_ALLOWLIST_STAMP): scripts/check_runtime_c_allowlist.sh $(wildcard runtime/*.c) | $(OUT_GEN_DIR)
	@bash "$(ROOT_DIR)/scripts/check_runtime_c_allowlist.sh" \
		runtime/clang_bridge.c \
		runtime/helpers.c \
		runtime/llvm_bridge.c \
		runtime/with_runtime.c
	@touch "$@"

$(HELPERS_OBJ): runtime/helpers.c | $(OUT_LIB_DIR)
	$(call HOST_COMPILE,)

$(COMPAT_RUNTIME_OBJ): $(COMPAT_RUNTIME_SRC) | $(OUT_LIB_DIR)
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(WITH) build $< --emit-obj --no-prelude -O0 -o $@

$(PANIC_RUNTIME_OBJ): rt/panic_runtime.w | $(OUT_LIB_DIR)
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(WITH) build $< --emit-obj --no-prelude -O0 -o $@

$(FIBER_STUBS_OBJ): rt/fiber_stubs.w | $(OUT_LIB_DIR)
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(WITH) build $< --emit-obj --no-prelude -O0 -o $@

$(CHANNEL_RUNTIME_OBJ): rt/channel_runtime.w | $(OUT_LIB_DIR)
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(WITH) build $< --emit-obj --no-prelude -O0 -o $@

$(FIBER_RUNTIME_OBJ): rt/fiber_runtime.w | $(OUT_LIB_DIR)
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(WITH) build $< --emit-obj --no-prelude -O0 -o $@

$(FIBER_OBJ): $(FIBER_CORE_SRC) | $(OUT_LIB_DIR)
	@if [ -z "$(FIBER_CORE_SRC)" ]; then echo "error: unsupported host platform $(UNAME_S)/$(UNAME_M) for fiber runtime" >&2; exit 1; fi
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(WITH) build $< --emit-obj --no-prelude -O0 -o $@

$(FIBER_ASM_OBJ): $(FIBER_ASM_SRC) | $(OUT_LIB_DIR)
	@if [ -z "$(FIBER_ASM_SRC)" ]; then echo "error: unsupported host architecture $(UNAME_M) for fiber_asm.o" >&2; exit 1; fi
	$(call HOST_COMPILE,)

$(RT_CORE_OBJ): rt/rt_core.w $(STAGE2_BIN) | $(OUT_LIB_DIR)
	$(STAGE2_BIN) build $< --emit-obj --no-prelude -O2 -o $@

# Compile With runtime backend to .o using the With compiler (after stage2 exists)
$(RT_DARWIN_AARCH64_OBJ): rt/darwin_aarch64.w $(STAGE2_BIN) | $(OUT_LIB_DIR)
	$(STAGE2_BIN) build $< --emit-obj --no-prelude -O2 -o $@

$(RT_WITH_REFRESH_STAMP): $(STAGE2_BIN) $(COMPAT_RUNTIME_SRC) rt/panic_runtime.w rt/fiber_stubs.w rt/channel_runtime.w rt/fiber_runtime.w $(FIBER_CORE_SRC) | $(OUT_LIB_DIR) $(OUT_GEN_DIR)
	$(STAGE2_BIN) build $(COMPAT_RUNTIME_SRC) --emit-obj --no-prelude -O0 -o $(COMPAT_RUNTIME_OBJ)
	$(STAGE2_BIN) build rt/panic_runtime.w --emit-obj --no-prelude -O0 -o $(PANIC_RUNTIME_OBJ)
	$(STAGE2_BIN) build rt/fiber_stubs.w --emit-obj --no-prelude -O0 -o $(FIBER_STUBS_OBJ)
	$(STAGE2_BIN) build rt/channel_runtime.w --emit-obj --no-prelude -O0 -o $(CHANNEL_RUNTIME_OBJ)
	$(STAGE2_BIN) build rt/fiber_runtime.w --emit-obj --no-prelude -O0 -o $(FIBER_RUNTIME_OBJ)
	$(STAGE2_BIN) build $(FIBER_CORE_SRC) --emit-obj --no-prelude -O0 -o $(FIBER_OBJ)
	@touch "$@"

$(EMBEDDED_OBJECTS_ASM): scripts/embed_runtime_objects.sh $(HELPERS_OBJ) $(COMPAT_RUNTIME_OBJ) $(PANIC_RUNTIME_OBJ) $(FIBER_STUBS_OBJ) $(CHANNEL_RUNTIME_OBJ) $(FIBER_RUNTIME_OBJ) $(FIBER_OBJ) $(FIBER_ASM_OBJ) | $(OUT_LIB_DIR)
	@bash "$(ROOT_DIR)/scripts/embed_runtime_objects.sh" "$(OUT_LIB_DIR)" "$@"

$(EMBEDDED_OBJECTS_OBJ): $(EMBEDDED_OBJECTS_ASM) | $(OUT_LIB_DIR)
	$(call HOST_COMPILE,)

$(LLVM_BRIDGE_OBJ): runtime/llvm_bridge.c | $(OUT_LIB_DIR)
	@if [ ! -x "$(LLVM_CONFIG_BIN)" ]; then echo "error: missing llvm-config at $(LLVM_CONFIG_BIN)" >&2; exit 1; fi
	$(call LLVM_COMPILE,)

$(CLANG_BRIDGE_OBJ): runtime/clang_bridge.c | $(OUT_LIB_DIR)
	@if [ ! -f "$(LLVM_PREFIX)/include/clang-c/Index.h" ]; then echo "error: missing clang-c/Index.h under $(LLVM_PREFIX)/include" >&2; exit 1; fi
	$(call LLVM_COMPILE,)

$(LLVM_LINK_STAMP): $(LLVM_BRIDGE_OBJ) $(CLANG_BRIDGE_OBJ) | $(OUT_LIB_DIR)
	@set -euo pipefail; \
	if [ ! -x "$(LLVM_CONFIG_BIN)" ]; then \
		echo "error: missing llvm-config at $(LLVM_CONFIG_BIN)" >&2; \
		exit 1; \
	fi; \
	if [ -z "$(LIBCLANG_FILE)" ]; then \
		echo "error: missing libclang under $(LLVM_PREFIX)/lib" >&2; \
		exit 1; \
	fi; \
	"$(LLVM_CONFIG_BIN)" --link-static --libfiles \
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
		2>/dev/null | tr ' ' '\n' > "$(LLVM_LINK_RSP)"; \
	{ \
		if [ -n "$(SDK_PATH)" ]; then \
			echo "-isysroot"; \
			echo "$(SDK_PATH)"; \
		fi; \
		echo "-lm"; \
		echo "-lz"; \
		if [ -f /opt/homebrew/lib/libzstd.a ]; then \
			echo "/opt/homebrew/lib/libzstd.a"; \
		else \
			echo "-lzstd"; \
		fi; \
		echo "-lxml2"; \
		echo "-lc++"; \
		echo "$(LIBCLANG_FILE)"; \
		echo "-Wl,-rpath,$(dir $(LIBCLANG_FILE))"; \
	} >> "$(LLVM_LINK_RSP)"; \
	printf '%s\n' "$(LLVM_CC_BIN)" > "$(LLVM_CC_FILE)"; \
	lines="$$(wc -l < "$(LLVM_LINK_RSP)")"; \
	echo "static LLVM bridge: $(LLVM_BRIDGE_OBJ) ($$lines link entries)"; \
	echo "clang bridge: $(CLANG_BRIDGE_OBJ) (libclang c_import support)"; \
	touch "$@"

$(RUNTIME_LINK): $(RUNTIME_ARTIFACTS) $(RUNTIME_C_ALLOWLIST_STAMP) | $(OUT_BIN_DIR)
	@if [ -L "$@" ]; then rm -f "$@"; elif [ -e "$@" ]; then rm -rf "$@"; fi
	@ln -s ../lib "$@"

define build_stage
	@tmp="$(3)"; \
	dsym="$$tmp.dSYM"; \
	gen_bin="$(OUT_GEN_DIR)/main"; \
	gen_dsym="$(OUT_GEN_DIR)/main.dSYM"; \
	child_pid=""; \
	cleanup_build_stage() { \
		status="$$1"; \
		sig="$$2"; \
		trap - EXIT INT TERM HUP; \
		if [ -n "$$child_pid" ] && kill -0 "$$child_pid" 2>/dev/null; then \
			if [ -n "$$sig" ]; then \
				kill -s "$$sig" "$$child_pid" 2>/dev/null || true; \
			else \
				kill "$$child_pid" 2>/dev/null || true; \
			fi; \
			wait "$$child_pid" 2>/dev/null || true; \
		fi; \
		rm -f "$$tmp" "$$gen_bin"; \
		rm -rf "$$dsym" "$$gen_dsym"; \
		exit "$$status"; \
	}; \
	trap 'cleanup_build_stage $$? ""' EXIT; \
	trap 'cleanup_build_stage 130 INT' INT; \
	trap 'cleanup_build_stage 143 TERM' TERM; \
	trap 'cleanup_build_stage 129 HUP' HUP; \
	rm -f "$$tmp" "$$gen_bin" "$@"; \
	rm -rf "$$dsym" "$$gen_dsym" "$@.dSYM"; \
	$(1) build $(GEN_MAIN_ENTRY) -o "$$tmp" $(4) & \
	child_pid="$$!"; \
	wait "$$child_pid"; \
	rc=$$?; \
	child_pid=""; \
	if [ $$rc -ne 0 ]; then echo "error: build failed" >&2; exit $$rc; fi; \
	if [ ! -x "$$tmp" ]; then mv "$$gen_bin" "$$tmp" 2>/dev/null || true; fi; \
	if [ -d "$$gen_dsym" ]; then mv "$$gen_dsym" "$$dsym" 2>/dev/null || true; fi; \
	if [ ! -x "$$tmp" ]; then echo "error: no output binary produced" >&2; exit 1; fi; \
	cp "$$tmp" "$@"; \
	if [ -d "$$dsym" ]; then cp -R "$$dsym" "$@.dSYM"; fi; \
	rm -f "$$tmp"; \
	rm -rf "$$dsym"; \
	echo "[$(2)] wrote $@"
endef

$(STAGE1_BIN): $(GEN_STAMP) $(RUNTIME_LINK)
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(call build_stage,$(WITH),stage1,$(STAGE1_TMP),-O0)

$(STAGE2_BIN): $(STAGE1_BIN) $(GEN_STAMP) $(RUNTIME_LINK)
	@rm -rf "$(HOME)/.cache/with/c_import"
	$(call build_stage,$(STAGE1_BIN),stage2,$(STAGE_BUILD_TMP),-O0)

$(STAGE3_BIN): $(STAGE2_BIN) $(GEN_STAMP) $(RUNTIME_LINK)
	@rm -rf "$(HOME)/.cache/with/c_import"
	$(call build_stage,$(STAGE2_BIN),stage3,$(STAGE_BUILD_TMP),-O0)

# Build the canonical binary with embedded runtime objects.
# Phase 1 (during EMBEDDED_OBJECTS_ASM): embeds C-compiled objects (helpers, etc.)
# Phase 2 (here): re-embeds with With-compiled rt_core + rt_darwin_aarch64,
# recompiles the generated assembly payload, and has the compiler re-link itself.
$(CANONICAL_BIN): $(STAGE2_BIN) $(RT_WITH_ARTIFACTS) $(RT_WITH_REFRESH_STAMP) | $(OUT_BIN_DIR)
	@rm -f "$@" && rm -rf "$@.dSYM"
	@bash "$(ROOT_DIR)/scripts/embed_runtime_objects.sh" "$(OUT_LIB_DIR)" "$(EMBEDDED_OBJECTS_ASM)"
	@$(HOST_CC) -c -O2 -o "$(EMBEDDED_OBJECTS_OBJ)" "$(EMBEDDED_OBJECTS_ASM)"
	@WITH_OUT_DIR="$(ROOT_DIR)/out" $(STAGE2_BIN) build $(GEN_MAIN_ENTRY) -O0 -o "$@"
	@echo "build complete: $@"

test: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __test)

__test: $(STAGE2_BIN)
	./scripts/run_tests.sh
	WITH=$(STAGE2_BIN) ./scripts/run_cli_selfhost_tests.sh
	./scripts/run_issue61_noop_local_regression.sh
	./scripts/run_embedded_runtime_extract_regression.sh

emit-c-test: build
	@echo "=== emit-c test ==="
	rm -rf out/emit-c-test
	mkdir -p out/emit-c-test
	./out/bin/with build out/gen/main.w --emit-c -o out/emit-c-test/main.c
	cd out/emit-c-test && zig cc -o with-from-c main.c \
		../../runtime/with_runtime.c \
		-I../../runtime \
		-lc
	./out/emit-c-test/with-from-c --version
	@echo "=== emit-c byte equality ==="
	./out/emit-c-test/with-from-c build out/gen/main.w -o out/emit-c-test/stage2-from-c -O0
	diff <(nm out/bin/with-stage2 | sort) <(nm out/emit-c-test/stage2-from-c | sort) \
		&& echo "EMIT-C FIXPOINT" || echo "EMIT-C DIVERGED"

fixpoint: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __fixpoint)

__fixpoint: $(STAGE3_BIN)
	@diff "$(STAGE2_BIN)" "$(STAGE3_BIN)" && echo "FIXPOINT"

install: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __install)

__install: $(STAGE2_BIN)
	install -d "$(INSTALL_BINDIR)"
	install -d "$(INSTALL_LIBDIR)"
	install -m 0755 "$(STAGE2_BIN)" "$(INSTALL_BINDIR)/with"
	cp -R "$(OUT_LIB_DIR)/." "$(INSTALL_LIBDIR)/"

install-user: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __install-user)

__install-user: $(CANONICAL_BIN)
	install -d "$(USER_BINDIR)"
	install -m 0755 "$(CANONICAL_BIN)" "$(USER_BINDIR)/with"

update-seed: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __update-seed)

__update-seed: __fixpoint
	@cp "$(STAGE2_BIN)" "$(SEED_PATH)"
	@echo "seed updated: $(SEED_PATH)"

clean: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __clean)

__clean:
	rm -rf "$(OUT)/"

FORCE:
