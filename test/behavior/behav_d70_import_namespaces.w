//! expect-stdout: 3.14159 3 1
//! expect-stdout: 6.28319 3.14159 3.14159
//! expect-stdout: 2 3
//! expect-stdout: 2.71828 4

// D70 (§18.2): every import is also a namespace, so a name a later import
// shadows stays reachable. §18.2's example: the header and std.math both
// provide `PI`; bare `PI` is std.math's (the later import), the header's is
// reached through its file name without `.h`, and std.math's names through
// `math` (its last path segment) or the full path `std.math`. A namespaced
// call reaches std.math's builtins (`math.sqrt`), and the receiver forms
// of a method call and a builtin method are unchanged.

use c_import("behav_d70_raylike.h")
use std.math

type Holder { v: i32 }

extend Holder:
    fn plus_one(): self.v + 1

fn main:
    print(f"{PI} {behav_d70_raylike.PI} {ONE}")
    print(f"{math.TAU} {math.PI} {std.math.PI}")
    print(f"{math.sqrt(4.0)} {behav_d70_raylike.PI}")
    let h = Holder { v: 3 }
    print(f"{math.E} {h.plus_one()}")
