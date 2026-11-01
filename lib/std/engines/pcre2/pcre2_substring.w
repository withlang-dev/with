// Migrated from C
use std.engines.pcre2.defs
use std.engines.pcre2.pcre2_config
use std.engines.pcre2.pcre2_context
use std.engines.pcre2.pcre2_convert
use std.engines.pcre2.pcre2_compile
use std.engines.pcre2.pcre2_pattern_info
use std.engines.pcre2.pcre2_match_data
use std.engines.pcre2.pcre2_dfa_match
use std.engines.pcre2.pcre2_match
use std.engines.pcre2.pcre2_match_next
use std.engines.pcre2.pcre2_serialize
use std.engines.pcre2.pcre2_substitute
use std.engines.pcre2.pcre2_jit_compile
use std.engines.pcre2.pcre2_error
use std.engines.pcre2.pcre2_maketables
use std.engines.pcre2.pcre2_tables
use std.engines.pcre2.pcre2_chartables
use std.engines.pcre2.pcre2_ucd
use std.engines.pcre2.pcre2_auto_possess
use std.engines.pcre2.pcre2_chkdint
use std.engines.pcre2.pcre2_extuni
use std.engines.pcre2.pcre2_find_bracket
use std.engines.pcre2.pcre2_newline
use std.engines.pcre2.pcre2_ord2utf
use std.engines.pcre2.pcre2_script_run
use std.engines.pcre2.pcre2_string_utils
use std.engines.pcre2.pcre2_study
use std.engines.pcre2.pcre2_valid_utf
use std.engines.pcre2.pcre2_xclass

// contract: receiver:pcre2_real_match_data_8,unproved:1:read only,unproved:2:out-parameter a return before the write,unproved:3:out-parameter a return before the write
pub unsafe fn pcre2_substring_copy_byname_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringname: *const u8, __param_buffer: *mut u8, __param_sizeptr: *mut u64) -> i32 {
    var __local_first: *const u8

    var __local_last: *const u8

    var __local_entry: *const u8


    var __local_failrc: i32

    var __local_entrysize: i32


    if ((*__param_match_data).matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER) {
        return -41
    }

    (__local_entrysize = ((pcre2_substring_nametable_scan_8((*__param_match_data).code, __param_stringname, (&raw mut __local_first as *mut *const u8), (&raw mut __local_last as *mut *const u8)) as i32)))

    if (__local_entrysize < 0) {
        return __local_entrysize
    }

    (__local_failrc = ((-54 as i32)))

    (__local_entry = __local_first)

    while (__local_entry <= __local_last) {
        var __local_n: u32 = (((((((__local_entry[0]) as i32) << (8 as u32)) as i32) | ((__local_entry[(0 + 1)]) as i32)) as u32))

        if (__local_n < (*__param_match_data).oveccount) {
            if ((*__param_match_data).ovector[((__local_n as u32) *% (2 as u32))] != (~(0 as u64))) {
                return pcre2_substring_copy_bynumber_8(__param_match_data, __local_n, __param_buffer, __param_sizeptr)
            }

            (__local_failrc = ((-55 as i32)))

        }


        (__local_entry = __local_entry + ((__local_entrysize as isize) as usize))

    }


    return __local_failrc

}

// contract: receiver:pcre2_real_match_data_8,unproved:2:out-parameter a return before the write,unproved:3:out-parameter a return before the write
pub unsafe fn pcre2_substring_copy_bynumber_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringnumber: u32, __param_buffer: *mut u8, __param_sizeptr: *mut u64) -> i32 {
    var __local_rc: i32

    var __local_size: u64

    (__local_rc = ((pcre2_substring_length_bynumber_8(__param_match_data, __param_stringnumber, (&raw mut __local_size as *mut u64)) as i32)))

    if (__local_rc < 0) {
        return __local_rc
    }

    if (((__local_size as u64) +% (1 as u64)) > (*__param_sizeptr)) {
        return -48
    }

    if (__local_size != 0) {
        with_memcpy(((__param_buffer as *mut c_void) as *mut u8), ((((*__param_match_data).subject + ((*__param_match_data).ovector[((__param_stringnumber as u32) *% (2 as u32))] as usize)) as *const c_void) as *const u8), ((((__local_size as u64) *% (1 as u64)) as u64) as i64))
    }

    ((__param_buffer[__local_size]) = ((0 as u8)))

    ((*__param_sizeptr) = __local_size)

    return 0

}

