//! expect-stdout: ok

// #2176 (§16.1): `long double` is a With float only where it is a double
// (Apple arm64, Windows: `c_longdouble = f64`). On x86-64 and AArch64 Linux
// it is x87 extended or binary128, which With has no float for, so a
// declaration that needs it is omitted and the rest of the header imports.
// Before, the function's signature named `c_longdouble`, which that target
// does not define, and the whole import failed (glibc's wcstold, reached
// from SDL3/SDL.h).
use c_import("long double ld_extern(long double x);
static inline long double ld_twice(long double x) { return x * 2; }
long double *ld_slot(void);
#define LD_ONE 1.0L
#define LD_TWO ((long double)2)
static inline int plain(int x) { return x + 1; }
")

fn main:
    assert(plain(1) == 2)
    print("ok")
