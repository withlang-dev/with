// std.task — Task type and collection-level async combinators.
//
// Task[T] is an opaque handle to a running fiber. It contains the fiber_id
// and a pointer to the heap-allocated result buffer where the fiber writes
// its return value. The T parameter is for type safety in sema.

use std.collections
use std.result

extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_is_cancelled() -> i32
extern fn with_fiber_yield() -> Unit
extern fn with_runtime_fiber_completion_sequence(fiber_id: i32) -> i64
extern fn with_runtime_has_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

/// Opaque handle to a running fiber. Returned by async fn calls.
/// The result_buf points to a heap-allocated buffer where the fiber
/// writes its return value. Await loads from it and frees it.
pub type Task[T] { fiber_id: i32, result_buf: *mut u8 }

/// Scope-owned task handle returned by `async scope`'s `s.track(...)`.
/// It has the same ABI as Task[T], but its cleanup is owned by the scope,
/// so dropping the handle itself does not cancel the fiber.
pub type ScopedTask[T] ephemeral { fiber_id: i32, result_buf: *mut u8 }

async fn task_cancel_point(): ()

fn task_wait_for_progress():
    if with_fiber_in_fiber() != 0:
        with_fiber_yield()
        return
    if with_runtime_has_fibers() != 0:
        with_runtime_run_one_step()

fn task_first_completed[T](pending: &Vec[Task[T]], finished: &Vec[i32]) -> i32:
    var winner = -1
    var winner_sequence: i64 = 0
    var i = 0
    while i < pending.len() as i32:
        if finished[i] == 0:
            let sequence = with_runtime_fiber_completion_sequence(pending[i].fiber_id)
            if sequence > 0 and (winner < 0 or sequence < winner_sequence):
                winner = i
                winner_sequence = sequence
        i = i + 1
    winner

/// Await all tasks. Returns Vec[T] in input order.
/// Fails fast on first Err.
pub fn await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[Vec[T], E]:
    let pending: Vec[Task[Result[T, E]]] = Vec.new()
    for task in tasks.into_iter():
        pending.push(task)

    let total = pending.len() as i32
    let finished: Vec[i32] = Vec.new()
    let order: Vec[i32] = Vec.new()
    let values: Vec[Option[T]] = Vec.new()
    var i = 0
    while i < total:
        finished.push(0)
        order.push(i)
        let empty: Option[T] = None
        values.push(empty)
        i = i + 1

    var cleanup_i = 0
    defer:
        // Awaited tasks are removed from pending in lockstep with
        // finished/order, so everything still here is un-awaited and the
        // bound is the live length (the await_first pattern).
        while cleanup_i < pending.len() as i32:
            pending[cleanup_i].join_cleanup()
            cleanup_i = cleanup_i + 1

    while pending.len() > 0:
        let ready = task_first_completed(&pending, &finished)
        if ready < 0:
            task_wait_for_progress()
            if with_fiber_is_cancelled() != 0:
                task_cancel_point().await
            continue

        // D27/D33: remove transfers — await needs the owned Task; `order`
        // remembers the original slot for in-order results.
        let orig: i32 = order[ready]
        order.remove(ready)
        finished.remove(ready)
        let result = pending.remove(ready).await
        if result.is_ok():
            with values.slot(orig) as mut slot:
                slot.set(Some(result.unwrap()))
        else:
            return Err(result.err().unwrap())

    let ordered: Vec[T] = Vec.new()
    while values.len() > 0:
        ordered.push(values.remove(0).unwrap())
    Ok(ordered)

/// Await all tasks (infallible version). Returns Vec[T] in input order.
pub fn await_all[T](tasks: impl IntoIter[Task[T]]) -> Vec[T]:
    let pending: Vec[Task[T]] = Vec.new()
    for task in tasks.into_iter():
        pending.push(task)

    let values: Vec[T] = Vec.new()
    var cleanup_i = 0
    defer:
        // Awaited tasks were removed, so everything live is un-awaited.
        while cleanup_i < pending.len() as i32:
            pending[cleanup_i].join_cleanup()
            cleanup_i = cleanup_i + 1

    // D27/D33: remove transfers — await needs the owned Task.
    while pending.len() > 0:
        values.push(pending.remove(0).await)
    values

