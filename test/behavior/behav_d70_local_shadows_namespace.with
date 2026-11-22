//! expect-stdout: 7 3.14159

// D70 (§18.2): a namespace name is an import's name (tier 3), so a local
// binding named `math` shadows it — `math.PI` reads the local's field —
// and the namespace is reachable again once the local is out of scope.

use std.math

type Consts { PI: i32 }

fn local_value() -> i32:
    let math = Consts { PI: 7 }
    math.PI

fn main:
    print(f"{local_value()} {math.PI}")
