//! expect-check-fail: read of C global `g_n` may race: C can write it
//! expect-check-fail: `g_bump` of the same library is called from code that may run off `main`'s own path

// #3239 (§16.3): a function taken as a value may be called by whoever holds
// it, on any task.
use c_import("int g_n;\nint g_bump(void);\n")

c contract counter:
    runs no threads

fn helper() -> i32: g_bump()

async fn work(f: fn() -> i32) -> i32: f()

fn main:
    let t = work(helper)
    let before = g_n
    print(f"{before + t.await}")
