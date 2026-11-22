//! expect-stdout: ok

// clang 22 split its builtin float.h into __float_*.h parts. The embedded
// header subset left them out, so any C header that reaches <float.h>
// (CoreFoundation.h does) failed with "'__float_header_macro.h' file not
// found"; and the materialized header cache was keyed by clang's version
// alone, so an upgraded compiler kept the old directory. The values go through
// C constants: float.h's macros alias compiler builtins, which c_import does
// not probe in a system header.

use c_import("#include <float.h>\nstatic const int with_flt_radix = FLT_RADIX;\nstatic const int with_dbl_dig = DBL_DIG;\n")

fn main:
    assert(with_flt_radix == 2)
    assert(with_dbl_dig >= 15)
    print("ok")
