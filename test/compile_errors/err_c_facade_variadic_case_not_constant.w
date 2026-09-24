//! expect-check-fail: fn 'ulimit': 'case nothing' names no imported integer constant; a case selector is a compile-time constant the header declares, of the selector parameter's type (§16.2b.5)

// D66 (spec §16.2b.5): a case selector is an imported constant.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case nothing: c_long

fn main:
    print("unreached")
