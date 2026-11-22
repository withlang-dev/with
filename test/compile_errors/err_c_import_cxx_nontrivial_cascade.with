//! expect-error: cannot create value of opaque type
use c_import("struct Nontrivial { int value; ~Nontrivial(); }; struct Holder { Nontrivial values[2]; };", lang: "c++")
fn main:
    var value: Holder
