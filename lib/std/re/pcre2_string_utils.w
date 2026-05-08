// Migrated from PCRE2
use std.re.defs

@[c_export("_pcre2_strcmp_8")]
fn _pcre2_strcmp_8(__param_str1: *const u8, __param_str2: *const u8) -> c_int {
    var __local_str1 = __param_str1
    var __local_str2 = __param_str2
    var __local_c1: u8

    var __local_c2: u8


    while true {
        var __ci_expr_logic_0: c_int

        if ((if (unsafe: *__local_str1) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe: *__local_str2) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_str1

        (__local_str1 = __local_str1 + 1)

        (__local_c1 = (unsafe: *__ci_expr_old_1))

        var __ci_expr_old_2: *const u8 = __local_str2

        (__local_str2 = __local_str2 + 1)

        (__local_c2 = (unsafe: *__ci_expr_old_2))

        if ((if __local_c1 != __local_c2: 1 else: 0) != 0) {
            return ((((if __local_c1 > __local_c2: 1 else: 0) as c_int) << (1 as c_uint)) - 1)
        }

    }

    return 0

}

@[c_export("_pcre2_strcmp_c8_8")]
fn _pcre2_strcmp_c8_8(__param_str1: *const u8, __param_str2: *const i8) -> c_int {
    var __local_str1 = __param_str1
    var __local_str2 = __param_str2
    var __local_c1: u8

    var __local_c2: u8


    while true {
        var __ci_expr_logic_0: c_int

        if ((if (unsafe: *__local_str1) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe: *__local_str2) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_str1

        (__local_str1 = __local_str1 + 1)

        (__local_c1 = (unsafe: *__ci_expr_old_1))

        var __ci_expr_old_2: *const c_char = __local_str2

        (__local_str2 = __local_str2 + 1)

        (__local_c2 = (unsafe: *__ci_expr_old_2))

        if ((if __local_c1 != __local_c2: 1 else: 0) != 0) {
            return ((((if __local_c1 > __local_c2: 1 else: 0) as c_int) << (1 as c_uint)) - 1)
        }

    }

    return 0

}

@[c_export("_pcre2_strcpy_c8_8")]
fn _pcre2_strcpy_c8_8(__param_str1: *mut u8, __param_str2: *const i8) -> c_ulong {
    var __local_str2 = __param_str2
    var __local_t: *mut u8 = __param_str1

    while ((if (unsafe: *__local_str2) != 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = __local_t

        (__local_t = __local_t + 1)

        var __ci_expr_old_1: *const c_char = __local_str2

        (__local_str2 = __local_str2 + 1)

        ((unsafe: *__ci_expr_old_0) = (unsafe: *__ci_expr_old_1))

    }

    ((unsafe: *__local_t) = 0)

    return (((__local_t as usize) -% (__param_str1 as usize)) / sizeof[u8]())

}

@[c_export("_pcre2_strlen_8")]
fn _pcre2_strlen_8(__param_str: *const u8) -> c_ulong {
    var __local_str = __param_str
    var __local_c: c_ulong = 0

    while true {
        var __ci_expr_old_0: *const u8 = __local_str

        (__local_str = __local_str + 1)

        if (not ((if (unsafe: *__ci_expr_old_0) != 0: 1 else: 0) != 0)) {
            break
        }

        (__local_c = __local_c + 1)

    }

    return __local_c

}

@[c_export("_pcre2_strncmp_8")]
fn _pcre2_strncmp_8(__param_str1: *const u8, __param_str2: *const u8, __param_len: c_ulong) -> c_int {
    var __local_str1 = __param_str1
    var __local_str2 = __param_str2
    var __local_len = __param_len
    var __local_c1: u8

    var __local_c2: u8


    while ((if __local_len > 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const u8 = __local_str1

        (__local_str1 = __local_str1 + 1)

        (__local_c1 = (unsafe: *__ci_expr_old_0))


        var __ci_expr_old_1: *const u8 = __local_str2

        (__local_str2 = __local_str2 + 1)

        (__local_c2 = (unsafe: *__ci_expr_old_1))


        if ((if __local_c1 != __local_c2: 1 else: 0) != 0) {
            return ((((if __local_c1 > __local_c2: 1 else: 0) as c_int) << (1 as c_uint)) - 1)
        }


        (__local_len = __local_len - 1)

    }

    return 0

}

@[c_export("_pcre2_strncmp_c8_8")]
fn _pcre2_strncmp_c8_8(__param_str1: *const u8, __param_str2: *const i8, __param_len: c_ulong) -> c_int {
    var __local_str1 = __param_str1
    var __local_str2 = __param_str2
    var __local_len = __param_len
    var __local_c1: u8

    var __local_c2: u8


    while ((if __local_len > 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const u8 = __local_str1

        (__local_str1 = __local_str1 + 1)

        (__local_c1 = (unsafe: *__ci_expr_old_0))


        var __ci_expr_old_1: *const c_char = __local_str2

        (__local_str2 = __local_str2 + 1)

        (__local_c2 = (unsafe: *__ci_expr_old_1))


        if ((if __local_c1 != __local_c2: 1 else: 0) != 0) {
            return ((((if __local_c1 > __local_c2: 1 else: 0) as c_int) << (1 as c_uint)) - 1)
        }


        (__local_len = __local_len - 1)

    }

    return 0

}
