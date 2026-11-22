//! check-only

// §31.4, §31.8.1: a C global is safe to read and to write when every access
// to its library is provably on one thread and the library's contract says
// `runs no threads`. This library is the test's own, and its contract
// says so: the safe path, with no `unsafe`.
use c_import("int g_n;\nint g_bump(void);\n")

c contract counter:
    runs no threads

fn main:
    g_n = 41
    let before = g_n
    print(f"{before + g_bump()}")
