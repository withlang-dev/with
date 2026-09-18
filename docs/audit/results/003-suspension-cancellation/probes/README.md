# Audit 003 probe rerun guide

These probes are report-only evidence. They assert the specified behavior, so a
confirmed defect normally ends with exit `1`, `124`, `134`, or `139`; a failing
probe must not be reinterpreted as a passing test.

All commands below run from the repository root unless a different working
directory is shown. The audited compiler is:

```text
./out/bootstrap/bin/with-stage1
```

Every `.w` probe first uses the same static command:

```text
rtk ./out/bootstrap/bin/with-stage1 check \
  docs/audit/results/003-suspension-cancellation/probes/<probe>.w \
  --validate-all
```

Unless the table says otherwise, runtime probes use:

```text
rtk timeout 10s ./out/bootstrap/bin/with-stage1 run \
  docs/audit/results/003-suspension-cancellation/probes/<probe>.w \
  --debug-alloc --debug-alloc-filter=non-root
```

Allocator addresses vary between runs. The stable evidence is exit status,
message class, allocation size/origin, count, markers, drop count, and liveness
count.

## Await and ordinary-call matrix

| Probe | `check --validate-all` | Stable runtime outcome |
|---|---|---|
| `await_copy_unit_cancel.w` | exit 0, `validate-all: ok` | exit 0, `await-copy-unit-cancel-ok`, leak count 0 |
| `await_owned_normal.w` | exit 0, `validate-all: ok` | exit 0, `await-owned-normal-ok`, leak count 0 |
| `await_direct_shapes_cancel.w` | exit 0, `validate-all: ok` | exit 1 after `copy`, `unit`, `owned`; `invalid free addr=<garbage>` |
| `await_tuple_parent_cancel.w` | exit 0, `validate-all: ok` | exit 134; prints live-fiber excess `2`, then liveness assertion |
| `await_tuple_child_cancel.w` | exit 0, `validate-all: ok` | exit 124 after printing parent-cancelled `1` and live-fiber excess `2` |
| `await_nested_parent_cancel.w` | exit 0, `validate-all: ok` | exit 0, `nested-parent-cancel-ok`, leak count 0 |
| `await_child_cancel.w` | exit 0, `validate-all: ok` | exit 0; prints cancelled `1`, continuation marker `0`, leak count 0 |
| `await_owned_self_cancel.w` | exit 0, `validate-all: ok` | exit 0 in isolation; `owned-self-cancel-ok`, leak count 0 |
| `await_matrix.w` | exit 0, `validate-all: ok` | direct case restores `0 0`; tuple case prints `0 2` and exits 134 |
| `ordinary_call_semantics.w` | exit 0, `validate-all: ok` | exit 134; prints continuation count `5`, defer count `4` |
| `ordinary_call_owned.w` | exit 0, `validate-all: ok` | exit 134; prints continuation count `1` |
| `dynamic_trait_cancel.w` | exit 0, `validate-all: ok` | exit 134; prints continuation count `1` |
| `race_matrix.w` | exit 0, `validate-all: ok` | exit 0; ten scheduler offsets, repeated cancel, `race-matrix-ok`, leak count 0 |

The repository #916 fixture is run directly:

```text
rtk ./out/bootstrap/bin/with-stage1 check \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w --validate-all
rtk timeout 10s ./out/bootstrap/bin/with-stage1 run \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w \
  --debug-alloc --debug-alloc-filter=non-root
```

Stable outcome: the check exits 0 with `validate-all: ok`; execution exits 1
with `origin=drop#struct __drop_struct_94` and `pointer is not an allocated
payload start`.

## Select matrix

| Probe | Mode/outcome | Stable runtime outcome |
|---|---|---|
| `select_parent_cancel.w` | unbiased, parent cancelled while no winner | exit 124 in `join_cleanup` |
| `select_parent_cancel_biased.w` | biased, same outcome | exit 124 in `join_cleanup` |
| `select_cancelled_winner.w` | biased, cancelled child is ready winner | exit 134; prints arm `1`, parent-cancelled `0` |
| `select_cancelled_winner_unbiased.w` | unbiased, only cancelled child ready | exit 134; prints arm `1`, parent-cancelled `0` |
| `select_panic_cleanup.w` | winner panics, sibling owns defer | exit 134; prints `select child panic`; no sibling-cleanup marker |
| `select_cancelled_owned_winner.w` | owned result from cancelled winner | check exits 0; run exits 1 during codegen: `actual=i32 expected=Resource fn=choose` |

