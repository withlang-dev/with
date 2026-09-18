use c_import("#define ANSWER 42\n#define SQUARE(x) ((x) * (x))\n#define PASTE(a, b) a ## b")
use std.builtins.print_i32
fn main:
    print_i32(ANSWER)
    print_i32(SQUARE(6))
