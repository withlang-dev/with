//! expect-stdout: ok
// Spec test: Section 14.8 — Scoped Task Tracking (formerly 25.53)

extern fn with_fiber_live_fibers() -> i32

async fn fetch_data(id: i32) -> Result[i32, str]:
    id + 1

async fn compute(id: i32) -> i32:
    id + 1

async fn fallible(value: i32) -> Result[i32, str]:
    value

async fn tick() -> i32:
    1

async fn borrow_until_scope_cancel(value: &i32) -> i32:
    assert(*value == 41)
    while true:
        let _ = tick().await
    0

async fn test_track_registers_and_awaits:
    let result = async scope s =>:
        let task = s.track(fetch_data(41))
        task.await.unwrap()
    assert(result == 42)

async fn test_scoped_task_drop_is_scope_owned:
    async scope s =>:
        s.track(compute(1))
        0

async fn test_question_return_keeps_scope_cleanup -> Result[i32, str]:
    let total = async scope s =>:
        let left = s.track(fallible(20))
        let right = s.track(fallible(22))
        left.await? + right.await?
    total

fn test_scope_exit_cancels_unawaited_task:
    let baseline = unsafe { with_fiber_live_fibers() }
    let value = 41
    async scope s =>:
        s.track(borrow_until_scope_cancel(&value))
        0
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    test_track_registers_and_awaits().await
    test_scoped_task_drop_is_scope_owned().await
    assert(test_question_return_keeps_scope_cleanup().await.unwrap() == 42)
    test_scope_exit_cancels_unawaited_task()
    print("ok")
