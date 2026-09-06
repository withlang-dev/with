# Audit: build/clang_resource.w @ 450733e5

Scope: read-only source audit of the 215-line build-time module that generates
`out/gen/compiler/EmbeddedClangResourceData.w` from the static SDK's clang
builtin headers (`lib/clang/<v>/include`), so the shipped binary serves
clang's resource dir from inside itself (#312). Targets traced: T13
(ownership/drop), T15 (migration fidelity), T22 (spec conformance).

Callers (in-repo, via REGEX search for `clang_resource|embedded-clang-resource`,
excluding `out/`): `build.w:10` (`use build.clang_resource`), `build.w:1625-1627`
(`embedded-clang-resource-source` target, action
`generate_embedded_clang_resource_action`, output
`out/gen/compiler/EmbeddedClangResourceData.w`), `build.w:1548,1813,1842,1859,1876,1893`
(stage/bootstrap deps). Consumer of the generated data:
`src/compiler/EmbeddedClangResource.w` (`ensure_clang_resource_dir`, via
`src/CImport.w:277` and `src/CiMigrate.w:894,1020`). Data dep:
`compiler_default_llvm_prefix()` (`build/compiler.w:276-277`, in-project
`.deps/llvm-<ver>-<host>`, no `llvm-config` probing).

## Probes run
1. `out/bootstrap/bin/with-stage1 check build/clang_resource.w` → fails with
   `error: import module not found: 'build.compiler'` (build/clang_resource.w:13).
   HARNESS ARTIFACT, not a defect: `use build.compiler` resolves only with
   `build/` as module root under the real build entry — identical to the
   `build/emit_c.w` + `build/package.w` artifact recorded in
   `docs/audit/modules/build__lanes.w.md`. The module does compile under the build
   entry (evidence: `out/gen/compiler/EmbeddedClangResourceData.w` generated
   from this module at this commit, 36 headers, version `"22"`).
2. Listing↔branch consistency over `out/gen/compiler/EmbeddedClangResourceData.w`:
   36 `let CLANG_RES_<n>` symbols + LIST + VERSION = 38 `^let CLANG_RES_`;
   36 `if name ==` branches; 36 listing lines; branch set == listing set;
   0 duplicates either side; branches in sorted order; no absolute/`..` entries
   (only `llvm_libc_wrappers/`, `ppc_wrappers/` subdirs).
3. Raw-string escalation check: `cr_raw_string_literal` loop verified by
   reasoning (`"` → `"#` → `"##` … must terminate) plus generated-output
   evidence — 9 literals use `r#"..."#` (exactly the headers containing `"`
   bytes, e.g. the GPU-wrapper `#error "..."`), 27 use `r"..."`.
