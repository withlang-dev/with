# Audit: build/release_uat_fixtures/libcurl_main.w @ 450733e5 — COMPLETE

Module: `build/release_uat_fixtures/libcurl_main.w` (36 lines, read completely)
— release UAT probe main for the `c.libcurl` package: global init, easy
init, NOSIGNAL setopt, version-info null checks, balanced cleanup on every
path, prints `libcurl UAT passed`. Sole in-repo caller:
`build/release_uat.w:347` (`run_release_libcurl_uat_action` via
`ruat_run_c_package_uat(ctx, "c.libcurl", "libcurl",
"build/release_uat_fixtures/libcurl_main.w", "libcurl UAT passed")`, lines
303-332: reads fixture text, `with init` a fresh project, `with get
c.libcurl`, overwrites `src/main.w` with fixture, `with run` must print the
expected stdout exactly). Landed byte-identical from the old inline builder
by `7b39ff0f` ("Move release UAT probe programs to fixture files"). No other
callers (`build/` grep: only the fixture + `release_uat.w`).

## Targets traced
- T13 ownership/drop: every early-return path balances `curl_easy_cleanup`
  + `curl_global_cleanup`. `init_rc != CURLE_OK` (line 5) returns with
  nothing allocated (correct, no cleanup owed); `easy == null` (line 10)
  cleans globals only (line 12); `opt_rc` fail (line 16) cleans easy + global
  (lines 18-19); `info == null` (line 23) cleans both (lines 25-26);
  `info.version == null` (line 28) cleans both (lines 30-31); success path
  cleans both (lines 34-35). No live-handle drop, no double free. Clean.
- T15 migration fidelity: N/A. Fixture is a hand-written `.w` probe, not
  migrated C output; landing commit states content is byte-identical to what
  the old builder produced, and no `migrate` gate touches it (migrate gate
  is `release_uat.w:280-299` on `tiny.c` only). Nothing to fidelity-check.
  Clean by non-applicability.
- T22 spec conformance: `use c_import("curl/curl.h")` (line 1), `fn main:`
  colon form, `let`/`if`/`return`, `unsafe {}` scoping, `null`, `as c_long`,
  `print`/`write` all match the 4 sibling fixtures (`zlib/bzip2/sqlite3/
  openssl_main.w`) and the `ruat_run_c_package_uat` contract (expected
  stdout `libcurl UAT passed` == line 36 literal). Bare (non-`unsafe`)
  `curl_global_init` (line 4) / `curl_global_cleanup` (lines 12,19,26,31,35)
  vs `unsafe`-wrapped `curl_easy_*` is principled, not a defect: only the
  pointer-touching calls are wrapped, matching the `getpid()`-without-
  `unsafe` precedent at `lib/std/os.w:68` (c_import'd plain-int call in safe
  code); all-pointer siblings wrap everything. `write` resolves via the
  ambient `use std.builtins` prelude (`lib/std/builtins.w:36`,
  `lib/std/prelude.w:4`) in real project builds. Clean.

## Probes run (seed out/bootstrap/bin/with-stage1)
- P1 `check build/release_uat_fixtures/libcurl_main.w` → `error: type
  mismatch in binding` (x2, span 37:1) + `'write' requires an explicit
  import (§18.1)` (line 36), rc=1. NOT a fixture defect — see N1/N2.
- P2 `check .../zlib_main.w` → identical `write`-import error only, rc=1.
  Proves the `write` error is systemic seed-vs-release drift (seed bare-file
  check lacks the project prelude), shared by all 5 fixtures.
- P3 `check .../sqlite3_main.w` → large-Copy warnings + `undefined
  variable` x7 + `write`-import error, rc=1; P4 `check .../openssl_main.w`
  → `panic: invalid free` ICE, rc=1. Seed stage1 fails on every sibling
  fixture, each differently — the UAT runs against the freshly built release
  compiler, not the seed. Refutes P1 as evidence of fixture defect.
- P5 code-read: `lib/std/os.w:68` bare-`getpid()` precedent refutes the
  unsafe-scoping hypothesis; `7b39ff0f` byte-identical landing statement
  refutes content-drift hypotheses; `build/release_uat.w:303-332` gate
  reading confirms the stdout contract.

## Negative controls
- N1 `write`-import error reproduced on all 5 fixtures under seed bare
  `check`, but every fixture runs as `src/main.w` inside a `with init`
  project where the `std.builtins` prelude provides `write`/`print`
  (`lib/std/builtins.w:36`, `lib/std/prelude.w:4`). Refuted as defect.
- N2 P1 `type mismatch in binding` has no in-repo caller contradiction:
  the only caller passes the fixture through opaquely as text
  (`release_uat.w:308,325`); sibling sqlite3 shows the same class of
  seed-only binding errors while openssl ICEs. Seed diagnostic, not
  actionable without the release compiler. Refuted as defect.
- N3 `test/internals/conan_recipe_link_metadata_test.w:5,11,14` mentions
  "libcurl" only as conan-recipe string data — not coverage of this
  fixture. Coverage is the build-graph UAT gate itself
  (`build/release_uat.w:346-347`); no test-file coverage claimed beyond
  that. Fixture file exists in tree (36 lines, listed).

## Findings
(none — all candidate defects refuted above; T13/T15/T22 clean.)

Verdict: COMPLETE
