// Migrated from PCRE2
use std.re.defs

@[c_export("_pcre2_valid_utf_8")]
fn _pcre2_valid_utf_8(__param_string: *const u8, __param_length: c_ulong, __param_erroroffset: *mut c_ulong) -> c_int {
    var __local_length = __param_length
    var __local_p: *const u8

    var __local_c: c_uint

    (__local_p = __param_string)

    while ((if __local_length > 0: 1 else: 0) != 0) {
        var __local_ab: c_uint

        var __local_d: c_uint


        (__local_c = (unsafe: *__local_p))

        (__local_length = __local_length - 1)

        if ((if __local_c < 128: 1 else: 0) != 0) {
            (__local_p = __local_p + 1)

            continue

        }

        if ((if __local_c < 192: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = (((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong)))

            return -22

        }

        if ((if __local_c >= 254: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = (((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong)))

            return -23

        }

        (__local_ab = _pcre2_utf8_table4[((__local_c as c_uint) & (63 as c_uint))])

        if ((if __local_length < __local_ab: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = (((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong)))

            match ((__local_ab as c_ulong) -% (__local_length as c_ulong)) {
                1 => {
                    return -3
                },
                2 => {
                    return -4
                },
                3 => {
                    return -5
                },
                4 => {
                    return -6
                },
                5 => {
                    return -7
                },
            }

        }

        (__local_length = __local_length - __local_ab)

        (__local_p = __local_p + 1)

        (__local_d = (unsafe: *__local_p))

        if ((if ((__local_d as c_uint) & (192 as c_uint)) != 128: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (1 as c_ulong)))

            return -8

        }


        while true {
            match __local_ab {
                1 => {
                    if ((if ((__local_c as c_uint) & (62 as c_uint)) == 0: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (1 as c_ulong)))

                        return -17

                    }
                },
                2 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    var __ci_expr_logic_0: c_int = 0

                    if ((if __local_c == 224: 1 else: 0) != 0) {
                        (__ci_expr_logic_0 = (if (if ((__local_d as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_0 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -18

                    }


                    var __ci_expr_logic_1: c_int = 0

                    if ((if __local_c == 237: 1 else: 0) != 0) {
                        (__ci_expr_logic_1 = (if (if __local_d >= 160: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_1 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -16

                    }


                },
                3 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -10

                    }


                    var __ci_expr_logic_2: c_int = 0

                    if ((if __local_c == 240: 1 else: 0) != 0) {
                        (__ci_expr_logic_2 = (if (if ((__local_d as c_uint) & (48 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_2 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -19

                    }


                    var __ci_expr_logic_4: c_int

                    if ((if __local_c > 244: 1 else: 0) != 0) {
                        (__ci_expr_logic_4 = (if true: 1 else: 0))
                    } else {
                        var __ci_expr_logic_3: c_int = 0

                        if ((if __local_c == 244: 1 else: 0) != 0) {
                            (__ci_expr_logic_3 = (if (if __local_d > 143: 1 else: 0) != 0: 1 else: 0))
                        }

                        (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

                    }

                    if (__ci_expr_logic_4 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -15

                    }


                },
                4 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -10

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (4 as c_ulong)))

                        return -11

                    }


                    var __ci_expr_logic_5: c_int = 0

                    if ((if __local_c == 248: 1 else: 0) != 0) {
                        (__ci_expr_logic_5 = (if (if ((__local_d as c_uint) & (56 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_5 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (4 as c_ulong)))

                        return -20

                    }


                },
                5 => {
                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (2 as c_ulong)))

                        return -9

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (3 as c_ulong)))

                        return -10

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (4 as c_ulong)))

                        return -11

                    }


                    (__local_p = __local_p + 1)

                    if ((if (((unsafe: *__local_p) as c_int) & 192) != 128: 1 else: 0) != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (5 as c_ulong)))

                        return -12

                    }


                    var __ci_expr_logic_6: c_int = 0

                    if ((if __local_c == 252: 1 else: 0) != 0) {
                        (__ci_expr_logic_6 = (if (if ((__local_d as c_uint) & (60 as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0))
                    }

                    if (__ci_expr_logic_6 != 0) {
                        ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (5 as c_ulong)))

                        return -21

                    }


                },
            }

            break

        }

        if ((if __local_ab > 3: 1 else: 0) != 0) {
            ((unsafe: *__param_erroroffset) = ((((((__local_p as usize) -% (__param_string as usize)) / sizeof[u8]()) as c_ulong) as c_ulong) -% (__local_ab as c_ulong)))

            var __ci_expr_ternary_8: c_int = 0

            if ((if __local_ab == 4: 1 else: 0) != 0) {
                (__ci_expr_ternary_8 = -13)
            } else {
                (__ci_expr_ternary_8 = -14)
            }

            return __ci_expr_ternary_8


        }


        (__local_p = __local_p + 1)

    }


    return 0

}
