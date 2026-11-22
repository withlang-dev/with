//! expect-stdout: 7

// #2815 (§18.2, D70), the other order: the module is the import written
// last, so the bare `tzname` is its value; the header's array is still the
// C symbol, untouched. A one-liner imports std.io after the program's own
// imports (§18.5b.2), which is where std.io's `stdin` first met stdio.h's.
use c_import("extern char *tzname[2];")
use shadow_tzname

fn main:
    print(tzname)
