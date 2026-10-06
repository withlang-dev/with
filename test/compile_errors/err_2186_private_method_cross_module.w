//! expect-check-fail: method 'Gauge.secret' is private to its package

// #2186: "Cross-module access to a non-`pub` symbol is a compile error;
// this applies uniformly to functions, types, constants, and globals"
// (§18.3). A method is a function: `secret` has no `pub`, so a call from
// another module is refused, as a free function's is.
use visibility.private_surface

fn main:
    let g = Gauge { n: 3 }
    print(g.secret())
