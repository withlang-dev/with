//! expect-error: opaque types cannot be passed by value
use c_import("struct Nontrivial { int value; ~Nontrivial(); }; extern \"C\" void nontrivial_accept(Nontrivial value);", lang: "c++")
fn main:
    nontrivial_accept(null)
