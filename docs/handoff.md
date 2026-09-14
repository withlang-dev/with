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
   `ALLOC_TESTING`); `c-algorithms-promote-tests` promotes them into
   `test/corpora/c_algorithms/` (shared `engine/`, per-program `defs.w` +
   test module); `c-algorithms-test` (in `:test`) assembles each program,
   compiles it with `out/release/bin/with build --no-prelude` and runs it.
   All 17 pass. A migrate workspace runs in the DRIVER's compiler, and the
   battery's driver is the seed (CI: `src/main build :test`), whose migrator
   bails on Darwin's `assert`; that is why the lane compiles checked-in
   output and why re-migration is run as
   `WITH=out/release/bin/with out/release/bin/with build :c-algorithms-promote`.
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

## 1c. The branch's own regressions — FIXED (2026-09-13, commits 8d3f7785..e132688b)

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

Root causes and fixes (every formerly red fixture passes under stage1 AND
the release binary of the fixed tree):
- 31a347d4: MIR replaced a closure argument to a GENERIC_CALL (spawn worker,
  monomorphized callback) with a placeholder `const 0`, so the body was never
  prelowered (`MirLower.w` GENERIC_CALL arg loop). Fixed: the closure is
  lowered there. A statement-bodied closure with a value-returning type now
  gets the implicit default return in `prepare_anonymous_body`.
- 88f0ad31 was right (D22 §13.6, D28: str is not Copy). The non-conforming
  sources were fixed: `JsonWriter.value_str(&str)`, `cd_unary`'s `Acc` opts
  into Copy, the #1043 fixture drops its bit-copying `var inferred = h.text`.
- 92c0c01d was right (privacy). `VecIter` and the adapter types are user
  surface, so they are `pub`; the three tests naming them import them
  (D29 staged rule).
- behav_migrate_va_list (e7ddf116, not in the first table): call parameter
  types came from the CANONICAL callable type, erasing the `va_list` typedef
  (#1104); `ci_callable_cxtype` prefers the sugared type.
- The interface-alias gate from 66049bf5 was narrowed to real type
  declarations (std.libc's `c_int` alias must coexist with the interface's).

## 2. What is NOT done

- **The battery is GREEN** at 4832bf0a: `with build`, `:fixpoint`, `:test`
  (1027 behavior, 759 compile-error, corpora lane 17/17, wo-drift x3),
  `:test-green`, `:last-green`, `:drop-audit` (131 cells, 0 non-PASS; the
  three empty facade cells read FIXED against the seed baseline, which
  cannot run them), `:move-audit`. Two more fixes landed on the way:
  `anon_union_init_not_flattened` (the unnamed-record lookup keyed on a
  marker b0434ad3 removed from the translated type text) and the ABI hash
  re-record (message-only TypeLayout change). Not reseeded: the branch is
  stacked on #1129, which is red on CI. A stage1 behavior-test sweep and a direct
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

0. **RULED (D41):** `Ord.cmp(&self, &other)` backs the four ordered
   operators, `Eq.eq(&self, &other)` backs `==`/`!=`, fixed-name methods
   are overrides. Implemented on the branch (Sema `operator_method_derived`,
   MirLower `lower_derived_comparison`, `traits.w`, every impl in the tree,
   fixture `behav_ord_cmp_operators.w`). The §11.7 wording below is
   PROPOSED — only Eric's blessing of the exact words lands it in
   `docs/with-specification.md`; until then the spec still says six fixed
   names and the implementation is ahead of it.

   Proposed §11.7 intro (replaces "Arithmetic and comparison operators are
   the main exception … need to name them."):

   > Arithmetic operators are the main exception: they use fixed method
   > names on the concrete type (`add`, `sub`, `mul`, `div`, `matmul`,
   > `neg`). Comparison is one primitive per family: `Eq.eq(self: &Self,
   > other: &Self) -> bool` backs `==` and `!=`, and `Ord.cmp(self: &Self,
   > other: &Self) -> i32` backs `<`, `<=`, `>`, and `>=` (negative, zero,
   > or positive as the receiver orders before, with, or after `other`). A
   > type may additionally define the fixed-name methods `ne`, `lt`, `le`,
   > `gt`, `ge` as overrides; when present, the override is selected for
   > its operator. Both operands are observed, never consumed: `a < b`
   > compares the values `a` and `b` name, whether they are owned or views,
   > and a view of a type with neither primitive is a compile error, never
   > an address comparison — only raw pointers order by address (§16). The
   > prelude traits `Add`, `Sub`, `Mul`, `Div`, `MatMul`, `Neg`, `Eq`, and
   > `Ord` remain available for explicit bounds and documentation, but an
   > unbounded generic does not need to name them.

   Proposed replacement for the "Arithmetic and comparison operator
   methods" table: arithmetic rows unchanged (`+ add`, `- sub`, `* mul`,
   `/ div`, `@ matmul`, unary `- neg`); the comparison rows become a
   derivation table — `==` ← `eq(&other)`; `!=` ← `not eq(&other)`,
   override `ne`; `<` ← `cmp(&other) < 0`, override `lt`; `<=` ←
   `cmp(&other) <= 0`, override `le`; `>` ← `cmp(&other) > 0`, override
   `gt`; `>=` ← `cmp(&other) >= 0`, override `ge` — followed by
   `trait Eq: fn eq(self: &Self, other: &Self) -> bool` and
   `trait Ord: fn cmp(self: &Self, other: &Self) -> i32`, then the existing
   arithmetic trait listing introduced as "for the arithmetic operators".

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
