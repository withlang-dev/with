# Audit — `build/zlib_gzip.w`

Status: **INCOMPLETE** (one error-severity finding survives refutation)
Source revision: `450733e5` (module predates it; `git log -- build/zlib_gzip.w` last touches `f92a299e`, `ae6b7e78`)
Source SHA-256: `8b55e92e0ff3af6a438d26a3cfa2f2c0c26062e430fb3281c0928344c2dd6215`
Lines examined: 1–38 (full module, single read)

Applicable targets: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).

## Verdict: INCOMPLETE — F1 (error) survives refutation; module does not compile as a program

## Findings

### F1 — build/zlib_gzip.w:5 — error — T13 — probe: executed (seed `check` + `build`) — SURVIVES refutation
The module declares its own extern with the wrong parameter type:

```w
extern fn with_str_from_vec_u8(bytes: *const Vec[u8]) -> str   // build/zlib_gzip.w:5
```

The canonical signature everywhere else in the repo takes a raw byte pointer:

- `lib/std/string.w:28`: `extern fn with_str_from_vec_u8(bytes: *const u8) -> str`
- `rt/rt_core.w:2313`: `pub fn with_str_from_vec_u8(v: *const u8) -> str`
- `runtime/with_runtime.h:31`: `with_str with_str_from_vec_u8(const void *bytes);`

The module-local declaration shadows/overloads the runtime symbol for the
whole program, so the embedded-std use at `<embedded-std>/std/string.w:80`
(`with_str_from_vec_u8((&raw const self.bytes) as *const u8)`) fails
unification:

```text
error: wrong argument type in call to 'with_str_from_vec_u8'
 --> <embedded-std>/std/string.w:80:30
  = note: argument 1 expects *const Vec[u8]
  = note: actual type: *const u8
```

Observed: `out/bootstrap/bin/with-stage1 check build/zlib_gzip.w` → rc=1
(`error: check failed during compilation`); `out/bootstrap/bin/with-stage1
build build/zlib_gzip.w -o /tmp/zlib_gzip_probe` → rc=1 (`error: build
failed`), no binary produced.
Refutation attempt (callers + intent): the sole live consumer compiles this
file exactly as a standalone program — `pkg_compile_gzip_helper`
(`build/package.w:411-431`: `compiler build build/zlib_gzip.w -o <helper>`),
reached via `pkg_write_archive` (`build/package.w:452-482`) from
`run_package_bootstrap_c_action`, wired as the live `package-bootstrap-c`
target with an explicit `build/zlib_gzip.w` input edge
(`build.w:1551-1581`, esp. `build.w:1577`). The failure is a frontend type
error, independent of which compiler runs the lane, and the repo's own
`lib/std/string.w:28` agrees with the runtime header, so no compiler
resolves it differently. `check build.w` → `ok` (rc=0) does NOT refute:
there the path appears only as an input-edge string, never as a compilation
unit, so the poisoned extern never unifies. Landed-commit intent does not
refute either: `450733e5` (regex-runtime pcre2-bundle shim) does not touch
this module, so there is no intent drift to reconcile — the defect predates
it. Fix direction (not applied; read-only audit): declare
`extern fn with_str_from_vec_u8(bytes: *const u8) -> str` and call it as
`with_str_from_vec_u8(data.ptr as *const u8)`, matching sibling idiom
(`build/zlib_gunzip.w:20`, `lib/std/zlib.w:34-35`). No issue filed per
instructions.

### F2 — build/zlib_gzip.w:24 — info — T22 — probe: static (read) — refuted as defect
`if input.len() == 0: print("could not read input tar"); return 1`
conflates a missing/unreadable tar with a 0-byte tar (same shape as sibling
`build/zlib_gunzip.w:114`, audit F4). Refutation: a 0-byte input is never a
valid tar, the arm still fails closed with rc=1, and the caller
(`pkg_run_gzip_helper`, `build/package.w:446-449`) gates on `rc != 0` plus
output existence, so no success path is reachable. Cosmetic only. No issue
filed per instructions.

### F3 — build/zlib_gzip.w:5,15-16,30 — info — T13/T22 — probe: static + blocked live probe — held, not this module's defect alone
Binary gzip bytes cross the `Vec[u8] <-> str` boundary through a hand-rolled
raw extern (`bytes_from_str` byte loop; `bytes_to_str` via `unsafe`
`with_str_from_vec_u8`) instead of a safe facade, and the `write_file` error
arm (`build/zlib_gzip.w:30-32`) reports only `"could not write gzip output"`.
Refutation as defect: With `str` is length-delimited so embedded NULs in
gzip output survive the round trip by construction (same loop the gunzip
sibling uses at `build/zlib_gunzip.w:11-17`); no committed `str`-from-bytes
safe helper exists for programs outside `std.string`'s methods, so the
extern is the only available shape — its *type* is F1, its *existence* is
convention. Live byte-identity round-trip probe not runnable until F1 is
fixed. No issue filed per instructions.

