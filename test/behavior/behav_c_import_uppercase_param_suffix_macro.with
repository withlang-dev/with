//! expect-stdout: 7
//! expect-stdout: ok

// sqlite3.h names parameters `N`, `Z` and `C`. In a With parameter list an
// uppercase-initial identifier is a unit-variant pattern (§9.7, `fn value(None:
// Option[i32])`), so the generated method wrapper spells them `p_N`; before,
// the wrapper was a refutable pattern plus an "undefined variable" at its call.
// `#define ACC_SUFFIX L` is curl's bare integer-suffix idiom: a token, not a
// value. It is omitted from the surface; before, it was `let ACC_SUFFIX: c_long = `.
use c_import("typedef struct Acc { int total; } Acc;\nstatic inline int acc_add(Acc *a, int N, int C) { a->total = a->total + N * C; return a->total; }\n#define ACC_SUFFIX L\n#define ACC_LIMIT 100L\n")

fn main:
    var a = Acc { total: 1 }
    let t = unsafe { a.add(2, 3) }
    print(f"{t}")
    if ACC_LIMIT == 100: print("ok")
