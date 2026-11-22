//! expect-stdout: ok
// §16: a C enum's constants are surfaced as usable values.
use c_import("typedef enum Color { COLOR_RED = 0, COLOR_GREEN = 1, COLOR_BLUE = 7 } Color;\n")
fn main:
    if COLOR_RED == 0 and COLOR_GREEN == 1 and COLOR_BLUE == 7: print("ok")
    else: print("bad")