## T13 ownership/drop — blocked by F1
- Standalone `check`/`build` never reach borrow analysis (type error first),
  so move/borrow/drop behavior of `bytes_from_str` / `bytes_to_str` /
  `write_file(argv.get(2), bytes_to_str(&gzip_bytes))` (where the temporary
  `str` borrows the match-arm-local `gzip_bytes`) is unverified by the
  compiler here. Read-only inspection: `&Vec[u8]` borrows outlive the call in
  every use; no manual free/retain/drop in the module. Package-root
  `check build.w` (`ok`) does not cover this program unit (see F1).

## T15 migration fidelity — clean (consumer-only; module is hand-written, not migrated)
- Uses the migrated implementation directly: `compress_gzip(&input_bytes)`
  (`lib/std/zlib.w:63-64`, default level via `compress_gzip_level`,
  `deflateInit2_` with `MAX_WBITS + 16` gzip wrapper, vendored 1.3.2) —
  exactly the handoff expectation (`docs/completed/zlib-handoff.md:39`,
  helpers backed by the migrated implementation; recon row at
  `docs/specs/std-zlib/recon.md:39`).
- `Err(err) => print(err.message)` propagates the structured facade error
  (`ZlibError.message`, `lib/std/zlib.w:13-32`) to the caller's captured
  stdout/stderr on rc=1.

## T22 spec conformance — clean except F1 blocks the whole contract
- CLI contract matches the caller: `argv.len() < 3` → usage + rc=2;
  read/compress/write failures print a message and return 1, which
  `pkg_run_gzip_helper` (`build/package.w:446-449`) turns into a lane
  failure via its rc check plus output-existence check.
- No test file covers this binary: `grep -rn 'zlib_gzip|compress_gzip'
  test/ tests/` hits only the facade-level `test/behavior/behav_zlib_std.w`
  (exists, 88 lines; exercises `compress_gzip`/`decompress_gzip` in memory,
  never the helper binary or its CLI/rc contract). Coverage of the helper
  itself rests on no committed test.

## Probes run
1. `out/bootstrap/bin/with-stage1 check build/zlib_gzip.w` → rc=1,
   `error: wrong argument type in call to 'with_str_from_vec_u8'` at
   `<embedded-std>/std/string.w:80` (expects `*const Vec[u8]`). FAIL (F1).
2. `out/bootstrap/bin/with-stage1 build build/zlib_gzip.w -o
   /tmp/zlib_gzip_probe` → rc=1, `error: build failed`, no binary. FAIL (F1).
3. `out/bootstrap/bin/with-stage1 check build.w` → `ok`, rc=0 (package root;
   module present only as input-edge string `build.w:1577`). PASS — does not
   exercise F1 (see refutation).
4. Caller search (`muse.search`, literal `zlib_gzip`): sole live consumer is
   `build/package.w:411-450` (`pkg_compile_gzip_helper` /
   `pkg_run_gzip_helper`), reached via `pkg_write_archive` → release action;
   `build.w:1577` input edge; docs references are prose-only
   (`docs/wo_bundles.md:167`, `docs/completed/zlib-handoff.md:39,252`,
   `docs/specs/std-zlib/recon.md:39`).
5. Signature search (`with_str_from_vec_u8`): canonical `*const u8` at
   `lib/std/string.w:28`, `rt/rt_core.w:2313`,
   `runtime/with_runtime.h:31`; only `build/zlib_gzip.w:5` declares
   `*const Vec[u8]`.

## Negative controls
- N1: `check`/`build` of sibling `build/zlib_gunzip.w` in the same env →
  rc=0 and a 483,832-byte working binary (`/tmp/zlib_gunzip_probe`) — proves
  the F1 failure is specific to gzip's line-5 declaration, not a broken
  toolchain or environment.
- N2: `test/` + `tests/` grep for `zlib_gzip|compress_gzip` returns only
  facade tests in the existing `test/behavior/behav_zlib_std.w` (verified
  present, 88 lines) — proves the no-helper-coverage claim is a verified
  absence, not an unchecked assertion.
- N3: `git log -- build/zlib_gzip.w` shows last touches `f92a299e`,
  `ae6b7e78`; `git show 450733e5 --stat` touches only `build.w` +
  `src/main.w` — proves the defect predates the pinned commit and no
  landed-commit intent reconciles it.

Verdict: INCOMPLETE
