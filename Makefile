SHELL := /bin/bash

.PHONY: all build stage1 stage2 stage3 runtime selfcheck smoke test test-pcre2 \
	fixpoint install install-user update-seed clean seed deps print-version \
	emit-c-test emit-c-fixpoint emit-c-roundtrip cross \
	pcre2-migrate pcre2-build pcre2-test pcre2-promote \
	regex-migrate regex-build regex-test regex-promote

ROOT_DIR := $(CURDIR)
REPO_FULL_NAME ?= QuixiAI/with
WITH_BUILD_ENV := WITH_OUT_DIR="$(ROOT_DIR)/out"

OUT ?= out
OUT_BIN_DIR := $(OUT)/bin
OUT_RELEASE_BIN_DIR := $(OUT)/release/bin
OUT_TMP_DIR := $(OUT)/tmp
OUT_GEN_DIR := $(OUT)/gen

CANONICAL_BIN := $(OUT_RELEASE_BIN_DIR)/with
SEED_PATH := src/main
SEED_VERSION ?=
SEED_ASSET ?= auto

# Seed compiler: WITH env var, out/release/bin/with, `with` on PATH, or src/main.
WITH ?= $(shell \
	if [ -x "$(CANONICAL_BIN)" ]; then \
		printf '%s\n' "$(CANONICAL_BIN)"; \
	elif command -v with >/dev/null 2>&1; then \
		command -v with; \
	elif [ -x "$(SEED_PATH)" ]; then \
		printf '%s\n' "$(SEED_PATH)"; \
	fi)
STAGE0_BIN := $(WITH)

VERSION_SOURCE_FILE := src/version

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

REPO_SERIAL_LOCK := $(OUT_TMP_DIR)/repo-serial.lock

define WITH_REPO_LOCK
	@set -euo pipefail; \
	lock="$(REPO_SERIAL_LOCK)"; \
	owner_file="$$lock/owner"; \
	acquired=0; \
	if mkdir "$$lock" 2>/dev/null; then \
		acquired=1; \
	elif [ -f "$$owner_file" ]; then \
		owner="$$(cat "$$owner_file")"; \
		owner_pid="$$(printf '%s\n' "$$owner" | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p')"; \
		if [ -n "$$owner_pid" ] && ! kill -0 "$$owner_pid" 2>/dev/null; then \
			rm -rf "$$lock"; \
			if mkdir "$$lock" 2>/dev/null; then \
				acquired=1; \
			fi; \
		fi; \
	fi; \
	if [ "$$acquired" -eq 1 ]; then \
		trap 'rm -rf "$$lock"' EXIT INT TERM HUP; \
		printf 'target=%s pid=%s started=%s\n' "$@" "$$$$" "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$$owner_file"; \
		export WITH_REPO_LOCKED=1; $(1); \
	else \
		if [ -f "$$owner_file" ]; then \
			owner="$$(cat "$$owner_file")"; \
		else \
			owner="target=<unknown> pid=<unknown> started=<unknown>"; \
		fi; \
		echo "error: another top-level target is already running: $$owner" >&2; \
		exit 1; \
	fi
endef

define RUN_GRAPH_TARGET
	@if [ -z "$(STAGE0_BIN)" ]; then echo "error: no seed compiler — set WITH, add with to PATH, or run: make seed" >&2; exit 1; fi
	$(WITH_BUILD_ENV) $(STAGE0_BIN) build :$(1)
endef

$(OUT_TMP_DIR):
	@mkdir -p "$@"

# --- Public targets (all delegate to with build via the graph) ---

all: build

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

test: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __test)

test-pcre2: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __test-pcre2)

fixpoint: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __fixpoint)

install: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __install)

install-user: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __install-user)

update-seed: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __update-seed)

clean: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __clean)

seed: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __seed)

deps: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __deps)

pcre2-migrate: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __regex-migrate)

pcre2-build: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __regex-build)

pcre2-test: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __regex-test)

pcre2-promote: | $(OUT_TMP_DIR)
	$(call WITH_REPO_LOCK,$(MAKE) --no-print-directory __regex-promote)

regex-migrate: pcre2-migrate
regex-build: pcre2-build
regex-test: pcre2-test
regex-promote: pcre2-promote

print-version:
	@$(RESOLVE_VERSION_SH)

emit-c-test:
	$(call RUN_GRAPH_TARGET,emit-c-test)

