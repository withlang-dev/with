//! expect-stdout: 42
use c_import("#define FLAT_ATTR(TEXT)\n#define FLAT_OUT() FLAT_ATTR(\"out_struct: ;\")\n#define FLAT_CHAIN(TEXT) FLAT_ATTR(TEXT)\n#define FLAT_DESCRIBE(COUNT, DESC) FLAT_ATTR(#COUNT \",\" #DESC)\n#define EMPTY\n#define FLAT_ID(EMPTY) EMPTY\n", lang: "c++")
fn main: print(FLAT_ID(42))
