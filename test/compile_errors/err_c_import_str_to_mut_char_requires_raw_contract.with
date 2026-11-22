//! expect-error: raw c_import function call requires unsafe context

use c_import("void takes_mut(char *s);\n")

fn main:
    takes_mut("hello")
