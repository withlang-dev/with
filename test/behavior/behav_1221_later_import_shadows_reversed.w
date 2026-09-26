//! expect-stdout: 3 3.5 6.28319

// #1221 (§18.2, Eric's ruling): the imports of
// behav_1221_later_import_shadows.w in the other order — the header comes
// last, so `PI` is its `3`, and a module's own declaration (`HALF_PI` here)
// still beats every import.

use std.math
use c_import("#define PI 3
#define HALF_PI 9
")

let HALF_PI = 3.5

fn main:
    print(f"{PI} {HALF_PI} {TAU}")
