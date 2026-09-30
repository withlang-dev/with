//! expect-error: cannot create value of opaque type
use c_import("struct Nontrivial { int value; Nontrivial(const Nontrivial&); };", lang: "c++")
fn main:
    var value: Nontrivial
