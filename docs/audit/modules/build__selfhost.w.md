# Audit: build/selfhost.w @ 450733e5

Scope: read-only source audit of `build/selfhost.w` (8072 lines, 223 fns) at commit 450733e5.
Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).
Compiler: out/bootstrap/bin/with-stage1 (seed compiler).

## Module summary
Build-graph action library (`module build.selfhost`; uses `build.compiler`,
`pcre2`, `std.build`, `std.process`, `std.sysinfo`, `std.crypto.sha256`).
Provides the CLI-selfhost / LSP / fmt / one-liner / project / edge / parallel /
object-symbol / build-w / pcre2-prep / migrate-basic / migrate-core / bundle-interface /
embedded-runtime-regression / emit-c-smoke test actions, plus `bs_*` helpers
(path join/abs/capture, owned-string, C-compiler select, host/cross triple,
run-capture variants with env/cwd/stdin, trim/assert helpers, LSP frame builders,
fixture writers). All 15 `pub fn run_*_action` entry points are wired in build.w
(smoke:2424, one-liner:2431, fmt:2438, object-symbol:2445, build-w:2473,
project:2480, lsp:2488, edge:2494, parallel:2500, pcre2-prep:2506,
migrate-basic:2512, migrate-core:2518, bundle-interface:2455,
embedded-runtime-regression:2556, emit-c-smoke:2562); each resolves to exactly
one definition, all in build/selfhost.w.

## Target disposition
- T13 ownership/drop: CONFORMANT. `selfhost_owned_text(s): s ++ ""` (selfhost.w:9)
  is the house idiom (same as build/abi.w, build/sdk.w, build/retention.w, ...).
  Borrowed `&str`/`&Vec[str]`/`&ProcessEnv` inputs are deep-copied to owned
  argv/env clones at every spawn site (e.g. 164-168, 183, 199-201);
  `SelfhostRunResult { result.rc, move result.stdout, move result.stderr }`
  moves captures out (150, 172, 187, 207, 235). Bounded `.get(i)` loops,
  `inputs.get(0)` guarded by `len() == 0 -> bs_fail` at each action head
  (239-240, 753, 982, 1032, 1082 pattern). No `extern` FFI, no manual memory
  ops in module logic (`extern fn` hits at 1551-1621 are With fixture *source
  text* inside string literals, not module declarations); drop glue
  compiler-owned.
- T15 migration fidelity: CONFORMANT, no fork. File originates in c416b0c8
  (`Prepare static LLVM release build`); recent commits touch it in place.
  No duplicated action logic remains in build.w (build.w holds only target
  wiring + `.action =` assignments). Sibling actions live in their own modules
  exactly once (fixpoint-evidence: retention.w:630, pcre2-migrate: pcre2.w:650,
  with-compiler-build: compiler.w:1747, emit-c-fixpoint: emit_c.w:874,
  release-migrate-uat: release_uat.w:264). `bs_*` helper names are unique
  across build/*.w (duplicate-definition scan empty).
- T22 spec conformance: CONFORMANT (no formal spec doc governs the harness;
  judged against fail-closed battery intent + landed-commit gates). Every
  fallible step returns `bs_fail` (rc 1 + diagnostic): missing inputs/output
  dir (239-248), copy/chmod/mkdir failures (258-261), spawn rc 124 timeout vs
  nonzero distinguished (283-286, 293-296), stdout mismatch (297-299).
  Windows-skip gates (bs_windows_skip:25-32, embedded-regression:249-252)
  stamp the output dir `ok` and print the issue number — landed intent per the
  #809/#811 comments, not silent passes.

## Findings
No defects. (Numbered candidates below; each died in refutation.)
1. Candidate (T13, minor): `let _restore_out_dir = set_env(...)` (282) ignores
   restore failure, leaving WITH_OUT_DIR pointed at a removed dir for later
   actions in-process — refuted: only the `set_env` syscall itself failing
   triggers it (no repo caller observes this; `env()++""` read-back at 278
   preserves the prior value on the success path). Not filed.
2. Candidate (T22, minor): `SelfhostRunResult { 1, "", ... }` positional init
   (197) vs named inits elsewhere — refuted: field order matches the type
   decl (11-15); seed check of leaf modules ok, graph evaluation clean (P3).
   Not filed.
3. Candidate (T22): `with-stage1 check build/selfhost.w` fails with
   `import module not found: 'build.compiler'` — refuted, not a module
   defect: identical failure for build/sdk.w (also `use build.compiler`),
   while build/compiler.w itself checks `ok`; i.e. a `check`-subcommand
   multi-`use build.*` resolution limitation. Real-path resolution succeeds
   (P3). Not filed.

## Probes run (seed out/bootstrap/bin/with-stage1, linux-x86_64)
- P1 (control) `with-stage1 check build/abi.w` -> `ok`.
- P2 `with-stage1 check build/compiler.w` -> `ok`; `check build/sdk.w` ->
  same `build.compiler` resolution error as selfhost.w (negative control
  showing the failure is in the `check` driver, not this module).
- P3 `with-stage1 build --list` -> exit 0; full build.w graph evaluation
  (which `use`s build.selfhost -> build.compiler + pcre2) succeeds with no
  error lines — positive control for real-path module resolution/typecheck.
- Definition-uniqueness scans: 12/12 build.w-wired cli_selfhost/migrate
  actions defs=1; `bs_*` duplicate scan empty; 3 extra entry points confirmed
  wired (build.w:2455,2556,2562).
- No test-file coverage is claimed (harness module; covered by the battery
  targets it implements). Repo sources untouched (`git status` shows only
  pre-existing untracked dirs `.codex/ docs/issues/ docs/specs/
  docs/superpowers/`; no modifications).

Verdict: COMPLETE
