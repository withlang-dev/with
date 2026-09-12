# Bindings acquire cleanup after initialization

The strengthened ownership audit at bd02ff27 found an uninitialized drop in
`ComptimeEvaluator.eval_toolfs_capability_method`: `_810` is `data`, whose
initializer returns early for invalid binary input. `--trace-ownership`
shows StorageLive at bb789, assignment at bb792, and uninitialized drops on
the early-return blocks bb806 and bb811.

The small phase regression reproduces the invalid drop as
`fn sym221 stmt3: drop of _2 ... (Uninit)`. The native debug-allocator run with
WITH_ALLOC_NO_REUSE=1 reports zero leaks for this particular stack layout;
that does not make the uninitialized drop valid. The ownership validator
detects the wrong edge independently of which bytes happen to occupy it.

LLDB on bd02ff27 stage1 stopped at MirBuilder.schedule_drop with body sym221,
local 2 and value-drop kind 0. Its caller is lower_let_binding+408:
`0x100904068` schedules cleanup, before the initializer's lower_expr call at
`0x1009040a0` and assignment at `0x1009040c8`. This proves the premature
schedule at MirLower.w:5736. Evidence: `/tmp/with-initializer-schedule-lldb.log`,
`/tmp/with-initializer-lowering-lldb.log`, and
`/tmp/with-initializer-return-verdict.log`.

The binding now schedules cleanup after acquiring its value. Early exits
inside the initializer cannot include that binding. Pure-view and discarded
bindings retain their existing ownership behavior.

The validator also needs to model StorageLive's explicit zero-initialization
marker. The zero-storage phase fixture failed as `fn sym222 stmt1` on the
old compiler, while its emitted `empty` IR stores null/zero in all four Vec
fields before calling drop glue. The producer is CodegenDispatch.w:5466-5474;
the transfer function ignored d1. `/tmp/with-zero-init.ll` and
`/tmp/with-zero-init-verdict.log` record both sides. Direct MIR tests require
zero-initialized storage to pass and ordinary uninitialized storage to fail.

Module ownership validation now reports each failing body in one run. The
previous first-body return forced repeated full compiler audits before later
failures became visible; a two-body malformed MIR test guards this coverage.
