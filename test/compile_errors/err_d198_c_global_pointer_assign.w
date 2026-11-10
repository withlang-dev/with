//! expect-check-fail: assigning the C global `g_p` requires unsafe context
// D198 (§16.3): assigning a C global whose type holds a pointer is raw; the integer global on the line before stays safe.
use c_import("const int *g_p; int g_n;")

fn main:
    g_n = 3
    g_p = 4096 as *const i32
