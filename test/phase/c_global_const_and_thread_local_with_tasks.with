//! expect-check-stdout: ok

// §16.3 (#3220): the header proves two cases in any program. A `const`
// global is never written; a `_Thread_local` global is one per thread, so
// neither a read nor a write of it races.
use c_import("const int g_c; _Thread_local int g_t;")

async fn work() -> i32:
    g_t = g_t + 1
    g_t + g_c

fn main:
    let t = work()
    print(f"{t.await}")
