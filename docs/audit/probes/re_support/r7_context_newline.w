use std.libc
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_match_data
use std.re.pcre2_newline

// r7: context setters incl. invalid values; match_data clamps/getters;
// _pcre2_is_newline_8 / _pcre2_was_newline_8 matrix.
unsafe fn main:
    let g = pcre2_general_context_create_8(null as unsafe extern "C" fn(c_ulong, *mut c_void) -> *mut c_void, null as unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, null)
    printf(c"g-null=%d\n".ptr, (g as i64) != 0)
    let cc = pcre2_compile_context_create_8(g)
    printf(c"set-bsrok=%d set-badbsr=%d set-nlok=%d set-badnl=%d\n".ptr, pcre2_set_bsr_8(cc, 1), pcre2_set_bsr_8(cc, 9), pcre2_set_newline_8(cc, 4), pcre2_set_newline_8(cc, 99))
    printf(c"set-maxpat=%d set-maxcompl=%d set-parens=%d set-xopt=%d set-varlook=%d\n".ptr, pcre2_set_max_pattern_length_8(cc, 100), pcre2_set_max_pattern_compiled_length_8(cc, 100), pcre2_set_parens_nest_limit_8(cc, 10), pcre2_set_compile_extra_options_8(cc, 8), pcre2_set_max_varlookbehind_8(cc, 10))
    printf(c"set-opt-null=%d set-opt-full=%d set-opt-bad=%d\n".ptr, pcre2_set_optimize_8(cc, 0), pcre2_set_optimize_8(cc, 1), pcre2_set_optimize_8(cc, 7))
    printf(c"set-opt-nullctx=%d\n".ptr, pcre2_set_optimize_8(null, 0))
    let mc = pcre2_match_context_create_8(g)
    printf(c"set-depth=%d set-heap=%d set-match=%d set-off=%d set-rec=%d\n".ptr, pcre2_set_depth_limit_8(mc, 5), pcre2_set_heap_limit_8(mc, 6), pcre2_set_match_limit_8(mc, 7), pcre2_set_offset_limit_8(mc, 8), pcre2_set_recursion_limit_8(mc, 9))
    let vc = pcre2_convert_context_create_8(g)
    printf(c"glob-esc=%d glob-esc-bad=%d glob-sep=%d glob-sep-bad=%d\n".ptr, pcre2_set_glob_escape_8(vc, 92), pcre2_set_glob_escape_8(vc, 65), pcre2_set_glob_separator_8(vc, 47), pcre2_set_glob_separator_8(vc, 65))
    // copies
    let g2 = pcre2_general_context_copy_8(g)
    let cc2 = pcre2_compile_context_copy_8(cc)
    let mc2 = pcre2_match_context_copy_8(mc)
    let vc2 = pcre2_convert_context_copy_8(vc)
    var ncopy: i32 = 0
    if (g2 as i64) != 0: ncopy = ncopy + 1
    if (cc2 as i64) != 0: ncopy = ncopy + 1
    if (mc2 as i64) != 0: ncopy = ncopy + 1
    if (vc2 as i64) != 0: ncopy = ncopy + 1
    printf(c"copies=%d\n".ptr, ncopy)
    // match_data clamps: 0 -> 1; getters
    let md0 = pcre2_match_data_create_8(0, g)
    let md1 = pcre2_match_data_create_8(5, g)
    printf(c"md0count=%u md1count=%u md1size=%lu mdnull=%d\n".ptr, pcre2_get_ovector_count_8(md0), pcre2_get_ovector_count_8(md1), pcre2_get_match_data_size_8(md1), (pcre2_match_data_create_from_pattern_8(null, g) as i64) == 0)
    printf(c"mdheap=%lu startchar=%lu marknull=%d\n".ptr, pcre2_get_match_data_heapframes_size_8(md1), pcre2_get_startchar_8(md1), (pcre2_get_mark_8(md1) as i64) == 0)
    printf(c"ovecptr=%d\n".ptr, (pcre2_get_ovector_pointer_8(md1) as i64) != 0)
    pcre2_match_data_free_8(md0)
    pcre2_match_data_free_8(md1)
    // newline: type 2 = ANYCRLF-ish? type codes: use 2 (CRLF-only path) and 0 (any)
    let crlf = with_alloc(4)
    unsafe { crlf[0] = 13 }
    unsafe { crlf[1] = 10 }
    var ln: c_uint = 0
    let r_crlf = _pcre2_is_newline_8(crlf, 2, crlf + 2, &raw mut ln, 0)
    let l_crlf = ln
    let r_lf = _pcre2_is_newline_8(crlf + 1, 2, crlf + 2, &raw mut ln, 0)
    let l_lf = ln
    printf(c"is-crlf-t2=%d len=%u is-lf-t2=%d len=%u\n".ptr, r_crlf, l_crlf, r_lf, l_lf)
    let nel = with_alloc(4)  // U+0085 NEL = C2 85
    unsafe { nel[0] = 194 }
    unsafe { nel[1] = 133 }
    let r_nel = _pcre2_is_newline_8(nel, 0, nel + 2, &raw mut ln, 1)
    let l_nel = ln
    let r_nel2 = _pcre2_is_newline_8(nel, 2, nel + 2, &raw mut ln, 1)
    printf(c"is-nel-any=%d len=%u is-nel-t2=%d\n".ptr, r_nel, l_nel, r_nel2)
    let r_lffix = _pcre2_is_newline_8(crlf + 1, 0, crlf + 2, &raw mut ln, 0)
    printf(c"is-lf-fixed=%d len=%u\n".ptr, r_lffix, ln)
    // was_newline: ptr one past CRLF
    let r_was = _pcre2_was_newline_8(crlf + 2, 2, crlf, &raw mut ln, 0)
    let l_was = ln
    let r_waslf = _pcre2_was_newline_8(crlf + 1, 2, crlf, &raw mut ln, 0)
    printf(c"was-crlf=%d len=%u was-lf=%d len=%u\n".ptr, r_was, l_was, r_waslf, ln)
    pcre2_convert_context_free_8(vc)
    pcre2_convert_context_free_8(vc2)
    pcre2_match_context_free_8(mc)
    pcre2_match_context_free_8(mc2)
    pcre2_compile_context_free_8(cc)
    pcre2_compile_context_free_8(cc2)
    pcre2_general_context_free_8(g)
    pcre2_general_context_free_8(g2)
    let _done = 0
