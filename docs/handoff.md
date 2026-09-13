# Handoff — stdlib sourcing Phase 1: the c-algorithms corpus and its facades (2026-09-13)

State dump for the agent picking up `docs/stdlib_sourcing_plan.md` Phase 1.
The previous handoff (the `.wo` bundle / ABI chain) is history: #1101, #1103,
#1107 and #1108 merged. Phase 0 is PR #1129 (`fnabi-phase0`); this branch is
stacked on it.

Author/commit rules: commits are `Eric Hartford <eric@quixi.ai>`, no
attribution trailers. Never `git stash`. No Python/bash/perl/sed/awk
scripts — With one-liners (`with -p`/`-n`/`-e`) and `with run tool.w`.
Never `-O0`. Only Eric blesses spec wording. The Bash tool is zsh.

---

## 0. Where things are

| Branch | Worktree | Meaning |
|---|---|---|
| `c-algorithms-phase1` | `~/.local/with-staging/c-algorithms-phase1` | Phase 1, this handoff |
| `fnabi-phase0` | `~/.local/with-staging/fnabi-phase0` | Phase 0, PR #1129 (CI red on 4 lanes at last look; not touched here) |
| `main` | `~/with` | origin/main is at 17109853 (#1103 merged); the local `~/with` checkout is behind |

Issues filed from this work: #1135, #1136, #1137 (all compiler gaps, see §3).

## 1. What landed on the branch (all verified with a stage1 built from the tip)

1. **Corpus.** `build/c_algorithms.w`: pin (fragglet/c-algorithms `23d45379`),
   reference fetch, raw migration (`c-algorithms-migrate`: 19 engine modules +
   `defs.w` + the harness `alloc_testing.w`/`framework.w`/`test_cpp.w`),
   `c-algorithms-check-generated` (no `@[c_export]`, no untranslated residue,
   module floor), `c-algorithms-promote` → `lib/std/c_algorithms/` (generated,
   never hand-edited; `bundle.w` is the `.wo` root), and
   `c-algorithms-bundle-root-check`.
2. **Upstream tests.** `c-algorithms-migrate-tests` migrates each of the 17 test
   programs as its own whole migration (engine + framework + test, with
   `ALLOC_TESTING`) into `out/c_algorithms_tests_migrated/tests/<name>/`;
   `c-algorithms-test` compiles and runs them. All 17 pass. `:test` depends on
   `c-algorithms-test` (the corpora lane).
3. **Bundle.** `calg_wo = wo_bundle_plan(ctx, "c_algorithms", "std/c_algorithms",
   "lib/std/c_algorithms/bundle.w")` wired at every site zlib's plan is (host,
   stage2/3/fixpoint/release link, cross linux/windows plans, embedded blobs,
   bootstrap empty slots, wo-drift with `test_cpp.w` as harness).
   `build/runtime.w` and `build.w` exclude `lib/std/c_algorithms/` from the
   embedded stdlib; `build/compiler.w` lists `std.c_algorithms` as internal.
   `with build :c_algorithms-wo` built and installed the host slot.
4. **Migrator fix** (general): a record forward-declared with no definition in
   the TU renders `type X = opaque` so another TU's definition upgrades it
   regardless of file order (`test-trie.c` sorted before `trie.c` and `_Trie`
   became `{ __pad0 }`). Fixture `behav_migrate_incomplete_record_order.w`.
5. **Facades.** `lib/std/collections/engine_slot.w` (slot storage + the one C
   trampoline), `sorted_vec.w` (`SortedVec[T]`), `binary_heap.w`
   (`BinaryHeap[T]`, max by default, `new_min()`), `trie.w` (`Trie[V]`, keys are
   `str` bytes, `iter_prefix`). Ownership per the plan: the facade owns every
   value in a heap slot; `get`/`peek` observe, `remove`/`pop` transfer,
   `move fn drop` releases every value then the engine. Tests:
   `behav_sorted_vec.w`, `behav_binary_heap.w`, `behav_trie.w`; complexity rows
   in `test/complexity/stdlib.w` (sorted-vec, binary-heap, trie — all PASS,
   numbers below); drop-audit cells `*_facade` in `tools/drop_audit.w`.
6. **Sema fix for #1137** (`src/SemaCheck.w`, `check_binary`): ordering two
   views (`&T < &T`) of a type without the operator method is now a diagnostic
   instead of a silent address comparison. Fixture
   `test/compile_errors/err_view_order_without_lt.w`.
7. Docs: plan "Phase 1 status", `docs/wo_bundles.md` note.

Complexity lane, stage1 on Eric's laptop (n vs 4n, ns): sorted-vec 399917 →
1728916; binary-heap 346209 → 1481959; trie 4079708 → 16974792.

## 1b. Verified since the first cut (2026-09-13, this branch)

- Full `with build` and `:fixpoint` pass on the branch tip.
- The facade tests pass under BOTH stage1 and the release binary after two
  more fixes: the bundle interface's `pub type Trie = _Trie` /
  `BinaryHeap = _BinaryHeap` aliases no longer shadow a source type of the
  same name (`SemaDecl.prepare_interface_demand`), and the #1137 diagnostic
  fires only for declared struct/enum/instantiation targets.
- A generic type whose only use is being dropped no longer phase-bugs
  (`MirLower`: eager caches refreshed after generic Drop registration;
  fixture `behav_generic_drop_only_use.w`).

