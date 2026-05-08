// Migrated from PCRE2
use std.re.defs

@[c_export("_pcre2_ckd_smul_8")]
fn _pcre2_ckd_smul_8(__param_r: *mut c_ulong, __param_a: c_int, __param_b: c_int) -> c_int {
    var __local_m: c_longlong

    do {
        0
    } while (0 != 0)

    (__local_m = (__param_a as c_longlong) * (__param_b as c_longlong))

    var __ci_expr_logic_0: c_int = 0

    if ((if sizeof[c_longlong]() > sizeof[c_ulong](): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if __local_m > ((((0 as c_ulong) -% 1) as c_longlong)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 1
    }


    ((unsafe: *__param_r) = ((__local_m as c_ulong)))

    return 0

}
