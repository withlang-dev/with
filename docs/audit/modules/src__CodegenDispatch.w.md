# Primary verification — `src/CodegenDispatch.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `87e4cbb61411fbdfc1b8c22d109602e47005e0ad846153a92f6e4b2db78427f2`
Source examined: child 18821 complete (10 sed-verified chunks + deep reads
1-2000, 5600-6299, 10070-10329), findings none reported; primary seam review
(full reads): async spawn emitters :18362/:18449-18464 (from #995),
FIBER_AWAIT lowering :10078-10168 (from #995), extern decls :17586-17591,
`marshal_mir_call_arg` + `mir_eval_call_arg_range` :5628-5652,
`mir_emit_dyn_trait_call` :6905-6984, plus all-probe runs below

## Scope examined

MIR→LLVM dispatch: call marshalling, async spawn/await, dyn dispatch, extern
declarations, receiver shapes.

Applicable overview targets examined: T2-3 (call/ABI marshalling), T4 (async
lowering), T13-14 (emission validity), T23 (fallbacks), T24 (Codegen.w overlap).

## Behavioral matrix

All 3 probes in `docs/audit/probes/codegendispatch/` run by primary, all rc=0:
`p1_call_struct` (`call=6`), `p2_async_spawn` (`await=42`), `p3_extern_cstr`
(`cstr=hi`).

## Verdict: no new finding; two D6-relevant confirmations

- Call-arg path is D6-COMPLIANT in this file: `marshal_mir_call_arg`
  reads the canonical Sema verdict (`sig_param_uses_value_ref_abi`, :5635),
  missing signatures go loud (`had_error=1`, :5631-5634), and
  `mir_eval_call_arg_range` funnels every user call path through it
  ("branch-local template guesses are forbidden", :5642-5644). This sharpens
  the Codegen.w ABI-001 note: the per-path-classifier risk sits on the
  DECLARATION side (`declare_function_at_inner` inline chain), not the call
  side. No divergence demonstrated anywhere — consistent with ABI-001's
  record-don't-file status.
- Dyn call emission is fail-loud at every malformed step (missing symbol/
  receiver/non-dyn/trait metadata/method/bad lowering/bad fn type,
  :6915-6946 + sret guards). The ONLY silent dyn hole is the null slot
  CONTENT (#1002), which this call site cannot detect (a loaded null looks
  like any pointer) — confirming #1002's fix belongs at vtable construction.
- Async spawn/await emitters previously verified under #995 (unchecked -1
  stored into Task.fiber_id); no additional defect found on re-review.

## Notes

- Child reported no findings for this file; primary's seam review (the four
  highest-risk regions) independently found none either. Residual risk is
  proportional to the file's size (18.8k lines); the highest-risk seams are
  now primary-read, which is where defects in this file have historically
  lived (#995, #1002-adjacent).
