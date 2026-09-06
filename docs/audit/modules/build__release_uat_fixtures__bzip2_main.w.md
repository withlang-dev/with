# Audit: build/release_uat_fixtures/bzip2_main.w @ 450733e5 — COMPLETE

Module: `build/release_uat_fixtures/bzip2_main.w` (34 lines, read completely) —
release UAT probe main for the `c.bzip2` package: `BZ2_bzBuffToBuffCompress`
(blockSize 9, verbosity 0, workFactor 30) then `BZ2_bzBuffToBuffDecompress`
roundtrip of `"with bzip2 roundtrip"`, with length + byte-prefix checks,
`return 1` on any failure, `write("bzip2 UAT passed\n")` on success.
Callers: `build/release_uat.w:337-338` (`run_release_bzip2_uat_action` →
`ruat_run_c_package_uat(ctx, "c.bzip2", "bzip2",
"build/release_uat_fixtures/bzip2_main.w", "bzip2 UAT passed")`, which reads
the fixture, scaffolds `out/release-uat/bzip2-project` via `with init`,
`with get c.bzip2`, writes fixture to `src/main.w`, and asserts stdout);
`build.w:2682-2690` (`release-bzip2-uat` target, fixture declared as
`.input`, `allow_network`, `require-last-green` dep, member of `release-uat`
group at `build.w:2753`). Landed intent: `7b39ff0f` ("Move release UAT probe
programs to fixture files") — fixture extracted from inline probe; shape
matches intent. No other callers.

## Targets traced
- T13 ownership/drop: no owned values, no `move`, no heap allocation. All
  state is stack arrays (`compressed: [u8; 512]`, `output: [u8; 128]`) plus
  scalar lens; `same_prefix` takes borrowed raw pointers (`*const u8`) and
  returns `bool` by value. `&raw mut` / `&raw const` borrows are short-lived
  inside call expressions. Byte-identical borrow/ownership idiom to sibling
  `zlib_main.w:3-9,31`. No live-value drops. Clean.
- T15 migration fidelity: N/A — hand-written UAT main, not migrated output;
  no migrate flags apply. C-FFI fidelity: `use c_import("bzlib.h")` matches
  the `c.bzip2` package header by name; arg order on both calls matches the
  canonical `BZ2_bzBuffToBuff{Compress,Decompress}` signatures
  (dest, destLen, src, srcLen, blockSize/verbosity/workFactor and
  dest, destLen, src, srcLen, small, verbosity); `input as *mut c_char`
  for the source buffer is faithful to the C signature's non-const `char*`
  (sibling `zlib_main.w:18` uses `*const` because zlib's signature is
  const-qualified — divergence is API fidelity, not drift). Clean.
- T22 spec conformance: `use c_import`, `unsafe fn same_prefix(...):` /
  `fn main:` colon forms, `while`/`var`/`let`, `as` casts
  (`c_uint`/`c_char`/`*mut`/`*const`), `print` on failure paths vs `write`
  on the pass path (exact sibling convention from `zlib_main.w:19-37`),
  integer `return 1` failure codes, `output_len`/`input.len()` length gate
  before content comparison. `ruat_run_c_package_uat` asserts exactly
  `"bzip2 UAT passed"` on stdout, which only `write` (line 34) produces.
  Clean.

## Probes run (seed out/bootstrap/bin/with-stage1)
- P1 `check build/release_uat_fixtures/bzip2_main.w` → `error: 'write'
  requires an explicit import (§18.1)` at `bzip2_main.w:34:5`, check fails.
  Status: EXPECTED under the bare seed — fixtures execute as `src/main.w`
  inside a `with init` scaffold (which supplies the prelude), never as
  bare-seed check targets. Parse/resolve of every other construct (`unsafe
  fn`, `&raw mut/const`, `c_import`, `return 1`) succeeded to reach the
  §18.1 resolve stage. Not a module defect.
- P2 control `check build/release_uat_fixtures/zlib_main.w` → identical
  §18.1 `write`-import error at `zlib_main.w:37:5`. Confirms P1 is
  scaffold-vs-seed harness behavior shared by the landed passing sibling,
  not bzip2-specific. PASS as negative control.

## Negative controls
- N1 bare-seed `check` failure (P1) refuted as defect by the zlib sibling
  control (P2): same error, same stage, on the already-landed fixture.
- N2 `*mut c_char` source-pointer cast (line 18) refuted as const-correctness
  defect: bzlib's C signature takes non-const `char*`; the `*mut` cast is
  required for fidelity, and the sibling's `*const` matches zlib's
  const-qualified signature. No in-repo caller contradicts this.
- N3 no files under `tests/ test/ tools/ scripts/` reference `bzip2_main`
  or `release_uat_fixtures` (grep, empty) — coverage is the build-graph UAT
  gate itself (`build.w:2682-2690` + `build/release_uat.w:337-338`); no
  unit-test coverage claimed beyond that. Fixture file exists in tree.

## Findings
(none — no defects survived refutation)

Verdict: COMPLETE (no defects; T13/T15/T22 clean, 2 probes + 3 negative controls).
