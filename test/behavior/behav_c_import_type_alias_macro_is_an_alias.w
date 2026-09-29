//! expect-stdout: 5 7

// §16.2: an object macro whose whole value names a declared type is a type
// alias, and one meaning is forced: it is emitted as `type X = T`, never
// skipped (MSVC's <stdlib.h> `#define onexit_t _onexit_t`). A program names
// the macro's type like the typedef's.
use c_import("typedef int my_int_t;\n#define my_alias_t my_int_t\ntypedef struct pair { int a; int b; } pair;\n#define pair_t pair\n")

fn main:
    let x: my_alias_t = 5
    let p = pair_t { a: 3, b: 4 }
    print(f"{x} {p.a + p.b}")
