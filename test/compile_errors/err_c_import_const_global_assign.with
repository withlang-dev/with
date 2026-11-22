//! expect-check-fail: cannot assign to immutable

// §16.3c: a c_import `const int` global is modeled as an immutable binding;
// assigning to it is rejected.

use c_import("const int k_limit = 100;\n")

fn main:
    k_limit = 5
    print("no")
