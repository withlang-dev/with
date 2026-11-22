//! expect-check-fail: exactly one 'void *' userdata parameter
//! expect-check-fail: = help: leave this case out: a callback with no 'void *' parameter, or several, has no form (#3178)
use c_import("typedef void (*visitor)(void *, void *); int configure(int option, ...);\n#define VISIT 1\n#define DATA 2\n")
c contract settings:
    fn configure
        variadic param 1 selected by param option:
            case VISIT: callback param 1 as visitor userdata param DATA
fn main: ()