4. Missing-include probe (SDK clang 22, independent of the With toolchain):
   `#include <float.h>` preprocessed with
   `-resource-dir ~/.cache/with/clang-resource/22` (the cache materialized from
   this module's subset) → `fatal error: '__float_header_macro.h' file not
   found` (float.h:21). NOT a setup artifact — see negative controls.
5. Negative controls: (a) same file with
   `-resource-dir .deps/llvm-22.1.6-linux-x86_64/lib/clang/22` → rc=0;
   (b) `#include <stddef.h>` with the cache resource dir → rc=0. So the
   breakage is specific to the subset (float.h family), not the harness.
6. Negative REGEX controls: `cr_generate|cr_should_embed|cr_find_include_dir|`
   `cr_raw_string_literal|cr_sorted|cr_relpath|cr_dirname|cr_basename|`
   `clang_resource_owned_text` across `*.w` excluding `out/` and
   `build/clang_resource.w` → only the compiler-side twin `ecr_dirname`
   (`src/compiler/EmbeddedClangResource.w:21,58`, deliberately divergent —
   absolute forward-slash paths only) matches. All generator helpers are
   module-private with a single in-module caller each.
7. Include-closure sweep: for every header `cr_should_embed` accepts, grepped
   its plain `#include <…>` lines in
   `.deps/llvm-22.1.6-linux-x86_64/lib/clang/22/include` and checked each
   against the embed set (see Findings).

## Findings
1. build/clang_resource.w:112-127 (`cr_should_embed`) — Severity: medium —
   Targets: T22 — Probe status: confirmed by execution probes 4/5 (probe 4
   fails, both controls in probe 5 pass). The filter embeds `float.h` but none
   of its three unconditional internal includes: `float.h` contains
   `#include <__float_header_macro.h>`, `#include <__float_float.h>`, and
   `#include <__float_infinity_nan.h>` (plain includes, resolved against the
   resource dir — unlike the `#include_next` system fallbacks in
   `limits.h`/`stdint.h`), and all three exist in the SDK include dir (241
   files) yet match no `cr_should_embed` branch (no `__float_` rule). Default
   `c_import` of `<float.h>` is therefore broken out of the box; the committed
   test `tests/test_cimport.w:18` + `:169-174` (`use c_import("<float.h>")`,
   asserts `FLT_MAX`/`DBL_MAX`/`FLT_EPSILON`) exercises exactly this path.
   Refutation attempts: (a) `WITH_CLANG_RESOURCE_DIR` override — escape hatch
   for "the rare header outside the set", not a fix for the default path, and
   the header is explicitly *inside* the curated set; (b) landed-commit intent
   (`5c6df72a`, "Embed the curated C/POSIX clang headers") lists float.h as a
   header "a c_import realistically needs" and enumerates only
   "`__stddef_*`/`__stdarg_*` fragments" — the `__float_*` omission reads as
   oversight, not deliberate exclusion (no size argument applies: 3 tiny
   files); (c) sibling headers survive the same sweep — `stddef.h`'s ten
   `__stddef_*` includes and `stdarg.h`'s five `__stdarg_*` includes are all
   embedded, `stdatomic.h` needs only `stddef.h`/`stdint.h` (embedded),
   `tgmath.h`→`complex.h`/`math.h` and `mm_malloc.h`→`malloc.h`/`stdlib.h`
   are system/target headers per spec §16.1, not resource-dir builtins.
   Defect survives all three. Fix direction (not applied, read-only audit):
   add `if name.starts_with("__float_") and name.ends_with(".h"): return true`.

## Reviewed and refuted (not defects)
- T13: module owns no handles — only `str`/`Vec[str]`/`i32`; `s ++ ""`
  owned-text duplication (`clang_resource_owned_text`, :14) is the exact
  idiom of `build.w:17`, `build/abi.w:11`, `build/sdk.w:7`; `cr_sorted`
  (:65-80) mirrors the `sdk.w:213-217` insertion-sort ownership pattern;
  `sorted = out` move-assign is sound. No drop/move obligations anywhere.
- T15: signatures use `&str`/`&Vec[str]`/`&ActionCtx` per the #747 migration,
  `as i32`/`as i64` casts, `Vec.new()`/`f"…"` spellings match siblings;
  compiles under the build entry (probe 1 artifact explained above).
- T22 (remainder): no system-LLVM probing — reads the in-project `.deps` SDK
  via `compiler_default_llvm_prefix()` (in-repo callers at build.w,
  build/compiler.w agree); version extraction
  `cr_basename(cr_dirname(include_dir))` verified end-to-end (`"22"` in the
  generated output); `cr_find_include_dir` first-`/include/`-match is
  deterministic in practice (`.deps` holds exactly one clang version by
  construction); `cr_relpath` basename fallback is dead but harmless (prefix
  always matches since `include_dir` derives from the same tree);
  basename-filter side effect of embedding `llvm_libc_wrappers/inttypes.h`
  and `ppc_wrappers/mm_malloc.h` is harmless (GPU-only `#error` guard /
  subdirectory preserved, never included on host); `cr_generate`'s `""`
  error sentinel is unambiguous (a successful output always contains the
  header + LIST + VERSION prologue).
- Apparent missing closing quote in `cr_raw_string_literal` (:104):
  `"r" ++ hashes ++ "\"" ++ text ++ "\"" ++ hashes` is correct — the `r#"…"#`
  closer is quote-then-hashes, no trailing quote. Refuted by probe 3.

## Verdict: INCOMPLETE
