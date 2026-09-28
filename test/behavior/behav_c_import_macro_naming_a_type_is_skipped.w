//! only-on: windows
//! expect-stdout: 5
// §16.2: an object macro whose value names a declared type is a type alias,
// not a value. MSVC's <stdlib.h> `#define onexit_t _onexit_t` (reached from
// SDL3 on Windows) used to become `let onexit_t = _onexit_t`, an undefined
// variable that broke the SDL.h import there. The UCRT defines the alias only
// with its non-standard names enabled, as SDL's build has them.
use c_import("#define _CRT_DECLARE_NONSTDC_NAMES 1\n#include <stdlib.h>\n")

fn main:
    print(f"{abs(-5)}")
