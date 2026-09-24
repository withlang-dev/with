//! expect-check-fail: fn 'ulimit': 'variadic param' names param 0, but the variadic position of 'ulimit' is param 1: its C parameters are params 0 to 0, and the variadic argument has no name (§16.2b.5)

// D66 (spec §16.2b.5): N is the variadic position itself.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 0 selected by param cmd:
            case UL_SETFSIZE: c_long

fn main:
    print("unreached")
