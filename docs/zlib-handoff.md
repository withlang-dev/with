# zlib Migration — Handoff

Status doc for an agent taking over the zlib-into-With migration. Updated
2026-06-17. Branch: **`main`**.

---

## 1. Goal & why

Two intertwined deliverables (full plan:
`~/.claude/plans/read-eliminate-makefile-md-project-state-linked-rose.md`):

1. **A general, unattended C→With migration pipeline**, validated by migrating
   **all of zlib** with zero per-library design attention. The real target is
   ~50 such libraries; zlib is the second instance after pcre2.
2. **A native `std.zlib`** (migrated, pure With) to provide gzip/DEFLATE for
   `.tar.gz` packaging in `docs/eliminate-Makefile.md` (the build system must not
   shell out to host `tar`/`zstd`, and compiler-owned code may not `c_import`).

This handoff covers deliverable 1 (the migration). Packaging is later phases.

## 2. Methodology — NON-NEGOTIABLE RULES

- **Migrate the WHOLE library. No cherry-picking, no per-library customization.**
  Excluding hard files or adding zlib-specific knobs defeats the purpose.
- **Fix `with migrate` (the migrator) and re-migrate. NEVER hand-edit generated
  `.w`.** Loop until all of zlib migrates AND compiles.
- **Migrator bugs are fixed in THIS work, not filed** as issues.
- **Validate** via zlib's own migrated test suite (eventually).
- **Compiler-owned code (`src/`, `rt/`, `lib/std/`, `build.w`, `build/`) must
  NEVER `c_import`.** Packaging needs migrated `std.zlib`, never `c_import zlib`.
- **Commit discipline:** `with build` + `with build :fixpoint` + `with build
  :test` all green before every commit. Eric Hartford is the SOLE author — never
  add AI/co-author trailers.
- **Sequencing:** the 11 codec files first; the 4 `gz*` file-I/O files
  (gzclose, gzlib, gzread, gzwrite — need `lseek`/POSIX bindings in `std.libc`)
  are deferred. Packaging comes after the codec compiles + tests.

## 3. How to drive migration (fast loop, no compiler rebuild)

zlib 1.3.2 is staged at `out/zlib_src/` (the 15 library `.c` files + headers).
Source tarball sha256 (the v1.3.2 release `.tar.gz` asset):
`bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16`.

Re-stage if needed:
```sh
mkdir -p out/zlib_reference && cd out/zlib_reference
curl -L --fail -o zlib-1.3.2.tar.gz https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz
tar -xzf zlib-1.3.2.tar.gz
cd /Users/eric/with && rm -rf out/zlib_src && mkdir -p out/zlib_src
cp out/zlib_reference/zlib-1.3.2/*.c out/zlib_reference/zlib-1.3.2/*.h out/zlib_src/
```

Migrate the codec subset (the `with migrate` CLI is fully scriptable — runs in
seconds; only *changing the migrator* needs a ~5-min `with build`):
```sh
./out/release/bin/with migrate out/zlib_src -o out/zlib_migrated \
  --shared-defs std.zlib.defs --no-c-export -I out/zlib_src \
  --exclude gzclose.c --exclude gzlib.c --exclude gzread.c --exclude gzwrite.c
```

`with migrate` CLI flags (handler `run_migrate_command`, `src/main.w:~2402`):
`-o <out>`, `-I <inc>`, `-include <hdr>`, `-D <define>`, `--no-c-export`,
`--prefer-brace|--prefer-colon`, `--width-slice N`, `--shared-defs <prefix>`,
`--migrate-one <basename>`, `--exclude <basename>`.

**Synthetic per-module compile check** (mirrors the pcre2 pipeline — inline
`defs.w`, drop the `use std.zlib` line, `with check`):
```sh
defs=$(cat out/zlib_migrated/defs.w)
for f in out/zlib_migrated/*.w; do
  mod=$(basename "$f" .w); [ "$mod" = defs ] && continue
  body=$(grep -v '^use std.zlib' "$f")
  printf '%s\n%s\n' "$defs" "$body" > out/zcheck/$mod.w
  errs=$(./out/release/bin/with check out/zcheck/$mod.w 2>&1 | rg -c '^error')
  echo "$mod: ${errs:-0}"
done
```

## 4. What's already in history

All three verified green (build + fixpoint + test):

