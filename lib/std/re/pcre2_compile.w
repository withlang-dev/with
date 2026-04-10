// Migrated from PCRE2
use std.re.defs

type BOOL = c_int
type PCRE2_UCHAR8 = u8
type PCRE2_SPTR8 = *const u8
type pcre2_general_context_8 = pcre2_real_general_context_8
type pcre2_compile_context_8 = pcre2_real_compile_context_8
type pcre2_match_context_8 = pcre2_real_match_context_8
type pcre2_convert_context_8 = pcre2_real_convert_context_8
type pcre2_code_8 = pcre2_real_code_8
type pcre2_match_data_8 = pcre2_real_match_data_8
type pcre2_jit_stack_8 = pcre2_real_jit_stack_8
type pcre2_jit_callback_8 = *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8
type pcre2_callout_block_8 { version: c_uint = 0, callout_number: c_uint = 0, capture_top: c_uint = 0, capture_last: c_uint = 0, offset_vector: *mut c_ulong = null, mark: *const u8 = null, subject: *const u8 = null, subject_length: c_ulong = 0, start_match: c_ulong = 0, current_position: c_ulong = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null, callout_flags: c_uint = 0 }
type struct_pcre2_callout_block_8 = pcre2_callout_block_8
type pcre2_callout_enumerate_block_8 { version: c_uint = 0, pattern_position: c_ulong = 0, next_item_length: c_ulong = 0, callout_number: c_uint = 0, callout_string_offset: c_ulong = 0, callout_string_length: c_ulong = 0, callout_string: *const u8 = null }
type struct_pcre2_callout_enumerate_block_8 = pcre2_callout_enumerate_block_8
type pcre2_substitute_callout_block_8 { version: c_uint = 0, input: *const u8 = null, output: *const u8 = null, output_offsets: [2]c_ulong = [0 as c_ulong; 2], ovector: *mut c_ulong = null, oveccount: c_uint = 0, subscount: c_uint = 0 }
type struct_pcre2_substitute_callout_block_8 = pcre2_substitute_callout_block_8
extern fn pcre2_config_8(p0: c_uint, p1: *mut c_void) -> c_int
extern fn pcre2_general_context_copy_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_create_8(p0: *const fn(c_ulong, *mut c_void) -> *mut c_void, p1: *const fn(*mut c_void, *mut c_void) -> void, p2: *mut c_void) -> *mut pcre2_real_general_context_8
extern fn pcre2_general_context_free_8(p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_compile_context_copy_8(p0: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_compile_context_8
extern fn pcre2_compile_context_free_8(p0: *mut pcre2_real_compile_context_8) -> void
extern fn pcre2_set_bsr_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_character_tables_8(p0: *mut pcre2_real_compile_context_8, p1: *const u8) -> c_int
extern fn pcre2_set_compile_extra_options_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_max_pattern_length_8(p0: *mut pcre2_real_compile_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_max_pattern_compiled_length_8(p0: *mut pcre2_real_compile_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_max_varlookbehind_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_newline_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_parens_nest_limit_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_compile_recursion_guard_8(p0: *mut pcre2_real_compile_context_8, p1: *const fn(c_uint, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_optimize_8(p0: *mut pcre2_real_compile_context_8, p1: c_uint) -> c_int
extern fn pcre2_convert_context_copy_8(p0: *mut pcre2_real_convert_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_convert_context_8
extern fn pcre2_convert_context_free_8(p0: *mut pcre2_real_convert_context_8) -> void
extern fn pcre2_set_glob_escape_8(p0: *mut pcre2_real_convert_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_glob_separator_8(p0: *mut pcre2_real_convert_context_8, p1: c_uint) -> c_int
extern fn pcre2_pattern_convert_8(p0: *const u8, p1: c_ulong, p2: c_uint, p3: *mut *mut u8, p4: *mut c_ulong, p5: *mut pcre2_real_convert_context_8) -> c_int
extern fn pcre2_converted_pattern_free_8(p0: *mut u8) -> void
extern fn pcre2_match_context_copy_8(p0: *mut pcre2_real_match_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_create_8(p0: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_context_8
extern fn pcre2_match_context_free_8(p0: *mut pcre2_real_match_context_8) -> void
extern fn pcre2_set_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_set_substitute_case_callout_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong, p2: *mut c_void) -> c_int
extern fn pcre2_set_depth_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_heap_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_match_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_offset_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_ulong) -> c_int
extern fn pcre2_set_recursion_limit_8(p0: *mut pcre2_real_match_context_8, p1: c_uint) -> c_int
extern fn pcre2_set_recursion_memory_management_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(c_ulong, *mut c_void) -> *mut c_void, p2: *const fn(*mut c_void, *mut c_void) -> void, p3: *mut c_void) -> c_int
fn pcre2_compile_8(__param_pattern: *const u8, __param_patlen: c_ulong, __param_options: c_uint, errorptr: *mut c_int, erroroffset: *mut c_ulong, __param_ccontext: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_code_8:
    var pattern = __param_pattern
    var patlen = __param_patlen
    var options = __param_options
    var ccontext = __param_ccontext
    var utf: c_int = 0
    var ucp: c_int = 0
    var has_lookbehind: c_int = 0
    var zero_terminated: c_int = 0
    var re: *mut pcre2_real_code_8 = null
    var cb: compile_block_8
    var tables: *const u8 = null
    var null_str: [1]u8 = [0 as u8; 1]
    var code: *mut u8 = null
    var codestart: *mut u8 = null
    var ptr: *const u8 = null
    var pptr: *mut c_uint = null
    var length: c_ulong = 0
    var usedlength: c_ulong = 0
    var re_blocksize: c_ulong = 0
    var parsed_size_needed: c_ulong = 0
    var firstcuflags: c_uint = 0
    var reqcuflags: c_uint = 0
    var firstcu: c_uint = 0
    var reqcu: c_uint = 0
    var setflags: c_uint = 0
    var xoptions: c_uint = 0
    var skipatstart: c_uint = 0
    var limit_heap: c_uint = 0
    var limit_match: c_uint = 0
    var limit_depth: c_uint = 0
    var newline: c_int = 0
    var bsr: c_int = 0
    var errorcode: c_int = 0
    var regexrc: c_int = 0
    var i: c_uint = 0
    var optim_flags: c_uint = 0
    var stack_groupinfo: [256]c_uint = [0 as c_uint; 256]
    var stack_parsed_pattern: [1024]c_uint = [0 as c_uint; 1024]
    var named_groups: [20]named_group_8
    var c16workspace: [3000]c_uint = [0 as c_uint; 3000]
    var cworkspace: *mut u8 = null
    var p: *const pso = null
    var c: c_uint = 0
    var pp: c_uint = 0
    var heap_parsed_pattern: *mut c_uint = null
    var loopcount: c_int = 0
    var ng: *mut named_group_8 = null
    var tablecount: c_uint = 0
    var rcode: *mut u8 = null
    var rgroup: *const u8 = null
    var ccount: c_uint = 0
    var start: c_int = 0
    var rc: [8]recurse_cache
    var groupnumber: c_int = 0
    var search_from: *const u8 = null
    var temp: *mut u8 = null
    var possessify_rc: c_int = 0
    var dotstar_anchor: c_int = 0
    var minminlength: c_int = 0
    var study_rc: c_int = 0
    var assertedcuflags: c_uint = 0
    var assertedcu: c_uint = 0
    var current_data: *mut compile_data = null
    var next_data: *mut compile_data = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                has_lookbehind = 0
                re = (null as *mut pcre2_real_code_8)
                // null_str re-declared (skipped)
                length = 1
                setflags = 0
                limit_heap = 4294967295
                limit_match = 4294967295
                limit_depth = 4294967295
                newline = 0
                bsr = 0
                errorcode = 0
                optim_flags = (if (if ccontext != (null as *mut pcre2_real_compile_context_8): 1 else: 0) != 0: ccontext.optimization_flags else: 7)
                // stack_groupinfo re-declared (skipped)
                // stack_parsed_pattern re-declared (skipped)
                // named_groups re-declared (skipped)
                if (if errorptr == (null as *mut c_int): 1 else: 0) != 0:
                    if (if erroroffset != (null as *mut c_ulong): 1 else: 0) != 0:
                        ((unsafe: *erroroffset) = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return (null as *mut pcre2_real_code_8)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if erroroffset == (null as *mut c_ulong): 1 else: 0) != 0:
                    if (if errorptr != (null as *mut c_int): 1 else: 0) != 0:
                        ((unsafe: *errorptr) = ERR120)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return (null as *mut pcre2_real_code_8)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *errorptr) = ERR0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *erroroffset) = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if pattern == (null as *const u8): 1 else: 0) != 0:
                    if (if patlen == 0: 1 else: 0) != 0:
                        (pattern = ((&null_str[0] as *mut u8) as *const u8))
                    else:
                        ((unsafe: *errorptr) = ERR16)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        return (null as *mut pcre2_real_code_8)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 67108864)) != 0: 1 else: 0) != 0:
                    options = options | 524288
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                zero_terminated
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if patlen > ccontext.max_pattern_length: 1 else: 0) != 0:
                    ((unsafe: *errorptr) = ERR88)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return (null as *mut pcre2_real_code_8)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 16384)) != 0: 1 else: 0) != 0:
                    optim_flags = optim_flags & (0 - 1 - 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 32768)) != 0: 1 else: 0) != 0:
                    optim_flags = optim_flags & (0 - 2 - 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 65536)) != 0: 1 else: 0) != 0:
                    optim_flags = optim_flags & (0 - 4 - 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (tables = (if ((if ccontext.tables != (null as *const u8): 1 else: 0)) != 0: ccontext.tables else: _pcre2_default_tables_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.lcc = (tables + (0 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.fcc = (tables + (256 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.cbits = (tables + (512 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.assert_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.bracount = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.cx = ccontext)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.dupnames = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.end_pattern = (pattern + patlen))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.erroroffset = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.external_flags = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.external_options = options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.groupinfo = (&stack_groupinfo[0] as *mut c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.had_recurse = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.lastcapture = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.max_lookbehind = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.max_varlookbehind = ccontext.max_varlookbehind)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.name_entry_size = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.name_table = (null as *mut u8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.named_groups = (&named_groups[0] as *mut named_group_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.named_group_list_size = 20)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.names_found = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.parens_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.parsed_pattern = (&stack_parsed_pattern[0] as *mut c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.req_varyopt = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.start_code = cworkspace)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.start_pattern = pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.start_workspace = cworkspace)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.workspace_size = 6000)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.first_data = (null as *mut compile_data))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.last_data = (null as *mut compile_data))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.top_backref = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.backref_map = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (xoptions = ccontext.extra_options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (ptr = pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (skipatstart = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 33554432)) == 0: 1 else: 0) != 0:
                    while (if (if (if (patlen -% skipatstart) >= 2: 1 else: 0) != 0 and (if ptr[skipatstart] == 40: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[(skipatstart +% 1)] == 42: 1 else: 0) != 0: 1 else: 0) != 0:
                        (i = 0)
                        while (if i < ((23 * sizeof[pso]()) / sizeof[pso]()): 1 else: 0) != 0:
                            p = ((&pso_list[0] as *mut pso) + i)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if (if ((patlen -% skipatstart) -% 2) >= p.length: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(((ptr + skipatstart) + (2 as isize as usize)), p.name, p.length) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                skipatstart = skipatstart + (p.length + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                match p.type_
                                    PSO_OPT =>
                                        cb.external_options = cb.external_options | p.value
                                    PSO_XOPT =>
                                        xoptions = xoptions | p.value
                                    PSO_FLG =>
                                        setflags = setflags | p.value
                                    PSO_NL =>
                                        (newline = p.value)
                                        setflags = setflags | 32768
                                    PSO_BSR =>
                                        (bsr = p.value)
                                        setflags = setflags | 16384
                                    PSO_LIMM =>
                                        (pp = skipatstart)
                                        if (if (if (if pp >= patlen: 1 else: 0) != 0 or (if pp == skipatstart: 1 else: 0) != 0: 1 else: 0) != 0 or (if ptr[pp] != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (errorcode = ERR60)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            ptr = ptr + pp
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (utf = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 3
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if p.type_ == PSO_LIMH: 1 else: 0) != 0:
                                            (limit_heap = c)
                                        else:
                                            if (if p.type_ == PSO_LIMM: 1 else: 0) != 0:
                                                (limit_match = c)
                                            else:
                                                (limit_depth = c)
                                        (pp = pp + 1)
                                        (skipatstart = pp)
                                    PSO_OPTMZ =>
                                        optim_flags = optim_flags & (0 - (p.value) - 1)
                                        match p.value
                                            1 =>
                                                cb.external_options = cb.external_options | 16384
                                            2 =>
                                                cb.external_options = cb.external_options | 32768
                                            4 =>
                                                cb.external_options = cb.external_options | 65536
                                            _ => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (i = i + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if i >= ((23 * sizeof[pso]()) / sizeof[pso]()): 1 else: 0) != 0:
                            break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ptr = ptr + skipatstart
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((cb.external_options & ((524288 | 131072)))) != 0: 1 else: 0) != 0:
                    (errorcode = ERR32)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 3
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (utf = (if ((cb.external_options & 524288)) != 0: 1 else: 0))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if utf != 0:
                    if (if ((options & 4096)) != 0: 1 else: 0) != 0:
                        (errorcode = ERR74)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 3
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (if ((options & 1073741824)) == 0: 1 else: 0) != 0 and (if ((errorcode = _pcre2_valid_utf_8(pattern, patlen, erroroffset))) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                        __pc = 4
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (ucp = (if ((cb.external_options & 131072)) != 0: 1 else: 0))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ucp != 0 and (if ((cb.external_options & 2048)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (errorcode = ERR75)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 3
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((xoptions & 65536)) != 0: 1 else: 0) != 0:
                    if (if (if utf != 0: 0 else: 1) != 0 and (if ucp != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                        (errorcode = ERR104)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 3
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if utf != 0: 0 else: 1) != 0:
                        (errorcode = ERR105)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 3
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if ((xoptions & 128)) != 0: 1 else: 0) != 0:
                        (errorcode = ERR106)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 3
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if bsr == 0: 1 else: 0) != 0:
                    (bsr = ccontext.bsr_convention)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if newline == 0: 1 else: 0) != 0:
                    (newline = ccontext.newline_convention)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.nltype = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                match newline
                    1 =>
                        (cb.nllen = 1)
                        ((&cb.nl[0] as *mut u8)[0] = 13)
                    2 =>
                        (cb.nllen = 1)
                        ((&cb.nl[0] as *mut u8)[0] = 10)
                    6 =>
                        (cb.nllen = 1)
                        ((&cb.nl[0] as *mut u8)[0] = 0)
                    3 =>
                        (cb.nllen = 2)
                        ((&cb.nl[0] as *mut u8)[0] = 13)
                        ((&cb.nl[0] as *mut u8)[1] = 10)
                    4 =>
                        (cb.nltype = 1)
                    5 =>
                        (cb.nltype = 2)
                    _ =>
                        (errorcode = ERR56)
                        __pc = 3
                        __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (parsed_size_needed = max_parsed_pattern(ptr, cb.end_pattern, utf, options))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((ccontext.extra_options & ((4 | 8)))) != 0: 1 else: 0) != 0:
                    parsed_size_needed = parsed_size_needed + 4
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 4)) != 0: 1 else: 0) != 0:
                    parsed_size_needed = parsed_size_needed + 4
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                parsed_size_needed = parsed_size_needed + 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if parsed_size_needed > 1024: 1 else: 0) != 0:
                    heap_parsed_pattern = (ccontext.memctl.malloc((parsed_size_needed *% sizeof[c_uint]()), ccontext.memctl.memory_data) as *mut c_uint)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if heap_parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                        ((unsafe: *errorptr) = ERR21)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 1
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb.parsed_pattern = heap_parsed_pattern)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.parsed_pattern_end = (cb.parsed_pattern + parsed_size_needed))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (errorcode = parse_regex(ptr, cb.external_options, xoptions, (&mut has_lookbehind as *mut c_int), (&mut cb as *mut compile_block_8)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if errorcode != 0: 1 else: 0) != 0:
                    __pc = 2
                    __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if has_lookbehind != 0:
                    loopcount = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if cb.bracount >= 128: 1 else: 0) != 0:
                        (cb.groupinfo = (ccontext.memctl.malloc((((2 *% ((cb.bracount +% 1)))) *% sizeof[c_uint]()), ccontext.memctl.memory_data) as *mut c_uint))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if cb.groupinfo == (null as *mut c_uint): 1 else: 0) != 0:
                            (errorcode = ERR21)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (cb.erroroffset = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            __pc = 2
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    with_memset((cb.groupinfo as *mut c_void) as *i8, 0, ((((2 *% cb.bracount) +% 1)) *% sizeof[c_uint]()) as i64)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (errorcode = check_lookbehinds(cb.parsed_pattern, (null as *mut *mut c_uint), (null as *mut parsed_recurse_check), (&mut cb as *mut compile_block_8), (&mut loopcount as *mut c_int)))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if errorcode != 0: 1 else: 0) != 0:
                        __pc = 2
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.erroroffset = patlen)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (pptr = cb.parsed_pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (code = cworkspace)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *code) = 137)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                compile_regex(cb.external_options, xoptions, (&mut code as *mut *mut u8), (&mut pptr as *mut *mut c_uint), (&mut errorcode as *mut c_int), 0, (&mut firstcu as *mut c_uint), (&mut firstcuflags as *mut c_uint), (&mut reqcu as *mut c_uint), (&mut reqcuflags as *mut c_uint), (null as *mut branch_chain_8), (null as *mut open_capitem), (&mut cb as *mut compile_block_8), (&mut length as *mut c_ulong))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if errorcode != 0: 1 else: 0) != 0:
                    __pc = 2
                    __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if length > 65536: 1 else: 0) != 0:
                    (errorcode = ERR20)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if re_blocksize > ccontext.max_pattern_compiled_length: 1 else: 0) != 0:
                    (errorcode = ERR101)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                re_blocksize = re_blocksize + sizeof[pcre2_real_code_8]()
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if re == (null as *mut pcre2_real_code_8): 1 else: 0) != 0:
                    (errorcode = ERR21)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                with_memset(((((re as *mut i8) + sizeof[pcre2_real_code_8]()) - (8 as isize as usize)) as *mut c_void) as *i8, 0, 8 as i64)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.memctl = ccontext.memctl)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.tables = tables)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.executable_jit = null)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                with_memset(((&re.start_bitmap[0] as *mut u8) as *mut c_void) as *i8, 0, (32 *% sizeof[u8]()) as i64)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.blocksize = re_blocksize)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.magic_number = 1346589253)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.compile_options = options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.overall_options = cb.external_options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.extra_options = xoptions)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.flags = ((1 | cb.external_flags) | setflags))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.limit_heap = limit_heap)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.limit_match = limit_match)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.limit_depth = limit_depth)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.first_codeunit = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.last_codeunit = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.bsr_convention = bsr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.newline_convention = newline)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.max_lookbehind = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.minlength = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.top_bracket = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.top_backref = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.name_entry_size = cb.name_entry_size)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.name_count = cb.names_found)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.optimization_flags = optim_flags)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.parens_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.assert_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.lastcapture = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.start_code = codestart)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.req_varyopt = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.had_accept = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb.had_pruneorskip = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb.names_found > 0: 1 else: 0) != 0:
                    ng = cb.named_groups
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    tablecount = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (i = 0)
                    while (if i < cb.names_found: 1 else: 0) != 0:
                        if (if ng.length > 0: 1 else: 0) != 0:
                            (tablecount = _pcre2_compile_add_name_to_table8((&mut cb as *mut compile_block_8), ng, tablecount))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (pptr = cb.parsed_pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *code) = 137)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (regexrc = compile_regex(re.overall_options, re.extra_options, (&mut code as *mut *mut u8), (&mut pptr as *mut *mut c_uint), (&mut errorcode as *mut c_int), 0, (&mut firstcu as *mut c_uint), (&mut firstcuflags as *mut c_uint), (&mut reqcu as *mut c_uint), (&mut reqcuflags as *mut c_uint), (null as *mut branch_chain_8), (null as *mut open_capitem), (&mut cb as *mut compile_block_8), (null as *mut c_ulong)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if regexrc < 0: 1 else: 0) != 0:
                    re.flags = re.flags | 8192
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.top_bracket = cb.bracount)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.top_backref = cb.top_backref)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re.max_lookbehind = cb.max_lookbehind)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if cb.had_accept != 0:
                    (reqcu = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (reqcuflags = (4294967294 as c_uint))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    re.flags = re.flags | 8388608
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *code = 0)
                (code = code + 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (usedlength = ((code as usize -% codestart as usize) / sizeof[u8]()))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if usedlength > length: 1 else: 0) != 0:
                    (errorcode = ERR23)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if errorcode == 0: 1 else: 0) != 0 and cb.had_recurse != 0: 1 else: 0) != 0:
                    ccount = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    start = 8
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (rcode = find_recurse(codestart, utf))
                    while (if rcode != (null as *mut u8): 1 else: 0) != 0:
                        if (if groupnumber == 0: 1 else: 0) != 0:
                            (rgroup = (codestart as *const u8))
                        else:
                            search_from = (codestart as *const u8)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (rgroup = (null as *const u8))
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            while (if i < ccount: 1 else: 0) != 0:
                                if (if groupnumber == (&rc[0] as *mut recurse_cache)[p].groupnumber: 1 else: 0) != 0:
                                    (rgroup = (&rc[0] as *mut recurse_cache)[p].group)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if groupnumber > (&rc[0] as *mut recurse_cache)[p].groupnumber: 1 else: 0) != 0:
                                    (search_from = (&rc[0] as *mut recurse_cache)[p].group)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if rgroup == (null as *const u8): 1 else: 0) != 0:
                                (rgroup = _pcre2_find_bracket_8(search_from, utf, groupnumber))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if rgroup == (null as *const u8): 1 else: 0) != 0:
                                    (errorcode = ERR53)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (start = start - 1) < 0: 1 else: 0) != 0:
                                    (start = (8 - 1))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&rc[0] as *mut recurse_cache)[start].groupnumber = groupnumber)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&rc[0] as *mut recurse_cache)[start].group = rgroup)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ccount < 8: 1 else: 0) != 0:
                                    (ccount = ccount + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (rcode = find_recurse(((rcode + (1 as isize as usize)) + (2 as isize as usize)), utf))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if errorcode == 0: 1 else: 0) != 0 and (if ((optim_flags & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    possessify_rc = _pcre2_auto_possessify_8(temp, ((&mut cb as *mut compile_block_8) as *const compile_block_8))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if possessify_rc != 0: 1 else: 0) != 0:
                        (errorcode = ERR80)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (cb.erroroffset = 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if errorcode != 0: 1 else: 0) != 0:
                    __pc = 2
                    __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((re.overall_options & (2147483648 as c_uint))) == 0: 1 else: 0) != 0:
                    dotstar_anchor = ((if ((optim_flags & 2)) != 0: 1 else: 0))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if is_anchored((codestart as *const u8), 0, (&mut cb as *mut compile_block_8), 0, 0, dotstar_anchor) != 0:
                        re.overall_options = re.overall_options | 2147483648
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((optim_flags & 4)) != 0: 1 else: 0) != 0:
                    minminlength = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if firstcuflags >= 4294967294: 1 else: 0) != 0:
                        assertedcuflags = 0
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        assertedcu = find_firstassertedcu((codestart as *const u8), (&mut assertedcuflags as *mut c_uint), 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if (if assertedcuflags < 4294967294: 1 else: 0) != 0 and (if assertedcu != reqcu: 1 else: 0) != 0: 1 else: 0) != 0:
                            (firstcu = assertedcu)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (firstcuflags = assertedcuflags)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if firstcuflags < 4294967294: 1 else: 0) != 0:
                        (re.first_codeunit = firstcu)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        re.flags = re.flags | 16
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (minminlength = minminlength + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if ((firstcuflags & 1)) != 0: 1 else: 0) != 0:
                            if (if (if firstcu < 128: 1 else: 0) != 0 or ((if (if (if utf != 0: 0 else: 1) != 0 and (if ucp != 0: 0 else: 1) != 0: 1 else: 0) != 0 and (if firstcu < 255: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                if (if cb.fcc[firstcu] != firstcu: 1 else: 0) != 0:
                                    re.flags = re.flags | 32
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    continue
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    else:
                        if (if ((re.overall_options & (2147483648 as c_uint))) == 0: 1 else: 0) != 0:
                            dotstar_anchor = ((if ((optim_flags & 2)) != 0: 1 else: 0))
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            if is_startline((codestart as *const u8), 0, (&mut cb as *mut compile_block_8), 0, 0, dotstar_anchor) != 0:
                                re.flags = re.flags | 512
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if reqcuflags < 4294967294: 1 else: 0) != 0:
                        if (if (if ((re.overall_options & (2147483648 as c_uint))) == 0: 1 else: 0) != 0 or (if ((reqcuflags & 2)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                            (re.last_codeunit = reqcu)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            re.flags = re.flags | 128
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            if (if ((reqcuflags & 1)) != 0: 1 else: 0) != 0:
                                if (if (if reqcu < 128: 1 else: 0) != 0 or ((if (if (if utf != 0: 0 else: 1) != 0 and (if ucp != 0: 0 else: 1) != 0: 1 else: 0) != 0 and (if reqcu < 255: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                    if (if cb.fcc[reqcu] != reqcu: 1 else: 0) != 0:
                                        re.flags = re.flags | 256
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        continue
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    continue
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (study_rc = _pcre2_study_8(re))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if study_rc != 0: 1 else: 0) != 0:
                        (errorcode = ERR31)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (cb.erroroffset = 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 2
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (if ((re.flags & 64)) != 0: 1 else: 0) != 0 and (if minminlength == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                        (minminlength = 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if re.minlength < minminlength: 1 else: 0) != 0:
                        (re.minlength = minminlength)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // EXIT
                (__goto_pending = 0)
                if (if cb.parsed_pattern != (&stack_parsed_pattern[0] as *mut c_uint): 1 else: 0) != 0:
                    ccontext.memctl.free((cb.parsed_pattern as *mut c_void), ccontext.memctl.memory_data)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb.named_group_list_size > 20: 1 else: 0) != 0:
                    ccontext.memctl.free((cb.named_groups as *mut c_void), ccontext.memctl.memory_data)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb.groupinfo != (&stack_groupinfo[0] as *mut c_uint): 1 else: 0) != 0:
                    ccontext.memctl.free((cb.groupinfo as *mut c_void), ccontext.memctl.memory_data)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return re
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 2
                continue
            2 =>  // HAD_CB_ERROR
                (__goto_pending = 0)
                (ptr = (pattern + cb.erroroffset))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 3
                continue
            3 =>  // HAD_EARLY_ERROR
                (__goto_pending = 0)
                ((unsafe: *erroroffset) = ((ptr as usize -% pattern as usize) / sizeof[u8]()))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 4
                continue
            4 =>  // HAD_ERROR
                (__goto_pending = 0)
                ((unsafe: *errorptr) = errorcode)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                pcre2_code_free_8(re)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re = (null as *mut pcre2_real_code_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb.first_data != (null as *mut compile_data): 1 else: 0) != 0:
                    current_data = cb.first_data
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while true:
                        next_data = current_data.next
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        cb.cx.memctl.free((current_data as *mut c_void), cb.cx.memctl.memory_data)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (current_data = next_data)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if not ((if current_data != (null as *mut compile_data): 1 else: 0) != 0):
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            _ => break

fn pcre2_code_free_8(code: *mut pcre2_real_code_8):
    var ref_count: *mut c_ulong
    if (if code != (null as *mut pcre2_real_code_8): 1 else: 0) != 0:
        if (if ((code.flags & 262144)) != 0: 1 else: 0) != 0:
            if (if (unsafe: *ref_count) > 0: 1 else: 0) != 0:
                (((unsafe: *ref_count)) = ((unsafe: *ref_count)) - 1)
                if (if (unsafe: *ref_count) == 0: 1 else: 0) != 0:
                    code.memctl.free((code.tables as *mut c_void), code.memctl.memory_data)
                
            
        
        code.memctl.free((code as *mut c_void), code.memctl.memory_data)


fn pcre2_code_copy_8(code: *const pcre2_real_code_8) -> *mut pcre2_real_code_8:
    var ref_count: *mut c_ulong
    var newcode: *mut pcre2_real_code_8
    if (if code == (null as *const pcre2_real_code_8): 1 else: 0) != 0:
        return (null as *mut pcre2_real_code_8)

    (newcode = (code.memctl.malloc(code.blocksize, code.memctl.memory_data) as *mut pcre2_real_code_8))
    if (if newcode == (null as *mut pcre2_real_code_8): 1 else: 0) != 0:
        return (null as *mut pcre2_real_code_8)

    with_memcpy((newcode as *mut c_void) as *i8, (code as *const c_void) as *i8, code.blocksize as i64)
    (newcode.executable_jit = null)
    if (if ((code.flags & 262144)) != 0: 1 else: 0) != 0:
        (((unsafe: *ref_count)) = ((unsafe: *ref_count)) + 1)

    return newcode

fn pcre2_code_copy_with_tables_8(code: *const pcre2_real_code_8) -> *mut pcre2_real_code_8:
    var ref_count: *mut c_ulong
    var newcode: *mut pcre2_real_code_8
    var newtables: *mut u8
    if (if code == (null as *const pcre2_real_code_8): 1 else: 0) != 0:
        return (null as *mut pcre2_real_code_8)

    (newcode = (code.memctl.malloc(code.blocksize, code.memctl.memory_data) as *mut pcre2_real_code_8))
    if (if newcode == (null as *mut pcre2_real_code_8): 1 else: 0) != 0:
        return (null as *mut pcre2_real_code_8)

    with_memcpy((newcode as *mut c_void) as *i8, (code as *const c_void) as *i8, code.blocksize as i64)
    (newcode.executable_jit = null)
    (newtables = (code.memctl.malloc((1088 +% sizeof[c_ulong]()), code.memctl.memory_data) as *mut u8))
    if (if newtables == (null as *mut u8): 1 else: 0) != 0:
        code.memctl.free((newcode as *mut c_void), code.memctl.memory_data)
        return (null as *mut pcre2_real_code_8)

    with_memcpy((newtables as *mut c_void) as *i8, (code.tables as *const c_void) as *i8, 1088 as i64)
    ((unsafe: *ref_count) = 1)
    (newcode.tables = (newtables as *const u8))
    newcode.flags = newcode.flags | 262144
    return newcode

extern fn pcre2_pattern_info_8(p0: *const pcre2_real_code_8, p1: c_uint, p2: *mut c_void) -> c_int
extern fn pcre2_callout_enumerate_8(p0: *const pcre2_real_code_8, p1: *const fn(*mut pcre2_callout_enumerate_block_8, *mut c_void) -> c_int, p2: *mut c_void) -> c_int
extern fn pcre2_match_data_create_8(p0: c_uint, p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_create_from_pattern_8(p0: *const pcre2_real_code_8, p1: *mut pcre2_real_general_context_8) -> *mut pcre2_real_match_data_8
extern fn pcre2_match_data_free_8(p0: *mut pcre2_real_match_data_8) -> void
extern fn pcre2_dfa_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8, p7: *mut c_int, p8: c_ulong) -> c_int
extern fn pcre2_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_get_mark_8(p0: *mut pcre2_real_match_data_8) -> *const u8
extern fn pcre2_get_match_data_size_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_match_data_heapframes_size_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_get_ovector_count_8(p0: *mut pcre2_real_match_data_8) -> c_uint
extern fn pcre2_get_ovector_pointer_8(p0: *mut pcre2_real_match_data_8) -> *mut c_ulong
extern fn pcre2_get_startchar_8(p0: *mut pcre2_real_match_data_8) -> c_ulong
extern fn pcre2_next_match_8(p0: *mut pcre2_real_match_data_8, p1: *mut c_ulong, p2: *mut c_uint) -> c_int
extern fn pcre2_substring_copy_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_copy_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_free_8(p0: *mut u8) -> void
extern fn pcre2_substring_get_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_get_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut *mut u8, p3: *mut c_ulong) -> c_int
extern fn pcre2_substring_length_byname_8(p0: *mut pcre2_real_match_data_8, p1: *const u8, p2: *mut c_ulong) -> c_int
extern fn pcre2_substring_length_bynumber_8(p0: *mut pcre2_real_match_data_8, p1: c_uint, p2: *mut c_ulong) -> c_int
extern fn pcre2_substring_nametable_scan_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: *mut *const u8, p3: *mut *const u8) -> c_int
extern fn pcre2_substring_number_from_name_8(p0: *const pcre2_real_code_8, p1: *const u8) -> c_int
extern fn pcre2_substring_list_free_8(p0: *mut *mut u8) -> void
extern fn pcre2_substring_list_get_8(p0: *mut pcre2_real_match_data_8, p1: *mut *mut *mut u8, p2: *mut *mut c_ulong) -> c_int
extern fn pcre2_serialize_encode_8(p0: *mut *const pcre2_real_code_8, p1: c_int, p2: *mut *mut u8, p3: *mut c_ulong, p4: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_decode_8(p0: *mut *mut pcre2_real_code_8, p1: c_int, p2: *const u8, p3: *mut pcre2_real_general_context_8) -> c_int
extern fn pcre2_serialize_get_number_of_codes_8(p0: *const u8) -> c_int
extern fn pcre2_serialize_free_8(p0: *mut u8) -> void
extern fn pcre2_substitute_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8, p7: *const u8, p8: c_ulong, p9: *mut u8, p10: *mut c_ulong) -> c_int
extern fn pcre2_jit_compile_8(p0: *mut pcre2_real_code_8, p1: c_uint) -> c_int
extern fn pcre2_jit_match_8(p0: *const pcre2_real_code_8, p1: *const u8, p2: c_ulong, p3: c_ulong, p4: c_uint, p5: *mut pcre2_real_match_data_8, p6: *mut pcre2_real_match_context_8) -> c_int
extern fn pcre2_jit_free_unused_memory_8(p0: *mut pcre2_real_general_context_8) -> void
extern fn pcre2_jit_stack_create_8(p0: c_ulong, p1: c_ulong, p2: *mut pcre2_real_general_context_8) -> *mut pcre2_real_jit_stack_8
extern fn pcre2_jit_stack_assign_8(p0: *mut pcre2_real_match_context_8, p1: *const fn(*mut c_void) -> *mut pcre2_real_jit_stack_8, p2: *mut c_void) -> void
extern fn pcre2_jit_stack_free_8(p0: *mut pcre2_real_jit_stack_8) -> void
extern fn pcre2_get_error_message_8(p0: c_int, p1: *mut u8, p2: c_ulong) -> c_int
extern fn pcre2_maketables_8(p0: *mut pcre2_real_general_context_8) -> *const u8
extern fn pcre2_maketables_free_8(p0: *mut pcre2_real_general_context_8, p1: *const u8) -> void
type pcre2_memctl { malloc: *const fn(c_ulong, *mut c_void) -> *mut c_void = null, free: *const fn(*mut c_void, *mut c_void) -> void = null, memory_data: *mut c_void = null }
type struct_pcre2_memctl = pcre2_memctl
type open_capitem { next: *mut open_capitem = null, number: c_ushort = 0, assert_depth: c_ushort = 0 }
type struct_open_capitem = open_capitem
type ucp_type_table { name_offset: c_ushort = 0, type_: c_ushort = 0, value: c_ushort = 0 }
type struct_ucp_type_table = ucp_type_table
type ucd_record { script: u8 = 0, chartype: u8 = 0, gbprop: u8 = 0, caseset: u8 = 0, other_case: c_int = 0, scriptx_bidiclass: c_ushort = 0, bprops: c_ushort = 0 }
type struct_ucd_record = ucd_record
type pcre2_serialized_data { magic: c_uint = 0, version: c_uint = 0, config: c_uint = 0, number_of_codes: c_int = 0 }
type struct_pcre2_serialized_data = pcre2_serialized_data
extern var _pcre2_utf8_table1: *c_int
extern let _pcre2_utf8_table1_size: c_uint
extern var _pcre2_utf8_table2: *c_int
extern var _pcre2_utf8_table3: *c_int
extern var _pcre2_utf8_table4: *u8
extern var _pcre2_OP_lengths_8: *u8
extern var _pcre2_callout_end_delims_8: *c_uint
extern var _pcre2_callout_start_delims_8: *c_uint
extern var _pcre2_default_compile_context_8: pcre2_real_compile_context_8
extern var _pcre2_default_convert_context_8: pcre2_real_convert_context_8
extern var _pcre2_default_match_context_8: pcre2_real_match_context_8
extern var _pcre2_default_tables_8: *u8
extern var _pcre2_hspace_list_8: *c_uint
extern var _pcre2_vspace_list_8: *c_uint
extern var _pcre2_ucd_boolprop_sets_8: *c_uint
extern var _pcre2_ucd_caseless_sets_8: *c_uint
extern let _pcre2_ucd_turkish_dotted_i_caseset_8: c_uint
extern var _pcre2_ucd_nocase_ranges_8: *c_uint
extern let _pcre2_ucd_nocase_ranges_size_8: c_uint
extern var _pcre2_ucd_digit_sets_8: *c_uint
extern var _pcre2_ucd_script_sets_8: *c_uint
extern var _pcre2_ucd_records_8: *ucd_record
extern var _pcre2_ucd_stage1_8: *c_ushort
extern var _pcre2_ucd_stage2_8: *c_ushort
extern var _pcre2_ucp_gbtable_8: *c_uint
extern var _pcre2_ucp_gentype_8: *c_uint
extern var _pcre2_unicode_version_8: *const i8
extern var _pcre2_utt_8: *ucp_type_table
extern var _pcre2_utt_names_8: *c_char
extern let _pcre2_utt_size_8: c_ulong
extern var _pcre2_ebcdic_1047_to_ascii_8: *u8
extern var _pcre2_ascii_to_ebcdic_1047_8: *u8
type pcre2_real_general_context_8 { memctl: pcre2_memctl }
type struct_pcre2_real_general_context_8 = pcre2_real_general_context_8
type pcre2_real_compile_context_8 { memctl: pcre2_memctl, stack_guard: *const fn(c_uint, *mut c_void) -> c_int = null, stack_guard_data: *mut c_void = null, tables: *const u8 = null, max_pattern_length: c_ulong = 0, max_pattern_compiled_length: c_ulong = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, parens_nest_limit: c_uint = 0, extra_options: c_uint = 0, max_varlookbehind: c_uint = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_compile_context_8 = pcre2_real_compile_context_8
type pcre2_real_match_context_8 { memctl: pcre2_memctl, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, callout_data: *mut c_void = null, substitute_callout: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int = null, substitute_callout_data: *mut c_void = null, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong = null, substitute_case_callout_data: *mut c_void = null, offset_limit: c_ulong = 0, heap_limit: c_uint = 0, match_limit: c_uint = 0, depth_limit: c_uint = 0 }
type struct_pcre2_real_match_context_8 = pcre2_real_match_context_8
type pcre2_real_convert_context_8 { memctl: pcre2_memctl, glob_separator: c_uint = 0, glob_escape: c_uint = 0 }
type struct_pcre2_real_convert_context_8 = pcre2_real_convert_context_8
type pcre2_real_code_8 { memctl: pcre2_memctl, tables: *const u8 = null, executable_jit: *mut c_void = null, start_bitmap: [32]u8 = [0 as u8; 32], blocksize: c_ulong = 0, code_start: c_ulong = 0, magic_number: c_uint = 0, compile_options: c_uint = 0, overall_options: c_uint = 0, extra_options: c_uint = 0, flags: c_uint = 0, limit_heap: c_uint = 0, limit_match: c_uint = 0, limit_depth: c_uint = 0, first_codeunit: c_uint = 0, last_codeunit: c_uint = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, max_lookbehind: c_ushort = 0, minlength: c_ushort = 0, top_bracket: c_ushort = 0, top_backref: c_ushort = 0, name_entry_size: c_ushort = 0, name_count: c_ushort = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_code_8 = pcre2_real_code_8
type pcre2_real_match_data_8 { memctl: pcre2_memctl, code: *const pcre2_real_code_8 = null, subject: *const u8 = null, mark: *const u8 = null, heapframes: *mut heapframe = null, heapframes_size: c_ulong = 0, subject_length: c_ulong = 0, start_offset: c_ulong = 0, leftchar: c_ulong = 0, rightchar: c_ulong = 0, startchar: c_ulong = 0, matchedby: u8 = 0, flags: u8 = 0, oveccount: c_ushort = 0, options: c_uint = 0, rc: c_int = 0, ovector: [131072]c_ulong = [0 as c_ulong; 131072] }
type struct_pcre2_real_match_data_8 = pcre2_real_match_data_8
type recurse_check { prev: *mut recurse_check = null, group: *const u8 = null }
type struct_recurse_check = recurse_check
type parsed_recurse_check { prev: *mut parsed_recurse_check = null, groupptr: *mut c_uint = null }
type struct_parsed_recurse_check = parsed_recurse_check
type recurse_cache { group: *const u8 = null, groupnumber: c_int = 0 }
type struct_recurse_cache = recurse_cache
type branch_chain_8 { outer: *mut branch_chain_8 = null, current_branch: *mut u8 = null }
type struct_branch_chain_8 = branch_chain_8
type named_group_8 { name: *const u8 = null, number: c_uint = 0, length: c_ushort = 0, hash_dup: c_ushort = 0 }
type struct_named_group_8 = named_group_8
type compile_data { next: *mut compile_data = null }
type struct_compile_data = compile_data
type class_ranges { header: compile_data, char_lists_size: c_ulong = 0, char_lists_start: c_ulong = 0, range_list_size: c_ushort = 0, char_lists_types: c_ushort = 0 }
type struct_class_ranges = class_ranges
type recurse_arguments { header: compile_data, size: c_ulong = 0, skip_size: c_ulong = 0 }
type struct_recurse_arguments = recurse_arguments
// union
type class_bits_storage { classbits: [32]u8 = [0 as u8; 32], classwords: [8]c_uint = [0 as c_uint; 8] }
type struct_class_bits_storage = class_bits_storage
type compile_block_8 { cx: *mut pcre2_real_compile_context_8 = null, lcc: *const u8 = null, fcc: *const u8 = null, cbits: *const u8 = null, ctypes: *const u8 = null, start_workspace: *mut u8 = null, start_code: *mut u8 = null, start_pattern: *const u8 = null, end_pattern: *const u8 = null, name_table: *mut u8 = null, workspace_size: c_ulong = 0, small_ref_offset: [10]c_ulong = [0 as c_ulong; 10], erroroffset: c_ulong = 0, classbits: class_bits_storage, names_found: c_ushort = 0, name_entry_size: c_ushort = 0, parens_depth: c_ushort = 0, assert_depth: c_ushort = 0, named_groups: *mut named_group_8 = null, named_group_list_size: c_uint = 0, external_options: c_uint = 0, external_flags: c_uint = 0, bracount: c_uint = 0, lastcapture: c_uint = 0, parsed_pattern: *mut c_uint = null, parsed_pattern_end: *mut c_uint = null, groupinfo: *mut c_uint = null, top_backref: c_uint = 0, backref_map: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], class_op_used: [15]u8 = [0 as u8; 15], req_varyopt: c_uint = 0, max_varlookbehind: c_uint = 0, max_lookbehind: c_int = 0, had_accept: c_int = 0, had_pruneorskip: c_int = 0, had_recurse: c_int = 0, dupnames: c_int = 0, first_data: *mut compile_data = null, last_data: *mut compile_data = null }
type struct_compile_block_8 = compile_block_8
type pcre2_real_jit_stack_8 { memctl: pcre2_memctl, stack: *mut c_void = null }
type struct_pcre2_real_jit_stack_8 = pcre2_real_jit_stack_8
type dfa_recursion_info { prevrec: *mut dfa_recursion_info = null, subject_position: *const u8 = null, last_used_ptr: *const u8 = null, group_num: c_uint = 0 }
type struct_dfa_recursion_info = dfa_recursion_info
// /Users/eric/with/.reference/pcre2/src/pcre2_intmodedep.h:696:8: demoted to opaque
type heapframe = opaque
type struct_heapframe = heapframe
type static_assertion_heapframe_size = [1]c_int
// /Users/eric/with/.reference/pcre2/src/pcre2_intmodedep.h:1024:16: demoted to opaque
type heapframe_align = opaque
type struct_heapframe_align = heapframe_align
type match_block_8 { memctl: pcre2_memctl, heap_limit: c_uint = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, hitend: c_int = 0, hasthen: c_int = 0, hasbsk: c_int = 0, allowemptypartial: c_int = 0, allowlookaroundbsk: c_int = 0, lcc: *const u8 = null, fcc: *const u8 = null, ctypes: *const u8 = null, start_offset: c_ulong = 0, end_offset_top: c_ulong = 0, partial: c_ushort = 0, bsr_convention: c_ushort = 0, name_count: c_ushort = 0, name_entry_size: c_ushort = 0, name_table: *const u8 = null, start_code: *const u8 = null, start_subject: *const u8 = null, check_subject: *const u8 = null, end_subject: *const u8 = null, true_end_subject: *const u8 = null, end_match_ptr: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, mark: *const u8 = null, nomatch_mark: *const u8 = null, verb_ecode_ptr: *const u8 = null, verb_skip_ptr: *const u8 = null, verb_current_recurse: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, skip_arg_count: c_uint = 0, ignore_skip_arg: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null }
type struct_match_block_8 = match_block_8
type dfa_match_block_8 { memctl: pcre2_memctl, start_code: *const u8 = null, start_subject: *const u8 = null, end_subject: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, tables: *const u8 = null, start_offset: c_ulong = 0, heap_limit: c_uint = 0, heap_used: c_ulong = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, allowemptypartial: c_int = 0, nl: [4]u8 = [0 as u8; 4], bsr_convention: c_ushort = 0, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, recursive: *mut dfa_recursion_info = null }
type struct_dfa_match_block_8 = dfa_match_block_8
extern fn _pcre2_auto_possessify_8(p0: *mut u8, p1: *const compile_block_8) -> c_int
fn _pcre2_check_escape_8(ptrptr: *mut *const u8, ptrend: *const u8, chptr: *mut c_uint, errorcodeptr: *mut c_int, options: c_uint, xoptions: c_uint, bracount: c_uint, isclass: c_int, cb: *mut compile_block_8) -> c_int:
    var utf: c_int = 0
    var alt_bsux: c_int = 0
    var ptr: *const u8 = null
    var c: c_uint = 0
    var cc: c_uint = 0
    var escape: c_int = 0
    var i: c_int = 0
    var p: *const u8 = null
    var s: c_int = 0
    var oldptr: *const u8 = null
    var overflow: c_int = 0
    var xc: c_uint = 0
    var hptr: *const u8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                utf = (if ((options & 524288)) != 0: 1 else: 0)
                alt_bsux = (if ((((options & 2)) | ((xoptions & 32)))) != 0: 1 else: 0)
                ptr = (unsafe: *ptrptr)
                escape = 0
                if (if ptr >= ptrend: 1 else: 0) != 0:
                    ((unsafe: *errorcodeptr) = ERR1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *errorcodeptr) = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 2
                continue
            2 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *chptr) = c)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return escape
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 3
                continue
            3 =>  // ESCAPE_FAILED_FORWARD
                (__goto_pending = 0)
                (ptr = ptr + 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 2
                continue
            _ => break

extern fn _pcre2_ckd_smul_8(p0: *mut c_ulong, p1: c_int, p2: c_int) -> c_int
extern fn _pcre2_extuni_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: *const u8, p4: c_int, p5: *mut c_int) -> *const u8
extern fn _pcre2_find_bracket_8(p0: *const u8, p1: c_int, p2: c_int) -> *const u8
extern fn _pcre2_is_newline_8(p0: *const u8, p1: c_uint, p2: *const u8, p3: *mut c_uint, p4: c_int) -> c_int
extern fn _pcre2_jit_free_rodata_8(p0: *mut c_void, p1: *mut c_void) -> void
extern fn _pcre2_jit_free_8(p0: *mut c_void, p1: *mut pcre2_memctl) -> void
extern fn _pcre2_jit_get_size_8(p0: *mut c_void) -> c_ulong
extern fn _pcre2_jit_get_target_8() -> *const i8
extern fn _pcre2_memctl_malloc_8(p0: c_ulong, p1: *mut pcre2_memctl) -> *mut c_void
extern fn _pcre2_ord2utf_8(p0: c_uint, p1: *mut u8) -> c_uint
extern fn _pcre2_script_run_8(p0: *const u8, p1: *const u8, p2: c_int) -> c_int
extern fn _pcre2_strcmp_8(p0: *const u8, p1: *const u8) -> c_int
extern fn _pcre2_strcmp_c8_8(p0: *const u8, p1: *const i8) -> c_int
extern fn _pcre2_strcpy_c8_8(p0: *mut u8, p1: *const i8) -> c_ulong
extern fn _pcre2_strlen_8(p0: *const u8) -> c_ulong
extern fn _pcre2_strncmp_8(p0: *const u8, p1: *const u8, p2: c_ulong) -> c_int
extern fn _pcre2_strncmp_c8_8(p0: *const u8, p1: *const i8, p2: c_ulong) -> c_int
extern fn _pcre2_study_8(p0: *mut pcre2_real_code_8) -> c_int
extern fn _pcre2_valid_utf_8(p0: *const u8, p1: c_ulong, p2: *mut c_ulong) -> c_int
extern fn _pcre2_was_newline_8(p0: *const u8, p1: c_uint, p2: *const u8, p3: *mut c_uint, p4: c_int) -> c_int
extern fn _pcre2_xclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: c_int) -> c_int
extern fn _pcre2_eclass_8(p0: c_uint, p1: *const u8, p2: *const u8, p3: *const u8, p4: c_int) -> c_int
type eclass_op_info { code_start: *mut u8 = null, length: c_ulong = 0, op_single_type: u8 = 0, bits: class_bits_storage }
type struct_eclass_op_info = eclass_op_info
var _pcre2_posix_class_maps8: *c_int = [160, 64, -2, 128, -1, 0, 96, -1, 0, 160, -1, 2, 224, 288, 0, 0, -1, 1, 288, -1, 0, 64, -1, 0, 192, -1, 0, 224, -1, 0, 256, -1, 0, 0, -1, 0, 160, -1, 0, 32, -1, 0]
extern fn _pcre2_update_classbits_8(ptype: c_uint, pdata: c_uint, negated: c_int, classbits: *mut u8) -> void
extern fn _pcre2_compile_class_not_nested_8(options: c_uint, xoptions: c_uint, start_ptr: *mut c_uint, pcode: *mut *mut u8, negate_class: c_int, has_bitmap: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint
extern fn _pcre2_compile_class_nested_8(options: c_uint, xoptions: c_uint, pptr: *mut *mut c_uint, pcode: *mut *mut u8, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int
extern fn _pcre2_compile_get_hash_from_name8(name: *const u8, length: c_uint) -> c_ushort
extern fn _pcre2_compile_find_named_group8(name: *const u8, length: c_uint, cb: *mut compile_block_8) -> *mut named_group_8
extern fn _pcre2_compile_add_name_to_table8(cb: *mut compile_block_8, ng: *mut named_group_8, tablecount: c_uint) -> c_uint
extern fn _pcre2_compile_find_dupname_details8(name: *const u8, length: c_uint, indexptr: *mut c_int, countptr: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int
extern fn _pcre2_compile_parse_scan_substr_args8(pptr: *mut c_uint, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint
extern fn _pcre2_compile_parse_recurse_args8(pptr_start: *mut c_uint, offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int
fn compile_regex(options: c_uint, xoptions: c_uint, codeptr: *mut *mut u8, pptrptr: *mut *mut c_uint, errorcodeptr: *mut c_int, skipunits: c_uint, firstcuptr: *mut c_uint, firstcuflagsptr: *mut c_uint, reqcuptr: *mut c_uint, reqcuflagsptr: *mut c_uint, bcptr: *mut branch_chain_8, __param_open_caps: *mut open_capitem, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int:
    var open_caps = __param_open_caps
    var code: *mut u8 = (unsafe: *codeptr)
    var last_branch: *mut u8 = code
    var start_bracket: *mut u8 = code
    var lookbehind: c_int
    var capitem: open_capitem
    var capnumber: c_int = 0
    var okreturn: c_int = 1
    var pptr: *mut c_uint = (unsafe: *pptrptr)
    var firstcu: c_uint
    var reqcu: c_uint
    var lookbehindlength: c_uint
    var lookbehindminlength: c_uint
    var firstcuflags: c_uint
    var reqcuflags: c_uint
    var length: c_ulong
    var bc: branch_chain_8
    if (if (if cb.cx.stack_guard != (null as *const fn(c_uint, *mut c_void) -> c_int): 1 else: 0) != 0 and cb.cx.stack_guard(cb.parens_depth, cb.cx.stack_guard_data) != 0: 1 else: 0) != 0:
        ((unsafe: *errorcodeptr) = ERR33)
        (cb.erroroffset = 0)
        return 0

    (bc.outer = bcptr)
    (bc.current_branch = code)
    (reqcu = 0)
    (firstcu = reqcu)
    (reqcuflags = (4294967295 as c_uint))
    (firstcuflags = reqcuflags)
    (length = (6 +% skipunits))
    (lookbehind = (if (if (if (unsafe: *code) == OP_ASSERTBACK: 1 else: 0) != 0 or (if (unsafe: *code) == OP_ASSERTBACK_NOT: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *code) == OP_ASSERTBACK_NA: 1 else: 0) != 0: 1 else: 0))
    if lookbehind != 0:
        (lookbehindminlength = (unsafe: *pptr))
        pptr = pptr + 2
    else:
        (lookbehindminlength = 0)
        (lookbehindlength = lookbehindminlength)

    if (if (unsafe: *code) == OP_CBRA: 1 else: 0) != 0:
        (capitem.number = capnumber)
        (capitem.next = open_caps)
        (capitem.assert_depth = cb.assert_depth)
        (open_caps = (&mut capitem as *mut open_capitem))

    code = code + (3 +% skipunits)
    while true:
        var branch_return: c_int
        var branchfirstcu: c_uint = 0
        var branchreqcu: c_uint = 0
        var branchfirstcuflags: c_uint = 4294967295
        var branchreqcuflags: c_uint = 4294967295
        if (if lookbehind != 0 and (if lookbehindlength > 0: 1 else: 0) != 0: 1 else: 0) != 0:
            if (if (if lookbehindminlength == 65535: 1 else: 0) != 0 or (if lookbehindminlength == lookbehindlength: 1 else: 0) != 0: 1 else: 0) != 0:
                (unsafe: *code = 126)
                (code = code + 1)
                length = length + 3
            else:
                (unsafe: *code = 127)
                (code = code + 1)
                length = length + 5
            
        
        if (if ((branch_return = compile_branch((&mut options as *mut c_uint), (&mut xoptions as *mut c_uint), (&mut code as *mut *mut u8), (&mut pptr as *mut *mut c_uint), errorcodeptr, (&mut branchfirstcu as *mut c_uint), (&mut branchfirstcuflags as *mut c_uint), (&mut branchreqcu as *mut c_uint), (&mut branchreqcuflags as *mut c_uint), (&mut bc as *mut branch_chain_8), open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length as *mut c_ulong))))) == 0: 1 else: 0) != 0:
            return 0
        
        if (if branch_return < 0: 1 else: 0) != 0:
            (okreturn = -1)
        
        if (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0:
            if (if (unsafe: *last_branch) != OP_ALT: 1 else: 0) != 0:
                (firstcu = branchfirstcu)
                (firstcuflags = branchfirstcuflags)
                (reqcu = branchreqcu)
                (reqcuflags = branchreqcuflags)
            else:
                if (if (if firstcuflags != branchfirstcuflags: 1 else: 0) != 0 or (if firstcu != branchfirstcu: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if firstcuflags < 4294967294: 1 else: 0) != 0:
                        if (if reqcuflags >= 4294967294: 1 else: 0) != 0:
                            (reqcu = firstcu)
                            (reqcuflags = firstcuflags)
                        
                    
                    (firstcuflags = (4294967294 as c_uint))
                
                if (if (if (if firstcuflags >= 4294967294: 1 else: 0) != 0 and (if branchfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if branchreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                    (branchreqcu = branchfirstcu)
                    (branchreqcuflags = branchfirstcuflags)
                
                if (if ((if ((reqcuflags & (0 - 2 - 1))) != ((branchreqcuflags & (0 - 2 - 1))): 1 else: 0)) != 0 or (if reqcu != branchreqcu: 1 else: 0) != 0: 1 else: 0) != 0:
                    (reqcuflags = (4294967294 as c_uint))
                else:
                    (reqcu = branchreqcu)
                    reqcuflags = reqcuflags | branchreqcuflags
                
            
        
        if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
            (code = ((((unsafe: *codeptr) + (1 as isize as usize)) + (2 as isize as usize)) + skipunits))
            length = length + 3
        else:
            ((unsafe: *code) = 121)
            (last_branch = code)
            (bc.current_branch = last_branch)
            code = code + (1 + 2)
        
        (pptr = pptr + 1)

    return 0

fn get_branchlength(pptrptr: *mut *mut c_uint, minptr: *mut c_int, errcodeptr: *mut c_int, lcptr: *mut c_int, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8) -> c_int:
    var branchlength: c_int = 0
    var branchminlength: c_int = 0
    var grouplength: c_int = 0
    var groupminlength: c_int = 0
    var lastitemlength: c_uint = 0
    var lastitemminlength: c_uint = 0
    var pptr: *mut c_uint = null
    var offset: c_ulong = 0
    var this_recurse: parsed_recurse_check
    var r: *mut parsed_recurse_check = null
    var gptr: *mut c_uint = null
    var gptrend: *mut c_uint = null
    var escape: c_uint = 0
    var min: c_uint = 0
    var max: c_uint = 0
    var group: c_uint = 0
    var itemlength: c_uint = 0
    var itemminlength: c_uint = 0
    var name: *const u8 = null
    var is_dupname: c_int = 0
    var ng: *mut named_group_8 = null
    var meta_code: c_uint = 0
    var length: c_uint = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                branchlength = 0
                branchminlength = 0
                lastitemlength = 0
                lastitemminlength = 0
                pptr = (unsafe: *pptrptr)
                if (if (((unsafe: *lcptr)) = ((unsafe: *lcptr)) + 1) > 2000: 1 else: 0) != 0:
                    ((unsafe: *errcodeptr) = ERR35)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return -1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (pptr = pptr + 1) != null:
                    group = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    itemlength = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    itemminlength = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (unsafe: *pptr) < 2147483648: 1 else: 0) != 0:
                        (itemminlength = 1)
                        (itemlength = itemminlength)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if (2147483647 - branchlength) < (itemlength as c_int): 1 else: 0) != 0 or (if (branchlength = branchlength + itemlength) > ((65535 as c_int)): 1 else: 0) != 0: 1 else: 0) != 0:
                        ((unsafe: *errcodeptr) = ERR87)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        return -1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    branchminlength = branchminlength + itemminlength
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (lastitemlength = itemlength)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (lastitemminlength = itemminlength)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 5
                continue
            5 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *pptrptr) = pptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *minptr) = branchminlength)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return branchlength
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 6
                continue
            6 =>  // PARSED_SKIP_FAILED
                (__goto_pending = 0)
                ((unsafe: *errcodeptr) = ERR90)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return -1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn set_lookbehind_lengths(pptrptr: *mut *mut c_uint, errcodeptr: *mut c_int, lcptr: *mut c_int, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8) -> c_int:
    var offset: c_ulong
    var bptr: *mut c_uint = (unsafe: *pptrptr)
    var gbptr: *mut c_uint = bptr
    var maxlength: c_int = 0
    var minlength: c_int = 2147483647
    var variable: c_int = 0
    0
    (unsafe: *pptrptr) = (unsafe: *pptrptr) + 2
    if variable != 0:
        (gbptr[1] = minlength)
    else:
        (gbptr[1] = 65535)

    return 1

fn check_lookbehinds(__param_pptr: *mut c_uint, retptr: *mut *mut c_uint, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8, lcptr: *mut c_int) -> c_int:
    var pptr = __param_pptr
    var errorcode: c_int = 0
    var nestlevel: c_int = 0
    while (if (unsafe: *pptr) != 2147483648: 1 else: 0) != 0:
        if (if (unsafe: *pptr) < 2147483648: 1 else: 0) != 0:
            continue
        
        (pptr = pptr + 1)

    return 0

var meta_extra_lengths: [73]u8 = [0, 0, 0, 0, 3, 1, 3, 5, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 3, 3, 3, 3, 2, 0, 1, 1, 0, 0, 0, 0, 0, 2, 1, 1, 0, 0, 2, 3, 0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0]
let PSKIP_ALT: c_uint = 0
let PSKIP_CLASS: c_uint = 1
let PSKIP_KET: c_uint = 2
var xdigitab: [256]u8 = [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255, 255, 255, 255, 255, 255, 255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255]
var escapes: [75]c_short = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 59, 60, 61, 62, 63, 64, -1, -4, -14, -6, -25, 0, -2, -18, 0, 0, -3, 0, 0, -12, 0, -15, -26, -17, -8, 0, 0, -20, -10, -22, 0, -23, 91, 92, 93, 94, 95, 96, 7, -5, 0, -7, 27, 12, 0, -19, 0, 0, -28, 0, 0, 10, 0, -16, 0, 13, -9, 9, 0, -21, -11, 0, 0, -24]
type verbitem { len: c_uint = 0, meta: c_uint = 0, has_arg: c_int = 0 }
type struct_verbitem = verbitem
var verbnames: [43]c_char








var verbs: [9]verbitem = [verbitem { len: 0, meta: 2150432768, has_arg: 1 }, verbitem { len: 4, meta: 2150432768, has_arg: 1 }, verbitem { len: 6, meta: 2150498304, has_arg: -1 }, verbitem { len: 1, meta: 2150563840, has_arg: -1 }, verbitem { len: 4, meta: 2150563840, has_arg: -1 }, verbitem { len: 6, meta: 2150629376, has_arg: 0 }, verbitem { len: 5, meta: 2150760448, has_arg: 0 }, verbitem { len: 4, meta: 2150891520, has_arg: 0 }, verbitem { len: 4, meta: 2151022592, has_arg: 0 }]
let verbcount: c_int = 9
var verbops: [11]c_uint = [156, 166, 165, 163, 164, 157, 158, 159, 160, 161, 162]
type alasitem { len: c_uint = 0, meta: c_uint = 0 }
type struct_alasitem = alasitem
var alasnames: [229]c_char


















var alasmeta: [19]alasitem = [alasitem { len: 3, meta: 2150039552 }, alasitem { len: 3, meta: 2150170624 }, alasitem { len: 5, meta: 2150301696 }, alasitem { len: 5, meta: 2150367232 }, alasitem { len: 3, meta: 2150105088 }, alasitem { len: 3, meta: 2150236160 }, alasitem { len: 18, meta: 2150039552 }, alasitem { len: 19, meta: 2150170624 }, alasitem { len: 29, meta: 2150301696 }, alasitem { len: 30, meta: 2150367232 }, alasitem { len: 18, meta: 2150105088 }, alasitem { len: 19, meta: 2150236160 }, alasitem { len: 3, meta: 2148990976 }, alasitem { len: 14, meta: 2148990976 }, alasitem { len: 6, meta: 2147614720 }, alasitem { len: 2, meta: 2149974016 }, alasitem { len: 3, meta: 2415853568 }, alasitem { len: 10, meta: 2149974016 }, alasitem { len: 17, meta: 2415853568 }]
let alascount: c_int = 19
var chartypeoffset: [4]c_uint = [0, 13, 26, 39]
var posix_names: [84]c_char



var posix_name_lengths: [15]u8 = [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 6, 0]
let PSO_OPT: c_uint = 0
let PSO_XOPT: c_uint = 1
let PSO_FLG: c_uint = 2
let PSO_NL: c_uint = 3
let PSO_BSR: c_uint = 4
let PSO_LIMH: c_uint = 5
let PSO_LIMM: c_uint = 6
let PSO_LIMD: c_uint = 7
let PSO_OPTMZ: c_uint = 8
type pso { name: *const i8 = null, length: c_ushort = 0, type_: c_ushort = 0, value: c_uint = 0 }
type struct_pso = pso
var pso_list: [23]pso
var opcode_possessify: [120]u8 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 0, 43, 0, 44, 0, 45, 0, 0, 0, 0, 0, 0, 55, 0, 56, 0, 57, 0, 58, 0, 0, 0, 0, 0, 0, 68, 0, 69, 0, 70, 0, 71, 0, 0, 0, 0, 0, 0, 81, 0, 82, 0, 83, 0, 84, 0, 0, 0, 0, 0, 0, 94, 0, 95, 0, 96, 0, 97, 0, 0, 0, 0, 0, 0, 106, 0, 107, 0, 108, 0, 109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
type static_assertion_opcode_possessify = [1]c_int
fn read_number(ptrptr: *mut *const u8, ptrend: *const u8, allow_sign: c_int, __param_max_value: c_uint, max_error: c_uint, intptr: *mut c_int, errorcodeptr: *mut c_int) -> c_int:
    var max_value = __param_max_value
    var sign: c_int = 0
    var n: c_uint = 0
    var ptr: *const u8 = null
    var yield_: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                sign = 0
                n = 0
                ptr = (unsafe: *ptrptr)
                yield_ = 0
                ((unsafe: *errorcodeptr) = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if allow_sign >= 0: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if (unsafe: *ptr) == 43: 1 else: 0) != 0:
                        (sign = 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        max_value = max_value - allow_sign
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (ptr = ptr + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    else:
                        if (if (unsafe: *ptr) == 45: 1 else: 0) != 0:
                            (sign = -1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (ptr = ptr + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if allow_sign >= 0: 1 else: 0) != 0 and (if sign != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if n == 0: 1 else: 0) != 0:
                        ((unsafe: *errorcodeptr) = ERR26)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 1
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if sign > 0: 1 else: 0) != 0:
                        n = n + allow_sign
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (yield_ = 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *intptr) = n)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *ptrptr) = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return yield_
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn read_repeat_counts(ptrptr: *mut *const u8, ptrend: *const u8, minp: *mut c_uint, maxp: *mut c_uint, errorcodeptr: *mut c_int) -> c_int:
    var p: *const u8 = null
    var pp: *const u8 = null
    var yield_: c_int = 0
    var had_minimum: c_int = 0
    var min: c_int = 0
    var max: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                p = (unsafe: *ptrptr)
                yield_ = 0
                had_minimum = 0
                min = 0
                max = 65536
                ((unsafe: *errorcodeptr) = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p) == 32: 1 else: 0) != 0 or (if (unsafe: *p) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (p = p + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (pp = p)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *pp) == 32: 1 else: 0) != 0 or (if (unsafe: *pp) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (pp = pp + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if pp >= ptrend: 1 else: 0) != 0:
                    return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (unsafe: *pp) == 125: 1 else: 0) != 0:
                    if (if had_minimum != 0: 0 else: 1) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    if (if (unsafe: *(pp = pp + 1)) != 44: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *pp) == 32: 1 else: 0) != 0 or (if (unsafe: *pp) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (pp = pp + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if pp >= ptrend: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *pp) == 32: 1 else: 0) != 0 or (if (unsafe: *pp) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (pp = pp + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (if pp >= ptrend: 1 else: 0) != 0 or (if (unsafe: *pp) != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if read_number((&mut p as *mut *const u8), ptrend, -1, 65535, 105, (&mut min as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                    if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                        __pc = 1
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (p = p + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p) == 32: 1 else: 0) != 0 or (if (unsafe: *p) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (p = p + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if read_number((&mut p as *mut *const u8), ptrend, -1, 65535, 105, (&mut max as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                        if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                            __pc = 1
                            __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p) == 32: 1 else: 0) != 0 or (if (unsafe: *p) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (p = p + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (unsafe: *p) == 125: 1 else: 0) != 0:
                        (max = min)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    else:
                        (p = p + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p) == 32: 1 else: 0) != 0 or (if (unsafe: *p) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                            (p = p + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if read_number((&mut p as *mut *const u8), ptrend, -1, 65535, 105, (&mut max as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                            if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                                __pc = 1
                                __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if max < min: 1 else: 0) != 0:
                            ((unsafe: *errorcodeptr) = ERR4)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            __pc = 1
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p) == 32: 1 else: 0) != 0 or (if (unsafe: *p) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (p = p + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (p = p + 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (yield_ = 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = p)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return yield_
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn check_posix_syntax(__param_ptr: *const u8, ptrend: *const u8, endptr: *mut *const u8) -> c_int:
    var ptr = __param_ptr
    var terminator: u8
    (terminator = (unsafe: *(ptr = ptr + 1)))
    while (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 2: 1 else: 0) != 0:
        if (if (if (unsafe: *ptr) == 92: 1 else: 0) != 0 and ((if (if ptr[1] == 93: 1 else: 0) != 0 or (if ptr[1] == 92: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
            (ptr = ptr + 1)
        else:
            if (if ((if (if (unsafe: *ptr) == 91: 1 else: 0) != 0 and (if ptr[1] == terminator: 1 else: 0) != 0: 1 else: 0)) != 0 or (if (unsafe: *ptr) == 93: 1 else: 0) != 0: 1 else: 0) != 0:
                return 0
            else:
                if (if (if (unsafe: *ptr) == terminator: 1 else: 0) != 0 and (if ptr[1] == 93: 1 else: 0) != 0: 1 else: 0) != 0:
                    ((unsafe: *endptr) = ptr)
                    return 1
        
        (ptr = ptr + 1)

    return 0

fn check_posix_name(ptr: *const u8, len: c_int) -> c_int:
    var pn: *const i8 = (&posix_names[0] as *mut c_char)
    var yield_: c_int = 0
    while (if (&posix_name_lengths[0] as *mut u8)[yield_] != 0: 1 else: 0) != 0:
        if (if (if len == (&posix_name_lengths[0] as *mut u8)[yield_]: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, pn, (len as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
            return yield_
        
        pn = pn + ((&posix_name_lengths[0] as *mut u8)[yield_] + 1)
        (yield_ = yield_ + 1)

    return -1

fn read_name(ptrptr: *mut *const u8, ptrend: *const u8, utf: c_int, terminator: c_uint, offsetptr: *mut c_ulong, nameptr: *mut *const u8, namelenptr: *mut c_uint, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int:
    var ptr: *const u8 = null
    var is_group: c_int = 0
    var is_braced: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                ptr = (unsafe: *ptrptr)
                is_group = ((if (unsafe: *(ptr = ptr + 1)) != 42: 1 else: 0))
                is_braced = (if terminator == 125: 1 else: 0)
                if is_braced != 0:
                    while (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *ptr) == 32: 1 else: 0) != 0 or (if (unsafe: *ptr) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (ptr = ptr + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ptr >= ptrend: 1 else: 0) != 0:
                    ((unsafe: *errorcodeptr) = (if is_group != 0: ERR62 else: ERR60))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 1
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *nameptr) = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                utf
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if (if ptr < ptrend: 1 else: 0) != 0 and 1 != 0: 1 else: 0) != 0 and (if ((cb.ctypes[(unsafe: *ptr)] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (ptr = ptr + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((ptr as usize -% (unsafe: *nameptr) as usize) / sizeof[u8]()) > 128: 1 else: 0) != 0:
                    ((unsafe: *errorcodeptr) = ERR48)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 1
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if is_group != 0:
                    if (if ptr == (unsafe: *nameptr): 1 else: 0) != 0:
                        ((unsafe: *errorcodeptr) = ERR62)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 1
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if is_braced != 0:
                        while (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *ptr) == 32: 1 else: 0) != 0 or (if (unsafe: *ptr) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                            (ptr = ptr + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if terminator != 0: 1 else: 0) != 0:
                        (ptr = ptr + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *ptrptr) = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // FAILED
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn parse_capture_list(ptrptr: *mut *const u8, ptrend: *const u8, utf: c_int, __param_parsed_pattern: *mut c_uint, __param_offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> *mut c_uint:
    var parsed_pattern = __param_parsed_pattern
    var offset = __param_offset
    var next_offset: c_ulong = 0
    var ptr: *const u8 = null
    var name: *const u8 = null
    var terminator: u8 = 0
    var meta: c_uint = 0
    var namelen: c_uint = 0
    var i: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                ptr = (unsafe: *ptrptr)
                if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 40: 1 else: 0) != 0: 1 else: 0) != 0:
                    ((unsafe: *errorcodeptr) = ERR118)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while true:
                    (ptr = ptr + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if ptr >= ptrend: 1 else: 0) != 0:
                        ((unsafe: *errorcodeptr) = ERR117)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        __pc = 2
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if read_number((&mut ptr as *mut *const u8), ptrend, cb.bracount, 65535, 161, (&mut i as *mut c_int), errorcodeptr) != 0:
                        if (if i <= 0: 1 else: 0) != 0:
                            ((unsafe: *errorcodeptr) = ERR15)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            __pc = 2
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (meta = (2149122048 as c_uint))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    else:
                        if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                            __pc = 2
                            __goto_pending = 1
                        else:
                            if (if (unsafe: *ptr) == 60: 1 else: 0) != 0:
                                (terminator = 62)
                            else:
                                if (if (unsafe: *ptr) == 39: 1 else: 0) != 0:
                                    (terminator = 39)
                                else:
                                    ((unsafe: *errorcodeptr) = ERR117)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 2
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, terminator, (&mut next_offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), errorcodeptr, cb) != 0: 0 else: 1) != 0:
                                __pc = 2
                                __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (meta = (2149056512 as c_uint))
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if offset == 0: 1 else: 0) != 0 or (if ((next_offset -% offset)) >= 65536: 1 else: 0) != 0: 1 else: 0) != 0:
                        (unsafe: *parsed_pattern = 2148925440)
                        (parsed_pattern = parsed_pattern + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        0
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (offset = next_offset)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (unsafe: *parsed_pattern = namelen)
                    (parsed_pattern = parsed_pattern + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (offset = next_offset)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if ptr >= ptrend: 1 else: 0) != 0:
                        __pc = 1
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (unsafe: *ptr) == 41: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (unsafe: *ptr) != 44: 1 else: 0) != 0:
                        ((unsafe: *errorcodeptr) = ERR24)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        __pc = 2
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *ptrptr) = (ptr + (1 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return parsed_pattern
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // UNCLOSED_PARENTHESIS
                (__goto_pending = 0)
                ((unsafe: *errorcodeptr) = ERR14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 2
                continue
            2 =>  // FAILED
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return (null as *mut c_uint)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn manage_callouts(ptr: *const u8, pcalloutptr: *mut *mut c_uint, auto_callout: c_int, __param_parsed_pattern: *mut c_uint, cb: *mut compile_block_8) -> *mut c_uint:
    var parsed_pattern = __param_parsed_pattern
    var previous_callout: *mut c_uint = (unsafe: *pcalloutptr)
    if (if auto_callout != 0: 0 else: 1) != 0:
        (previous_callout = (null as *mut c_uint))
    else:
        if (if (if (if previous_callout == (null as *mut c_uint): 1 else: 0) != 0 or (if previous_callout != (parsed_pattern - (4 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 or (if previous_callout[3] != 255: 1 else: 0) != 0: 1 else: 0) != 0:
            (previous_callout = parsed_pattern)
            parsed_pattern = parsed_pattern + 4
            (previous_callout[0] = (2147876864 as c_uint))
            (previous_callout[2] = 0)
            (previous_callout[3] = 255)
        

    ((unsafe: *pcalloutptr) = previous_callout)
    return parsed_pattern

fn handle_escdsw(escape: c_int, __param_parsed_pattern: *mut c_uint, options: c_uint, xoptions: c_uint) -> *mut c_uint:
    var parsed_pattern = __param_parsed_pattern
    var ascii_option: c_uint = 0
    var prop: c_uint = 16
    match escape
        ESC_D =>
            (prop = 15)
            (ascii_option = 256)
        ESC_d =>
            (ascii_option = 256)
        ESC_S =>
            (prop = 15)
            (ascii_option = 512)
        ESC_s =>
            (ascii_option = 512)
        ESC_W =>
            (prop = 15)
            (ascii_option = 1024)
        ESC_w =>
            (ascii_option = 1024)
        _ => 0

    if (if (if ((options & 131072)) == 0: 1 else: 0) != 0 or (if ((xoptions & ascii_option)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
        (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% escape))
        (parsed_pattern = parsed_pattern + 1)
    else:
        (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% prop))
        (parsed_pattern = parsed_pattern + 1)
        match escape
            ESC_d => 0
            ESC_s => 0
            ESC_w => 0
            _ => 0
        

    return parsed_pattern

fn max_parsed_pattern(ptr: *const u8, ptrend: *const u8, utf: c_int, options: c_uint) -> c_long:
    var big32count: c_ulong = 0
    var parsed_size_needed: c_long
    utf
    (parsed_size_needed = ((((ptrend as usize -% ptr as usize) / sizeof[u8]())) +% big32count))
    if (if ((options & 4)) != 0: 1 else: 0) != 0:
        parsed_size_needed = parsed_size_needed + ((((ptrend as usize -% ptr as usize) / sizeof[u8]())) * 4)

    return parsed_size_needed

type nest_save { nest_depth: c_ushort = 0, reset_group: c_ushort = 0, max_group: c_ushort = 0, flags: c_ushort = 0, options: c_uint = 0, xoptions: c_uint = 0 }
type struct_nest_save = nest_save
let RANGE_NO: c_uint = 0
let RANGE_STARTED: c_uint = 1
let RANGE_FORBID_NO: c_uint = 2
let RANGE_FORBID_STARTED: c_uint = 3
let RANGE_OK_ESCAPED: c_uint = 4
let RANGE_OK_LITERAL: c_uint = 5
let CLASS_OP_EMPTY: c_uint = 0
let CLASS_OP_OPERAND: c_uint = 1
let CLASS_OP_OPERATOR: c_uint = 2
let CLASS_MODE_NORMAL: c_uint = 0
let CLASS_MODE_ALT_EXT: c_uint = 1
let CLASS_MODE_PERL_EXT: c_uint = 2
let CLASS_MODE_PERL_EXT_LEAF: c_uint = 3
fn parse_regex(__param_ptr: *const u8, __param_options: c_uint, __param_xoptions: c_uint, has_lookbehind: *mut c_int, cb: *mut compile_block_8) -> c_int:
    var ptr = __param_ptr
    var options = __param_options
    var xoptions = __param_xoptions
    var c: c_uint = 0
    var delimiter: c_uint = 0
    var namelen: c_uint = 0
    var class_range_state: c_uint = 0
    var class_op_state: c_uint = 0
    var class_mode_state: c_uint = 0
    var class_start: *mut c_uint = null
    var verblengthptr: *mut c_uint = null
    var verbstartptr: *mut c_uint = null
    var previous_callout: *mut c_uint = null
    var parsed_pattern: *mut c_uint = null
    var parsed_pattern_end: *mut c_uint = null
    var this_parsed_item: *mut c_uint = null
    var prev_parsed_item: *mut c_uint = null
    var meta_quantifier: c_uint = 0
    var add_after_mark: c_uint = 0
    var nest_depth: c_ushort = 0
    var class_depth_m1: c_short = 0
    var class_maxdepth_m1: c_short = 0
    var hash: c_ushort = 0
    var after_manual_callout: c_int = 0
    var expect_cond_assert: c_int = 0
    var errorcode: c_int = 0
    var escape: c_int = 0
    var i: c_int = 0
    var inescq: c_int = 0
    var inverbname: c_int = 0
    var utf: c_int = 0
    var auto_callout: c_int = 0
    var is_dupname: c_int = 0
    var negate_class: c_int = 0
    var okquantifier: c_int = 0
    var thisptr: *const u8 = null
    var name: *const u8 = null
    var ptrend: *const u8 = null
    var verbnamestart: *const u8 = null
    var class_range_forbid_ptr: *const u8 = null
    var ng: *mut named_group_8 = null
    var top_nest: *mut nest_save = null
    var end_nests: *mut nest_save = null
    var prev_expect_cond_assert: c_int = 0
    var min_repeat: c_uint = 0
    var max_repeat: c_uint = 0
    var set: c_uint = 0
    var unset: c_uint = 0
    var optset: *mut c_uint = null
    var xset: c_uint = 0
    var xunset: c_uint = 0
    var xoptset: *mut c_uint = null
    var terminator: c_uint = 0
    var prev_meta_quantifier: c_uint = 0
    var prev_okquantifier: c_int = 0
    var tempptr: *const u8 = null
    var offset: c_ulong = 0
    var verbnamelength: c_ulong = 0
    var ok: c_int = 0
    var p: *const u8 = null
    var char_is_literal: c_int = 0
    var posix_negate: c_int = 0
    var posix_class: c_int = 0
    var start_c: c_uint = 0
    var new_class_mode_state: c_uint = 0
    var vn: *const i8 = null
    var meta: c_uint = 0
    var hyphenok: c_int = 0
    var oldoptions: c_uint = 0
    var oldxoptions: c_uint = 0
    var calloutlength: c_ulong = 0
    var startptr: *const u8 = null
    var n: c_int = 0
    var ge: c_uint = 0
    var major: c_int = 0
    var minor: c_int = 0
    var was_r_ampersand: c_int = 0
    var newsize: c_uint = 0
    var newspace: *mut named_group_8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                verblengthptr = (null as *mut c_uint)
                verbstartptr = (null as *mut c_uint)
                previous_callout = (null as *mut c_uint)
                parsed_pattern = cb.parsed_pattern
                parsed_pattern_end = cb.parsed_pattern_end
                this_parsed_item = (null as *mut c_uint)
                prev_parsed_item = (null as *mut c_uint)
                meta_quantifier = 0
                add_after_mark = 0
                nest_depth = 0
                class_depth_m1 = -1
                class_maxdepth_m1 = -1
                after_manual_callout = 0
                expect_cond_assert = 0
                errorcode = 0
                inescq = 0
                inverbname = 0
                utf = (if ((options & 524288)) != 0: 1 else: 0)
                auto_callout = (if ((options & 4)) != 0: 1 else: 0)
                okquantifier = 0
                ptrend = cb.end_pattern
                verbnamestart = (null as *const u8)
                class_range_forbid_ptr = (null as *const u8)
                if (if ((xoptions & 8)) != 0: 1 else: 0) != 0:
                    (unsafe: *parsed_pattern = 2148073472)
                    (parsed_pattern = parsed_pattern + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (unsafe: *parsed_pattern = 2149449728)
                    (parsed_pattern = parsed_pattern + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    if (if ((xoptions & 4)) != 0: 1 else: 0) != 0:
                        (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% 5))
                        (parsed_pattern = parsed_pattern + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (unsafe: *parsed_pattern = 2149449728)
                        (parsed_pattern = parsed_pattern + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 33554432)) != 0: 1 else: 0) != 0:
                    while (if ptr < ptrend: 1 else: 0) != 0:
                        if (if parsed_pattern >= parsed_pattern_end: 1 else: 0) != 0:
                            (errorcode = ERR63)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            __pc = 19
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (thisptr = ptr)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        0
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if auto_callout != 0:
                            (parsed_pattern = manage_callouts(thisptr, (&mut previous_callout as *mut *mut c_uint), auto_callout, parsed_pattern, cb))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        0
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 17
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (top_nest = (null as *mut nest_save))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 16777216)) != 0: 1 else: 0) != 0:
                    options = options | 128
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if ptr < ptrend: 1 else: 0) != 0:
                    min_repeat = 0
                    max_repeat = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if nest_depth > cb.cx.parens_nest_limit: 1 else: 0) != 0:
                        (errorcode = ERR19)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        __pc = 19
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if parsed_pattern >= parsed_pattern_end: 1 else: 0) != 0:
                        (errorcode = ERR63)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        __pc = 19
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if this_parsed_item != parsed_pattern: 1 else: 0) != 0:
                        (prev_parsed_item = this_parsed_item)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (this_parsed_item = parsed_pattern)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (thisptr = ptr)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if inescq != 0:
                        if (if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                            (inescq = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (ptr = ptr + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        else:
                            if inverbname != 0:
                                (unsafe: *parsed_pattern = c)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (after_manual_callout = after_manual_callout - 1) <= 0: 1 else: 0) != 0:
                                    (parsed_pattern = manage_callouts(thisptr, (&mut previous_callout as *mut *mut c_uint), auto_callout, parsed_pattern, cb))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (meta_quantifier = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                        if (if (if (unsafe: *ptr) == 81: 1 else: 0) != 0 or (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (if (if expect_cond_assert > 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == 81: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0 and (if ptr[1] == 92: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[2] == 69: 1 else: 0) != 0: 1 else: 0)) != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                (ptr = ptr - 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (errorcode = ERR28)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (inescq = (if (unsafe: *ptr) == 81: 1 else: 0))
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (ptr = ptr + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            continue
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if ((options & 128)) != 0: 1 else: 0) != 0:
                        if (if (if c < 256: 1 else: 0) != 0 and (if ((cb.ctypes[c] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                            continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if c == 35: 1 else: 0) != 0:
                            while (if ptr < ptrend: 1 else: 0) != 0:
                                (ptr = ptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            continue
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if (if (if c == 40: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[0] == 63: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 35: 1 else: 0) != 0: 1 else: 0) != 0:
                        while (if (if (ptr = ptr + 1) < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                            0
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if ptr >= ptrend: 1 else: 0) != 0:
                            (errorcode = ERR18)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            __pc = 19
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (ptr = ptr + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if expect_cond_assert > 0: 1 else: 0) != 0:
                        ok = (if (if (if c == 40: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0: 1 else: 0) != 0 and ((if (if ptr[0] == 63: 1 else: 0) != 0 or (if ptr[0] == 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if ok != 0:
                            if (if ptr[0] == 42: 1 else: 0) != 0:
                                (ok = (if 1 != 0 and (if ((cb.ctypes[ptr[1]] & 4)) != 0: 1 else: 0) != 0: 1 else: 0))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                match ptr[1]
                                    67 =>
                                        (ok = (if expect_cond_assert == 2: 1 else: 0))
                                    61 =>
                                        (ok = (if (if ptr[2] == 61: 1 else: 0) != 0 or (if ptr[2] == 33: 1 else: 0) != 0: 1 else: 0))
                                    60 =>
                                        (ok = (if (if ptr[2] == 61: 1 else: 0) != 0 or (if ptr[2] == 33: 1 else: 0) != 0: 1 else: 0))
                                    _ =>
                                        (ok = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if ok != 0: 0 else: 1) != 0:
                            (errorcode = ERR28)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if expect_cond_assert == 2: 1 else: 0) != 0:
                                __pc = 19
                                __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            __pc = 20
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (prev_expect_cond_assert = expect_cond_assert)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (expect_cond_assert = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (prev_okquantifier = okquantifier)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (prev_meta_quantifier = meta_quantifier)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (okquantifier = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (meta_quantifier = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if prev_meta_quantifier != 0: 1 else: 0) != 0 and ((if (if c == 63: 1 else: 0) != 0 or (if c == 43: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (parsed_pattern[(if ((if prev_meta_quantifier == 2151743488: 1 else: 0)) != 0: -3 else: -1)] = (prev_meta_quantifier +% ((if ((if c == 63: 1 else: 0)) != 0: 131072 else: 65536))))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    match c
                        92 =>
                            (tempptr = ptr)
                            (escape = _pcre2_check_escape_8((&mut ptr as *mut *const u8), ptrend, (&mut c as *mut c_uint), (&mut errorcode as *mut c_int), options, xoptions, cb.bracount, 0, cb))
                            if (if errorcode != 0: 1 else: 0) != 0:
                                if (if ((xoptions & 2)) == 0: 1 else: 0) != 0:
                                    __pc = 19
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ptr = tempptr)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ptr >= ptrend: 1 else: 0) != 0:
                                    (c = 92)
                                else:
                                    0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (escape = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if escape == 0: 1 else: 0) != 0:
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if escape < 0: 1 else: 0) != 0:
                                    (escape = ((0 - escape) - 1))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (okquantifier = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    match escape
                                        ESC_C =>
                                            if (if ((options & 1048576)) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR83)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            (okquantifier = 1)
                                            (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% escape))
                                            (parsed_pattern = parsed_pattern + 1)
                                        ESC_ub =>
                                            (unsafe: *parsed_pattern = 117)
                                            (parsed_pattern = parsed_pattern + 1)
                                            0
                                        ESC_X =>
                                            (errorcode = ERR45)
                                            __pc = 1
                                            __goto_pending = 1
                                            (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% escape))
                                            (parsed_pattern = parsed_pattern + 1)
                                        ESC_H =>
                                            (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% escape))
                                            (parsed_pattern = parsed_pattern + 1)
                                        ESC_d =>
                                            (parsed_pattern = handle_escdsw(escape, parsed_pattern, options, xoptions))
                                        ESC_P =>
                                            __pc = 1
                                            __goto_pending = 1
                                        ESC_g =>
                                            (terminator = (if ((if (unsafe: *ptr) == 60: 1 else: 0)) != 0: 62 else: (if ((if (unsafe: *ptr) == 39: 1 else: 0)) != 0: 39 else: 125)))
                                            if (if (if escape == ESC_g: 1 else: 0) != 0 and (if terminator != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                                                p = (ptr + (1 as isize as usize))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if read_number((&mut p as *mut *const u8), ptrend, cb.bracount, 65535, 161, (&mut i as *mut c_int), (&mut errorcode as *mut c_int)) != 0:
                                                    if (if (if p >= ptrend: 1 else: 0) != 0 or (if (unsafe: *p) != terminator: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = p)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (errorcode = ERR119)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        __pc = 1
                                                        __goto_pending = 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = (p + (1 as isize as usize)))
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    __pc = 7
                                                    __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if errorcode != 0: 1 else: 0) != 0:
                                                    __pc = 1
                                                    __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, terminator, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                __pc = 1
                                                __goto_pending = 1
                                            (unsafe: *parsed_pattern = (if ((if (if escape == ESC_k: 1 else: 0) != 0 or (if terminator == 125: 1 else: 0) != 0: 1 else: 0)) != 0: 2147745792 else: 2149908480))
                                            (parsed_pattern = parsed_pattern + 1)
                                            (unsafe: *parsed_pattern = namelen)
                                            (parsed_pattern = parsed_pattern + 1)
                                            0
                                            (okquantifier = 1)
                                        _ =>
                                            (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% escape))
                                            (parsed_pattern = parsed_pattern + 1)
                        94 =>
                            (unsafe: *parsed_pattern = 2148073472)
                            (parsed_pattern = parsed_pattern + 1)
                        36 =>
                            (unsafe: *parsed_pattern = 2149187584)
                            (parsed_pattern = parsed_pattern + 1)
                        46 =>
                            (unsafe: *parsed_pattern = 2149253120)
                            (parsed_pattern = parsed_pattern + 1)
                            (okquantifier = 1)
                        42 =>
                            (meta_quantifier = (2151153664 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            (meta_quantifier = (2151350272 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            (meta_quantifier = (2151546880 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend, (&mut min_repeat as *mut c_uint), (&mut max_repeat as *mut c_uint), (&mut errorcode as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    __pc = 19
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (meta_quantifier = (2151743488 as c_uint))
                            if (if prev_okquantifier != 0: 0 else: 1) != 0:
                                (errorcode = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item) == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern = parsed_pattern + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern = meta_quantifier)
                            (parsed_pattern = parsed_pattern + 1)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern = min_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern = max_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        43 =>
                            (meta_quantifier = (2151350272 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            (meta_quantifier = (2151546880 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend, (&mut min_repeat as *mut c_uint), (&mut max_repeat as *mut c_uint), (&mut errorcode as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    __pc = 19
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (meta_quantifier = (2151743488 as c_uint))
                            if (if prev_okquantifier != 0: 0 else: 1) != 0:
                                (errorcode = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item) == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern = parsed_pattern + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern = meta_quantifier)
                            (parsed_pattern = parsed_pattern + 1)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern = min_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern = max_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        63 =>
                            (meta_quantifier = (2151546880 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend, (&mut min_repeat as *mut c_uint), (&mut max_repeat as *mut c_uint), (&mut errorcode as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    __pc = 19
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (meta_quantifier = (2151743488 as c_uint))
                            if (if prev_okquantifier != 0: 0 else: 1) != 0:
                                (errorcode = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item) == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern = parsed_pattern + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern = meta_quantifier)
                            (parsed_pattern = parsed_pattern + 1)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern = min_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern = max_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        123 =>
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend, (&mut min_repeat as *mut c_uint), (&mut max_repeat as *mut c_uint), (&mut errorcode as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    __pc = 19
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (meta_quantifier = (2151743488 as c_uint))
                            if (if prev_okquantifier != 0: 0 else: 1) != 0:
                                (errorcode = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item) == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern = parsed_pattern + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern = meta_quantifier)
                            (parsed_pattern = parsed_pattern + 1)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern = min_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern = max_repeat)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        91 =>
                            if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 6: 1 else: 0) != 0 and ((if (if _pcre2_strncmp_c8_8(ptr, ((&STRING_WEIRD_STARTWORD[0] as *mut c_char) as *const i8), 6) == 0: 1 else: 0) != 0 or (if _pcre2_strncmp_c8_8(ptr, ((&STRING_WEIRD_ENDWORD[0] as *mut c_char) as *const i8), 6) == 0: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% 5))
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ptr[2] == 60: 1 else: 0) != 0:
                                    (unsafe: *parsed_pattern = 2150039552)
                                    (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    (unsafe: *parsed_pattern = 2150170624)
                                    (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *has_lookbehind) = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((options & 131072)) == 0: 1 else: 0) != 0:
                                    (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% 11))
                                    (parsed_pattern = parsed_pattern + 1)
                                else:
                                    (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% 16))
                                    (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (unsafe: *parsed_pattern = 524288)
                                    (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern = 2149384192)
                                (parsed_pattern = parsed_pattern + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ptr = ptr + 6
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (okquantifier = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if (if (unsafe: *ptr) == 58: 1 else: 0) != 0 or (if (unsafe: *ptr) == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *ptr) == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend, (&mut tempptr as *mut *const u8)) != 0: 1 else: 0) != 0:
                                (errorcode = (if ((if (unsafe: *(ptr = ptr - 1)) == 58: 1 else: 0)) != 0: ERR12 else: ERR13))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ptr = (tempptr + (2 as isize as usize)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (class_mode_state = (if ((if ((options & 134217728)) != 0: 1 else: 0)) != 0: CLASS_MODE_ALT_EXT else: CLASS_MODE_NORMAL))
                            (okquantifier = 1)
                            (class_depth_m1 = -1)
                            (class_maxdepth_m1 = -1)
                            (class_range_state = 0)
                            (class_op_state = 0)
                            (class_start = (null as *mut c_uint))
                            while true:
                                char_is_literal = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if inescq != 0:
                                    if (if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (inescq = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 5
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if class_mode_state == 2: 1 else: 0) != 0:
                                        (errorcode = ERR116)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 4
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((if (if c == 32: 1 else: 0) != 0 or (if c == 9: 1 else: 0) != 0: 1 else: 0)) != 0 and ((if (if ((options & 16777216)) != 0: 1 else: 0) != 0 or (if class_mode_state >= 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                    __pc = 5
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if (if (if (if class_depth_m1 >= 0: 1 else: 0) != 0 and (if c == 91: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0: 1 else: 0) != 0 and ((if (if (if (unsafe: *ptr) == 58: 1 else: 0) != 0 or (if (unsafe: *ptr) == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *ptr) == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend, (&mut tempptr as *mut *const u8)) != 0: 1 else: 0) != 0:
                                    posix_negate = 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if class_range_state == 1: 1 else: 0) != 0:
                                        (ptr = (tempptr + (2 as isize as usize)))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode = ERR50)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if class_range_state == 3: 1 else: 0) != 0:
                                        (ptr = class_range_forbid_ptr)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode = ERR50)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (ptr = (tempptr + (2 as isize as usize)))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode = ERR113)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (unsafe: *ptr) != 58: 1 else: 0) != 0:
                                        (ptr = (tempptr + (2 as isize as usize)))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode = ERR13)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (unsafe: *((ptr = ptr + 1))) == 94: 1 else: 0) != 0:
                                        (posix_negate = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (posix_class = check_posix_name(ptr, ((((tempptr as usize -% ptr as usize) / sizeof[u8]())) as c_int)))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (ptr = (tempptr + (2 as isize as usize)))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if posix_class < 0: 1 else: 0) != 0:
                                        (errorcode = ERR30)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (class_range_state = 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (class_op_state = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (unsafe: *parsed_pattern = (if posix_negate != 0: 2149646336 else: 2149580800))
                                    (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (unsafe: *parsed_pattern = posix_class)
                                    (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if ((if (if c == 91: 1 else: 0) != 0 and ((if (if (if class_depth_m1 < 0: 1 else: 0) != 0 or (if class_mode_state == 1: 1 else: 0) != 0: 1 else: 0) != 0 or (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0 or ((if (if c == 40: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        start_c = c
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if (if start_c == 91: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if class_depth_m1 >= 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (new_class_mode_state = 3)
                                        else:
                                            (new_class_mode_state = class_mode_state)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_range_state == 1: 1 else: 0) != 0:
                                            (parsed_pattern[-1] = 45)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (errorcode = ERR113)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_depth_m1 >= (15 - 1): 1 else: 0) != 0:
                                            (ptr = ptr - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (errorcode = ERR107)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (negate_class = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        while true:
                                            if (if ptr >= ptrend: 1 else: 0) != 0:
                                                if (if start_c == 40: 1 else: 0) != 0:
                                                    (errorcode = ERR14)
                                                else:
                                                    (errorcode = ERR6)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            0
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if new_class_mode_state == 2: 1 else: 0) != 0:
                                                break
                                            else:
                                                if (if c == 92: 1 else: 0) != 0:
                                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = ptr + 1)
                                                    else:
                                                        if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, "Q\\E", 3) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            ptr = ptr + 3
                                                        else:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if (if c == 93: 1 else: 0) != 0 and (if ((cb.external_options & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if new_class_mode_state < 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            if (if class_start != (null as *mut c_uint): 1 else: 0) != 0:
                                                (unsafe: *class_start) = (unsafe: *class_start) | 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (class_start = (null as *mut c_uint))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern = (if negate_class != 0: 2148270080 else: 2148204544))
                                            (parsed_pattern = parsed_pattern + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if class_depth_m1 < 0: 1 else: 0) != 0:
                                                break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_range_state = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_op_state = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 5
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_start != (null as *mut c_uint): 1 else: 0) != 0:
                                            (unsafe: *class_start) = (unsafe: *class_start) | 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_start = (null as *mut c_uint))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_start = parsed_pattern)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern = (if negate_class != 0: 2148401152 else: 2148139008))
                                        (parsed_pattern = parsed_pattern + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_range_state = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_op_state = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_mode_state = new_class_mode_state)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_depth_m1 = class_depth_m1 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_maxdepth_m1 < class_depth_m1: 1 else: 0) != 0:
                                            (class_maxdepth_m1 = class_depth_m1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((&cb.class_op_used[0] as *mut u8)[class_depth_m1] = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if c == 93: 1 else: 0) != 0 and (if new_class_mode_state != 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (class_range_state = 5)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_op_state = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            0
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 5
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        continue
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        if (if (if c == 93: 1 else: 0) != 0 or ((if (if c == 41: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                            if (if class_mode_state == 2: 1 else: 0) != 0:
                                                if (if (if c == 93: 1 else: 0) != 0 and (if class_depth_m1 != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode = ERR14)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr - 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    __pc = 19
                                                    __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if c == 41: 1 else: 0) != 0 and (if class_depth_m1 < 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode = ERR22)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    __pc = 19
                                                    __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if class_op_state == 2: 1 else: 0) != 0:
                                                (errorcode = ERR110)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if class_mode_state == 2: 1 else: 0) != 0 and (if class_op_state == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR114)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if class_range_state == 1: 1 else: 0) != 0:
                                                (parsed_pattern[-1] = 45)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern = 2148335616)
                                            (parsed_pattern = parsed_pattern + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (class_depth_m1 = class_depth_m1 - 1) < 0: 1 else: 0) != 0:
                                                if (if class_mode_state == 2: 1 else: 0) != 0:
                                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (errorcode = ERR115)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        __pc = 19
                                                        __goto_pending = 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_range_state = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_op_state = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if class_mode_state == 3: 1 else: 0) != 0:
                                                (class_mode_state = 2)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_start = (null as *mut c_uint))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            if (if (if class_mode_state == 2: 1 else: 0) != 0 and ((if (if (if (if (if c == 43: 1 else: 0) != 0 or (if c == 124: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 45: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 38: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 94: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                if (if class_op_state != 1: 1 else: 0) != 0:
                                                    (errorcode = ERR109)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    __pc = 19
                                                    __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if class_start != (null as *mut c_uint): 1 else: 0) != 0:
                                                    (unsafe: *class_start) = (unsafe: *class_start) | 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (class_start = (null as *mut c_uint))
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern = (if (if c == 43: 1 else: 0) != 0: 2152005632 else: (if (if c == 124: 1 else: 0) != 0: 2152005632 else: (if (if c == 45: 1 else: 0) != 0: 2152071168 else: (if (if c == 38: 1 else: 0) != 0: 2151940096 else: 2152136704)))))
                                                (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (class_range_state = 0)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (class_op_state = 2)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                if (if (if class_mode_state == 2: 1 else: 0) != 0 and (if c == 33: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    if (if class_op_state == 1: 1 else: 0) != 0:
                                                        (errorcode = ERR113)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        __pc = 19
                                                        __goto_pending = 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    if (if class_start != (null as *mut c_uint): 1 else: 0) != 0:
                                                        (unsafe: *class_start) = (unsafe: *class_start) | 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (class_start = (null as *mut c_uint))
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (unsafe: *parsed_pattern = 2152202240)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (class_range_state = 0)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (class_op_state = 2)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    if (if (if (if (if class_mode_state == 1: 1 else: 0) != 0 and ((if (if (if (if c == 124: 1 else: 0) != 0 or (if c == 45: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 38: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 126: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == c: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = ptr + 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == c: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            while (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == c: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                (ptr = ptr + 1)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (errorcode = ERR108)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            __pc = 19
                                                            __goto_pending = 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if class_op_state != 1: 1 else: 0) != 0:
                                                            (errorcode = ERR109)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            __pc = 19
                                                            __goto_pending = 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if class_start != (null as *mut c_uint): 1 else: 0) != 0:
                                                            (unsafe: *class_start) = (unsafe: *class_start) | 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (class_start = (null as *mut c_uint))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if class_range_state == 1: 1 else: 0) != 0:
                                                            (parsed_pattern[-1] = 45)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (unsafe: *parsed_pattern = (if (if c == 124: 1 else: 0) != 0: 2152005632 else: (if (if c == 45: 1 else: 0) != 0: 2152071168 else: (if (if c == 38: 1 else: 0) != 0: 2151940096 else: 2152136704))))
                                                        (parsed_pattern = parsed_pattern + 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (class_range_state = 0)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (class_op_state = 2)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    else:
                                                        if (if c == 92: 1 else: 0) != 0:
                                                            (tempptr = ptr)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (escape = _pcre2_check_escape_8((&mut ptr as *mut *const u8), ptrend, (&mut c as *mut c_uint), (&mut errorcode as *mut c_int), options, xoptions, cb.bracount, 1, cb))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            if (if errorcode != 0: 1 else: 0) != 0:
                                                                if (if (if ((xoptions & 2)) == 0: 1 else: 0) != 0 or (if class_mode_state >= 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                (ptr = tempptr)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                if (if ptr >= ptrend: 1 else: 0) != 0:
                                                                    (c = 92)
                                                                else:
                                                                    0
                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                        break
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                (escape = 0)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            match escape
                                                                0 =>
                                                                    (char_is_literal = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (c = 8)
                                                                    (char_is_literal = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (c = 107)
                                                                    (char_is_literal = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (inescq = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_b =>
                                                                    (c = 8)
                                                                    (char_is_literal = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (c = 107)
                                                                    (char_is_literal = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (inescq = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_k =>
                                                                    (c = 107)
                                                                    (char_is_literal = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (inescq = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_Q =>
                                                                    (inescq = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_E =>
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_B =>
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_N =>
                                                                    (errorcode = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_H => 0
                                                                ESC_d => 0
                                                                ESC_P =>
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_A =>
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                _ =>
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            if (if class_range_state == 1: 1 else: 0) != 0:
                                                                (errorcode = ERR50)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            if (if class_range_state == 3: 1 else: 0) != 0:
                                                                (ptr = class_range_forbid_ptr)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                (errorcode = ERR50)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                (errorcode = ERR113)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (class_range_state = 2)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (class_op_state = 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        else:
                                                            if (if class_mode_state == 2: 1 else: 0) != 0:
                                                                (errorcode = ERR116)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            else:
                                                                if (if (if c == 45: 1 else: 0) != 0 and (if class_range_state >= 4: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                    (unsafe: *parsed_pattern = (if ((if class_range_state == 5: 1 else: 0)) != 0: 2149777408 else: 2149711872))
                                                                    (parsed_pattern = parsed_pattern + 1)
                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                        break
                                                                    (class_range_state = 1)
                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                        break
                                                                else:
                                                                    if (if (if c == 45: 1 else: 0) != 0 and (if class_range_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                        (unsafe: *parsed_pattern = 45)
                                                                        (parsed_pattern = parsed_pattern + 1)
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                        (class_range_state = 3)
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                        (class_range_forbid_ptr = ptr)
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                    else:
                                                                        if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                            (errorcode = ERR113)
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                            __pc = 19
                                                                            __goto_pending = 1
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                        if (if class_range_state == 1: 1 else: 0) != 0:
                                                                            if (if c == parsed_pattern[-2]: 1 else: 0) != 0:
                                                                                (parsed_pattern = parsed_pattern - 1)
                                                                            else:
                                                                                if (if parsed_pattern[-2] > c: 1 else: 0) != 0:
                                                                                    (errorcode = ERR8)
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                                    __pc = 19
                                                                                    __goto_pending = 1
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                                else:
                                                                                    if (if (if char_is_literal != 0: 0 else: 1) != 0 and (if parsed_pattern[-1] == 2149777408: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                                        (parsed_pattern[-1] = (2149711872 as c_uint))
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                                    0
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                            (class_range_state = 0)
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                            (class_op_state = 1)
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                        else:
                                                                            if (if class_range_state == 3: 1 else: 0) != 0:
                                                                                (ptr = class_range_forbid_ptr)
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                (errorcode = ERR50)
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                __pc = 19
                                                                                __goto_pending = 1
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                            else:
                                                                                (class_range_state = (if char_is_literal != 0: RANGE_OK_LITERAL else: RANGE_OK_ESCAPED))
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                (class_op_state = 1)
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                0
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ptr >= ptrend: 1 else: 0) != 0:
                                    if (if (if class_mode_state == 2: 1 else: 0) != 0 and (if class_depth_m1 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if (if class_mode_state == 1: 1 else: 0) != 0 and (if class_depth_m1 == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if class_maxdepth_m1 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR112)
                                    else:
                                        (errorcode = ERR6)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 19
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        40 =>
                            if (if ptr >= ptrend: 1 else: 0) != 0:
                                __pc = 18
                                __goto_pending = 1
                            if (if (unsafe: *ptr) != 63: 1 else: 0) != 0:
                                if (if (unsafe: *ptr) != 42: 1 else: 0) != 0:
                                    (nest_depth = nest_depth + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if ((options & 8192)) == 0: 1 else: 0) != 0:
                                        if (if cb.bracount >= 65535: 1 else: 0) != 0:
                                            (errorcode = ERR97)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.bracount = cb.bracount + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern = ((2148007936 as c_uint) | cb.bracount))
                                        (parsed_pattern = parsed_pattern + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *parsed_pattern = 2149449728)
                                        (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or (if ((c = ptr[1])) == 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        break
                                    else:
                                        if (if 1 != 0 and (if ((cb.ctypes[c] & 4)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (vn = (&alasnames[0] as *mut c_char))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, 0, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                __pc = 19
                                                __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if ptr >= ptrend: 1 else: 0) != 0:
                                                __pc = 18
                                                __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (unsafe: *ptr) != 58: 1 else: 0) != 0:
                                                (errorcode = ERR95)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 21
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i = 0)
                                            while (if i < 19: 1 else: 0) != 0:
                                                if (if (if namelen == (&alasmeta[0] as *mut alasitem)[i].len: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name, vn, namelen) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                vn = vn + ((&alasmeta[0] as *mut alasitem)[i].len +% 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (i = i + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if i >= 19: 1 else: 0) != 0:
                                                (errorcode = ERR95)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (meta = (&alasmeta[0] as *mut alasitem)[i].meta)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if prev_expect_cond_assert > 0: 1 else: 0) != 0 and ((if (if meta < 2150039552: 1 else: 0) != 0 or (if meta > 2150236160: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR28)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            match meta
                                                2147614720 =>
                                                    __pc = 10
                                                    __goto_pending = 1
                                                    __pc = 11
                                                    __goto_pending = 1
                                                    __pc = 12
                                                    __goto_pending = 1
                                                    __pc = 13
                                                    __goto_pending = 1
                                                    (ptr = ptr + 1)
                                                    (unsafe: *parsed_pattern = 2148990976)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, 0, (&mut errorcode as *mut c_int), cb))
                                                    if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    __pc = 15
                                                    __goto_pending = 1
                                                    (ptr = ptr - 1)
                                                    __pc = 14
                                                    __goto_pending = 1
                                                    __pc = 19
                                                    __goto_pending = 1
                                                2150039552 =>
                                                    __pc = 11
                                                    __goto_pending = 1
                                                    __pc = 12
                                                    __goto_pending = 1
                                                    __pc = 13
                                                    __goto_pending = 1
                                                    (ptr = ptr + 1)
                                                    (unsafe: *parsed_pattern = 2148990976)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, 0, (&mut errorcode as *mut c_int), cb))
                                                    if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    __pc = 15
                                                    __goto_pending = 1
                                                    (ptr = ptr - 1)
                                                    __pc = 14
                                                    __goto_pending = 1
                                                    __pc = 19
                                                    __goto_pending = 1
                                                2150301696 =>
                                                    __pc = 12
                                                    __goto_pending = 1
                                                    __pc = 13
                                                    __goto_pending = 1
                                                    (ptr = ptr + 1)
                                                    (unsafe: *parsed_pattern = 2148990976)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, 0, (&mut errorcode as *mut c_int), cb))
                                                    if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    __pc = 15
                                                    __goto_pending = 1
                                                    (ptr = ptr - 1)
                                                    __pc = 14
                                                    __goto_pending = 1
                                                    __pc = 19
                                                    __goto_pending = 1
                                                2150105088 =>
                                                    __pc = 13
                                                    __goto_pending = 1
                                                    (ptr = ptr + 1)
                                                    (unsafe: *parsed_pattern = 2148990976)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, 0, (&mut errorcode as *mut c_int), cb))
                                                    if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    __pc = 15
                                                    __goto_pending = 1
                                                    (ptr = ptr - 1)
                                                    __pc = 14
                                                    __goto_pending = 1
                                                    __pc = 19
                                                    __goto_pending = 1
                                                2148990976 =>
                                                    (ptr = ptr + 1)
                                                    (unsafe: *parsed_pattern = 2148990976)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, 0, (&mut errorcode as *mut c_int), cb))
                                                    if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    __pc = 15
                                                    __goto_pending = 1
                                                    (ptr = ptr - 1)
                                                    __pc = 14
                                                    __goto_pending = 1
                                                    __pc = 19
                                                    __goto_pending = 1
                                                2150170624 =>
                                                    (ptr = ptr - 1)
                                                    __pc = 14
                                                    __goto_pending = 1
                                                    __pc = 19
                                                    __goto_pending = 1
                                                2149974016 =>
                                                    __pc = 19
                                                    __goto_pending = 1
                                                _ =>
                                                    (errorcode = ERR89)
                                                    __pc = 19
                                                    __goto_pending = 1
                                                    __pc = 10
                                                    __goto_pending = 1
                                                    __pc = 11
                                                    __goto_pending = 1
                                                    __pc = 12
                                                    __goto_pending = 1
                                                    __pc = 13
                                                    __goto_pending = 1
                                                    (ptr = ptr + 1)
                                                    (unsafe: *parsed_pattern = 2148990976)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, 0, (&mut errorcode as *mut c_int), cb))
                                                    if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    __pc = 15
                                                    __goto_pending = 1
                                                    (ptr = ptr - 1)
                                                    __pc = 14
                                                    __goto_pending = 1
                                                    __pc = 19
                                                    __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            (vn = (&verbnames[0] as *mut c_char))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, 0, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                __pc = 19
                                                __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if ptr >= ptrend: 1 else: 0) != 0 or ((if (if (unsafe: *ptr) != 58: 1 else: 0) != 0 and (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR60)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i = 0)
                                            while (if i < 9: 1 else: 0) != 0:
                                                if (if (if namelen == (&verbs[0] as *mut verbitem)[i].len: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name, vn, namelen) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                vn = vn + ((&verbs[0] as *mut verbitem)[i].len +% 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (i = i + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if i >= 9: 1 else: 0) != 0:
                                                (errorcode = ERR60)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if (if (unsafe: *ptr) == 58: 1 else: 0) != 0 and (if (ptr + (1 as isize as usize)) < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (ptr = ptr + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if (&verbs[0] as *mut verbitem)[i].has_arg > 0: 1 else: 0) != 0 and (if (unsafe: *ptr) != 58: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR66)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (verbstartptr = parsed_pattern)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (okquantifier = ((if (&verbs[0] as *mut verbitem)[i].meta == 2150498304: 1 else: 0)))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (unsafe: *(ptr = ptr + 1)) == 58: 1 else: 0) != 0:
                                                if (if (&verbs[0] as *mut verbitem)[i].has_arg < 0: 1 else: 0) != 0:
                                                    (add_after_mark = (&verbs[0] as *mut verbitem)[i].meta)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (unsafe: *parsed_pattern = 2150432768)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    (unsafe: *parsed_pattern = ((&verbs[0] as *mut verbitem)[i].meta +% ((if ((if (&verbs[0] as *mut verbitem)[i].meta != 2150432768: 1 else: 0)) != 0: 65536 else: 0))))
                                                    (parsed_pattern = parsed_pattern + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (verblengthptr = parsed_pattern)
                                                (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (verbnamestart = ptr)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (inverbname = 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                (unsafe: *parsed_pattern = (&verbs[0] as *mut verbitem)[i].meta)
                                                (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                __pc = 18
                                __goto_pending = 1
                            match (unsafe: *ptr)
                                80 =>
                                    if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    if (if (unsafe: *ptr) == 60: 1 else: 0) != 0:
                                        (terminator = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (unsafe: *ptr) == 62: 1 else: 0) != 0:
                                        __pc = 8
                                        __goto_pending = 1
                                    if (if (unsafe: *ptr) != 61: 1 else: 0) != 0:
                                        (errorcode = ERR41)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 21
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, 41, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2147745792)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (unsafe: *parsed_pattern = namelen)
                                    (parsed_pattern = parsed_pattern + 1)
                                    0
                                    (okquantifier = 1)
                                82 =>
                                    (i = 0)
                                    (ptr = ptr + 1)
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or ((if (if (unsafe: *ptr) != 41: 1 else: 0) != 0 and (if (unsafe: *ptr) != 40: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR58)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (terminator = 0)
                                    __pc = 7
                                    __goto_pending = 1
                                    if (if (ptr + (1 as isize as usize)) >= ptrend: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 18
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (terminator = 0)
                                    __pc = 9
                                    __goto_pending = 1
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, 0, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2149908480)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (unsafe: *parsed_pattern = namelen)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (terminator = 0)
                                    0
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                43 =>
                                    if (if (ptr + (1 as isize as usize)) >= ptrend: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 18
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (terminator = 0)
                                    __pc = 9
                                    __goto_pending = 1
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, 0, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2149908480)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (unsafe: *parsed_pattern = namelen)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (terminator = 0)
                                    0
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                48 =>
                                    (terminator = 0)
                                    __pc = 9
                                    __goto_pending = 1
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, 0, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2149908480)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (unsafe: *parsed_pattern = namelen)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (terminator = 0)
                                    0
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                38 =>
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, 0, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2149908480)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (unsafe: *parsed_pattern = namelen)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (terminator = 0)
                                    0
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                67 =>
                                    if (if ((xoptions & 32768)) != 0: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode = ERR103)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (expect_cond_assert = (prev_expect_cond_assert - 1))
                                    if (if (if (if (if previous_callout != (null as *mut c_uint): 1 else: 0) != 0 and (if ((options & 4)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if previous_callout == (parsed_pattern - (4 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 and (if parsed_pattern[-1] == 255: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = previous_callout)
                                    (previous_callout = parsed_pattern)
                                    (after_manual_callout = 1)
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR39)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (ptr = ptr + 1)
                                    (previous_callout[2] = 0)
                                40 =>
                                    if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (nest_depth = nest_depth + 1)
                                    if (if (if (unsafe: *ptr) == 63: 1 else: 0) != 0 or (if (unsafe: *ptr) == 42: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *parsed_pattern = 2148466688)
                                        (parsed_pattern = parsed_pattern + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (ptr = ptr - 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (expect_cond_assert = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if read_number((&mut ptr as *mut *const u8), ptrend, cb.bracount, 65535, 161, (&mut i as *mut c_int), (&mut errorcode as *mut c_int)) != 0:
                                        if (if i <= 0: 1 else: 0) != 0:
                                            (errorcode = ERR15)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern = 2148663296)
                                        (parsed_pattern = parsed_pattern + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern = i)
                                        (parsed_pattern = parsed_pattern + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        if (if errorcode != 0: 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        else:
                                            if (if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 10: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, ((&STRING_VERSION[0] as *mut c_char) as *const i8), 7) == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[7] != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                ge = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                major = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                minor = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                ptr = ptr + 7
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (unsafe: *ptr) == 62: 1 else: 0) != 0:
                                                    (ge = 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if read_number((&mut ptr as *mut *const u8), ptrend, -1, 1000, 179, (&mut major as *mut c_int), (&mut errorcode as *mut c_int)) != 0: 0 else: 1) != 0:
                                                    __pc = 19
                                                    __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 46: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    if (if read_number((&mut ptr as *mut *const u8), ptrend, -1, 1000, 179, (&mut minor as *mut c_int), (&mut errorcode as *mut c_int)) != 0: 0 else: 1) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode = ERR79)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    if (if ptr < ptrend: 1 else: 0) != 0:
                                                        __pc = 21
                                                        __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    __pc = 19
                                                    __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern = 2148859904)
                                                (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern = ge)
                                                (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern = major)
                                                (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern = minor)
                                                (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                was_r_ampersand = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if (if (unsafe: *ptr) == 82: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) > 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 38: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (terminator = 41)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (was_r_ampersand = 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    if (if (unsafe: *ptr) == 60: 1 else: 0) != 0:
                                                        (terminator = 62)
                                                    else:
                                                        if (if (unsafe: *ptr) == 39: 1 else: 0) != 0:
                                                            (terminator = 39)
                                                        else:
                                                            (terminator = 41)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (ptr = ptr - 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, terminator, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                    __pc = 19
                                                    __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if was_r_ampersand != 0:
                                                    ((unsafe: *parsed_pattern) = (2148728832 as c_uint))
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr - 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    if (if terminator == 41: 1 else: 0) != 0:
                                                        if (if (if namelen == 6: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name, ((&STRING_DEFINE[0] as *mut c_char) as *const i8), 6) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            ((unsafe: *parsed_pattern) = (2148532224 as c_uint))
                                                        else:
                                                            ((unsafe: *parsed_pattern) = (if ((if (if (unsafe: *name) == 82: 1 else: 0) != 0 and (if i >= (namelen as c_int): 1 else: 0) != 0: 1 else: 0)) != 0: 2148794368 else: 2148597760))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (ptr = ptr - 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    else:
                                                        ((unsafe: *parsed_pattern) = (2148597760 as c_uint))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (unsafe: *(parsed_pattern = parsed_pattern + 1)) != 2148532224: 1 else: 0) != 0:
                                                    (unsafe: *parsed_pattern = namelen)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR24)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (ptr = ptr + 1)
                                62 =>
                                    (unsafe: *parsed_pattern = 2147614720)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (nest_depth = nest_depth + 1)
                                    (ptr = ptr + 1)
                                61 =>
                                    (unsafe: *parsed_pattern = 2150039552)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2150301696)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2150105088)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern = parsed_pattern + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    0
                                    ptr = ptr + 2
                                    (nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                42 =>
                                    (unsafe: *parsed_pattern = 2150301696)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    (unsafe: *parsed_pattern = 2150105088)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern = parsed_pattern + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    0
                                    ptr = ptr + 2
                                    (nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                33 =>
                                    (unsafe: *parsed_pattern = 2150105088)
                                    (parsed_pattern = parsed_pattern + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern = parsed_pattern + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    0
                                    ptr = ptr + 2
                                    (nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                60 =>
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern = parsed_pattern + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    0
                                    ptr = ptr + 2
                                    (nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                39 =>
                                    (terminator = 39)
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend, utf, terminator, (&mut offset as *mut c_ulong), (&mut name as *mut *const u8), (&mut namelen as *mut c_uint), (&mut errorcode as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    if (if cb.bracount >= 65535: 1 else: 0) != 0:
                                        (errorcode = ERR97)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (cb.bracount = cb.bracount + 1)
                                    (unsafe: *parsed_pattern = ((2148007936 as c_uint) | cb.bracount))
                                    (parsed_pattern = parsed_pattern + 1)
                                    (nest_depth = nest_depth + 1)
                                    if (if cb.names_found >= 10000: 1 else: 0) != 0:
                                        (errorcode = ERR49)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (is_dupname = 0)
                                    (hash = _pcre2_compile_get_hash_from_name8(name, namelen))
                                    (ng = cb.named_groups)
                                    if (if i < cb.names_found: 1 else: 0) != 0:
                                        break
                                    if (if cb.names_found >= cb.named_group_list_size: 1 else: 0) != 0:
                                        newsize = (cb.named_group_list_size *% 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        newspace = (cb.cx.memctl.malloc((newsize *% sizeof[named_group_8]()), cb.cx.memctl.memory_data) as *mut named_group_8)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if newspace == (null as *mut named_group_8): 1 else: 0) != 0:
                                            (errorcode = ERR21)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        with_memcpy((newspace as *mut c_void) as *i8, (cb.named_groups as *const c_void) as *i8, (cb.named_group_list_size *% sizeof[named_group_8]()) as i64)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if cb.named_group_list_size > 20: 1 else: 0) != 0:
                                            cb.cx.memctl.free((cb.named_groups as *mut c_void), cb.cx.memctl.memory_data)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.named_groups = newspace)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.named_group_list_size = newsize)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if is_dupname != 0:
                                        hash = hash | 32768
                                    (cb.named_groups[cb.names_found].name = name)
                                    (cb.named_groups[cb.names_found].number = cb.bracount)
                                    (cb.named_groups[cb.names_found].hash_dup = hash)
                                    (cb.names_found = cb.names_found + 1)
                                91 =>
                                    (class_mode_state = 2)
                                    (c = (unsafe: *(ptr = ptr + 1)))
                                    __pc = 3
                                    __goto_pending = 1
                                _ =>
                                    (nest_depth = nest_depth + 1)
                                    (top_nest.nest_depth = nest_depth)
                                    (top_nest.flags = 0)
                                    if (if (unsafe: *ptr) == 124: 1 else: 0) != 0:
                                        top_nest.flags = top_nest.flags | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        cb.external_flags = cb.external_flags | 2097152
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern = 2149449728)
                                        (parsed_pattern = parsed_pattern + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        hyphenok = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        oldoptions = options
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        oldxoptions = xoptions
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest.reset_group = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest.max_group = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unset = 0)
                                        (set = unset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (optset = (&mut set as *mut c_uint))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (xunset = 0)
                                        (xset = xunset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (xoptset = (&mut xset as *mut c_uint))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 94: 1 else: 0) != 0: 1 else: 0) != 0:
                                            options = options & (0 - ((((((8 | 1024) | 8192) | 32) | 128) | 16777216)) - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            xoptions = xoptions & (0 - (128) - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (hyphenok = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (ptr = ptr + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        while (if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) != 58: 1 else: 0) != 0: 1 else: 0) != 0:
                                            match (unsafe: *(ptr = ptr + 1))
                                                45 =>
                                                    if (if hyphenok != 0: 0 else: 1) != 0:
                                                        (errorcode = ERR94)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        __pc = 19
                                                        __goto_pending = 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    (optset = (&mut unset as *mut c_uint))
                                                    (xoptset = (&mut xunset as *mut c_uint))
                                                    (hyphenok = 0)
                                                97 =>
                                                    if (if ptr < ptrend: 1 else: 0) != 0:
                                                        if (if (unsafe: *ptr) == 68: 1 else: 0) != 0:
                                                            (unsafe: *xoptset) = (unsafe: *xoptset) | 256
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (ptr = ptr + 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (unsafe: *ptr) == 80: 1 else: 0) != 0:
                                                            (unsafe: *xoptset) = (unsafe: *xoptset) | ((2048 | 4096))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (ptr = ptr + 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (unsafe: *ptr) == 83: 1 else: 0) != 0:
                                                            (unsafe: *xoptset) = (unsafe: *xoptset) | 512
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (ptr = ptr + 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (unsafe: *ptr) == 84: 1 else: 0) != 0:
                                                            (unsafe: *xoptset) = (unsafe: *xoptset) | 4096
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (ptr = ptr + 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (unsafe: *ptr) == 87: 1 else: 0) != 0:
                                                            (unsafe: *xoptset) = (unsafe: *xoptset) | 1024
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (ptr = ptr + 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    (unsafe: *xoptset) = (unsafe: *xoptset) | ((((256 | 512) | 1024) | 4096) | 2048)
                                                74 =>
                                                    (unsafe: *optset) = (unsafe: *optset) | 64
                                                    cb.external_flags = cb.external_flags | 1024
                                                105 =>
                                                    (unsafe: *optset) = (unsafe: *optset) | 8
                                                109 =>
                                                    (unsafe: *optset) = (unsafe: *optset) | 1024
                                                110 =>
                                                    (unsafe: *optset) = (unsafe: *optset) | 8192
                                                114 =>
                                                    (unsafe: *xoptset) = (unsafe: *xoptset) | 128
                                                115 =>
                                                    (unsafe: *optset) = (unsafe: *optset) | 32
                                                85 =>
                                                    (unsafe: *optset) = (unsafe: *optset) | 262144
                                                120 =>
                                                    (unsafe: *optset) = (unsafe: *optset) | 128
                                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if (unsafe: *ptr) == 120: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (unsafe: *optset) = (unsafe: *optset) | 16777216
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (ptr = ptr + 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                _ =>
                                                    (errorcode = ERR11)
                                                    __pc = 19
                                                    __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if ((set & ((128 | 16777216)))) == 128: 1 else: 0) != 0 or (if ((unset & 128)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            unset = unset | 16777216
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (options = (((options | set)) & ((0 - unset - 1))))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (xoptions = (((xoptions | xset)) & ((0 - xunset - 1))))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if ptr >= ptrend: 1 else: 0) != 0:
                                            __pc = 18
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (unsafe: *(ptr = ptr + 1)) == 41: 1 else: 0) != 0:
                                            (nest_depth = nest_depth - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            (unsafe: *parsed_pattern = 2149449728)
                                            (parsed_pattern = parsed_pattern + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if options != oldoptions: 1 else: 0) != 0 or (if xoptions != oldxoptions: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (unsafe: *parsed_pattern = 2149515264)
                                            (parsed_pattern = parsed_pattern + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern = options)
                                            (parsed_pattern = parsed_pattern + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern = xoptions)
                                            (parsed_pattern = parsed_pattern + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                        124 =>
                            if (if (if (if top_nest != (null as *mut nest_save): 1 else: 0) != 0 and (if top_nest.nest_depth == nest_depth: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((top_nest.flags & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (cb.bracount = top_nest.reset_group)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern = 2147549184)
                            (parsed_pattern = parsed_pattern + 1)
                        41 =>
                            (okquantifier = 1)
                            if (if (if top_nest != (null as *mut nest_save): 1 else: 0) != 0 and (if top_nest.nest_depth == nest_depth: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if (if ((top_nest.flags & 1)) != 0: 1 else: 0) != 0 and (if top_nest.max_group > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (cb.bracount = top_nest.max_group)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((top_nest.flags & 2)) != 0: 1 else: 0) != 0:
                                    (okquantifier = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((top_nest.flags & 4)) != 0: 1 else: 0) != 0:
                                    (unsafe: *parsed_pattern = 2149384192)
                                    (parsed_pattern = parsed_pattern + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if nest_depth == 0: 1 else: 0) != 0:
                                (errorcode = ERR22)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (nest_depth = nest_depth - 1)
                            (unsafe: *parsed_pattern = 2149384192)
                            (parsed_pattern = parsed_pattern + 1)
                        _ =>
                            0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if inverbname != 0 and (if ptr >= ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                    (errorcode = ERR60)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 19
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 17
                continue
            17 =>  // PARSED_END
                (__goto_pending = 0)
                (parsed_pattern = manage_callouts(ptr, (&mut previous_callout as *mut *mut c_uint), auto_callout, parsed_pattern, cb))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((xoptions & 8)) != 0: 1 else: 0) != 0:
                    (unsafe: *parsed_pattern = 2149384192)
                    (parsed_pattern = parsed_pattern + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (unsafe: *parsed_pattern = 2149187584)
                    (parsed_pattern = parsed_pattern + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    if (if ((xoptions & 4)) != 0: 1 else: 0) != 0:
                        (unsafe: *parsed_pattern = 2149384192)
                        (parsed_pattern = parsed_pattern + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (unsafe: *parsed_pattern = ((2149318656 as c_uint) +% 5))
                        (parsed_pattern = parsed_pattern + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if parsed_pattern >= parsed_pattern_end: 1 else: 0) != 0:
                    (errorcode = ERR63)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 19
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *parsed_pattern) = (2147483648 as c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if nest_depth == 0: 1 else: 0) != 0:
                    return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 18
                continue
            18 =>  // UNCLOSED_PARENTHESIS
                (__goto_pending = 0)
                (errorcode = ERR14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 19
                continue
            19 =>  // FAILED
                (__goto_pending = 0)
                return errorcode
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 20
                continue
            20 =>  // FAILED_BACK
                (__goto_pending = 0)
                (ptr = ptr - 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 19
                continue
                __pc = 21
                continue
            21 =>  // FAILED_FORWARD
                (__goto_pending = 0)
                (ptr = ptr + 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 19
                continue
            _ => break

fn first_significant_code(__param_code: *const u8, skipassert: c_int) -> *const u8:
    var code = __param_code
    while true:
        match ((unsafe: *code) as c_int)
            OP_ASSERT_NOT =>
                code = code + _pcre2_OP_lengths_8[(unsafe: *code)]
            OP_WORD_BOUNDARY => 0
            OP_CALLOUT => 0
            OP_CALLOUT_STR => 0
            OP_SKIPZERO => 0
            OP_COND => 0
            OP_MARK => 0
            _ =>
                return code
        


fn compile_branch(optionsptr: *mut c_uint, xoptionsptr: *mut c_uint, codeptr: *mut *mut u8, pptrptr: *mut *mut c_uint, errorcodeptr: *mut c_int, firstcuptr: *mut c_uint, firstcuflagsptr: *mut c_uint, reqcuptr: *mut c_uint, reqcuflagsptr: *mut c_uint, bcptr: *mut branch_chain_8, open_caps: *mut open_capitem, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int:
    var bravalue: c_int = 0
    var okreturn: c_int = 0
    var group_return: c_int = 0
    var repeat_min: c_uint = 0
    var repeat_max: c_uint = 0
    var greedy_default: c_uint = 0
    var greedy_non_default: c_uint = 0
    var repeat_type: c_uint = 0
    var op_type: c_uint = 0
    var options: c_uint = 0
    var xoptions: c_uint = 0
    var firstcu: c_uint = 0
    var reqcu: c_uint = 0
    var zeroreqcu: c_uint = 0
    var zerofirstcu: c_uint = 0
    var pptr: *mut c_uint = null
    var meta: c_uint = 0
    var meta_arg: c_uint = 0
    var firstcuflags: c_uint = 0
    var reqcuflags: c_uint = 0
    var zeroreqcuflags: c_uint = 0
    var zerofirstcuflags: c_uint = 0
    var req_caseopt: c_uint = 0
    var reqvary: c_uint = 0
    var tempreqvary: c_uint = 0
    var offset: c_ulong = 0
    var length_prevgroup: c_ulong = 0
    var code: *mut u8 = null
    var last_code: *mut u8 = null
    var orig_code: *mut u8 = null
    var tempcode: *mut u8 = null
    var previous: *mut u8 = null
    var op_previous: u8 = 0
    var groupsetfirstcu: c_int = 0
    var had_accept: c_int = 0
    var matched_char: c_int = 0
    var previous_matched_char: c_int = 0
    var reset_caseful: c_int = 0
    var utf: c_int = 0
    var possessive_quantifier: c_int = 0
    var note_group_empty: c_int = 0
    var mclength: c_uint = 0
    var skipunits: c_uint = 0
    var subreqcu: c_uint = 0
    var subfirstcu: c_uint = 0
    var groupnumber: c_uint = 0
    var verbarglen: c_uint = 0
    var verbculen: c_uint = 0
    var subreqcuflags: c_uint = 0
    var subfirstcuflags: c_uint = 0
    var oc: *mut open_capitem = null
    var mcbuffer: [8]u8 = [0 as u8; 8]
    var c: c_uint = 0
    var d: c_uint = 0
    var i: c_int = 0
    var count: c_int = 0
    var index: c_int = 0
    var ng: *mut named_group_8 = null
    var name: *const u8 = null
    var start_pptr: *mut c_uint = null
    var length: c_uint = 0
    var tc: *mut u8 = null
    var condcount: c_int = 0
    var pp: *const u8 = null
    var delimiter: c_uint = 0
    var callout_string: *mut u8 = null
    var replicate: c_int = 0
    var delta: c_ulong = 0
    var len: c_int = 0
    var bralink: *mut u8 = null
    var brazeroptr: *mut u8 = null
    var linkoffset: c_int = 0
    var oldlinkoffset: c_int = 0
    var bra: *mut u8 = null
    var ketcode: *mut u8 = null
    var bracode: *mut u8 = null
    var nlen: c_int = 0
    var prop_type: c_int = 0
    var prop_value: c_int = 0
    var oldcode: *mut u8 = null
    var repcode: c_uint = 0
    var args: *mut recurse_arguments = null
    var current: *mut c_ushort = null
    var end: *mut c_ushort = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                bravalue = 0
                okreturn = -1
                group_return = 0
                repeat_min = 0
                repeat_max = 0
                options = (unsafe: *optionsptr)
                xoptions = (unsafe: *xoptionsptr)
                pptr = (unsafe: *pptrptr)
                offset = 0
                length_prevgroup = 0
                code = (unsafe: *codeptr)
                last_code = code
                orig_code = code
                previous = (null as *mut u8)
                groupsetfirstcu = 0
                had_accept = 0
                matched_char = 0
                previous_matched_char = 0
                reset_caseful = 0
                utf = 0
                (greedy_default = ((if ((options & 262144)) != 0: 1 else: 0)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (greedy_non_default = (greedy_default ^ 1))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (zeroreqcu = 0)
                (zerofirstcu = zeroreqcu)
                (reqcu = zerofirstcu)
                (firstcu = reqcu)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (zeroreqcuflags = (4294967295 as c_uint))
                (zerofirstcuflags = zeroreqcuflags)
                (reqcuflags = zerofirstcuflags)
                (firstcuflags = reqcuflags)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (req_caseopt = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: 1 else: 0))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (pptr = pptr + 1) != null:
                    if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                        if (if code >= (cb.start_workspace + cb.workspace_size): 1 else: 0) != 0:
                            ((unsafe: *errorcodeptr) = ERR52)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (cb.erroroffset = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            return 0
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if code > ((cb.start_workspace + cb.workspace_size) - ((100) as isize as usize)): 1 else: 0) != 0:
                            ((unsafe: *errorcodeptr) = ERR86)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (cb.erroroffset = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            return 0
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if code < last_code: 1 else: 0) != 0:
                            (code = last_code)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if (if meta < 2151153664: 1 else: 0) != 0 or (if meta > 2151874560: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (unsafe: *lengthptr) > 65536: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR20)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (code = orig_code)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (last_code = code)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if meta < 2151153664: 1 else: 0) != 0 or (if meta > 2151874560: 1 else: 0) != 0: 1 else: 0) != 0:
                        (previous = code)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if matched_char != 0 and (if had_accept != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                            (okreturn = 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (previous_matched_char = matched_char)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (matched_char = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (note_group_empty = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (skipunits = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    match meta
                        2147483648 =>
                            ((unsafe: *firstcuflagsptr) = firstcuflags)
                            ((unsafe: *reqcuptr) = reqcu)
                            ((unsafe: *reqcuflagsptr) = reqcuflags)
                            ((unsafe: *codeptr) = code)
                            ((unsafe: *pptrptr) = pptr)
                            return okreturn
                        2148073472 =>
                            if (if ((options & 1024)) != 0: 1 else: 0) != 0:
                                if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags = (4294967294 as c_uint))
                                    (zerofirstcuflags = firstcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = 28)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (unsafe: *code = 27)
                                (code = code + 1)
                        2149187584 =>
                            (unsafe: *code = (if ((if ((options & 1024)) != 0: 1 else: 0)) != 0: OP_DOLLM else: OP_DOLL))
                            (code = code + 1)
                        2149253120 =>
                            (matched_char = 1)
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = (4294967294 as c_uint))
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (unsafe: *code = (if ((if ((options & 32)) != 0: 1 else: 0)) != 0: OP_ALLANY else: OP_ANY))
                            (code = code + 1)
                        2148204544 =>
                            if (if meta == 2148270080: 1 else: 0) != 0:
                                (unsafe: *code = 13)
                                (code = code + 1)
                            else:
                                (unsafe: *code = 110)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                with_memset((code as *mut c_void) as *i8, 0, 32 as i64)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                code = code + (32 / sizeof[u8]())
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = (4294967294 as c_uint))
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                        2148401152 =>
                            if (if (((unsafe: *pptr) & 1)) != 0: 1 else: 0) != 0:
                                if (if _pcre2_compile_class_nested_8(options, xoptions, (&mut pptr as *mut *mut c_uint), (&mut code as *mut *mut u8), errorcodeptr, cb, lengthptr) != 0: 0 else: 1) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (if pptr[1] < 2147483648: 1 else: 0) != 0 and (if pptr[2] == 2148335616: 1 else: 0) != 0: 1 else: 0) != 0:
                                c = pptr[1]
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta == 2148139008: 1 else: 0) != 0:
                                    (meta = c)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 11
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcu = reqcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcuflags = reqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zerofirstcu = firstcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zerofirstcuflags = firstcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_NOTI else: OP_NOT))
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (if (if (if meta == 2148139008: 1 else: 0) != 0 and (if pptr[1] < 2147483648: 1 else: 0) != 0: 1 else: 0) != 0 and (if pptr[2] < 2147483648: 1 else: 0) != 0: 1 else: 0) != 0 and (if pptr[3] == 2148335616: 1 else: 0) != 0: 1 else: 0) != 0:
                                c = pptr[1]
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (d = ((cb.fcc)[c]))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if c != d: 1 else: 0) != 0 and (if pptr[2] == d: 1 else: 0) != 0: 1 else: 0) != 0:
                                    pptr = pptr + 3
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (meta = c)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if ((options & 8)) == 0: 1 else: 0) != 0:
                                        (reset_caseful = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        options = options | 8
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (req_caseopt = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 12
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (pptr = _pcre2_compile_class_not_nested_8(options, xoptions, (pptr + (1 as isize as usize)), (&mut code as *mut *mut u8), (if meta == 2148401152: 1 else: 0), (null as *mut c_int), errorcodeptr, cb, lengthptr))
                            if (if pptr == (null as *mut c_uint): 1 else: 0) != 0:
                                return 0
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = (4294967294 as c_uint))
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                        2150498304 =>
                            (had_accept = 1)
                            (cb.had_accept = had_accept)
                            (oc = open_caps)
                            while (if (if oc != (null as *mut open_capitem): 1 else: 0) != 0 and (if oc.assert_depth >= cb.assert_depth: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + 3
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    (unsafe: *code = 168)
                                    (code = code + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (oc = oc.next)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *code = (if ((if cb.assert_depth > 0: 1 else: 0)) != 0: OP_ASSERT_ACCEPT else: OP_ACCEPT))
                            (code = code + 1)
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = (4294967294 as c_uint))
                        2150760448 => 0
                        2150629376 => 0
                        2151022592 =>
                            cb.external_flags = cb.external_flags | 4096
                            (unsafe: *code = 161)
                            (code = code + 1)
                        2151088128 =>
                            cb.external_flags = cb.external_flags | 4096
                            __pc = 2
                            __goto_pending = 1
                            (verbarglen = (unsafe: *((pptr = pptr + 1))))
                            (verbculen = 0)
                            (tempcode = code)
                            (code = code + 1)
                            i = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = (unsafe: *((pptr = pptr + 1))))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (mclength = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&mcbuffer[0] as *mut u8)[0] = meta)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + mclength
                                else:
                                    code = code + mclength
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    verbculen = verbculen + mclength
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i = i + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *tempcode) = verbculen)
                            (unsafe: *code = 0)
                            (code = code + 1)
                        2150825984 =>
                            (verbarglen = (unsafe: *((pptr = pptr + 1))))
                            (verbculen = 0)
                            (tempcode = code)
                            (code = code + 1)
                            i = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = (unsafe: *((pptr = pptr + 1))))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (mclength = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&mcbuffer[0] as *mut u8)[0] = meta)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + mclength
                                else:
                                    code = code + mclength
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    verbculen = verbculen + mclength
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i = i + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *tempcode) = verbculen)
                            (unsafe: *code = 0)
                            (code = code + 1)
                        2150432768 =>
                            (verbarglen = (unsafe: *((pptr = pptr + 1))))
                            (verbculen = 0)
                            (tempcode = code)
                            (code = code + 1)
                            i = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = (unsafe: *((pptr = pptr + 1))))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (mclength = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&mcbuffer[0] as *mut u8)[0] = meta)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + mclength
                                else:
                                    code = code + mclength
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    verbculen = verbculen + mclength
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i = i + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *tempcode) = verbculen)
                            (unsafe: *code = 0)
                            (code = code + 1)
                        2149515264 =>
                            (options = (unsafe: *((pptr = pptr + 1))))
                            ((unsafe: *optionsptr) = options)
                            (xoptions = (unsafe: *((pptr = pptr + 1))))
                            ((unsafe: *xoptionsptr) = xoptions)
                            (greedy_default = ((if ((options & 262144)) != 0: 1 else: 0)))
                            (greedy_non_default = (greedy_default ^ 1))
                            (req_caseopt = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: 1 else: 0))
                        2148925440 =>
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                (pptr = _pcre2_compile_parse_scan_substr_args8(pptr, errorcodeptr, cb, lengthptr))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if pptr == (null as *mut c_uint): 1 else: 0) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            while 1 != 0:
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (pptr = pptr - 1)
                        2148990976 =>
                            (bravalue = OP_ASSERT_SCS)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                start_pptr = pptr
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                length = (unsafe: *((pptr = pptr + 1)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (name = (cb.start_pattern + offset))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ng = _pcre2_compile_find_named_group8(name, length, cb))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ng == (null as *mut named_group_8): 1 else: 0) != 0:
                                    (groupnumber = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if meta == 2148794368: 1 else: 0) != 0:
                                        (i = 1)
                                        while (if i < length: 1 else: 0) != 0:
                                            (groupnumber = ((groupnumber *% 10) +% ((name[i] - 48))))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if groupnumber > 65535: 1 else: 0) != 0:
                                                ((unsafe: *errorcodeptr) = ERR61)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (cb.erroroffset = (offset +% i))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                return 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i = i + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if meta != 2148794368: 1 else: 0) != 0 or (if groupnumber > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR15)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if groupnumber == 0: 1 else: 0) != 0:
                                        (groupnumber = 65535)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr[1] = groupnumber)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (meta = (2148597760 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((ng.hash_dup & 32768)) == 0: 1 else: 0) != 0:
                                    if (if ng.number > cb.top_backref: 1 else: 0) != 0:
                                        (cb.top_backref = ng.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr[0] = meta)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr[1] = ng.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (start_pptr[0] = (meta | 1))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (code[(1 + 2)] = 149)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr = pptr + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta_arg == 0: 1 else: 0) != 0:
                                    (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_RREF else: OP_CREF))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr = pptr + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ng = (cb.named_groups + pptr[1]))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (count = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (index = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if _pcre2_compile_find_dupname_details8(ng.name, ng.length, (&mut index as *mut c_int), (&mut count as *mut c_int), errorcodeptr, cb) != 0: 0 else: 1) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_DNRREF else: OP_DNCREF))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (code[(1 + 2)] = 170)
                            (skipunits = 1)
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber = (unsafe: *((pptr = pptr + 1))))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)
                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits = 1)
                            pptr = pptr + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2148794368 =>
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                start_pptr = pptr
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                length = (unsafe: *((pptr = pptr + 1)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (name = (cb.start_pattern + offset))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ng = _pcre2_compile_find_named_group8(name, length, cb))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ng == (null as *mut named_group_8): 1 else: 0) != 0:
                                    (groupnumber = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if meta == 2148794368: 1 else: 0) != 0:
                                        (i = 1)
                                        while (if i < length: 1 else: 0) != 0:
                                            (groupnumber = ((groupnumber *% 10) +% ((name[i] - 48))))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if groupnumber > 65535: 1 else: 0) != 0:
                                                ((unsafe: *errorcodeptr) = ERR61)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (cb.erroroffset = (offset +% i))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                return 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i = i + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if meta != 2148794368: 1 else: 0) != 0 or (if groupnumber > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR15)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if groupnumber == 0: 1 else: 0) != 0:
                                        (groupnumber = 65535)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr[1] = groupnumber)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (meta = (2148597760 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((ng.hash_dup & 32768)) == 0: 1 else: 0) != 0:
                                    if (if ng.number > cb.top_backref: 1 else: 0) != 0:
                                        (cb.top_backref = ng.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr[0] = meta)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr[1] = ng.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (start_pptr[0] = (meta | 1))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (code[(1 + 2)] = 149)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr = pptr + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta_arg == 0: 1 else: 0) != 0:
                                    (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_RREF else: OP_CREF))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr = pptr + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ng = (cb.named_groups + pptr[1]))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (count = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (index = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if _pcre2_compile_find_dupname_details8(ng.name, ng.length, (&mut index as *mut c_int), (&mut count as *mut c_int), errorcodeptr, cb) != 0: 0 else: 1) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_DNRREF else: OP_DNCREF))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (code[(1 + 2)] = 170)
                            (skipunits = 1)
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber = (unsafe: *((pptr = pptr + 1))))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)
                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits = 1)
                            pptr = pptr + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2148532224 =>
                            (bravalue = OP_COND)
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (code[(1 + 2)] = 170)
                            (skipunits = 1)
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber = (unsafe: *((pptr = pptr + 1))))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)
                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits = 1)
                            pptr = pptr + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2148663296 =>
                            (bravalue = OP_COND)
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber = (unsafe: *((pptr = pptr + 1))))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)
                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits = 1)
                            pptr = pptr + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2148859904 =>
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits = 1)
                            pptr = pptr + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2148466688 =>
                            (bravalue = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2150039552 =>
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2150301696 =>
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2150105088 =>
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = 165)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr = pptr + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                cb.assert_depth = cb.assert_depth + 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 4
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2150170624 =>
                            (bravalue = OP_ASSERTBACK)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERTBACK_NOT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_BRA)
                            (note_group_empty = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code) = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, (&mut tempcode as *mut *mut u8), (&mut pptr as *mut *mut c_uint), errorcodeptr, skipunits, (&mut subfirstcu as *mut c_uint), (&mut subfirstcuflags as *mut c_uint), (&mut subreqcu as *mut c_uint), (&mut subreqcuflags as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc = code
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR54)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subreqcuflags = (4294967294 as c_uint))
                                        (subfirstcuflags = subreqcuflags)
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = 122)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code = tempcode)
                            if (if bravalue == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (groupsetfirstcu = 0)
                            if (if bravalue >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags < 4294967294: 1 else: 0) != 0:
                                        (firstcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags = subfirstcuflags)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2150236160 =>
                            (bravalue = OP_ASSERTBACK_NOT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_BRA)
                            (note_group_empty = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code) = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, (&mut tempcode as *mut *mut u8), (&mut pptr as *mut *mut c_uint), errorcodeptr, skipunits, (&mut subfirstcu as *mut c_uint), (&mut subfirstcuflags as *mut c_uint), (&mut subreqcu as *mut c_uint), (&mut subreqcuflags as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc = code
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR54)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subreqcuflags = (4294967294 as c_uint))
                                        (subfirstcuflags = subreqcuflags)
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = 122)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code = tempcode)
                            if (if bravalue == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (groupsetfirstcu = 0)
                            if (if bravalue >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags < 4294967294: 1 else: 0) != 0:
                                        (firstcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags = subfirstcuflags)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2150367232 =>
                            (bravalue = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_BRA)
                            (note_group_empty = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code) = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, (&mut tempcode as *mut *mut u8), (&mut pptr as *mut *mut c_uint), errorcodeptr, skipunits, (&mut subfirstcu as *mut c_uint), (&mut subfirstcuflags as *mut c_uint), (&mut subreqcu as *mut c_uint), (&mut subreqcuflags as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc = code
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR54)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subreqcuflags = (4294967294 as c_uint))
                                        (subfirstcuflags = subreqcuflags)
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = 122)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code = tempcode)
                            if (if bravalue == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (groupsetfirstcu = 0)
                            if (if bravalue >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags < 4294967294: 1 else: 0) != 0:
                                        (firstcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags = subfirstcuflags)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2147614720 =>
                            (bravalue = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_BRA)
                            (note_group_empty = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code) = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, (&mut tempcode as *mut *mut u8), (&mut pptr as *mut *mut c_uint), errorcodeptr, skipunits, (&mut subfirstcu as *mut c_uint), (&mut subfirstcuflags as *mut c_uint), (&mut subreqcu as *mut c_uint), (&mut subreqcuflags as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc = code
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR54)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subreqcuflags = (4294967294 as c_uint))
                                        (subfirstcuflags = subreqcuflags)
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = 122)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code = tempcode)
                            if (if bravalue == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (groupsetfirstcu = 0)
                            if (if bravalue >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags < 4294967294: 1 else: 0) != 0:
                                        (firstcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags = subfirstcuflags)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2149974016 =>
                            (bravalue = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue = OP_BRA)
                            (note_group_empty = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code) = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, (&mut tempcode as *mut *mut u8), (&mut pptr as *mut *mut c_uint), errorcodeptr, skipunits, (&mut subfirstcu as *mut c_uint), (&mut subfirstcuflags as *mut c_uint), (&mut subreqcu as *mut c_uint), (&mut subreqcuflags as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc = code
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR54)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subreqcuflags = (4294967294 as c_uint))
                                        (subfirstcuflags = subreqcuflags)
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = 122)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code = tempcode)
                            if (if bravalue == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (groupsetfirstcu = 0)
                            if (if bravalue >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags < 4294967294: 1 else: 0) != 0:
                                        (firstcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags = subfirstcuflags)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2149449728 =>
                            (bravalue = OP_BRA)
                            (note_group_empty = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code) = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, (&mut tempcode as *mut *mut u8), (&mut pptr as *mut *mut c_uint), errorcodeptr, skipunits, (&mut subfirstcu as *mut c_uint), (&mut subfirstcuflags as *mut c_uint), (&mut subreqcu as *mut c_uint), (&mut subreqcuflags as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc = code
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR54)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((unsafe: *errorcodeptr) = ERR27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subreqcuflags = (4294967294 as c_uint))
                                        (subfirstcuflags = subreqcuflags)
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code = 122)
                                (code = code + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code = tempcode)
                            if (if bravalue == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (groupsetfirstcu = 0)
                            if (if bravalue >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags < 4294967294: 1 else: 0) != 0:
                                        (firstcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags = subfirstcuflags)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = subreqcuflags)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2147745792 => 0
                        2147876864 =>
                            (code[0] = 119)
                            (code[(1 + (2 * 2))] = pptr[3])
                            pptr = pptr + 3
                            code = code + _pcre2_OP_lengths_8[OP_CALLOUT]
                        2147942400 =>
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + (pptr[3] +% 9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 3
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                length = pptr[3]
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                callout_string = (code + (((1 + (4 * 2))) as isize as usize))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code[0] = 120)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 3
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pp = (cb.start_pattern + offset))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *callout_string = (unsafe: *(pp = pp + 1)))
                                (callout_string = callout_string + 1)
                                (delimiter = (unsafe: *(callout_string = callout_string + 1)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if delimiter == 123: 1 else: 0) != 0:
                                    (delimiter = 125)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while (if (length = length - 1) > 1: 1 else: 0) != 0:
                                    if (if (if (unsafe: *pp) == delimiter: 1 else: 0) != 0 and (if pp[1] == delimiter: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *callout_string = delimiter)
                                        (callout_string = callout_string + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        pp = pp + 2
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (length = length - 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *callout_string = (unsafe: *(pp = pp + 1)))
                                        (callout_string = callout_string + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *callout_string = 0)
                                (callout_string = callout_string + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code = callout_string)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2151809024 =>
                            (repeat_max = (unsafe: *((pptr = pptr + 1))))
                            __pc = 5
                            __goto_pending = 1
                            __pc = 5
                            __goto_pending = 1
                            __pc = 5
                            __goto_pending = 1
                            (repeat_max = 1)
                            if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags = zerofirstcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu = zeroreqcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags = zeroreqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta
                                2151809024 =>
                                    (possessive_quantifier = 1)
                                2151874560 =>
                                    (possessive_quantifier = 0)
                                _ =>
                                    (repeat_type = greedy_default)
                                    (possessive_quantifier = 0)
                            (tempcode = previous)
                            (op_previous = (unsafe: *previous))
                            match op_previous
                                OP_CHAR =>
                                    (op_type = (&chartypeoffset[0] as *mut c_uint)[(op_previous - OP_CHAR)])
                                    ((&mcbuffer[0] as *mut u8)[0] = code[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = (&mcbuffer[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous) = 137)
                                    (op_previous = (unsafe: *previous))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous[(3 +% length)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value = previous[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value = -1)
                                        (prop_type = prop_value)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode = code)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code = previous)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type = repeat_type + op_type
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code = op_previous)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *code = prop_type)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code = prop_value)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier != 0:
                                match (unsafe: *tempcode)
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[(unsafe: *tempcode)] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len > 0: 1 else: 0) != 0:
                                    repcode = (unsafe: *tempcode)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode) = (&opcode_possessify[0] as *mut u8)[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len = len + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code = 122)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary
                        2151153664 =>
                            __pc = 5
                            __goto_pending = 1
                            __pc = 5
                            __goto_pending = 1
                            (repeat_max = 1)
                            if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags = zerofirstcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu = zeroreqcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags = zeroreqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta
                                2151809024 =>
                                    (possessive_quantifier = 1)
                                2151874560 =>
                                    (possessive_quantifier = 0)
                                _ =>
                                    (repeat_type = greedy_default)
                                    (possessive_quantifier = 0)
                            (tempcode = previous)
                            (op_previous = (unsafe: *previous))
                            match op_previous
                                OP_CHAR =>
                                    (op_type = (&chartypeoffset[0] as *mut c_uint)[(op_previous - OP_CHAR)])
                                    ((&mcbuffer[0] as *mut u8)[0] = code[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = (&mcbuffer[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous) = 137)
                                    (op_previous = (unsafe: *previous))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous[(3 +% length)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value = previous[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value = -1)
                                        (prop_type = prop_value)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode = code)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code = previous)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type = repeat_type + op_type
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code = op_previous)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *code = prop_type)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code = prop_value)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier != 0:
                                match (unsafe: *tempcode)
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[(unsafe: *tempcode)] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len > 0: 1 else: 0) != 0:
                                    repcode = (unsafe: *tempcode)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode) = (&opcode_possessify[0] as *mut u8)[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len = len + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code = 122)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary
                        2151350272 =>
                            __pc = 5
                            __goto_pending = 1
                            (repeat_max = 1)
                            if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags = zerofirstcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu = zeroreqcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags = zeroreqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta
                                2151809024 =>
                                    (possessive_quantifier = 1)
                                2151874560 =>
                                    (possessive_quantifier = 0)
                                _ =>
                                    (repeat_type = greedy_default)
                                    (possessive_quantifier = 0)
                            (tempcode = previous)
                            (op_previous = (unsafe: *previous))
                            match op_previous
                                OP_CHAR =>
                                    (op_type = (&chartypeoffset[0] as *mut c_uint)[(op_previous - OP_CHAR)])
                                    ((&mcbuffer[0] as *mut u8)[0] = code[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = (&mcbuffer[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous) = 137)
                                    (op_previous = (unsafe: *previous))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous[(3 +% length)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value = previous[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value = -1)
                                        (prop_type = prop_value)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode = code)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code = previous)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type = repeat_type + op_type
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code = op_previous)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *code = prop_type)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code = prop_value)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier != 0:
                                match (unsafe: *tempcode)
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[(unsafe: *tempcode)] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len > 0: 1 else: 0) != 0:
                                    repcode = (unsafe: *tempcode)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode) = (&opcode_possessify[0] as *mut u8)[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len = len + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code = 122)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary
                        2151546880 =>
                            (repeat_max = 1)
                            if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags = zerofirstcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu = zeroreqcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags = zeroreqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta
                                2151809024 =>
                                    (possessive_quantifier = 1)
                                2151874560 =>
                                    (possessive_quantifier = 0)
                                _ =>
                                    (repeat_type = greedy_default)
                                    (possessive_quantifier = 0)
                            (tempcode = previous)
                            (op_previous = (unsafe: *previous))
                            match op_previous
                                OP_CHAR =>
                                    (op_type = (&chartypeoffset[0] as *mut c_uint)[(op_previous - OP_CHAR)])
                                    ((&mcbuffer[0] as *mut u8)[0] = code[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = (&mcbuffer[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous) = 137)
                                    (op_previous = (unsafe: *previous))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous[(3 +% length)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value = previous[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value = -1)
                                        (prop_type = prop_value)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode = code)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code = previous)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type = repeat_type + op_type
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code = op_previous)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *code = prop_type)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code = prop_value)
                                            (code = code + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier != 0:
                                match (unsafe: *tempcode)
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[(unsafe: *tempcode)] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len > 0: 1 else: 0) != 0:
                                    repcode = (unsafe: *tempcode)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode) = (&opcode_possessify[0] as *mut u8)[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len = len + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code = 122)
                                        (code = code + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary
                        2147811328 =>
                            (pptr = pptr + 1)
                            __pc = 10
                            __goto_pending = 1
                            if (if meta_arg < 10: 1 else: 0) != 0:
                                (offset = (&cb.small_ref_offset[0] as *mut c_ulong)[meta_arg])
                            else:
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            0
                            if (if meta_arg > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = (4294967294 as c_uint))
                                (zerofirstcuflags = firstcuflags)
                            (unsafe: *code = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_REFI else: OP_REF))
                            (code = code + 1)
                            if (if ((options & 8)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = (((if ((if ((xoptions & 128)) != 0: 1 else: 0)) != 0: 1 else: 0)) | ((if ((if ((xoptions & 65536)) != 0: 1 else: 0)) != 0: 2 else: 0))))
                                (code = code + 1)
                            cb.backref_map = cb.backref_map | (if ((if meta_arg < 32: 1 else: 0)) != 0: ((1 << meta_arg)) else: 1)
                            if (if meta_arg > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = meta_arg)
                        2147680256 =>
                            if (if meta_arg < 10: 1 else: 0) != 0:
                                (offset = (&cb.small_ref_offset[0] as *mut c_ulong)[meta_arg])
                            else:
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            0
                            if (if meta_arg > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = (4294967294 as c_uint))
                                (zerofirstcuflags = firstcuflags)
                            (unsafe: *code = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_REFI else: OP_REF))
                            (code = code + 1)
                            if (if ((options & 8)) != 0: 1 else: 0) != 0:
                                (unsafe: *code = (((if ((if ((xoptions & 128)) != 0: 1 else: 0)) != 0: 1 else: 0)) | ((if ((if ((xoptions & 65536)) != 0: 1 else: 0)) != 0: 2 else: 0))))
                                (code = code + 1)
                            cb.backref_map = cb.backref_map | (if ((if meta_arg < 32: 1 else: 0)) != 0: ((1 << meta_arg)) else: 1)
                            if (if meta_arg > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = meta_arg)
                        2149842944 =>
                            pptr = pptr + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            if (if meta_arg > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *code) = 118)
                            code = code + (1 + 2)
                            (length_prevgroup = 3)
                            (groupsetfirstcu = 0)
                            (cb.had_recurse = 1)
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = (4294967294 as c_uint))
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                        2148007936 =>
                            (bravalue = OP_CBRA)
                            (skipunits = 2)
                            (cb.lastcapture = meta_arg)
                            __pc = 3
                            __goto_pending = 1
                            if (if (if meta_arg > 5: 1 else: 0) != 0 and (if meta_arg < 23: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            if (if (if (if cb.assert_depth > 0: 1 else: 0) != 0 and (if meta_arg == 3: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((xoptions & 64)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR99)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta_arg
                                14 =>
                                    cb.external_flags = cb.external_flags | 4194304
                                    if (if utf != 0: 0 else: 1) != 0:
                                        (meta_arg = 13)
                                4 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                1 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                3 =>
                                    cb.external_flags = cb.external_flags | 16777216
                                _ => 0
                            (unsafe: *code = meta_arg)
                            (code = code + 1)
                        2149318656 =>
                            if (if (if meta_arg > 5: 1 else: 0) != 0 and (if meta_arg < 23: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            if (if (if (if cb.assert_depth > 0: 1 else: 0) != 0 and (if meta_arg == 3: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((xoptions & 64)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR99)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta_arg
                                14 =>
                                    cb.external_flags = cb.external_flags | 4194304
                                    if (if utf != 0: 0 else: 1) != 0:
                                        (meta_arg = 13)
                                4 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                1 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                3 =>
                                    cb.external_flags = cb.external_flags | 16777216
                                _ => 0
                            (unsafe: *code = meta_arg)
                            (code = code + 1)
                        _ =>
                            if (if meta >= 2147483648: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR89)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (meta = (unsafe: *pptr))
                            (matched_char = 1)
                            (mclength = 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            ((&mcbuffer[0] as *mut u8)[0] = meta)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (unsafe: *code = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_CHARI else: OP_CHAR))
                            (code = code + 1)
                            code = code + mclength
                            if (if (if (&mcbuffer[0] as *mut u8)[0] == 13: 1 else: 0) != 0 or (if (&mcbuffer[0] as *mut u8)[0] == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.external_flags = cb.external_flags | 2048
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (zerofirstcuflags = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcu = reqcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcuflags = reqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if mclength == 1: 1 else: 0) != 0 or (if req_caseopt == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (firstcu = (&mcbuffer[0] as *mut u8)[0])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (firstcuflags = req_caseopt)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength != 1: 1 else: 0) != 0:
                                        (reqcu = code[-1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    (reqcuflags = (4294967294 as c_uint))
                                    (firstcuflags = reqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (zerofirstcu = firstcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zerofirstcuflags = firstcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcu = reqcu)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcuflags = reqcuflags)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if mclength == 1: 1 else: 0) != 0 or (if req_caseopt == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = code[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags = (req_caseopt | cb.req_varyopt))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if reset_caseful != 0:
                                options = options & (0 - 8 - 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (req_caseopt = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reset_caseful = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn is_anchored(__param_code: *const u8, bracket_map: c_uint, cb: *mut compile_block_8, atomcount: c_int, inassert: c_int, dotstar_anchor: c_int) -> c_int:
    var code = __param_code
    while true:
        var scode: *const u8 = first_significant_code((code + (_pcre2_OP_lengths_8[(unsafe: *code)] as isize as usize)), 0)
        var op: c_int = (unsafe: *scode)
        if (if (if (if (if op == OP_BRA: 1 else: 0) != 0 or (if op == OP_BRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
            if (if is_anchored(scode, bracket_map, cb, atomcount, inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                return 0
            
        else:
            if (if (if (if (if op == OP_CBRA: 1 else: 0) != 0 or (if op == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                var n: c_int
                var new_map: c_uint = (bracket_map | ((if ((if n < 32: 1 else: 0)) != 0: ((1 << n)) else: 1)))
                if (if is_anchored(scode, new_map, cb, atomcount, inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                    return 0
                
            else:
                if (if (if op == OP_ASSERT: 1 else: 0) != 0 or (if op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if is_anchored(scode, bracket_map, cb, atomcount, 1, dotstar_anchor) != 0: 0 else: 1) != 0:
                        return 0
                    
                else:
                    if (if (if op == OP_COND: 1 else: 0) != 0 or (if op == OP_SCOND: 1 else: 0) != 0: 1 else: 0) != 0:
                        if (if is_anchored(scode, bracket_map, cb, atomcount, inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                            return 0
                        
                    else:
                        if (if op == OP_ONCE: 1 else: 0) != 0:
                            if (if is_anchored(scode, bracket_map, cb, (atomcount + 1), inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                                return 0
                            
                        else:
                            if ((if (if (if op == OP_TYPESTAR: 1 else: 0) != 0 or (if op == OP_TYPEMINSTAR: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_TYPEPOSSTAR: 1 else: 0) != 0: 1 else: 0)) != 0:
                                if (if (if (if (if (if (if scode[1] != OP_ALLANY: 1 else: 0) != 0 or (if ((bracket_map & cb.backref_map)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 or (if atomcount > 0: 1 else: 0) != 0: 1 else: 0) != 0 or cb.had_pruneorskip != 0: 1 else: 0) != 0 or inassert != 0: 1 else: 0) != 0 or (if dotstar_anchor != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                    return 0
                                
                            else:
                                if (if (if (if op != OP_SOD: 1 else: 0) != 0 and (if op != OP_SOM: 1 else: 0) != 0: 1 else: 0) != 0 and (if op != OP_CIRC: 1 else: 0) != 0: 1 else: 0) != 0:
                                    return 0
        
        if not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0):
            break

    return 1

fn is_startline(__param_code: *const u8, bracket_map: c_uint, cb: *mut compile_block_8, atomcount: c_int, inassert: c_int, dotstar_anchor: c_int) -> c_int:
    var code = __param_code
    while true:
        var scode: *const u8 = first_significant_code((code + (_pcre2_OP_lengths_8[(unsafe: *code)] as isize as usize)), 0)
        var op: c_int = (unsafe: *scode)
        if (if op == OP_COND: 1 else: 0) != 0:
            scode = scode + (1 + 2)
            if (if (unsafe: *scode) == OP_CALLOUT: 1 else: 0) != 0:
                scode = scode + _pcre2_OP_lengths_8[OP_CALLOUT]
            
            match (unsafe: *scode)
                OP_CREF =>
                    if (if is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor) != 0: 0 else: 1) != 0:
                        return 0
                    scode = scode + (1 + 2)
                _ =>
                    if (if is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor) != 0: 0 else: 1) != 0:
                        return 0
                    scode = scode + (1 + 2)
            
            (scode = first_significant_code(scode, 0))
            (op = (unsafe: *scode))
        
        if (if (if (if (if op == OP_BRA: 1 else: 0) != 0 or (if op == OP_BRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
            if (if is_startline(scode, bracket_map, cb, atomcount, inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                return 0
            
        else:
            if (if (if (if (if op == OP_CBRA: 1 else: 0) != 0 or (if op == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                var n: c_int
                var new_map: c_uint = (bracket_map | ((if ((if n < 32: 1 else: 0)) != 0: ((1 << n)) else: 1)))
                if (if is_startline(scode, new_map, cb, atomcount, inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                    return 0
                
            else:
                if (if (if op == OP_ASSERT: 1 else: 0) != 0 or (if op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor) != 0: 0 else: 1) != 0:
                        return 0
                    
                else:
                    if (if op == OP_ONCE: 1 else: 0) != 0:
                        if (if is_startline(scode, bracket_map, cb, (atomcount + 1), inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                            return 0
                        
                    else:
                        if (if (if (if op == OP_TYPESTAR: 1 else: 0) != 0 or (if op == OP_TYPEMINSTAR: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_TYPEPOSSTAR: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (if (if (if (if (if scode[1] != OP_ANY: 1 else: 0) != 0 or (if ((bracket_map & cb.backref_map)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 or (if atomcount > 0: 1 else: 0) != 0: 1 else: 0) != 0 or cb.had_pruneorskip != 0: 1 else: 0) != 0 or inassert != 0: 1 else: 0) != 0 or (if dotstar_anchor != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                return 0
                            
                        else:
                            if (if (if op != OP_CIRC: 1 else: 0) != 0 and (if op != OP_CIRCM: 1 else: 0) != 0: 1 else: 0) != 0:
                                return 0
        
        if not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0):
            break

    return 1

fn find_recurse(__param_code: *mut u8, utf: c_int) -> *mut u8:
    var code = __param_code
    while true:
        var c: u8 = (unsafe: *code)
        if (if c == OP_END: 1 else: 0) != 0:
            return (null as *mut u8)
        
        if (if c == OP_RECURSE: 1 else: 0) != 0:
            return code
        


fn find_firstassertedcu(__param_code: *const u8, flags: *mut c_uint, inassert: c_uint) -> c_uint:
    var code = __param_code
    var c: c_uint = 0
    var cflags: c_uint = 4294967294
    ((unsafe: *flags) = (4294967294 as c_uint))
    while true:
        var d: c_uint
        var dflags: c_uint
        var xl: c_int = (if ((if (if (if (if (unsafe: *code) == OP_CBRA: 1 else: 0) != 0 or (if (unsafe: *code) == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *code) == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *code) == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)
        var scode: *const u8 = first_significant_code((((code + (1 as isize as usize)) + (2 as isize as usize)) + (xl as isize as usize)), 1)
        var op: u8 = (unsafe: *scode)
        match op
            OP_BRA =>
                if (if dflags >= 4294967294: 1 else: 0) != 0:
                    return 0
                if (if cflags >= 4294967294: 1 else: 0) != 0:
                    (c = d)
                    (cflags = dflags)
                else:
                    if (if (if c != d: 1 else: 0) != 0 or (if cflags != dflags: 1 else: 0) != 0: 1 else: 0) != 0:
                        return 0
            OP_EXACT =>
                scode = scode + 2
                if (if cflags >= 4294967294: 1 else: 0) != 0:
                    (c = scode[1])
                    (cflags = 0)
                else:
                    if (if c != scode[1]: 1 else: 0) != 0:
                        return 0
            OP_CHAR =>
                if (if cflags >= 4294967294: 1 else: 0) != 0:
                    (c = scode[1])
                    (cflags = 0)
                else:
                    if (if c != scode[1]: 1 else: 0) != 0:
                        return 0
            OP_EXACTI =>
                scode = scode + 2
                if (if cflags >= 4294967294: 1 else: 0) != 0:
                    (c = scode[1])
                    (cflags = 1)
                else:
                    if (if c != scode[1]: 1 else: 0) != 0:
                        return 0
            OP_CHARI =>
                if (if cflags >= 4294967294: 1 else: 0) != 0:
                    (c = scode[1])
                    (cflags = 1)
                else:
                    if (if c != scode[1]: 1 else: 0) != 0:
                        return 0
            _ =>
                return 0
        
        if not ((if (unsafe: *code) == OP_ALT: 1 else: 0) != 0):
            break

    ((unsafe: *flags) = cflags)
    return c

fn parsed_skip(__param_pptr: *mut c_uint, skiptype: c_uint) -> *mut c_uint:
    var pptr = __param_pptr
    var nestlevel: c_uint = 0
    while (pptr = pptr + 1) != null:
        var meta: c_uint
        match meta
            2147483648 =>
                return (null as *mut c_uint)
            2147680256 => 0
            2149318656 =>
                if (if (if ((unsafe: *pptr) -% (2149318656 as c_uint)) == 15: 1 else: 0) != 0 or (if ((unsafe: *pptr) -% (2149318656 as c_uint)) == 16: 1 else: 0) != 0: 1 else: 0) != 0:
                    pptr = pptr + 1
            2150432768 => 0
            2148335616 =>
                if (if skiptype == 1: 1 else: 0) != 0:
                    return pptr
            2147614720 => 0
            2147549184 =>
                if (if (if nestlevel == 0: 1 else: 0) != 0 and (if skiptype == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    return pptr
            2149384192 =>
                if (if nestlevel == 0: 1 else: 0) != 0:
                    return pptr
                (nestlevel = nestlevel - 1)
            _ =>
                if (if meta < 2147483648: 1 else: 0) != 0:
                    continue
        
        (meta = (((meta >> 16)) & 32767))
        if (if meta >= (73 * sizeof[u8]()): 1 else: 0) != 0:
            return (null as *mut c_uint)
        
        pptr = pptr + (&meta_extra_lengths[0] as *mut u8)[meta]


fn get_grouplength(pptrptr: *mut *mut c_uint, minptr: *mut c_int, isinline: c_int, errcodeptr: *mut c_int, lcptr: *mut c_int, group: c_int, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8) -> c_int:
    var gi: *mut c_uint = null
    var branchlength: c_int = 0
    var branchminlength: c_int = 0
    var grouplength: c_int = 0
    var groupminlength: c_int = 0
    var groupinfo: c_uint = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                gi = (cb.groupinfo + ((2 * group) as isize as usize))
                grouplength = -1
                groupminlength = 2147483647
                if (if (if group > 0: 1 else: 0) != 0 and (if ((cb.external_flags & 2097152)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    groupinfo = gi[0]
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if ((groupinfo & 1073741824)) != 0: 1 else: 0) != 0:
                        return -1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if ((groupinfo & (2147483648 as c_uint))) != 0: 1 else: 0) != 0:
                        if isinline != 0:
                            ((unsafe: *pptrptr) = parsed_skip((unsafe: *pptrptr), 2))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        ((unsafe: *minptr) = gi[1])
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        return (groupinfo & 65535)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while true:
                    (branchlength = get_branchlength(pptrptr, (&mut branchminlength as *mut c_int), errcodeptr, lcptr, recurses, cb))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if branchlength < 0: 1 else: 0) != 0:
                        __pc = 1
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if branchlength > grouplength: 1 else: 0) != 0:
                        (grouplength = branchlength)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if branchminlength < groupminlength: 1 else: 0) != 0:
                        (groupminlength = branchminlength)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (unsafe: *(unsafe: *pptrptr)) == 2149384192: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (unsafe: *pptrptr) = (unsafe: *pptrptr) + 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if group > 0: 1 else: 0) != 0:
                    (gi[1] = groupminlength)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *minptr) = groupminlength)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return grouplength
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // ISNOTFIXED
                (__goto_pending = 0)
                if (if group > 0: 1 else: 0) != 0:
                    gi[0] = gi[0] | 1073741824
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return -1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

// untranslatable fn-like macro
fn BYTES2CU() -> Never:
    comptime_error("untranslatable C macro: BYTES2CU")
// untranslatable fn-like macro
fn CAST_USER_ADDR_T() -> Never:
    comptime_error("untranslatable C macro: CAST_USER_ADDR_T")
// untranslatable fn-like macro
fn CHMAX_255() -> Never:
    comptime_error("untranslatable C macro: CHMAX_255")
// untranslatable fn-like macro
fn CLIST_ALIGN_TO() -> Never:
    comptime_error("untranslatable C macro: CLIST_ALIGN_TO")
// untranslatable fn-like macro
fn CU2BYTES() -> Never:
    comptime_error("untranslatable C macro: CU2BYTES")
let ESCAPES_FIRST: c_int = 48
let ESCAPES_LAST: c_int = 122
// untranslatable fn-like macro
fn GET() -> Never:
    comptime_error("untranslatable C macro: GET")
// untranslatable fn-like macro
fn GET2() -> Never:
    comptime_error("untranslatable C macro: GET2")
// untranslatable fn-like macro
fn GETCHAR() -> Never:
    comptime_error("untranslatable C macro: GETCHAR")
// untranslatable fn-like macro
fn GETCHARINC() -> Never:
    comptime_error("untranslatable C macro: GETCHARINC")
// untranslatable fn-like macro
fn GETCHARINCTEST() -> Never:
    comptime_error("untranslatable C macro: GETCHARINCTEST")
// untranslatable fn-like macro
fn GETCHARLEN() -> Never:
    comptime_error("untranslatable C macro: GETCHARLEN")
// untranslatable fn-like macro
fn GETCHARTEST() -> Never:
    comptime_error("untranslatable C macro: GETCHARTEST")
// untranslatable fn-like macro
fn GETOFFSET() -> Never:
    comptime_error("untranslatable C macro: GETOFFSET")
// untranslatable fn-like macro
fn GETPLUSOFFSET() -> Never:
    comptime_error("untranslatable C macro: GETPLUSOFFSET")
// untranslatable fn-like macro
fn GETUTF8() -> Never:
    comptime_error("untranslatable C macro: GETUTF8")
// untranslatable fn-like macro
fn GETUTF8INC() -> Never:
    comptime_error("untranslatable C macro: GETUTF8INC")
// untranslatable fn-like macro
fn GETUTF8LEN() -> Never:
    comptime_error("untranslatable C macro: GETUTF8LEN")
// untranslatable fn-like macro
fn GET_MAX_CHAR_VALUE() -> Never:
    comptime_error("untranslatable C macro: GET_MAX_CHAR_VALUE")
// untranslatable fn-like macro
fn GET_UCD() -> Never:
    comptime_error("untranslatable C macro: GET_UCD")
let GI_FIXED_LENGTH_MASK: c_uint = 0x0000ffff
let GI_NOT_FIXED_LENGTH: c_uint = 0x40000000
let GI_SET_FIXED_LENGTH: c_uint = 0x80000000
let GROUPINFO_DEFAULT_SIZE: c_int = 256
fn HASUTF8EXTRALEN[T](c: T) -> T:
    (c >= 0xc0)
// untranslatable fn-like macro
fn HTONL() -> Never:
    comptime_error("untranslatable C macro: HTONL")
// untranslatable fn-like macro
fn HTONLL() -> Never:
    comptime_error("untranslatable C macro: HTONLL")
// untranslatable fn-like macro
fn HTONS() -> Never:
    comptime_error("untranslatable C macro: HTONS")
fn INT16_C[T](v: T) -> T:
    v
fn INT32_C[T](v: T) -> T:
    v
fn INT64_C[T](v: T) -> i64:
    (v as i64)
fn INT8_C[T](v: T) -> T:
    v
fn INTMAX_C[T](v: T) -> i64:
    (v as i64)
fn IS_DIGIT[T](x: T) -> T:
    ((x >= CHAR_0) and (x <= CHAR_9))
// untranslatable fn-like macro
fn IS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: IS_NEWLINE")
// untranslatable fn-like macro
fn MAPBIT() -> Never:
    comptime_error("untranslatable C macro: MAPBIT")
// untranslatable fn-like macro
fn MAPSET() -> Never:
    comptime_error("untranslatable C macro: MAPSET")
// untranslatable fn-like macro
fn MAX_255() -> Never:
    comptime_error("untranslatable C macro: MAX_255")
let MAX_GROUP_NUMBER: c_uint = 65535
let MAX_REPEAT_COUNT: c_uint = 65535
fn META_CODE[T](x: T) -> T:
    (x & 0xffff0000)
fn META_DATA[T](x: T) -> T:
    (x & 0x0000ffff)
// untranslatable fn-like macro
fn META_DIFF() -> Never:
    comptime_error("untranslatable C macro: META_DIFF")
// untranslatable fn-like macro
fn NAMED_GROUP_GET_HASH() -> Never:
    comptime_error("untranslatable C macro: NAMED_GROUP_GET_HASH")
let NAMED_GROUP_LIST_SIZE: c_int = 20
let NSF_ATOMICSR: c_uint = 0x0004
let NSF_CONDASSERT: c_uint = 0x0002
let NSF_RESET: c_uint = 0x0001
// untranslatable fn-like macro
fn NTOHL() -> Never:
    comptime_error("untranslatable C macro: NTOHL")
// untranslatable fn-like macro
fn NTOHLL() -> Never:
    comptime_error("untranslatable C macro: NTOHLL")
// untranslatable fn-like macro
fn NTOHS() -> Never:
    comptime_error("untranslatable C macro: NTOHS")
let OFLOW_MAX: c_int = 2147483627
// untranslatable fn-like macro
fn PARSED_LITERAL() -> Never:
    comptime_error("untranslatable C macro: PARSED_LITERAL")
let PARSED_PATTERN_DEFAULT_SIZE: c_int = 1024
// untranslatable fn-like macro
fn PCRE2_ASSERT() -> Never:
    comptime_error("untranslatable C macro: PCRE2_ASSERT")
// untranslatable fn-like macro
fn PCRE2_DEBUG_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_DEBUG_UNREACHABLE")
// untranslatable fn-like macro
fn PCRE2_GLUE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_GLUE")
// untranslatable fn-like macro
fn PCRE2_JOIN() -> Never:
    comptime_error("untranslatable C macro: PCRE2_JOIN")
fn PCRE2_SUFFIX[T](a: T) -> T:
    PCRE2_GLUE(a, PCRE2_CODE_UNIT_WIDTH)
// untranslatable fn-like macro
fn PCRE2_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_UNREACHABLE")
// untranslatable fn-like macro
fn PRIV() -> Never:
    comptime_error("untranslatable C macro: PRIV")
let PUBLIC_LITERAL_COMPILE_EXTRA_OPTIONS: c_int = 65676
let PUBLIC_LITERAL_COMPILE_OPTIONS: c_int = 2147483644
// untranslatable fn-like macro
fn PUT() -> Never:
    comptime_error("untranslatable C macro: PUT")
// untranslatable fn-like macro
fn PUT2() -> Never:
    comptime_error("untranslatable C macro: PUT2")
// untranslatable fn-like macro
fn PUT2INC() -> Never:
    comptime_error("untranslatable C macro: PUT2INC")
// untranslatable fn-like macro
fn PUTCHAR() -> Never:
    comptime_error("untranslatable C macro: PUTCHAR")
// untranslatable fn-like macro
fn PUTINC() -> Never:
    comptime_error("untranslatable C macro: PUTINC")
// untranslatable fn-like macro
fn PUTOFFSET() -> Never:
    comptime_error("untranslatable C macro: PUTOFFSET")
// untranslatable fn-like macro
fn READPLUSOFFSET() -> Never:
    comptime_error("untranslatable C macro: READPLUSOFFSET")
// untranslatable fn-like macro
fn REAL_GET_UCD() -> Never:
    comptime_error("untranslatable C macro: REAL_GET_UCD")
let REPEAT_UNLIMITED: c_int = 65536
let REQ_CASELESS: c_uint = 0x00000001
let REQ_NONE: c_uint = 0xfffffffe
let REQ_UNSET: c_uint = 0xffffffff
let REQ_VARY: c_uint = 0x00000002
let RSCAN_CACHE_SIZE: c_int = 8
fn SELECT_VALUE8[T](value8: T, value: T) -> T:
    value8
// untranslatable fn-like macro
fn SETBIT() -> Never:
    comptime_error("untranslatable C macro: SETBIT")
// untranslatable fn-like macro
fn SKIPOFFSET() -> Never:
    comptime_error("untranslatable C macro: SKIPOFFSET")
// untranslatable fn-like macro
fn STATIC_ASSERT() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT")
// untranslatable fn-like macro
fn STATIC_ASSERT_JOIN() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT_JOIN")
// untranslatable fn-like macro
fn TABLE_GET() -> Never:
    comptime_error("untranslatable C macro: TABLE_GET")
// untranslatable fn-like macro
fn UCD_ANY_I() -> Never:
    comptime_error("untranslatable C macro: UCD_ANY_I")
// untranslatable fn-like macro
fn UCD_BIDICLASS() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS")
// untranslatable fn-like macro
fn UCD_BIDICLASS_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS_PROP")
// untranslatable fn-like macro
fn UCD_BPROPS() -> Never:
    comptime_error("untranslatable C macro: UCD_BPROPS")
// untranslatable fn-like macro
fn UCD_BPROPS_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_BPROPS_PROP")
// untranslatable fn-like macro
fn UCD_CASESET() -> Never:
    comptime_error("untranslatable C macro: UCD_CASESET")
// untranslatable fn-like macro
fn UCD_CATEGORY() -> Never:
    comptime_error("untranslatable C macro: UCD_CATEGORY")
// untranslatable fn-like macro
fn UCD_CHARTYPE() -> Never:
    comptime_error("untranslatable C macro: UCD_CHARTYPE")
fn UCD_DOTTED_I[T](ch: T) -> T:
    (((ch as c_int) == 0x69) or ((ch as c_int) == 0x0130))
fn UCD_FOLD_I_TURKISH[T](ch: T) -> T:
    (if ((ch as c_int) == 0x0130): 0x69 else: (if ((ch as c_int) == 0x49): 0x0131 else: (ch as c_int)))
// untranslatable fn-like macro
fn UCD_GRAPHBREAK() -> Never:
    comptime_error("untranslatable C macro: UCD_GRAPHBREAK")
// untranslatable fn-like macro
fn UCD_OTHERCASE() -> Never:
    comptime_error("untranslatable C macro: UCD_OTHERCASE")
// untranslatable fn-like macro
fn UCD_SCRIPT() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPT")
// untranslatable fn-like macro
fn UCD_SCRIPTX() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPTX")
// untranslatable fn-like macro
fn UCD_SCRIPTX_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPTX_PROP")
fn UINT16_C[T](v: T) -> T:
    v
fn UINT32_C[T](v: T) -> u32:
    (v as u32)
fn UINT64_C[T](v: T) -> u64:
    (v as u64)
fn UINT8_C[T](v: T) -> T:
    v
fn UINTMAX_C[T](v: T) -> u64:
    (v as u64)
fn UPPER_CASE[T](c: T) -> T:
    (c - 32)
// untranslatable fn-like macro
fn WAS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: WAS_NEWLINE")
// untranslatable fn-like macro
fn WCOREDUMP() -> Never:
    comptime_error("untranslatable C macro: WCOREDUMP")
// untranslatable fn-like macro
fn WEXITSTATUS() -> Never:
    comptime_error("untranslatable C macro: WEXITSTATUS")
// untranslatable fn-like macro
fn WIFCONTINUED() -> Never:
    comptime_error("untranslatable C macro: WIFCONTINUED")
// untranslatable fn-like macro
fn WIFEXITED() -> Never:
    comptime_error("untranslatable C macro: WIFEXITED")
// untranslatable fn-like macro
fn WIFSIGNALED() -> Never:
    comptime_error("untranslatable C macro: WIFSIGNALED")
// untranslatable fn-like macro
fn WIFSTOPPED() -> Never:
    comptime_error("untranslatable C macro: WIFSTOPPED")
let WORK_SIZE_SAFETY_MARGIN: c_int = 100
// untranslatable fn-like macro
fn WSTOPSIG() -> Never:
    comptime_error("untranslatable C macro: WSTOPSIG")
// untranslatable fn-like macro
fn WTERMSIG() -> Never:
    comptime_error("untranslatable C macro: WTERMSIG")
fn W_EXITCODE[T](ret: T, sig: T) -> T:
    ((ret << 8) | sig)
// untranslatable fn-like macro
fn W_STOPCODE() -> Never:
    comptime_error("untranslatable C macro: W_STOPCODE")
fn XDIGIT[T](c: T) -> T:
    xdigitab[c]
// untranslatable fn-like macro
fn alloca() -> Never:
    comptime_error("untranslatable C macro: alloca")
// untranslatable fn-like macro
fn clearerr_unlocked() -> Never:
    comptime_error("untranslatable C macro: clearerr_unlocked")
// untranslatable fn-like macro
fn feof_unlocked() -> Never:
    comptime_error("untranslatable C macro: feof_unlocked")
// untranslatable fn-like macro
fn ferror_unlocked() -> Never:
    comptime_error("untranslatable C macro: ferror_unlocked")
// untranslatable fn-like macro
fn fileno_unlocked() -> Never:
    comptime_error("untranslatable C macro: fileno_unlocked")
// untranslatable fn-like macro
fn fropen() -> Never:
    comptime_error("untranslatable C macro: fropen")
// untranslatable fn-like macro
fn fwopen() -> Never:
    comptime_error("untranslatable C macro: fwopen")
// untranslatable fn-like macro
fn getc_unlocked() -> Never:
    comptime_error("untranslatable C macro: getc_unlocked")
// untranslatable fn-like macro
fn getchar_unlocked() -> Never:
    comptime_error("untranslatable C macro: getchar_unlocked")
// untranslatable fn-like macro
fn htonl() -> Never:
    comptime_error("untranslatable C macro: htonl")
// untranslatable fn-like macro
fn htonll() -> Never:
    comptime_error("untranslatable C macro: htonll")
// untranslatable fn-like macro
fn htons() -> Never:
    comptime_error("untranslatable C macro: htons")
fn memccpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn memcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn memmove() -> Never:
    comptime_error("variadic macro — use direct call")
fn memset() -> Never:
    comptime_error("variadic macro — use direct call")
// untranslatable fn-like macro
fn ntohl() -> Never:
    comptime_error("untranslatable C macro: ntohl")
// untranslatable fn-like macro
fn ntohll() -> Never:
    comptime_error("untranslatable C macro: ntohll")
// untranslatable fn-like macro
fn ntohs() -> Never:
    comptime_error("untranslatable C macro: ntohs")
// untranslatable fn-like macro
fn offsetof() -> Never:
    comptime_error("untranslatable C macro: offsetof")
// untranslatable fn-like macro
fn putc_unlocked() -> Never:
    comptime_error("untranslatable C macro: putc_unlocked")
// untranslatable fn-like macro
fn putchar_unlocked() -> Never:
    comptime_error("untranslatable C macro: putchar_unlocked")
// untranslatable fn-like macro
fn sigmask() -> Never:
    comptime_error("untranslatable C macro: sigmask")
fn snprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn sprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn stpcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn stpncpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strcat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strlcat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strlcpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn strncat() -> Never:
    comptime_error("variadic macro — use direct call")
fn strncpy() -> Never:
    comptime_error("variadic macro — use direct call")
fn vsnprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn vsprintf() -> Never:
    comptime_error("variadic macro — use direct call")
