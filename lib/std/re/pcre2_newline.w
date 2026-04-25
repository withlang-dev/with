// Migrated from PCRE2
use std.re.defs

fn _pcre2_is_newline_8(ptr: *const u8, type_: c_uint, endptr: *const u8, lenptr: *mut c_uint, utf: c_int) -> c_int {
    var c: c_uint

    if (utf != 0) {
        (c = (unsafe: *ptr))

        if ((if c >= 192: 1 else: 0) != 0) {
            if ((if (c & 32) == 0: 1 else: 0) != 0) {
                (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: ptr[1]) & 63))
            } else {
                if ((if (c & 16) == 0: 1 else: 0) != 0) {
                    (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[2]) & 63))
                } else {
                    if ((if (c & 8) == 0: 1 else: 0) != 0) {
                        (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[3]) & 63))
                    } else {
                        if ((if (c & 4) == 0: 1 else: 0) != 0) {
                            (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[4]) & 63))
                        } else {
                            (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[3]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[4]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[5]) & 63))
                        }
                    }
                }
            }

        }

    } else {
        (c = (unsafe: *ptr))
    }

    if ((if type_ == 2: 1 else: 0) != 0) {
        match c {
            10 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            13 => {
                var __ci_expr_ternary_1: c_int = 0

                var __ci_expr_logic_0: c_int = 0

                if ((if ptr < (endptr - ((1 as isize) as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (unsafe: ptr[1]) == 10: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_ternary_1 = 2)
                } else {
                    (__ci_expr_ternary_1 = 1)
                }

                ((unsafe: *lenptr) = __ci_expr_ternary_1)


                return 1

            },
            _ => {
                return 0
            },
        }
    } else {
        match c {
            10 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            11 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            12 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            13 => {
                var __ci_expr_ternary_3: c_int = 0

                var __ci_expr_logic_2: c_int = 0

                if ((if ptr < (endptr - ((1 as isize) as usize)): 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if (unsafe: ptr[1]) == 10: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    (__ci_expr_ternary_3 = 2)
                } else {
                    (__ci_expr_ternary_3 = 1)
                }

                ((unsafe: *lenptr) = __ci_expr_ternary_3)


                return 1

            },
            133 => {
                var __ci_expr_ternary_4: c_int = 0

                if (utf != 0) {
                    (__ci_expr_ternary_4 = 2)
                } else {
                    (__ci_expr_ternary_4 = 1)
                }

                ((unsafe: *lenptr) = __ci_expr_ternary_4)


                return 1

            },
            8232 => {
                ((unsafe: *lenptr) = 3)

                return 1

            },
            8233 => {
                ((unsafe: *lenptr) = 3)

                return 1

            },
            _ => {
                return 0
            },
        }
    }

}

fn _pcre2_was_newline_8(__param_ptr: *const u8, type_: c_uint, startptr: *const u8, lenptr: *mut c_uint, utf: c_int) -> c_int {
    var ptr = __param_ptr
    var c: c_uint

    (ptr = ptr - 1)

    if (utf != 0) {
        while ((if ((unsafe: *ptr) & 192) == 128: 1 else: 0) != 0) {
            (ptr = ptr - 1)
        }

        (c = (unsafe: *ptr))

        if ((if c >= 192: 1 else: 0) != 0) {
            if ((if (c & 32) == 0: 1 else: 0) != 0) {
                (c = (((c & 31) as c_uint) << (6 as c_uint)) | ((unsafe: ptr[1]) & 63))
            } else {
                if ((if (c & 16) == 0: 1 else: 0) != 0) {
                    (c = ((((c & 15) as c_uint) << (12 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[2]) & 63))
                } else {
                    if ((if (c & 8) == 0: 1 else: 0) != 0) {
                        (c = (((((c & 7) as c_uint) << (18 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[3]) & 63))
                    } else {
                        if ((if (c & 4) == 0: 1 else: 0) != 0) {
                            (c = ((((((c & 3) as c_uint) << (24 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[3]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[4]) & 63))
                        } else {
                            (c = (((((((c & 1) as c_uint) << (30 as c_uint)) | ((((unsafe: ptr[1]) & 63) as c_uint) << (24 as c_uint))) | ((((unsafe: ptr[2]) & 63) as c_uint) << (18 as c_uint))) | ((((unsafe: ptr[3]) & 63) as c_uint) << (12 as c_uint))) | ((((unsafe: ptr[4]) & 63) as c_uint) << (6 as c_uint))) | ((unsafe: ptr[5]) & 63))
                        }
                    }
                }
            }

        }

    } else {
        (c = (unsafe: *ptr))
    }

    if ((if type_ == 2: 1 else: 0) != 0) {
        match c {
            10 => {
                var __ci_expr_ternary_1: c_int = 0

                var __ci_expr_logic_0: c_int = 0

                if ((if ptr > startptr: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (unsafe: ptr[-1]) == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_0 != 0) {
                    (__ci_expr_ternary_1 = 2)
                } else {
                    (__ci_expr_ternary_1 = 1)
                }

                ((unsafe: *lenptr) = __ci_expr_ternary_1)


                return 1

            },
            13 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            _ => {
                return 0
            },
        }
    } else {
        match c {
            10 => {
                var __ci_expr_ternary_3: c_int = 0

                var __ci_expr_logic_2: c_int = 0

                if ((if ptr > startptr: 1 else: 0) != 0) {
                    (__ci_expr_logic_2 = (if (if (unsafe: ptr[-1]) == 13: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_2 != 0) {
                    (__ci_expr_ternary_3 = 2)
                } else {
                    (__ci_expr_ternary_3 = 1)
                }

                ((unsafe: *lenptr) = __ci_expr_ternary_3)


                return 1

            },
            11 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            12 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            13 => {
                ((unsafe: *lenptr) = 1)

                return 1

            },
            133 => {
                var __ci_expr_ternary_4: c_int = 0

                if (utf != 0) {
                    (__ci_expr_ternary_4 = 2)
                } else {
                    (__ci_expr_ternary_4 = 1)
                }

                ((unsafe: *lenptr) = __ci_expr_ternary_4)


                return 1

            },
            8232 => {
                ((unsafe: *lenptr) = 3)

                return 1

            },
            8233 => {
                ((unsafe: *lenptr) = 3)

                return 1

            },
            _ => {
                return 0
            },
        }
    }

}
