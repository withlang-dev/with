# Primary verification — `rt/fiber_core_darwin.w`

Status: **Complete**
Primary verifier: root agent
Source revision: `450733e5`
Source SHA-256: `ae7e93abecf6b90dd9505540e37c8cbc71230530bfd3501a40e837477d818eb0`
Source examined: all 1090 lines

## Scope examined

The complete module was read inline. It owns the Darwin scheduler core:
pthread-mutex-protected run queues (8 workers x 1024 ring slots), slot
table with generations (`fibers_by_slot`, `fiber_slot_generations`,
`free_fiber_slots`), fiber pool with stack guard pages, spawn/take/cancel/
panic paths, worker threads + work stealing, stack-overflow signal handling,
and init/shutdown. The 1024/8 bounds: `MAX_FIBERS = 1024` (`:51`),
`MAX_FIBERS_WORKERS = 8` (`:52`), `FIBER_SLOT_BITS = 10` / mask 1023
(`:55-56`); ids are `(generation << 10) | slot`, always positive
(`fiber_compose_id` `:342-343`, allocate bumps generation `:367-370`).

Applicable overview targets examined: 4 (scheduling/cancellation), 13–14
(spawn contract consumed by codegen), 15 (runtime foundations), 19
(platforms — Darwin-only paths), 23 (fail-loud discipline). Every
`rt_libc_abort` and early-return branch was traced.

## Behavioral matrix

Same executions as the sibling runtime modules, all exercising this exact
file's spawn/slot/recycle/take/steal paths at scale (seed stage1, `-O1`,
x86_64 Linux): despite the name, `build.w:629,640,672` compiles
`rt/fiber_core_darwin.w` as the fiber core for every Unix target including
Linux, so the probes below ran this module's code directly:

- `docs/audit/probes/fiber_spawn_cap_1024/bis.w` (1100 tasks): exact 1024
  boundary — exercises `with_fiber_spawn`'s `live_fiber_count >=
  MAX_FIBERS` -1 path (`:772-774`), slot allocation/generation bump,
  `take_completed` reap (`:834-856`), and `recycle_fiber`.
- `docs/audit/probes/fiber_spawn_cap_1024/dbg3.w` (3000 tasks, 1 and 8
  workers): deterministic zeros past index 1023.
- `/tmp/chantest` w4 runs (probe `docs/audit/probes/chan_race_w4/main.w`):
  work-stealing dequeue paths under contention — 1 segfault + 5 wrong sums;
  root-caused to the channel layer (sibling module), not to stealing here.

## Steal-race hypothesis — REFUTED (closes audit open question)

The pre-existing hypothesis of scheduler steal non-atomicity does not hold
for queue integrity: every queue/slot mutation runs under `scheduler_lock`
(pthread mutex, abort-on-error `:145-159`):

- `run_one_fiber_for_worker` holds the lock across
  `dequeue_for_worker` → `steal_from_worker` (`:653-662`); the lock-free
  `steal_from_worker` body (`:443-454`) is therefore single-threaded by
  construction, as are `pop_worker_local`, `enqueue_worker[_front]`, slot
  alloc/release, take/reap, cancel, and panic capture.
- `with_fiber_switch` runs unlocked, but only after the dequeued fiber is
  marked RUNNING and registered as the worker's current — no other worker
  can observe it as stealable.
- Generation-checked `fiber_lookup` (`:353-360`) closes ABA on slot reuse;
  reap (unregister + recycle) is atomic under one lock hold (`:853-855`).

Consequence: #991's multi-worker corruption is purely the channel layer's
missing synchronization (`rt/channel_runtime.w` takes no lock at all), not
stealing. No scheduler change is indicated by the channel evidence.

## FIBER-CAP-001 locus (filed #995, evidence in sibling module file)

This module is where the -1 originates (`:772-778`, three fail-loud-checked
branches returning -1: live-cap, slot-exhaustion, alloc/stack failure) and
where await's early-return is justified (`fiber_lookup(-1)` → 0 via
`fiber_slot_from_id` `:345-348`; `with_runtime_fiber_is_live` `:1031-1038`).
Valid ids are always > 0, so a `fiber_id <= 0` guard at the await/cancel
entry points (the convention `with_fiber_detach` already uses in
`rt/fiber_runtime.w:266,286`) is available without touching this module's
lookup semantics. No new defect retained here beyond the #995 chain.

## Notes (no finding)

- Telemetry-grade unlocked reads: `with_fiber_live_fibers` (`:1074-1075`),
  `with_fiber_steal_events/attempts` (`:1077-1081`),
  `with_fiber_worker_count` (`:1083-1084`), `cross_thread_cancels`
  (`:1089-1090`), and `current_worker_index`'s scan of
  `worker_thread_ids` (`:167-174`). Plain cross-thread reads without the
  mutex — benign counters/indices in practice; retained only as a pattern
  note for T22 (platform atomics), not a defect: no execution shows harm
  and all scheduling decisions read under lock.
- `with_fiber_configure` guard (`:761`) reads `live_fiber_count` /
  `free_pool_head` / `worker_threads_started` unlocked — pre-init
  configuration path; same benign class.
- Dead surface: `with_fiber_set_result` (`:909-912`) writes
  `FIBER_OFF_RESULT` (`:68`), which has no reader anywhere in `src/`, `rt/`,
  or `lib/` — the trampoline writes the Task result buffer directly. The
  declaration block in `src/CodegenDispatch.w:17586-17591` is likewise
  never called. Harmless; noted for a future dead-code sweep.
- `enqueue_panicked_fiber` silently drops when the 1024 panic ring is full
  (`:390-394`) — the one silent-drop branch in an otherwise fail-loud file
  (queue-full aborts at `:416-417`, `:425-426`; thread-spawn failure aborts
  at `:704-706`; post-DONE resume aborts at `:641`, `:957`). Reachable only
  with 1024 un-reaped panics; noted, not filed.
- `fiber_write_i32` (`:577-594`): `0 - value` on `INT32_MIN` would
  underflow inside a signal-handler diagnostic — purely latent (only
  reachable printing fiber id `i32::MIN`, impossible since ids are
  positive); noted, not filed.
- `allocate_stack_region` ignores `mprotect` failure (`:503`): a failed
  guard page degrades a future stack overflow from trapped fault to
  corruption. Silent but OS-failure-class; noted for T19, not filed.
- `recycle_fiber` decrements `live_fiber_count` only when `fiber_id(f) != 0`
  (`:549`); no double-recycle path found (reap unregisters first,
  shutdown visits only registered slots). Asymmetry read as defensive, not
  defective.
- Init zeroes generations (`:734`) while old handles could theoretically
  persist across `init` — full-id comparison fails safe (miss, not alias).
  Sound direction.
