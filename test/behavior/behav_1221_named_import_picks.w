//! expect-stdout: 3.14159 1

// #1221 (§18.2, Eric's ruling): the header and `use std.math` both provide
// `PI`; the named import `use std.math.PI` is written last, so it resolves
// PI — the later import shadows the earlier.

use c_import("#define PI 3.5f
#define ONE 1
")
use std.math
use std.math.PI

fn main:
    print(f"{PI} {ONE}")
