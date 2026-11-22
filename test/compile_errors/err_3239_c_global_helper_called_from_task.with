//! expect-check-fail: read of C global `g_n` may race: C can write it
//! expect-check-fail: `g_bump` of the same library is called from code that may run off `main`'s own path

// #3239 (§16.3): a helper the task also calls reaches the library off
// `main`'s path, so `main`'s own read has no proof either.
use c_import("int g_n;\nint g_bump(void);\n")

c contract counter:
    runs no threads

fn helper() -> i32: g_bump()

async fn work() -> i32: helper()

fn main:
    let t = work()
    let before = g_n
    print(f"{before + helper() + t.await}")