// contract: unproved:0:read only
pub unsafe fn pcre2_substring_free_8(__param_string: *mut u8) {
    if (__param_string != null) {
        var __local_memctl: *mut pcre2_memctl = ((((__param_string as *mut c_char) - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        (*__local_memctl).free.unwrap()((__local_memctl as *mut c_void), (*__local_memctl).memory_data)

    }

}

// contract: receiver:pcre2_real_match_data_8,unproved:1:read only,unproved:2:out-parameter a return before the write,unproved:3:out-parameter a return before the write
pub unsafe fn pcre2_substring_get_byname_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringname: *const u8, __param_stringptr: *mut *mut u8, __param_sizeptr: *mut u64) -> i32 {
    var __local_first: *const u8

    var __local_last: *const u8

    var __local_entry: *const u8


    var __local_failrc: i32

    var __local_entrysize: i32


    if ((*__param_match_data).matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER) {
        return -41
    }

    (__local_entrysize = ((pcre2_substring_nametable_scan_8((*__param_match_data).code, __param_stringname, (&raw mut __local_first as *mut *const u8), (&raw mut __local_last as *mut *const u8)) as i32)))

    if (__local_entrysize < 0) {
        return __local_entrysize
    }

    (__local_failrc = ((-54 as i32)))

    (__local_entry = __local_first)

    while (__local_entry <= __local_last) {
        var __local_n: u32 = (((((((__local_entry[0]) as i32) << (8 as u32)) as i32) | ((__local_entry[(0 + 1)]) as i32)) as u32))

        if (__local_n < (*__param_match_data).oveccount) {
            if ((*__param_match_data).ovector[((__local_n as u32) *% (2 as u32))] != (~(0 as u64))) {
                return pcre2_substring_get_bynumber_8(__param_match_data, __local_n, __param_stringptr, __param_sizeptr)
            }

            (__local_failrc = ((-55 as i32)))

        }


        (__local_entry = __local_entry + ((__local_entrysize as isize) as usize))

    }


    return __local_failrc

}

// contract: receiver:pcre2_real_match_data_8,unproved:2:out-parameter a return before the write,unproved:3:out-parameter a return before the write
pub unsafe fn pcre2_substring_get_bynumber_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringnumber: u32, __param_stringptr: *mut *mut u8, __param_sizeptr: *mut u64) -> i32 {
    var __local_rc: i32

    var __local_size: u64

    var __local_yield_: *mut u8

    (__local_rc = ((pcre2_substring_length_bynumber_8(__param_match_data, __param_stringnumber, (&raw mut __local_size as *mut u64)) as i32)))

    if (__local_rc < 0) {
        return __local_rc
    }

    (__local_yield_ = ((_pcre2_memctl_malloc_8((((sizeof[pcre2_memctl]() as u64) +% (((((__local_size as u64) +% (1 as u64)) as u64) *% (8 as u64)) as u64)) as u64), (__param_match_data as *mut pcre2_memctl)) as *mut u8)))

    if (__local_yield_ == null) {
        return -48
    }

    (__local_yield_ = ((((__local_yield_ as *mut c_char) + (sizeof[pcre2_memctl]() as usize)) as *mut u8)))

    if (__local_size != 0) {
        with_memcpy(((__local_yield_ as *mut c_void) as *mut u8), ((((*__param_match_data).subject + ((*__param_match_data).ovector[((__param_stringnumber as u32) *% (2 as u32))] as usize)) as *const c_void) as *const u8), ((((__local_size as u64) *% (1 as u64)) as u64) as i64))
    }

    ((__local_yield_[__local_size]) = ((0 as u8)))

    ((*__param_stringptr) = __local_yield_)

    ((*__param_sizeptr) = __local_size)

    return 0

}

// contract: receiver:pcre2_real_match_data_8,unproved:1:read only,unproved:2:out-parameter a return before the write
pub unsafe fn pcre2_substring_length_byname_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringname: *const u8, __param_sizeptr: *mut u64) -> i32 {
    var __local_first: *const u8

    var __local_last: *const u8

    var __local_entry: *const u8


    var __local_failrc: i32

    var __local_entrysize: i32


    if ((*__param_match_data).matchedby == PCRE2_MATCHEDBY_DFA_INTERPRETER) {
        return -41
    }

    (__local_entrysize = ((pcre2_substring_nametable_scan_8((*__param_match_data).code, __param_stringname, (&raw mut __local_first as *mut *const u8), (&raw mut __local_last as *mut *const u8)) as i32)))

    if (__local_entrysize < 0) {
        return __local_entrysize
    }

    (__local_failrc = ((-54 as i32)))

    (__local_entry = __local_first)

    while (__local_entry <= __local_last) {
        var __local_n: u32 = (((((((__local_entry[0]) as i32) << (8 as u32)) as i32) | ((__local_entry[(0 + 1)]) as i32)) as u32))

        if (__local_n < (*__param_match_data).oveccount) {
            if ((*__param_match_data).ovector[((__local_n as u32) *% (2 as u32))] != (~(0 as u64))) {
                return pcre2_substring_length_bynumber_8(__param_match_data, __local_n, __param_sizeptr)
            }

            (__local_failrc = ((-55 as i32)))

        }


        (__local_entry = __local_entry + ((__local_entrysize as isize) as usize))

    }


    return __local_failrc

}

