# Handoff — the .wo bundles / stdlib-sourcing campaign (2026-09-08)

**C4 landing update:** the local A/B performance gate is now green on the
rebased landing tree. After excluding the initial pair, the two uncached
warm pairs were 263.9/268.7 s (C4/baseline 1.018) and 275.6/284.3 s
(1.032); baseline passed 985 files and C4 passed 986 in every run.
`docs/wo_bundles.md` records the measured table. Main's handoff-only changes
have been merged into `wo-c4`. The first battery passed build (164.5 s),
fixpoint (276.6 s), and move audit (15 cells), then caught an audit-generator
defect: 113 probes redeclared private allocation symbols with obsolete
pointer types. LLDB observed the return signature replacement in
`Sema.collect_extern_fn` → `Sema.add_sig` (symbol 32, return 81 → 20).
The generator now uses `std.mem.alloc/free_mem` and retains each side's
diagnostics separately; all 115 drop cells pass against the pinned seed
(102.6 s). The next battery passed build (157.3 s), fixpoint (266.9 s),
and `audit:all` (2,504,943 facts, zero violations), but the test survey
failed only `bundle-interface-tests` (58 other targets green; 728.2 s).
The reduced consumer was just `use std.wi_demo`: LLDB observed
`interface_line_name("impl Pair:", 2)` returning an empty string, then
`parse_interface_chunk` receiving its indented methods without the impl
header. The merge now demands whole declarations, keeping leading
attributes and indented bodies with their header, and names inherent
impls by their target. The development compiler (78.9 s) passes the
reduced import and original consumer. Expanded fixtures verify an unused
attributed type and a demanded packed type: emitted interface and
source/interface fingerprints agree, and the consumer reads 42 from a
five-byte packed value. The next step is a fresh battery on this committed
correction, using `out/release/bin/with` for every post-build step.
Debugger launches now work; a disabled DevToolsSecurity status did not
establish an authorization blocker, and no approval popup was seen.
Do not repeat the performance gate or
use the earlier quiet-box requirement below; the local ratio ruling
supersedes it. C4 is not yet merged or reseeded.

You are picking up a campaign mid-flight. This note is self-contained: it
tells you where every thread stands, exactly what is next, the gates that
must hold, and the traps that cost days this week. Read `CLAUDE.md` first —
the self-host discipline is binding, and the memory notes in
`~/.claude/projects/-Users-eric-with/memory/` (indexed by `MEMORY.md`) hold
the rulings and traps in more detail than fits here.

## 0. Where the repo stands (stable — build on it, don't re-fight it)

- **Main is green on all five CI lanes** (macOS, linux-x86_64, linux-aarch64,
  windows-x86_64, windows-aarch64) at `79d523f4`. Windows was the last
  holdout (#1081, a native-Windows `invalid free` in the compiler building
  the pcre2 bundle); it is closed, and `fix_windows.md` records the route.
- **Seeds:** `seed.lock` pins Mac/Linux to **v0.15.2.0** and both Windows
  platforms to **v0.15.2.1**. Every platform bootstraps from a published seed
  it can use. `with build :seed` reads the lock; `tools/bump_seed_pins.w`
  rewrites every workflow pin from it.
- **Never-again guards, all landed:** `seed.lock` + the `:seed-compat` lane
  (the pinned seed builds stage1 of a tree copy — run it with the FRESH
  compiler, see §6), D40 seed numbering (`docs/decisions.md`: `Y` is a
  bootstrap-compatibility group, a breakage bumps `Y` and resets `Z`), and
  publish-first releases (`with build :publish-release-asset`,
  `build/release_publish.w`: each platform adds its asset the moment it is
  verified; nobody waits for the slowest runner).
- **Open PRs:** only #1078 (Eric's own draft audit evidence; not a review
  target). Everything mergeable was merged or closed-as-landed on 09-07.

## 1. The campaign and its sequence

The goal, per `docs/wo_bundles.md`, `docs/with-abi.md`, `docs/abi_roadmap.md`,
`docs/fn_abi_descriptor_design.md`, and `docs/stdlib_sourcing_plan.md`:
compile each migrated C corpus **once** into a `.wo` bundle behind a
versioned With ABI (Level 0), so that bringing in the container/algorithm
corpora costs nothing per build. The sequence in `wo_bundles.md` §Sequence:

| step | state |
|---|---|
| 1. ABI v1 written + ABI-hash check in the battery | **done** |
| 2. pcre2 → `pcre2.wo`, `with_regex_*` shim retired | mechanism + bundle landed (C1–C3); **shim retirement = C4, built but NOT merged — see §2** |
| 3. zlib → `zlib.wo` | **not started** — §3 |
| 4. new corpora arrive as `.wo` from day one | gated on 2 and 3 — §4 |

**The order is not negotiable:** C4 lands, then zlib, then Phase 0 of the
corpora plan, then c-algorithms. zlib and Phase 0 touch the same
embed/link wiring C4 touches, so starting them before C4 lands only adds to
C4's rebase. Phase 0's *docs* (§4) are the one thing that can run in
parallel.

## 2. C4 — retire the regex shim. THE BLOCKER. Land this first.

### What it is
`std.regex` calls pcre2 directly through the bundle interface; the
`with_regex_*` runtime shim and every hook that carried it are deleted
(D30); the compiler's regex-literal validation and codegen go through the
facade. Tracked by #955 (also covers the emit-C lane after the bundle).

### Where the code is
Two worktrees under `~/.local/with-staging/`:

- **`c4r` — the landing tree.** Branch `wo-c4` rebased onto main
  `79d523f4`: **head `973a738a`, 32 commits**, ABI hash re-recorded for the
  merged tree, `with check src/main.w` passes with the seed. This is what
  eventually merges to main.
- **`c4p` — the measuring tree.** Head `980a12e0` (same fixes, on the older
  base), working tree clean. Lane measurements were taken here because the
  box must be quiet for a valid number.

Both carry the full C4 series, in this order: the facade (C4.1), regex-literal
validation via `std.regex` (C4.2), codegen through the facade, the shim
deletion (C4.4), the ambient-tier/prelude changes, the bundle-corpus
in-unit compile for emit-C, the MIR global-proxy mark, then the three
performance commits: **lazy interface collection** (`fe5d31dd`-class),
**indexed symbol/signature/extern-var lookups** (`a463244a`), and the
**on-demand interface merge** (`e331b848` + the root-tail rotation
`2fe8ecb9`). Plus `1c775d05`: three "source wins" rules (Sema
`collect_fn_decl`, `collect_extern_fn`, codegen `declare_function_at_inner`)
so an interface declaration never displaces a same-named source
declaration whatever the order.

### The gate (Eric's ruling, 2026-09-07: "we are gonna need to fix the perf")
**Hard. C4 does not land above it.**
- hello-world `with check` ≤ **0.05 s** (pre-C4 baseline 0.03 s)
- behavior-tests lane ≤ **158 s** (pre-C4 baseline 144 s; that is +10%)
- measured on an **idle box**, first cold run excluded, release compiler.

### Where the numbers stand
| mechanism | hello check | behavior lane | verdict |
|---|---|---|---|
| C4 without perf work | 0.23 s | 414 s | the bug Eric ruled on |
| + lazy interface collection | 0.07 s | 177 s (green) | hello over, lane over |
| + lookup indexes | 0.07 s | 177 s (no change — expected; it is the fix for large units) | — |
| + on-demand merge, first run | **0.05 s ✓** (`decls` 4771→1366; interface parses 59 of 3,405 lines) | 306.8 s **RED**, 14/980 failed | invalid |
| + root-tail rotation, rerun | 0.05 s ✓ | 282.2 s, **GREEN** (980/980) — but **invalid**: the box carried a full core of foreign load (Steam ~99% of a core, WindowServer, VS Code, a VM; load 3.0–3.5) | not a gate measurement |

**Neither 177 s nor 282 s is admissible** — both were taken on a loaded box.
Per-test timings on `behav_derive_clone.w`, same box state, three binaries:
pre-C4 seed check/build/test 0.03/0.09/0.39–0.54 s; eager C4 0.45/0.54/0.81 s;
on-demand C4 **0.05/0.12/0.40 s** — parity with the seed on `test`, half of
eager C4. On that arithmetic the lane on a quiet box lands near **150–160 s**,
i.e. at the gate. So the "regression" was load, not the merge.

The 14 failures in the first run were a real ordering bug: the merge
appended interface chunks *after* the root's declarations, but
`Sema.is_local_decl` takes the **last N** declarations of the merged pool as
the root's, so the root's own types read as imported (`derive` generation,
sealed-trait locality and `copy` all failed). `2fe8ecb9` rotates the chunks
in before the root tail; the rerun above proves it (980/980).

