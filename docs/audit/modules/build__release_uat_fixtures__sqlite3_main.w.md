# Audit: build/release_uat_fixtures/sqlite3_main.w @ 450733e5

Scope: full module (38 lines, read completely). Targets: T13 ownership/drop,
T15 migration fidelity, T22 spec conformance.
Caller: build/release_uat.w:341 `run_release_sqlite3_uat_action` ->
`ruat_run_c_package_uat(ctx, "c.sqlite3", "sqlite3",
"build/release_uat_fixtures/sqlite3_main.w", "sqlite3 UAT passed")`
(verified via grep; fixture read into fresh `with init` project after
`with get c.sqlite3`, source written to src/main.w, `run` output matched).

## Probes run
- P1 `with-stage1 ast sqlite3_main.w`: PASS, parses; SQLITE_OK/SQLITE_ROW
  references present in AST output.
- P2 `with-stage1 check sqlite3_main.w` (standalone, no package/project):
  7x `error: undefined variable` at 39:1 (EOF) + 1x `'write' requires an
  explicit import` at 38:5. See F1/F2 (both refuted).
- P3 Negative controls: `check zlib_main.w` -> only the `write`-import error;
  `check bzip2_main.w` -> only the `write`-import error. So the `write` error
  is a standalone-probe artifact shared by every fixture (prelude comes from
  the `with init` project in the real flow), not a defect.
- P4 History: `git show 7b39ff0f` ("Move release UAT probe programs to fixture
  files", intent: byte-identical move from escaped builders in release_uat.w).

## Findings
1. (INFO, T22, probe P1) Syntax/spec: `fn main:` with bare `return 1` exits,
   `print` for diagnostics, `write("sqlite3 UAT passed\n")` for the pass
   marker. Identical shape to all five sibling C-package fixtures
   (zlib/bzip2/openssl/libcurl). Expected stdout "sqlite3 UAT passed"
   matches line 38 modulo trailing newline, same convention as siblings.
   No deviation. Probe: P1 PASS.
2. (INFO, T13, manual trace) Ownership/drop: `db`/`stmt` are raw C pointers,
   no With owned values, no drop glue needed. Lifecycle order correct on all
   paths: exec-fail closes db (stmt still null); prep-fail closes db with
   stmt NULL per sqlite3_prepare_v2 contract (output set to NULL on error);
   step-fail finalizes stmt then closes db; success copies `value` out (line
   31) before finalize+close (lines 32-33). No double-finalize, no
   use-after-free, no close-with-unfinalized-statement (avoids SQLITE_BUSY).
   No defect. Probe: manual trace, no compiler probe applicable.
3. (REFUTED, T15/T22, probes P2/P4) Standalone `check` reports 7x undefined
   variable (c-package symbols without `with get c.sqlite3`) -- refuted:
   caller release_uat.w:303-331 always runs `with get c.sqlite3` before
   build, so standalone resolution is not the supported configuration;
   in-repo caller intent (7b39ff0f: byte-identical extraction) confirms
   content. Not a defect.
4. (REFUTED, T22, probes P2/P3) Standalone `check` `write`-import error --
   refuted by negative control: all sibling fixtures produce the identical
   error standalone; the real flow builds inside a `with init` project that
   provides the prelude. Not a defect.
5. (INFO, T15) Migration fidelity: landed-commit intent (7b39ff0f message)
   is byte-identical move; fixture content is self-consistent with caller
   expectation (pass string, package id c.sqlite3). No contrary evidence.
   Coverage file check: build/release_uat.w exists and references this exact
   fixture path at line 341.

## Negative controls
- zlib_main.w / bzip2_main.w standalone `check`: same `write`-import error,
  zero undefined-variable errors (their symbols resolve from system headers
  in this env; sqlite3's 7 do not without the package -- environment
  artifact, refuted per F3).

Verdict: COMPLETE
