SHELL := /bin/bash

.PHONY: all build stage1 stage2 stage3 smoke test fixpoint install install-user clean seed runtime print-version FORCE

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
EMBEDDED_STDLIB_INC := $(OUT_LIB_DIR)/embedded_stdlib.inc.h
EMBEDDED_OBJECTS_INC := $(OUT_LIB_DIR)/embedded_objects.inc.h
HELPERS_OBJ := $(OUT_LIB_DIR)/helpers.o
SUPPORT_RUNTIME_OBJ := $(OUT_LIB_DIR)/support_runtime.o
WITH_RUNTIME_OBJ := $(OUT_LIB_DIR)/with_runtime.o
FIBER_OBJ := $(OUT_LIB_DIR)/fiber.o
FIBER_ASM_OBJ := $(OUT_LIB_DIR)/fiber_asm.o
EMBEDDED_OBJECTS_OBJ := $(OUT_LIB_DIR)/embedded_objects.o
LLVM_BRIDGE_OBJ := $(OUT_LIB_DIR)/llvm_bridge.o
CLANG_BRIDGE_OBJ := $(OUT_LIB_DIR)/clang_bridge.o
LLVM_LINK_RSP := $(OUT_LIB_DIR)/llvm_link.rsp
LLVM_CC_FILE := $(OUT_LIB_DIR)/llvm_cc
LLVM_LINK_STAMP := $(OUT_LIB_DIR)/.llvm-link-ready

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

# Seed compiler: WITH env var, `with` on PATH, or src/main (downloaded).
WITH ?= $(shell command -v with 2>/dev/null || ([ -x $(SEED_PATH) ] && echo $(SEED_PATH)))

INSTALL_BINDIR := $(DESTDIR)$(BINDIR)
INSTALL_LIBDIR := $(INSTALL_BINDIR)/runtime

ifeq ($(filter $(UNAME_M),arm64 aarch64),$(UNAME_M))
FIBER_ASM_SRC := runtime/fiber_asm_aarch64.s
endif
ifeq ($(filter $(UNAME_M),x86_64 amd64),$(UNAME_M))
FIBER_ASM_SRC := runtime/fiber_asm_x86_64.s
endif

LIBCLANG_FILE := $(firstword $(wildcard $(LLVM_PREFIX)/lib/libclang.dylib) $(wildcard $(LLVM_PREFIX)/lib/libclang.so))

RUNTIME_ARTIFACTS := \
	$(HELPERS_OBJ) \
	$(SUPPORT_RUNTIME_OBJ) \
	$(WITH_RUNTIME_OBJ) \
	$(FIBER_OBJ) \
	$(FIBER_ASM_OBJ) \
	$(EMBEDDED_OBJECTS_OBJ) \
	$(LLVM_BRIDGE_OBJ) \
	$(CLANG_BRIDGE_OBJ) \
	$(LLVM_LINK_STAMP)

define RESOLVE_VERSION_SH
set -euo pipefail; \
fallback_version="$$(sed -n '1{s/[[:space:]]*$$//;p;}' "$(VERSION_SOURCE_FILE)")"; \
if [ -z "$$fallback_version" ]; then \
	echo "error: empty or missing version in $(VERSION_SOURCE_FILE)" >&2; \
	exit 1; \
fi; \
if [ -n "$${WITH_VERSION:-}" ]; then \
	printf '%s\n' "$${WITH_VERSION}"; \
	exit 0; \
fi; \
if git -C "$(ROOT_DIR)" rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
	describe="$$(git -C "$(ROOT_DIR)" describe --tags --dirty --always --match 'v*' 2>/dev/null || true)"; \
	if [ -n "$$describe" ]; then \
		clean_describe="$${describe%-dirty}"; \
		if [[ "$$clean_describe" == v* ]]; then \
			if [[ ! "$$clean_describe" =~ -[0-9]+-g[0-9a-f]+$$ ]] && [ "$$clean_describe" != "$$fallback_version" ]; then \
				echo "error: $(VERSION_SOURCE_FILE) ($$fallback_version) does not match current tag ($$clean_describe)" >&2; \
				exit 1; \
			fi; \
			printf '%s\n' "$$describe"; \
			exit 0; \
		fi; \
	fi; \
	short_hash="$$(git -C "$(ROOT_DIR)" rev-parse --short=9 HEAD 2>/dev/null || true)"; \
	if [ -n "$$short_hash" ]; then \
		dirty_suffix=""; \
		if ! git -C "$(ROOT_DIR)" diff --quiet --ignore-submodules=dirty -- || ! git -C "$(ROOT_DIR)" diff --cached --quiet --ignore-submodules=dirty --; then \
			dirty_suffix="-dirty"; \
		fi; \
		printf '%s-g%s%s\n' "$$fallback_version" "$$short_hash" "$$dirty_suffix"; \
		exit 0; \
	fi; \
fi; \
printf '%s\n' "$$fallback_version"
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

build: $(CANONICAL_BIN)

stage1: $(STAGE1_BIN)

stage2: $(STAGE2_BIN)

stage3: $(STAGE3_BIN)

runtime: $(RUNTIME_LINK)

smoke: $(STAGE2_BIN)
	./out/bin/with-stage2 check src/main.w

print-version:
	@$(RESOLVE_VERSION_SH)

