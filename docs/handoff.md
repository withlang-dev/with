# Handoff: coordinator status (2026-10-01, active continuation)

## Current continuation checkpoint

This checkpoint supersedes the September 30 14:00 snapshot below. Work remains in progress;
neither draft PR is ready and no final battery has run.

- The Linux branch is pushed through `19a8157e`. The ARM SDK is published at
  `nightly-sdk-20260930-e997223d40ce` and pinned on that branch. The new ARM
  compiler cross-links and launches, but its full native verification and new
  seed publication remain pending. The old ARM seed's libxml compatibility
  provisions must stay until the replacement is verified and pinned.
- Current permissions make `~/.local/with-staging/linux-own-sdk` read-only and
  block SSH and the Docker socket. Work continues in the writable checkout
  `/private/tmp/with-linux-sdk-resume`, cloned at `19a8157e`, now committed
  as Eric at **`fc66110eff23b0f98ac290ac95cc49318feddc72`** (`WIP:`).
  This commit is newer than the dirty copies in the original staging tree.
  Do not discard either checkout or mistake the original staging edits for
  the latest patch. Main's unrelated dirty files remain untouched.
- Push of `fc66110e` failed: the sandbox cannot resolve `github.com`.
  Connected GitHub reads now work and confirm both PRs are still drafts at
  their published heads. Attempts to update both PR descriptions were rejected:
  `MCP tool call requires approval, but approval policy is never`. This is a
  connector-specific rejection; do not treat it as evidence about Eric's
  Git/SSH credentials. After Eric confirmed his `gh` login and registered SSH
  key, the native CLI path was tested directly: `gh api user --silent` cannot
  connect to `api.github.com`, and BOTH actual SSH pushes (parallel-Sema and
  Linux) fail with exit 128, `Could not resolve hostname github.com`, before
  authentication. `gh auth status` reports an invalid token, but API access
  is unavailable, so credentials cannot be validated from this runner; do
  not ask Eric to reauthenticate as a fix for the observed DNS failure.
  Committing works in the writable checkouts. Their explicit `github` remotes
  now use `git@github.com:withlang-dev/with.git`; `origin` still points to the
  original local staging clone. A fresh connector PR-body update also returns
  an error; fetching #1945 confirms its body and published head remain unchanged.
  Do not attempt an escalation or bypass of the enforced restrictions.
  A verified recovery bundle is `out/linux-own-sdk-1944-checkpoint.bundle`
  in the main checkout; it requires published parent `19a8157e`. The patch,
  With verification harnesses and logs are copied to main's
  `out/1944-checkpoint/`. The temporary checkout has no tracked dirty files;
  exclude its untracked `.deps` SDK symlink from commits.
- #1944 has a passing full-workload fix on Mac; native Linux confirmation
  and the broader ownership close-out remain pending. The first fix (`564aa644`) shares immutable text
  across comptime snapshots, but the full Linux evaluator still reached
  63 GB. Native ARM allocator/debugger work then proved a second cause:
  `eval_call`'s borrowed `.len()` path retained `recv_signal`. An early-return
  arm downgraded its cleanup globally; `save_move_state` omitted `drop_kinds`.
  LLDB observed `cancel_scheduled_value_drop_for_local` changing the slot
  from `DK_VALUE` to `DK_STORAGE` at instruction `0x5951fb8`.
- The current patch restores cleanup kinds with branch move state and records
  scope ownership independently of surviving Drop statements. StorageDead
  cannot erase an ownership obligation. Strengthened validation exposed five
  findings, now resolved: constant-switch reachability, raw extern bit-copy
  signature metadata, explicit `move` materialization for an `&T` argument,
  and reset-before-drop ordering for a nested field move.
- Evidence in the writable checkout: `out/compiler-validate1944-round2.txt`
  says `validate-all: ok` for `src/main.w`; the conditional-return and
  borrowed-move behavior fixtures pass with `WITH_DEBUG_ALLOC=1` and
  `WITH_ALLOC_NO_REUSE=1`, leak count zero; validator unit regressions pass
  with leak count zero. The dev build passed in 62.5 seconds. The corrected
  existing D16 debug-allocator fixture now actually takes `&Resource` and
  passes with immediate destructor count 1 and leak count zero.
- Pinned-seed `:stage2` passed (456.9 seconds). Stage2's generation is
  `b84d6849b076b3b280c9808b1b72c7445c1a61b14a3bd94836084a24998a7e0d`.
  The actual 64 KiB comptime reader passes under a **32 MiB allocation cap**,
  and its materialized result passes its runtime assertions.
