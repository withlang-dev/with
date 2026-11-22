//! expect-check-fail: c_import symbol 'ANNOTATION' was omitted

use c_import("#define ATTRIBUTE(x) __attribute__((deprecated))\n#define ANNOTATION ATTRIBUTE(4.0)\n")

fn main: print(ANNOTATION)
