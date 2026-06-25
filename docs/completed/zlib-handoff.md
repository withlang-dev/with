# zlib Migration — Handoff

Status: completed; archived as the zlib migration handoff and verification
record. Originally updated 2026-06-17 on branch **`main`**.

---

## 1. Goal & why

Two intertwined deliverables (full plan:
`~/.claude/plans/read-eliminate-makefile-md-project-state-linked-rose.md`):

1. **A general, unattended C→With migration pipeline**, validated by migrating
   **all of zlib** with zero per-library design attention. The real target is
   ~50 such libraries; zlib is the second instance after pcre2.
2. **A native `std.zlib`** (migrated, pure With) to provide gzip/DEFLATE for
   `.tar.gz` packaging in `docs/completed/eliminate-Makefile.md` (the build
   system must not shell out to host `tar`/`zstd`, and compiler-owned code may
   not `c_import`).

This handoff originally covered deliverable 1. The follow-up build graph,
stdlib facade, gzip/gunzip helper, packaging integration, and migrated zlib
tests have since landed.

## Completion evidence

As of 2026-06-24:

- `build/zlib.w` defines graph-owned `:zlib-reference`, `:zlib-migrate`,
  `:zlib-build`, `:zlib-test`, `:zlib-check-generated`, and `:zlib-promote`
  actions.
- `build.w` wires those targets into the project graph.
- `lib/std/zlib.w` provides the safe in-memory facade:
  `compress`, `compress_level`, `compress_gzip`, `compress_gzip_level`,
  `decompress`, `decompress_with_limit`, `decompress_gzip`, and
  `decompress_gzip_with_limit`.
- `lib/std/zlib/` contains the promoted migrated modules, including the
  upstream `example` and `minigzip` test programs.
- `build/zlib_gzip.w` and `build/zlib_gunzip.w` use the migrated `std.zlib`
  implementation for build/package archive flows.
- `run_zlib_test_action` compiles and runs migrated `example` and `minigzip`
  round-trip checks.

## 2. Methodology — NON-NEGOTIABLE RULES

- **Migrate the WHOLE library. No cherry-picking, no per-library customization.**
  Excluding hard files or adding zlib-specific knobs defeats the purpose.
- **Fix `with migrate` (the migrator) and re-migrate. NEVER hand-edit generated
  `.w`.** Loop until all of zlib migrates AND compiles.
- **Migrator bugs are fixed in THIS work, not filed** as issues.
- **Validate** via zlib's own migrated test suite.
- **Compiler-owned code (`src/`, `rt/`, `lib/std/`, `build.w`, `build/`) must
  NEVER `c_import`.** Packaging needs migrated `std.zlib`, never `c_import zlib`.
- **Commit discipline:** `with build` + `with build :fixpoint` + `with build
  :test` all green before every commit. Eric Hartford is the SOLE author — never
  add AI/co-author trailers.
- **Sequencing:** migrate and check all 15 zlib library sources together.
  Packaging comes after the migrated library has a real module/link surface and
  zlib's migrated tests pass against it.

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

Migrate the full library (the `with migrate` CLI is fully scriptable — runs in
seconds; only *changing the migrator* needs a ~5-min `with build`):
```sh
./out/release/bin/with migrate out/zlib_src -o out/zlib_migrated \
  --shared-defs std.zlib.defs --no-c-export -I out/zlib_src
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

## 5. Migration and synthetic compile bar: DONE for all 15 library files

As of 2026-06-17, all 15 zlib library files migrate with 0 untranslatable files
and the inlined-defs synthetic per-module compile check is clean. This is not
yet the same as "zlib's migrated tests pass against the migrated library";
packaging/linkage still needs a real module surface instead of per-file extern
references to sibling zlib functions.

synthetic per-module compile check is clean:

| Module | Errors |
| --- | ---: |
| adler32 | 0 |
| compress | 0 |
| crc32 | 0 |
| deflate | 0 |
| gzclose | 0 |
| gzlib | 0 |
| gzread | 0 |
| gzwrite | 0 |
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
  --shared-defs std.zlib.defs --no-c-export -I out/zlib_src
mkdir -p out/zcheck
for f in out/zlib_migrated/*.w; do
  mod=$(basename "$f" .w); [ "$mod" = defs ] && continue
  { cat out/zlib_migrated/defs.w; rg -v '^use std\.zlib' "$f"; } > "out/zcheck/$mod.w"
  errs=$(./out/release/bin/with check "out/zcheck/$mod.w" 2>&1 | tee "out/zcheck/$mod.err" | rg -c '^error')
  printf '%s: %s\n' "$mod" "${errs:-0}"
done
```