- The full forced **`linux-sysroot-aarch64` evaluator** passes on Mac under
  a 2 GiB allocation cap: exit 0, no timeout, **138.962 seconds, 712556544
  bytes peak RSS (680 MiB)**, down from the earlier 63 GB run. Logs:
  `out/full-worker1944-verdict.txt`, `out/worker1944.stderr`.
  The scratch With harness is `out/run1944-worker.w`; use the explicit ARM
  target, because the default `linux-sysroot` on Mac produces an empty pack.
- The generated ARM leaf pack is 9970096 bytes, SHA-256
  `e8d4b0eca8b74c81cff214c5b1eefd2c9a1a799a5b3273864b7a26d83e6da30c`.
  All 1534 entries exist in the native ARM compiler's embedded reference.
  Headers and other data match byte-for-byte. Eleven ELF files differ only
  in their non-loadable `.comment` SDK-producer Git hash: removing that
  section **in comparison copies only** makes all eleven byte-identical.
  Do not require literal equality to the old native leaf pack hash: SDK
  producer metadata differs, and the embedded reference also carries later
  compiler-rt/libc++ entries. No production pack was modified. Evidence:
  `out/sysroot1944-pack-comparison.txt`, `out/sysroot1944-elf-comparison.txt`.
- Stage2/stage3 are byte-identical over all 16 units. The full pinned-seed
  `:fixpoint` target finally passed; `out/fixpoint-1944-final-store.txt`
  records exit-zero completion (25.5 seconds with existing outputs).
  Two earlier attempts passed byte comparison but failed later on an
  absolute `.wo` install path. Use **`WITH_WO_DIR=out/cache/wo`**, not an
  absolute path; the current graph and install targets use that relative
  store and pass. Keep caches inside this writable checkout:
  `WITH_BUILD_RUNNER_DIR=$PWD/out/cache/build-runners`,
  `WITH_TEST_VERDICT_DIR=$PWD/out/cache/test-verdicts`,
  `XDG_CACHE_HOME=$PWD/out/cache`, and the driver `WITH=$PWD/src/main`.
- Stage2's standalone drop audit passes **254/254 cells, zero regressions**
  against the pinned seed (`out/drop-audit-1944-stage2.txt`). The required
  seed-driven **`:deep-debug-tool-tests --no-deps` and `:drop-audit --no-deps`
  also pass** (9.3 and 13.3 seconds). The release candidate's audit has
  254/254 PASS, zero regressions: `out/drop-audit/audit.stdout`.
  Logs: `out/deep-debug-tools-1944.txt`, `out/drop-audit-1944-seed.txt`.
