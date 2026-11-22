//! expect-check-fail: 'NO_SUCH' is not a constant the header defines
//! expect-check-fail: = help: name a constant of the imported header, or write the literal
// §16.2b.11: a fixed name is a constant of the imported header.

use c_import("#define LIB_VERSION \"1.2\"\ntypedef struct st { int a; long b; } st;\nstatic inline int lib_init_(const char *version, int size) { return 0; }\nstatic inline int lib_small(signed char size) { return size; }\ntypedef struct big { char bytes[300]; } big;\n")

c contract notes:
    fn lib_init_
        param size fixed NO_SUCH

fn main:
    print("unreachable")
