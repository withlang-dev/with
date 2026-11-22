//! expect-stdout: 6.28319

// #1221 (§18.2): `use std.math` and a header both provide `PI`, and the
// program never names it. Two imports that provide one name are not an
// error by themselves — only a use of the ambiguous name is.

use c_import("#define PI 3.5f
")
use std.math

fn main:
    print(f"{TAU}")
