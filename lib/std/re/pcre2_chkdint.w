// Migrated from PCRE2
use std.re.defs

fn _pcre2_ckd_smul_8(r: *mut c_ulong, a: c_int, b: c_int) -> c_int {
    var m: c_longlong

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (m = (a as c_longlong) * (b as c_longlong))

    var __ci_expr_logic_0: c_int = 0
    
    if ((if sizeof[c_longlong]() > sizeof[c_ulong](): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if m > (((0 -% 1) as c_longlong)): 1 else: 0) != 0: 1 else: 0))
    }
    
    if (__ci_expr_logic_0 != 0) {
        return 1
    }
    

    ((unsafe: *r) = ((m as c_ulong)))

    return 0

}

