//! expect-error: is declared without a prototype, so C passes its arguments after the default argument promotions, and a value of type 'str' has no C argument form

// #1831: an unprototyped call's argument must have a C form after the
// default argument promotions; a `str` has none.
use c_import("int knr();\n")

fn main:
    print(unsafe { knr("text") })
