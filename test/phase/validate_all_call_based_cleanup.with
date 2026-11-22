//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #1944 follow-up: an owned local released by a runtime call — a task
// handle's detach-cancel or cleanup await, a scope handle's destroy — has
// no Drop statement. The lowering records the local as owned cleanup and
// must also record that the consuming call takes it (`move`), or the
// ownership validator reports it "still Init at return" on every scope and
// task program. Every call-released kind is covered: detached task,
// ephemeral task, thread scope and async scope, with an early return
// inside each so the return-edge cleanup is exercised too.

async fn square(x: i32) -> i32:
    x * x

async fn len_of(s: &str) -> i32:
    s.len() as i32

async fn cancelled() -> i32:
    let t = square(2)
    t.cancel()
    1

async fn detached_cond(b: bool) -> i32:
    let t = square(3)
    if b:
        return t.await
    0

async fn ephemeral_cond(b: bool) -> i32:
    let name = "abcd"
    let t = len_of(&name)
    if b:
        return t.await
    0

async fn tracked(b: bool) -> i32:
    async scope s =>:
        s.track(square(3))
        if b:
            return 5
        s.track(square(4))
        0
    7

fn joined(b: bool) -> i32:
    let a = scope s =>:
        let h = s.spawn(() => 8)
        if b:
            return 3
        h.join()
    a

async fn main:
    assert(cancelled().await == 1)
    assert(detached_cond(true).await == 9)
    assert(detached_cond(false).await == 0)
    assert(ephemeral_cond(true).await == 4)
    assert(ephemeral_cond(false).await == 0)
    assert(tracked(true).await == 5)
    assert(tracked(false).await == 7)
    assert(joined(true) == 3)
    assert(joined(false) == 8)
    print("ok")