// contract: receiver:pcre2_real_match_data_8,unproved:2:out-parameter a return before the write
pub unsafe fn pcre2_substring_length_bynumber_8(__param_match_data: *mut pcre2_real_match_data_8, __param_stringnumber: u32, __param_sizeptr: *mut u64) -> i32 {
    var __local_left: u64

    var __local_right: u64


    var __local_count: i32 = (*__param_match_data).rc

    if (__local_count == -2) {
        if (__param_stringnumber > 0) {
            return -2
        }

        (__local_count = ((0 as i32)))

    } else {
        if (__local_count < 0) {
            return __local_count
        }
    }

    if ((*__param_match_data).matchedby != PCRE2_MATCHEDBY_DFA_INTERPRETER) {
        if (__param_stringnumber > (*(*__param_match_data).code).top_bracket) {
            return -49
        }

        if (__param_stringnumber >= (*__param_match_data).oveccount) {
            return -54
        }

        if ((*__param_match_data).ovector[((__param_stringnumber as u32) *% (2 as u32))] == (~(0 as u64))) {
            return -55
        }

    } else {
        if (__param_stringnumber >= (*__param_match_data).oveccount) {
            return -54
        }

        var __ci_expr_logic_0: i32 = 0

        if (__local_count != 0) {
            (__ci_expr_logic_0 = (if __param_stringnumber >= ((__local_count as u32)): 1 else: 0))
        }

        if __ci_expr_logic_0 {
            return -55
        }


    }

    (__local_left = (((*__param_match_data).ovector[((__param_stringnumber as u32) *% (2 as u32))] as u64)))

    (__local_right = (((*__param_match_data).ovector[((((__param_stringnumber as u32) *% (2 as u32)) as u32) +% (1 as u32))] as u64)))

    var __ci_expr_logic_1: i32

    if (__local_left > (*__param_match_data).subject_length) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if __local_right > (*__param_match_data).subject_length: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        loop {
            0
            if not (false) {
                break
            }
        }

        return -67

    }


    if (__param_sizeptr != null) {
        ((*__param_sizeptr) = (((if __local_left > __local_right: (0 as u64) else: (((__local_right as u64) -% (__local_left as u64)) as u64)) as u64)))
    }

    return 0

}