seed:
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
$(EMBEDDED_STDLIB_INC): scripts/generate_embedded_stdlib.py $(STD_SOURCES) | $(OUT_LIB_DIR)
	@python3 "$(ROOT_DIR)/scripts/generate_embedded_stdlib.py" "$(ROOT_DIR)" "$@"

$(HELPERS_OBJ): runtime/helpers.c $(EMBEDDED_STDLIB_INC) | $(OUT_LIB_DIR)
	$(call HOST_COMPILE,-DWITH_HAS_CURL)

$(SUPPORT_RUNTIME_OBJ): runtime/support_runtime.c | $(OUT_LIB_DIR)
	$(call HOST_COMPILE,)

$(WITH_RUNTIME_OBJ): runtime/with_runtime.c | $(OUT_LIB_DIR)
	$(call HOST_COMPILE,)

$(FIBER_OBJ): runtime/fiber.c | $(OUT_LIB_DIR)
	$(call HOST_COMPILE,)

$(FIBER_ASM_OBJ): $(FIBER_ASM_SRC) | $(OUT_LIB_DIR)
	@if [ -z "$(FIBER_ASM_SRC)" ]; then echo "error: unsupported host architecture $(UNAME_M) for fiber_asm.o" >&2; exit 1; fi
	$(call HOST_COMPILE,)

$(EMBEDDED_OBJECTS_INC): scripts/embed_runtime_objects.sh $(HELPERS_OBJ) $(SUPPORT_RUNTIME_OBJ) $(WITH_RUNTIME_OBJ) $(FIBER_OBJ) $(FIBER_ASM_OBJ) | $(OUT_LIB_DIR)
	@bash "$(ROOT_DIR)/scripts/embed_runtime_objects.sh" "$(OUT_LIB_DIR)" "$@"

$(EMBEDDED_OBJECTS_OBJ): runtime/embedded_objects.c $(EMBEDDED_OBJECTS_INC) | $(OUT_LIB_DIR)
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

$(RUNTIME_LINK): $(RUNTIME_ARTIFACTS) | $(OUT_BIN_DIR)
	@if [ -L "$@" ]; then rm -f "$@"; elif [ -e "$@" ]; then rm -rf "$@"; fi
	@ln -s ../lib "$@"

define build_stage
	@tmp="$(3)"; \
	dsym="$$tmp.dSYM"; \
	gen_bin="$(OUT_GEN_DIR)/main"; \
	gen_dsym="$(OUT_GEN_DIR)/main.dSYM"; \
	rm -f "$$tmp" "$$gen_bin" "$@"; \
	rm -rf "$$dsym" "$$gen_dsym" "$@.dSYM"; \
	$(1) build $(GEN_MAIN_ENTRY) -o "$$tmp"; \
	if [ ! -x "$$tmp" ]; then mv "$$gen_bin" "$$tmp"; fi; \
	if [ -d "$$gen_dsym" ]; then mv "$$gen_dsym" "$$dsym"; fi; \
	cp "$$tmp" "$@"; \
	if [ -d "$$dsym" ]; then cp -R "$$dsym" "$@.dSYM"; fi; \
	rm -f "$$tmp"; \
	rm -rf "$$dsym"; \
	echo "[$(2)] wrote $@"
endef

$(STAGE1_BIN): $(GEN_STAMP) $(RUNTIME_LINK)
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(call build_stage,$(WITH),stage1,$(STAGE1_TMP))

$(STAGE2_BIN): $(STAGE1_BIN) $(GEN_STAMP) $(RUNTIME_LINK)
	@rm -rf "$(HOME)/.cache/with/c_import"
	$(call build_stage,$(STAGE1_BIN),stage2,$(STAGE_BUILD_TMP))

$(STAGE3_BIN): $(STAGE2_BIN) $(GEN_STAMP) $(RUNTIME_LINK)
	@rm -rf "$(HOME)/.cache/with/c_import"
	$(call build_stage,$(STAGE2_BIN),stage3,$(STAGE_BUILD_TMP))

$(CANONICAL_BIN): $(STAGE2_BIN) | $(OUT_BIN_DIR)
	@rm -f "$@" && rm -rf "$@.dSYM"
	@cp "$(STAGE2_BIN)" "$@"
	@[ ! -d "$(STAGE2_BIN).dSYM" ] || cp -R "$(STAGE2_BIN).dSYM" "$@.dSYM"
	@echo "build complete: $@"

test: $(STAGE2_BIN)
	./scripts/run_tests.sh

fixpoint: $(STAGE3_BIN)
	@diff "$(STAGE2_BIN)" "$(STAGE3_BIN)" && echo "FIXPOINT"

install: $(STAGE2_BIN)
	install -d "$(INSTALL_BINDIR)"
	install -d "$(INSTALL_LIBDIR)"
	install -m 0755 "$(STAGE2_BIN)" "$(INSTALL_BINDIR)/with"
	cp -R "$(OUT_LIB_DIR)/." "$(INSTALL_LIBDIR)/"

install-user: $(STAGE2_BIN)
	install -d "$(USER_BINDIR)"
	install -d "$(USER_LIBDIR)"
	install -m 0755 "$(STAGE2_BIN)" "$(USER_BINDIR)/with"
	cp -R "$(OUT_LIB_DIR)/." "$(USER_LIBDIR)/"

clean:
	rm -rf "$(OUT)/"
	rm -f runtime/embedded_objects.inc.h

FORCE:
