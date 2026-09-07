use c_import("typedef long double ld_t; long double ld_fn(long double x); struct LDS { long double v; }; typedef char lds_c_is_16[sizeof(struct LDS)==16?1:-1];")
use std.builtins.print_i32
fn main:
    print_i32(sizeof[c_longdouble]() as i32)
    print_i32(sizeof[LDS]() as i32)
