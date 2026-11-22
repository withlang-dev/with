//! expect: ok

// #3401: a generic function of the package, instantiated in the importer;
// one of the two calls a private function of the package.
use shapes
fn main:
    let xs = [Shape { w: 2, h: 3, name: "a" }, Shape { w: 7, h: 1, name: "b" }]
    print(first_of(xs).w)
    print(widest(xs, (s) => s.w))
