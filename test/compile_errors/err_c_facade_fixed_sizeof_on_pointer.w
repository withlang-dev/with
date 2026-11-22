//! expect-check-fail: which is not an integer
//! expect-check-fail: = help: a size is fixed on an integer parameter
// §16.2b.11: a size is fixed on an integer parameter.

use c_import("#define LIB_VERSION \"1.2\"\ntypedef struct st { int a; long b; } st;\nstatic inline int lib_init_(const char *version, int size) { return 0; }\nstatic inline int lib_small(signed char size) { return size; }\ntypedef struct big { char bytes[300]; } big;\n")

c contract notes:
    fn lib_init_
        param version fixed sizeof(st)

fn main:
    print("unreachable")
