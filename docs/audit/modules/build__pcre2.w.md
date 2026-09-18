# Audit — `build/pcre2.w`

Status: **COMPLETE**
Source revision: `450733e5` (module untouched by it; `git show 450733e5 --stat` touches only `build.w`, `src/main.w`)
Source SHA-256: `e01f1394497287c5bf744cf1bb4080c404b549096eea5c2ab69b7a0c3aab998e`
Lines examined: 1–940 (full module, single read)

Applicable targets: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).

## Verdict: COMPLETE — no defect findings

## Findings

### F1 — build/pcre2.w:261,270,282,302,328,335 — info — T22 — probe: static (grep) — refuted as defect
Five private helpers from the retired isolated synthetic check are now dead:
`pcre2_line_starts_with_fn_main` (261, used only by 270),
`pcre2_module_defines_main` (270), `pcre2_module_body_for_synthetic_check` (282),
`pcre2_first_function_name` (302), `pcre2_check_synthetic_module` (335, with
`pcre2_decls_contain_function` at 328 used only inside it). Each occurs exactly
once (def) repo-wide; all are non-`pub`, so no external caller can exist.
Refutation: commit `f3c8048f` ("replace the isolated synthetic check with a
cohesive compile") deliberately replaced the per-module check with the cohesive
check in `pcre2_count_generated_errors` (455–502) and left the helpers;
`check build.w` rc=0 confirms no unused-symbol error under current spec, and
the dead code has no runtime effect. Dead-code hygiene note only, not a defect.
No issue filed per instructions.

### F2 — build/pcre2.w:73–93 (`pcre2_emit_normalized_heap_line`) — info — T15 — probe: code review (execution HELD: full `RunTest` corpus too heavy for audit probe) — refuted as defect
Frame-size/heap-size/malloc-free rewrites are hardcoded to observed values
(e.g. frame_count 1..8 → 136/632/152/16136/16136/136/152/152).
Refutation: this is a test-output normalizer for upstream `testoutputheap-8`,
applied in `pcre2_prepare_reference_tree` (571–578) only when content differs;
the 3-line window logic was traced — rewrite arms match only malloc/free
triples, never `Frame size` lines, so the missing `frame_count` increment in
rewrite arms is unreachable, and `i + 2 < line_count` is the correct strict
bound for a 3-line window. Brittle-by-design, no logic error found.

## T13 ownership/drop — clean
- `pub run_*_action(ctx: ActionCtx)` take ctx by value; private helpers take
  `&ActionCtx` — matches sibling `build/zlib.w` convention.
- `move excludes` at 683/733 matches by-value `excludes: Vec[str]` param (173);
  `move names` into `comp_sort_strings` (423) matches its by-value signature
  (build/compiler.w:1951). `check build.w` rc=0 confirms all moves/borrows.
- `let _remove_extract_root = fs.remove_tree(tmp_dir)` (639) ignores rc:
  best-effort temp cleanup after successful rename; same pattern as siblings.
- Cross-module caller `build/selfhost.w:7369` passes `&ActionCtx` to
  `pcre2_count_generated_errors(ctx, ...)` (455, `&ActionCtx` param) — consistent.

## T15 migration fidelity — clean
- `pcre2_migrate_options` (173–199) matches sibling `zlib_migrate_options`
  field-for-field except intended deltas: `defines=[PCRE2_CODE_UNIT_WIDTH=8,
  HAVE_CONFIG_H=1]`, `exclude_basenames` wired from action args (677–681),
  `shared_defs="std.re.defs"`. `block_style=2`, `width_slice=8`,
  `no_c_export=true`, `convert_goto_to_structured=false` identical.
- Triple `c_export` enforcement: `no_c_export=true` + `pcre2_reject_c_exports`
  gate on migrate (691) / promote (915) / check-generated (895) + smoke-test
  rejection (739). `generated_count < 30` floor (689) guards empty migration.
- `config.h` synthesis (547–568) defines `SUPPORT_PCRE2_8`/`SUPPORT_UNICODE`
  and inherits upstream numeric defaults via `#include "config.h.generic"` —
  consistent with the 8-bit-only build flag in migrate options.

## T22 spec conformance — clean
- All 8 `pub run_*_action` entries validate `inputs`/`args`/`output` arity
  first and fail via `pcre2_fail` (diagnostics + return 1); stamp/output writes
  checked everywhere (e.g. 452, 646, 708, 903).
- `pcre2_bundle_root_text` (414, pure `pub fn`) is shared by writer
  `pcre2_write_bundle_root` (431) and checker
  `run_pcre2_bundle_root_check_action` (441) — the wo-drift pair cannot diverge
  by construction; harness modules (`bundle`, `pcre2test`, `pcre2posix`)
  excluded symmetrically (421 vs import loop 401).

## Probes run
1. `out/bootstrap/bin/with-stage1 check build.w` → `ok`, rc=0 (whole build
   package incl. this module typechecks; ownership/borrow/moves verified).
2. `out/bootstrap/bin/with-stage1 check build/pcre2.w` → expected resolution
   failure (`import module not found: 'build.compiler'`) — submodule must be
   checked via the package root; see negative controls.
3. Repo-wide caller search: `pcre2_bundle_root_text` / callers
   `pcre2_count_generated_errors` — sole in-repo caller `build/selfhost.w:7369`;
   dead-helper defs occur exactly once each (no callers).
4. Sibling diff vs `build/zlib.w` migrate options — shape match confirmed.
5. `git show 450733e5 --stat` + `git log --oneline -5 -- build/pcre2.w` —
   landed-commit intent established (module predates commit; helpers left by
   `f3c8048f` deliberately).

## Negative controls
- N1: standalone `check build/pcre2.w` fails on module resolution while `check
  build.w` passes — proves probe (1) exercises the module rather than
  vacuously passing, and scopes the T13 typecheck claim to package-root
  checking.
- N2: searched REGEX-callable surface for stray callers of the five dead
  helpers outside `build/pcre2.w` — zero hits, confirming F1 is dead code, not
  a live path the audit missed.

Verdict: COMPLETE
