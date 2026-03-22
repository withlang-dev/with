.PHONY: all build stage1 stage2 stage3 smoke test fixpoint install install-user clean seed FORCE

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DESTDIR ?=
OUT ?= out

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

RUNTIME_STAMP := $(OUT_LIB_DIR)/.runtime-ready
RUNTIME_LINK := $(OUT_BIN_DIR)/runtime

STAGE1_BIN := $(OUT_BIN_DIR)/with-stage1
STAGE2_BIN := $(OUT_BIN_DIR)/with-stage2
STAGE3_BIN := $(OUT_BIN_DIR)/with-stage3
CANONICAL_BIN := $(OUT_BIN_DIR)/with
STAGE1_TMP := $(OUT_BIN_DIR)/with-stage1-build
STAGE_BUILD_TMP := $(OUT_BIN_DIR)/with-stage-build

USER_BINDIR ?= $(HOME)/.local/bin
USER_LIBDIR := $(USER_BINDIR)/runtime

# Seed compiler: WITH env var, `with` on PATH, or src/main (downloaded).
WITH ?= $(shell command -v with 2>/dev/null || ([ -x src/main ] && echo src/main))

INSTALL_BINDIR := $(DESTDIR)$(BINDIR)
INSTALL_LIBDIR := $(INSTALL_BINDIR)/runtime

all: build

build: $(CANONICAL_BIN)

stage1: $(STAGE1_BIN)

stage2: $(STAGE2_BIN)

stage3: $(STAGE3_BIN)

smoke: $(STAGE2_BIN)
	./out/bin/with-stage2 check src/main.w

# Download seed binary from GitHub releases.
seed:
	./scripts/download_seed.sh

$(OUT_BIN_DIR) $(OUT_LIB_DIR) $(OUT_LOG_DIR) $(OUT_TMP_DIR) $(OUT_GEN_DIR):
	@mkdir -p "$@"

$(GEN_STAMP): FORCE | $(OUT_BIN_DIR) $(OUT_LIB_DIR) $(OUT_LOG_DIR) $(OUT_TMP_DIR) $(OUT_GEN_DIR)
	@./scripts/generate_versioned_sources.sh $(OUT) >/dev/null
	@touch "$@"

$(RUNTIME_STAMP): FORCE | $(OUT_BIN_DIR) $(OUT_LIB_DIR) $(OUT_LOG_DIR) $(OUT_TMP_DIR)
	@./scripts/ensure_runtime.sh
	@touch "$@"

$(RUNTIME_LINK): $(RUNTIME_STAMP) | $(OUT_BIN_DIR)
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

FORCE:
