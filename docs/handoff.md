# Handoff — the .wo bundles / stdlib-sourcing campaign (2026-09-08)

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
  `79d523f4`: **head `2fe8ecb9`, 30 commits**, ABI hash re-recorded for the
  merged tree, `with check src/main.w` passes with the seed. This is what
  eventually merges to main.
- **`c4p` — the measuring tree.** Head `5ac74456` (same fixes, on the older
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
| + root-tail rotation, rerun | — | **282.2 s**, likely RED (the `test-pass` marker was not refreshed) | **not a gate measurement** |

The 14 failures were a real ordering bug: the merge appended interface
chunks *after* the root's declarations, but `Sema.is_local_decl` takes the
**last N** declarations of the merged pool as the root's, so the root's own
types read as imported (`derive` generation, sealed-trait locality and
`copy` all failed). `2fe8ecb9` rotates the chunks in before the root tail.

### What you must do next (in order)
1. **Get the truth on the 282 s rerun.** In `c4p`: was it green? (`out/.build-state/behavior-tests.test-pass` freshness; the lane's captured output under `out/test-graph/behavior-tests/`.) If red, the failure list and cause first.
2. **Root-cause the lane cost.** Even if green, 282 s is ~100 s *worse* than lazy collection alone — roughly 100 ms per compile, more than the 40 ms parse×2 the merge was meant to remove. Profile a **representative behavior test, not hello** (`WITH_PROFILE=1` breaks `frontend.comptime` into prepare/transform and reports `[profile] frontend.interface lines=N of M`). Name the mechanism and its ms. Suspects, unmeasured: the rotation copying the decl list + three per-decl vectors on every compile; the on-demand fixpoint re-parsing sections per iteration; chunks re-lexed per file. **Measure, don't guess** — the parse×2 finding was made exactly this way.
3. Iterate until the lane is **green and ≤ 158 s on the `c4p` base.** Every mechanism you add: report its measured delta.
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
