.PHONY: all build test fixpoint install clean

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DESTDIR ?=
OUT ?= out

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
	$(WITH) build src/main.w && mv src/main $(OUT)/bin/with-stage1
	$(OUT)/bin/with-stage1 build src/main.w && mv src/main $(OUT)/bin/with-stage2
	@cp $(OUT)/bin/with-stage2 $(OUT)/bin/with
	@echo "build complete: $(OUT)/bin/with"

test: build
	./scripts/run_tests.sh

fixpoint: build
	$(OUT)/bin/with-stage2 build src/main.w && mv src/main $(OUT)/bin/with-stage3
	@diff $(OUT)/bin/with-stage2 $(OUT)/bin/with-stage3 && echo "FIXPOINT"

install: build
	install -d "$(INSTALL_BINDIR)"
	install -d "$(INSTALL_LIBDIR)"
	install -m 0755 $(OUT)/bin/with-stage2 "$(INSTALL_BINDIR)/with"
	cp -R $(OUT)/lib/. "$(INSTALL_LIBDIR)/"

clean:
	rm -rf $(OUT)/
