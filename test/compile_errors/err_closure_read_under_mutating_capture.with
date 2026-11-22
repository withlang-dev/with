//! expect-check-fail: cannot read `n` while `g` is a live mutating view into it

// §12.4 (D62, #1691): a live closure that mutates a captured place holds an
// exclusive view of it; reading the place before the closure's last use is
// refused, as mutating it under a read capture is.
use std.builtins.print_i32
fn main:
    var n = 1
    let g = () => n += 1
    g()
    let seen = n
    g()
    print_i32(seen + n)
