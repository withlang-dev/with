// Migrated from PCRE2
use std.re.defs

fn _pcre2_strcmp_8(__param_str1: *const u8, __param_str2: *const u8) -> c_int {
    var str1 = __param_str1
    var str2 = __param_str2
    var c1: u8

    var c2: u8


    while true {
        var __ci_expr_logic_0: c_int

        if ((if (unsafe: *str1) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe: *str2) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = str1

        (str1 = str1 + 1)

        (c1 = (unsafe: *__ci_expr_old_1))

        var __ci_expr_old_2: *const u8 = str2

        (str2 = str2 + 1)

        (c2 = (unsafe: *__ci_expr_old_2))

        if ((if c1 != c2: 1 else: 0) != 0) {
            return ((((if c1 > c2: 1 else: 0) as c_int) << 1) - 1)
        }

    }

    return 0

}

fn _pcre2_strcmp_c8_8(__param_str1: *const u8, __param_str2: *const i8) -> c_int {
    var str1 = __param_str1
    var str2 = __param_str2
    var c1: u8

    var c2: u8


    while true {
        var __ci_expr_logic_0: c_int

        if ((if (unsafe: *str1) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe: *str2) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = str1

        (str1 = str1 + 1)

        (c1 = (unsafe: *__ci_expr_old_1))

        var __ci_expr_old_2: *const c_char = str2

        (str2 = str2 + 1)

        (c2 = (unsafe: *__ci_expr_old_2))

        if ((if c1 != c2: 1 else: 0) != 0) {
            return ((((if c1 > c2: 1 else: 0) as c_int) << 1) - 1)
        }

    }

    return 0

}

fn _pcre2_strcpy_c8_8(str1: *mut u8, __param_str2: *const i8) -> c_ulong {
    var str2 = __param_str2
    var t: *mut u8 = str1

    while ((if (unsafe: *str2) != 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *mut u8 = t

        (t = t + 1)

        var __ci_expr_old_1: *const c_char = str2

        (str2 = str2 + 1)

        ((unsafe: *__ci_expr_old_0) = (unsafe: *__ci_expr_old_1))

    }

    ((unsafe: *t) = 0)

    return (((t as usize) -% (str1 as usize)) / sizeof[u8]())

}

fn _pcre2_strlen_8(__param_str: *const u8) -> c_ulong {
    var str = __param_str
    var c: c_ulong = 0

    while true {
        var __ci_expr_old_0: *const u8 = str

        (str = str + 1)

        if (not ((if (unsafe: *__ci_expr_old_0) != 0: 1 else: 0) != 0)) {
            break
        }

        (c = c + 1)

    }

    return c

}

fn _pcre2_strncmp_8(__param_str1: *const u8, __param_str2: *const u8, __param_len: c_ulong) -> c_int {
    var str1 = __param_str1
    var str2 = __param_str2
    var len = __param_len
    var c1: u8

    var c2: u8


    while ((if len > 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const u8 = str1

        (str1 = str1 + 1)

        (c1 = (unsafe: *__ci_expr_old_0))


        var __ci_expr_old_1: *const u8 = str2

        (str2 = str2 + 1)

        (c2 = (unsafe: *__ci_expr_old_1))


        if ((if c1 != c2: 1 else: 0) != 0) {
            return ((((if c1 > c2: 1 else: 0) as c_int) << 1) - 1)
        }


        (len = len - 1)

    }

    return 0

}

fn _pcre2_strncmp_c8_8(__param_str1: *const u8, __param_str2: *const i8, __param_len: c_ulong) -> c_int {
    var str1 = __param_str1
    var str2 = __param_str2
    var len = __param_len
    var c1: u8

    var c2: u8


    while ((if len > 0: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const u8 = str1

        (str1 = str1 + 1)

        (c1 = (unsafe: *__ci_expr_old_0))


        var __ci_expr_old_1: *const c_char = str2

        (str2 = str2 + 1)

        (c2 = (unsafe: *__ci_expr_old_1))


        if ((if c1 != c2: 1 else: 0) != 0) {
            return ((((if c1 > c2: 1 else: 0) as c_int) << 1) - 1)
        }


        (len = len - 1)

    }

    return 0

}
