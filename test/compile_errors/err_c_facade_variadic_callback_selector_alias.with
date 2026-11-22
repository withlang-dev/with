//! expect-check-fail: callback and its userdata need distinct selector values
//! expect-check-fail: = help: name the option that sets the userdata, which differs from the one that sets the callback
use c_import("typedef void (*visitor)(void *); int configure(int option, ...);\n#define VISIT 1\n#define DATA 1\n")
c contract settings:
    fn configure
        variadic param 1 selected by param option:
            case VISIT: callback param 1 as visitor userdata param DATA
fn main: ()
