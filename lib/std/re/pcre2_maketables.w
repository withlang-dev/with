// Migrated from PCRE2
use std.re.defs

fn pcre2_maketables_8(gcontext: *mut pcre2_real_general_context_8) -> *const u8 {
    var yield_: *mut u8 = with 0 as __ci_expr_seq_9 {
        var __ci_expr_ternary_0: *mut c_void = null
        if ((if gcontext != null: 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = gcontext.memctl.malloc(1088, gcontext.memctl.memory_data))
        } else {
            (__ci_expr_ternary_0 = ((with_alloc((1088 as i64)) as *mut c_void)))
        }
        (__ci_expr_ternary_0 as *mut u8)
    }

    var i: c_int

    var p: *mut u8

    if ((if yield_ == null: 1 else: 0) != 0) {
        return null
    }

    (p = yield_)

    (i = 0)

    while ((if i < 256: 1 else: 0) != 0) {
        var c: c_int = to_lower(i)

        var __ci_expr_old_1: *mut u8 = p

        (p = p + 1)

        var __ci_expr_ternary_2: c_int = 0

        if ((if c < 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_2 = c)
        } else {
            (__ci_expr_ternary_2 = i)
        }

        ((unsafe: *__ci_expr_old_1) = __ci_expr_ternary_2)



        (i = i + 1)

    }


    (i = 0)

    while ((if i < 256: 1 else: 0) != 0) {
        var c_1: c_int = with 0 as __ci_expr_seq_60 {
            var __ci_expr_ternary_3: c_int = 0
            if (is_lower(i) != 0) {
                (__ci_expr_ternary_3 = to_upper(i))
            } else {
                (__ci_expr_ternary_3 = to_lower(i))
            }
            __ci_expr_ternary_3
        }

        var __ci_expr_old_4: *mut u8 = p

        (p = p + 1)

        var __ci_expr_ternary_5: c_int = 0

        if ((if c_1 < 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_5 = c_1)
        } else {
            (__ci_expr_ternary_5 = i)
        }

        ((unsafe: *__ci_expr_old_4) = __ci_expr_ternary_5)



        (i = i + 1)

    }


    with_memset((p as *i8), 0, (320 as i64))

    (i = 0)

    while ((if i < 256: 1 else: 0) != 0) {
        if (is_digit(i) != 0) {
            ((unsafe: p[(64 + (i / 8))]) = (unsafe: p[(64 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if (is_upper(i) != 0) {
            ((unsafe: p[(96 + (i / 8))]) = (unsafe: p[(96 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if (is_lower(i) != 0) {
            ((unsafe: p[(128 + (i / 8))]) = (unsafe: p[(128 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if (is_alnum(i) != 0) {
            ((unsafe: p[(160 + (i / 8))]) = (unsafe: p[(160 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if ((if i == 95: 1 else: 0) != 0) {
            ((unsafe: p[(160 + (i / 8))]) = (unsafe: p[(160 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if (is_space(i) != 0) {
            ((unsafe: p[(0 + (i / 8))]) = (unsafe: p[(0 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if (is_xdigit(i) != 0) {
            ((unsafe: p[(32 + (i / 8))]) = (unsafe: p[(32 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if ((if is_print(i) and (not is_space(i)): 1 else: 0) != 0) {
            ((unsafe: p[(192 + (i / 8))]) = (unsafe: p[(192 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if (is_print(i) != 0) {
            ((unsafe: p[(224 + (i / 8))]) = (unsafe: p[(224 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if ((if (is_print(i) and (not is_alnum(i))) and (not is_space(i)): 1 else: 0) != 0) {
            ((unsafe: p[(256 + (i / 8))]) = (unsafe: p[(256 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }

        if ((if (i < 32) or (i == 127): 1 else: 0) != 0) {
            ((unsafe: p[(288 + (i / 8))]) = (unsafe: p[(288 + (i / 8))]) | ((1 as c_uint) << (i & 7)))
        }


        (i = i + 1)

    }


    (p = p + 320)

    (i = 0)

    while ((if i < 256: 1 else: 0) != 0) {
        var x: c_int = 0

        if (is_space(i) != 0) {
            (x = x + 1)
        }

        if (is_alpha(i) != 0) {
            (x = x + 2)
        }

        if (is_lower(i) != 0) {
            (x = x + 4)
        }

        if (is_digit(i) != 0) {
            (x = x + 8)
        }

        var __ci_expr_logic_6: c_int

        if (is_alnum(i) != 0) {
            (__ci_expr_logic_6 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_6 = (if (if i == 95: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_6 != 0) {
            (x = x + 16)
        }


        var __ci_expr_old_7: *mut u8 = p

        (p = p + 1)

        ((unsafe: *__ci_expr_old_7) = x)



        (i = i + 1)

    }


    return yield_

}

fn pcre2_maketables_free_8(gcontext: *mut pcre2_real_general_context_8, tables: *const u8) {
    if ((if gcontext != null: 1 else: 0) != 0) {
        gcontext.memctl.free((tables as *mut c_void), gcontext.memctl.memory_data)
    } else {
        with_free(((tables as *mut c_void) as *mut i8))
    }

}
