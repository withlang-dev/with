# Handoff — stdlib sourcing Phases 0/1/2 (2026-09-14)

Three worktrees under `~/.local/with-staging/`, one PR stack. Read this
whole file before touching any of them. Nothing here is reseeded.

| Worktree | Branch | PR | Tip | State |
|---|---|---|---|---|
| `fnabi-phase0` | `fnabi-phase0` | #1129 → main | 92bf3984 (2 new commits, unpushed) | battery IN PROGRESS, one red fixture (below) |
| `c-algorithms-phase1` | `c-algorithms-phase1` | #1138 → fnabi-phase0 | b247e05a + 2 uncommitted fixes | CI red on 3 lanes; local fixes unverified |
| `tommyds-phase2` | (no branch yet, off b247e05a) | none | all uncommitted | migrator+corpus work, nothing built since the fixes |

Standing rules: commits authored `Eric Hartford <eric@quixi.ai>`, no AI
attribution; never `git stash`; no python/bash/perl/sed/awk scripts (With
one-liners or `with run tool.w`); never `-O0`; take a keep_awake hold for
long runs (hold `hold:e3f18876` is active until ~06:40 — release or renew);
the Bash tool is zsh (no word split); never cite unprinted hashes; a migrate
workspace runs in the build DRIVER's compiler, so re-migration is
`WITH=out/release/bin/with out/release/bin/with build :<corpus>-promote`;
never `WITH=<stage1> <stage1> build` (#1116: a source-only stage1 cannot
compile programs reaching std.regex / src/main.w).

Scratchpad (session-local, may vanish):
`/private/tmp/claude-501/-Users-eric-with/073101c7-74ec-4cff-a1e2-4a17b88d45c4/scratchpad`
(`p0_build*.log`, `p0_fixpoint.log`, `p0_test.log`, `ab_*.log` unit timings,
`keep_bc/`, `keep_fix2/` unit bitcode + analysis scripts, `ci_linux/`,
`ci_winarm/` downloaded CI captures, `agg/big.w` aggregate-copy repro,
`loc/` __locale_data repro, `tm/gen5` TommyDS migration).

## 1. Phase 0 (#1129, `fnabi-phase0`) — the Windows x86_64 stage2 timeout, ROOT-CAUSED AND FIXED

Symptom: CI lane windows x86_64 stage2 exceeded 1801 s; other lanes green.

Root cause (observed, not inferred): the codegen-units emit of ONE unit took
635 s (reproducible on macOS: `WITH_CODEGEN_UNITS=16 WITH_PROFILE=1
./out/release/bin/with build out/gen/main.w --target windows_x86_64 -O1 -o
/tmp/x.exe`, read the `[profile] llvm.unitN` lines; rc=1 at link is only
the missing cross rt objects, ignore it). `sample` of the stuck thread:
`LLVMTargetMachineEmitToFile → SelectionDAGISel → DAGCombiner::visitSTORE →
checkMergeStoreCandidatesForDependencies → SDNode::hasPredecessorHelper`
(quadratic store merging). The IR feeding it: codegen moves a struct as
`store (load %T)`; the gen-time per-function `sroa,mem2reg` cleanup
(`run_mir_cleanup_passes`, src/CodegenDispatch.w) scalarizes that
first-class aggregate into a load+store PER LEAF (`Compilation` = 1660
leaves; comptime_eval_tool_action_result had a block with 4069 stores) —
main's run_cli had 4 such Compilation copies, the Phase 0 tree 30, because
the FnAbi call path also evaluated every IndirectPlace (mut-receiver)
operand and then discarded the value for the place address (a DEAD 1660-leaf
load before every `comp.configure(...)`-style call). Standalone `opt`+`llc`
on the same unit bitcode is fast because llc's default x86 tune is i586
while our TM passes CPU "generic" (tune=generic) — note for later, NOT
changed: `wl_init_target_machine` still passes `c"generic"`.

Fixes (committed on fnabi-phase0, unpushed):
- d7c75f28 `marshal_ref_operand` (src/CodegenDispatch.w): a place operand
  yields its address without materializing its value; the concrete call
  path's `needs_ref` branch and `mir_ref_arg_ptr` use it.
