//! expect-check-fail: fn 'ulimit': UL_GETFSIZE is not a case of its variadic contract, so the type of its variadic argument is unknown; the safe surface presents only the listed cases (§16.2b.5)
//! expect-check-fail: add 'case UL_GETFSIZE: <type>' under 'variadic param 1 selected by param cmd:' in facade limits, or call the raw ulimit under unsafe

// D66 (spec §16.2b.5): "a selector that is unlisted … is refused on the
// safe surface with a note naming the case to add, and the raw variadic
// function remains available under `unsafe`".
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: c_long

fn main:
    let current = ulimit(UL_GETFSIZE)
    print(f"{current}")
