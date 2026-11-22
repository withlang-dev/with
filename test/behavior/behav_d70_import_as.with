//! expect-stdout: 3.14159 3.14159 3 1

// D70 (§18.2): `use m as n` names an import's namespace `n` — a module
// and a c_import alike. Bare `PI` is the last import's (std.math, named
// `m`); `rl.PI` reaches the header's.

use c_import("behav_d70_raylike.h") as rl
use std.math as m

fn main:
    print(f"{PI} {m.PI} {rl.PI} {rl.ONE}")
