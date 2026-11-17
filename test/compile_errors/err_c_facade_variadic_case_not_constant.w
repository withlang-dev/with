//! expect-check-fail: fn 'ulimit': 'case nothing' names no imported integer constant; a case selector is a compile-time constant the header declares, of the selector parameter's type (§16.2b.5)
//! expect-check-fail: = help: write the constant's C name as the header spells it: 'case CURLOPT_URL: str'

// D66 (spec §16.2b.5): a case selector is an imported constant.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c contract limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case nothing: c_long

fn main:
    print("unreached")