## 6. Fixed compile-bar gaps in the current working tree

- Full-library zlib migration now includes `gzclose.c`, `gzlib.c`, `gzread.c`,
  and `gzwrite.c`.
- `std.libc` exposes the POSIX/file APIs zlib's gzip path needs (`open`,
  `read`, `write`, `close`, `lseek`, `unlink`, `fcntl`) through runtime-backed
  wrappers where necessary.
- Normal With function declarations can carry `...` variadic signatures, and
  migrated C variadic definitions lower `va_start` / `va_end` to LLVM stdarg
  intrinsics through compiler-recognized `with_va_start` / `with_va_end` calls.
- `vsnprintf` is part of the explicit libc surface.
- C function pointer types are reconstructed/printed as `extern "C" fn(...)`
  and C zero/null assignments into pointer/function-pointer typed targets lower
  to `null`.
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

### Cross-module linkage

Completed. Promoted zlib modules now carry `use std.zlib.X` sibling imports and
public definitions where needed, so `--no-c-export` migrated modules compile
and link as normal With modules.

### Cosmetic / generalization residue
- Migrator emits redundant `unsafe` (warnings only).
- Hardcoded `"Migrated from PCRE2"` / "migrated PCRE2" labels at
  `src/CiMigrate.w:~338, ~341, ~830` — genericize (derive from the lib /
  shared-defs prefix).

## 7. Completion status

- Migrator/printer fixes are in history.
- The zlib graph targets are implemented and wired.
- Cross-module imports for promoted zlib modules are present.
- Migrated upstream `example` and `minigzip` are compiled and run by
  `:zlib-test`.
- The `std.zlib` facade and gzip/gunzip build helpers are implemented.
- Package flows use migrated zlib for `.tar.gz` archive compression and
  decompression.

## 8. Key files / functions / line numbers

- `src/CiMigrate.w`
  - `ci_migrate_shared_decl_add` (143) — shared-defs dedup (first-sighting)
  - `ci_migrate_shared_decl_upgrade_opaque_type` — opaque→concrete
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

## 9. Implemented follow-up

1. **`:zlib-test` validation:** `run_zlib_test_action` migrates zlib's upstream
   `example.c` and `minigzip.c`, compiles them against the migrated library, and
   runs example plus gzip/decompress round-trip checks.
2. **`build/zlib.w` graph targets:** `:zlib-reference`, `:zlib-migrate`,
   `:zlib-build`, `:zlib-check-generated`, `:zlib-test`, and `:zlib-promote`
   are implemented.
3. **Thin `lib/std/zlib.w` facade:** `std.zlib` exposes in-memory zlib and gzip
   compression/decompression over the migrated internals. It is pure With: no
   `c_import` and no extern dependency on system libz.
4. **Packaging:** build/package flows use `build/zlib_gzip.w` and
   `build/zlib_gunzip.w` helpers backed by `std.zlib` for `.tar.gz` archive
   creation and extraction.

## 10. Verification before any commit
```sh
with build && with build :fixpoint && with build :test && with build :test-green
```
All three green; `with build :test` counts baseline: behavior 682,
compile-error 576, codegen 16, spec 162, phase 21, internals 11, lexer 7,
parser 9, emit-C smoke OK. Then synthetic-check the codec modules (§3).
