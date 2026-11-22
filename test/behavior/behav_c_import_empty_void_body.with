//! expect-stdout: 3
// A void C body with no statement — `{}`, or `{ (void)d; }` whose only
// statement discards its parameter — is translated as `return`. It used
// to be refused as "inline body translation failed" (`{}`), or emitted as a
// `:` with no body under it, which failed to parse (`(void)d;` once the
// migrator read a cast to Unit as void).

use c_import("static inline void f0(void) {}
static inline void f1(int d) { (void)d; }
static inline int f2(int x) { (void)x; return 3; }
")

fn main:
    f0()
    f1(1)
    print(f2(1))
