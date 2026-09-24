//! expect-check-fail: fn 'ulimit': the selector cmd must be a compile-time constant at the call — the case it picks decides the type of the variadic argument, and only a listed case is presented safely (§16.2b.5)

// D66 (spec §16.2b.5): "the selector must be a compile-time constant at
// the call"; a value computed at run time picks no case.
use c_import("long ulimit(int cmd, ...);\n#define UL_GETFSIZE 1\n#define UL_SETFSIZE 2\n")

c facade limits:
    fn ulimit
        variadic param 1 selected by param cmd:
            case UL_SETFSIZE: c_long

fn pick(n: i32) -> c_int: if n > 0: UL_SETFSIZE else: UL_GETFSIZE

fn main:
    let which = pick(1)
    let set = ulimit(which, 4096 as c_long)
    print(f"{set}")
