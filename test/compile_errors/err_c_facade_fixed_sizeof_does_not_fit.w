//! expect-check-fail: cannot hold
//! expect-check-fail: = help: the raw operation stays available
// §16.2b.11: a fixed size fits the integer parameter that receives it.

use c_import("#define LIB_VERSION \"1.2\"\ntypedef struct st { int a; long b; } st;\nstatic inline int lib_init_(const char *version, int size) { return 0; }\nstatic inline int lib_small(signed char size) { return size; }\ntypedef struct big { char bytes[300]; } big;\n")

c contract notes:
    fn lib_small
        param size fixed sizeof(big)

fn main:
    print("unreachable")
