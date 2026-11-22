//! expect-error: raw surface

// §16.2: an ABI-expressible function we can't model (here, an inline
// function returning a function pointer) is reachable via the raw surface;
// referencing it gives directional guidance toward a manual extern. The
// function is a plain `inline`, which may have an external definition for
// that extern to bind; a `static inline` has none, so its omission is
// inexpressible (an inline body over a record c_import imports opaque,
// #1417).

use c_import("typedef int (*fnptr)(int);\ninline fnptr get_fn(void) { return 0; }\n")

fn main:
    get_fn
