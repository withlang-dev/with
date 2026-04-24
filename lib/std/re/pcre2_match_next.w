// Migrated from PCRE2
use std.re.defs

fn pcre2_next_match_8(match_data: *mut pcre2_real_match_data_8, pstart_offset: *mut c_ulong, poptions: *mut c_uint) -> c_int {
    var rc: c_int = match_data.rc

    var start_offset: c_ulong = match_data.start_offset

    var ovector: *mut c_ulong = ((&match_data.ovector[0] as *mut c_ulong))

    if ((if rc < 0: 1 else: 0) != 0) {
        return 0
    }

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe: ovector[0]) != start_offset: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe: ovector[1]) == start_offset: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        if ((if start_offset >= match_data.subject_length: 1 else: 0) != 0) {
            return 0
        }

        ((unsafe: *pstart_offset) = do_bumpalong(match_data, (unsafe: ovector[1])))

        ((unsafe: *poptions) = 0)

        return 1

    }


    if ((if (unsafe: ovector[0]) == (unsafe: ovector[1]): 1 else: 0) != 0) {
        if ((if (unsafe: ovector[0]) >= match_data.subject_length: 1 else: 0) != 0) {
            return 0
        }

        ((unsafe: *pstart_offset) = (unsafe: ovector[1]))

        ((unsafe: *poptions) = 8)

        return 1

    }

    ((unsafe: *pstart_offset) = (unsafe: ovector[1]))

    ((unsafe: *poptions) = 0)

    return 1

}

fn do_bumpalong(match_data: *mut pcre2_real_match_data_8, offset: c_ulong) -> c_ulong {
    var subject: *const u8 = match_data.subject

    var subject_length: c_ulong = match_data.subject_length

    var utf: c_int = (if (match_data.code.overall_options & 524288) != 0: 1 else: 0)

    var __ci_expr_logic_1: c_int = 0

    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe: subject[offset]) == 13: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (offset +% 1) < subject_length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if (if (unsafe: subject[(offset +% 1)]) == 10: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        match match_data.code.newline_convention {
            3 | 4 | 5 => {
                return (offset +% 2)
            },
        }

    }


    if (utf != 0) {
        var next: *const u8 = ((subject + offset) + ((1 as isize) as usize))

        var subject_end: *const u8 = (subject + subject_length)

        subject_end

        while true {
            var __ci_expr_logic_2: c_int = 0

            if ((if next < subject_end: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if ((unsafe: *next) & 192) == 128: 1 else: 0) != 0: 1 else: 0))
            }

            if (not (__ci_expr_logic_2 != 0)) {
                break
            }

            (next = next + 1)

        }

        return (((next as usize) -% (subject as usize)) / sizeof[u8]())

    }

    return (offset +% 1)

}
