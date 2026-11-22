//! expect-check-fail: names no imported type
//! expect-check-fail: = help: name a type the header declares
// §16.2b.11: a fixed size names a type the header declares.

use c_import("#define LIB_VERSION \"1.2\"\ntypedef struct st { int a; long b; } st;\nstatic inline int lib_init_(const char *version, int size) { return 0; }\nstatic inline int lib_small(signed char size) { return size; }\ntypedef struct big { char bytes[300]; } big;\n")

c contract notes:
    fn lib_init_
        param size fixed sizeof(nothing)

fn main:
    print("unreachable")
