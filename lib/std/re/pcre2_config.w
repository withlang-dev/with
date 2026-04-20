// Migrated from PCRE2
use std.re.defs

fn pcre2_config_8(what: c_uint, where_: *mut c_void) -> c_int {
    if ((if where_ == null: 1 else: 0) != 0) {
        match what:
            0 | 14 | 7 | 16 | 12 | 1 | 3 | 4 | 13 | 5 | 6 | 8 | 15 | 9 =>
                return 4
            _ =>
                return -34
                
                return 4
                
        
    }

    match what:
        0 =>
            ((unsafe: *(where_ as *mut c_uint)) = 1)
        14 =>
            ((unsafe: *(where_ as *mut c_uint)) = 1)
        7 =>
            ((unsafe: *(where_ as *mut c_uint)) = 10000000)
        16 =>
            ((unsafe: *(where_ as *mut c_uint)) = 2)
        12 =>
            ((unsafe: *(where_ as *mut c_uint)) = 20000000)
        1 =>
            ((unsafe: *(where_ as *mut c_uint)) = 0)
        2 =>
            return -34
            
            ((unsafe: *(where_ as *mut c_uint)) = ((2 as c_uint)))
            
        3 =>
            ((unsafe: *(where_ as *mut c_uint)) = ((2 as c_uint)))
        4 =>
            ((unsafe: *(where_ as *mut c_uint)) = 10000000)
        5 =>
            ((unsafe: *(where_ as *mut c_uint)) = 2)
        13 =>
            ((unsafe: *(where_ as *mut c_uint)) = 0)
        6 =>
            ((unsafe: *(where_ as *mut c_uint)) = 250)
        8 =>
            ((unsafe: *(where_ as *mut c_uint)) = 0)
        15 =>
            ((unsafe: *(where_ as *mut c_uint)) = 1088)
        10 =>
            var v: *const c_char = ((_pcre2_unicode_version_8 as *const c_char))
            
            var __ci_expr_ternary_0: c_ulong = 0
            
            if ((if where_ == null: 1 else: 0) != 0) {
                (__ci_expr_ternary_0 = string_len(v))
            } else {
                (__ci_expr_ternary_0 = _pcre2_strcpy_c8_8((where_ as *mut u8), v))
            }
            
            return (((1 +% __ci_expr_ternary_0) as c_int))
            
            
            
            ((unsafe: *(where_ as *mut c_uint)) = 1)
            
        9 =>
            ((unsafe: *(where_ as *mut c_uint)) = 1)
        11 =>
            var v_1: *const c_char = with 0 as __ci_expr_seq_47 {
                var __ci_expr_ternary_1: *mut c_char = null
                if ((if 32 == 0: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = (("10.48 2025-10-21" as *mut c_char)))
                } else {
                    (__ci_expr_ternary_1 = (("10.48-DEV 2025-10-21" as *mut c_char)))
                }
                (__ci_expr_ternary_1 as *const c_char)
            }
            
            var __ci_expr_ternary_2: c_ulong = 0
            
            if ((if where_ == null: 1 else: 0) != 0) {
                (__ci_expr_ternary_2 = string_len(v_1))
            } else {
                (__ci_expr_ternary_2 = _pcre2_strcpy_c8_8((where_ as *mut u8), v_1))
            }
            
            return (((1 +% __ci_expr_ternary_2) as c_int))
            
            
        _ =>
            return -34
            
            ((unsafe: *(where_ as *mut c_uint)) = 1)
            

    return 0

}