Positive controls `test/spec/spec_ss14_9_select_await.w` and
`test/spec/spec_ss14_10_fair_select_await.w` both exit 0 with allocator leak
count 0. `test/debug_alloc/da_async_cancel_drops_live.w` proves a normal select
loser is dropped once and ends with leak count 0.

## Channel matrix

| Probe | Stable runtime outcome |
|---|---|
| `channel_recv_cancel.w` | exit 124: empty/open receive never consumes cancellation |
| `channel_send_cancel.w` | exit 124: full bounded send never consumes cancellation |
| `channel_cancel_wake_race.w` | exit 134 after wake; prints cancelled `1`, reported-cancelled `0` |
| `channel_owned_cancel_wake.w` | exit 134; prints reported-cancelled `0`, post-wake continuation `1`, payload drops `2` |

The last probe proves payloads still transfer/drop exactly once in that
interleaving, but cancellation is lost and source after the blocked send runs.
Normal controls `test/behavior/behav_channel_bounded.w`,
`test/debug_alloc/da_channel_task_fiber.w`,
`test/spec/spec_ss14_15_channel_generic_payloads.w`, and
`test/spec/spec_ss14_15_channel_drops_queued_payloads.w` exit 0 with leak count
0.

## Synchronization matrix

| Probe | Wait | Stable runtime outcome |
|---|---|---|
| `sync_mutex_cancel.w` | contended mutex enter, release after cancel | exit 134; continuation `1`, reported-cancelled `0` |
| `sync_rwlock_read_cancel.w` | reader behind writer | exit 134; continuation `1`, reported-cancelled `0` |
| `sync_rwlock_write_cancel.w` | writer behind reader/writer | exit 134; continuation `1`, reported-cancelled `0` |
| `sync_condvar_cancel.w` | unsignalled condvar | exit 124 |
| `sync_barrier_cancel.w` | missing barrier party | exit 124 |
| `sync_once_cancel.w` | waiter behind non-returning initializer | exit 124 |
| `sync_condvar_cancel_wake.w` | cancel then notify | exit 134; reported-cancelled `0`, continuation `1` |
| `sync_barrier_cancel_wake.w` | cancel then last party arrives | exit 134; reported-cancelled `0`, continuation `1` |
| `sync_once_cancel_wake.w` | cancel waiter then release initializer | exit 134; reported-cancelled `0`, continuation `1` |

Normal controls for mutex, rwlock, once, condvar, and barrier are the
`test/spec/spec_ss14_17_*` fixtures; each exits 0 with allocator leak count 0.

## `no_suspend` effect matrix

These direct or statically named controls correctly exit 1 with E0702:

- repository direct-await, select, channel, mutex, rwlock, condvar, and barrier
  negative fixtures;
- `err_no_suspend_two_wrappers.w` (two statically named wrappers around direct
  await);
- `err_no_suspend_once_direct.w`;
- `err_no_suspend_join_cleanup_wrapper.w`.

These probes incorrectly exit 0 with `validate-all: ok`:

- `err_no_suspend_callable_param.w`;
- `err_no_suspend_callable_two_wrappers.w`;
- `err_no_suspend_dyn_trait.w`;
- `err_no_suspend_mutex_wrapper.w`;
- `err_no_suspend_mutex_set_wrapper.w`;
- `err_no_suspend_rwlock_wrapper.w`;
- `err_no_suspend_rwlock_write_wrapper.w`;
- `err_no_suspend_once_wrapper.w`;
- `err_no_suspend_condvar_wrapper.w`;
- `err_no_suspend_barrier_wrapper.w`;
- `err_no_suspend_channel_wrapper.w`.

Each file contains its own `//! expect-error: E0702` contract and minimal
wrapper/callable boundary.

## Completed result and stored-task ownership

