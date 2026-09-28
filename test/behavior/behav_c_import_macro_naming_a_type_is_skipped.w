//! only-on: windows
//! expect-stdout: 5
// §16.2: an object macro whose value names a declared type is a type alias,
// not a value. MSVC's <stdlib.h> `#define onexit_t _onexit_t` (reached from
// SDL3 on Windows) used to become `let onexit_t = _onexit_t`, an undefined
// variable that broke every full import of <stdlib.h> and SDL.h there.
use c_import("stdlib.h")

fn main:
    print(f"{abs(-5)}")
