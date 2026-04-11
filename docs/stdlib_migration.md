# Stdlib Migration Build System

## Overview

With's stdlib is built from migrated C libraries. The build system manages the full lifecycle: fetching C sources, migrating them to With, post-processing, checking, promoting to `lib/std/`, compiling to object files, and archiving into static libraries. The process is repeatable, version-pinned, and automatable by agents.

---

## Directory Structure

```
scripts/
  migrate.sh                    # Universal migration driver (all libraries use this)
  migrate/
    pcre2.conf                  # Per-library config (version, flags, source paths)
    pcre2_post.sh               # Per-library post-processing (library-specific fixups)
    jq.conf
    jq_post.sh
    libsodium.conf
    ...

.reference/                     # C source trees (gitignored, fetched by Makefile)
  pcre2/src/*.c
  jq/src/*.c
  ...

out/migrate/                    # Migration workspace (generated, gitignored)
  pcre2/
    raw/                        # Raw with migrate output
    prepared/                   # Post-processed, ready for check
  jq/
    raw/
    prepared/
  ...

lib/std/                        # Final With source (checked into git)
  re/                           # PCRE2 → std.re
    defs.w
    pcre2_compile.w
    ...
  re.w                          # Layer 2 API wrapper (hand-written)
  json/                         # jq → std.json
    defs.w
    ...
  json.w                        # Layer 2 API wrapper (hand-written)
  ...

out/lib/                        # Compiled objects and archives (generated)
  re/*.o
  libpcre2_with.a
  json/*.o
  libjq_with.a
  ...
```

---

## Library Config Files

Each library has `scripts/migrate/{lib}.conf`:

```bash
# scripts/migrate/pcre2.conf

# Identity
LIB_NAME=pcre2
STD_MODULE=re
LIB_VERSION=10.48

# Fetch
LIB_URL=https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.48/pcre2-10.48.tar.gz
LIB_STRIP=1                     # tar --strip-components
LIB_DEST=.reference/pcre2       # Where to extract

# Migration
SRC_DIR=.reference/pcre2/src
MIGRATE_FLAGS="-I .reference/pcre2/src -D PCRE2_CODE_UNIT_WIDTH=8 -D HAVE_CONFIG_H=1"
MIGRATE_EXTRA="--no-c-exports"
MIGRATE_SOURCES="*.c"
MIGRATE_EXCLUDE="pcre2_jit_compile.c pcre2_ucptables.c"

# Post-processing
PATCH_SCRIPT=scripts/migrate/pcre2_post.sh

# Preamble file for check (types, externs shared across modules)
PREAMBLE_FILE=pcre2_tables.w
DEFS_FILE=defs.w
```

---

## Makefile Targets

### Primary targets (what you type)

