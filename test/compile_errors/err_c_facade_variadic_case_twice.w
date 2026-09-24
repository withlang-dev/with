//! expect-check-fail: fn 'ulimit': 'case UL_SETFSIZE' is listed twice; one selector value has one case (§16.2b.5)

// D66 (spec §16.2b.5): one selector value, one case.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: c_long
            case UL_SETFSIZE: c_int

fn main:
    print("unreached")