| Probe | Stable runtime outcome |
|---|---|
| `cleanup_result_ownership.w` | exit 134: normal awaited Resource drops once; completed `join_cleanup` leaves drop count at 1 instead of 2 |
| `cleanup_join_owned_leak.w` | exit 0; drop count `0`; one 32-byte `with_alloc` leak |
| `cleanup_drop_owned_leak.w` | exit 0; drop count `0`; one 32-byte `with_alloc` leak |
| `stored_task_drop.w` | exit 0; two 16-byte `with_alloc` leaks for `Vec[Task[i32]]` |
| `stored_task_struct_drop.w` | exit 0; one 16-byte task result-buffer leak |
| `stored_task_option_drop.w` | exit 0; one 16-byte task result-buffer leak |
| `stored_task_tuple_drop.w` | exit 0; two 16-byte task result-buffer leaks |

`test/spec/spec_ss14_async_await.w` is an independent repository witness: it
prints its expected output but the allocator reports two 32-byte leaks from its
`Vec[Task[i32]]` storage case.

## Panic observations

Panic probes omit the allocator flag so the panic path itself is the observed
event:

```text
rtk timeout 10s ./out/bootstrap/bin/with-stage1 run \
  docs/audit/results/003-suspension-cancellation/probes/<probe>.w
```

- `panic_direct_cleanup.w`: exit 134, `direct child panic`; parent defer marker
  absent.
- `select_panic_cleanup.w`: exit 134, `select child panic`; loser defer marker
  absent.
- `test/behavior/behav_async_scope_panic_cancels_siblings.w`: exit 134 and
  prints `sibling cleanup` before the panic.
- `test/behavior/behav_async_panic.w`: exit 134 and prints its expected `done`
  marker before the panic.

The direct-parent-defer expectation is retained as a contract question. Select
loser cleanup is part of structured select cancellation and is a confirmed
protocol defect.

## Four-worker stress and LLDB root proof

The dedicated project enables four workers in `threaded/with.toml`. From
`docs/audit/results/003-suspension-cancellation/probes/threaded/`:

```text
rtk ../../../../../out/bootstrap/bin/with-stage1 check main.w --validate-all
rtk ../../../../../out/bootstrap/bin/with-stage1 build main.w -o threaded_probe
rtk timeout 20s ./threaded_probe --debug-alloc --debug-alloc-filter=non-root
```

The check and build exit 0. The program first prints worker count `4`. Ten
direct executions all failed before the expected cancellation count `640`:
observed exits included 134, 139, a pthread mutex-owner assertion, and debug
allocator invalid frees. Three post-rebuild samples were 134, 139, 134.

Current `nm` evidence:

```text
rtk nm ./threaded_probe | rtk rg \
  'worker_current_fibers|recycle_fiber|with_runtime_take_completed_fiber'
0000000000216380 T __with_mod_3141101948886044325__recycle_fiber
000000000023a0c0 B __with_mod_3141101948886044325__worker_current_fibers
0000000000217b90 T with_runtime_take_completed_fiber
```

This LLDB command stops only when `recycle_fiber` receives a fiber still present
in one of the four current-worker slots:

```text
rtk lldb --batch \
  -o "breakpoint set --name recycle_fiber --condition \
      '\$rdi == *(long*)0x23a0c0 || \
       \$rdi == *(long*)0x23a0c8 || \
       \$rdi == *(long*)0x23a0d0 || \
       \$rdi == *(long*)0x23a0d8'" \
  -o run \
  -o 'register read rdi' \
  -o 'memory read --format x --size 8 --count 4 0x23a0c0' \
  -o 'thread backtrace all' \
  -- ./threaded_probe --debug-alloc --debug-alloc-filter=non-root
```

Observed stop:

```text
thread #4: recycle_fiber at rt/fiber_core_darwin.w:547
rdi = 0x00007ffff5d73fe0
worker_current_fibers[0] = 0x00007ffff5d73fe0
frame #1: with_runtime_take_completed_fiber at rt/fiber_core_darwin.w:854

thread #1:
frame #5: finish_scheduler_turn at rt/fiber_core_darwin.w:644
frame #6: run_one_fiber_for_worker at rt/fiber_core_darwin.w:664
```

Thus the exact control block being recycled is still registered as a current
worker fiber while the worker returning from its context switch is waiting to
finish the scheduler turn. Hard-coded addresses are current-binary evidence;
after rebuilding, rerun `nm` and substitute the new array base.

One LLDB-slowed execution survived memory corruption long enough to print
cancellation count `628` and fail the `640` assertion. That is the executable
witness for the separate global `last_await_*` status-cache race.
