//! expect-error: `use std.math` provides no 'GOLDEN' (through the namespace 'math')

// D70 (§18.2): a namespace reaches only what its import provides; a member
// the module does not declare is a located error, never a field read of an
// undefined variable `math`.

use std.math

fn main:
    print(math.GOLDEN)
