//! expect-check-fail: callback and its userdata need distinct selector values
use c_import("typedef void (*visitor)(void *); int configure(int option, ...);\n#define VISIT 1\n#define DATA 1\n")
c facade settings:
    fn configure
        variadic param 1 selected by param option:
            case VISIT: callback param 1 as visitor userdata param DATA
fn main: ()
