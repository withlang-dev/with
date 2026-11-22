//! expect-stdout: 7
//! expect-stdout: 60

// #1678, D75 (§16.2b.5): a `static inline` variadic C function is a `...`
// definition. c_import translates its body — `va_start` declares the list
// where it starts, `va_arg(ap, int)` is `ap.arg[c_int]()`, `va_end` is the
// list's scope end — and the definition is unsafe to call. (Before D75 the
// body was omitted: "inline body translation failed: va_arg is not
// supported".)
use c_import("#include <stdarg.h>\nstatic inline int probe(int n, ...) { va_list ap; va_start(ap, n); int x = va_arg(ap, int); va_end(ap); return x; }\nstatic inline long total(int n, ...) { va_list ap; long t = 0; va_start(ap, n); for (int i = 0; i < n; i++) t += va_arg(ap, long); va_end(ap); return t; }")

fn main:
    print(unsafe { probe(1, 7) })
    print(unsafe { total(3, 10 as i64, 20 as i64, 30 as i64) })