emit-c-fixpoint:
	$(call RUN_GRAPH_TARGET,emit-c-fixpoint)

emit-c-roundtrip:
	$(call RUN_GRAPH_TARGET,emit-c-roundtrip)

# --- Internal targets ---

__build:
	$(call RUN_GRAPH_TARGET,build)

__stage1:
	$(call RUN_GRAPH_TARGET,stage1)

__stage2:
	$(call RUN_GRAPH_TARGET,stage2)

__stage3:
	$(call RUN_GRAPH_TARGET,stage3)

__runtime:
	$(call RUN_GRAPH_TARGET,runtime)

__selfcheck:
	$(call RUN_GRAPH_TARGET,selfcheck)

__smoke:
	$(call RUN_GRAPH_TARGET,selfcheck)

__test:
	$(call RUN_GRAPH_TARGET,test)

__test-pcre2: __regex-test

__fixpoint:
	$(call RUN_GRAPH_TARGET,fixpoint)

__install:
	$(call RUN_GRAPH_TARGET,install)

__install-user:
	$(call RUN_GRAPH_TARGET,install-user)

__update-seed:
	$(call RUN_GRAPH_TARGET,update-seed)

__deps:
	$(call RUN_GRAPH_TARGET,deps)

__clean:
	@$(WITH_BUILD_ENV) "$(WITH)" build :clean

__regex-migrate:
	$(call RUN_GRAPH_TARGET,pcre2-migrate)

__regex-build:
	$(call RUN_GRAPH_TARGET,pcre2-build)

__regex-test:
	$(call RUN_GRAPH_TARGET,pcre2-test)

__regex-promote:
	$(call RUN_GRAPH_TARGET,pcre2-promote)

__seed:
	@set -euo pipefail; \
	if [ -n "$(STAGE0_BIN)" ]; then \
		$(WITH_BUILD_ENV) $(STAGE0_BIN) build :seed; \
		exit $$?; \
	fi; \
	dest="$(SEED_PATH)"; \
	repo="$(REPO_FULL_NAME)"; \
	asset="$(SEED_ASSET)"; \
	if [ "$$asset" = "auto" ]; then \
		case "$$(uname -s):$$(uname -m)" in \
			Darwin:arm64|Darwin:aarch64) asset="with-darwin-aarch64" ;; \
			Linux:x86_64) asset="with-linux-x86_64" ;; \
			*) asset="" ;; \
		esac; \
	fi; \
	if [ -z "$$asset" ]; then \
		echo "error: unsupported seed host: $$(uname -s)/$$(uname -m)" >&2; \
		echo "set SEED_ASSET to a published release asset name" >&2; \
		exit 1; \
	fi; \
	if [ -x "$$dest" ]; then \
		echo "seed binary already exists: $$dest"; \
		echo "remove it first if you want to re-download"; \
		exit 0; \
	fi; \
	tag="$(SEED_VERSION)"; \
	if [ -z "$$tag" ]; then \
		tag="$$( \
			gh release list --repo "$$repo" --limit 10 --json tagName,isDraft -q '.[] | select(.isDraft | not) | .tagName' 2>/dev/null | \
			while IFS= read -r candidate; do \
				if [ -z "$$candidate" ]; then continue; fi; \
				if gh release view "$$candidate" --repo "$$repo" --json assets -q '.assets[].name' 2>/dev/null | grep -qx "$$asset"; then \
					printf '%s\n' "$$candidate"; \
					break; \
				fi; \
			done \
			|| true \
		)"; \
		if [ -z "$$tag" ]; then \
			echo "error: could not find a release with seed binary" >&2; \
			echo "install gh CLI and authenticate, or specify one:" >&2; \
			echo "  make seed SEED_VERSION=v0.5.2-uaf" >&2; \
			exit 1; \
		fi; \
		echo "latest seed release: $$tag"; \
	fi; \
	url="https://github.com/$$repo/releases/download/$$tag/$$asset"; \
	echo "downloading seed from: $$url"; \
	curl -fSL -o "$$dest" "$$url"; \
	chmod +x "$$dest"; \
	echo "seed installed: $$dest"

# Cross-target compilation is graph-owned and currently fails loudly until the
# compiler has real non-native codegen/link support.
CROSS_TARGET ?=

cross:
	$(WITH_BUILD_ENV) CROSS_TARGET="$(CROSS_TARGET)" $(STAGE0_BIN) build :cross
