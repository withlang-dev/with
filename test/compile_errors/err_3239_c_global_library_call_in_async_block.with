//! expect-check-fail: read of C global `g_n` may race: C can write it
//! expect-check-fail: `g_bump` of the same library is called from code that may run off `main`'s own path

// #3239 (§16.3): an async block written in `main` is a task's body, not
// `main`'s own path.
use c_import("int g_n;\nint g_bump(void);\n")

c contract counter:
    runs no threads

fn main:
    let t = async { g_bump() }
    let before = g_n
    print(f"{before + t.await}")
