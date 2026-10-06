//! expect-stdout: 4
//! expect-stdout: 30

// #2186 (§18.3): from another module, a `pub` method is callable, and so is
// a method reached through a public trait; only the private `secret` is
// refused (err_2186_private_method_cross_module). `open` calls `secret`
// from inside its own module.
use visibility.gauge

fn main:
    let g = Gauge { n: 3 }
    print(g.open())
    print(g.show())