| Commit | What |
| --- | --- |
| `1382b866` | 3 general migrator fixes: (a) recover `sizeof` under function-like / cross-file macro expansion via new bridge accessor `with_ci_cursor_spelling_head` (reads the operator keyword at the cursor's spelling-START location, which points into the macro body even when the operand type lives in another header); (b) portable-baseline migrate preamble (`ci_migrate_portable_baseline_preamble`, in `ci_migrate_source_prefix`) that `#undef`s host CPU-feature macros (`__ARM_FEATURE_CRC32`, AVX/SSE4, NEON crypto…) so libs take their generic C path, not inline-asm/SIMD; (c) treat an empty translated function body `{}` as success not failure (CiMigrate.w `~1341`, gated `ret == "Unit" and fn_body_cursor>=0 and num_children==0`). **Result: all 11 codec files migrate with 0 untranslatable.** |
| `7b44d300` | `calloc` IR-path lowering (CImport.w `build_libc_call_value_expr`, `~7862`) now mirrors `malloc`: cast args to i64, `unsafe` wrap, cast `*i8` result to `*c_void`, call `with_alloc_zeroed`; and the migrate preamble (CiMigrate.w `~516`) declares `extern fn with_alloc_zeroed(count: i64, size: i64) -> *i8`. |
| `445a45f1` | Parser: `sizeof[T]`/`alignof[T]` accept function-pointer types. In `Parser.parse_index_or_slice`, when the bracket starts with `extern`/`fn` (tokens that can't begin an index expression), parse a TYPE and store it as `NK_INDEX.data1` (sema's `sizeof_alignof_type_arg_node` resolves it as a type). |

## 5. Migration and synthetic compile bar: DONE for codec subset

As of 2026-06-17, the 11 codec files migrate with 0 untranslatable files and the
synthetic per-module compile check is clean:

| Module | Errors |
| --- | ---: |
| adler32 | 0 |
| compress | 0 |
| crc32 | 0 |
| deflate | 0 |
| infback | 0 |
| inffast | 0 |
| inflate | 0 |
| inftrees | 0 |
| trees | 0 |
| uncompr | 0 |
| zutil | 0 |

Latest evidence command:
```sh
rm -rf out/zlib_migrated out/zcheck
./out/release/bin/with migrate out/zlib_src -o out/zlib_migrated \
  --shared-defs std.zlib.defs --no-c-export -I out/zlib_src \
  --exclude gzclose.c --exclude gzlib.c --exclude gzread.c --exclude gzwrite.c
mkdir -p out/zcheck
for f in out/zlib_migrated/*.w; do
  mod=$(basename "$f" .w); [ "$mod" = defs ] && continue
  { cat out/zlib_migrated/defs.w; rg -v '^use std\.zlib' "$f"; } > "out/zcheck/$mod.w"
  errs=$(./out/release/bin/with check "out/zcheck/$mod.w" 2>&1 | tee "out/zcheck/$mod.err" | rg -c '^error')
  printf '%s: %s\n' "$mod" "${errs:-0}"
done
```

## 6. Fixed compile-bar gaps in the current working tree

- Shared defs now upgrade an already-recorded opaque type when a later file
  provides the concrete body. The positive signal is `type <name> {` or
  `type <name> = union {`, so anonymous nested opaque declarations do not block
  the upgrade.
- C call/assignment coercion now handles string literals to C string pointers
  and integer zero to pointer `null` in typed contexts.
- Function-pointer dereference used for C `(*fp)(...)` now lowers to the function
  pointer value itself before call printing.
- C char array initializers from string literals now lower to element arrays.
- Migrated C POD structs/unions, including anonymous subrecords, now get
  `impl Copy`.
- Anonymous record field initializers now use synthesized names such as
  `ct_data_s_fc` / `ct_data_s_dl`, not libclang raw spellings like
  `ct_data_s::(unnamed at ...)`.
- Compound bitwise assignments now spell C integer conversions explicitly enough
  for With's mixed-signedness checker.
- `do while` output is desugared into an explicit loop, and terminating
  `if`-then branches print in guard form to avoid false unreachable diagnostics.

### Cross-module linkage (after the per-module errors clear)
Migrated modules reference siblings via `extern fn` (e.g. `compress.w` externs
`deflate`), because those functions are declared in `zlib.h`. With `--no-c-export`
they won't link cross-module. The pcre2 pipeline solves this with
`pcre2_ensure_generated_dependencies` (build/pcre2.w) — a HARDCODED per-module
`use std.re.X` injection list. For zlib this must be **generalized** (auto-derive
`use std.zlib.X` imports from referenced sibling symbols; make the defining
functions `pub`). This is a Phase-C generalization target, not a per-lib list.

### Cosmetic / generalization residue
- Migrator emits redundant `unsafe` (warnings only).
- Hardcoded `"Migrated from PCRE2"` / "migrated PCRE2" labels at
  `src/CiMigrate.w:~338, ~341, ~830` — genericize (derive from the lib /
  shared-defs prefix).

## 7. Remaining work

- Keep green: `with build`, `with build :fixpoint`, `with build :test`, and
  `with build :test-green`.
- Commit the current migrator/printer fixes on `main` after the full checklist
  is green.
- Generalize cross-module imports for migrated libraries. Migrated modules still
  reference sibling functions via declarations from headers; the pcre2 path uses
  a hardcoded dependency injection list. zlib should drive a generic solution
  that derives `use std.zlib.<module>` imports from referenced sibling symbols
  and makes defining functions `pub`.
- Defer the four file-I/O sources (`gzclose.c`, `gzlib.c`, `gzread.c`,
  `gzwrite.c`) until the POSIX/libc surface needed for `lseek` and friends is
  available in `std.libc`.
- Cosmetic cleanup remains: redundant `unsafe` warnings and old PCRE2 wording in
  generic migration messages.

## 8. Key files / functions / line numbers

- `src/CiMigrate.w`
  - `ci_migrate_shared_decl_add` (143) — shared-defs dedup (first-sighting)
  - `ci_migrate_shared_decl_upgrade_opaque_type` (WIP, added) — opaque→concrete
  - `ci_migrate_write_shared_defs` (337; reads `g_migrate_shared_decl_buf` @354)
  - `ci_migrate_shared_defs_reset` (126); globals `g_migrate_shared_decl_buf`
    (60, `Vec[str]`), `_keys` (61, str), `_records` (62, `Vec[str]`)
  - `ci_migrate_source_prefix` (598) + `ci_migrate_portable_baseline_preamble`
    (committed); `migrate_c_directory` (1133); `ci_migrate_file_inner` (739,
    calls `with_cimport_parse(source)` directly)
  - empty-body success fix (~1341); preamble libc externs (~456–520)
  - hardcoded "PCRE2" labels (~338, 341, 830)
- `src/CImport.w`
  - type rendering → `ci_migrate_shared_decl_add("type", …)` at 1701 (demoted
    opaque), 1785 (concrete struct), 1935, 1954; forward-decl-skip-if-defined at
    1690 (`ci_record_definition_exists`, 824)
  - `ci_type_name_is_emitted` (850) / `ci_mark_type_name_emitted` (853) (per-file)
  - `ci_render_missing_pointer_opaques` (946) — **c_import only**, not migrate
  - sizeof macro recovery in `CiExprPool.lower_expr_ir` `CXK_UNARY_EXPR` (~6298,
    committed); `calloc` in `build_libc_call_value_expr` (~7862, committed)
- `src/compiler/ClangBridge.w`
  - `with_ci_cursor_spelling_head` (committed) + helper
    `cursor_spelling_head_from_cursor`
- `src/Parser.w` — `parse_index_or_slice` sizeof[fn-type] fix (committed)
- `src/SemaCheck.w` — `sizeof_alignof_type_arg_node` (10509),
  `is_sizeof_or_alignof` (10489)
- `src/main.w` — `run_migrate_command` (~2402)
- Pipeline template: `build/pcre2.w` (mirror for `:zlib-*` targets, but
  generalize — do NOT clone its per-lib knobs: hardcoded file-rank table, import
  injection, width-slice, test-output normalization)

## 9. After the codec compiles

1. **`:zlib-test`-equivalent validation:** migrate zlib's OWN test suite
   (`out/zlib_src` has `test/example.c`, `test/minigzip.c` upstream — re-stage
   from `out/zlib_reference/zlib-1.3.2/test/`) and run it against the migrated
   codec. This is the acceptance gate ("migrates AND compiles AND its tests
   pass"), like `:pcre2-test` runs upstream RunTest.
2. **`build/zlib.w` graph targets:** `:zlib-reference` (pin v1.3.2 + enforce the
   sha256 above via `ToolFs.sha256_file`), `:zlib-migrate`, `:zlib-build`,
   `:zlib-check-generated`, `:zlib-test`, `:zlib-promote` → `lib/std/zlib/`.
   Mirror `build/pcre2.w` but config-minimal + generalized.
3. **Thin `lib/std/zlib.w` facade:** `gzip_compress(bytes, level) -> Vec[u8]` /
   `gzip_decompress(bytes) -> Vec[u8]` over the migrated internals (zero
   gzip-header mtime for determinism). Pure With — no `c_import`, no extern to
   system libz.
4. **`gz*` family** (deferred): gzclose/gzlib/gzread/gzwrite do file I/O
   (`lseek`/`open`/`read`/`write`) — need POSIX bindings in `std.libc`.
5. **Packaging** (plan Phases B/D/E): native compiler-binary packages (no
   compression; SDK `llvm-readobj`/`llvm-nm`/`llvm-strip` inspection), `.tar.gz`
   via `std.zlib`, SDK/bootstrap packaging.

## 10. Verification before any commit
```sh
with build && with build :fixpoint && with build :test && with build :test-green
```
All three green; `with build :test` counts baseline: behavior 682,
compile-error 576, codegen 16, spec 162, phase 21, internals 11, lexer 7,
parser 9, emit-C smoke OK. Then synthetic-check the codec modules (§3).