- **A semantic question is pending with Eric.** The nested-tail fixture
  returns correct text with no double free, but its containing custom Drop
  is skipped when moving its only string field leaves all-zero storage.
  `behav_1944_nested_tail_move_cleanup.w` deliberately remains red on its
  destructor-count assertion. Eric was asked whether to preserve that
  destructor (§2.5.1) or treat the all-zero containing value as disarmed
  (D72's storage sentinel). Do not change the assertion to go green or
  change the liveness layout without settling that conflict. The identified
  codegen branch is `mir_emit_guarded_user_drop` in `src/CodegenDispatch.w`:
  the `rt_value_is_zero` guard skips the containing user Drop. Sema's
  `struct_decl_needs_liveness_byte` excludes its string owning field from
  the hidden-byte cases. Local LLDB launch is blocked by this sandbox;
  the native LLDB cleanup-kind proof above predates that restriction.
- The resumed pinned-seed `:gate` ran all available fixed checks successfully,
  including self-check, examples, benchmarks and the C migrator. The overall
  gate remains RED because `no-host-toolchain-tests` cannot enter its nested
  sandbox: `sandbox_apply: Operation not permitted` (exit 5). Log:
  `out/gate-1944-resume.txt` in the writable Linux checkout. Do not weaken or
  disable that check to make the gate green.
- Next for Linux: settle that destructor ruling without weakening the fixture, then
  finish native Linux/ARM verification, cut and verify the ARM seed, retain
  compatibility until it is pinned, and run the layer gates and one battery
  on the final stack. Native access and GitHub push still need a session
  whose permissions allow SSH/Docker and network access; this session's
  approval policy is `never`, so do not attempt an escalation or bypass.
- The earlier Docker verification container `with-linux-sdk-verify` remains
  running with its idle command; the current sandbox cannot stop it. No
  Linux compiler worker was left running when access became unavailable.
  All compiler/test processes launched locally for this checkpoint finished.
- Independent parallel-Sema work has resumed while Linux-specific work waits.
  The writable checkout is `/private/tmp/with-parallel-sema-resume`, cloned
  from published `72951be0`; original staging remains untouched. All eight
  discrepancies are reproduced under `out/order-baseline/`.
  `analyze select:kind=diagnostic` silently returned no rows because Frontend
  moved `Sema.diags` into `Zcu.diagnostics` while Analysis still read Sema's
  empty list. The repaired collector reads the current owner; its new
  failing-first behavior regression passes. Populated diagnostic records prove
  user AST nodes (file 0) were rendered with the last body's file 7 (`std.option`).
  Node-owned spans fix the five existing diagnostic-file differences. A new
  cross-module yield/pull regression exposed a second renderer defect:
  `Zcu.render_diag_frontend_with` excluded root file 0 from cross-file labels.
  That correction and the tool/span fixes are committed as Eric in
  **`ff04f4ad`**. Both new behavior regressions pass under the fresh stage1;
  all five original diagnostic-file cases are byte-identical in both orders.
  The cross-module label now renders `src/main.w@3:17`, with the primary at
  `src/producer.w:3:5`. A verified recovery bundle is
  `out/parallel-sema-diagnostics-checkpoint.bundle` in the main checkout,
  requiring published parent `72951be0`.
  Raw-pointer validity propagation is now committed as Eric in **`2c1159a4`**:
  the shared effect
  transfer carries validity requirements, wrapper contracts are checked after
  the fixpoint, and explanations now show the internal bit and provenance.
  Direct, multi-hop and borrowed-pointer tests pass; the final expanded
  regression also covers pointer aliases and matching final effect records.
  The expanded regression fails on the previous compiler and passes on the
  fresh stage1, whose self-check and unchanged ZIP behavior also pass. The
  transitive validity graph proved private ZIP handle helpers require unsafe
  contracts; validated archive methods contain those internal calls. No
  public API or fixture was weakened. A verified recovery bundle is
  `out/parallel-sema-s2a-checkpoint.bundle`, requiring `72951be0`.
  The closure fix is committed as **`882f7b30`**. Inspector facts retain capture
  types after scope exit. They prove reverse checking marks the `spawn_os`
  closure non-escaping despite final effects 12 and `r: &i32` being ephemeral.
  The fix defers direct-argument escape checks until complete effects,
  revokes provisional markers and sorts all post-body diagnostics. Its new
  regression fails before and passes after; the existing callable clone/call
  test and fresh self-check pass. The pinned-seed dev build passes in 354.2 s.
  **`286fc41c`** adds native signature and global-effect inspector records.
  They prove an unsafe generic specialization's generated-name lookup returns
  no declaration while its canonical declaration is unsafe, and that reverse
  dynamic-drop traversal looks for private `Tok` from `std.option` and skips it.
  **`667e55d7`** publishes impl target types from the declaration's module and
  consumes them in the drop graph. Its failing-first regression passes in both
  orders, including a private implementor behind another module's public factory.
  The diagnostic-file regression also passes again under the fresh compiler.
  A verified recovery bundle through `667e55d7` is
  `out/parallel-sema-canonical-facts-checkpoint.bundle`, requiring `72951be0`.
  **`c73ff5e5`** repairs the order checker: it discarded child exit codes and
  compared concatenated stdout/stderr. A native With probe (forward exit 1,
  reverse exit 0, identical output) falsely passed all 1584 before and is
  rejected after. Capture I/O and empty corpora fail loudly. Its six-case
  behavior regression fails before and passes after. The full scan completed:
  **0 of 1584 differences, empty allowlist, 0 runner failures**, recorded in
  `out/sema-order-after-canonical-facts.txt`.
  **`d9d74c93`** fixes generic pointer contracts and effect edges. The
  11-case pointer matrix fails under the saved baseline and passes under the
  candidate, including cached calls, aliases and borrowed pointers. It also
  passes under the normal test timeout after duplicate check/analyze work was
  combined without dropping cases or assertions. **Important runner fact:**
  `with test` overrides `WITH_TEST_COMPILER`; failing-first comparisons must
  run the compiled fixture directly with that environment variable. The valid
  isolated logs are `out/generic-effect-matrix-direct-{before,after}.txt`.
  Disregard `generic-effect-matrix-reduced-work-before.txt`, whose supposed
  baseline run actually used the candidate.
  **`ba3cac94`** fixes imported generic fact paths using Sema's canonical
  declaration, not the caller fallback. The new signature/parameter/
  specialization provenance regression fails before and passes in both orders;
  dev (74.8 s) and fresh self-check pass. **`25275371`** expires downcast name
  markers with their bindings: native instructions prove an unrelated `c`
  received trait-object mutation advice from an earlier match's stale marker.
  Its failing-first regression passes after, across functions and within one
  body, while live downcast help is preserved. **`a209e49c`** adds
  `sema-order-check` to the fixed gate. All these commits are local as Eric.
  **`67467cb6bbc69c1c59373b1257ef1c8286dd14ba`** closes the inventory's
  `global_race_mutated_syms` read.
  The complete four-spelling matrix proves `let` and stable `global` have an
  extra unused-unsafe error in reverse order. LLDB locates the partial-set
  read at `0x10004ff40`/`0x10004ff44`, followed by immediate block judgment.
  The fix retains lexical global-read requirements until mutation facts are
  complete. Its control case exposed a safe generic callee inheriting caller
  unsafe context: the safe `print` specialization's internal `with_println_str`
  call marked the caller's otherwise unused unsafe block necessary. Native
  instructions locate that branch at `0x1002db0ec`/`0x1002db124`; function-body
  entry now saves, clears and restores lexical unsafe context. The seven-case
  regression fails before, fails its unused control under deferral alone, and
  passes under the complete fix. Unsafe generic calls and fresh self-check
  pass; the existing unused-unsafe fixture remains rejected. Both dev builds
  pass. Inventory dispositions are recorded in the branch's `notes.md`.
  The first final drop audit exposed 17 COMPILE-FAIL regressions in the
  collection facades. `explain:effect` proves direct RAW validity seeds at
  `engine_slot.w:21` (`a`) and `hash_index.w:37` (`probe`); both callback
  declarations falsely said safe while their engine callback types already
  require unsafe. Native enforcer instructions at `0x10069cd6c` and
  `0x10069ce14` test canonical unsafe status and RAW bit 5. Commit
  **`1ef49d246adc84a7dd6af4832df9459067b29fa6`** corrects the two library
  contracts, documents the live-slot preconditions and removes redundant
  inner unsafe blocks. No application fixture changed. Both source modules
  check successfully, and the final audit passes every original cell.
  The tracked tree is clean, with `.deps` excluded as a local SDK symlink.
  There are twelve local commits beyond the published draft. Main's verified
  **`out/parallel-sema-review.bundle`** contains head `1ef49d24` and requires
  `72951be0`; `out/parallel-sema-review.patch` is the corresponding source diff.
  Review descriptions are `out/parallel-sema-pr-review.txt` and
  `out/linux-own-sdk-pr-review.txt`. Native proof and test logs are copied into
  `out/parallel-sema-review-evidence/`, including the immutable generic-edge
  baseline compiler with matching SHA-256 verification.
  The final pinned-seed **`:gate` completed in 402.0 seconds**. The stage
  chain, fresh self-check, build.w check, ABI/unit-return/spec checks,
  examples (20 steps), benchmarks (8 programs), C migrator, deep-debug tools
  and user-program safety check all pass. The repaired order checker reports
  **0 differences across 1586 fixtures, empty allowlist, 0 runner failures**.
  The overall gate is RED solely because all four `no-host-toolchain` cases
  are denied by the enclosing sandbox: `sandbox_apply: Operation not
  permitted` (child exit 71). Do not disable that check or start the final
  battery on the red gate. Log: `out/gate-slot-contract-review.txt`.
  Final pinned-seed **`:drop-audit` passes 254/254, zero regressions**
  (13.9 seconds), and **`:fixpoint` passes all 16 units** (9.3 seconds,
  existing comparison outputs), with native debug line/variable checks green.
  Fresh release `audit:resolution` reports **3073637 facts, 130280 MIR calls,
  zero violations**. Logs are `out/drop-audit-slot-contract-review.txt`,
  `out/fixpoint-slot-contract-review.txt` and
  `out/resolution-audit-slot-contract-review.txt`; the full drop table is
  preserved as `out/parallel-sema-review-evidence/drop-audit-slot-contract-table.txt`
  in main. All locally launched build/test processes have finished.
  No final battery has run. GitHub refreshed snapshots still show drafts at
  `72951be0` (#1945) and `19a8157e` (#1935). The Linux branch already has
  `40aaf6f9` as an ancestor; do not infer a needed rebase solely from the
  connector's normalized `mergeable=false` on #1935.
  Next delivery is #1945: run the restricted host-toolchain gate in a session
  that permits it, then the final pinned-seed battery, publish the twelve
  commits and evidence, and mark ready only when green. The S1 overlays,
  S2b worker scratch, S3 parallel waves and S4 threaded-IR performance work
  remain subsequent campaign steps; this layer makes no parallel speed claim.
  Continue every unblocked task; a saved checkpoint is not a reason to stop.

## Historical snapshot (14:00)

You are taking over as coordinator. Read `CLAUDE.md` first; everything below
assumes its rules (seed-driven battery, one stack one battery, fix don't
file, commit as Eric Hartford <eric@quixi.ai> with no AI trailers, never
`git stash`, worktrees in `~/.local/with-staging`). The previous handoff
(modeled-C close-out, 2026-09-28) is kept in `docs/handoff-2026-09-28.md`.

**All agents are stopped.** Both working agents committed their in-progress
work as `WIP:` commits and reported; everything is pushed. Nothing of ours is
running on the Mac or on eric-5090.

## Where main is

- `origin/main` = `40aaf6f9` (#1942). The installed `~/.local/bin/with` is
  that build (`with v0.15.3.0-g40aaf6f90`), installed through the reseed
  gate (`src/main build`, then `out/release/bin/with build :install-user`).
- The pinned seed (`seed.lock`) did not change today on darwin. Windows is
  pinned to the self-contained seed `nightly-20260930-local-2-bd6e00d1dee6`
  (#1937). The linux SDK pins live only on the unmerged `linux-own-sdk`
  branch (below).
- Open PRs of ours: #1935 (`linux-own-sdk`, draft), #1945 (`parallel-sema`,
  draft). Josh's two old drafts #1887 and #1863 are not ours; leave them.

## Merged today (all battery-green before merge)

| PR | What |
|---|---|
| #1937 | Windows compiler is self-contained (own linker, C runtime, build tools); VS-free SDK release job; self-contained Windows seed pinned |
| #1938 | #1816: a one-liner's code (`with -e`, REPL line) is statements, so `with -e 'let x = 1'` runs; a let-only entry file errors "has no `fn main` and no top-level statement to run" instead of lld's `undefined symbol: _main`. Also c_import: a void C body with no statement (`{}`, `{ (void)d; }`) is `return` (ci_trans_stmt_ir reports lowered-vs-failed separately from text) |
| #1939 | ABI v11: aggregates over 16 bytes cross With calls by plain pointer to a caller copy and return via sret on every target (never byval; byval only for the C convention on SysV x86_64). Codegen units emit on threads while the next generates; decl lookup by name index. Compiling the compiler: 103.6 s → 35.8 s wall, 11.6 GB → 1.46 GB peak RSS. `docs/spec/abi/with-abi.md` is at v11 (Eric merged it) |
| #1934 | #1911/#1933: Linux sigprocmask gets a whole glibc sigset_t; C's usual arithmetic conversions in translated macros; discarded side effects never dropped; operators libclang does not name are translated or refused, never peeled; migrator helper parameters are `__with_`-prefixed (hygiene) |
| #1942 | `benchmarks/run.py` (Python — forbidden) replaced by `benchmarks/run.w`; `std.process.run_to_files[_in]` (exit code, timeout, peak RSS); `std.json.json_quote` public and escapes all control chars; driver fix: `with run tool.w -n 5` / `with tool.w a b` forward every argument after the source file to the program; `:benchmarks-check` in the gate's fixed list |

Earlier today (before #1937): #1928 stack (SIMD #1874 per D78/D80, macOS
with no host toolchain #1826, int formatting #1922, parallel `with test`,
machine-wide build-runner store) and the Windows no-Visual-Studio layers
#1931/#1932.

## Work in flight (stopped, resumable)

### 1. Linux zero-dependency slice — branch `linux-own-sdk`, PR #1935 (draft)

Worktree `~/.local/with-staging/linux-own-sdk`, clean, pushed at
`e997223d`.

**Commits on the branch not on origin/main** (oldest first). The first four
are the pre-squash #1911/#1933 commits that main already has as the squash
`bfa02014`; they drop or conflict on rebase:

| commit | what |
|---|---|
| `37629e29` | rt: Linux /dev/urandom fallback casts its u64 remainder to i64 (already on main) |
| `0c0d6a9c` | rt: glibc sigprocmask gets a whole sigset_t (#1911, on main) |
| `e56b46d7` | c_import: usual arithmetic conversions in macros; discarded effects kept (#1911, on main) |
| `8c9a825f` | migrate: unnamed operators translated or refused; hygienic helper names (#1933, on main) |
| `5dd98e71` | `:linux-sysroot` generates the x86_64 sysroot from the Zig source |
| `f500975a` | the compiler carries the x86_64 sysroot and links through its own lld |
| `ee37bfea` | the own-sysroot link names libpthread and libdl |
| `594656a8` | `:no-host-toolchain` runs in bubblewrap; c_import uses `--sysroot` |
| `6ca391cc` | pin SDK `nightly-sdk-20260930-594656a80308`; D81 records Eric's Linux rulings |
| `6f039463` | the compiler carries cmake and ninja; `with cc` links through its own lld and sysroot |
| `9c76c93d` | pin SDK `nightly-sdk-20260930-6f0394637064` |
| `a3d0c802` | `with cc` on Linux links C++ against a libc++ the compiler carries; `cxx_hello.cpp` in `:no-host-toolchain` |
| `f85f3a60` | per-architecture Linux sysroot; `:linux-sysroot-aarch64` |
| `2f2e484a` | a build-action worker the kernel kills is reported with its signal, not a silent survey failure (#1944); no test (killing a worker by signal from a test is not straightforward) |
| `e997223d` | **WIP:** linux-aarch64 slice — cross-built SDK, per-arch sysroot and link pack, per-arch link and driver |

**Verified**
- Linux x86_64 slice: Mac gate and Linux gate (incl. `:no-host-toolchain`)
  green on `6f039463`/`9c76c93d`; a fresh eric-5090 checkout builds from the
  pinned SDK with no `LLVM_PREFIX`.
- `a3d0c802`: C++ hello via `with cc` builds and runs in the sandbox.
- aarch64 SDK (cross-built): its clang, lld, cmake and ninja compile, link
  and run C and C++ in Docker linux/arm64 on debian:buster (glibc 2.28),
  needing only libc-family libraries. A C program linked against the aarch64
  sysroot runs on Debian 10 and 12 arm64.
- Seed-driven `:cross-rt-arm` green on eric-5090 (tree = `e997223d` minus
  `2f2e484a`). `with check` passes for `src/main.w` and `build.w`.

**Not verified**
- No gate (Mac or Linux) on `a3d0c802` or later.
- No linux-aarch64 compiler has been built or run with this slice.
  `stage2 build src/main.w --target aarch64-unknown-linux-gnu` from x86_64
  stops at the pcre2 bundle (embedded per target), so the compiler must be
  built natively in the `tools/docker/linux-aarch64` container.
- `:no-host-toolchain` has not run on aarch64.

**SDKs**
- Published and pinned on the branch: linux-x86_64
  `nightly-sdk-20260930-6f0394637064`, sha256
  `5d3f1a34f677185880d87bb3b9031e6c4f2967bf4fd0b5077fb3c9e702b6a47f`
  (supersedes `...594656a80308`, whose cmake/ninja linked host libstdc++).
- **Unpublished:** linux-aarch64 `with-llvm-sdk-22.1.6-linux-aarch64.tar.gz`,
  sha256 `4fe9695ef30a05d2f15bd0095b2d8b892ae9102930ca520b382ab545a3727a2b`,
  on eric-5090 at `~/with-ladder/los-fresh/out/release/`, with a copy and
  its manifest on the Mac in `~/.local/with-staging/aarch64-verify/`.
  `sdk.lock` still pins linux-aarch64 to the old `sdk-linux-aarch64` asset.
  Eric has approved publishing Linux SDKs as `nightly-sdk-<date>-<sha>`
  prereleases (never `v*`).

**eric-5090:** `~/with-ladder/los-fresh` is at `a3d0c802` (detached) with
uncommitted edits identical to `e997223d` minus `2f2e484a`; nothing there is
unique. Sync it from the pushed branch.

**Next steps**
1. Rebase onto `origin/main`. The four pre-squash commits drop; if a
   `src/CImport.w` conflict appears in `lower_discard_expr_side_effects_ir`
   (`CXK_BINARY_OP` arm), main's version is already the resolved one: main's
   guarded `if` for discarded `a && b` / `a || b` (mingw's assert) plus
   #1911's fail-loud `BO_ASSIGN` and operand-effects merge.
2. On the Mac, in the `with-aarch64-host` image and `with-aarch64` volume,
   bootstrap the branch natively per the "Linux aarch64 Release Host" section
   of `docs/spec/toolchain/with-release-runbook.md`: the new aarch64 SDK
   tarball as `LLVM_PREFIX`; the libxml2 shim should no longer be needed;
   install bubblewrap and run the container privileged for the sandbox;
   `src/main build :dev`, then `:no-host-toolchain`.
3. Fix whatever breaks. Then publish the aarch64 SDK (nightly-sdk
   prerelease) and pin it in `sdk.lock` and the workflows
   (`tools/bump_seed_pins.w` pattern; `:seed-driver` must agree).
4. Mac `src/main build :gate` and Linux `:gate` on eric-5090 on the final
   commit; then the battery; mark #1935 ready.
5. Remaining gap: C++ through `with cc` on the Mac (the darwin sysroot
   carries no libc++ headers).

Eric's Linux rulings (2026-09-30, recorded in the D81 meeting doc on the
branch): glibc floor 2.28; a user program may find libraries the sysroot
does not carry (zlib, curl) on the host, searched after the sysroot.

### 2. Order-independent body checking → parallel sema — branch `parallel-sema`, PR #1945 (draft)

Worktree `~/.local/with-staging/parallel-sema`, clean, pushed. Rebased
onto main `40aaf6f9` cleanly (the pre-rebase tip is kept locally as branch
`parallel-sema-prerebase`). After the rebase only `with check src/main.w`
has run (ok) — no build or gate yet.

**Commits** (post-rebase hashes; pre-rebase in parentheses)

| commit | what |
|---|---|
| `30448abc` (`f5a00670`) | `WITH_PROFILE` counts what body checking adds to shared tables (841 types, 6 symbols, 6 sigs) and what each codegen unit interns (unit 0: 5451; others ≤ 42) |
| `8c43bc8d` (`2ebe2eef`) | `WITH_SEMA_BODY_ORDER=reverse` debug switch |
| `eab721b7` (`03c38460`) | `--sema-body-order-reverse`, `tools/sema_order_check.w`, `:sema-order-check` target (~40 s), empty `test/sema_order_allowlist.txt`, docs in `deep-debugging-tools.md` |
| `d0ed0915` (`d3bf5685`) | #1941: `@[no_alloc]` judges allocating calls after all bodies (fixpoint over recorded calls); 2 fixtures that compiled `ok` before |
| `5b344b60` (`5892705d`) | an impl method with no return type gets its trait's declared return before any body is checked; fixture |
| `8f129a0c` (`cabb8701`) | D43 (§4.10): a function value or call whose callee has no return annotation checks the callee's body first; env swap is `enter_callee_lexical_env`/`leave_callee_lexical_env`, shared with `check_fn_body_concrete`; fixture `err_1941_fn_value_before_body.w` |
| `afc12b4f` (`22f4c883`) | c_import diagnostics name inline source `<c_import source>`, not a random /tmp file; fixture |
| `87d1f0e5` (`22a959e4`) | **WIP:** diagnostics from `check_bodies` sorted by source position (file, offset, message) |
| `72951be0` | `docs/proposals/parallel-sema/`: the field inventory working notes (`notes.md`, `result0.tsv`, `all.tsv`) |

**Reverse-order diff count** (`:sema-order-check`): 128 at baseline → 127 →
20 → 16 → 15 → **8** on the WIP commit. All 8 are substantive; the allowlist
has 0 entries (the D43 "was not known here" case disappeared with the D43
callee-first commit). Remaining:
- `err_issue366_safe_wrapper_raw_ptr_precondition` — raw-pointer validity
  effect summary read cross-body; reverse compiles `ok`.
- `err_thread_spawn_closure_captures_ref`.
- `err_gen_pull_may_suspend`, `err_gen_pull_view_of_own_local` — likely
  `expr_may_suspend` / `gen_for_each_syms` read cross-body, plus spans in the
  wrong file.
- `err_d21_mut_receiver_owned_escape`, `err_receiver_contract_mut_escape`,
  `err_d60_self_receiver_tail` — likely receiver effect / view-origin
  summaries read cross-body; reverse also reports spans in the wrong file (a
  `local_file_id` leak).
- `err_1827_drop_dyn_box` — a global-view check.

Other cross-body reads still on the S2a list (from the inventory):
`sig_param_effects` / `sig_param_view_origins` / `sig_param_invoke_many` read
by callers; `global_race_mutated_syms`; `body_typed_sigs` /
`untyped_callee_calls`; first-wins caches (generic specialization, drop,
debug_fmt, dyn_impl, dispatchers); name-keyed scratch never cleared
(`dyn_downcast_binding_syms`, `facade_touch_hit_params`) that changes later
bodies' diagnostic text. Key facts per table are in
`docs/proposals/parallel-sema/notes.md`.

**Verified**
- Gate green on every commit through `afc12b4f` (pre-rebase hashes).
- `:fixpoint` (stage2 == stage3, 16 units) and `:drop-audit` (254 cells, 0
  regressions) green only on the first two commits; not run since #1941 (no
  stage boundary reached yet).
- WIP `87d1f0e5`: gate NOT run. It changes line order in 32 fixtures'
  forward-order output; nobody has checked whether any test or consumer
  depends on the old order.
- Forward-order diagnostic content over `test/compile_errors` is unchanged
  from the pre-S2a baseline except the two c_import fixtures (intended).

**Measurements:** compiling the compiler ≈ 35.8 s wall idle (52.6 s / 106 s
user / 1.53 GB on a loaded machine); sema bodies ≈ 15 s idle. No parallel
speedup yet.

**Background and ruling.** Parallel sema/IR was blocked because body results
depend on check order. Ruling (coordinator, from Eric's standing priorities —
build perf #1, never defer, one owner per fact, no per-platform divergence;
fork-per-unit rejected as platform-divergent and unsafe with live emit
threads): **Option B** — make results order-independent, then parallelize.

**Next steps**
1. `src/main build :dev` + gate on the rebased tree; review consumers of
   diagnostic order for the WIP commit, then reword or amend it.
2. Finish S2a: one cross-body read per commit, each with a failing-first
   fixture, moved to a post-body pass or published from declarations. Work
   the 8 fixtures, then the inventory items. Fix wrong-file spans
   (save/restore `local_file_id` around nested or post-body emits). Only real
   D43 cycle cases go in the allowlist.
3. When the count reaches the allowlist: add `sema-order-check` to
   `gate_fixed_targets()` in `build.w`; `:fixpoint` + `:drop-audit` for the
   stage boundary; battery; merge.
4. S1: per-body overlays for types, type_extra, sigs, specializations,
   debug_fmt entries, dispatchers, `global_calls`; merge in body order; remap
   ids in every table holding TypeIds/SigIdx; rebase pooled offset vectors;
   re-intern names that spell TypeIds (`…__sema__<key>`,
   `__with_debug_fmt_<tid>`). Prove byte-identical output, then `:fixpoint`.
5. S2b: per-worker scratch and ambient context (scope/label/borrow stacks,
   `suppress_errors`, `current_module_path`, `local_file_id`, generic
   substitution stacks, `named_types` Self entries); an explicit rule for
   generic bodies re-checked per instantiation (last instantiation wins today).
6. S3: parallel sema over dependency waves, merged in fixed order; measure
   wall/user/RSS.
7. S4: codegen reads a frozen Sema handle + per-thread context
   (`current_module_path` out of Sema); frozen InternPool base + per-unit
   overlay; threaded IR generation; measure.

## Rules and rulings made today you must carry

- D80/D81 (SIMD amendment; zero dependencies): build reads only our SDK;
  run time only OS syscalls/in-box libs; no Xcode, MSVC, Windows SDK or
  system glibc in the compiler. User applications link their own deps via
  `with get` or manually. Windows is windows-gnu (mingw-w64 UCRT) with our
  SDK; `with get` builds packages from source and writes import libraries
  (ruling A); the release ships the notice file.
- ABI v11 is merged; the 16-byte line is Eric's.
- "Fix, don't file": bugs found mid-work are fixed in the batch.
- "Commit and push continuously": agents commit every working step; the
  coordinator pushes draft PRs promptly.
- Eric said: don't install the bash hook.
- Spec §3.8 (D22/D27): an unannotated `let` of a field binds a view; the
  `ecs.w` benchmark was fixed to `let id: i32 = self.count` accordingly.

## Open issues touched today

- #1941 — fixed on `parallel-sema` (#1945, unmerged); closes when it merges.
- #1944 — OPEN: the comptime evaluator reached 63 GB on the `linux-sysroot`
  action (StringBuilder per-byte values, no reclamation) and the kernel
  killed it; the native runner runs the same action fine (10 MB pack). A
  from-scratch build driven by `out/release/bin/with` therefore fails at
  `linux-sysroot` / `linux-sysroot-aarch64` (they run before the runner is
  ready); seed-driven builds are fine. Only the silent-reporting half is
  fixed (`2f2e484a` on `linux-own-sdk`). Needs a real evaluator fix.
- #1915 — OPEN umbrella for zero dependencies; Linux x86_64 done on the
  branch, aarch64 WIP.
- Unraised with Eric, mention if asked: the §20b.5 unreachable-code error
  sits in tension with the not-a-nanny rule.

## Housekeeping

- Many stale worktrees remain in `~/.local/with-staging` from earlier
  campaigns (`fix-*`, `next-*`, `spec-*`, `review-1872`, `main-battery`,
  `seedcheck`, `speed-main`, `battery-speed`, `ex-cinterop`, `impl-d75`).
  Before removing any, check it has no uncommitted work and its branch is
  merged or pushed. `fix-1911` (merged) can go once `linux-own-sdk` is
  rebased. `parallel-sema-prerebase` is a local safety branch; delete it once
  the rebased branch passes the gate.
- eric-5090: `~/.local/with-staging/outline-drop-glue` (merged, idle) can be
  removed; `~/with-ladder/los-fresh` holds nothing unique.
- Untracked in the main checkout (not ours, leave): `docs/plans/`,
  `examples/spiral/`.

## Next steps, in order

1. `linux-own-sdk`: rebase onto main, native aarch64 bootstrap, publish and
   pin the aarch64 SDK, gates, battery, #1935 ready.
2. `parallel-sema`: gate the rebased tree, settle the WIP commit, finish
   S2a, then battery (#1945) — batch with #1935 if both are ready together.
3. Fix #1944.
4. Keep compile speed going through S1–S4; measure wall/user/RSS each stage.
