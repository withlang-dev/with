//! expect-check-fail: binds text to
//! expect-check-fail: = help: fix the parameter with a constant of its own type
// §16.2b.11: a fixed constant is a value of the parameter's type.

use c_import("#define LIB_VERSION \"1.2\"\ntypedef struct st { int a; long b; } st;\nstatic inline int lib_init_(const char *version, int size) { return 0; }\nstatic inline int lib_small(signed char size) { return size; }\ntypedef struct big { char bytes[300]; } big;\n")

c contract notes:
    fn lib_init_
        param size fixed LIB_VERSION

fn main:
    print("unreachable")
