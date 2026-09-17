//! expect-check-fail: c_import symbol 'END' was omitted

use c_import("#define END { 0, (void *)0 }\n")

fn main: print(END)
