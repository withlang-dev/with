# Primary verification — `lib/std/thread.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 37 lines (single complete read)

## Scope examined

OS-thread facade: `with_thread_spawn`/`with_thread_join` externs (`:4-5`),
`RawFn0I32` transmute shim (`:7-10`), `JoinHandle` (`:13-15`), ephemeral
`ScopedJoinHandle` (`:18-22`, produced by the compiler-builtin
`scope s =>: s.spawn(...)`, not by this module), `spawn_os` (`:31`, named
fn or `() =>` closure worker via transmute), `join(&JoinHandle)` (`:36-37`,
call-site auto-refs). Runtime: `rt/rt_core.w:1302` (`with_thread_spawn`,
null-fn_ptr guard, per-thread `RtThreadStart` alloc) and `:1317`
(`with_thread_join`, frees start block, returns worker result).
Callers: `test/behavior/behav_std_thread_spawn_{os,closure}.w`,
`test/compile_errors/err_{spawn_os_captures_rc,thread_spawn_closure_captures_ref,ephemeral_task_in_spawn_os_worker,scoped_join_handle_struct_storage}.w`
(Send/capture gates), `lib/std/prelude.w:14` (re-export). No lib callers.

## Behavioral matrix (all EXECUTED, race-free by construction)

- `docs/audit/probes/thread/spawn_join_fn.w`: named `fn worker() -> i32`
  returns 37, `join(handle) == 37`. PASS (`ok`).
- `docs/audit/probes/thread/spawn_closure_capture.w`: `spawn_os(() => base+2)`
  with `base = 5` returns 7 (capture by value across the thread). PASS.
- `docs/audit/probes/thread/spawn_fanout_sum.w`: 4 threads returning disjoint
  constants 10/20/30/40, joined and summed == 100 — schedule-independent,
  no shared mutation. PASS.
- `docs/audit/probes/thread/scoped_spawn.w`: `scope s =>: s.spawn(() => base+2)`,
  `handle.join() == 42`. PASS (covers the `ScopedJoinHandle` producer path).
- `with check lib/std/thread.w` → ok (stage1).
- Repo tests re-run verbatim: `behav_std_thread_spawn_os`,
  `behav_std_thread_spawn_closure`, `behav_scope_spawn` — all print `ok`.

## Findings

None. In-report notes (not filed):
- `join` takes `&JoinHandle` but every call site spells `join(handle)` —
  auto-ref at the call site; signature is authoritative, no action.
- `spawn_os` has no `@[effect]` pin by design (D30 R2b, comment `:25-30`):
  `fn() -> i32` is Copy; Send-capture is still enforced (the two
  `err_spawn_os_*`/`err_thread_spawn_*` negative tests gate it).
- No shared-mutable-memory probe: intentionally HELD — any such probe
  would be racy by construction, and the module offers no
  synchronization primitive to make one deterministic.

Verdict: COMPLETE