```makefile
# ── Stdlib library list ──────────────────────────────────────────
STDLIB_LIBS = pcre2 jq libsodium mbedtls zlib lmdb utf8proc xxhash \
              libyaml toml-c llhttp linenoise libbacktrace zstd lz4 \
              c-ares sqlite yxml msgpack stb_image

# ── Single-library targets ──────────────────────────────────────

# First-time setup: fetch + migrate + check + promote + build
#   make stdlib-init-pcre2
stdlib-init-%:
	scripts/migrate.sh fetch $*
	scripts/migrate.sh migrate $*
	scripts/migrate.sh prepare $*
	scripts/migrate.sh check $*
	scripts/migrate.sh promote $*
	scripts/migrate.sh build $*

# Re-migrate after with migrate improvements (keeps existing lib/std/)
#   make stdlib-remigrate-pcre2
stdlib-remigrate-%:
	scripts/migrate.sh migrate $*
	scripts/migrate.sh prepare $*
	scripts/migrate.sh check $*
	scripts/migrate.sh promote $*
	scripts/migrate.sh build $*

# Version bump: fetch new source + full re-migration
#   (edit scripts/migrate/pcre2.conf first, update LIB_VERSION and LIB_URL)
#   make stdlib-update-pcre2
stdlib-update-%:
	rm -rf .reference/$*
	scripts/migrate.sh fetch $*
	scripts/migrate.sh migrate $*
	scripts/migrate.sh prepare $*
	scripts/migrate.sh check $*
	@echo "Check passed. Review diff, then: make stdlib-promote-$*"

# Promote after review (separate from update for safety)
stdlib-promote-%:
	scripts/migrate.sh promote $*
	scripts/migrate.sh build $*

# Just rebuild .o files and .a (no migration, no check)
#   make stdlib-build-pcre2
stdlib-build-%:
	scripts/migrate.sh build $*

# Just check (no migration, no promote)
#   make stdlib-check-pcre2
stdlib-check-%:
	scripts/migrate.sh check $*

# ── All-library targets ─────────────────────────────────────────

# Build all library .a files from existing lib/std/ source
stdlib-build:
	@for lib in $(STDLIB_LIBS); do \
		if [ -d "lib/std/$$(. scripts/migrate/$$lib.conf && echo $$STD_MODULE)" ]; then \
			scripts/migrate.sh build $$lib || echo "FAIL: $$lib"; \
		fi; \
	done

# Check all libraries
stdlib-check:
	@scripts/migrate_scorecard.sh

# Re-migrate everything (after migrator improvements)
stdlib-remigrate-all:
	@for lib in $(STDLIB_LIBS); do \
		if [ -f "scripts/migrate/$$lib.conf" ]; then \
			echo "=== $$lib ==="; \
			$(MAKE) stdlib-remigrate-$$lib || echo "FAILED: $$lib"; \
		fi; \
	done

# ── Integration with main build ─────────────────────────────────

# The main build target depends on stdlib .a files
build: out/bin/with stdlib-build

# Stdlib .a files are prerequisites for the final compiler binary
# (only for libraries that have been promoted to lib/std/)
STDLIB_ARCHIVES = $(foreach lib,$(STDLIB_LIBS),\
    $(if $(wildcard lib/std/$(shell . scripts/migrate/$(lib).conf 2>/dev/null && echo $$STD_MODULE)/),\
        out/lib/lib$(lib)_with.a))
```

---

## Workflow: When to Do What

### First time adding a new library

```
1. Create scripts/migrate/{lib}.conf
2. Create scripts/migrate/{lib}_post.sh (can be empty)
3. make stdlib-init-{lib}
4. Write lib/std/{module}.w (Layer 2 API wrapper)
5. Write test/test_{module}.w
6. git add lib/std/{module}/ lib/std/{module}.w scripts/migrate/{lib}.*
7. git commit -m "add std.{module} (migrated from {lib})"
```

### After improving with migrate

```
1. make build && make fixpoint          # rebuild compiler with migrator fix
2. make stdlib-remigrate-all            # re-migrate everything
3. scripts/migrate_scorecard.sh         # check what improved
4. git add lib/std/ && git commit       # commit improved migrations
```

### Bumping a dependency version

```
1. Edit scripts/migrate/{lib}.conf      # update LIB_VERSION, LIB_URL
2. make stdlib-update-{lib}             # fetch + migrate + check (no promote yet)
3. diff lib/std/{module}/ out/migrate/{lib}/prepared/   # review changes
4. make stdlib-promote-{lib}            # deploy to lib/std/
5. make build && make test              # verify nothing broke
6. git add lib/std/{module}/ scripts/migrate/{lib}.conf
7. git commit -m "bump {lib} to {version}"
```

### Fixing a post-processing regression

```
1. Edit scripts/migrate/{lib}_post.sh   # add/fix the perl fixup
2. scripts/migrate.sh prepare {lib}     # re-run post-processing only
3. scripts/migrate.sh check {lib}       # verify fix
4. make stdlib-promote-{lib}            # deploy
```

---

## Scorecard

`scripts/migrate_scorecard.sh` reports migration health:

