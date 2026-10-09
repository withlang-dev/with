# Handoff: coordinator status (2026-10-02, evening)

You are taking over as coordinator. Read `CLAUDE.md` first; everything below
assumes its rules (seed-driven battery, one stack one battery, fix don't
file, commit as Eric Hartford <eric@quixi.ai> with no AI trailers, never
`git stash`, worktrees in `~/.local/with-staging`). Earlier handoffs:
`docs/handoff-2026-09-28.md` (modeled-C close-out).

**Nothing is running.** No agent, no battery. Every merged worktree is
removed.

## Where main is

- `origin/main` = `93070165` (#1965). The installed `~/.local/bin/with` is
  that build, installed through the reseed gate after a green battery on
  main itself.
- Seeds: darwin unchanged; windows-x86_64 pinned to the self-contained seed
  `nightly-20260930-local-2-bd6e00d1dee6` (#1937). SDKs in `sdk.lock`:
  linux-x86_64 `nightly-sdk-20260930-6f0394637064`, linux-aarch64
  `nightly-sdk-20260930-e997223d40ce` (cross-built, native bootstrap still
  pending — the one open item on #1915).

## Merged 2026-10-01 → 10-02 (every one battery-green before merge)

Stack #1950: #1935 (Linux zero-dependency: own sysroot/lld/libc++/cmake/
ninja; x86_64 verified in a sandbox with host tools hidden) → #1949 (D82).
#1945 (type-check verdicts independent of body-check order; 0 of 1584
fixtures differ reversed; `sema-order-check` in the gate; #1941). Josh's
#1947, #1887, #1863 (reviewed, approved, battery on merged main).
Stack #1972 (seven layers): #1966 imports not transitive (#1955) → #1956
unstamped image links its bundles (#1330) → #1961 (#1356) → #1968 `Vec.get`
retired, 876+48 sites migrated, a tail-read miscompile (#1239) → #1959
emit-c closures and generators (#1766) → #1971 `out/gen` guard → #1970
latent `get`/import sites. Then #1965 (#1757, #1732, #1737, #1746; generic
free calls record view origins; generic instances resolve their template by
identity; emit-c installs Sema's substitution record for mono bodies).

## Modeled-C campaign (#1709): the 17 open window issues

15 closed on main with evidence. Open on purpose, remaining work named on
each: **#1457** (same-named methods across modules — the collision is a
located error by design; the symbol must carry its declaration through
Sema's owner-keyed tables and codegen naming) and **#1647** (D65 audit:
phase 1 of 5 done; ~11 codegen sites still branch on LLVM pointer kinds,
`CodegenDispatch.w:1201–1912`, `marshal_ref_addr`).

## The one open PR: #1960 `fix-1438` (layout, ABI v13) — words blessed 2026-10-02, battery running

Worktree `~/.local/with-staging/fix-1438`, tip `b8e7bcf2`, pushed, clean.
Code complete: TypeLayout owns every layout (§2 enum rule, §3 Option niche,
fat dyn pointers); codegen builds enum/Option/Result bodies from the model
and verifies the emitted size (BUG on mismatch); 63 of 64 kinds agree
(`Unit` is spec-sanctioned); #1958 (Option over aligned payloads) fixed on
the branch, 22 struct-indexing sites → one accessor pair. `:fixpoint`,
`:drop-audit` 254/0, gate green. **ABI 12 → 13.** Batteries ALONE.

Eric blessed the three sentences (2026-10-02); they are on the branch as
44ec95cc (§1 fat dyn pointers, §3 niche set, v13 history), rebased onto
main 93070165, battery running alone from this worktree:
1. §3: `Option[T]` whose payload is a single non-null address — `&T`, `*T`,
   an `extern fn`, a std `Box[T]` — lowers to that nullable pointer; `&str`
   (a view) and `&dyn`/`Box[dyn]` (fat) do not. (Codegen always niched
   Box/extern fn; the model now matches; Rust's exact set.)
2. §1: `&dyn T`, `*dyn T`, `Box[dyn T]` are `{ data, vtable }`, two words.
3. `docs/spec/abi/with-abi.md` v13 history entry: an enum's payload area
   sits at the largest payload's alignment and the enum is aligned to the
   larger of tag and payload (§2 as written); payloads were packed at
   offset 4. `E64` 12→16, `Result[i64, str]` 20→24.
When blessed: land the words on the branch, rebase onto main, battery, mark
ready. Follow-up filed: #1964 (tuples over aligned payloads, same class).

## Lessons from this window (keep)

- **Never symlink `out/gen` between worktrees.** `compat-runtime-source`
  writes the embedded stdlib there; a stage2 in one worktree read another's
  stdlib mid-build and "miscompiled itself" (stage2 ≠ stage3). Root-caused
  with lldb; the build now refuses a symlinked `out/gen` (#1971). Copy it.
- **A squash-merged main needs its own battery** before `:install-user`
  accepts it (D49: a green belongs to the sources; the squash is a new
  tree). Budget ~12 min after every merge.
- **Merge a stack only from its top** (`gh stack merge <top> --yes
  --squash`). #1962 was merged from the middle of a stack and landed into
  its base branch, not main; it had to be re-opened as #1968.
- **One worktree, one build at a time.** A battery's gate was SIGKILLed one
  second in because two bisect builds I had left running shared its lock.
- Per-issue agents each pay a stage1 build + gate; for small unrelated fixes
  one agent per batch is cheaper (the verifier did four in one build).

## Other open items

- #1955's spec note: §18.2 tier 5 says bare std names need no `use`; the
  compiler is non-compliant in the strict direction (D29 import-gate
  scaffolding, #750/#752). The std-tier walk-through in
  `module_visible_no_prelude` is neither tier 3 nor 5 — an implementation
  leftover. Not changed.
- #1967: a visible module's type candidate is returned before the
  scoped-binding tier (a module `type T` could shadow a generic param).
- #1951–#1954 (from the Josh reviews): POSIX `remove_tree("link/")` empties
  the target; Windows `copy_tree`/`list_files_text` follow junctions;
  Windows panic paths mangle backslashes; `VecRange.len()` crashes the
  compiler.
- 45cc685e (#1945's squash) is authored `ehartford@gmail.com` — GitHub's
  squash took the account email, not `eric@quixi.ai`.
- Compile-speed next steps (after S2a): S1 deterministic table growth, S2b
  per-worker context, S3 parallel sema waves, S4 threaded IR gen — see the
  10-01 handoff for the plan; the inventory is `docs/proposals/parallel-sema/`.

## Worktrees kept (not mine to delete without a look)

`next-sema-values` (2 dirty files), and five with commits on no remote:
`battery-speed`, `fix-rtgen`, `fnabi-srcpath-before`, `next-cimport-modules`,
`next-emit-c` — Sept 27–29 campaign leftovers; check `git log origin/main..`
in each before removing. Untracked in the main checkout (not ours):
`docs/plans/`, `examples/spiral/`.