- 92bf3984 `wl_lower_aggregate_copies` (src/compiler/LlvmBridge.w), called
  from `run_mir_cleanup_passes` before sroa: `store (load %T)` with
  ABI size ≥ 64 → `llvm.memmove` (same pointer → dropped), `store
  zeroinitializer` → `llvm.memset`, use-less load erased. Plus
  `ensure_llvm_mem_intrinsic` in src/Codegen.w: the five hand-declared
  memcpy/memset declarations now reuse an existing declaration (LLVM
  declares them itself once a pass forms one; a second `wl_add_function`
  under the same name got a `.709` suffix and the verifier rejected it —
  that was the first rebuild's stage2 failure).

Evidence: every windows_x86_64 unit now emits in < 3 s (was 5–70 s + one at
635 s); darwin `with build` 484 s; `:fixpoint` GREEN (stage2 == stage3).

Battery state (isolation batch: codegen change alone):
- `with build` green, `:fixpoint` green.
- `:test` was running (log `p0_test.log`): compile-error 756 ok, codegen 16
  ok, spec 210 ok, phase 56 ok, comptime-diff 6 ok; **behavior-tests RED:
  `test/behavior/behav_derive_deserialize.w` exits 134, standalone
  `./out/release/bin/with run test/behavior/behav_derive_deserialize.w` →
  `panic: missing JSON field: name`.** Almost certainly the memmove/memset
  lowering (a struct copy or zero-init whose source/dest semantics differ
  from the scalar stores — suspects: memset of a struct with non-zero
  defaults? a `store zeroinitializer` that SROA previously split and a
  later partial store depended on? or memmove where the load had OTHER
  uses and the erase/keep logic left a stale value). Route: build the
  fixture with `WITH_DUMP_LLIR_PRE=1` (only the non-unit path dumps),
  diff against the same dump from `~/with/out/release/bin/with`, look at
  the deserialize function's memmove/memset. Fix, then rerun the full
  battery: `with build`, `:fixpoint`, `:test`, `:test-green`,
  `:last-green`, `:drop-audit`, `:move-audit` (codegen change ⇒ audits
  required). The test run may still be in flight — check
  `pgrep -fl 'with build :test'` before starting anything in that tree.
- Not yet checked whether the remaining tests after behavior-tests passed
  (survey continues past a failure; read `p0_test.log` to the end).
- Then push fnabi-phase0, confirm the windows x86_64 lane goes green, merge
  #1129, merge fnabi-phase0 into c-algorithms-phase1.

## 2. Phase 1 (#1138, `c-algorithms-phase1`) — three CI failures, two fixes drafted (UNCOMMITTED, UNBUILT)

CI captures were downloaded (`gh run download <run> -n <lane>-test-captures
-D <dir>` from inside a repo checkout; scratch `ci_linux/`, `ci_winarm/`).

a. linux x86_64 `test/spec/spec_ss16_ffi_and_c_import.w`: `unknown type
   '__locale_data'` from `use c_import("time.h")`. Cause: Phase 1 commit
   72e10671 replaced the ClangBridge hack "a record tag starting with `_`
   renders as c_void" with `clang_Cursor_isAnonymous` (needed so `_Trie`
   keeps identity), so glibc's `struct __locale_struct { struct
   __locale_data *__locales[13]; … }` now names `__locale_data` — a record
   declared only inside a member type, never at file scope, so it never
   entered the decl list and no `type __locale_data = opaque` was emitted
   (an explicit `struct __locale_data;` forward decl DOES render opaque —
   verified). Local repro: `scratch/loc/loc.c` / `loc2.w`.
   Fix drafted in `src/compiler/ClangBridge.w`: `session_append_decl`
   (factored from `collect_decl`), `session_decl_contains`,
   `collect_undefined_record_type` (walks pointer/array/function/typedef/
   elaborated types), `collect_member_record_types` visitor,
   `collect_undefined_records(s)` called after the main session's
   `clang_visitChildren(root, collect_decl, …)` (the one that sets
   `header_file = 0`; the two macro-session sites are untouched).
   `with check src/compiler/ClangBridge.w` ok. NOT built/tested: needs a
   build (the bridge is a separate object built by stage2), then
   `./out/release/bin/with migrate scratch/loc/loc.c --no-c-export -o x.w`
   must contain `type __locale_data = opaque`, and a new fixture (e.g.
   `test/behavior/behav_migrate_member_only_record.w`, single-TU, no fwd
   decl) should pin it.
b. linux x86_64 + windows aarch64 corpora lanes (`c_algorithms-wo-drift`,
   `c-algorithms-test`): `undefined symbol: __assert_rtn` — the corpus was
   migrated on macOS and Darwin's assert reporter does not exist elsewhere.
   Fix drafted in `lib/std/libc.w`: `__assert_rtn` and `__assert_fail` are
   now With functions (`libc_assert_failed` → `eprint` + `abort()`),
   header comment amended, `use std.builtins.eprint` + `extern fn
   with_str_from_cstr` added. `with check lib/std/libc.w` ok. NOT built:
   verify with `scratch/assertp/a.w` (expects the message + abort) and the
   corpora lane (`with build :c-algorithms-test`).
c. windows aarch64 `test/behavior/behav_migrate_assert_macro.w`: native
   Windows migration of `<assert.h>` bails (`untranslatable function …
   bailed at kind=111`, then `unsupported filtered system variable
   '_wassert'`): UCRT's assert expands to `_wassert(L"…", L"…", line)` with
   WIDE string literals, which the migrator does not lower. Not fixed. Two
   options: implement wide literals + a portable `_wassert` in std.libc, or
   `//! skip-on: windows #NNNN` with a filed issue (precedent exists for
   #799/#800 skips). Decide, file the issue either way.

