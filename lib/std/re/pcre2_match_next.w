// Migrated from PCRE2
use std.re.defs

fn pcre2_next_match_8(__param_match_data: *mut pcre2_real_match_data_8, __param_pstart_offset: *mut c_ulong, __param_poptions: *mut c_uint) -> c_int {
    var __local_rc: c_int = __param_match_data.rc

    var __local_start_offset: c_ulong = __param_match_data.start_offset

    var __local_ovector: *mut c_ulong = ((&raw const (unsafe *__param_match_data).ovector[0] as *mut c_ulong))

    if ((if __local_rc < 0: 1 else: 0) != 0) {
        return 0
    }

    do {
        0
    } while (0 != 0)

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe __local_ovector[0]) != __local_start_offset: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe __local_ovector[1]) == __local_start_offset: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        if ((if __local_start_offset >= __param_match_data.subject_length: 1 else: 0) != 0) {
            return 0
        }

        ((unsafe *__param_pstart_offset) = do_bumpalong(__param_match_data, (unsafe __local_ovector[1])))

        ((unsafe *__param_poptions) = 0)

        return 1

    }


    if ((if (unsafe __local_ovector[0]) == (unsafe __local_ovector[1]): 1 else: 0) != 0) {
        if ((if (unsafe __local_ovector[0]) >= __param_match_data.subject_length: 1 else: 0) != 0) {
            return 0
        }

        ((unsafe *__param_pstart_offset) = (unsafe __local_ovector[1]))

        ((unsafe *__param_poptions) = 8)

        return 1

    }

    ((unsafe *__param_pstart_offset) = (unsafe __local_ovector[1]))

    ((unsafe *__param_poptions) = 0)

    return 1

}

fn do_bumpalong(__param_match_data: *mut pcre2_real_match_data_8, __param_offset: c_ulong) -> c_ulong {
    var __local_subject: *const u8 = __param_match_data.subject

    var __local_subject_length: c_ulong = __param_match_data.subject_length

    var __local_utf: c_int = (if ((__param_match_data.code.overall_options as c_uint) & (524288 as c_uint)) != 0: 1 else: 0)

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe __local_subject[__param_offset]) == 13: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if ((__param_offset as c_ulong) +% (1 as c_ulong)) < __local_subject_length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if (unsafe __local_subject[((__param_offset as c_ulong) +% (1 as c_ulong))]) == 10: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        match __param_match_data.code.newline_convention {
            3 => {
                return ((__param_offset as c_ulong) +% (2 as c_ulong))
            },
            4 => {
                return ((__param_offset as c_ulong) +% (2 as c_ulong))
            },
            5 => {
                return ((__param_offset as c_ulong) +% (2 as c_ulong))
            },
        }

    }


    if (__local_utf != 0) {
        var __local_next: *const u8 = ((__local_subject + (__param_offset as usize)) + ((1 as isize) as usize))

        var __local_subject_end: *const u8 = (__local_subject + (__local_subject_length as usize))

        __local_subject_end

        while true {
            var __ci_expr_logic_2: c_int = 0

            if ((if __local_next < __local_subject_end: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if ((((unsafe *__local_next) as c_int) as c_uint) & (192 as c_uint)) == 128: 1 else: 0) != 0: 1 else: 0))
            }

            if (not (__ci_expr_logic_2 != 0)) {
                break
            }

            (__local_next = __local_next + 1)

        }

        return (((__local_next as usize) -% (__local_subject as usize)) / sizeof[u8]())

    }

    return ((__param_offset as c_ulong) +% (1 as c_ulong))

}
