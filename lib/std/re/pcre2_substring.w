// Migrated from PCRE2
use std.re.defs

fn pcre2_substring_copy_byname_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringname: *const u8, __param_buffer: *mut u8, __param_sizeptr: *mut c_ulong) -> c_int {
    var __local_first: *const u8

    var __local_last: *const u8

    var __local_entry: *const u8


    var __local_failrc: c_int

    var __local_entrysize: c_int


    if ((if __param_match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        return -41
    }

    (__local_entrysize = pcre2_substring_nametable_scan_8(__param_match_data.code, __param_stringname, (&raw mut __local_first as *mut *const u8), (&raw mut __local_last as *mut *const u8)))

    if ((if __local_entrysize < 0: 1 else: 0) != 0) {
        return __local_entrysize
    }

    (__local_failrc = -54)

    (__local_entry = __local_first)

    while ((if __local_entry <= __local_last: 1 else: 0) != 0) {
        var __local_n: c_uint = ((((((unsafe __local_entry[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_entry[(0 + 1)]) as c_int)) as c_uint))

        if ((if __local_n < __param_match_data.oveccount: 1 else: 0) != 0) {
            if ((if __param_match_data.ovector[((__local_n as c_uint) *% (2 as c_uint))] != (~(0 as c_ulong)): 1 else: 0) != 0) {
                return pcre2_substring_copy_bynumber_8(__param_match_data, __local_n, __param_buffer, __param_sizeptr)
            }

            (__local_failrc = -55)

        }


        (__local_entry = __local_entry + ((__local_entrysize as isize) as usize))

    }


    return __local_failrc

}

fn pcre2_substring_copy_bynumber_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringnumber: c_uint, __param_buffer: *mut u8, __param_sizeptr: *mut c_ulong) -> c_int {
    var __local_rc: c_int

    var __local_size: c_ulong

    (__local_rc = pcre2_substring_length_bynumber_8(__param_match_data, __param_stringnumber, (&raw mut __local_size as *mut c_ulong)))

    if ((if __local_rc < 0: 1 else: 0) != 0) {
        return __local_rc
    }

    if ((if ((__local_size as c_ulong) +% (1 as c_ulong)) > (unsafe *__param_sizeptr): 1 else: 0) != 0) {
        return -48
    }

    if ((if __local_size != 0: 1 else: 0) != 0) {
        with_memcpy((__param_buffer as *i8), ((__param_match_data.subject + (__param_match_data.ovector[((__param_stringnumber as c_uint) *% (2 as c_uint))] as usize)) as *i8), (((__local_size as c_ulong) *% (1 as c_ulong)) as i64))
    }

    ((unsafe __param_buffer[__local_size]) = 0)

    ((unsafe *__param_sizeptr) = __local_size)

    return 0

}

fn pcre2_substring_free_8(__param_string: *mut u8) {
    if ((if __param_string != null: 1 else: 0) != 0) {
        var __local_memctl: *mut pcre2_memctl = ((((__param_string as *mut c_char) - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        __local_memctl.free(__local_memctl, __local_memctl.memory_data)

    }

}

fn pcre2_substring_get_byname_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringname: *const u8, __param_stringptr: *mut *mut u8, __param_sizeptr: *mut c_ulong) -> c_int {
    var __local_first: *const u8

    var __local_last: *const u8

    var __local_entry: *const u8


    var __local_failrc: c_int

    var __local_entrysize: c_int


    if ((if __param_match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        return -41
    }

    (__local_entrysize = pcre2_substring_nametable_scan_8(__param_match_data.code, __param_stringname, (&raw mut __local_first as *mut *const u8), (&raw mut __local_last as *mut *const u8)))

    if ((if __local_entrysize < 0: 1 else: 0) != 0) {
        return __local_entrysize
    }

    (__local_failrc = -54)

    (__local_entry = __local_first)

    while ((if __local_entry <= __local_last: 1 else: 0) != 0) {
        var __local_n: c_uint = ((((((unsafe __local_entry[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_entry[(0 + 1)]) as c_int)) as c_uint))

        if ((if __local_n < __param_match_data.oveccount: 1 else: 0) != 0) {
            if ((if __param_match_data.ovector[((__local_n as c_uint) *% (2 as c_uint))] != (~(0 as c_ulong)): 1 else: 0) != 0) {
                return pcre2_substring_get_bynumber_8(__param_match_data, __local_n, __param_stringptr, __param_sizeptr)
            }

            (__local_failrc = -55)

        }


        (__local_entry = __local_entry + ((__local_entrysize as isize) as usize))

    }


    return __local_failrc

}

fn pcre2_substring_get_bynumber_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringnumber: c_uint, __param_stringptr: *mut *mut u8, __param_sizeptr: *mut c_ulong) -> c_int {
    var __local_rc: c_int

    var __local_size: c_ulong

    var __local_yield_: *mut u8

    (__local_rc = pcre2_substring_length_bynumber_8(__param_match_data, __param_stringnumber, (&raw mut __local_size as *mut c_ulong)))

    if ((if __local_rc < 0: 1 else: 0) != 0) {
        return __local_rc
    }

    (__local_yield_ = ((_pcre2_memctl_malloc_8(((sizeof[pcre2_memctl]() as c_ulong) +% (((((__local_size as c_ulong) +% (1 as c_ulong)) as c_ulong) *% (8 as c_ulong)) as c_ulong)), (__param_match_data as *mut pcre2_memctl)) as *mut u8)))

    if ((if __local_yield_ == null: 1 else: 0) != 0) {
        return -48
    }

    (__local_yield_ = ((((__local_yield_ as *mut c_char) + (sizeof[pcre2_memctl]() as usize)) as *mut u8)))

    if ((if __local_size != 0: 1 else: 0) != 0) {
        with_memcpy((__local_yield_ as *i8), ((__param_match_data.subject + (__param_match_data.ovector[((__param_stringnumber as c_uint) *% (2 as c_uint))] as usize)) as *i8), (((__local_size as c_ulong) *% (1 as c_ulong)) as i64))
    }

    ((unsafe __local_yield_[__local_size]) = 0)

    ((unsafe *__param_stringptr) = __local_yield_)

    ((unsafe *__param_sizeptr) = __local_size)

    return 0

}

fn pcre2_substring_length_byname_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringname: *const u8, __param_sizeptr: *mut c_ulong) -> c_int {
    var __local_first: *const u8

    var __local_last: *const u8

    var __local_entry: *const u8


    var __local_failrc: c_int

    var __local_entrysize: c_int


    if ((if __param_match_data.matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        return -41
    }

    (__local_entrysize = pcre2_substring_nametable_scan_8(__param_match_data.code, __param_stringname, (&raw mut __local_first as *mut *const u8), (&raw mut __local_last as *mut *const u8)))

    if ((if __local_entrysize < 0: 1 else: 0) != 0) {
        return __local_entrysize
    }

    (__local_failrc = -54)

    (__local_entry = __local_first)

    while ((if __local_entry <= __local_last: 1 else: 0) != 0) {
        var __local_n: c_uint = ((((((unsafe __local_entry[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_entry[(0 + 1)]) as c_int)) as c_uint))

        if ((if __local_n < __param_match_data.oveccount: 1 else: 0) != 0) {
            if ((if __param_match_data.ovector[((__local_n as c_uint) *% (2 as c_uint))] != (~(0 as c_ulong)): 1 else: 0) != 0) {
                return pcre2_substring_length_bynumber_8(__param_match_data, __local_n, __param_sizeptr)
            }

            (__local_failrc = -55)

        }


        (__local_entry = __local_entry + ((__local_entrysize as isize) as usize))

    }


    return __local_failrc

}

fn pcre2_substring_length_bynumber_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringnumber: c_uint, __param_sizeptr: *mut c_ulong) -> c_int {
    var __local_left: c_ulong

    var __local_right: c_ulong


    var __local_count: c_int = __param_match_data.rc

    if ((if __local_count == -2: 1 else: 0) != 0) {
        if ((if __param_stringnumber > 0: 1 else: 0) != 0) {
            return -2
        }

        (__local_count = 0)

    } else {
        if ((if __local_count < 0: 1 else: 0) != 0) {
            return __local_count
        }
    }

    if ((if __param_match_data.matchedby != PCRE2_MATCHEDBY_DFA_INTERPRETER: 1 else: 0) != 0) {
        if ((if __param_stringnumber > __param_match_data.code.top_bracket: 1 else: 0) != 0) {
            return -49
        }

        if ((if __param_stringnumber >= __param_match_data.oveccount: 1 else: 0) != 0) {
            return -54
        }

        if ((if __param_match_data.ovector[((__param_stringnumber as c_uint) *% (2 as c_uint))] == (~(0 as c_ulong)): 1 else: 0) != 0) {
            return -55
        }

    } else {
        if ((if __param_stringnumber >= __param_match_data.oveccount: 1 else: 0) != 0) {
            return -54
        }

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_count != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __param_stringnumber >= ((__local_count as c_uint)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return -55
        }


    }

    (__local_left = __param_match_data.ovector[((__param_stringnumber as c_uint) *% (2 as c_uint))])

    (__local_right = __param_match_data.ovector[((((__param_stringnumber as c_uint) *% (2 as c_uint)) as c_uint) +% (1 as c_uint))])

    var __ci_expr_logic_1: c_int

    if ((if __local_left > __param_match_data.subject_length: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __local_right > __param_match_data.subject_length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        do {
            0
        } while (0 != 0)

        return -67

    }


    if ((if __param_sizeptr != null: 1 else: 0) != 0) {
        var __ci_expr_ternary_2: c_ulong = 0

        if ((if __local_left > __local_right: 1 else: 0) != 0) {
            (__ci_expr_ternary_2 = 0)
        } else {
            (__ci_expr_ternary_2 = ((__local_right as c_ulong) -% (__local_left as c_ulong)))
        }

        ((unsafe *__param_sizeptr) = __ci_expr_ternary_2)

    }

    return 0

}

fn pcre2_substring_nametable_scan_8(__param_code: *const pcre2_real_code_8, __param_stringname: *const u8, __param_firstptr: *mut *const u8, __param_lastptr: *mut *const u8) -> c_int {
    var __local_bot: c_ushort = 0

    var __local_top: c_ushort = __param_code.name_count

    var __local_entrysize: c_ushort = __param_code.name_entry_size

    var __local_nametable: *const u8 = ((((__param_code as *const c_char) + (sizeof[pcre2_real_code_8]() as usize)) as *const u8))

    while ((if __local_top > __local_bot: 1 else: 0) != 0) {
        var __local_mid: c_ushort = ((((__local_top as c_int) + (__local_bot as c_int)) / 2)) as c_ushort

        var __local_entry: *const u8 = (__local_nametable + ((((__local_entrysize as c_int) * (__local_mid as c_int)) as isize) as usize))

        var __local_c: c_int = _pcre2_strcmp_8(__param_stringname, (__local_entry + ((2 as isize) as usize)))

        if ((if __local_c == 0: 1 else: 0) != 0) {
            var __local_first: *const u8

            var __local_last: *const u8

            var __local_lastentry: *const u8

            (__local_lastentry = __local_nametable + ((((__local_entrysize as c_int) * ((__param_code.name_count as c_int) - 1)) as isize) as usize))

            (__local_last = __local_entry)

            (__local_first = __local_last)


            while ((if __local_first > __local_nametable: 1 else: 0) != 0) {
                if ((if _pcre2_strcmp_8(__param_stringname, ((__local_first - ((__local_entrysize as c_uint) as usize)) + ((2 as isize) as usize))) != 0: 1 else: 0) != 0) {
                    break
                }

                (__local_first = __local_first - ((__local_entrysize as c_uint) as usize))

            }

            while ((if __local_last < __local_lastentry: 1 else: 0) != 0) {
                if ((if _pcre2_strcmp_8(__param_stringname, ((__local_last + ((__local_entrysize as c_uint) as usize)) + ((2 as isize) as usize))) != 0: 1 else: 0) != 0) {
                    break
                }

                (__local_last = __local_last + ((__local_entrysize as c_uint) as usize))

            }

            if ((if __param_firstptr == null: 1 else: 0) != 0) {
                var __ci_expr_ternary_0: c_int = 0

                if ((if __local_first == __local_last: 1 else: 0) != 0) {
                    (__ci_expr_ternary_0 = (((((((unsafe __local_entry[0]) as c_int) << (8 as c_uint)) | ((unsafe __local_entry[(0 + 1)]) as c_int)) as c_uint) as c_int)))
                } else {
                    (__ci_expr_ternary_0 = -50)
                }

                return __ci_expr_ternary_0

            }

            ((unsafe *__param_firstptr) = __local_first)

            ((unsafe *__param_lastptr) = __local_last)

            return __local_entrysize

        }

        if ((if __local_c > 0: 1 else: 0) != 0) {
            (__local_bot = (__local_mid as c_int) + 1)
        } else {
            (__local_top = __local_mid)
        }

    }

    return -49

}

fn pcre2_substring_number_from_name_8(__param_code: *const pcre2_real_code_8, __param_stringname: *const u8) -> c_int {
    return pcre2_substring_nametable_scan_8(__param_code, __param_stringname, null, null)

}

fn pcre2_substring_list_free_8(__param_list: *mut *mut u8) {
    if ((if __param_list != null: 1 else: 0) != 0) {
        var __local_memctl: *mut pcre2_memctl = ((((__param_list as *mut c_char) - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        __local_memctl.free(__local_memctl, __local_memctl.memory_data)

    }

}

fn pcre2_substring_list_get_8(__param_match_data: *mut pcre2_real_match_data_8, __param_listptr: *mut *mut *mut u8, __param_lengthsptr: *mut *mut c_ulong) -> c_int {
    var __local_i: c_int

    var __local_count: c_int

    var __local_count2: c_int


    var __local_size: c_ulong

    var __local_lensp: *mut c_ulong

    var __local_memp: *mut pcre2_memctl

    var __local_listp: *mut *mut u8

    var __local_sp: *mut u8

    var __local_ovector: *mut c_ulong

    (__local_count = __param_match_data.rc)

    if ((if __local_count < 0: 1 else: 0) != 0) {
        return __local_count
    }


    if ((if __local_count == 0: 1 else: 0) != 0) {
        (__local_count = __param_match_data.oveccount)
    }

    (__local_count2 = 2 * __local_count)

    (__local_ovector = (&(unsafe __param_match_data.ovector[0]) as *mut c_ulong))

    (__local_size = ((sizeof[pcre2_memctl]() as c_ulong) +% (sizeof[usize]() as c_ulong)))

    if ((if __param_lengthsptr != null: 1 else: 0) != 0) {
        (__local_size = __local_size + ((sizeof[usize]() as c_ulong) *% (__local_count as c_ulong)))
    }

    (__local_i = 0)

    while ((if __local_i < __local_count2: 1 else: 0) != 0) {
        (__local_size = __local_size + ((sizeof[usize]() as c_ulong) +% (1 as c_ulong)))

        if ((if (unsafe __local_ovector[(__local_i + 1)]) > (unsafe __local_ovector[__local_i]): 1 else: 0) != 0) {
            (__local_size = __local_size + (((((unsafe __local_ovector[(__local_i + 1)]) as c_ulong) -% ((unsafe __local_ovector[__local_i]) as c_ulong)) as c_ulong) *% (1 as c_ulong)))
        }


        (__local_i = __local_i + 2)

    }


    (__local_memp = ((_pcre2_memctl_malloc_8(__local_size, (__param_match_data as *mut pcre2_memctl)) as *mut pcre2_memctl)))

    if ((if __local_memp == null: 1 else: 0) != 0) {
        return -48
    }

    (__local_listp = ((((__local_memp as *mut c_char) + (sizeof[pcre2_memctl]() as usize)) as *mut *mut u8)))

    ((unsafe *__param_listptr) = __local_listp)


    (__local_lensp = ((((__local_listp as *mut c_char) + (((sizeof[usize]() as c_ulong) *% ((__local_count + 1) as c_ulong)) as usize)) as *mut c_ulong)))

    if ((if __param_lengthsptr == null: 1 else: 0) != 0) {
        (__local_sp = ((__local_lensp as *mut u8)))

        (__local_lensp = ((null as *mut c_ulong)))

    } else {
        ((unsafe *__param_lengthsptr) = __local_lensp)

        (__local_sp = ((((__local_lensp as *mut c_char) + (((sizeof[usize]() as c_ulong) *% (__local_count as c_ulong)) as usize)) as *mut u8)))

    }

    (__local_i = 0)

    while ((if __local_i < __local_count2: 1 else: 0) != 0) {
        var __ci_expr_ternary_0: c_ulong = 0

        if ((if (unsafe __local_ovector[(__local_i + 1)]) > (unsafe __local_ovector[__local_i]): 1 else: 0) != 0) {
            (__ci_expr_ternary_0 = (((unsafe __local_ovector[(__local_i + 1)]) as c_ulong) -% ((unsafe __local_ovector[__local_i]) as c_ulong)))
        } else {
            (__ci_expr_ternary_0 = 0)
        }

        (__local_size = __ci_expr_ternary_0)


        if ((if __local_size != 0: 1 else: 0) != 0) {
            with_memcpy((__local_sp as *i8), ((__param_match_data.subject + ((unsafe __local_ovector[__local_i]) as usize)) as *i8), (((__local_size as c_ulong) *% (1 as c_ulong)) as i64))
        }

        var __ci_expr_old_1: *mut *mut u8 = __local_listp

        (__local_listp = __local_listp + 1)

        ((unsafe *__ci_expr_old_1) = __local_sp)


        if ((if __local_lensp != null: 1 else: 0) != 0) {
            var __ci_expr_old_2: *mut c_ulong = __local_lensp

            (__local_lensp = __local_lensp + 1)

            ((unsafe *__ci_expr_old_2) = __local_size)

        }

        (__local_sp = __local_sp + (__local_size as usize))

        var __ci_expr_old_3: *mut u8 = __local_sp

        (__local_sp = __local_sp + 1)

        ((unsafe *__ci_expr_old_3) = 0)



        (__local_i = __local_i + 2)

    }


    ((unsafe *__local_listp) = ((null as *mut u8)))

    return 0

}
