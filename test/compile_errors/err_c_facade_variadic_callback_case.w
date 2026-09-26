//! expect-check-fail: a variadic callback requires its C type

// D66 requires an explicit `as T`: a variadic declaration has no callback
// signature, and neither an option's name nor the userdata pairing proves it.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: callback param 1 userdata param UL_GETFSIZE

fn main:
    print("unreached")
