// Migrated from PCRE2
use std.re.defs

fn pcre2_match_data_create_8(__param_oveccount: c_uint, gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var oveccount = __param_oveccount
    var yield_: *mut pcre2_real_match_data_8

    if ((if oveccount < 1: 1 else: 0) != 0) {
        (oveccount = 1)
    }

    if ((if oveccount > 65535: 1 else: 0) != 0) {
        (oveccount = 65535)
    }

    (yield_ = ((_pcre2_memctl_malloc_8((120 +% ((2 *% oveccount) *% sizeof[c_ulong]())), (gcontext as *mut pcre2_memctl)) as *mut pcre2_real_match_data_8)))

    if ((if yield_ == null: 1 else: 0) != 0) {
        return null
    }

    (yield_.oveccount = oveccount)

    (yield_.flags = 0)

    (yield_.heapframes = ((null as *mut heapframe)))

    (yield_.heapframes_size = 0)

    return yield_

}

fn pcre2_match_data_create_from_pattern_8(code: *const pcre2_real_code_8, __param_gcontext: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8 {
    var gcontext = __param_gcontext
    if ((if code == null: 1 else: 0) != 0) {
        return null
    }

    if ((if gcontext == null: 1 else: 0) != 0) {
        (gcontext = ((code as *mut pcre2_real_general_context_8)))
    }

    return pcre2_match_data_create_8((code.top_bracket + 1), gcontext)

}

fn pcre2_match_data_free_8(match_data: *mut pcre2_real_match_data_8) {
    if ((if match_data != null: 1 else: 0) != 0) {
        if ((if match_data.heapframes != null: 1 else: 0) != 0) {
            match_data.memctl.free(match_data.heapframes, match_data.memctl.memory_data)
        }

        if ((if (match_data.flags & 1) != 0: 1 else: 0) != 0) {
            match_data.memctl.free((match_data.subject as *mut c_void), match_data.memctl.memory_data)
        }

        match_data.memctl.free(match_data, match_data.memctl.memory_data)

    }

}

fn pcre2_get_mark_8(match_data: *mut pcre2_real_match_data_8) -> *const u8 {
    return match_data.mark

}

fn pcre2_get_match_data_size_8(match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return (120 +% ((2 * match_data.oveccount) *% sizeof[c_ulong]()))

}

fn pcre2_get_match_data_heapframes_size_8(match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return match_data.heapframes_size

}

fn pcre2_get_ovector_count_8(match_data: *mut pcre2_real_match_data_8) -> c_uint {
    return match_data.oveccount

}

fn pcre2_get_ovector_pointer_8(match_data: *mut pcre2_real_match_data_8) -> *mut c_ulong {
    return (&match_data.ovector[0] as *mut c_ulong)

}

fn pcre2_get_startchar_8(match_data: *mut pcre2_real_match_data_8) -> c_ulong {
    return match_data.startchar

}
