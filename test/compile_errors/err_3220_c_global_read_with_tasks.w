//! expect-check-fail: read of C global `g_n` may race: C can write it
// §16.3 (#3220): a C global is safe to access when every call into its
// library and every access to its globals is provably on one thread. A
// program with a task has no such proof, and C is a writer the compiler
// cannot see: the read is refused even though no With code writes it.
use c_import("int g_n; const int g_c; _Thread_local int g_t;")

async fn work() -> i32: g_n

fn main:
    let t = work()
    print(f"{t.await}")
