//! expect-error: bare 'math' names both a field of the receiver `Gauge` and the import namespace `math` (§9.5)

// §9.5 (#1930): a field named like an import namespace; the bare use is
// ambiguous, `self.math` and `std.math.PI` reach each.

use std.math

type Gauge {
    math: i32,
}

impl Gauge:
    fn get -> i32: math

fn main:
    print(f"{Gauge { math: 1 }.get()}")