// contract: receiver:pcre2_real_code_8,unproved:1:read only,unproved:2:out-parameter written conditionally,unproved:3:out-parameter written conditionally
pub unsafe fn pcre2_substring_nametable_scan_8(__param_code: *const pcre2_real_code_8, __param_stringname: *const u8, __param_firstptr: *mut *const u8, __param_lastptr: *mut *const u8) -> i32 {
    var __local_bot: u16 = ((0 as u16))

    var __local_top: u16 = (*__param_code).name_count

    var __local_entrysize: u16 = (*__param_code).name_entry_size

    var __local_nametable: *const u8 = ((((__param_code as *const c_char) + (sizeof[pcre2_real_code_8]() as usize)) as *const u8))

    while (__local_top > __local_bot) {
        var __local_mid: u16 = (((((__local_top as i32) + (__local_bot as i32)) / 2) as u16))

        var __local_entry: *const u8 = (__local_nametable + ((((__local_entrysize as i32) * (__local_mid as i32)) as isize) as usize))

        var __local_c: i32 = ((_pcre2_strcmp_8(__param_stringname, (__local_entry + ((2 as isize) as usize))) as i32))

        if (__local_c == 0) {
            var __local_first: *const u8

            var __local_last: *const u8

            var __local_lastentry: *const u8

            (__local_lastentry = __local_nametable + ((((__local_entrysize as i32) * (((*__param_code).name_count as i32) - 1)) as isize) as usize))

            (__local_last = __local_entry)

            (__local_first = __local_last)


            while (__local_first > __local_nametable) {
                if (_pcre2_strcmp_8(__param_stringname, ((__local_first - ((__local_entrysize as u32) as usize)) + ((2 as isize) as usize))) != 0) {
                    break
                }

                (__local_first = __local_first - (((__local_entrysize as u32) as usize) as i32))

            }

            while (__local_last < __local_lastentry) {
                if (_pcre2_strcmp_8(__param_stringname, ((__local_last + ((__local_entrysize as u32) as usize)) + ((2 as isize) as usize))) != 0) {
                    break
                }

                (__local_last = __local_last + (((__local_entrysize as u32) as usize) as i32))

            }

            if (__param_firstptr == null) {
                return (if __local_first == __local_last: (((((((__local_entry[0]) as i32) << (8 as u32)) as i32) | ((__local_entry[(0 + 1)]) as i32)) as u32) as i32) else: (-50 as i32))
            }

            ((*__param_firstptr) = __local_first)

            ((*__param_lastptr) = __local_last)

            return ((__local_entrysize as i32))

        }

        if (__local_c > 0) {
            (__local_bot = ((((__local_mid as i32) + 1) as u16)))
        } else {
            (__local_top = __local_mid)
        }

    }

    return -49

}

// contract: receiver:pcre2_real_code_8,unproved:1:read only
pub unsafe fn pcre2_substring_number_from_name_8(__param_code: *const pcre2_real_code_8, __param_stringname: *const u8) -> i32 {
    return pcre2_substring_nametable_scan_8(__param_code, __param_stringname, (null as *mut *const u8), (null as *mut *const u8))

}

// contract: unproved:0:read only
pub unsafe fn pcre2_substring_list_free_8(__param_list: *mut *mut u8) {
    if (__param_list != null) {
        var __local_memctl: *mut pcre2_memctl = ((((__param_list as *mut c_char) - (sizeof[pcre2_memctl]() as usize)) as *mut pcre2_memctl))

        (*__local_memctl).free.unwrap()((__local_memctl as *mut c_void), (*__local_memctl).memory_data)

    }

}