## 1c. The branch's own regressions — the blocker for the battery

`with build :test` is red on ~16 fixtures that pass on the Phase 0 base
(c0a28c6e) and were ALREADY red at the pre-session tip af5d9adb. Bisected
with stage1 builds in throwaway worktrees (each verdict = the named test
run against that commit's stage1):

| Culprit commit | Regressed fixtures | Symptom |
|---|---|---|
| 31a347d4 mir: retain concrete closure and async bodies before codegen | behav_scope_block_forms, behav_scope_join_vec_join, behav_iter_of_self_independent (pass at c03e93bc, fail at 31a347d4) | `BUG: anonymous expression lacks MIR constant` / `invalid MIR: use rvalue type incompatible` |
| 88f0ad31 Preserve borrowed dereference places in non-Copy bindings | behav_derive_serialize, behav_derive_deserialize (pass at 92c0c01d, fail at 88f0ad31; ee1884c7/e7ddf116 touch only the migrator and libc) | `cannot take ownership of a non-Copy value through a borrow (str is not Copy)` at json.w `out.value_str(*self)` |
| 92c0c01d Reject private generic type applications across module boundaries | behav_iter_pipeline_local (pass at b2594539, fail at 92c0c01d); probably err_iter_of_self_vec_iter, borrowed_str_binding_preserves_source, spec_ss14_9/16 | `symbol 'VecIter' is private to module <embedded-std>/std/collections.w` |
| not attributed | cd_unary (passes at 31a347d4, fails at af5d9adb), behav_migrate_va_list (exit 134), behav_scope_spawn*, test/spec scoped-send | |

These are compiler changes the previous agent made while getting the
corpus and facade probes to compile; none has a root-cause note in its
message that explains the regression. Each needs its own root cause (the
route: `--dump-mir` / `--validate-all` on the fixture at the culprit vs its
parent; `git show <commit>` is 4–13 lines of Sema/MIR each). Do not revert
blindly: the corpus tests (all 17) and the facades depend on some of these
(e.g. 88f0ad31 for `let value: T = unsafe { (*slot).value }`?) — re-run
`:c-algorithms-test` and the facade tests after each change.

## 2. What is NOT done

- **The battery.** `with build` and `:fixpoint` pass; `:test` is red on the
  §1c regressions (the run was stopped after the behavior lane; wo-drift,
  pcre2-test and the corpora lane were not reached). `:test-green`,
  `:last-green`, `:drop-audit`, `:move-audit` not run. A stage1 behavior-test sweep and a direct
  `with run tools/drop_audit.w <stage1> ~/.local/bin/with` were started; check
  their logs before trusting anything (`p7`-harness fixtures pick the stale
  `out/stage/bin/with-stage2` and fail for that reason alone until a full build
  refreshes it — `behav_migrate_incomplete_record_order.w` is one).
- **Commits.** Everything above is committed (tip: see `git log`).
- **Comparison measurements** against comparison engines (RB/AVL vs sorted
  array, etc.) are not recorded; the complexity rows above are the only
  numbers.
- **PR** on top of #1129 (which is itself red on CI).

## 3. Rulings and gaps to raise with Eric

1. **`<` on user types.** §11.7 dispatches comparison operators to fixed method
   names (`lt`, `gt`, …); `Ord` carries only `cmp(other: Self)`. So a type
   with `Ord` has no `<`, and generic `T: Ord` code cannot compare two views
   without copying. Today's facades therefore require `lt`/`gt` taking `&T`
   on the element type (the tests' `Tag` defines them). Proposal for a ruling:
   one `Ord.cmp(other: &Self)` backs all six comparisons (no-ceremony: one
   method, not six), and views compare values, never addresses.
2. #1135 — a non-capturing closure inside a generic function coerced to
   `extern "C" fn` is miscompiled (runs the closure thunk). Blocks handing a
   monomorphized comparator straight to a C engine; the facades store a
   With-ABI closure in each slot and route through `slot_compare` instead.
3. #1136 — a module under `lib/std/collections/` cannot see a corpus `pub let`
   (`BINARY_HEAP_TYPE_MAX`) and needs item imports for generic types.
   Workarounds are marked in `binary_heap.w` and the facades' `use` lines.
4. #1137 — fixed on the branch (diagnostic); the `x < y` on owned 16-byte
   structs still fails LLVM verification (also in #1137's text).

## 4. Commands

```
cd ~/.local/with-staging/c-algorithms-phase1
WITH=~/.local/bin/with with build :dev            # stage1 from the tree (installed seed, NEVER WITH=<stage1>: #1116)
B=$PWD/out/bootstrap/bin/with-stage1
$B test test/behavior/behav_sorted_vec.w test/behavior/behav_binary_heap.w test/behavior/behav_trie.w
$B build test/complexity/stdlib.w -O1 -o /tmp/cx && /tmp/cx
WITH=~/.local/bin/with with build :c-algorithms-test   # 17 upstream programs (~4.5 min: 18 migrations)
WITH=~/.local/bin/with with build :c_algorithms-wo     # the bundle slot
with run tools/drop_audit.w $B ~/.local/bin/with        # facade cells against the seed baseline
```

Traps: `with build <target>` needs the colon (`:c-algorithms-test`);
`WITH=<stage1> <stage1> build …` makes stage1 the seed and its empty bundle
slots hit #1116 (`stderr` shadowing errors in `out/gen/main.w`).
