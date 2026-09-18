# Audit: build/release_uat_fixtures/zlib_main.w @ 450733e5 — INCOMPLETE

Module: `build/release_uat_fixtures/zlib_main.w` (37 lines, read completely) —
release-UAT probe program for the `c.zlib` package. The gate
(`build/release_uat.w:334-335`, `ruat_run_c_package_uat`) reads this fixture
as text, writes it over `src/main.w` in a fresh `with init` project after
`with get c.zlib`, then `with run` must print `zlib UAT passed`. Declared as
a build-graph target input (`build.w:2675`), write scope `out/release-uat`,
`allow_network`, `dep require-last-green`. Sole in-repo caller of the file.
Landed intent: commit `7b39ff0f` ("Move release UAT probe programs to fixture
files") — content byte-identical to the old escaped-string builder; no
semantic change intended.

## Targets traced
- T13 ownership/drop: CLEAN. No owned heap values anywhere: two stack arrays
  (`compressed: [u8; 256]`, `output: [u8; 128]`), integer lengths
  (`uLongf`), string literal `input`. All cross-language pointers are
  `&raw mut` / `&raw const` borrows inside `unsafe` blocks; `same_prefix`
  takes `*const u8` and copies nothing. No moves, no drops, no live-value
  drop points. Nothing to refute.
- T15 migration fidelity: CLEAN. Diff of `7b39ff0f -- */zlib_main.w` against
  the current 37-line file matches line-for-line; the pre-move builder
  (`7b39ff0f^:build/release_uat.w:192-224`, `ruat_zlib_program`) emits the
  same `use c_import("zlib.h")`, `same_prefix`, compress/uncompress checks,
  `zlibVersion()` null check, and `write("zlib UAT passed\\n")`. The
  byte-identical claim in the commit message holds for this fixture.
- T22 spec conformance: DEFECT (F1 below). `fn main:` form matches the
  `examples/hello.w` and `cli_init_main_template` (`src/main.w:5110`) idiom;
  `return 1` failure arms, `unsafe` blocks, `&raw`, and `c_import` all pass
  the seed checker (no diagnostics on lines 1-36). Only line 37 fails.

## Findings
1. `build/release_uat_fixtures/zlib_main.w:37` — severity: gate-blocking —
   T22 spec conformance — probe status: REPRODUCED (P1, P2). Bare `write(...)`
   violates the closed §18.2 prelude
   (`docs/with-specification.md:10325-10340`: prelude has `print`, `eprint`
   but NOT `write`). Seed `out/bootstrap/bin/with-stage1` rejects it:
   `'write' requires an explicit import (§18.1); add: use std.builtins.write`.
   Refutation attempt: prelude/fallback-tier defense fails — the D fallback
   tier is not active at this commit (per `docs/decisions.md` D29 work items,
   only scaffolding `6430d1ee` has landed, and it is an ancestor of
   `450733e5`); under scaffolding a non-prelude std name resolves only via
   explicit import. Older-compiler defense fails — the audit pins commit
   `450733e5`, whose compiler enforces the gate. Scope note: the same bare
   `write` appears in all four sibling C-package fixtures (`bzip2`,
   `sqlite3`, `openssl`, `libcurl` `*_main.w:34/38/42/36`); `raylib_spiral`
   uses only `print` (prelude, clean). Fix (not applied, read-only mandate):
   add `use std.builtins.write` to the fixture. Landed-commit intent does not
   cover this — `6430d1ee`'s sweep ("compiler's own sources, build/, and
   tools/") never touched `build/release_uat_fixtures/` (no fixture path in
   its `--stat`; only fixture history is `7b39ff0f`), because fixtures are
   text data, never compiled in-repo. Do not file issues (caller instruction).

## Probes run (seed out/bootstrap/bin/with-stage1)
- P1 `check build/release_uat_fixtures/zlib_main.w` → 1 error, only line 37
  (`'write' requires an explicit import (§18.1)`), `check failed during
  compilation`. Lines 1-36 (c_import, unsafe fn, &raw, return 1) clean.
  REPRODUCES F1.
- P2 project-mode: fresh `with-stage1 init` project in `/tmp/zlib_probe`,
  `src/main.w` = `fn main:` + bare `write("probe hi\\n")`, `run` → same
  §18.1 error on `src/main.w:2`. Confirms the UAT gate path (project `run`,
  not just bare-file `check`) is affected. REPRODUCES F1.
- P3 `check examples/hello.w` (bare `print`) → `ok`, rc=0. Prelude still
  provides `print`; checker discriminates correctly.

## Negative controls
- N1 bare `write` in project mode fails (P2) while bare `print` passes (P3):
  the probe is specific to prelude membership, not a blanket rejection.
- N2 `check examples/fizzbuzz.w` fails on an unrelated type error
  (`match i32` arm producing `&str`), proving the seed checker performs real
  sema rather than stub-pass.
- N3 claimed adjacent coverage verified to exist: behavior test
  `test/behavior/behav_zlib_std.w` (exists, `use std.zlib`, `//! 
  expect-stdout: ok`) covers the std wrapper, not this C-linkage probe; the
  fixture's only executor is the release-UAT gate (`build.w:2672-2678`).
  No test file asserts this fixture's content.

Verdict: INCOMPLETE (1 gate-blocking finding: F1 bare `write` needs `use std.builtins.write`)
