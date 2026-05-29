// Migrated from PCRE2
use std.re.defs

fn _pcre2_is_newline_8(__param_ptr: *const u8, __param_type_: c_uint, __param_endptr: *const u8, __param_lenptr: *mut c_uint, __param_utf: c_int) -> c_int {
    var __local_c: c_uint

    if (__param_utf != 0) {
        (__local_c = (unsafe *__param_ptr))

        if ((if __local_c >= 192: 1 else: 0) != 0) {
            if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe __param_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
            } else {
                if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe __param_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __param_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                } else {
                    if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe __param_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __param_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __param_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                    } else {
                        if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe __param_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __param_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __param_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __param_ptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                        } else {
                            (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe __param_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __param_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __param_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __param_ptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __param_ptr[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                        }
                    }
                }
            }

        }

    } else {
        (__local_c = (unsafe *__param_ptr))
    }

    if ((if __param_type_ == 2: 1 else: 0) != 0) {
        match __local_c {
            10 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            13 => {
                var __ci_expr_ternary_1: c_int = 0

                var __ci_expr_logic_0: c_int = 0

                if ((if __param_ptr < (__param_endptr - ((1 as isize) as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (unsafe __param_ptr[1]) == 10: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_ternary_1 = 2)
                } else {
                    (__ci_expr_ternary_1 = 1)
                }

                ((unsafe *__param_lenptr) = __ci_expr_ternary_1)


                return 1

            },
            _ => {
                return 0
            },
        }
    } else {
        match __local_c {
            10 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            11 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            12 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            13 => {
                var __ci_expr_ternary_3: c_int = 0

                var __ci_expr_logic_2: c_int = 0

                if ((if __param_ptr < (__param_endptr - ((1 as isize) as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if (unsafe __param_ptr[1]) == 10: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    (__ci_expr_ternary_3 = 2)
                } else {
                    (__ci_expr_ternary_3 = 1)
                }

                ((unsafe *__param_lenptr) = __ci_expr_ternary_3)


                return 1

            },
            133 => {
                var __ci_expr_ternary_4: c_int = 0

                if (__param_utf != 0) {
                    (__ci_expr_ternary_4 = 2)
                } else {
                    (__ci_expr_ternary_4 = 1)
                }

                ((unsafe *__param_lenptr) = __ci_expr_ternary_4)


                return 1

            },
            8232 => {
                ((unsafe *__param_lenptr) = 3)

                return 1

            },
            8233 => {
                ((unsafe *__param_lenptr) = 3)

                return 1

            },
            _ => {
                return 0
            },
        }
    }

}

fn _pcre2_was_newline_8(__param_ptr: *const u8, __param_type_: c_uint, __param_startptr: *const u8, __param_lenptr: *mut c_uint, __param_utf: c_int) -> c_int {
    var __local_ptr = __param_ptr
    var __local_c: c_uint

    (__local_ptr = __local_ptr - 1)

    if (__param_utf != 0) {
        while ((if ((((unsafe *__local_ptr) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0) {
            (__local_ptr = __local_ptr - 1)
        }

        (__local_c = (unsafe *__local_ptr))

        if ((if __local_c >= 192: 1 else: 0) != 0) {
            if ((if ((__local_c as c_uint) & (32 as c_uint)) == 0: 1 else: 0) != 0) {
                (__local_c = (((((__local_c as c_uint) & (31 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint) | (((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
            } else {
                if ((if ((__local_c as c_uint) & (16 as c_uint)) == 0: 1 else: 0) != 0) {
                    (__local_c = (((((((__local_c as c_uint) & (15 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                } else {
                    if ((if ((__local_c as c_uint) & (8 as c_uint)) == 0: 1 else: 0) != 0) {
                        (__local_c = (((((((((__local_c as c_uint) & (7 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                    } else {
                        if ((if ((__local_c as c_uint) & (4 as c_uint)) == 0: 1 else: 0) != 0) {
                            (__local_c = (((((((((((__local_c as c_uint) & (3 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                        } else {
                            (__local_c = (((((((((((((__local_c as c_uint) & (1 as c_uint)) as c_uint) << (30 as c_uint)) as c_uint) | (((((((unsafe __local_ptr[1]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (24 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[2]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (18 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[3]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (12 as c_uint)) as c_uint)) as c_uint) | (((((((unsafe __local_ptr[4]) as c_int) as c_uint) & (63 as c_uint)) as c_uint) << (6 as c_uint)) as c_uint)) as c_uint) | (((((unsafe __local_ptr[5]) as c_int) as c_uint) & (63 as c_uint)) as c_uint))
                        }
                    }
                }
            }

        }

    } else {
        (__local_c = (unsafe *__local_ptr))
    }

    if ((if __param_type_ == 2: 1 else: 0) != 0) {
        match __local_c {
            10 => {
                var __ci_expr_ternary_1: c_int = 0

                var __ci_expr_logic_0: c_int = 0

                if ((if __local_ptr > __param_startptr: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (unsafe __local_ptr[-1]) == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_ternary_1 = 2)
                } else {
                    (__ci_expr_ternary_1 = 1)
                }

                ((unsafe *__param_lenptr) = __ci_expr_ternary_1)


                return 1

            },
            13 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            _ => {
                return 0
            },
        }
    } else {
        match __local_c {
            10 => {
                var __ci_expr_ternary_3: c_int = 0

                var __ci_expr_logic_2: c_int = 0

                if ((if __local_ptr > __param_startptr: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if (unsafe __local_ptr[-1]) == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    (__ci_expr_ternary_3 = 2)
                } else {
                    (__ci_expr_ternary_3 = 1)
                }

                ((unsafe *__param_lenptr) = __ci_expr_ternary_3)


                return 1

            },
            11 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            12 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            13 => {
                ((unsafe *__param_lenptr) = 1)

                return 1

            },
            133 => {
                var __ci_expr_ternary_4: c_int = 0

                if (__param_utf != 0) {
                    (__ci_expr_ternary_4 = 2)
                } else {
                    (__ci_expr_ternary_4 = 1)
                }

                ((unsafe *__param_lenptr) = __ci_expr_ternary_4)


                return 1

            },
            8232 => {
                ((unsafe *__param_lenptr) = 3)

                return 1

            },
            8233 => {
                ((unsafe *__param_lenptr) = 3)

                return 1

            },
            _ => {
                return 0
            },
        }
    }

}
