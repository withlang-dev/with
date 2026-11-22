//! expect-check-fail: c_import symbol 'WRAPPED' was omitted

use c_import("int tick(void);\n#define WRAP(x) tick()\n#define WRAPPED WRAP (0)\n")

fn main: print(WRAPPED)
