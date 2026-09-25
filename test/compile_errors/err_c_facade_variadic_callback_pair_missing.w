//! expect-check-fail: a variadic callback names its paired selector

use c_import("typedef void (*visitor)(void *); int configure(int option, ...);\n#define VISIT 1\n")
c facade settings:
    fn configure
        variadic param 1 selected by param option:
            case VISIT: callback param 1 as visitor
fn main: ()
