//! expect-stdout: ok

// clang 22 split its builtin float.h into __float_*.h parts. The embedded
// header subset left them out, so any C header that reaches <float.h>
// (CoreFoundation.h does) failed with "'__float_header_macro.h' file not
// found". The embed action now refuses a subset that is not closed under
// inclusion.

use c_import("float.h")

fn main:
    assert(FLT_RADIX == 2)
    assert(DBL_DIG >= 15)
    print("ok")
