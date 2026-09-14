# Handoff — stdlib sourcing Phases 0/1/2 and the corpus registry (2026-09-14, night)

Worktrees under `~/.local/with-staging/`. Read this whole file before
touching any of them. Nothing here is reseeded.

Where things stand on GitHub: #1129 (Phase 0) is MERGED into main as one
squash commit. #1138 was squash-merged into fnabi-phase0 and #1141 into
c-algorithms-phase1 (both stacked PRs; neither reached main). #1142
(`c-algorithms-phase1` → main) carries Phase 1 + Phase 2; origin/main was
merged into it (96b31754, every conflict resolved to the branch side, which
is the superset; abi-hash-check green). The registry branch below stacks
on c-algorithms-phase1 and targets main once #1142 lands.

| Worktree | Branch | PR | State |
|---|---|---|---|
| `fnabi-phase0` | `fnabi-phase0` | #1129 → main | tip 503b3c3a pushed; local battery green (build, fixpoint, test, test-green, last-green, drop-audit 119/0, move-audit 15/0); ALL FIVE CI LANES GREEN. Ready to merge. |
| `c-algorithms-phase1` | `c-algorithms-phase1` | #1138 → fnabi-phase0 | tip 71b4bdf7 pushed; local battery green at da594bc0 (build, fixpoint, test, test-green, last-green); CI: the corpora lanes went green with the portable assert reporters, `behav_migrate_assert_macro` is `skip-on: windows #1140`. Watch the lanes at 71b4bdf7. |
| `tommyds-phase2` | `tommyds-phase2` | none yet (stack on #1138) | PR #1141 → c-algorithms-phase1; tip pushed; local battery GREEN at 376daeee (build, fixpoint, test, test-green, last-green, drop-audit 136/0, move-audit 15/0). Watch the lanes. |

Standing rules: commits authored `Eric Hartford <eric@quixi.ai>`, no AI
attribution; never `git stash`; no python/bash/perl/sed/awk scripts (With
one-liners or `with run tool.w`); never `-O0`; take a keep_awake hold for
long runs; the Bash tool is zsh (no word split); never cite unprinted
hashes; a migrate workspace runs in the build DRIVER's compiler, so
re-migration is `WITH=out/release/bin/with out/release/bin/with build
:<corpus>-promote`; never `WITH=<stage1> <stage1> build` (#1116).

## 1. Phase 0 (#1129) — done

Root cause of the Windows x86_64 stage2 timeout and the three fixes are in
the PR comment (d7c75f28, 92bf3984, 503b3c3a): SROA-scalarized struct copies
plus dead aggregate loads before in-place receiver calls fed LLVM's
quadratic store merging; large aggregate copies now lower to
memmove/memset before the per-function cleanup, a ref argument no longer
evaluates its place, and a reference-typed operand still evaluates (its
value is the pointer). Every windows_x86_64 unit emits in under 3 s.
Follow-ups noted, not done: the 64-byte threshold is a guess; the target
machine passes CPU "generic" (x86 tune) where clang passes x86-64; a
`WITH_KEEP_UNITS` switch to keep unit bitcode would have saved an hour.

## 2. Phase 1 (#1138) — done pending CI

Three CI failures fixed: `__assert_rtn`/`__assert_fail` are With functions
in std.libc (portable report + abort) so a macOS-migrated corpus links on
Linux/Windows; a record named only through a member type (glibc's
`__locale_data`) is collected by the Clang bridge after the declaration
walk and renders opaque (fixture `behav_migrate_member_only_record`); the
native-Windows `assert.h` migration gap (UCRT `_wassert` + wide string
literals) is filed as #1140 and the fixture skips on Windows.

## 3. Phase 2 (`tommyds-phase2`, PR #1141) — done pending CI

Commits on top of the Phase 1 tip (03eb3d8e..3b77462e):
- migrator: bit builtins → integer methods; pointer-to-function-typedef →
  function pointer; libc qsort/rand/srand + Darwin mach clock modeled
  portably (rt `with_libc_mach_absolute_time`); a HEADER's `static inline`
  definitions are published once by the same-named unit and imported by
  every other unit (`ci_migrate_translate_function`, the project scan's
  `header_owner_module`, `ci_migrate_collect_unsafe_extern_fns` treats a
  header-owned static as an imported raw function). A unit's own static
  inline helpers and headers no unit owns stay private per includer.
  Fixtures: `behav_migrate_bit_builtins`, `_fn_typedef_pointer`,
  `_libc_qsort_clock`, `_libc_mach_clock` (darwin-only),
  `_header_inline_owner`.
- corpus `lib/std/tommyds/` (13 units + defs + check_ harness + bundle.w),
  fourth `.wo` bundle (`build/tommyds.w`, `tommy_wo` at all 27 `calg_wo`
  sites, exclusions in build.w + build/runtime.w, internal module list),
  corpora lane `tommyds-test` (tommycheck: OK, 37 sections), drift lane
  and root check.
- facade `std.collections.hash_index.HashIndex[K: Hash + Eq, V]` over
  hashdyn: node-first slot per entry, one C trampoline
  (`hash_slot_compare`), reusable probe slot, bucket-walk clear/drop/iter.
  `behav_hash_index`, complexity row `hash-index` (PASS, linear),
  drop-audit cells `hash_index_{empty,full,partial,replace,cursor}`,
  `test/benchmark/hash_engines.w` (numbers in the plan's Phase 2 status:
  HashIndex 32/3/26 ns vs rt_core HashMap 41/9/58 vs raw hashdyn 18/5/15).
- docs: plan "Phase 2 status", wo_bundles.md fourth bundle.

Verified on the branch tip's release binary: all Phase 2 fixtures, the
corpora lane, the complexity lane, the benchmark; `:tommyds-promote` with
the release compiler reproduces the checked-in corpus byte for byte.

Battery GREEN at 376daeee (the chain below has finished; PR #1141 carries the evidence comment). Was run from the scratchpad
(`p2_dropaudit.log`, then `p2_bt_build.log` → `p2_bt_fixpoint.log` →
`p2_bt_test.log`; marker `p2_battery_done`). Remaining after it: `:test-green`,
`:last-green`, `:move-audit`; read `out/drop-audit/audit.stdout` (expect the
five hash_index cells PASS, 0 regressions); push `tommyds-phase2`; open the
PR stacked on #1138 (body: the plan's Phase 2 status + the battery line);
watch the lanes. Not reseeded.

Traps hit (all in memory too): a user program's `std.*` comes from the
binary's EMBEDDED stdlib, so a facade edit needs `with build` before
`with run` sees it; the bundle root must exist before the first build
(the migrate action writes it, but the action needs a tree compiler:
generate it once from the module list); the CLI migrate needs
`--no-prelude` to match the build action's prelude-free output; `with -n`
with `return` truncates the output file; #1139 (two modules of one package
cannot both define a private fn of one name — user packages only, the std
bundle path is fine).

## 4. The corpus registry (`corpus-registry`, branch off c-algorithms-phase1)

Ruled by Eric 2026-09-14 ("do it now, before STC"): `build/corpus.w`
(the `Corpus` record: upstream pin, package, directory, harness, floor,
defines, excludes, promote ordering, test lane, six explicit hooks) and
`build/corpora.w` (the registry `corpus_count`/`corpus_at`, the generic
actions, `corpus_pipeline`, the exclusion and internal-module args, the
wo-drift group, the :test deps). `build.w` derives `corpus_plans` and
loops at all 27 former sites; `build/runtime.w` takes `exclude=` args,
`build/compiler.w`'s inventory `internal-module=` args. The four corpus
modules are declarations + hooks + lanes. Docs: wo_bundles.md "The corpus
registry" (also why the registry is indexed: ephemeral records and the
seed's comptime evaluator). Commits ab9ac09c, 33bd693a (roots regenerated,
comments only), 3534f1fd.

Proof done: fixpoint green; `wo-drift` byte-identical for all four
bundles; with the same migrator the old pipelines (run in the Phase 2
tree) and the registry pipeline produce identical migrated trees for
pcre2, zlib, c-algorithms and TommyDS (pcre2's registry output adds the
root and UPSTREAM the raw old dir lacked). Battery `:test` → `:test-green`
→ `:last-green` was running (scratch `cr_bt_*.log`, marker
`cr_bt_done`); then push, PR (base c-algorithms-phase1, retarget to main
after #1142), watch lanes. Seed-evaluator traps hit are in memory
(`corpus-registry`): plain records cannot hold reference-taking fn fields
(ephemeral can); a Vec of ephemeral records does not iterate under the
seed; hook values need `&ctx`/`&path` explicitly; `module` is a keyword.

## 5. Open follow-ups
- #1139 private-name collision across modules of one package.
- #1140 UCRT `_wassert` + wide string literals in the migrator.
- Phase 0 codegen follow-ups (§1).
- `hashlin`/`hashtable` facades: same node protocol, not surfaced until a
  facade needs incremental or fixed-size resize.
- Phase 3 (STC) per the plan: its template-instantiation staging is a
  `stage` hook on a `Corpus`; the registry is the test of the abstraction.
- Retarget: after #1142 merges, open/retarget the registry PR to main and
  delete the merged phase branches so nothing is stranded.
