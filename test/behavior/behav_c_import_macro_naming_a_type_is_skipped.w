//! only-on: windows
//! expect-stdout: 5
// §16.2: an object macro whose value names a declared type is a type alias,
// not a value. MSVC's <stdlib.h> `#define onexit_t _onexit_t` (reached from
// SDL3 on Windows) used to become `let onexit_t = _onexit_t`, an undefined
// variable that broke every import reaching <stdlib.h> through another
// header, as SDL.h does. (As the imported header itself, its typedefs are
// already known type names, so the include must be transitive.)
use c_import("#include <stdlib.h>\n")

fn main:
    print(f"{abs(-5)}")
