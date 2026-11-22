//! expect-stdout: 6
//! expect-stdout: 7

// D51 (#1830): a c_import `static inline` function whose body calls a raw
// C function (here the variadic snprintf) is itself raw — an `unsafe fn` —
// never a safe `fn` by inference. Its translation failed Sema instead
// ("raw c_import function call requires unsafe context" in the generated
// body), so the whole c_import was unusable.
use c_import("int snprintf(char *buf, unsigned long n, const char *fmt, ...);\nstatic inline int fmt_len(void) { return snprintf(0, 0, \"%d-%d\", 12, 345); }\nstatic inline int fmt_len_plus(int k) { return fmt_len() + k; }\n")

fn main:
    print(unsafe { fmt_len() })
    print(unsafe { fmt_len_plus(1) })
