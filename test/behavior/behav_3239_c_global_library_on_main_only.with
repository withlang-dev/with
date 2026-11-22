//! check-only

// #3239 (§16.3): with a task in the program, a C global is still safe when
// every call into its library and every access to its globals runs only on
// `main`'s own path. The task here never reaches the library; `main` and a
// helper only `main` calls do.
use c_import("int g_n;\nint g_bump(void);\n")

c contract counter:
    runs no threads

async fn work() -> i32: 7

fn helper() -> i32: g_bump() + g_n

fn main:
    let t = work()
    g_n = 41
    let before = g_n
    print(f"{before + helper() + t.await}")