**The remaining per-compile residue is measured** (phase profile of `check`
on `behav_derive_clone.w`, on-demand release vs seed, ms): parse 9.7 vs 3.5,
resolve 9.9 vs 3.8, imports 4.2 vs 0.3, interface 4.2 (new), comptime 9.9
vs 4.4, sema 4.9 vs 3.9, MIR 3.5 vs 2.8 — **48 vs 21 ms**. About 16 of the
extra 27 ms is the interface sections' **937 `use` lines**: parsed as `use`
declarations twice (Resolve, then the import worklist — `decls` 1368 vs
447, the 920 extra are those use decls), each resolved to a module path
individually (`resolve_module_path_frontend` × 937 for ~35 distinct
modules), then carried through the comptime transform's pool clone before
being stripped. The chunk fixpoint itself is 4.2 ms (two passes); the
rotation is sub-millisecond. **That fix is done and committed** (`c4p`
`980a12e0`, ported to `c4r` as `4d775b12`): Resolve turns a section's `use`
lines into import edges directly from text (`process_interface_module`),
and the worklist enqueues a section's imports from the same text with a
per-compile name→path memo (35 distinct modules) — no use declaration of a
section enters the pool. Same check: **48 → 40 ms** (seed 21), `decls=463`,
imports 0.5 ms. The same commit fixes a latent pairing bug it exposed: a
section's path was pushed to the pending list before its imports recursed
and its text after, so `pcre2_compile_8` was attributed to
`pcre2_compile_cgroup.w`, its link name hashed the wrong module and the
bundle went unlinked (caught by the regex tests). With it: check 0.04 s ×3
(seed 0.03), hello-world **0.04–0.05 s ×4** — the hello gate is met; the 14
derive/sealed/copy tests, the three regex behavior tests, the regex/abort
repros, the compiler self-check and both fixtures all pass. The branch's
`docs/wo_bundles.md` (`973a738a`) documents all five mechanisms with their
figures.

