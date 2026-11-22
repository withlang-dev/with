//! expect-error: cannot create value of opaque type
use c_import("struct Base {}; struct Derived : Base { int value; };", lang: "c++")
fn main:
    var value: Derived
