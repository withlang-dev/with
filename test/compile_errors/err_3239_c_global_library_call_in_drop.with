//! expect-check-fail: read of C global `g_n` may race: C can write it
//! expect-check-fail: `g_bump` of the same library is called from code that may run off `main`'s own path

// #3239 (§16.3): a `Drop` impl runs wherever its value dies, on any task;
// no call Sema saw says where.
use c_import("int g_n;\nint g_bump(void);\n")

c contract counter:
    runs no threads

type Guard { n: i32 }

impl Drop for Guard:
    move fn drop():
        g_bump()

async fn work() -> i32:
    let g = Guard { n: 1 }
    g.n

fn main:
    let t = work()
    let before = g_n
    print(f"{before + t.await}")
