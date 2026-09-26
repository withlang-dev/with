//! expect-stdout: 3.14159 1

// #1221 (§18.2): `use std.math` and a header both provide `PI`; the named
// import `use std.math.PI` picks std.math's over the two whole-module
// provisions — the spelling the ambiguity diagnostic offers.

use c_import("#define PI 3.5f
#define ONE 1
")
use std.math
use std.math.PI

fn main:
    print(f"{PI} {ONE}")
