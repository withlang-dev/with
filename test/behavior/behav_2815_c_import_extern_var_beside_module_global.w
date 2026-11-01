//! expect-stdout: 7
//! expect-stdout: ok

// #2815 (§18.2, D70): a header's `extern var` is its importer's import; a
// module value of the same name is another import's. They met as one
// global declared twice ("conflicting global declaration for 'stdin'",
// std.io's beside glibc's). The import written last provides the bare
// name — here the header, so `tzname` is libc's array — and the module's
// stays reachable through its namespace.
use shadow_tzname
use c_import("extern char *tzname[2];")

fn main:
    print(shadow_tzname.tzname)
    let names = tzname
    let _ = names
    print("ok")
