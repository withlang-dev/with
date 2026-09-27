//! expect-check-fail: inline body translation failed: va_arg is not supported
//! expect-check-fail-not: declare a manual extern

// #1678 (§16.2): a `static inline` variadic C function's body reads its
// arguments with va_arg, which c_import does not translate. Its only
// definition is that body — there is no symbol for a manual extern to bind —
// so the omission is inexpressible: the diagnostic names the translator's
// reason and does not send the user to a raw extern that cannot link. (The
// base said "inline body translation failed" and "declare a manual extern
// \"C\" binding and call it under unsafe".)
use c_import("#include <stdarg.h>\nstatic inline int probe(int n, ...) { va_list ap; va_start(ap, n); int x = va_arg(ap, int); va_end(ap); return x; }")

fn main:
    print(unsafe { probe(1, 7) })
