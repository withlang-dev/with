//! expect-check-fail: read of C global `g_n` may race: C can write it
//! expect-check-fail: `g_n` of the same library is accessed inside a closure, an async block or a scope

// #3239 (§16.3): a closure's body runs where and when its holder chooses;
// an access inside one is not on `main`'s own path.
use c_import("int g_n;\n")

c contract counter:
    runs no threads

async fn work() -> i32: 7

fn main:
    let t = work()
    let read = () => g_n
    print(f"{read() + t.await}")
