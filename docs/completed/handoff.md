# Handoff — state as of 2026-09-25 (evening)

## Authoritative state

This section supersedes every status, running-job and stack claim below.
Preserve the binding rules in §2.

### Landed and verified today

- **#1686** (212e42b0 annotation cleanup + seed pin bump) merged as
  **1e839443** after a full pinned-seed battery under the seed it carries.
  Seed **`nightly-20260925-local-1-607a52f543e7`** (asset SHA-256
  `7456c37b…`) is published; `seed.lock` and the workflow pins point at it.
- **Main reseeded at 1e839443**: `:install-user` accepted (green recorded at
  2ac144c0), installed `~/.local/bin/with` = `7456c37b…` — byte-identical to
  the published seed asset (D50 reproducibility), runner compiled natively
  (19.8s, no fallback). `~/.local/with-staging/main-battery` holds it.
- **#1688** landed Eric's ruling on retained variadic pairs (D66 amendment;
  §16.2b.5, §16.2b.9; the D65 two-model debt note). **#1687** credited Josh
  Hickson for #1649 (its code reached main through #1683's squash).
- **#1689** filed: `into_iter` over a returned Vec of a three-`str` record
  yields the last element at every position (22-line repro in the issue).
- `~/with` (this worktree) is **1 ahead / 10+ behind** origin: Eric's
  unpushed `ea77639c` (cross-language benchmark suite) plus uncommitted
  benchmark edits. Not touched; it cannot fast-forward until Eric rebases
  or pushes it as a PR. Its `src/main` is still the previous seed,
  consistent with its own `seed.lock`. **Consequence:** a one-liner run
  from `~/with` with the new installed compiler fails to link
  (`_with_vec_free_buffer_drop_origin` undefined): inside the compiler's
  project root the tree's `rt/` is compiled in-unit (D30), and this stale
  tree predates #1681, which added that runtime function. Not a compiler
  bug; run one-liners from another directory until `~/with` is current.

### In flight — #1679 (retained variadic callback pairs, #1652)

Worktree `~/.local/with-staging/modeled-c-retained-integration`, branch
`modeled-c-retained-variadic`, head **93ddd188** (three commits on top of
the earlier foundation, rebased onto 1e839443, pushed; PR body current).
Implemented and verified on the branch stage1: `abandon` clause, `ok` on
variadic operations, callback/userdata setter rendering with the implied
userdata case, `U` binding for callback-only setters, the Sema pair-op
registry, `MirForeignPairs.w` (place flow over the real CFG, findings in
the body's file, `WITH_DUMP_PAIR_FLOW=1` dump), libcurl facade + UAT under
the amendment, 3 runtime/check fixtures and 7 compile-error fixtures.
Runtime proof against real libcurl: the file:// transfer through the pair
and the ruling's required failure case both pass under `--debug-alloc`
with leak count 0.

**Battery RUNNING**: `out/run_battery.sh`, status `out/battery-status.txt`,
logs `out/logs/battery*.log` (build, fixpoint, drop-audit, move-audit,
test, test-green, last-green, user-programs-safe; alone in its batch —
it changes the generated Drop). When green: post the verdict table on
#1679, `gh pr ready 1679`; Eric merges; then reseed main (§2) and remove
the worktree. If red: fix on the branch, re-run once.

Not modeled (refused conservatively; `docs/modeled-c-pair-state-plan.md`):
interprocedural pair summaries for helpers; a closure literal as the
callback (pass a named fn); the retained pointer case (POSTFIELDS);
reading a chunk's bytes inside a write callback (`char *` stays raw).

### Open with Eric

- **(c) wording**: the landed §16.2b.5/§16.2b.9 text says an "in-place
  `mut U` borrow", which the language cannot spell (no in-place `mut`
  parameter on a free fn; verified by running). Proposed replacement under
  the D62 capture model was put to Eric in this session: retained userdata
  is `&U`; when `U` is a callable, every callback-capable operation on the
  resource is a call of `U` (mutable captures invalidate views into their
  places), the places stay usable between operations, retention ends at
  reset/destroy/last callback-capable op, the resource is ephemeral for the
  window. Implementation follows D62 either way. Awaiting his word; then a
  docs-only PR.
- Eric is weighing surfacing redundant type annotations: the suggestion on
  record is a Sema-backed lint with an exact fix-it that `with fmt` applies
  and the compiler's own tree gates on, not a default warning in user
  programs.

### Worktrees

