//! expect-stdout: 3 2

// §12.4 (D62, #1691): the mutating view ends at the closure's last use; a
// read of the captured place after it is ordinary, and a snapshot taken
// with `move ||` never holds the place at all.
use std.builtins.print
fn main:
    var n = 1
    let g = () => n += 1
    g()
    g()
    let seen = n
    var m = 1
    let snap = move () => m + 1
    m = 7
    print(f"{seen} {snap()}")