```bash
#!/bin/bash
set -euo pipefail

printf "%-18s %6s %4s %7s %10s\n" "Library" "Files" "OK" "Errors" "Post-fixes"
printf "%-18s %6s %4s %7s %10s\n" "--------" "-----" "---" "------" "----------"

for conf in scripts/migrate/*.conf; do
    lib=$(basename "$conf" .conf)
    source "$conf"
    
    raw_dir="out/migrate/${lib}/raw"
    post_script="scripts/migrate/${lib}_post.sh"
    
    total=$(ls "$raw_dir"/*.w 2>/dev/null | wc -l | tr -d ' ')
    if [ "$total" = "0" ]; then
        printf "%-18s %6s %4s %7s %10s\n" "$lib" "-" "-" "-" "not migrated"
        continue
    fi
    
    check_out=$(scripts/migrate.sh check "$lib" 2>&1 | tail -1)
    ok=$(echo "$check_out" | grep -o 'OK=[0-9]*' | cut -d= -f2)
    errs=$(echo "$check_out" | grep -o 'TOTAL_ERRORS=[0-9]*' | cut -d= -f2)
    fixes=$(wc -l < "$post_script" 2>/dev/null | tr -d ' ' || echo 0)
    
    printf "%-18s %6s %4s %7s %10s\n" "$lib" "$total" "$ok" "$errs" "$fixes"
done
```

Output:

```
Library             Files   OK  Errors Post-fixes
--------            -----  ---  ------ ----------
pcre2                  32   31       0         24
jq                     -    -        -   not migrated
libsodium              -    -        -   not migrated
mbedtls                -    -        -   not migrated
zlib                   -    -        -   not migrated
lmdb                   -    -        -   not migrated
```

The goal: every library at 0 errors and shrinking post-fixes.

---

## AGENTS.md Section

Add this to the project's AGENTS.md:

```markdown
## Stdlib Migration

With's stdlib includes C libraries migrated via `with migrate`. Each library
follows the same pipeline: fetch → migrate → prepare → check → promote → build.

### Key rules

1. **Never edit files in `lib/std/{module}/` directly.** They are generated.
   Fix the migrator (`src/CImport.w`) or the post-processing script
   (`scripts/migrate/{lib}_post.sh`).

2. **Never edit files in `out/migrate/`.** They are generated and disposable.

3. **After ANY change to `src/CImport.w`:** run `make build && make fixpoint`,
   then `make stdlib-remigrate-all` to verify the change didn't regress
   other libraries.

4. **After ANY change to a `_post.sh` script:** run
   `scripts/migrate.sh prepare {lib} && scripts/migrate.sh check {lib}`
   to verify.

5. **Migration errors should be fixed in `with migrate`, not in post-processing.**
   Post-processing scripts are for library-specific quirks (macro expansion,
   version strings). If a pattern appears in 2+ libraries, fix the migrator.

6. **30-minute rule per bug.** If a migration error resists fixing in the
   migrator after 30 minutes, add it to the post-processing script and move on.
   File an issue. Come back later.

7. **Minimal C repros first.** Before fixing a migrator bug, write a 5-line C
   file that reproduces the error. Fix the migrator against the repro. Verify
   with build/selfcheck/fixpoint. Then re-migrate.

8. **One fix at a time.** After each migrator fix: build → selfcheck → fixpoint →
   re-migrate → measure error count. Never batch multiple migrator fixes without
   measuring between them.

### Workflow commands

| Command | When to use |
|---|---|
| `make stdlib-init-{lib}` | Adding a new library for the first time |
| `make stdlib-remigrate-{lib}` | After fixing a migrator bug |
| `make stdlib-update-{lib}` | Bumping a dependency to a new version |
| `make stdlib-build-{lib}` | Rebuilding .o files after compiler changes |
| `make stdlib-check-{lib}` | Verifying a library passes check |
| `scripts/migrate_scorecard.sh` | Dashboard of all library health |

### File ownership

| Path | Edited by | Checked in |
|---|---|---|
| `scripts/migrate/{lib}.conf` | Human | Yes |
| `scripts/migrate/{lib}_post.sh` | Human or agent | Yes |
| `lib/std/{module}/*.w` | Generated (promote) | Yes |
| `lib/std/{module}.w` | Human (Layer 2 API) | Yes |
| `out/migrate/{lib}/raw/` | Generated (migrate) | No |
| `out/migrate/{lib}/prepared/` | Generated (prepare) | No |
| `.reference/{lib}/` | Downloaded (fetch) | No |
| `src/CImport.w` | Human or agent (migrator fixes) | Yes |
```

---

## CLAUDE.md Section

Add this to the project's CLAUDE.md:

```markdown
## Stdlib Migration Context

The With stdlib includes migrated C libraries. The migration pipeline is:

    fetch → migrate → prepare → check → promote → build

Key files:
- `scripts/migrate.sh` — Universal migration driver
- `scripts/migrate/{lib}.conf` — Per-library config
- `scripts/migrate/{lib}_post.sh` — Per-library fixups
- `src/CImport.w` — The migrator (with migrate implementation)

### When asked to fix migration errors:

1. Determine if the error is a **migrator bug** or a **library-specific quirk**
2. Migrator bugs → fix in `src/CImport.w`, write a minimal C repro first
3. Library quirks → fix in `scripts/migrate/{lib}_post.sh`
4. After migrator fixes: `make build && make fixpoint && make stdlib-remigrate-all`
5. After post-processing fixes: `scripts/migrate.sh prepare {lib} && scripts/migrate.sh check {lib}`

### When asked to add a new library:

1. Create `scripts/migrate/{lib}.conf` with version, URL, flags
2. Create `scripts/migrate/{lib}_post.sh` (empty initially)
3. Run `make stdlib-init-{lib}`
4. Fix errors — migrator bugs first, post-processing for the rest
5. Write `lib/std/{module}.w` (Layer 2 idiomatic API)
6. Write a With test program in `test/test_{module}.w`

### When asked to bump a dependency:

1. Edit `scripts/migrate/{lib}.conf` (version, URL)
2. `make stdlib-update-{lib}` (fetches, migrates, checks — does NOT promote)
3. Review the diff between `lib/std/{module}/` and `out/migrate/{lib}/prepared/`
4. `make stdlib-promote-{lib}` to deploy
5. `make build && make test`

### Critical rules:

- Never edit `lib/std/{module}/*.w` directly — they are generated
- Never `rm -rf lib/std/{module}/` — deploy module-by-module
- Always `make build && make fixpoint` after migrator changes
- Always measure error counts before and after any fix
- 30-minute limit per individual bug — add to post-processing and move on
```

---

## Integration Test

`test/test_stdlib_migration.sh` verifies the whole pipeline works:

```bash
#!/bin/bash
set -euo pipefail

echo "=== Testing stdlib migration pipeline ==="

# Test with a tiny C library (not a real dependency — just validates the pipeline)
mkdir -p /tmp/test_migrate_lib/src
cat > /tmp/test_migrate_lib/src/add.c << 'EOF'
int add(int a, int b) { return a + b; }
int mul(int a, int b) { return a * b; }
EOF

cat > /tmp/test_migrate_conf << 'EOF'
LIB_NAME=testlib
STD_MODULE=testlib
LIB_VERSION=1.0
SRC_DIR=/tmp/test_migrate_lib/src
MIGRATE_FLAGS=""
MIGRATE_EXTRA="--no-c-exports"
MIGRATE_SOURCES="*.c"
MIGRATE_EXCLUDE=""
PATCH_SCRIPT=""
PREAMBLE_FILE=""
DEFS_FILE=""
EOF

# Run pipeline
mkdir -p scripts/migrate
cp /tmp/test_migrate_conf scripts/migrate/testlib.conf
touch scripts/migrate/testlib_post.sh

scripts/migrate.sh migrate testlib
scripts/migrate.sh prepare testlib
scripts/migrate.sh check testlib
echo "PASS: migration pipeline"

# Cleanup
rm -rf out/migrate/testlib scripts/migrate/testlib.conf scripts/migrate/testlib_post.sh
rm -rf /tmp/test_migrate_lib /tmp/test_migrate_conf
```

---

## Summary: The Complete Flow

```
Developer types:              What happens:
─────────────────             ──────────────────────────────────
make stdlib-init-jq           1. Downloads jq source from GitHub
                              2. Runs with migrate on each .c file
                              3. Applies jq_post.sh fixups
                              4. Verifies all modules pass with check
                              5. Copies to lib/std/json/
                              6. Compiles to out/lib/libjq_with.a

vim lib/std/json.w            Developer writes idiomatic With API

make build                    Compiler links against libjq_with.a

make stdlib-remigrate-all     After migrator improvement, re-migrate everything

scripts/migrate_scorecard.sh  See health of all libraries at a glance
```

One command to add a library. One command to update it. One command to re-migrate everything after a tool improvement. The scorecard tells you what works and what doesn't.