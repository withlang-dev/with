//! expect-check-fail: explicit 'as' type must be a C function pointer
//! expect-check-fail: = help: after 'as' name the header's function-pointer typedef for this callback
use c_import("int configure(int option, ...);\n#define VISIT 1\n#define DATA 2\n")
c contract settings:
    fn configure
        variadic param 1 selected by param option:
            case VISIT: callback param 1 as c_int userdata param DATA
fn main: ()