`main-battery` (reseeds, detached at 1e839443), `modeled-c-retained-integration`
(#1679), `stack-admin` (detached, administrative; removable), Eric's own
`/Users/eric/with-bench-fixes` (#1681 merged; his to remove). All merged
staging worktrees and branches were deleted today; the remote has only
`main`, `release*` and `modeled-c-retained-variadic`.

### Next after #1679

§2's priority: `with uat` (#1659), then STC (`docs/stdlib_sourcing_plan.md`
phase 3). Eric decides compiler merges.

## Historical resumption notes (superseded by takeover state above)

- **Merge approval received; already landed when checked:** Eric approved
  #1672/#1675. GitHub reports #1672 merged as **390bbeed**, #1675 as
  **a0cd734e**, and #1683 as **a5c6f430**. #1649 had merged into the
  foundation before #1683 landed. Fetched `origin/main` **a5c6f430** is
  tree-identical to verified float head **0ab7f0f2** (`git diff --stat` empty),
  so the float changes are on main too. No duplicate merge command issued.
  #1679 remains OPEN/draft, now based on main, remote head **0dc4b328**;
  this differs from our old local retained head, so inspect before any push.
  The lower-stack approval is resolved. No install or seed publication was
  performed in this approval turn.

- **Latest verified status (2026-09-25):** combined pinned-seed battery
  **60770 completed all green** at code head **1012a32b**: build, fixpoint,
  drop/move audits, full :test (1,290 behavior files rerun), test-green,
  last-green, user-programs-safe. Float worktree status file says `all passed`.
  The targeted literal test also passes compiled emit-C output:
  `out/float-literal-c-{compile,run}.log`. Documentation-only evidence commit
  **0ab7f0f2** records these results; no compiler changes after the battery.
  **#1683 and #1649 are now READY**, alongside #1672/#1675. #1679 remains
  draft and genuinely incomplete; do not claim retained callbacks work.
  Original fork PR #1649 now has head **0ab7f0f2**, C-compatible title/body,
  and base `public-return-foundation`; Josh's original author commits remain.
  GitHub rejected adding it to a stack: **"Pull requests from forks cannot
  be added to stacks."** Repository-owned stack is now **#1685**:
  **#1672 → #1675 → #1683 → #1679**. #1649 is a sibling of #1679 based on
  #1683 and must merge separately after its foundation. The temporary origin
  mirror `josh/float-round-trip` was deleted; original fork branch remains.
  All base changes used gh stack. Existing lower-stack merge approval is
  still pending; do not ask it again or silently extend its scope.
- **Cleanup candidate verified locally:** branch `public-return-annotation-cleanup`
  remains **3a18dcc0**. Local self-host build and fixpoint both passed
  (`out/audit-current-local-{selfcompile,fixpoint}.log`, sessions 51545/71398
  finished). Fresh `out/release/bin/with check build.w` passes; after moving
  the old runner aside, that exact fresh binary compiled a new native runner
  in 20.8s and passed :spec-inventory-check with no fallback
  (`out/audit-fresh-release-native-runner.log`). This is NONCANONICAL local
  evidence, not a pinned-seed battery. A seed cut containing the cleaned
  embedded Never signature is still required; none has been published.
  No active builds remain from this batch. Preserve the user's main-worktree
  edits. No new retained-integration source edits were made.

- **Current verification / cleanup bootstrap detail:** combined float battery
  60770 has passed build, fixpoint, drop/move and is in :test. Fresh combined
  stage1 passes `behav_float_unsigned_cast.w` and the 592×8 C sweep under
  debug allocator (zero leaks): `out/float-unsigned-after.log`,
  `out/c-float-final-sweep-alloc.log`.
  Cleanup branch rebased unchanged onto combined head: **3a18dcc0**, patch ID
  **7eb964bfe7d643d9bd809e0a8476b6fadf548c3a**. Compiler source check passes.
  **Its new seed needs both public inference AND the cleaned embedded
  Diagnostics.error Never signature.** Combined parent stage1 still embeds
  old Unit, so checking cleaned build.w produces four missing-return errors
  in selfhost.w (2646/3194/6678/6684). Old locally built cleanup stage1, with
  the correct embedded Never, accepts the exact same build.w.
  Logs `out/audit-current-{build,source}-check.log` and
  `out/audit-clean-stdlib-driver-check.log`. No annotations restored.
  Named copy `out/public-return-clean-stdlib-driver` now drives a explicitly
  NONCANONICAL :dev self-compile of current cleanup source; log
  `out/audit-current-local-selfcompile.log`. Source frozen while it runs.

- **IMPORTANT — repaired stack reorder / #1680:** while moving the parser
  foundation below retained callbacks, I pushed the new retained ancestry
  before changing #1680's base. GitHub automatically marked #1680 merged
  INTO ITS OLD PARENT and deleted its branch. It is **NOT on main** and
  cannot be reopened (`gh pr reopen` confirms). No code lost: replacement
  **#1683**, branch public-return-foundation, head **97e53972**, now has the
  parser fix plus Unit gate directly above #1675. Old #1680 title/body point
  to it. Correct stack **#1684**: **#1672 → #1675 → #1683 → #1679**.
  Retained head **aa7eba41** is based on public-return-foundation. Its final
  tree equals pre-reorder 6a85ec3e exactly. All changes used gh stack; no
  direct PR-base editing. The lower merge approval remains pending unchanged.
- Foundation standalone battery completed: every build/test/audit gate passed,
  but user-programs-safe correctly failed on four unsafe tally blocks in its
  old main base. Rebased foundation onto ready #1675; patch ID remains
  ae9144e5d5dab3f2a6795af69d0c827fa84cebd6. Float branch then rebased onto
  foundation: current combined head **1012a32b**, float patch ID unchanged.
  **Combined pinned-seed cold-cache battery RUNNING**, session **60770**,
  `float-c-format/out/combined-battery.log`, status out/ready-battery-status.txt.
  Includes lower modeled-C + foundation + all float changes; stage1 passed
  and full build is running. No source edits in float worktree until done.

- **MERGE APPROVAL PENDING:** #1672 and #1675 are now **ready (not drafts)**.
  Cold battery **22748 completed all green**, including 1282/1282 behavior
  files with zero cached verdicts and final test/last-green/user-safe gates.
  Stack rebased cleanly onto new main **c5aaf76f** (#1681); combined patch ID
  before/after is **9bfe49f5d021fa84ec5606b207841e33cd94fef4**. Pushed heads:
  #1672 **b1a1cf0d**, #1675 **78edfb7a**, #1679 **278e0daa**, #1680 **6a85ec3e**.
  `gh stack link 1672 1675 1679 1680` confirms stack #1676 current.
  PR bodies contain complete evidence/provenance. Asked Eric once via async
  whether to run **`gh stack merge 1675 --squash --yes`**, citing §2. Do not
  ask again; any reply authorizes only those two. Main battery before install.
- Float committed further exact f/e and cast work, then rebased cleanly onto
  c5aaf76f: **b8473e52** (4 commits). Aggregate patch ID unchanged:
  0fe5617e54288d440a1befb0bc46447d8ba48370. Worktree clean; no full battery
  started yet. Prior final stack-storage/dead-helper cleanup and cast fix still
  need rebuild. Foundation **93184** remains running on old base. Its final
  user-programs-safe will encounter main's four tally unsafe blocks because
  it lacks the lower modeled-C layers; do not waive that gate. Base final
  foundation/float validation on the ready lower layers (or their merged main).
- New worktree **stack-admin** holds original stack branches for operations;
  current branch public-return-inference-audit. New **modeled-c-retained-integration**
  worktree is clean, detached at a57c64f9 (created for later #1652 integration).
  No retained integration edits were made; its MIR/renderer work remains.

- **Newest float work / active processes:** lower initial battery **31175
  completed ALL GREEN**. Its cold-cache :test rerun now runs as session
  **22748**, log `modeled-c-ready-battery/out/cold-test-battery.log`, status
  `out/cold-test-status.txt`; prior verdict/pass/test-state files moved to
  `out/verdicts-before-cold/`. Unique epoch is set. Foundation **93184** has
  passed build/fixpoint/drop/move and is in :test. Max two batteries active;
  wait for a slot before float full validation.
- Float **21978b22** has further UNCOMMITTED fixes: exact fixed rounding,
  no 18-digit scientific clamp, dynamically sized output for high precision,
  stack storage for common precision; obsolete fixed/shortest helpers removed.
  LLDB `out/float-fixed-lldb-proof.log` observed rt_core.w:152 with val=1e30,
  and the +0.5 rounding at :162. Old probe printed `0.13` for .125:.2f and
  nonsense for 1e30. Rebuilt stage1 via :dev **41527 PASS** (119.6s wall).
  Boundary and C differential tests PASS for 592 values × 8 formats,
  including 1100 precision; debug allocator leak count=0
  (`out/c-fixed-{boundaries,sweep,sweep-alloc}.log`). Subsequent dead-helper
  removal/stack fast path source-check passes but needs the next rebuild.
- The same hunt found an actual **float→unsigned cast compiler bug**:
  CodegenDispatch.w:3890 used src_unsigned (always false for float) to choose
  FPToUI/FPToSI. `out/float-unsigned-before.ll` has @convert(double) emitting
  fptosi for declared u64; runtime strtod probe fails, while a constant-only
  assertion was optimized away by poison. Uncommitted fix uses Sema's
  destination type d1. New `behav_float_unsigned_cast.w` uses runtime values,
  covers f64→u8/u16/u32/u64, f32→u32/u64 and signed control. Old stage1 fails
  at line15 as expected (`out/float-unsigned-regression-before.log`). Fix NOT
  yet rebuilt or tested; include it in float battery. No code builds active
  in float worktree now; earlier general-format test session86127 passed.

- **Latest checkpoint (supersedes older running/dirty status below):** audit
  cleanup is committed as **3f7b3c3e** on `public-return-annotation-cleanup`
  in modeled-c-completion. It is not pushed or canonical-seed verified.
  Local self-compile, fresh build.w check, scanner, libc/runtime-domain,
  spec-inventory and user-programs-safe gates pass. Runtime-domain negative
  mutation reported both bad rows and failed before restoration and clean pass.
  Independent foundation worktree `public-return-foundation` has **6621f4c6**
  (parser fix without ForeignPairState edits) and **85db7d71** (prevention),
  based on main; no remote restructuring or PR yet.
- Lower battery **31175**: build, fixpoint, drop-audit, move-audit all passed;
  :test running, behavior-tests **1282/1282 passed**. Source remains unchanged.
- Float C ruling is implemented locally for default and explicit g, including
  high precision terminating expansions; spec/D68 and tests now state C %g.
  Sweep compares host snprintf for positive/negative values across the range.
  Seed-driven :dev is running in float-c-format, session **57707**, log
  `out/c-general-dev.log`. Do not edit its sources until build completes.
  These changes are uncommitted and unverified; no contributor branch push.

- **Float verification update:** committed **21978b22** on
  `float-c-format-resolution`, preserving rebased author commits d291009b and
  842917d8. Seed-built stage1 :dev passed (106.2s stage1, 156.3s wall).
  `out/c-general-{boundaries,sweep,literals}.log` all pass: direct snprintf
  comparisons for default/30-digit g across 586 values, fixed boundary cases,
  and literal-rounding tests. Broader fstring/float test command running,
  session **86127**, `out/c-general-format-tests.log`. No full battery yet.
  #1649 is a maintainer-editable fork PR (joshhickson/with,
  josh/float-round-trip); do not push until verified.
- **Foundation battery running:** public-return-foundation **85db7d71**,
  session **93184**, `out/foundation-battery.log`; same sequential runner as
  lower battery, with a fresh WITH_CIMPORT_CACHE_EPOCH. Source frozen.
  Lower battery did not set a fresh C-import epoch: after its current run,
  invalidate per-file verdict caches and rerun :test with a unique epoch
  before claiming the handoff's cold-cache requirement satisfied.

- **PR-resolution steering / float ruling (latest):** Eric asked to drive all
  drafts to resolution, then ruled "we need to match what C does" in reply
  to the #1649 default float display question. Interpreted explicitly in
  commentary as C `printf("%g")`: default six significant digits and C's
  precision-dependent notation threshold, not shortest round-trip. Primary
  reference: https://open-std.org/JTC1/SC22/WG14/issues/c99/issue0233.html.
  Preserve the correctly rounded literal fixes. Float review worktree
  `~/.local/with-staging/float-c-format`, branch `float-c-format-resolution`,
  fetched #1649 and rebased cleanly onto origin/main. No float code edits yet;
  do not push over the contributor branch before validation.
- **Lower modeled-C battery NOW RUNNING independently:** worktree
  `~/.local/with-staging/modeled-c-ready-battery`, branch
  `verify-modeled-c-ready`, source **590aa2be** (#1672 + #1675 only).
  Exact pinned seed copied into src/main; WITH points there. Driver
  `out/run_ready_battery.w` runs seed-driver, build, fixpoint, drop/move audit,
  test, test-green, last-green, user-programs-safe, stopping on first failure.
  Exec session **31175**, log `out/ready-battery.log`, live status
  `out/ready-battery-status.txt`. Seed-driver passed; full build is running
  (stage1 passed, pcre2 bundle building at last check). Do not alter this
  worktree during validation. This isolates ready layers from unfinished #1652.
- Local inference self-compile **passed**, 138.7s stage1 / 205.4s wall.
  Fresh stage1 embeds cleaned stdlib; scanner test passes and all three
  StringBuilder.push_* signatures remain Unit. Fatal-diagnostic negative
  regression fails at its intended unreachable statement. New compiler
  checking build.w exposed additional unreachable error-reporting code:
  working through it in the audit worktree (uncommitted). Counted validation
  loops now print error details then retain their existing nonzero/fatal
  aggregate outcome; consecutive fatal calls are combined so details appear;
  parallel test workers are all reaped before failure returns. Four wrongly
  removed OUTER fallback returns were caught in review and restored; Lexer
  does NOT emit DEDENT, so scratch rewriters now compare physical indentation.
  One removed outer literal tail in run_cross_unsupported_action is valid:
  BOTH if/else arms abort. Latest check log:
  `out/212e42b0-build-cleanup-final-check.log` (session  from current turn).

- **Newest checkpoint — return-inference fallout/prevention:** active worktree
  `~/.local/with-staging/modeled-c-completion` is now on
  `public-return-inference-audit`, **0a68d06d**, draft **#1680** at the top
  of GitHub stack #1676 (linked with `gh stack`). Parent #1679 is
  **a57c64f9**: it includes the public-return parser correction
  **869b2c7a** and per-resource-place CFG pair-state propagation. The
  resource-state model still is NOT connected to MIR acceptance or retained
  callback bridge generation; its fail-closed guard remains.
- Eric wants stronger mechanical prevention: new explicit `-> Unit` is legal
  but suspicious. #1680 adds lexer-based `:unit-return-review` to `:test`,
  uncached, exact-signature rationale ledger, untracked-source rejection,
  and public/private inference generated from identical bodies. Scanner and
  fixed-stage1 matrix pass; old pinned seed fails the matrix with the exact
  unsupported public-return diagnostic. A real tracked annotation mutation
  fails the review tool (fixture restored). Logs:
  `out/unit-return-{review-test,trigger-mutation,review-stack}.log`,
  `out/public-private-return-{matrix,old-seed}.log`.
- **Dirty audit work is intentional, not part of #1680's checkpoint:**
  210 token-accurate removals of redundant annotations introduced by
  `212e42b0`, across 30 files. Audit found 232 additions: 216 surviving Unit
  declarations, 4 now Never, 12 retired; keep the explicit-spelling test,
  `migrate_add_define`'s D43 mixed-tail choice, and four Workspace APIs
  (`set_migrate_options`, `begin_intercept`, `end_intercept`, `set_link_command`)
  whose comptime implementation returns Unit although their native unsupported
  fallback exits. Removing those four inferred Never incorrectly; restored
  with rationale before validation. `src/main.w` checks with the
  fixed stage1. Removing `Diagnostics.error -> Unit` exposes its real Never
  return and dead callers. LLDB stopped at SemaCheck.w:9894 with
  block_diverged=1 (`out/212e42b0-unreachable-proof.log`). Both native and
  comptime diagnostics.error abort; docs/with-build.md promises this.
  Removed 115 adjacent dead `return 1` statements in build actions and moved
  the unreachable checksum-failure temp-file deletion BEFORE the fatal
  diagnostic (one additional dead return removed). Direct `lib/std/build.w`
  check now passes; broader validation and regression for this cleanup remain.
  Changes are uncommitted; do not discard or blindly restore annotations.
- A **local, noncanonical self-compile** is running to validate fresh embedded
  stdlib after cleanup: driver `out/public-return-inference-driver` is a named
  copy of the previously fixed stage1, `WITH` points to that same file,
  command `build :dev`, log `out/212e42b0-local-selfcompile.log`, exec session
  **78715**. The earlier attempt was deliberately stopped before restoring
  the four Workspace contracts. This local bootstrap is NOT pinned-seed
  battery evidence. Do not edit compiler/stdlib sources while it runs.
  The 30-file direct sweep passed 25, with isolated module/prelude context
  failures on string, CImport, CiMigrate, ClangBridge, Windows fiber core.
  Correctly configured Windows fiber core `--no-prelude` passes; full main
  check covers the compiler modules. `std.string` needs the fresh embedding.
  New report: `docs/public-return-inference-audit.md` in the staging worktree.
- Bootstrap sequencing matters: pinned seed still rejects public inference.
  `out/bootstrap/bin/with-stage1` is the fixed parser compiler (185s :dev,
  `out/public-return-dev.log`), before the broad cleanup. A new seed is needed
  before the annotation cleanup can pass a full PINNED-seed chain. No full
  battery has run, no PR is merge-ready, and no merge approval is pending.

- **Modeled C completion active (2026-09-25):** Eric prioritized #1644,
  #1643 and #1652 to remove tally's four remaining unsafe blocks. Worktree
  `~/.local/with-staging/modeled-c-completion` now on
  `modeled-c-retained-variadic` (#1652 draft **#1679**, commit **6fd4fe78**, based on element
  layer 590aa2be after rebasing the stack onto bc0cf27f).
  No subagents; no full battery yet.
- **Both rulings approved and landed:** #1670 (`31489ce1`) adds explicit
  `elements` to D64 input and in/out clauses, typed slices, checked C-count
  conversion and copy-back bounds. #1671 (`c1c1012b`) adds explicit
  `callback param 2 as curl_write_callback userdata param CURLOPT_WRITEDATA`
  to D66. Both spec-inventory checks passed. No ruling question pending.
  Docs worktree: `modeled-c-elements-ruling`, currently callback-type branch.
- **Draft #1672** `modeled-c-completion` at **44cbc6c0**, based bc0cf27f:
  free callback bridges share methods' userdata-first typing, nullable pair,
  thread/effect checks. LLDB proved the no-resource rejection branch;
  source check/:dev, runtime/negative probes, method regressions and
  audit:all (643344 facts, zero violations) passed. Mutable collecting
  userdata works as an ordinary capturing callable borrowed by the callback;
  the call-once negative remains rejected. No full-battery claim.
- **Element-buffer layer draft #1675**, committed/pushed **590aa2be**:
  parser/Sema explicit unit plus a
  shared per-parameter renderer for ordinary/callback operations, checked
  count conversion, signed copy-back bounds. Typed records, input/inout,
  callback composition, signed/unsigned overflow and alias rejection pass.
  LLDB also proved/fixed translated C calls redirected through facades,
  missing generic slice coercion/parameter context, and resource effects
  left in C parameter indices after a buffer count is removed. Both byte
  and element stale-view probes now reject (diagnostic names C param 2).
  Audit missed the effect-index defect: filed #1674. Separate Display usize
  defect filed #1673. Logs under the implementation worktree's `out/`.
- **Latest dev build PASS:** `out/elements-dev-resolution.log`.
  Audit caught generic buffer/callback calls with a raw C callee operand:
  LLDB `out/elements-resolution-proof.log` stopped at MirLower.w:15118,
  raw callee 13358, node 578114. The generic lowering now propagates
  `comp_resolved` instead of choosing the operand from AST spelling.
  Source check, runtime fixture and free-callback regression pass;
  `out/elements-final-audit.log`: 644407 facts, zero violations.
  Added `behav_analysis_resolution_facade_generic.w` (runner needs stage2/
  release path, so final battery tests it; no fake stage2 copy).
- **Tally migrated under approved ruling:** real-header facade check passed
  before application rewrite. No unsafe remains. Stage1-direct example
  build, all 12 example tests, runtime output and debug allocator leak=0
  pass; root `:user-programs-safe` passes. Use stage1 directly for the
  example build (installed driver ignores WITH for that project target).
  Linked #1672 → #1675 using `gh stack link --base main 1672 1675`:
  **stack #1676**, both draft; no full battery yet.
  Committed-head gate rerun PASS (`out/user-programs-safe-elements-committed.log`).
  Tally `audit:all` PASS: 642885 facts, zero violations
  (`out/tally-final-audit.log`; use `-Iexamples/c-interop/vendor`, no space,
  after `audit:all`). No build/test process remains active for this work.
- **#1652 active, not complete; no question pending.** Eric approved
  `callbacks none` as a verified foreign-library assertion and refusal of
  callback-capable operations on incompatible pairs, but rejected a blanket
  scope-exit ban. Check actual cleanup, including early return and `?`.
  Required runtime proof: first setter succeeds, second fails, function
  returns an error, safe cleanup releases retained storage once. Track
  defaults/replacements/failures; model safe reset/unregister/abandonment;
  no concurrent callbacks between the separate setters. curl cleanup can
  invoke progress/header callbacks, so cannot be unconditionally `none`.
  Approved docs merged as **#1677 / bc0cf27f**; stack #1676 rebased/pushed
  with `gh stack rebase` and `gh stack push`.
- **#1652 WIP:** parser/Sema/audit accept `callbacks none`; parser accepts
  explicit callback type and per-case retention, but Sema deliberately
  rejects retained variadic cases until safety checks are wired. Latest
  `out/callback-state-dev.log` :dev PASS, clause behavior/negative tests
  PASS. `ForeignPairState.w` and its internal test cover setter outcomes,
  unknown failures retaining old/new origins, replacement, backward joins,
  callback-capable cleanup, callback-free destruction and creation loops.
  These abstract tests PASS but are NOT compiler integration or runtime
  acceptance evidence. LLDB proved/fixed the negative-guard edge filter
  in `out/foreign-pair-guard{,-branch}-proof.log`.
  Remaining: Sema slot/call facts, MIR place/alias and status flow, borrowed
  origin lifetimes including helpers, rendering, actual failing-setter test.
  See `docs/modeled-c-pair-state-plan.md` in the implementation worktree.
  Inline C variadic fixture with va_start/va_arg is omitted by c_import:
  filed **#1678**; do not substitute a fixed-arity definition (wrong ABI).
  Latest additional WIP: Sema resolves `ForeignVariadicSlot` declaration
  metadata (resource, retaining param, explicit C callable, unique void*
  slot, paired selector/value), still behind the safety refusal. Source
  check and **out/variadic-slot-dev.log** PASS (170s). Four new negative
  tests PASS: non-callable, ambiguous userdata, wrong variadic position,
  selector-value alias. Existing real-libcurl setopt, variadic free cases
  and callbacks-none behavior PASS. Latest gate PASS:
  **out/user-programs-safe-callback-state.log**.
  `out/curl-pair-failure-probe.w` runs the real variadic ABI: WRITEFUNCTION
  succeeds, deliberately invalid LASTENTRY fails UNKNOWN_OPTION, reset
  and cleanup complete. Raw probe only, not safe-facade acceptance; never
  add LASTENTRY to the production facade. Reset also has a MIME freefunc
  invocation path (easy.c:1110 -> url.c:198 -> mime.c:1127), so `none`
  needs a proof bounded by the modeled option set, not a global assumption.
  No full battery or active build. Do not claim #1652 done from these tests.
- **Visibility correction:** #1652 WIP is now committed and pushed as
  https://github.com/withlang-dev/with/pull/1679, added via `gh stack link`
  to stack #1676: #1672 → #1675 → #1679. The first two layers have targeted
  green checks but are not merge-ready without the complete stack battery.
  #1679 explicitly documents the remaining integration and failure-path
  acceptance work. Eric reiterated: keep working rather than stopping at
  progress reports; continue implementation, then one full stack battery.
- **#1665 complete and installed:** merged main **334739d2** built and
  installed successfully. The gate reused the published green for the
  byte-identical source tree at 1f277365. Installed ~/.local/bin/with,
  main-battery/out/release/bin/with, and rss-budget/out/release/bin/with
  are byte-identical, SHA-256
  **88b438898e344e8e1caa73bd4359e48ed21189a99e6de4f774e8157ed44011ef**.
  `--version` is still v0.15.2.1, so use the digest to identify this build.
  Logs: main-battery/out/main-334739d2-build.log and
  out/main-334739d2-install.log. #1665 is closed by the merge.
  Forced installed-runner rebuild and spec inventory check also PASS,
  without fallback: out/main-334739d2-installed-runner.log. No process or
  approval remains pending for #1665. Next planned campaign remains §4.3;
  #1667 is the separately filed seed self-refetch defect.
- **#1666 merged by Eric:** main is **334739d299aebf16fa11236904dc74a6fa914283**,
  byte-identical tree to tested 1f277365. ~/with was fast-forwarded with all
  user edits preserved. Its src/main now matches the new seed digest.
  main-battery is detached at 334739d2 and building for installation
  (`out/main-334739d2-build.log`). Reuse #1666's exact-tree green evidence;
  run install-user after build, then prove the installed runner rebuilds.
- A same-path `WITH=$PWD/src/main src/main build :seed` removed the old
  driver before compiling its HTTPS helper and failed with exit 127.
  Filed **#1667** with the observed failure/source evidence. Re-running
  with the installed compiler succeeded; ~/with/src/main is restored and
  checksum-verified. Logs: rss-budget/out/main-seed-refresh*.log.
- **FINAL #1665 validation (2026-09-25):** #1666 at **1f277365** is fully
  green and ready for review/merge. `rss-budget/out/logs-rss-seeded/`:
  build PASS, fixpoint all 16 units PASS, drop audit PASS, move audit PASS,
  full test PASS (1,274 behavior / 1,121 compile-error / 210 spec / 37
  internals, all other lanes green), test-green PASS, last-green PASS and
  published. Worktree clean, pushed; PR body and verdict updated.
  Eric's prior approval covered #1656/#1661/#1662, already merged; the
  #1666 merge is the remaining maintainer decision. Do not rerun this
  battery unless the source/base changes or new evidence justifies it.
- Closed resolved issues per §4.1: #1631, #1634, #1639, #1635, #1621, #1624.
  #1665 stays open until #1666 lands. #1649 remains untouched.
- **Seed published / final RSS battery active (2026-09-25):** main at
  8d3cc360 passed the complete pinned-seed battery, install-user, and a
  forced installed-runner rebuild + spec inventory check. Logs are in
  `main-battery/out/logs-8d3cc360/`. Installed compiler SHA-256:
  `a29eb6b4599035b5a19d60f31a0a3a72ce37db0f8e09752c064855b7119475da`.
  Published `nightly-20260925-local-1-8d3cc360cf23` with the byte-identical
  release binary, checksum and provenance. Main's seed.lock is unchanged;
  the new lock/workflow pins are in #1666.
- #1666 is now **1f277365**, pushed, including the new seed pins and removal
  of the temporary actual_options.output_path.clone() accommodation.
  The old seed fetched and verified the new asset into rss-budget/src/main.
  The full battery is running in `rss-budget/out/logs-rss-seeded/`, driven
  by that new pinned seed, with a cold c_import epoch and the stale embedded
  object moved aside. Do not overwrite rss-budget/src/main with ~/with's
  old seed. Main's new release compiler already checks #1666's restored
  field move successfully (`out/rss-new-seed-source-check.log`).
- **Latest:** Eric approved merging the verified stack. Ran
  `gh stack merge 1662 --squash --yes`: #1656/#1661/#1662 are merged at
  **8d3cc360cf23f42bc4776fa1ae12f12174960cdc**. GitHub automatically rebased
  #1666 onto main at **2741bf3f**; its stable patch ID is unchanged
  (`912fec33ccc051ed6e49b8f174fcf5fedada828c`). The rss-budget worktree
  follows that head; its only pending edit removes the field-copy seed
  accommodation, to commit with the replacement seed pins.
- Main battery is running in clean detached `main-battery` at 8d3cc360,
  pinned seed copied from ~/with/src/main, cold c_import epoch, stale
  embedded_objects.o moved aside. Logs: `out/logs-8d3cc360/`. Stage1 passed.
  After green: install-user, prove installed compiler builds its runner,
  publish a nightly seed with sidecars, add its lock/workflow pins to
  #1666, and run #1666's full battery with that new seed. The approval was
  for the first three PRs; #1666's merge remains Eric's decision.
- Eric reaffirmed: finish the existing #1656 → #1661 → #1662 GitHub stack
  first; manage it with `gh stack`. #1649 is still untouched.
- #1662 now includes **974c8bac**, pushed. LLDB disproved the table-sizing
  hypothesis below: `resolution_sorted_by_key` received one declaration span,
  initialized `root = -1`, and entered the `order[child]` bounds-panic branch.
  At helper +356, `w20=1`, `w10=w12=w13=0xffffffff`, `w15=0xfffffffe`;
  stepping the sign test reached +1016 (panic). The fix returns the already
  sorted order for fewer than two spans.
- Added `behav_analysis_resolution_no_prelude.w`: no-body diagnostic,
  singleton indirect call, two bodies. It fails on the previous compiler and
  passes on the new stage2. The original `behav_c_va_list_target_abi.w`
  passes on the new stage2, including all five targets. Planted resolution
  and unknown-callee validator tests pass on the new stage1.
- `audit-res` is clean at 974c8bac; its build log is
  `out/resolution-build.log`. `fold2` is fast-forwarded to the same commit;
  the corrected battery is **fully green**, logs in **`out/logs-resolution-fix/`**.
  Do not reuse the previous `out/logs/` verdict as evidence for this head.
- Imported remote stack #1664 using `gh stack checkout` and reset the clean
  `mc-curl` worktree to origin/0085bfe6, as instructed below; it is no longer
  stale. Updated all three PR descriptions, and removed #1661's incorrect
  “user-programs-safe green” title claim. All three are **ready for review**.
  Build, fixpoint (16 units), drop audit (213 cells), move audit (105 cells),
  full test (1,273 behavior / 1,121 compile-error / 210 spec / 36 internals),
  test-green and last-green passed. Verdict posted on #1662:
  https://github.com/withlang-dev/with/pull/1662#issuecomment-5825288540
- Eric then prioritized **#1665** (application builds wrongly inherit the
  compiler's global 1 GiB RSS guard). Work is active in
  `~/.local/with-staging/rss-budget`, branch `build-rss-budget-scope`, based
  on 974c8bac. **Draft PR #1666**, commit **f766251d**, is now the fourth
  layer of stack #1664 (`gh stack link 1664 1666`). Eric still owns the
  merge per §2. UAT/STC waits.
- #1665 LLDB proof: `out/rss-scope-lldb.txt` in that worktree. A tiny ordinary
  application builds successfully; injecting a recorded peak of 1 GiB + 1
  byte at `build_graph_times_report` reaches `run_build_graph +91024`, with
  x8=0x40000001, x27=0x40000000, takes the global guard branch and exits 1.
  The implementation in progress makes budgets explicit per target
  (`Target.rss_limit(bytes)`), defaults to reporting-only, configures the
  compiler stage targets in build.w, preserves budgets in graph/cache/clone
  paths, and tests synthetic measurements. Stage1 and the synthetic policy
  test pass (`out/rss-dev.log`, `out/rss-policy-stage1.log`). The iterate
  stage2 build passed (`out/rss-stage2.log`), driven by the new stage1.
  The stage2 integration test passed (`out/rss-integration.log`): ordinary
  and configured success, repeated one-byte-budget failure, dependent
  blocking, metadata isolation, invalid-budget rejection. Spec inventory
  also passed (`out/rss-spec-inventory.log`). The worktree is clean and
  pushed; #1666 stays draft pending the pinned-seed battery.
- **#1665 bootstrap prerequisite:** the pinned seed rejects src/main.w:2008
  with its known false field-move diagnostic; the verified stack compiler
  accepts it. Do not call an alternate-driver run the final pinned-seed
  battery. Eric has been asked once for permission to merge the green first
  three layers with `gh stack merge 1662 --squash`, then cut the seed before
  #1666's final battery. No answer yet. Do not repeat the approval request.

Everything a fresh agent needs to pick up every open thread and finish it.
`CLAUDE.md` is binding and is the *rules*; this file is the *state*, plus
the rules Eric gave in the last week that are not in `CLAUDE.md` yet (§2).
No subagent is running at handoff: every in-flight item is on disk (a
branch, a PR, a worktree) and described in §4.

---

## 1. Where things are

- **main** = `aa978c6d` (spec §18.5d / D67 `with uat`). Code-wise main =
  `fa33bda5` + docs: modeled C stages 0–13 complete (incl. 11, 12b, D64
  buffers/fixed args, the zlib/bzip2/sqlite3 facades and UAT rewrites, the
  recovered `examples/c-interop`), D62/D63 closures, the #1635
  alias-callable fix, the build-runner unblock.
- **Installed compiler** `~/.local/bin/with` = main `fa33bda5` build
  (reseeded after stack #1646; the gate matched the green recorded at
  3e298d3f; it compiles the native build runner, `:seed` green under it).
- **Pinned seed** (`seed.lock`) = `nightly-20260925-local-1-fa33bda543c2`,
  darwin digest `4b9da136…`; `~/with/src/main` IS that seed (fetched with
  `with build :seed` after #1651 merged). Every worktree copies
  `~/with/src/main` as its `src/main`. This seed still carries the 16-bit
  field-path bug (#1631, fixed in #1656 — not yet merged), hence the one
  accommodation line in §4.1.
- **Remote branches**: `main`, the four open-PR branches below, the 12
  `release*` branches. `delete_branch_on_merge` is ON for the repo.
- **Local**: `~/with` is on `main` (1814a141 — `git pull` to reach
  aa978c6d; it has Eric's uncommitted `docs/feature_plans/*`,
  `examples/spiral/` and this file — leave them).
- **Open PRs**:
  | PR | branch | head | base | state |
  |---|---|---|---|---|
  | #1656 | `sema-field-move-path` | 4ec85d78 | main | draft — bottom of stack #1664 |
  | #1661 | `modeled-c-d66-curl` | 0085bfe6 | `sema-field-move-path` | draft — middle |
  | #1662 | `analyze-audit-resolution` | d95194af | `modeled-c-d66-curl` | draft — top |
  | #1649 | `josh/float-round-trip` | 302def9f | main | **not ours** (a contributor's) — do not touch |

## 2. Rules Eric gave (binding; not all in CLAUDE.md yet)

- **Stacks.** Dependent PRs are a real `gh stack` (`gh stack link --base
  main <bottom> … <top>` by PR number; extension installed). Never
  `gh pr edit --base`. `gh stack link` cannot insert mid-stack: `gh stack
  unstack <stack#>` then re-link. Push each rebased layer with
  `git push --force-with-lease origin "${sha}:refs/heads/${branch}"`
  (braces!). Eric merges with `gh stack merge <top> --squash`; a single
  PR with `gh pr merge N --squash`. Branch protection: PR required, zero
  approvals — you may merge a main-red fix and blessed docs yourself;
  everything else Eric merges.
- **Fold before the battery; never trickle.** Everything landing in the
  same window = ONE stack → ONE battery → ONE merge command. Don't start a
  battery while another layer is expected; when a battery goes red, fix
  everything it found and re-run once. Max 2 concurrent batteries, and two
  concurrent `:test` phases double each other's wall time.
- **Batteries.** Always include `:drop-audit :move-audit`; cold c_import
  cache via `WITH_CIMPORT_CACHE_EPOCH=<unique>`; `rm -f
  out/stage/lib/embedded_objects.o` after a rebase; `ln -sfn ~/with/.deps
  .deps` in every new worktree (a missing link fails `build` in seconds).
  A rebase may merge without a re-battery only if `git diff <old-base>
  <old-head> | git patch-id --stable` is unchanged; after a stack merges
  onto a *different* base than it was tested on, main needs its own
  battery before `:install-user` (the D49 gate refuses otherwise).
- **Reseed** after a squash-merge: in `~/.local/with-staging/main-battery`
  detach at `origin/main`, `cp ~/with/src/main src/main`, `src/main
  build`, `src/main build :install-user` alone, `~/.local/bin/with
  --version`. If refused ("no published green"), run the full battery on
  main and then `:install-user`. Then confirm the installed build drives
  the runner: `rm -f out/.build-state/build-runner*; ~/.local/bin/with
  build :spec-inventory-check` must NOT print "build runner compile
  failed". If `--version` is SIGKILLed with identical bytes → #1599, run
  `:install-user` again.
- **Seed cut** (after a merge that the seed can't build, or to retire an
  accommodation): publish `nightly-<yyyymmdd>-local-1-<sha12>` with
  `with-darwin-aarch64` + `.sha256` + `.provenance` sidecars (copy the
  format from `gh release view nightly-20260925-local-1-fa33bda543c2`),
  bump `seed.lock` (version + darwin digest), `with run
  tools/bump_seed_pins.w`, fetch with the OLD seed (`~/with/src/main build
  :seed`), commit lock + `.github/workflows` pins, PR, then run the full
  battery on that branch **driven by the new seed** — green validates it;
  Eric merges; then `~/with`: `git pull && with build :seed`. The
  reseed gate now refuses a candidate whose runner compile falls back —
  never publish a seed that fails it (a 09-24 seed was published and
  withdrawn for exactly that).
- **Seed ≠ release** — never tag `v*` unless Eric says release.
- **Represent Eric to agents.** Answer agents' stop questions from the
  ruling/spec/decisions; escalate only real conflicts or genuine gaps, with
  a four-part brief (what the others do — verified in `.reference/` / what
  the spec says, quoted / mission fit / committed prediction). A
  compiler restriction the ruling never stated is not a gap (e.g. #1644).
- **Blessed = land it.** When Eric blesses words ("blessed", "as written
  with one addition", "rule (A)"), open the docs PR, run `with build
  :spec-inventory-check`, merge it yourself, start implementing. A new CLI
  command needs a spec-ahead row in the inventory lane
  (`build/compiler.w` `comp_known_missing_command` + the known-lines
  table) until it's implemented.
- **D65 — one owner per fact** (in CLAUDE.md): Sema decides what, MIR
  where/when, codegen how; no stage re-derives another's answer; fix bugs
  by moving the answer to its owner. Plan: `docs/mir-sema-hardening.md`.
- **Never**: git stash; python/perl/sed/awk (With one-liners, the Edit
  tool, or a With script); -O0; weakening a check; editing UAT/example/
  blog programs to go green (a §66-style rewrite under a spec ruling is
  the only sanctioned change, and every line must be what an app
  developer writes); `unsafe` in user programs; touching another agent's
  or contributor's work (#1649). Commit as `git -c user.name="Eric
  Hartford" -c user.email="eric@quixi.ai"`. `SDKROOT=/Library/Developer/
  CommandLineTools/SDKs/MacOSX15.4.sdk`. CI is not a signal (D56).
- **Priority after this stack:** `with uat` (#1659) + #1644 + #1652 as one
  batch; then STC — `docs/stdlib_sourcing_plan.md` phase 3 (Eric: don't
  let another canary become a campaign before STC ships).
- **Subagents** die on rate limits and model/account switches (5 times
  this week); worktrees survive; the harness may refuse to resume one —
  start a fresh agent on the same worktree with the state from this file.

## 3. Rulings landed this week (spec leads; compiler chases)

| Decision | What | Status |
|---|---|---|
| D58–D61 | let-else, `ok CONST`, tail assignment, Debug | on main |
| D62 | closure captures by place regardless of Copy; three views; `move ‖` owns env | on main |
| D63 | one callable type `fn(A)->R`, not Copy, call-once, views flow like `&T` | on main |
| D64 | `buffer param P len\|capacity param L [inout]` (bytes; `usize` result; caller slice untouched), `param N fixed <lit>` | on main |
| D65 | one authoritative producer per semantic fact | on main (doctrine) + `audit:resolution` in #1662 |
| D66 | discriminated variadic contracts (`variadic param N selected by param P:` + `case`); borrowed record views `returns borrow T from domain D\|param N`; `static` stays CStr-only | spec on main; compiler in #1661 |
| D67 | `with uat` acceptance scenarios (§18.5d); `with init` scaffolds `uat/hello.uat` | spec on main; compiler = #1659 (not started) |

Open items needing Eric (ask once, one line each):
- **#1533** `..rest` binds a view (spec line ~4244). Proposed: view.
- **#1587** `str[a..b]` is the substring view (today an invalid-MIR BUG).
- **Field-level facade facts** for pointer fields of a borrowed record
  (D66 deferred it; spelling like `record T field version CStr from self`).
- Unwritten briefs: #1431, #1564, #1482/#1497/#1502.

## 4. In flight — exact state

### 4.1 Stack #1664 (main → #1656 → #1661 → #1662) — battery red on ONE fixture; fix not started
- **#1656** `sema-field-move-path` (4ec85d78, worktree `fieldpath`):
  `FieldMovePath` record replaces an i64 with a 16-bit packed start —
  `field_move_path_for_expr` overflowed past the 65,536th field path and
  the move query read a stale path → false "use of moved value" whose
  verdict depended on unrelated source text (the real #1631/#1634 cause).
  Sema move-check change → it is why this stack runs `:move-audit`.
- **#1661** `modeled-c-d66-curl` (0085bfe6 on origin — the `mc-curl`
  worktree is at the STALE pre-rebase 02af8e34; `git fetch && git reset
  --hard origin/modeled-c-d66-curl` before using it): D66 variadic
  contracts (rendered `<name>__<CONST>` methods over the still-variadic
  declaration; Sema retargets by the compile-time selector), record views
  (`Option[&T]`), `c_import` `typedef void H` → `type H = c_void`,
  `lib/facades/libcurl.w` (Easy resource, `setopt` 9 cases, version record
  from `domain version_info`, `curl_version`/`curl_easy_strerror` static),
  `build/release_uat_fixtures/libcurl_main.w` 8 → 0 `unsafe`. Its own
  duplicate of the packing fix was dropped in the restack; **one
  accommodation commit** copies instead of field-moving in `src/main.w`
  `run_cli` because the pinned seed still has the bug — **delete that line
  in the first PR after the next seed cut.**
- **#1662** `analyze-audit-resolution` (d95194af, worktree `audit-res`,
  clean): `src/AnalysisResolution.w`, `audit:resolution` in `audit:all`
  (every MIR callee + argument count agrees with Sema's resolution), the
  #1639 validator (`mir_validate_call_callee_known`), planted fixtures in
  `test/internals/`, `MirBody.elided_call_nodes`. Zero violations on
  1218 behavior fixtures, `src/main.w`, `build.w`.
- **Battery** (worktree `fold2`, checkout `s1664-battery` = d95194af, logs
  `fold2/out/logs/`): build, fixpoint, drop-audit, move-audit **green**;
  `:test` **red on one fixture**: `test/behavior/behav_c_va_list_target_abi.w`,
  step "indirect ABI audit for darwin_aarch64": `with analyze src/indirect.w
  audit:all --target=darwin_aarch64 --no-prelude` → `panic: index out of
  bounds`, where `indirect.w` is `pub unsafe fn indirect(cb: extern "C"
  fn(c_va_list) -> i32, args: c_va_list) -> i32: cb(args)`. Isolated: only
  `audit:resolution`, only under `--no-prelude` (with the prelude it is
  `violations=0 ok`; `audit:calls`/`audit:mir` fine). Diagnosis: a table
  in the resolution collector (`sema_callable_syms`, `intrinsic_fn_syms`,
  a signature/snapshot index) is sized or keyed by prelude symbols and
  indexed unconditionally. **Fix on the #1662 layer** in `audit-res`:
  bounds-check (an audit must report a violation/BUG line naming the
  fact, never panic), make `--no-prelude` work, add a `--no-prelude`
  planted fixture, verify `behav_c_va_list_target_abi.w` passes (it runs
  the release binary through `test/behavior/lib/pre_d_build_runner.w`, so
  `with build` in the worktree first). Push `--force-with-lease origin
  HEAD:analyze-audit-resolution`, then re-run the full battery on the new
  top in `fold2` (§5 command), post the verdict table on #1662, `gh pr
  ready 1656 1661 1662`, Eric: `gh stack merge 1662 --squash`.
- **After merge:** main battery (the stack was tested on c18fdfea-era
  main + docs; patch-identical-rebase rule applies) → `:install-user` →
  seed cut (retires the accommodation and the seed's 16-bit bug) → close
  #1631, #1634, #1639, #1635 (if still open), #1621/#1624 (landed in D64),
  #1376 once `:user-programs-safe` is green (see 4.2).
- Issues filed by these agents: #1652 (callback/retained variadic cases —
  `CURLOPT_WRITEFUNCTION`/`POSTFIELDS`), #1653 (`<pwd.h>` translation),
  #1654 (build graph marks a stale output fresh when an input changes
  mid-action), #1655 (view invalidation flow-insensitive on returning
  branches), #1663 (pre-existing red `behav_c_facade_libc_system_headers.w`
  under stage1 — std.re `memchr` vs the #379 wrapper, also #1485).

### 4.2 `:user-programs-safe` — one file left
All four release UAT fixtures are at 0 `unsafe` once #1661 lands. The gate
stays red only on `examples/c-interop/src/tally.w` (4 `unsafe`): `tally_each`
is a *free function* taking a callback, and stage 9 only allowed callback
contracts on resource methods (#1644) — a stage-9 derived restriction, not
a ruling (§16.2b.9 and ruling §44 don't restrict it). Also element-count
buffers `const int *values, int count` (#1643; D64 is bytes-only — this
one IS a ruling question: does the D64 clause generalize to `[]T` with an
element count? Brief Eric with a prediction of yes). Fix #1644 in the next
batch; the gate goes green when both land.

### 4.3 Next batch (after #1664 merges and the seed is cut)
One stack, one battery:
1. **#1659 `with uat`** — plan `docs/uat-plan.md` (product feature:
   `src/Uat.w`, `with uat [<scenario>] --list --keep --record-images`,
   `WITH_UAT_WITH`, `requires:` probes, verdicts pass/skip/fail, `expect
   (human):`; `with init` writes `uat/hello.uat` + `uat/README.md` via
   generated templates; migrate the nine `build/release_uat.w` actions to
   `uat/*.uat`, `build/release_uat_fixtures` → `uat/fixtures`,
   `release-uat` target re-wired, `user-programs-safe` re-pointed; #1375
   closes via `requires: display`). Remove `uat` from the spec-ahead table
   in `build/compiler.w` when the command exists.
2. **#1644** callbacks on free functions.
3. **#1652** callback / retained variadic cases.
4. Optionally #1643 after Eric's yes.

### 4.4 Then STC
`docs/stdlib_sourcing_plan.md` phase 3 (the `Vec` engine, default
HashMap/HashSet, Deque/Stack/Queue/PriorityQueue/List, OrderedMap/Set,
BitSet, spans, `sort`, searches; #937–#940), then phase 4 M\*LIB. Migrate
whole libraries with the migrator (`docs/harden_migrate.md`); fix the
migrator, never hand-edit output.

### 4.5 Hardening (D65) phases after phase 1
`docs/mir-sema-hardening.md`: phase 2 codegen mode provenance (the `&fn`
marshalling class), phase 3 places, phase 4 effects, phase 5 MirLower
cleanup after STC. #1631's second face (one stage1 binary gives different
answers for `src/main.w` via `check` vs the generated `out/gen/main.w`)
is explained by the 16-bit bug (text-dependent verdict) — re-verify after
#1656 lands and the seed is cut, then close.

## 5. The battery command (per worktree)

```
cd <worktree> && ln -sfn ~/with/.deps .deps && cp ~/with/src/main src/main
rm -f out/stage/lib/embedded_objects.o
export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk WITH=$PWD/src/main WITH_CIMPORT_CACHE_EPOCH=b<tag>-$(date +%s)
rm -rf out/logs && mkdir -p out/logs
for t in "" ":fixpoint" ":drop-audit" ":move-audit" ":test" ":test-green" ":last-green"; do
  src/main build $t > out/logs/battery${t//:/_}.log 2>&1; rc=$?; echo "<tag> ${t:-build} rc=$rc"; [ $rc -ne 0 ] && break
done
rg -n "target failed|target '.*' failed" out/logs/battery_test.log | rg -o "'[^']+'" | sort -u
```
Run it in the background; never pipe `with build` through `tail`/`time`.
Red detail: `out/test-graph/<target>/<file>.stderr`; a kept test binary
reruns with `WITH_TEST_SHORT=1 <path>`. Known false reds:
`behav_c_import_scales_linearly` under load, a warm c_import cache,
stale `embedded_objects.o`, a missing `.deps` link.

## 6. Agent brief shape (what worked)
Exact worktree setup (`git worktree add ~/.local/with-staging/<name> -b
<branch> origin/<base>`; `cp ~/with/src/main src/main`; `ln -sfn
~/with/.deps .deps`; `with build :dev`; then
`out/bootstrap/bin/with-stage1` or `out/stage/bin/with-stage1`); canon to
read in order (ruling → plan → prior diffs → spec); scope verbatim;
decisions already made (incl. the inference test "what happens if this
inference is wrong?" and D65); iterate-tier verification only (fixtures,
`analyze audit:all`, stage1 `check src/main.w`, targeted corpus targets,
`:dev`; the debug-alloc lane and `contract-view-tests` allowed; never
`:fixpoint`/`:test`/audits); ONE draft PR, no stack link (the coordinator
folds); report PR/SHA/fixtures/derived decisions/left-undone; "file,
don't fix" for out-of-scope bugs; name off-limits worktrees; migration
scripts must run over EVERY test lane (`test/behavior`,
`test/compile_errors`, `test/phase`, `test/debug_alloc`, `test/spec`,
`test/contract`, `test/*.w`) — 12b missed three lanes and cost two
batteries; generated files (`src/InitTemplates.w` from
`docs/with_for_ai.md` via `tools/gen_init_templates.w`, run with the
stack's `out/release/bin/with`) must be regenerated when their source
changes.

## 7. Worktrees (`~/.local/with-staging`)
`main-battery` (reseeds; detached), `fieldpath` (#1656), `mc-curl` (#1661,
STALE — reset before use), `audit-res` (#1662, clean, where the next fix
goes), `fold2` (battery checkout of the stack top). Remove `fieldpath`,
`mc-curl`, `audit-res`, `fold2` after the stack merges. Ignore
`~/.claude/jobs/…/mainck` (a job tmp). A `git worktree remove` that fails
with "File name too long" needs `rm -rf <dir>; git worktree prune`.

## 8. Traps hit this week
- `s[2..]` on `str` (#1587) → `.slice(a, b)`; `/re/.replace` first match
  only (#1607); `JsonView` has no array indexing; `nr` is an int in
  `with -n` (use f-strings); `with check` refuses top-level statements
  after fns — use `fn main` for check/dump flags; `zg query --rg` refuses
  `-l`/`-o`; fish/zsh: `$sha:refs` in a refspec must be `${sha}:refs`;
  `with -n` over a 25k-line file is slow — use Read with offset/limit.
- Facade facts are collected (`SemaDecl` `collect_c_facades`) BEFORE
  `ci_syms` is filled — use `decl_is_c_import` for "is this a c_import
  translation" at facade-verification time.
- The OLD seed segfaults running `tools/gen_init_templates.w`; use the
  current release binary.
