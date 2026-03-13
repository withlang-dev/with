.PHONY: all build test fixpoint install clean

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DESTDIR ?=
OUT ?= out
STAGE_TMP := $(OUT)/bin/with-stage-build

# Seed compiler: use WITH env var, or `with` on PATH.
WITH ?= $(shell command -v with 2>/dev/null)

INSTALL_BINDIR := $(DESTDIR)$(BINDIR)
INSTALL_LIBDIR := $(INSTALL_BINDIR)/runtime

all: build

# Two-stage self-hosted build.
# The compiler outputs <stem> next to the source file, so we build and move.
build:
	@if [ -z "$(WITH)" ]; then echo "error: no seed compiler — set WITH or add with to PATH" >&2; exit 1; fi
	@mkdir -p $(OUT)/bin $(OUT)/lib $(OUT)/log
	@./scripts/ensure_runtime.sh
	@rm -f $(OUT)/bin/runtime && ln -s ../lib $(OUT)/bin/runtime
	@rm -f $(OUT)/bin/with-stage1 && rm -rf $(OUT)/bin/with-stage1.dSYM
	$(WITH) build src/main.w -o $(OUT)/bin/with-stage1
	@[ -x $(OUT)/bin/with-stage1 ] || mv src/main $(OUT)/bin/with-stage1
	@[ ! -d src/main.dSYM ] || mv src/main.dSYM $(OUT)/bin/with-stage1.dSYM
	@rm -f $(STAGE_TMP) && rm -rf $(STAGE_TMP).dSYM
	@rm -f $(OUT)/bin/with-stage2 && rm -rf $(OUT)/bin/with-stage2.dSYM
	$(OUT)/bin/with-stage1 build src/main.w -o $(STAGE_TMP)
	@[ -x $(STAGE_TMP) ] || mv src/main $(STAGE_TMP)
	@[ ! -d src/main.dSYM ] || mv src/main.dSYM $(STAGE_TMP).dSYM
	@cp $(STAGE_TMP) $(OUT)/bin/with-stage2
	@[ ! -d $(STAGE_TMP).dSYM ] || cp -R $(STAGE_TMP).dSYM $(OUT)/bin/with-stage2.dSYM
	@rm -f $(STAGE_TMP) && rm -rf $(STAGE_TMP).dSYM
	@cp $(OUT)/bin/with-stage2 $(OUT)/bin/with
	@echo "build complete: $(OUT)/bin/with"

test: build
	./scripts/run_tests.sh

fixpoint: build
	@rm -f $(STAGE_TMP) && rm -rf $(STAGE_TMP).dSYM
	@rm -f $(OUT)/bin/with-stage3 && rm -rf $(OUT)/bin/with-stage3.dSYM
	$(OUT)/bin/with-stage2 build src/main.w -o $(STAGE_TMP)
	@[ -x $(STAGE_TMP) ] || mv src/main $(STAGE_TMP)
	@[ ! -d src/main.dSYM ] || mv src/main.dSYM $(STAGE_TMP).dSYM
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
