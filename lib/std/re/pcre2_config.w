// Migrated from PCRE2
use std.re.defs

fn pcre2_config_8(__param_what: c_uint, __param_where_: *mut c_void) -> c_int {
    if ((if __param_where_ == null: 1 else: 0) != 0) {
        while true {
            match __param_what {
                0 => {
                    return 4
                },
                14 => {
                    return 4
                },
                7 => {
                    return 4
                },
                16 => {
                    return 4
                },
                12 => {
                    return 4
                },
                1 => {
                    return 4
                },
                3 => {
                    return 4
                },
                4 => {
                    return 4
                },
                13 => {
                    return 4
                },
                5 => {
                    return 4
                },
                6 => {
                    return 4
                },
                8 => {
                    return 4
                },
                15 => {
                    return 4
                },
                9 => {
                    return 4
                },
                2 => {
                    0
                },
                10 => {
                    0
                },
                11 => {
                    0
                },
                _ => {
                    return -34
                },
            }

            break

        }

    }

    while true {
        match __param_what {
            0 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 1)
            },
            14 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 1)
            },
            7 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 10000000)
            },
            16 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 2)
            },
            12 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 20000000)
            },
            1 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 0)
            },
            2 => {
                return -34
            },
            3 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = ((2 as c_uint)))
            },
            4 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 10000000)
            },
            5 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 2)
            },
            13 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 0)
            },
            6 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 250)
            },
            8 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 0)
            },
            15 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 1088)
            },
            10 => {
                var __local_v: *const c_char = ((_pcre2_unicode_version_8 as *const c_char))

                var __ci_expr_ternary_1: c_ulong = 0

                if ((if __param_where_ == null: 1 else: 0) != 0) {
                    (__ci_expr_ternary_1 = string_len(__local_v))
                } else {
                    (__ci_expr_ternary_1 = _pcre2_strcpy_c8_8((__param_where_ as *mut u8), __local_v))
                }

                return ((((1 as c_ulong) +% (__ci_expr_ternary_1 as c_ulong)) as c_int))


            },
            9 => {
                ((unsafe *(__param_where_ as *mut c_uint)) = 1)
            },
            11 => {
                var __local_v_1: *const c_char = with 0 as __ci_expr_seq_43 {
                    var __ci_expr_ternary_2: *mut c_char = null
                    if ((if 0 == 0: 1 else: 0) != 0) {
                        (__ci_expr_ternary_2 = (("10.47 2025-10-21" as *mut c_char)))
                    } else {
                        (__ci_expr_ternary_2 = (("10.472025-10-21" as *mut c_char)))
                    }
                    (__ci_expr_ternary_2 as *const c_char)
                }

                var __ci_expr_ternary_3: c_ulong = 0

                if ((if __param_where_ == null: 1 else: 0) != 0) {
                    (__ci_expr_ternary_3 = string_len(__local_v_1))
                } else {
                    (__ci_expr_ternary_3 = _pcre2_strcpy_c8_8((__param_where_ as *mut u8), __local_v_1))
                }

                return ((((1 as c_ulong) +% (__ci_expr_ternary_3 as c_ulong)) as c_int))


            },
            _ => {
                return -34
            },
        }

        break

    }

    return 0

}