After a+b build green locally: commit as two logical commits, run the Phase 1
battery (`with build`, `:fixpoint`, `:test` incl. corpora 17/17 and wo-drift,
`:test-green`, `:last-green`; the libc change is not a codegen change),
merge fnabi-phase0 in, push, watch #1138 lanes.

## 3. Phase 2 (`tommyds-phase2`, TommyDS whole-corpus) — all uncommitted

State: TommyDS 1f3727fc migrates 14/14 and its `check.c` (as `check_.w`,
renamed for the prelude collision) runs to `OK` (37 timed sections) under a
stage1 built from this tree (that stage1 is gone; `out/` was cleaned).
Uncommitted work, all in the tommyds-phase2 worktree:
- `build/tommyds.w` (new): pin, migrate/check-generated/promote/
  bundle-root-check/test actions, `tommy_pipeline(out, release_compiler)`;
  `build.w` wires `tommy_wo` at every `calg_wo` site, corpus exclusions in
  `build.w` and `build/runtime.w`, `std.tommyds` in `build/compiler.w`'s
  internal module list.
- `lib/std/tommyds/*.w`: the migrated corpus (15 files, no `bundle.w` yet —
  `:tommyds-promote` writes it).
- Migrator fixes in `src/CImport.w` + `src/CiPrint.w`: `__builtin_clz*/
  ctz*/popcount*/bswap*` lower structurally to `(x as uN).clz()` etc.
  (CIE_FIELD with d2=2 prints `base.method`); pointer-to-function-TYPEDEF
  → function pointer (`CXT_Typedef`/`CXT_Elaborated` canonicalized);
  libc allowlist `qsort`, `rand`, `srand`, `mach_absolute_time`,
  `mach_timebase_info` (FN|TYPE), `mach_timebase_info_data_t`,
  `kern_return_t`; `mach_timebase_info` calls need `unsafe`.
- `lib/std/libc.w`: `rand`, `srand`, `qsort` externs; portable mach clock
  (`mach_absolute_time` = runtime monotonic nanoseconds via
  `with_libc_mach_absolute_time` in `rt/rt_core.w`, timebase 1/1).
  NOTE: this tree's libc.w does NOT have the §2b assert change — merge
  c-algorithms-phase1 in first (it will also bring the ClangBridge fix and,
  after §1 lands, the codegen fixes).
- Fixtures written, never run: `test/behavior/behav_migrate_bit_builtins.w`,
  `behav_migrate_fn_typedef_pointer.w`, `behav_migrate_libc_qsort_clock.w`
  (portable), `behav_migrate_libc_mach_clock.w` (`//! only-on: darwin`).
Next: merge c-algorithms-phase1 (once green) into a new branch
`tommyds-phase2`; `with build`; run the four fixtures; `WITH=out/release/bin/with
out/release/bin/with build :tommyds-promote` (writes bundle.w), `:tommyds-wo`,
`:tommyds-test`, wo-drift lane; commit in logical pieces (migrator fixes with
fixtures, libc/rt bindings, build layer + corpus); docs: plan "Phase 2
status" (mirror the Phase 1 status block in `docs/stdlib_sourcing_plan.md`),
`docs/wo_bundles.md` (fourth bundle), this file; then the plan's Phase 2
design item (node ownership facades for hashdyn/hashlin/hashtable,
benchmarks vs c-algorithms hash table and rt_core HashMap, complexity/drop
evidence); battery; PR stacked on #1138.

## 4. Open follow-ups to file
- Aggregate copies below 64 bytes and struct-literal stores still
  scalarize (fine for LLVM, but the threshold is a guess; measure).
- `wl_init_target_machine` passes CPU "generic" (x86 tune=generic); llc's
  default is tune=i586. Consider matching clang (`x86-64` + tune generic)
  deliberately, with the A/B numbers.
- Unit bitcode is deleted after emit; a `WITH_KEEP_UNITS=1` switch would
  have saved an hour (this session copied files in a race).
- UCRT `_wassert` / wide string literals in the migrator (§2c).
