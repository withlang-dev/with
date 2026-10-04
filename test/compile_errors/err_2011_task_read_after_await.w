//! expect-check-fail: use of moved value
// #2011 (§22: `t.await // OK: consumes the task`): `.await` takes the result
// and releases the task, so the binding is moved; reading the handle after
// it reads a released task. Before, Sema accepted it.
async fn compute(v: i32) -> i32: v + 1

fn main:
    let t = compute(1)
    assert(t.await == 2)
    assert(t.is_done())
