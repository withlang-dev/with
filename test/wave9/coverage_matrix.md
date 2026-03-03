# Wave 9 Coverage Matrix

Stage0 script coverage mapping to Wave 9 corpus/harness buckets.

| Stage0 Script | Coverage State | Wave 9 Evidence | Notes |
| --- | --- | --- | --- |
| `run_phase4_async_fn_lowering_tests.sh` | `COVERED` | `check/run|test/wave9/cases/async_basic_ok.w`, `check/run|test/wave9/cases/spawn_async_fn_ok.w` | Async fn call/await + spawn path covered. |
| `run_phase4_await_lowering_tests.sh` | `COVERED` | `check|test/wave9/cases/await_non_task_fail.w`, `check/run|test/wave9/cases/await_tuple_ok.w` | Single-task and tuple-await coverage. |
| `run_phase4_async_block_tests.sh` | `KNOWN_DIVERGENCE` | `run|test/wave9/cases/async_block_inline_await_ok.w` | Stage0 run instability (`incorrect alignment`) tracked in corpus. |
| `run_phase4_async_scope_tests.sh` | `COVERED` | `check/run|test/wave9/cases/async_scope_track_and_await_ok.w`, `check|test/wave9/cases/track_non_task_fail.w`, `check|test/wave9/cases/track_outside_fail.w` | Scope + `track()` rules covered. |
| `run_phase4_select_await_tests.sh` | `KNOWN_DIVERGENCE` | `run|test/wave9/cases/select_await_prefer_fast_ok.w`, `check|test/wave9/cases/select_non_task_fail.w`, `check|test/wave9/cases/select_empty_fail.w` | Stage0 run instability on winner-path case tracked in corpus. |
| `run_phase4_spawn_tests.sh` | `COVERED` | `check/run|test/wave9/cases/spawn_async_fn_ok.w`, `check|test/wave9/cases/spawn_non_task_fail.w` | Spawn accept/reject paths covered. |
| `run_phase4_task_must_use_tests.sh` | `COVERED` | `build|test/wave9/cases/task_must_use_call_warn.w`, `build/run|test/wave9/cases/task_must_use_await_ok.w` | `E0801` warning/no-warning behavior covered. |
| `run_phase4_task_ephemerality_tests.sh` | `COVERED` | `build|test/wave9/cases/task_ephemeral_borrow_warn.w` | Ephemeral task escape warning covered. |
| `run_phase4_runtime_linkage_tests.sh` | `COVERED` | `build/run|test/wave9/cases/runtime_linkage_sync_ok.w`, `build/run|test/wave9/cases/runtime_linkage_async_ok.w` | Sync + async runtime-linkage smoke behavior covered. |
| `run_phase4_channel_tests.sh` | `COVERED` | `run|test/wave9/cases/channel_send_owned_ok.w` | Channel send/recv runtime path covered. |
| `run_phase4_task_cancel_tests.sh` | `COVERED` | `run|bootstrap/test/cases/task_cancel.w` | Task cancel runtime path covered. |
| `run_phase4_send_sync_scopedsend_tests.sh` | `COVERED` | `check|test/wave9/cases/channel_send_ephemeral_fail.w` | Send/Sync channel payload rejection path covered. |
| `run_phase4_fiber_context_switch_tests.sh` | `COVERED` | `run|bootstrap/test/cases/async_multi.w` | Multi-task scheduling/context switching path covered. |
| `run_phase4_fiber_pool_reuse_tests.sh` | `COVERED` | `run|bootstrap/test/cases/fiber_pool_reuse.w` | Fiber pool reuse runtime path covered. |
| `run_phase4_scheduler_work_steal_tests.sh` | `COVERED` | `run|bootstrap/test/cases/fiber_work_steal.w` | Work-steal runtime path covered. |
| `run_phase4_stack_limits_tests.sh` | `COVERED` | `run|bootstrap/test/cases/fiber_stack_limits.w` | Fiber stack-limit runtime path covered. |
| `run_phase4_std_net_scheduler_tests.sh` | `COVERED` | `run|bootstrap/test/cases/import_std_net.w` | std.net scheduler/runtime path now matches Stage0 run behavior. |
| `run_phase4_std_signal_tests.sh` | `COVERED` | `run|bootstrap/test/cases/import_std_signal.w` | std.signal scheduler/runtime path covered. |
| `run_phase4_milestone_25_17_25_18_tests.sh` | `COVERED` | `run|test/wave9/cases/async_scope_track_and_await_ok.w`, `build|test/wave9/cases/task_must_use_call_warn.w`, `build|test/wave9/cases/spawn_async_fn_ok.w` | Milestone async/task semantics represented by Wave 9 cases. |
| `run_phase2_denied_patterns_tests.sh` (`E0701`) | `COVERED` | `check|test/wave9/cases/may_suspend_guard_fail.w` | Guarded may-suspend rule covered. |
