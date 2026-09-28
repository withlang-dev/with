//! expect-stdout: ok
// #1876: a translated inline body's call to a math builtin (D42) is the
// builtin call Sema types itself, never an unsafe operation. MSVC's
// <corecrt_math.h> declares acosf and kin as such inline wrappers; the
// translation `return unsafe { acos(x as f64) }` was refused as a block with
// no unsafe operation.
use c_import("double acos(double);\nstatic inline float my_acosf(float x) { return (float)acos((double)x); }\n")
fn main:
    if my_acosf(1.0) < 0.001: print("ok")
    else: print("bad")
