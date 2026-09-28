//! expect-error: is declared without a prototype: each call passes its own promoted arguments, so it has no function type

// #1831: a function declared without a prototype has no With function type
// (each call passes its own promoted arguments); it is called directly.
use c_import("int knr();\n")

fn main:
    let f = knr
    print("x")
