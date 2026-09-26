//! expect-stdout: 6.28319
//! expect-stdout: 3.5

// #1221 (§18.2): a header and std.math both provide `PI`. Two imports that
// provide one name are not an error; only a use of an ambiguous name is. A
// named import (`use std.math.TAU`) introduces only the name it selects,
// so `PI` here is the header's — the one import that provides it — and
// std.math's stays behind the fallback tier.

use c_import("#define PI 3.5f
#define HALF 0.5f
")
use std.math.TAU

fn main:
    print(f"{TAU}")
    print(f"{PI}")
