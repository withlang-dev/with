// Migrated from PCRE2
use std.re.defs

@[c_export("_pcre2_ord2utf_8")]
fn _pcre2_ord2utf_8(__param_cvalue: c_uint, __param_buffer: *mut u8) -> c_uint {
    var __local_cvalue = __param_cvalue
    var __local_buffer = __param_buffer
    var __local_i: c_uint

    (__local_i = 0)

    while ((if __local_i < _pcre2_utf8_table1_size: 1 else: 0) != 0) {
        if ((if ((__local_cvalue as c_int)) <= _pcre2_utf8_table1[__local_i]: 1 else: 0) != 0) {
            break
        }

        (__local_i = __local_i + 1)

    }


    (__local_buffer = __local_buffer + (__local_i as usize))

    var __local_j: c_uint = __local_i

    while ((if __local_j != 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = __local_buffer

        (__local_buffer = __local_buffer - 1)

        ((unsafe: *__ci_expr_old_0) = (128 as c_uint) | (((__local_cvalue as c_uint) & (63 as c_uint)) as c_uint))


        (__local_cvalue = __local_cvalue >> (6 as c_uint))


        (__local_j = __local_j - 1)

    }


    ((unsafe: *__local_buffer) = (((_pcre2_utf8_table2[__local_i] | (__local_cvalue as c_int)) as u8)))

    return ((__local_i as c_uint) +% (1 as c_uint))

}
