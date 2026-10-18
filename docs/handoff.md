# Handoff — 2026-10-18 (evening): #2449 pools fixed (PR #2453 → main c98c84156), D22/D44 compliant (PR #2451 → 809561fc6), D120 Amendment 2 (#2450); the decisions still to implement

Read this section first; everything below "0-prev." is the archive of
earlier windows and is superseded where it disagrees.

## 0. Where the work stands

**Main is c98c84156.** Three merges this window, in order:
- **#2450 → 88c6fc333 (docs):** D120 Amendment 2, Eric verbatim "raise the
  bar to 5%": the record's "what would reopen it" is the 5% merge bar, not
  the ruling's 2%; the decision-log index line follows.
- **#2451 → 809561fc6:** the other agent's uncommitted `noncompliance-stack`
  worktree, reviewed and split into four commits: D118 aarch64 seeds (cut
  from 3d73b98c; the Linux one bootstrapped natively in docker to a 16-unit
  fixpoint + `:no-host-toolchain`, the Windows one cross-built here; the
  Windows cross link needed `with_clang_main`), D44 extraction copy glue +
  the audit (#1159), D22 compliant with all 66 `test/non_compliant/d22`
  fixtures promoted (the agent had deleted one instead of promoting it;
  restored as `err_d22_raw_pointer_not_contextual_copy`; the promoted
  fixtures' NON-COMPLIANT headers rewritten; the AI guide header and its
  generated template updated), D100 pub_lint one pass (#2211; its two
  `.clone()` on value lists dropped). Battery 489 s. **CLAUDE.md no longer
  calls the compiler NON-COMPLIANT for D22 or D44.**
- **#2453 → c98c84156:** #2449. `InternPool`/`AstPool` are counted handles
  (holder count in the state block, `clone()` another holder, `Drop`
  releases, the last frees tables/maps/arena pages); Copy removed; 428
  signatures take `&InternPool`/`&AstPool`; keepers store clones; the
  parser holds the caller's intern pool (no `x = parser.intern`
  hand-backs); backend seams give codegen clones; `take_pool`/`take_intern`
  and `src/compiler/foundation/InternPool.w` removed; arena pages start
  strings at offset 16 (a page-start str read as an owned allocation to
  `rt_payload_start_is_owned`). Pins: `test/debug_alloc/
  da_2449_pools_free_on_last_drop.w` (main's pool: leak count=283/286) and
  `lsp-memory-flat` in `cli-selfhost-lsp-tests` (new `with/memory` LSP
  request → runtime committed bytes; <1 MB growth over 50 edits; main's
  server: peak RSS 45 MB @40 edits, 126 MB @200; now flat 24 MB).
  Self-host A/B vs 809561fc6: 0.962–0.976 (faster). Branch battery 333 s
  on 263d45e2f; **the squash landed on top of #2451, so main's combined
  tree got its own battery in reseed-main
  (`~/.local/with-staging/main-battery-c98c84156.log`, GREEN, 520 s)**, installed
  (generation c4cd9285…, `reseed-c98c84156-install.log`).
  Ceremony: `clone-call src` granted 537 → 558 (the explicit second-holder
  spelling; the single-owner restructure, one pool per compilation with
  every phase borrowing it, removes them — Sema/Codegen would become
  view-holding types; not started).

**Filed:** #2452 — the build-graph cache key hashes build.w/build/ but not
the directory listings build.w enumerates (`list_files("src")`): a deleted
source file fails loudly ("missing declared input"), an added one is
silently not an input of `compiler-no-c-export` until the cache dies.
Workaround `rm out/.build-state/build-graph.cache`.

**Open for Eric:** the remaining ~3% D120 self-host cost is now under the
reopening threshold (Amendment 2), nothing owed; the single-owner pool
restructure above is a scope call.

**Traps this window:** the Bash tool's `=`/`===` as an echo separator is a
zsh glob error that aborts the chain; `use InternPool` in a probe program
resolves to the *current directory's* `src/InternPool.w`, so a "main
compiler" probe run from a worktree tests the worktree's source; the
compiler process exits via `exit(run_cli())` and never prints the
debug-allocator leak report (only programs do, through
`with_runtime_shutdown`); editing a worktree while its gate runs
invalidates the gate (the guard hook only blocks under a battery).

## 1. The decisions still to implement, in the record's order

1. **D120** — done (stages 1–6, measured, Amendment 2). Microbenchmarks
   tracked in `test/benchmark/cow_value_lists.w`.
2. **D118 aarch64 seeds (#2305)** — the seeds are cut and pinned (#2451);
   the GitHub lanes run nightly; check `linux aarch64` / `windows aarch64`
   lanes go green on the next run (they are post-hoc, D56).
3. **D123 — std.mssql, clean-room.** Not started (`mssql-cleanroom.md`).
4. **Standing items:** D30 (runtime in-unit; rt objects as cache —
   "TRANSITIONAL" in CLAUDE.md), D104's comptime allocator follow-up
   (#2220), #2452 (build-graph cache listings), the pool single-owner
   restructure (#2449 follow-on, Eric's call).

## 2. Standing rules for this work (unchanged)

Pinned seed `nightly-20261015-local-1-efcb91c30a6a` drives everything
(`WITH=$PWD/src/main src/main build …`); fresh worktree: `git worktree add
~/.local/with-staging/<n> -b <n> main`, `cp
~/.local/with-staging/reseed-main/src/main src/main`, `.deps` symlinks to
`~/with/.deps/llvm-22.1.6-darwin-arm64{,-release}`, `with build :dev` before
anything. Read gate/build/battery logs only via `with run
~/.claude/hooks/verdict.w <log>` (`--times`, `--progress`, `--detail
<needle>`); the guard hook blocks the rest. Hold the Mac awake for long
runs (keep_awake) and release after. With-only tooling; `with -p` with
`/re/.replace(line, …)` (not `line.replace(/re/…)`, #2434); the Bash tool
runs zsh (a failed glob aborts the whole `&&` chain — the trap that cost
one battery this window). Commit as `Eric Hartford <eric@quixi.ai>`, one
logical change per commit; never `git stash`; never cite an unprinted
hash. Order: `:dev` + targeted tests → `src/main build :gate` (+
`:debug-alloc-tests --no-deps`, `:drop-audit --no-deps`,
`:deep-debug-tool-tests --no-deps` after a MirLower/codegen change; they
need the gate's `out/release/bin/with`) → `with run
tools/ceremony_census.w --diff HEAD` and the full census → `with run
tools/battery.w` → post → `gh pr ready` → merge → reseed → install → pull
→ remove worktree. Only Eric blesses normative spec wording; a ruling that
breaks a fixture updates the fixture in the same change and says so.

**Hunt tools that paid off this window:** `WITH_KEEP_BITCODE=1` +
`.deps/…/bin/llvm-dis` + a per-function IR line table, diffed main vs
branch; standalone `opt -O1` / `llc -O1` on one unit's `.bc` to split
"the IR" from "the compiler"; `WITH_PROFILE=1` (`llvm.unitN` times);
`--dump-mir` filtered to one body (count `+retain`, `drop(`);
`WITH_TRACE_COW_COPIES=<bytes>`; `ps -o rss=` polling a build for peak RSS.


## 0-prev. The 2026-10-18 morning handoff (D120 merge-gate measurement, PR #2448)

(was: D120 stages 1–6 merged and measured (PR #2448 → main a82424d25, reseeded and installed); the decisions still to implement

Read this section first; everything below "0-archive." is the archive of
earlier windows and is superseded where it disagrees.

### 0. Where the work stood

**Main is a82424d25** (PR #2448, below), reseeded in `~/.local/with-staging/reseed-main` (detached at a82424d25; `reseed-a82424d25-{build,install}.log`), installed (generation 48d78d9a…), `~/with` fast-forwarded. Before it, since the 2026-10-16 handoff, another agent merged, in
this order: D120 stage 3 (PR #2442, squash e38e86f02), stage 4 (PR #2444,
merge commit a47fce2b2 over df583a52a: the uniqueness proof, loop
hoisting, wider last-use takes), stage 5 (PR #2445, merge commit over
40402de2a: C-boundary make-unique, per-instantiation generics, `with
analyze file.w cow`), stage 6 (PR #2446, squash 5b4939669: the `.clone()`
sweep, `test/benchmark/cow_value_lists.w`, plus a MirLower tail-view fix
and a `validate_read_after_drop` extension), and #2131 wasm32 bundles (PR
#2447, squash 3d73b98cd). Every tip has a green-store row
(`~/.local/with-green/green.tsv`: 813f412d2, df583a52a, 40402de2a,
f19fe59f9), so a battery reached `:test-green` on each. 
**What that agent did not do (2026-10-18 review):**
- The A/B each stage posted was against the previous main, so the ratios
  compound: stage 1 1.024–1.032, stage 2 1.003, stage 3 1.034, stage 4
  1.0415 (the stage meant to recover stage 1's cost made it slower),
  stages 5 and 6 none posted. Measured 2026-10-18 against the last
  pre-CoW compiler (60693617b, release build in
  `~/.local/with-staging/pre-d120-base`): `check src/main.w` rounds
  1.1045, 1.1449 clean (a third round was perturbed by a stray process);
  the clean re-run and the `WITH_PROFILE=1` phase profiles of both
  compilers are in `~/.local/with-staging/ab-main-vs-pre-d120-selfhost-2.log`
  and `profile-{pre-d120-base,d120-cow4}.log`. The ruling's "what would
  reopen it" is >2% not removable; Amendment 1's merge bar is 5% per
  interleaved A/B. Eric has not yet been briefed with the table; that
  brief, with the profile's phase deltas, is the next thing owed.
- The pcre2 and zlib corpus suites were never A/B'd. `tools/corpus_ab.w`
  (branch `d120-take-sema`, worktree `~/.local/with-staging/d120-take-sema`)
  now does it: `with run tools/corpus_ab.w <base> <cand> 3 pcre2|zlib`
  builds `lib/std/re/pcre2test.w` / `lib/std/zl/minigzip.w` with each
  compiler and times RunTest -8 0-29 / a 16 MB minigzip round trip.
- PR #2445's description cited `battery.w --local-only`, a flag that does
  not exist; corrected on GitHub 2026-10-18 (the green row is real).
- Stage 3's `comptime_take_sema` (the evaluator takes the Sema instead of
  a retained copy; 1,908 >64 KB copies per self-check at stage 3) was
  uncommitted when the agent took over and was dropped. On today's main
  `WITH_TRACE_COW_COPIES=65536 with check src/main.w` already reports 0
  copies (stage 4's proof covers it), so it is now a clarity change, kept
  on `d120-take-sema` with the corpus tool.
- A `with check` of a file with an inline `(match e: { A => x, B => y })`
  expression spun at 100% CPU for minutes instead of a diagnostic
  (2026-10-18, installed compiler = main). Not yet reduced or filed:
  reduce it (`with reduce`) and fix or file before the next merge.

**In flight by the other agent (do not touch without checking `ps` for a
live claude process):** `~/.local/with-staging/noncompliance-stack`
(branch `noncompliance-stack`, uncommitted, ~88 files): the D22/D44
promotion (test/non_compliant/d22 fixtures moved to test/behavior,
CLAUDE.md/AGENTS.md paragraphs rewritten to "implemented"), D100's
`tools/pub_lint.w`, compiler edits in SemaCheck/CodegenDispatch/
ComptimeEval/Analysis/InitTemplates, and a `seed.lock` bump to a
linux-aarch64 seed cut from 3d73b98cd (D118). It needs splitting into
logical commits; the CLAUDE.md compliance rewrite needs Eric's reading
before it lands.

**PR #2448 (merged 2026-10-18 as a82424d25; battery GREEN 229 s on 1e087af04):** the regression's cause at
the line and its fix (the last-use pass drew a view edge for an integer
copied out of a list; `WITH_TRACE_COW=1` now prints `[cow-last-use] …
taken / kept, <why>` per site), the drop guard word-wise, the uniqueness
dataflow's arrays per candidate, the comptime evaluator taking the Sema,
`tools/corpus_ab.w`, the parser hang fix. Self-host 1.093 → 1.032 against
the pre-CoW compiler, pcre2 0.966, zlib 0.992 (table on the PR). Reseeded, installed, worktree removed. `~/.local/with-staging/pre-d120-base` (detached at 60693617b, release built) is the pre-CoW baseline for any further A/B; remove it when D120 measurement is closed.

**#2449, found 2026-10-18, Eric's call on scope:** `InternPool` and
`AstPool` are `impl Copy` handles over raw allocations (a 1 MB arena page
each) that nothing frees; every `InternPool.init()` leaks, and the LSP calls
it on every reparse. The fix is ownership (resource types with Drop, one
owner per compilation, borrows everywhere else): hundreds of signatures.
Until then no new `InternPool.init()`/`AstPool.new()` outside the one
creation site per compilation.

### 1. The decisions list as of the morning

1. **D120 — collections and structs of values are values (#2304).**
   Plan: `docs/proposals/d120-implementation-plan.md`. All six stages are
   merged. Open: the merge-gate measurement the plan owes (self-host and
   the two corpus suites against the pre-CoW compiler, above), Eric's
   ruling on the held cumulative cost, and whatever that profile says is
   removable (`WITH_TRACE_COW=1` prints each kept uniqueness check; `with
   analyze file.w cow` reports them per program). D120-adjacent and still
   open: #2406 (`impl Copy` ordering), #1137 (views compared by address).
2. **D118 — the aarch64 seeds (#2305).** A linux-aarch64 seed cut from
   3d73b98cd is in the other agent's uncommitted `seed.lock`; the
   windows-aarch64 seed is not. Hosts: `ssh eric-5090`, `ssh win10`.
3. **D123 — std.mssql, clean-room.** No FreeTDS source; Decimal over i128;
   memory `mssql-cleanroom.md`. Not started.
4. **#2131 — wasm32 bundles:** merged (PR #2447). Verify the release
   carries them at the next release.
5. **The standing NON-COMPLIANT paragraphs (D22, D44, D30, D100 #2211,
   D104 #2220):** the other agent's branch claims D22/D44/D100 done; verify
   each against its acceptance matrix before the paragraph is rewritten.


## 0-archive. D120 `resource type` merged: PR #2438 → main 007fdb2c3 (2026-10-16, battery 285 s idle); main's own battery + install in `~/.local/with-staging/main-battery-007fdb2c3.log` / `reseed-007fdb2c3-install.log`

The copy-on-write half of D120 is in progress: the plan is
`docs/proposals/d120-implementation-plan.md` (merged, #2439 → 60693617b);
stage 1 (a List of values is a value) is built on branch `d120-cow1`
(`~/.local/with-staging/d120-cow1`, pushed) and its **battery is green**
and **merged as PR #2440 → main 1a69c26f3** under Eric's amended 5% bar
(D120 Amendment 1; self-host check measured 2.4% and 3.2% slower, the
uniqueness check at every mutation; stage 4's proof and hoisting is the
optimization). Main's battery + install:
`~/.local/with-staging/main-battery-1a69c26f3.log`,
`reseed-1a69c26f3-install.log`. **Stage 2 (a HashMap or HashSet of
values is a value) merged as PR #2441 → main 16fbd064f** (2026-10-16;
battery GREEN 286 s; self-host A/B median 1.0028, noise; reseeded and
installed from the merge: `reseed-16fbd064f-{build,install}.log`; the
count lives in the table block at HM_OFF_HOLDERS, `with_hashmap_make_unique`
copies a shared table and codegen retains its entries). Still owed for
D120: stages 3–6 of the plan (BTreeMap/BTreeSet follow stage 3's struct
rule) and the pcre2/zlib + microbenchmark measurements. Memory
`d120-cow-campaign-2026-10-16.md` has every piece and lesson. Then D118
aarch64 seeds (#2305), D123 std.mssql, #2131 wasm32.

## 0a. D121 step 6 merged: PR #2436 → main 5d04731e0 (2026-10-16); reseeded and installed (`~/.local/with-staging/main-battery-5d04731e0-2.log`, `reseed-5d04731e0-install.log`)

Battery green on 69bd5749c at 868 s, measured under a host load of 33–45
(a Virtualization VM at ~14 cores and a Python job of Eric's): not
comparable to #2432's 437 s; the UAT phase alone on the idle host took
267 s (libcurl 94 s, sdl 79 s, libxml2 37 s, raylib 34 s). An idle-host
battery is owed before `battery-time.md` gets a row. Next in the record's
order: D120 CoW (#2304), D118 aarch64 seeds (#2305), D123 mssql, #2131.

### What the branch was

Main is 92d47d7b0 (334c8f010 = step 5, plus the §16.2b.15 words Eric
blessed 2026-10-16, PR #2433 docs-only). The branch (four commits, rebased
on main) adds `uat/libxml2.uat` + `uat/fixtures/libxml2_main.w`: `with get
c.libxml2`, then `use facades.libxml2` parses, walks, reads attributes and
content; no hand facade, no `unsafe`. Verified with stage1 in the
scratchpad before the battery ("libxml2 UAT passed"; `with get` 25 s, the
program's build 47 s, down from 226 s). What it took is in the PR body and
in memory `d121-step6-libxml2-2026-10-16.md`: the engine's list-walk
proof, modeled-record fixed point and presentability rule (mirrors Sema's
`facade_op_raw_beyond`), the registry's shape facts (`nullable param`,
`text param`, `text return … freed by F`, facade-level `text utf8`;
`registry/c/libxml2/facts.w`), `freed by` through a global function
pointer (`xmlFree`), `Option[&str]` for a nullable C string, camel-case
shortening, the c_import macro-calls-unsafe-macro fix, and the renderer's
per-pool indexes (`AstPool.shape()`), which took the UAT program's check
from 194 s to 39 s. `with uat` now sets `WITH_REGISTRY=file://<root>`.
Gate log `~/.local/with-staging/d121-libxml2-gate1.log`; then
`:c-migrator-basic-tests --no-deps`, the full ceremony census (needs
out/release), `with run tools/battery.w`, post, ready, squash-merge,
reseed. Filed #2434 (one-liner regex replace BUG). Known stage1-only red:
`behav_c_facade_pending_producer_warns.w`.

Then, in the record's order: D120 CoW (#2304, merge gated on 2% self-host
and corpus), D118 aarch64 seeds (#2305), D123 std.mssql, #2131 wasm32.

## 0-old. D121 step 2, branch `d121-proof` (merged 2026-10-15 as #2420)

Eric asked (2026-10-15) to continue implementing the remaining decisions.
The record's order: D121 steps 2–6, D120 (#2304), D118 aarch64 seeds
(#2305), D123 mssql. Step 2 is built: `with migrate --facade NAME
<dir|file.c>` (`src/CiFacadeDraft.w`; the walker
`ci_body_ownership_evidence` in `CImport.w` beside D107's; the flag in
`main.w`; `migrate_c_facade` in `CiMigrate.w`). Proofs are a corpus fixed
point: retention, destruction, then returns (owned / borrow-from-param);
the draft pairs producers with the one unary destroyer per representation,
states proven borrows and lends, and the report says why the rest is raw.
Spellings are D133 (delegated). Test: `migrate-facade-by-evidence` in
`build/selfhost.w` (the draft is compiled against its header). Docs:
`docs/spec/toolchain/with-migrate-spec.md` "Usage", the D121 doc's status.
`WITH_DEBUG_MIGRATE_FACADE=1` prints every definition's evidence.

Measured on real zlib 1.3.2 (library units only): 108 declared functions,
15 safe, 93 raw; `gzopen` proven owned, `gzclose` a destroyer, but zlib has
three unary destroyers of `gzFile_s` (gzclose, gzclose_r, gzclose_w), so
the draft reports it for the registry rather than pick. `z_stream` is an
in-place resource (deflateInit_/deflateEnd), outside pointer-producer
proofs: raw with reason. **Merged: PR #2420 → main 0b7f0cbe4** (battery
green, 332 s, `~/.local/with-staging/d121-battery1.log`; the first gate was
red on spec-inventory — `--facade` is a migrator flag, listed internal in
`build/compiler.w` — and on ceremony-census — four `&x` at `&T` params,
dropped). Reseed from 0b7f0cbe4 in `~/.local/with-staging/reseed-main`
(`~/.local/with-staging/reseed-0b7f0cbe4.log`); `~/with` fast-forwarded.

**D134 (ruled and blessed verbatim 2026-10-15, spec v7.34, main 8aba76b75)**
closed the three facade-language questions: a borrowed value's origin is
per call (one `BorrowedR[Origin]` type), `detaches param N` yields an
owned `DetachedR[Origin]` dependent on its origin (verified in libxml2
2.15.4 tree.c: xmlUnlinkNode keeps node->doc; xmlFreeNode reads
doc->dict), and `text utf8` at the facade level with `text return bytes`
per item, validated at the boundary, a violation panics naming the C
function. Conformance branch `d134-impl` (`~/.local/with-staging/d134-impl`,
commits ce2bff93c, 56db43712, 9dd8568fa): renderer, Parser, Sema, tests
(behav_c_facade_borrow_per_value_origin, behav_c_facade_detaches,
behav_d134_text_utf8, …_violation_panics), the engine now drafts every
proven borrow. First battery was red on two invalidation pins: a borrowed
view's methods are generic, so facade lookups by `BorrowedR.m` found no
signature and an operation through a view touched nothing. Fixed in
2aa275e01: facts kept by effective name and replayed at instantiation
(`facade_note_generic`/`facade_replay_generic`, hooked in
`check_generic_method_body_concrete`); a borrow through a view views the
view's origin (a view of a view nested the type per call and hung);
`WITH_DEBUG_FACADE_POISON=1` was the tool that found it. **Merged: PR
#2422 → main 068b1ec20** (battery green, 288 s,
`~/.local/with-staging/d134-battery2.log`). #2361 (Eric's Linux-layout
PR) had merged under it, so the merged tree was not the blessed tree and
main's census was red (clone, move, ref-at-ref, str-clone over the bar):
cleaned in PR #2423 → main c24943f3f (battery 216 s), reseeded from it
(`~/.local/with-staging/reseed-c24943f3f.log`) and installed;
`~/with` fast-forwarded; both worktrees removed. The installed compiler
passes the four D134 tests and runs the engine. User code
naming a borrowed type now
spells its origin (`BorrowedDatabase[Statement]`). Under stage1 only,
behav_c_facade_pending_producer_warns fails because stage1 emits two std
warnings on every compile; the release binary does not.

**D121 step 3, Clang half, merged: PR #2424 → main 89cc63611** (battery
339 s; reseeded and installed, `~/.local/with-staging/reseed-step3.log`).
The bridge reads `__attribute__((…))` tokens (`with_cimport_fn_attributes`),
`malloc` makes an unproven return an owned producer with the provenance
`annotation:`, the report names every attribute. GObject-introspection
`.gir` transfer annotations are the step's other half, open.

**D121 step 4, the package registry: landed 2026-10-15 (D136, Eric's
"proceed" on the brief).** PR #2430 → main 7147a1d5f (battery 496 s),
reseeded and installed. `registry/c/<package>/facts.w` in this repository,
a cited facade fragment read by `with migrate --facade … --facts FILE`
(`src/CiFacts.w`; `registry/README.md` holds the review rule). One cited
fact (`registry/c/zlib/facts.w`: `drop gzclose`) takes real zlib from 15 to
35 safe functions. Open for Eric: the two package-management.md sentences
that contradict D121 (proposed replacements in the session's last report).
The two sentences were blessed ("I bless the two sentences") and merged
docs-only as PR #2431 → main b8d34af52 (2026-10-16).

**D121 step 5, `with get` writes the facade: built 2026-10-16 on branch
`d121-get` (`~/.local/with-staging/d121-get`), PR #2432 (draft), battery
running (`~/.local/with-staging/d121-get-battery1.log`).** Commits:
220c3f554 (migrator half: header per prototype, tolerant scan with the
reason in the report, `migrate_c_facade_for_package` with `use c_import`
lines), b9ef8216d (`with get`: engine over the package's CMake build via
compile_commands.json, binary packages get a configure-only pass under
`<dep>/.build`, registry facts fetched from github main at one commit with
`WITH_REGISTRY=<base URL>` override, `facade.w` / `facade-report.txt` /
`facade.json`, lock `registry` + `facts_sha256`, `use facades.<name>` →
dep facade in `src/Resolve.w`, project override by AST item surgery in
`Frontend.merge_fetched_facades_frontend`; selfhost fetched-mini case;
zlib/sqlite3 UATs expect the summary), 2914d21ba (shell escapes in
compile commands; attribute reader stops at a body), 186bbc4bd (census).
Measured `with get` wall: zlib 5 s, sqlite3 5 s, bzip2 4 s, raylib 26 s,
libcurl 62 s, sdl 59 s. **Merged: PR #2432 → main 334c8f010** (battery
437 s on c2b4cadfb; `:c-migrator-basic-tests --no-deps` green; trees
equal), reseeded from 334c8f010 and installed
(`~/.local/with-staging/reseed-334c8f010.log`); worktree removed. The
fifth commit c2b4cadfb fixed two things the first battery's migrator run
found: `use facades.<name>` imported one name (Resolve.w
`resolve_dotted_selection` took `facade.w` for the parent module) and a
project override had to join the written block (one module renders the
facade; Frontend `merge_fetched_facades_frontend` moves the project's
items in and empties its blocks). Then step 6 (libxml2 UAT over the
generated facade: libxml2 2.15.4 yields 1485 prototyped functions, 419
safe, 2 s), then D120, D118, D123, wasm32. Engine findings for step 6 are
in the memory file (self-referential local sources in loop walks;
`_xmlNode` unmodeled; `xmlReadFile` false retention; no `text return`
proof). Fidelity notes: sqlite3 amalgamation 276 functions / 22 safe
(out-params unproven: the hand facade stays), libcurl 11/152.

**The `.gir` half: landed 2026-10-15.** PR #2427 (reader) → efcb91c30,
PR #2428 (seed.lock → nightly-20261015-local-1-efcb91c30a6a) → e01266d61,
PR #2429 (the engine, battery 427 s) → ca9b47b62; reseeded from ca9b47b62
and installed (`~/.local/with-staging/reseed-ca9b47b62.log`). The record
below was written mid-flight and stays for the detail.

**The `.gir` half (2026-10-15, as it went).** `std.encoding.xml` (D135,
delegated: a strict native tree reader, not the tokenizer the stdlib plan
sketched) merged as PR #2427 → main efcb91c30. The compiler using a new
std module raises the minimum seed (the seed embeds its own std), so seed
`nightly-20261015-local-1-efcb91c30a6a` was cut on the three hosts and
published; the lock bump is branch `seed-lock-local-1`
(`~/.local/with-staging/seed-lock`), battery under the new seed in
`~/.local/with-staging/seed-lock-battery1.log`. The engine itself
(`src/CiGir.w`; the join in CiMigrate.w; the verdicts in CiFacadeDraft.w:
transfer full → owned, none → borrow of the instance or sole pointer
parameter, a `full` parameter → `consumes param N`, `free-function` → the
destroyer or the `drop` among several; a declared-only function is a
subject; the report says DISAGREES where a proof and the file differ) is
commit 9eac5a4f5 on `d121-gir` (`~/.local/with-staging/d121-gir`), its
selfhost fixture green (24 functions, 21 safe) with the installed compiler
driving `:c-migrator-basic-tests`. After the lock merges: rebase onto main,
copy the new seed to `src/main`, battery, PR, merge, reseed. GLib source
could not be scanned without its meson-generated config (a step-5 matter:
`with get` builds the package first).

Next: D121 steps 4 (per-package registry beside the Conan recipe), 5
(`with get` writes the facade and report, project overrides), 6 (libxml2
UAT), then D120, D118, D123.

## Previous: battery time, Eric's #1 priority (done)

Goal (Eric's /goal): the full battery under 10 minutes wall on this 18-core
Mac, no check weakened, skipped or moved out; keep cutting until an
iteration saves under 5%; then write the table into
`docs/spec/toolchain/battery-time.md` and here. Rules as in CLAUDE.md: the
pinned seed drives the battery; With-only tooling; `Eric Hartford
<eric@quixi.ai>`; never `git stash`; read logs only with `with run
~/.claude/hooks/verdict.w` (`--times`, `--progress`, `--detail`).

## 1. Where it stands

**Under ten minutes, officially, and the stop rule is met.** `with run
tools/battery.w` on main 592eb6602 under the pinned seed
`nightly-20261014-local-3-c411d0e45`: **390 s** on a warm worktree, **491 s**
on a fresh one (green, rc=0). The next cut tried (#2416, a critical lane's
parallel window capped at half the jobserver budget) measured 562 s fresh
against 491 s: no saving, closed unmerged. Run-to-run variance is now about
±100 s (tools-tests 170 s in one fresh run, 361 s in the next), which is the
noise floor any further cut has to clear. The table, the timeline and what
was fixed are in `docs/spec/toolchain/battery-time.md` (merged, #2415).

Main today: #2410 (tiers D131, emit-c D130, runtime by bytes D132, jobserver
lanes, CONTRIBUTING), #2411 (seed local-2 + evidence edges), #2413 (store
prune, linear listing, in-process Actions), #2414 (seed local-3).
`~/.local/bin/with` is reseeded from main; `~/with` is fast-forwarded.

Seeds published: `nightly-20261014-local-2-0da433ee8a07` and
`nightly-20261014-local-3-c411d0e45` (darwin, linux-x86_64, windows-x86_64;
`seed.lock` pins local-3). The partial prerelease
`nightly-20261014-local-1-7f81d1e6c8e9` (linux and windows only, pre-merge)
was deleted with its tag on 2026-10-15 at Eric's word.

## 2. Where 491 s goes, and what is left

`build` lands at 184 s (bootstrap 28 s → stage1 76 s → stage2 74 s); the
wall is that plus the longest test lane (emit-c-smoke 279–292 s under load,
45 s alone; it already runs its cases through `par_run`, and capping its
window changed nothing: the slowness is the whole machine's load under
every lane at once). Real levers left, each a project of its own: the 184 s
compile chain (stage1 and stage2 of the compiler itself), and the CPU the
test lanes burn (behavior-tests 1795 files, native-compile-error-tests 1742,
tools-tests, internals-tests, 150–360 s each under load).

**Determinism defect found and fixed (#2418, main baf0ac468):**
`MirLower.source_location_operand` stamped `sema.current_module_path` raw,
so every std module compiled from a checkout carried that checkout's
absolute path in each unwrap message; three releases built from identical
`src/` had three self-ids, the verdict and build stores served nothing
across worktrees, and the `.wo` store served one worktree a bundle naming
another's path. Sema now spells the path (`source_path_text`: a std module
as `<embedded-std>/…`, an absolute path by its `WITH_FILE_PREFIX_MAP`
spelling, a relative one as spelled; D38, D50, D65); MIR reads it. Proof:
36d5f43f4 built in two worktrees gives byte-identical unstamped images and
one self-id. Pin: `behav_panic_path_is_canonical.w`. `FnAbi.w` was left
untouched on purpose: it is ABI-defining and its hash keys every `.wo`.
Expected effect from here: a re-run of identical sources in any worktree
finds its passed tests in the verdict store.

Each driver change reaches the official battery only through a seed cut
(the seed is the driver): measure with a release binary built from the tree
first (`seed-driver` goes red, the rest measures), then cut.

## 3. Filed and found

- #2409 emit-c has no hash/equality for composite map keys (`emit-c-test`,
  `emit-c-fixpoint` red; pre-existing; not in any tier).
- #2412 https_fetch's connect probe has no retry (four corpus downloads at
  once all failed on the studio).
- Not filed, reduce first: `for d in deps[k]` over `List[List[str]]`
  yielding empty strings; `.parse()` unknown on `str` in `-n` scripts;
  `let out = args()[1]` needs `: str`; a `let` after an inline `if` in `-n`.

## 4. Seed-cut traps (each cost a rerun today)

- Every host's `src/main` falls behind the lock after a merge that bumps
  `seed.lock`: check its digest against the lock before `build`; install by
  `curl` + digest (`:seed` from an old seed may not compile the fetcher).
- studio128 has no `SDKROOT`; the facade tests read `sqlite3.h`, `bzlib.h`,
  `curl/curl.h` from the host SDK: run `:test` there with
  `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`.
- `screen -X quit` leaves the stage compiles running; `pkill` them and check
  `uptime` before `:test`, or tests time out (exit 124) under the load.
- Never run tests from a checkout whose `out/lib` is stale (`~/with` after a
  reseed elsewhere): the child compilers find no runtime of their generation.
- ssh to studio128 drops about one connection in three: retry loops, work in
  `screen -dmS`, poll a file for `rc=`. Sequencer: `~/seedcut` on studio128
  and eric-5090 (source `~/.local/with-staging/seedcut.w`); Windows uses
  `C:/ws7f81-launch.exe W:/ws7f81 …` over a held ssh.
- Publish from `~/.local/with-staging/reseed-main` with
  `:publish-release-asset`, darwin first; zsh does not word-split
  `set -- $p`.

## 5. Worktrees and logs

- `~/.local/with-staging/seed-bump`: branch `battery-time-docs` (this
  write-up); `~/.local/with-staging/fresh-592`: the fresh-worktree
  measurement (detached at 592eb6602); `~/.local/with-staging/battery-phases`:
  the merged battery-time-2 work (can go).
- Logs: `~/.local/with-staging/bt-*.log`, `bt*-onegraph.{log,err}`,
  `studio-cut*/`, `win-cut2/`, `linux-cut2/`.
