.PHONY: all build test fixpoint install clean seed

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DESTDIR ?=
OUT ?= out
OUT_GEN_DIR := $(OUT)/gen
GEN_MAIN_ENTRY := $(OUT_GEN_DIR)/main.w
STAGE_TMP := $(OUT)/bin/with-stage-build
# Seed compiler: WITH env var, `with` on PATH, or src/main (downloaded).
WITH ?= $(shell command -v with 2>/dev/null || ([ -x src/main ] && echo src/main))

INSTALL_BINDIR := $(DESTDIR)$(BINDIR)
INSTALL_LIBDIR := $(INSTALL_BINDIR)/runtime

all: build

# Download seed binary from GitHub releases.
seed:
	./scripts/download_seed.sh

# Two-stage self-hosted build.
# The compiler outputs <stem> next to the source file, so we build and move.
build:
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	@mkdir -p $(OUT)/bin $(OUT)/lib $(OUT)/log
	@./scripts/generate_versioned_sources.sh $(OUT) >/dev/null
	@./scripts/ensure_runtime.sh
	@rm -f $(OUT)/bin/runtime && ln -s ../lib $(OUT)/bin/runtime
	@rm -f $(OUT)/bin/with-stage1 && rm -rf $(OUT)/bin/with-stage1.dSYM
	$(WITH) build $(GEN_MAIN_ENTRY) -o $(OUT)/bin/with-stage1
	@[ -x $(OUT)/bin/with-stage1 ] || mv $(OUT_GEN_DIR)/main $(OUT)/bin/with-stage1
	@[ ! -d $(OUT_GEN_DIR)/main.dSYM ] || mv $(OUT_GEN_DIR)/main.dSYM $(OUT)/bin/with-stage1.dSYM
	@rm -f $(STAGE_TMP) && rm -rf $(STAGE_TMP).dSYM
	@rm -f $(OUT)/bin/with-stage2 && rm -rf $(OUT)/bin/with-stage2.dSYM
	@rm -rf "$(HOME)/.cache/with/c_import"
	$(OUT)/bin/with-stage1 build $(GEN_MAIN_ENTRY) -o $(STAGE_TMP)
	@[ -x $(STAGE_TMP) ] || mv $(OUT_GEN_DIR)/main $(STAGE_TMP)
	@[ ! -d $(OUT_GEN_DIR)/main.dSYM ] || mv $(OUT_GEN_DIR)/main.dSYM $(STAGE_TMP).dSYM
	@cp $(STAGE_TMP) $(OUT)/bin/with-stage2
	@[ ! -d $(STAGE_TMP).dSYM ] || cp -R $(STAGE_TMP).dSYM $(OUT)/bin/with-stage2.dSYM
	@rm -f $(STAGE_TMP) && rm -rf $(STAGE_TMP).dSYM
	@cp $(OUT)/bin/with-stage2 $(OUT)/bin/with
	@echo "build complete: $(OUT)/bin/with"

test: build
	./scripts/run_tests.sh

fixpoint: build
	@./scripts/generate_versioned_sources.sh $(OUT) >/dev/null
	@rm -f $(STAGE_TMP) && rm -rf $(STAGE_TMP).dSYM
	@rm -f $(OUT)/bin/with-stage3 && rm -rf $(OUT)/bin/with-stage3.dSYM
	@rm -rf "$(HOME)/.cache/with/c_import"
	$(OUT)/bin/with-stage2 build $(GEN_MAIN_ENTRY) -o $(STAGE_TMP)
	@[ -x $(STAGE_TMP) ] || mv $(OUT_GEN_DIR)/main $(STAGE_TMP)
	@[ ! -d $(OUT_GEN_DIR)/main.dSYM ] || mv $(OUT_GEN_DIR)/main.dSYM $(STAGE_TMP).dSYM
	@cp $(STAGE_TMP) $(OUT)/bin/with-stage3
	@[ ! -d $(STAGE_TMP).dSYM ] || cp -R $(STAGE_TMP).dSYM $(OUT)/bin/with-stage3.dSYM
	@rm -f $(STAGE_TMP) && rm -rf $(STAGE_TMP).dSYM
	@diff $(OUT)/bin/with-stage2 $(OUT)/bin/with-stage3 && echo "FIXPOINT"

install: build
	install -d "$(INSTALL_BINDIR)"
	install -d "$(INSTALL_LIBDIR)"
	install -m 0755 $(OUT)/bin/with-stage2 "$(INSTALL_BINDIR)/with"
	cp -R $(OUT)/lib/. "$(INSTALL_LIBDIR)/"

clean:
	rm -rf $(OUT)/
