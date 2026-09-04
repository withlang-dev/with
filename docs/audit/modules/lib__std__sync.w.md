# Primary verification — `lib/std/sync.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified,
sync leg topped up by primary full read + probe re-runs)
Source revision: `450733e5`
Source SHA-256: `a31e6d6ebc101b9f882a76329878b67e7fb06b67673d00db75ebc735b4e90df4`
Source examined: all 443 lines (primary read 1-120, 120-320, 320-443 — complete)

## Scope examined

Synchronization primitives over compiler atomic intrinsics: `Order` enum
(`:12-17`), `fence` stub replaced by MIR lowering (`:20-22`), `Atomic[T]`
(`:25-27`), spin Mutex + guards (`:115-219`), RwLock + guards (`:234-322`),
Once with panic-reset (`:324-353`), Condvar wait/notify (`:355-394`),
generation Barrier (`:396-424`), compat aliases (`:430-443`).

Applicable overview targets examined: 4 (fiber-aware blocking via
`sync_wait_for_progress`), 10 (stdlib foundations), 15 (atomic
discipline — the direct contrast with `rt/channel_runtime.w`'s plain i32s),
23 (silent clamps/defaults).

## Behavioral matrix

Probes in `docs/audit/probes/chan_sync_surface/`, re-run by primary with seed
stage1 at 450733e5 (all `check` rc=0):

- `sync_surface.w`: `run` prints `sync-surface-ok` rc=0 (Once + mutex
  basics; incidental `unsafe global access` warnings only).
- `sync_coord_surface.w`: `run` prints `coord-ok` rc=0 — Condvar
  waiter/notifier rendezvous + Barrier cross. Positive control: the
  fiber-aware coordination this module promises works.

## Verdict: sound direction, no filed finding

- Lock/unlock orderings pair correctly throughout: mutex spinlock
  `swap(Acquire)` / `store(Release)` (`:117`, `:122`); RwLock
  `CAS(Acquire,Relaxed)` with `fetch_sub/store(Release)` release
  (`:240`, `:251`, `:262`, `:270`, `:281`, `:293`); Condvar
  waiters/signals `AcqRel` (`:365-390`).
- `Once.call_once` panic path resets state to 0 via defer (`:340-342`) —
  matches the documented retry contract (`:92-93`).
- Barrier generation protocol (`:404-424`) resets `arrived` and bumps
  `generation` under the spinlock; waiters compare generations. Leader
  election via arrival order. Correct shape.
- `MutexGuard`/`RwReadGuard` carry `@[no_await_guard]` (`:64`, `:70`,
  `:81`, `:87`) — holding a lock across `.await` is an E0701-class error
  by construction, the right call for non-recursive spinlocks.

## Notes (no finding — analyzed, not filed)

- `notify_one`/`notify_all` take only `&self` with no documented requirement
  to hold the associated mutex. A notifier that never locks can lose a
  wakeup against a waiter that registers between the waiters-check and the
  signal (classic lost-wakeup shape, `:381`, `:388`). Correct usage (notify
  under the mutex, predicate recheck in a loop — as the coord probe does)
  is safe, but the contract is undocumented. Not filed: no deterministic
  execution demonstrates it, and the module's own probe models the safe
  pattern. Recommend documenting the hold-the-lock contract.
- `Barrier.new(0)` silently clamps to 1 party (`:398`). Trivial silent
  default; noted, not filed.
- Drop-while-held (Mutex/RwLock/Condvar/Barrier Drop impls free state
  without checking lock words) relies on the borrow checker to prevent
  live-guard drops. No escape demonstrated; standard unsafe-adjacent
  posture for this file, noted.
- Guards' `exit()` requires `T: Copy` (`:157`, `:165`, `:258`, `:266`) —
  non-Copy values exit via the Scoped traits or Drop. Coherent, documented
  by signatures.
