//! expect-check-fail: 'PI' is ambiguous

// #1221 (§18.2): two whole imports both provide `PI`; the declarations are
// legal, and a use of the bare name is the error — it names both providers
// and the named import that picks one.

use c_import("#define PI 3.5f
")
use std.math

fn main:
    print(f"{PI}")
