# Primary verification — `lib/std/re/pcre2test.w`

Status: **INCOMPLETE** — harness typechecks but does not link or run
standalone on Linux (blocker below; no issue filed per task instructions)
Primary verifier: primary (structure characterization + attempted execution)
Source revision: `450733e5`
Source examined: structurally (25,739 lines; NOT read fully — see map below)

## Scope examined (structure map, line ranges observed)

Upstream `pcre2test` CLI driver port: helpers `print_char_8` (`:19`),
`get_ucpname_8` (`:153`); `valid_utf` (`:2818`, only `pub` helper besides
`main`); `process_command_8` (`:8726`), `process_pattern_8` (`:9382`),
`process_data_8` (`:13537`), `unittest_8` (`:18599–~22993`, ~4.4k lines,
130 inline failure-message sites, no external corpus); 8-bit aliases
(`:22993–23090`); `usage` (`:23105`), `display_properties` (`:23557`),
`pub unsafe fn main(argc, argv)` (`:23965`, stdin/file-driven like upstream).
Embeds NO pattern corpus: reads patterns/data from stdin or input files at
runtime (`infile = __stdinp` at `:25074`, `fopen` at `:25088`). Reference
corpus = upstream `RunTest`/testdata, not vendored (no `RunTest` in repo;
`build/pcre2.w:744` `run_pcre2_test_smoke_action` needs external inputs).

## Behavioral matrix (EXECUTED, with exact output)

- `with-stage1 check lib/std/re/pcre2test.w` → exit 0 (warnings only). PASS.
- `with-stage1 build lib/std/re/pcre2test.w -o …/pcre2test` → link FAILED:
  `ld.lld: error: undefined symbol: __stderrp`, `__stdoutp`, `__stdinp`
  (`collect2: error: ld returned 1 exit status`, `error: build failed`).
  Root cause observed: these globals exist only in `rt/darwin_aarch64.w:96`
  (declared `extern` in `lib/std/libc.w:13-15` as Darwin-platform); no Linux
  definition. FAIL (platform blocker, not a source bug).
- `docs/audit/probes/re_harness/probe_valid_utf.w` (driver for pub `valid_utf`)
  → same link failure via `extend_inputline`/`c_option`/`display_properties`
  refs to `__stdoutp`. FAIL (same blocker).
- Repo tests unrunnable under seed (stale, pre-existing): `test/pcre2_smoke.w`
  and `test/pcre2_verify.w` fail with `unsafe function call requires unsafe
  context` (`:118–119`, `:142–143`); `test/pcre2_sanity_check.w` fails with
  `` `&mut` is not part of safe With (§15.1) `` (`:20`). All three: `run failed`.
- `-unittest` internal suite (130 assertion sites) and upstream `RunTest`
  corpus: NOT RUN (blocked at link; corpus not vendored).

## Findings (recorded, NOT filed)

1. (Blocker) `pcre2test` harness unlinkable standalone on Linux at this
   commit: needs `__stdinp/__stdoutp/__stderrp` shims or a Darwin host.
   Execution evidence above; `check`-clean so the port itself typechecks.
2. (Stale tests) `test/pcre2_smoke.w`, `test/pcre2_verify.w`,
   `test/pcre2_sanity_check.w` predate current `unsafe`/`&raw mut` rules and
   do not compile under the seed. The live equivalent is the build-system
   `workspace.compile()` path (`build/pcre2.w:767`), not standalone `run`.

Verdict: INCOMPLETE (link-blocked on Linux; source-checked only)