// contract: receiver:pcre2_real_match_data_8,unproved:1:out-parameter a return before the write,unproved:2:out-parameter a return before the write
pub unsafe fn pcre2_substring_list_get_8(__param_match_data: *mut pcre2_real_match_data_8, __param_listptr: *mut *mut *mut u8, __param_lengthsptr: *mut *mut u64) -> i32 {
    var __local_i: i32

    var __local_count: i32

    var __local_count2: i32


    var __local_size: u64

    var __local_lensp: *mut u64

    var __local_memp: *mut pcre2_memctl

    var __local_listp: *mut *mut u8

    var __local_sp: *mut u8

    var __local_ovector: *mut u64

    (__local_count = (*__param_match_data).rc)

    if (__local_count < 0) {
        return __local_count
    }


    if (__local_count == 0) {
        (__local_count = (((*__param_match_data).oveccount as i32)))
    }

    (__local_count2 = (((2 * __local_count) as i32)))

    (__local_ovector = (&(*__param_match_data).ovector[0] as *mut u64))

    (__local_size = ((((sizeof[pcre2_memctl]() as u64) +% (sizeof[usize]() as u64)) as u64)))

    if (__param_lengthsptr != null) {
        (__local_size = (__local_size +% ((sizeof[u64]() as u64) *% (__local_count as u64))))
    }

    (__local_i = ((0 as i32)))

    while (__local_i < __local_count2) {
        (__local_size = (__local_size +% ((sizeof[usize]() as u64) +% (1 as u64))))

        if ((__local_ovector[(__local_i + 1)]) > (__local_ovector[__local_i])) {
            (__local_size = (__local_size +% (((((__local_ovector[(__local_i + 1)]) as u64) -% ((__local_ovector[__local_i]) as u64)) as u64) *% (1 as u64))))
        }


        (__local_i = __local_i + 2)

    }


    (__local_memp = ((_pcre2_memctl_malloc_8(__local_size, (__param_match_data as *mut pcre2_memctl)) as *mut pcre2_memctl)))

    if (__local_memp == null) {
        return -48
    }

    (__local_listp = ((((__local_memp as *mut c_char) + (sizeof[pcre2_memctl]() as usize)) as *mut *mut u8)))

    ((*__param_listptr) = __local_listp)


    (__local_lensp = ((((__local_listp as *mut c_char) + (((sizeof[usize]() as u64) *% ((__local_count + 1) as u64)) as usize)) as *mut u64)))

    if (__param_lengthsptr == null) {
        (__local_sp = ((__local_lensp as *mut u8)))

        (__local_lensp = ((null as *mut u64)))

    } else {
        ((*__param_lengthsptr) = __local_lensp)

        (__local_sp = ((((__local_lensp as *mut c_char) + (((sizeof[u64]() as u64) *% (__local_count as u64)) as usize)) as *mut u8)))

    }

    (__local_i = ((0 as i32)))

    while (__local_i < __local_count2) {
        (__local_size = (((if (__local_ovector[(__local_i + 1)]) > (__local_ovector[__local_i]): ((((__local_ovector[(__local_i + 1)]) as u64) -% ((__local_ovector[__local_i]) as u64)) as u64) else: (0 as u64)) as u64)))

        if (__local_size != 0) {
            with_memcpy(((__local_sp as *mut c_void) as *mut u8), ((((*__param_match_data).subject + ((__local_ovector[__local_i]) as usize)) as *const c_void) as *const u8), ((((__local_size as u64) *% (1 as u64)) as u64) as i64))
        }

        var __ci_expr_old_0: *mut *mut u8 = __local_listp

        (__local_listp = __local_listp + 1)

        ((*__ci_expr_old_0) = __local_sp)


        if (__local_lensp != null) {
            var __ci_expr_old_1: *mut u64 = __local_lensp

            (__local_lensp = __local_lensp + 1)

            ((*__ci_expr_old_1) = __local_size)

        }

        (__local_sp = __local_sp + (__local_size as usize))

        var __ci_expr_old_2: *mut u8 = __local_sp

        (__local_sp = __local_sp + 1)

        ((*__ci_expr_old_2) = ((0 as u8)))



        (__local_i = __local_i + 2)

    }


    ((*__local_listp) = ((null as *mut u8)))

    return 0

}
