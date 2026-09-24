//! expect-check-fail: a callback case of a variadic contract ('case CONST: callback param N userdata param CONST') is not modeled yet (#1652); leave the case out and set that option through the raw function under unsafe (§16.2b.5, §16.2b.9)

// D66 (spec §16.2b.5) spells a callback case; the pairing across two calls
// is not modeled yet (#1652), and the spelling is refused loudly rather
// than rendered as a plain value.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: callback param 1 userdata param UL_GETFSIZE

fn main:
    print("unreached")
