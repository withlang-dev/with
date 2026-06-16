//! expect-error: raw surface

// §16.2: an ABI-expressible function we can't model (here, a static inline
// returning a function pointer) is reachable via the raw surface; referencing
// it gives directional guidance toward a manual extern.

use c_import("typedef int (*fnptr)(int);\nstatic inline fnptr get_fn(void) { return 0; }\n")

fn main:
    get_fn
