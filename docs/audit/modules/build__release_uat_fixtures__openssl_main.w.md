# Audit: build/release_uat_fixtures/openssl_main.w @ 450733e5

Module: `build/release_uat_fixtures/openssl_main.w` (42 lines, read completely)
Commit: 450733e5 (fixture moved from inline source in 7b39ff0f "Move release UAT probe programs to fixture files")
Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance

## Caller contract (verified, file exists)
- In-repo caller: `build/release_uat.w:343-344` `run_release_openssl_uat_action` ->
  `ruat_run_c_package_uat(ctx, "c.openssl", "openssl",
  "build/release_uat_fixtures/openssl_main.w", "openssl UAT passed")` (`build/release_uat.w:303-344`).
- Fixture file exists (read in full, 42 lines). Expected stdout `"openssl UAT passed"`
  matches fixture line 42 `write("openssl UAT passed\n")` — same `print`-on-error /
  `write`-on-pass convention as siblings `zlib_main.w`, `sqlite3_main.w`.
- Runner path (`ruat_run_c_package_uat`, `build/release_uat.w:303-332`): `init` project +
  `get c.openssl` + write `src/main.w` + `run`. Standalone `check` (no project, no
  c package) is out-of-contract usage; see probe P2.

## Findings
None standing. Verdict: COMPLETE.

1. (T13 ownership/drop — PASS) `EVP_MD_CTX_new` handle `ctx` (line 8) is null-checked
   (line 9) and `EVP_MD_CTX_free(ctx)` is called on every early-return error path
   (lines 16, 21, 25, 29) and on the success path (line 31). No double-free (each
   path returns immediately after freeing). `digest`/`digest_len` are stack locals;
   no owned value is dropped or leaked in-fixture. Refutation: searched in-repo
   callers — the only caller is the UAT runner above, which does not take ownership
   of fixture internals; no caller contradicts this. Probe: code-read (no runtime
   allocation to observe in a fixture-only audit).
2. (T15 migration fidelity — N/A, PASS) Fixture is a hand-written UAT probe, not
   migrated C: no `migrate` markers, no translated-cache idioms. Landed-commit
   intent (7b39ff0f) was a pure move of probe programs to fixture files. Nothing to
   fidelity-check. Refutation: no caller or commit message claims migrated provenance.
3. (T22 spec conformance — PASS) Digest vectors verified independently:
   `python3 hashlib.sha256(b"abc")` = `ba7816bf...f20015ad`; fixture checks prefix
   `ba 78 16 bf` (line 36) and suffix `f2 00 15 ad` (line 39) plus `digest_len == 32`
   (line 33) — all correct. Idioms match siblings and spec: `use c_import("openssl/evp.h")`
   (line 1), `unsafe { }` FFI blocks, `&raw mut`/`as *mut` pointer forms
   (line 27), `input as *const c_void` / `input.len() as c_ulong` (line 23, cf.
   `input as *const Bytef` in `zlib_main.w:18`). `or` in `if` conditions
   (lines 36, 39) parses — `ast` probe succeeds (P3). Refutation: constants
   cross-checked against hashlib, not copied from the fixture.
4. (Observation, NOT a fixture defect — refuted) Standalone
   `with-stage1 check build/release_uat_fixtures/openssl_main.w` panics
   deterministically (2/2): `panic: invalid free: pointer is not an allocated
   payload start` (P2). Negative controls: `check zlib_main.w` yields a clean
   diagnostic (`'write' requires an explicit import (§18.1)`, exit ok), and
   `check sqlite3_main.w` yields only a `copy_warn_threshold` warning — neither
   panics. So the panic is specific to this file under standalone check, but it
   does NOT survive refutation as a fixture defect: (a) standalone `check` is
   out-of-contract — the real caller runs the fixture as `src/main.w` inside an
   `init`+`get c.openssl` project where the prelude (`write`) and C package exist
   (standalone zlib fails the same way on the missing prelude); (b) `tokens` and
   `ast` probes on this file succeed, so the source lexes/parses; the crash is in
   standalone-check analysis, likely a stage1 bug worth a separate compiler note,
   not evidence the fixture is wrong. No issue filed per instructions.

## Probes run
- P1 `with-stage1 tokens build/release_uat_fixtures/openssl_main.w` — PASS (lexes; `use`/`c_import`/`fn`/`let` tokens OK).
- P2 `with-stage1 check build/release_uat_fixtures/openssl_main.w` — PANIC (deterministic, 2/2, varying addr): `invalid free ... panic: invalid free: pointer is not an allocated payload start`. Out-of-contract usage; see finding 4.
- P3 `with-stage1 ast build/release_uat_fixtures/openssl_main.w` — PASS (expands `fn main`, `[32]u8` digest init, `unsafe` exprs).
- P4 Negative controls: `check zlib_main.w` → clean §18.1 `write`-import diagnostic; `check sqlite3_main.w` → clean `sqlite3_io_methods` copy warning. Neither panics.
- P5 `python3 -c hashlib.sha256(b"abc")` → `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad` — confirms lines 36/39 vectors.
- P6 Caller/coverage check: `release_uat.w:343-344` references this exact fixture path with matching expected stdout; sibling fixtures (`zlib_main.w` 37 lines, `sqlite3_main.w` 39 lines) confirm the pass-signal convention. Not run: full `run` UAT (requires `get c.openssl` network fetch + build; out of scope for a read-only fixture audit).

## Negative controls
- Standalone `check` on siblings does not panic (see P4) — panic is file-specific to standalone analysis, not a general harness failure.
- Standalone `check` fails even healthy siblings (zlib §18.1 error) — standalone mode lacks project prelude/packages, so it cannot convict a fixture.

Verdict: COMPLETE
