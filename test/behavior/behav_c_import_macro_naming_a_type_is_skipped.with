//! only-on: windows
//! expect-stdout: 5
// §16.2: an object macro whose value names a declared type is a type alias,
// not a value. The UCRT's <stdlib.h> has `#define onexit_t _onexit_t`, which
// became `let onexit_t = _onexit_t`. Alone that went unnoticed, but a
// program importing the header twice, selectively and then in full (as a
// program using SDL3 does), keeps `_onexit_t` only in the first import,
// whose `only:` drops it, and the second import's `let` names nothing:
// "undefined variable".
use c_import("stdlib.h", only: ["abs"])
use c_import("#include <stdlib.h>\n#include <string.h>\n")

fn main:
    print(f"{abs(-5)}")
