//! expect-stdout: 3.14159 3 6.28319

// #1221 (§18.2, Eric's ruling: "which comes last shadows the others"): two
// explicit imports that provide one name are not an error, and the import
// written last resolves it. Here std.math comes after the header, so `PI`
// is std.math's f64; behav_1221_later_import_shadows_reversed.w writes the
// same imports the other way round and gets the header's `3`. The header's
// other names stay reachable (`HALF`), and a named import provides only what
// it selects (`use std.math.TAU` does not bring std.math's PI back).

use c_import("#define PI 3
#define HALF 3
")
use std.math

fn main:
    print(f"{PI} {HALF} {TAU}")
