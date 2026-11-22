//! expect-check-fail: its library's contract does not say `runs no threads`
// §31.6.2: no default grant. With no contract that says `runs no threads`
// the library is not known to leave its globals alone on other threads,
// so a read is raw in a single-threaded program too.
use c_import("int g_n;")

fn main:
    print(f"{g_n}")
