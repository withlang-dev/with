# #783 layout-sensitive UAF — investigation state (2026-08-15 ~02:00)

## Pinned reproduction (STABLE — 12/12)

```
env -i PATH=/usr/bin:/bin HOME=/Users/eric \
  ./out/release/bin/with test test/spec/spec_ss03_9_box_dyn_coercion.w   # FAILS
env -i PATH=/usr/bin:/bin HOME=/Users/eric X=1 \
  ./out/release/bin/with test test/spec/spec_ss03_9_box_dyn_coercion.w   # PASSES
```

Any env/argv byte change re-rolls the lottery (adding ONE var flips it; `check`
vs `test` argv flips it; `analyze` argv always passes). ONLY observe through
lldb with `settings set target.inherit-env false` + explicit env-vars and the
exact `test` argv — anything else observes a different world.

## What is known (hard evidence)

- Failure: MIR lowering of `let logger: Box[dyn T] = Box.new(...)` — callee
  falls through to variable lookup (`[mir-var-miss] sym=Box`), and audit:all
  reports `sig 196 (Box.drop__receiver__358_357): receiver requirement is not
  the finalized param[0] effect`.
- Causal commit a9522944 is 7 ComptimeEval lines that NEVER execute in this
  compile (lldb: 0 hits) — pure binary-layout butterfly.
- MallocScribble=1 → passes: a branch reads FREED memory and heap garbage
  decides it. GuardMalloc/debug-alloc also flip it (layout again).
- Worktree build at 5ff91b70 passes the same tests; its analyzer shows the MIR
  call fact `Box.new__receiver__359_106_106 sig=194 mono=786` that the bad
  world lacks.
- Probably same class as the test-driver crash on every battery failure path:
  `corrupt vec header at free ... origin=drop#struct __drop_struct_220`.
- Predates this session's ownership fixes (panic seen in take 5, before #780).

## Misleads already burned

- `check_generic_method_body_concrete` breakpoint: exactly ONE hit in BOTH
  failing and passing envs (x2=0x239 x3=0x184) — either not the divergence
  point or my register reading of its args is wrong. Only 3 `__receiver__`
  name producers exist (SemaCheck.w 17136/17244/17299).
- Both envs' `analyze facts` dumps are byte-identical (8670 facts) and DO
  contain the Box.new specialization — because the analyze argv re-rolls the
  lottery. Do not trust any observation that changes argv/env.
- The seed-built stage1 has a SEPARATE frozen-seed miscompile
  (&str.starts_with(&str) → with_str_from_cstr injection). Ignore stage1
  behavior entirely; use release/stage2.

## Next step (planned, not started)

In the pinned failing lldb config: breakpoint `mark_unsupported` (MirLower) —
catches the failure moment with NO env change; `bt` to the exact call-lowering
branch that failed its lookup; identify which sema table lookup missed; then
re-run with a watchpoint on that table's backing store to catch the free.

## State

`with build :test` currently red on spec_ss03_9_box_dyn_coercion +
spec_ss11_3_object_safety (cached-red, battery aborts there). Everything else
green: build/fixpoint/move-audit/drop-audit/debug-alloc + all other test
targets. RESEED IS BLOCKED until this is green (and the reseed go/no-go should
weigh #783 explicitly — installing a compiler with a live UAF lottery as seed).
