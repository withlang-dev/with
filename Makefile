.PHONY: all stage1 stage2 build test test-stage2 fixpoint install clean

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
DESTDIR ?=
OUT_DIR ?= out
OUT_BINDIR ?= $(OUT_DIR)/bin

STAGE2_BIN := $(OUT_BINDIR)/with-stage2
CANONICAL_BIN := $(OUT_BINDIR)/with

INSTALL_BINDIR := $(DESTDIR)$(BINDIR)
INSTALL_RUNTIMEDIR := $(INSTALL_BINDIR)/runtime

all: build

# Stage1 selfhost compiler built from the current selfhost seed.
stage1:
	./scripts/rebuild_selfhost.sh stage1

# Stage2 selfhost compiler built by stage1 (compiler built by itself).
stage2:
	./scripts/rebuild_selfhost.sh stage2

# Canonical local compiler artifact.
build: stage2
	@test -x "$(CANONICAL_BIN)"

# Run the selfhost test suite.
test: build
	./scripts/run_tests.sh

# Alias for CI compatibility.
test-stage2: test

# Fixpoint verification (stage2 == stage3).
fixpoint:
	./scripts/rebuild_selfhost.sh stage3
	@diff "$(OUT_BINDIR)/with-stage2" "$(OUT_BINDIR)/with-stage3" && echo "FIXPOINT"

# Install stage2 compiler and colocated runtime artifacts.
install: build
	install -d "$(INSTALL_BINDIR)"
	install -d "$(INSTALL_RUNTIMEDIR)"
	install -m 0755 "$(STAGE2_BIN)" "$(INSTALL_BINDIR)/with"
	cp -R runtime/. "$(INSTALL_RUNTIMEDIR)/"

clean:
	rm -f with with-new with-stage1 with-stage2 with-stage3
	rm -rf out/
	rm -rf .with/build/
