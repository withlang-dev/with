//! expect-check-fail: read of C global `g_n` may race: C can write it
//! expect-check-fail: `g_bump` of the same library is called from code that may run off `main`'s own path

// #3239 (§16.3): the task calls into the library, which may write the
// global `main` reads.
use c_import("int g_n;\nint g_bump(void);\n")

c contract counter:
    runs no threads

async fn work() -> i32: g_bump()

fn main:
    let t = work()
    let before = g_n
    print(f"{before + t.await}")