/// Return the result of the first task to complete.
pub fn await_first[T](tasks: impl IntoIter[Task[T]]) -> T:
    let pending: Vec[Task[T]] = Vec.new()
    for task in tasks.into_iter():
        pending.push(task)

    if pending.is_empty():
        todo("await_first: empty input")

    let total = pending.len() as i32
    let finished: Vec[i32] = Vec.new()
    var i = 0
    while i < total:
        finished.push(0)
        i = i + 1

    var cleanup_i = 0
    defer:
        // The winner was removed from BOTH vecs, so indices stay aligned and
        // the bound must be the live length, not the captured total.
        while cleanup_i < pending.len() as i32:
            if finished[cleanup_i] == 0:
                pending[cleanup_i].join_cleanup()
            cleanup_i = cleanup_i + 1

    while true:
        let ready = task_first_completed(&pending, &finished)
        if ready >= 0:
            // D27: remove transfers the element — await needs the owned Task.
            finished.remove(ready)
            return pending.remove(ready).await
        task_wait_for_progress()
        if with_fiber_is_cancelled() != 0:
            task_cancel_point().await
    todo("await_first: no live tasks")

/// Return the first successful result.
/// Fails only if all tasks fail.
pub fn await_any[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[T, Vec[E]]:
    let pending: Vec[Task[Result[T, E]]] = Vec.new()
    for task in tasks.into_iter():
        pending.push(task)

    let total = pending.len() as i32
    if pending.is_empty():
        let empty: Vec[E] = Vec.new()
        return Err(empty)

    let finished: Vec[i32] = Vec.new()
    let order: Vec[i32] = Vec.new()
    let errors: Vec[Option[E]] = Vec.new()
    var i = 0
    while i < total:
        finished.push(0)
        order.push(i)
        let empty: Option[E] = None
        errors.push(empty)
        i = i + 1

    var cleanup_i = 0
    defer:
        // Awaited tasks are removed in lockstep, so everything live is
        // un-awaited and the bound is the live length.
        while cleanup_i < pending.len() as i32:
            pending[cleanup_i].join_cleanup()
            cleanup_i = cleanup_i + 1

    while pending.len() > 0:
        let ready = task_first_completed(&pending, &finished)
        if ready < 0:
            task_wait_for_progress()
            if with_fiber_is_cancelled() != 0:
                task_cancel_point().await
            continue

        // D27/D33: remove transfers — await needs the owned Task.
        let orig: i32 = order[ready]
        order.remove(ready)
        finished.remove(ready)
        let result = pending.remove(ready).await
        if result.is_ok():
            return Ok(result.unwrap())
        with errors.slot(orig) as mut slot:
            slot.set(Some(result.err().unwrap()))

    let ordered: Vec[E] = Vec.new()
    while errors.len() > 0:
        ordered.push(errors.remove(0).unwrap())
    Err(ordered)

/// Await all tasks and return all results (including errors).
pub fn await_settled[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Vec[Result[T, E]]:
    let pending: Vec[Task[Result[T, E]]] = Vec.new()
    for task in tasks.into_iter():
        pending.push(task)

    let settled: Vec[Result[T, E]] = Vec.new()
    var cleanup_i = 0
    defer:
        // Awaited tasks were removed, so everything live is un-awaited.
        while cleanup_i < pending.len() as i32:
            pending[cleanup_i].join_cleanup()
            cleanup_i = cleanup_i + 1

    // D27/D33: remove transfers — await needs the owned Task.
    while pending.len() > 0:
        settled.push(pending.remove(0).await)
    settled

/// Limit concurrent execution to at most `n` tasks at a time.
pub fn with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]:
    let _ = n
    tasks

// ── Pulling a generator (§13.4) ───────────────────────────────────────────
// `g.pull()` runs the generator on its own coroutine: a fiber stack from the
// runtime's pool that only its caller resumes (rt with_fiber_coro_*), never
// the scheduler. next() resumes it; the generator's consumer body parks the
// element in next()'s slot and switches back. Sema resolves `g.pull()` on a
// generator value to gen_pull and rejects a generator that yields views of
// its own locals or may suspend.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8)
extern fn with_fiber_coro_new(entry: *const u8, arg: *mut u8) -> i64
extern fn with_fiber_coro_resume(co: i64)
extern fn with_fiber_coro_suspend(co: i64)
extern fn with_fiber_coro_finish(co: i64)
extern fn with_fiber_coro_free(co: i64)

// A pulled generator's state, on the heap so the coroutine's pointer to it
// stays valid while the Pulled that owns it moves. The header is what the
// coroutine entry and Pulled[T] — which cannot name the generator's type —
// read; the generator itself follows it (PullCore[G]). `run` and
// `drop_gen` are captureless closures specialized for G: they, not an
// escaping closure holding the generator, reach it (§12.2, #1732). `slot`
// is the Option[T] of the next() in progress.
type PullHeader {
    run: fn(*mut u8) -> Unit,
    drop_gen: fn(*mut u8) -> Unit,
    co: i64,
    slot: *mut u8,
    stop: bool,
    done: bool,
}

type PullCore[G] {
    head: PullHeader,
    source: G,
}

/// A generator stepped by `next()` on its own fiber: what `g.pull()` returns
/// (§13.4). Dropping it before the end stops the generator as a consumer's
/// `break` does. Pulled from a generator whose arguments are views, it is
/// as ephemeral as that generator value (Sema ties it to the views at the
/// `g.pull()`, #1732).
pub type Pulled[T] { core: *mut u8 }

// The coroutine's entry: the generator runs to its end or to a stop, then
// control returns to the resume for good.
unsafe fn pull_coro_main(arg: *mut u8):
    let head = arg as *mut PullHeader
    ((*head).run)(arg)
    (*head).done = true
    with_fiber_coro_finish((*head).co)

// The generator's consumer body, on the coroutine: hand `x` to the waiting
// next() and park until the next one; false leaves the generator at its
// yield (the Pulled is being dropped).
unsafe fn pull_yield[T](head: *mut PullHeader, x: T) -> bool:
    let slot = (*head).slot as *mut Option[T]
    *slot = Some(x)
    with_fiber_coro_suspend((*head).co)
    not (*head).stop

/// `g.pull()` (§13.4). Nothing runs, and no fiber stack is taken, until the
/// first `next()`.
pub fn gen_pull[T, G: Gen[T]](g: G) -> Pulled[T]:
    // The coroutine takes the generator out of the cell and consumes it.
    let run = (arg: *mut u8) => unsafe {
        var cell = *(arg as *mut PullCore[G])
        let held = move cell.source
        held.each(x => pull_yield(arg as *mut PullHeader, x))
    }
    // A generator that never ran is still in the cell when the Pulled drops.
    let drop_gen = (arg: *mut u8) => unsafe {
        var cell = *(arg as *mut PullCore[G])
        let held = move cell.source
        drop(held)
    }
    let core = with_alloc(sizeof[PullCore[G]]() as i64) as *mut PullCore[G]
    unsafe { *core = PullCore { head: PullHeader { run, drop_gen, co: 0, slot: 0 as *mut u8, stop: false, done: false }, source: g } }
    Pulled { core: core as *mut u8 }

impl[T] Iter[T] for Pulled[T]:
    mut fn next() -> Option[T]:
        let head = self.core as *mut PullHeader
        if (unsafe *head).done:
            return None
        if (unsafe *head).co == 0:
            let co = with_fiber_coro_new(pull_coro_main as *const u8, self.core)
            if co == 0:
                panic("g.pull(): no fiber stack could be allocated for the generator")
            (unsafe *head).co = co
        var item: Option[T] = None
        (unsafe *head).slot = &raw mut item as *mut u8
        with_fiber_coro_resume((unsafe *head).co)
        (unsafe *head).slot = 0 as *mut u8
        item

impl[T] Drop for Pulled[T]:
    move fn drop():
        let head = self.core as *mut PullHeader
        let co = (unsafe *head).co
        if co != 0:
            if not (unsafe *head).done:
                (unsafe *head).stop = true
                with_fiber_coro_resume(co)
            with_fiber_coro_free(co)
        else:
            ((unsafe *head).drop_gen)(self.core)
        with_free(self.core)
