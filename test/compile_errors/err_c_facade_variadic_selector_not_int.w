//! expect-check-fail: fn 'dprintf': 'selected by param 1' names param 1: *const i8 fmt, which is not an integer or enum; the selector is the parameter whose compile-time value picks the case (§16.2b.5)

// D66 (spec §16.2b.5): the selector is an integer or enum parameter; a
// format string selects nothing a case can name.
use c_import("int dprintf(int fd, const char *fmt, ...);\n#define UL_SETFSIZE 2\n")

c facade prints:
    fn dprintf
        variadic param 2 selected by param fmt:
            case UL_SETFSIZE: c_long

fn main:
    print("unreached")
