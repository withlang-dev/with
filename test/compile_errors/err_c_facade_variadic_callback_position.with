//! expect-check-fail: names the variadic argument position
//! expect-check-fail: = help: after 'callback param' write the variadic position, the function's parameter count: 'callback param 2 as T userdata param CONST retains by param 0'
use c_import("typedef void (*visitor)(void *); int configure(int option, ...);\n#define VISIT 1\n#define DATA 2\n")
c contract settings:
    fn configure
        variadic param 1 selected by param option:
            case VISIT: callback param 0 as visitor userdata param DATA
fn main: ()