### What you must do next (in order)
1. **Measure the gate as a RATIO, LOCALLY — this is the only thing left before landing.** Every mechanism is done; per-test arithmetic (`test` 0.40 s vs the seed's 0.39–0.54) puts the lane at or under the seed's own 144 s. Eric's rulings (2026-09-09): activity on the laptop blocks nothing — do **not** wait for an idle box — and the measurement is **local, not CI**. The gate is *relative* (≤ +10% over the pre-C4 baseline), so measure it on this box under identical conditions where load cancels: run the pre-C4 seed's behavior lane and C4's behavior lane **interleaved, A/B/A/B, at least two full pairs**, same box, release compiler. Report each run's wall time and the ratio C4/seed; **ratio ≤ 1.10 is the gate.** A wall-clock number taken alone on the shared laptop (177 s, 282 s) is load noise and proves nothing either way.
3. Iterate until the lane is **green and ≤ 158 s on the `c4p` base.** If the quiet-box number lands above the gate, profile a representative behavior test (not hello) with `WITH_PROFILE=1` and name the next mechanism with its ms, as above. Every mechanism you add: report its measured delta.
4. **Port to `c4r`**, re-measure the lane once on the rebased tree (main's changes can shift it), then the full battery **with the move and drop audits** (C4 touches MIR): `with build`, then with the fresh `out/release/bin/with`: `:fixpoint`, `:move-audit`, `:drop-audit`, `:test`, `:seed-compat`, `analyze src/main.w audit:all`, `:test-green`, `:last-green`. Report all numbers. Only then push, reseed (`:update-seed`, `:install-user`), close #955.
5. Update `docs/wo_bundles.md` §"Shim retired (batch C4)" with the final measured table (the branch's copy has the 0.23 s / 414 s pre-fix numbers and the placeholder).

### The prior agent
Session id `aa40516def8194a3f` did all of the above and knows the code
intimately; it can be resumed with a message if it is still reachable. It
went idle twice without reporting a lane number — if you resume it, demand
the number first. Its regression-found-then-fixed history is in this
session's memory note `wo-c4-plan.md`.

## 3. zlib → `zlib.wo` (next after C4; one mechanical batch)

The bundle machinery is already multi-bundle (bundle *slots*,
`embedded_bundle_count`, per-bundle link selection in `Link.w`; #946
closed), so this mirrors pcre2 exactly:
- a `wo_bundle_plan(ctx, "zlib", "std/zlib", "lib/std/zlib/bundle.w")` in
  `build.w` beside `pcre2_wo`, wired through `wo_bundle_targets`,
  `target_with_link_bundle` on every stage, and `target_with_wo_blobs`;
- a generated bundle root over the 18 modules in `lib/std/zlib/` (16 corpus
  + `example.w`/`minigzip.w` harness), written the way
  `build/pcre2.w pcre2_bundle_root_text` writes `lib/std/re/bundle.w`;
- `std.zlib` (`lib/std/zlib.w`, already the model facade importing its
  modules directly) and the consumers that recompile in-unit today
  (`std.build`, `build/zlib_gzip.w`, `build/zlib_gunzip.w`) link the bundle
  instead. Measure compiler build time before/after — the point is that it
  stops recompiling zlib on every build.

## 4. The corpora plan (`docs/stdlib_sourcing_plan.md`)

Three corpora + one surgical port, each migrated **whole** through pcre2's
pipeline and arriving as a `.wo`, with native facades choosing engines by
benchmark (D37): **c-algorithms** (fragglet: RB/AVL, heap, sorted array,
trie, hash table, list), **TommyDS** (hardened hashing/indexing), **STC**
(modern breadth: vec/deque/pqueue/hmap/smap/cstr/cbits...), and **M*LIB**
`m-bptree.h` only. Written natively, not migrated: graph algorithms,
union-find, SlotMap's free list, and Vec/str.

- **Phase 0 — measure first** (can start in parallel, docs-only until the
  lane): `docs/stdlib_inventory.md` (every structure/algorithm needed, its
  complexity contract, status — **not started**), the complexity-fixture
  lane (**not started**), and SlotMap's native free list (#936, open;
  Miguel is building SlotMap — keep it single-owner, no built-in locking;
  see the D22/D27 notes). Gate: lane green with known cliffs recorded.
- **Phase 1** c-algorithms whole (non-macro C; the `void*` + callback
  idiom). **Phase 2** TommyDS. **Phase 3** STC (the macro-migrator
  campaign). **Phase 4** M*LIB bptree, surgical.

**Open questions still Eric's** (plan §"Open questions"): #2 whether every
corpus builds in every battery (a `corpora` lane); #3 whether Phase 0's
inventory rules on names now (`Heap` vs `PriorityQueue`, the `BitSet` API)
or leaves that to each facade PR. #1 was ruled as D37.

## 5. Related, done, don't redo
- Publish-first release (`build/release_publish.w`, per-job publish in
  `nightly-release.yml`), proven on CI (create-first and add-later).
- D40 accepted and applied (v0.15.1.10 renumbered to v0.15.2.0; the
  transient v0.15.1.9/.11/.12/.13 tags deleted).
- Rob's #997/#1016/#1029/#1035 landed by cherry-pick (a c_import regression
  #997 exposed — glibc's `NAN`/`INFINITY`/`HUGE_VALF` emitted as
  self-referential globals — was caught by the battery and fixed, `1f826ac4`).
- `with_str_from_cstr` copies (the #1081 root cause), Windows runtime fixes.

## 6. Traps that cost days this week — read before your first battery
- **Never commit during a battery.** `last-green`'s version stamp tracks
  HEAD; a commit mid-battery leaves a stale test-pass marker and a red
  `last-green`. Commit first, then battery, then reseed.
- **Drive post-build steps with the FRESH compiler** (`./out/release/bin/with`),
  as CI does. Driver-side rules (cache freshness, the RSS tripwire) live in
  the compiler; the installed seed lacks them until reseed.
- **`:seed-compat` is a fresh-compiler check, not a seed-driven `:test`
  dep.** The pinned seed's 1 GiB RSS tripwire is flaky on its ~1 GiB nested
  build; that is why it left `:test`. Run it as its own fresh-driver step.
- **Build-layer API is seed-gated.** `build.w`/`build/*.w`/`lib/std/build.w`
  are comptime-evaluated by the *pinned seed*; a new `std.build` API or
  `Target` field used there needs a published seed that has it. Driver-side
  rules keyed by target name take effect in-batch; a real API addition is a
  seed-release cycle (land unused → publish seed → bump lock → use).
- **A seed experiment must set `WITH=<seed>`.** The driver binary is not the
  seed; unset `WITH` silently uses the installed compiler.
- **Never revert language surface to appease an old seed** (build-layer
  `s[i]` included). Cut a newer seed (D40 tells you the number).
- **No Python/bash/perl/sed/awk for text work; With one-liners and With
  tools.** Edit tool for edits. Never `git stash`.
- **Verify by running.** A grep, dump or trace print is a hypothesis; the
  root cause is the exact line, proven in lldb or the debug allocator.
- **Isolation:** an ownership/drop/codegen/ABI change is alone in its batch
  with `:move-audit` and `:drop-audit`. C4 qualifies.

## 7. Worktrees and files
- `~/.local/with-staging/c4r` (wo-c4 rebased, landing), `c4p` (measuring),
  `c4` (older detached), `relpub` (rob-lanes, landed — can be removed),
  `uncast` (wo-hash, landed — can be removed).
- `build/pcre2.w`, `build/wo.w`, `lib/std/re/bundle.w` — the pcre2 pipeline
  to mirror for zlib. `build/release_publish.w`, `build/seed.w`,
  `tools/bump_seed_pins.w` — the release/seed machinery.
- Issues: #955 (C4/emit-C), #936 (SlotMap free list, Phase 0), #1076/#1077
  (filed by the C4 agent: silent in-unit corpus fallback; store install dir
  `$HOME` literal).
