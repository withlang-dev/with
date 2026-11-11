//! expect-check-fail: its library's facade says `runs threads`
// §16.3 (#3237): a library that runs threads of its own may write its
// globals at any time; its facade says so, and its globals are then never
// provably on one thread, in a single-threaded program too.
use c_import("int g_n;")

c facade lib:
    runs threads

fn main:
    print(f"{g_n}")
