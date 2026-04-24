// Migrated from PCRE2
use std.re.defs

fn _pcre2_valid_utf_8(string: *const u8, __param_length: c_ulong, erroroffset: *mut c_ulong) -> c_int {
    var length = __param_length
    var p: *const u8

    var c: c_uint

    (p = string)

    while ((if length > 0: 1 else: 0) != 0) {
        var ab: c_uint

        var d: c_uint


        (c = (unsafe: *p))

        (length = length - 1)

        if ((if c < 128: 1 else: 0) != 0) {
            (p = p + 1)

            continue

        }

        if ((if c < 192: 1 else: 0) != 0) {
            ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong)))

            return -22

        }

        if ((if c >= 254: 1 else: 0) != 0) {
            ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong)))

            return -23

        }

        (ab = _pcre2_utf8_table4[(c & 63)])

        if ((if length < ab: 1 else: 0) != 0) {
            ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong)))

            match (ab -% length) {
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

        (length = length - ab)

        (p = p + 1)

        (d = (unsafe: *p))

        if ((if (d & 192) != 128: 1 else: 0) != 0) {
            ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 1))

            return -8

        }


        match ab {
            1 => {
                if ((if (c & 62) == 0: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 1))

                    return -17

                }
            },
            2 => {
                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 2))

                    return -9

                }


                var __ci_expr_logic_0: c_int = 0

                if ((if c == 224: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (d & 32) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 2))

                    return -18

                }


                var __ci_expr_logic_1: c_int = 0

                if ((if c == 237: 1 else: 0) != 0) {
                    (__ci_expr_logic_1 = (if (if d >= 160: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_1 != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 2))

                    return -16

                }


            },
            3 => {
                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 2))

                    return -9

                }


                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 3))

                    return -10

                }


                var __ci_expr_logic_2: c_int = 0

                if ((if c == 240: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if (d & 48) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 3))

                    return -19

                }


                var __ci_expr_logic_4: c_int

                if ((if c > 244: 1 else: 0) != 0) {
                    (__ci_expr_logic_4 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_3: c_int = 0

                    if ((if c == 244: 1 else: 0) != 0) {
                        (__ci_expr_logic_3 = (if (if d > 143: 1 else: 0) != 0: 1 else: 0))
                    }

                    (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

                }

                if (__ci_expr_logic_4 != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 3))

                    return -15

                }


            },
            4 => {
                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 2))

                    return -9

                }


                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 3))

                    return -10

                }


                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 4))

                    return -11

                }


                var __ci_expr_logic_5: c_int = 0

                if ((if c == 248: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if (d & 56) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_5 != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 4))

                    return -20

                }


            },
            5 => {
                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 2))

                    return -9

                }


                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 3))

                    return -10

                }


                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 4))

                    return -11

                }


                (p = p + 1)

                if ((if ((unsafe: *p) & 192) != 128: 1 else: 0) != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 5))

                    return -12

                }


                var __ci_expr_logic_6: c_int = 0

                if ((if c == 252: 1 else: 0) != 0) {
                    (__ci_expr_logic_6 = (if (if (d & 60) == 0: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_6 != 0) {
                    ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% 5))

                    return -21

                }


            },
        }

        if ((if ab > 3: 1 else: 0) != 0) {
            ((unsafe: *erroroffset) = (((((p as usize) -% (string as usize)) / sizeof[u8]()) as c_ulong) -% ab))

            var __ci_expr_ternary_7: c_int = 0

            if ((if ab == 4: 1 else: 0) != 0) {
                (__ci_expr_ternary_7 = -13)
            } else {
                (__ci_expr_ternary_7 = -14)
            }

            return __ci_expr_ternary_7


        }


        (p = p + 1)

    }


    return 0

}
