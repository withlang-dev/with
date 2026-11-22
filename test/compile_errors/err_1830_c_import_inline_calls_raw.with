//! expect-error: unsafe function call requires unsafe context

// D51 (#1830): a c_import `static inline` function whose body calls a raw
// C function is an `unsafe fn`; its call needs `unsafe`.
use c_import("int snprintf(char *buf, unsigned long n, const char *fmt, ...);\nstatic inline int fmt_len(void) { return snprintf(0, 0, \"%d\", 12); }\n")

fn main:
    print(fmt_len())
