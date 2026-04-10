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
@[c_export("pcre2_compile_8")]
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
                newline = 0
                bsr = 0
                errorcode = 0
                if (if errorptr == (null as *mut c_int): 1 else: 0) != 0:
                    if (if erroroffset != (null as *mut c_ulong): 1 else: 0) != 0:
                        (unsafe: *erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return (null as *mut pcre2_real_code_8)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if erroroffset == (null as *mut c_ulong): 1 else: 0) != 0:
                    if (if errorptr != (null as *mut c_int): 1 else: 0) != 0:
                        (unsafe: *errorptr = ERR120)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return (null as *mut pcre2_real_code_8)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *errorptr = ERR0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *erroroffset = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if pattern == (null as *const u8): 1 else: 0) != 0:
                    if (if patlen == 0: 1 else: 0) != 0:
                        (pattern = ((&null_str[0] as *mut u8) as *const u8))
                    else:
                        (unsafe: *errorptr = ERR16)
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
                    (unsafe: *errorptr = ERR88)
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
                    if (if heap_parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                        (unsafe: *errorptr = ERR21)
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
                (unsafe: *code = 137)
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
                (unsafe: *code = 137)
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
                (unsafe: *erroroffset = ((ptr as usize -% pattern as usize) / sizeof[u8]()))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 4
                continue
            4 =>  // HAD_ERROR
                (__goto_pending = 0)
                (unsafe: *errorptr = errorcode)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                pcre2_code_free_8(re)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re = (null as *mut pcre2_real_code_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb.first_data != (null as *mut compile_data): 1 else: 0) != 0:
                    while true:
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

@[c_export("pcre2_code_free_8")]
fn pcre2_code_free_8(code: *mut pcre2_real_code_8):
    var ref_count: *mut c_ulong
    if (if code != (null as *mut pcre2_real_code_8): 1 else: 0) != 0:
        if (if ((code.flags & 262144)) != 0: 1 else: 0) != 0:
            if (if unsafe: *ref_count > 0: 1 else: 0) != 0:
                ((unsafe: *ref_count) = (unsafe: *ref_count) - 1)
                if (if unsafe: *ref_count == 0: 1 else: 0) != 0:
                    code.memctl.free((code.tables as *mut c_void), code.memctl.memory_data)
                
            
        
        code.memctl.free((code as *mut c_void), code.memctl.memory_data)


@[c_export("pcre2_code_copy_8")]
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
        ((unsafe: *ref_count) = (unsafe: *ref_count) + 1)

    return newcode

@[c_export("pcre2_code_copy_with_tables_8")]
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
    (unsafe: *ref_count = 1)
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
let ucp_C: c_uint = 0
let ucp_L: c_uint = 1
let ucp_M: c_uint = 2
let ucp_N: c_uint = 3
let ucp_P: c_uint = 4
let ucp_S: c_uint = 5
let ucp_Z: c_uint = 6
let ucp_Cc: c_uint = 0
let ucp_Cf: c_uint = 1
let ucp_Cn: c_uint = 2
let ucp_Co: c_uint = 3
let ucp_Cs: c_uint = 4
let ucp_Ll: c_uint = 5
let ucp_Lm: c_uint = 6
let ucp_Lo: c_uint = 7
let ucp_Lt: c_uint = 8
let ucp_Lu: c_uint = 9
let ucp_Mc: c_uint = 10
let ucp_Me: c_uint = 11
let ucp_Mn: c_uint = 12
let ucp_Nd: c_uint = 13
let ucp_Nl: c_uint = 14
let ucp_No: c_uint = 15
let ucp_Pc: c_uint = 16
let ucp_Pd: c_uint = 17
let ucp_Pe: c_uint = 18
let ucp_Pf: c_uint = 19
let ucp_Pi: c_uint = 20
let ucp_Po: c_uint = 21
let ucp_Ps: c_uint = 22
let ucp_Sc: c_uint = 23
let ucp_Sk: c_uint = 24
let ucp_Sm: c_uint = 25
let ucp_So: c_uint = 26
let ucp_Zl: c_uint = 27
let ucp_Zp: c_uint = 28
let ucp_Zs: c_uint = 29
let ucp_ASCII: c_uint = 0
let ucp_ASCII_Hex_Digit: c_uint = 1
let ucp_Alphabetic: c_uint = 2
let ucp_Bidi_Control: c_uint = 3
let ucp_Bidi_Mirrored: c_uint = 4
let ucp_Case_Ignorable: c_uint = 5
let ucp_Cased: c_uint = 6
let ucp_Changes_When_Casefolded: c_uint = 7
let ucp_Changes_When_Casemapped: c_uint = 8
let ucp_Changes_When_Lowercased: c_uint = 9
let ucp_Changes_When_Titlecased: c_uint = 10
let ucp_Changes_When_Uppercased: c_uint = 11
let ucp_Dash: c_uint = 12
let ucp_Default_Ignorable_Code_Point: c_uint = 13
let ucp_Deprecated: c_uint = 14
let ucp_Diacritic: c_uint = 15
let ucp_Emoji: c_uint = 16
let ucp_Emoji_Component: c_uint = 17
let ucp_Emoji_Modifier: c_uint = 18
let ucp_Emoji_Modifier_Base: c_uint = 19
let ucp_Emoji_Presentation: c_uint = 20
let ucp_Extended_Pictographic: c_uint = 21
let ucp_Extender: c_uint = 22
let ucp_Grapheme_Base: c_uint = 23
let ucp_Grapheme_Extend: c_uint = 24
let ucp_Grapheme_Link: c_uint = 25
let ucp_Hex_Digit: c_uint = 26
let ucp_IDS_Binary_Operator: c_uint = 27
let ucp_IDS_Trinary_Operator: c_uint = 28
let ucp_IDS_Unary_Operator: c_uint = 29
let ucp_ID_Compat_Math_Continue: c_uint = 30
let ucp_ID_Compat_Math_Start: c_uint = 31
let ucp_ID_Continue: c_uint = 32
let ucp_ID_Start: c_uint = 33
let ucp_Ideographic: c_uint = 34
let ucp_InCB: c_uint = 35
let ucp_Join_Control: c_uint = 36
let ucp_Logical_Order_Exception: c_uint = 37
let ucp_Lowercase: c_uint = 38
let ucp_Math: c_uint = 39
let ucp_Modifier_Combining_Mark: c_uint = 40
let ucp_Noncharacter_Code_Point: c_uint = 41
let ucp_Pattern_Syntax: c_uint = 42
let ucp_Pattern_White_Space: c_uint = 43
let ucp_Prepended_Concatenation_Mark: c_uint = 44
let ucp_Quotation_Mark: c_uint = 45
let ucp_Radical: c_uint = 46
let ucp_Regional_Indicator: c_uint = 47
let ucp_Sentence_Terminal: c_uint = 48
let ucp_Soft_Dotted: c_uint = 49
let ucp_Terminal_Punctuation: c_uint = 50
let ucp_Unified_Ideograph: c_uint = 51
let ucp_Uppercase: c_uint = 52
let ucp_Variation_Selector: c_uint = 53
let ucp_White_Space: c_uint = 54
let ucp_XID_Continue: c_uint = 55
let ucp_XID_Start: c_uint = 56
let ucp_Bprop_Count: c_uint = 57
let ucp_bidiAL: c_uint = 0
let ucp_bidiAN: c_uint = 1
let ucp_bidiB: c_uint = 2
let ucp_bidiBN: c_uint = 3
let ucp_bidiCS: c_uint = 4
let ucp_bidiEN: c_uint = 5
let ucp_bidiES: c_uint = 6
let ucp_bidiET: c_uint = 7
let ucp_bidiFSI: c_uint = 8
let ucp_bidiL: c_uint = 9
let ucp_bidiLRE: c_uint = 10
let ucp_bidiLRI: c_uint = 11
let ucp_bidiLRO: c_uint = 12
let ucp_bidiNSM: c_uint = 13
let ucp_bidiON: c_uint = 14
let ucp_bidiPDF: c_uint = 15
let ucp_bidiPDI: c_uint = 16
let ucp_bidiR: c_uint = 17
let ucp_bidiRLE: c_uint = 18
let ucp_bidiRLI: c_uint = 19
let ucp_bidiRLO: c_uint = 20
let ucp_bidiS: c_uint = 21
let ucp_bidiWS: c_uint = 22
let ucp_gbCR: c_uint = 0
let ucp_gbLF: c_uint = 1
let ucp_gbControl: c_uint = 2
let ucp_gbExtend: c_uint = 3
let ucp_gbPrepend: c_uint = 4
let ucp_gbSpacingMark: c_uint = 5
let ucp_gbL: c_uint = 6
let ucp_gbV: c_uint = 7
let ucp_gbT: c_uint = 8
let ucp_gbLV: c_uint = 9
let ucp_gbLVT: c_uint = 10
let ucp_gbRegional_Indicator: c_uint = 11
let ucp_gbOther: c_uint = 12
let ucp_gbZWJ: c_uint = 13
let ucp_gbExtended_Pictographic: c_uint = 14
let ucp_Latin: c_uint = 0
let ucp_Greek: c_uint = 1
let ucp_Cyrillic: c_uint = 2
let ucp_Armenian: c_uint = 3
let ucp_Hebrew: c_uint = 4
let ucp_Arabic: c_uint = 5
let ucp_Syriac: c_uint = 6
let ucp_Thaana: c_uint = 7
let ucp_Devanagari: c_uint = 8
let ucp_Bengali: c_uint = 9
let ucp_Gurmukhi: c_uint = 10
let ucp_Gujarati: c_uint = 11
let ucp_Oriya: c_uint = 12
let ucp_Tamil: c_uint = 13
let ucp_Telugu: c_uint = 14
let ucp_Kannada: c_uint = 15
let ucp_Malayalam: c_uint = 16
let ucp_Sinhala: c_uint = 17
let ucp_Thai: c_uint = 18
let ucp_Tibetan: c_uint = 19
let ucp_Myanmar: c_uint = 20
let ucp_Georgian: c_uint = 21
let ucp_Hangul: c_uint = 22
let ucp_Ethiopic: c_uint = 23
let ucp_Cherokee: c_uint = 24
let ucp_Runic: c_uint = 25
let ucp_Mongolian: c_uint = 26
let ucp_Hiragana: c_uint = 27
let ucp_Katakana: c_uint = 28
let ucp_Bopomofo: c_uint = 29
let ucp_Han: c_uint = 30
let ucp_Yi: c_uint = 31
let ucp_Gothic: c_uint = 32
let ucp_Tagalog: c_uint = 33
let ucp_Hanunoo: c_uint = 34
let ucp_Buhid: c_uint = 35
let ucp_Tagbanwa: c_uint = 36
let ucp_Limbu: c_uint = 37
let ucp_Tai_Le: c_uint = 38
let ucp_Linear_B: c_uint = 39
let ucp_Shavian: c_uint = 40
let ucp_Cypriot: c_uint = 41
let ucp_Buginese: c_uint = 42
let ucp_Coptic: c_uint = 43
let ucp_Glagolitic: c_uint = 44
let ucp_Tifinagh: c_uint = 45
let ucp_Syloti_Nagri: c_uint = 46
let ucp_Phags_Pa: c_uint = 47
let ucp_Nko: c_uint = 48
let ucp_Kayah_Li: c_uint = 49
let ucp_Lycian: c_uint = 50
let ucp_Carian: c_uint = 51
let ucp_Lydian: c_uint = 52
let ucp_Avestan: c_uint = 53
let ucp_Samaritan: c_uint = 54
let ucp_Lisu: c_uint = 55
let ucp_Javanese: c_uint = 56
let ucp_Old_Turkic: c_uint = 57
let ucp_Kaithi: c_uint = 58
let ucp_Mandaic: c_uint = 59
let ucp_Chakma: c_uint = 60
let ucp_Meroitic_Hieroglyphs: c_uint = 61
let ucp_Sharada: c_uint = 62
let ucp_Takri: c_uint = 63
let ucp_Caucasian_Albanian: c_uint = 64
let ucp_Duployan: c_uint = 65
let ucp_Elbasan: c_uint = 66
let ucp_Grantha: c_uint = 67
let ucp_Khojki: c_uint = 68
let ucp_Linear_A: c_uint = 69
let ucp_Mahajani: c_uint = 70
let ucp_Manichaean: c_uint = 71
let ucp_Modi: c_uint = 72
let ucp_Old_Permic: c_uint = 73
let ucp_Psalter_Pahlavi: c_uint = 74
let ucp_Khudawadi: c_uint = 75
let ucp_Tirhuta: c_uint = 76
let ucp_Multani: c_uint = 77
let ucp_Old_Hungarian: c_uint = 78
let ucp_Adlam: c_uint = 79
let ucp_Newa: c_uint = 80
let ucp_Osage: c_uint = 81
let ucp_Tangut: c_uint = 82
let ucp_Masaram_Gondi: c_uint = 83
let ucp_Dogra: c_uint = 84
let ucp_Gunjala_Gondi: c_uint = 85
let ucp_Hanifi_Rohingya: c_uint = 86
let ucp_Sogdian: c_uint = 87
let ucp_Nandinagari: c_uint = 88
let ucp_Yezidi: c_uint = 89
let ucp_Cypro_Minoan: c_uint = 90
let ucp_Old_Uyghur: c_uint = 91
let ucp_Toto: c_uint = 92
let ucp_Garay: c_uint = 93
let ucp_Gurung_Khema: c_uint = 94
let ucp_Ol_Onal: c_uint = 95
let ucp_Sunuwar: c_uint = 96
let ucp_Todhri: c_uint = 97
let ucp_Tulu_Tigalari: c_uint = 98
let ucp_Unknown: c_uint = 99
let ucp_Common: c_uint = 100
let ucp_Lao: c_uint = 101
let ucp_Canadian_Aboriginal: c_uint = 102
let ucp_Ogham: c_uint = 103
let ucp_Khmer: c_uint = 104
let ucp_Old_Italic: c_uint = 105
let ucp_Deseret: c_uint = 106
let ucp_Inherited: c_uint = 107
let ucp_Ugaritic: c_uint = 108
let ucp_Osmanya: c_uint = 109
let ucp_Braille: c_uint = 110
let ucp_New_Tai_Lue: c_uint = 111
let ucp_Old_Persian: c_uint = 112
let ucp_Kharoshthi: c_uint = 113
let ucp_Balinese: c_uint = 114
let ucp_Cuneiform: c_uint = 115
let ucp_Phoenician: c_uint = 116
let ucp_Sundanese: c_uint = 117
let ucp_Lepcha: c_uint = 118
let ucp_Ol_Chiki: c_uint = 119
let ucp_Vai: c_uint = 120
let ucp_Saurashtra: c_uint = 121
let ucp_Rejang: c_uint = 122
let ucp_Cham: c_uint = 123
let ucp_Tai_Tham: c_uint = 124
let ucp_Tai_Viet: c_uint = 125
let ucp_Egyptian_Hieroglyphs: c_uint = 126
let ucp_Bamum: c_uint = 127
let ucp_Meetei_Mayek: c_uint = 128
let ucp_Imperial_Aramaic: c_uint = 129
let ucp_Old_South_Arabian: c_uint = 130
let ucp_Inscriptional_Parthian: c_uint = 131
let ucp_Inscriptional_Pahlavi: c_uint = 132
let ucp_Batak: c_uint = 133
let ucp_Brahmi: c_uint = 134
let ucp_Meroitic_Cursive: c_uint = 135
let ucp_Miao: c_uint = 136
let ucp_Sora_Sompeng: c_uint = 137
let ucp_Bassa_Vah: c_uint = 138
let ucp_Pahawh_Hmong: c_uint = 139
let ucp_Mende_Kikakui: c_uint = 140
let ucp_Mro: c_uint = 141
let ucp_Old_North_Arabian: c_uint = 142
let ucp_Nabataean: c_uint = 143
let ucp_Palmyrene: c_uint = 144
let ucp_Pau_Cin_Hau: c_uint = 145
let ucp_Siddham: c_uint = 146
let ucp_Warang_Citi: c_uint = 147
let ucp_Ahom: c_uint = 148
let ucp_Anatolian_Hieroglyphs: c_uint = 149
let ucp_Hatran: c_uint = 150
let ucp_SignWriting: c_uint = 151
let ucp_Bhaiksuki: c_uint = 152
let ucp_Marchen: c_uint = 153
let ucp_Nushu: c_uint = 154
let ucp_Soyombo: c_uint = 155
let ucp_Zanabazar_Square: c_uint = 156
let ucp_Makasar: c_uint = 157
let ucp_Medefaidrin: c_uint = 158
let ucp_Old_Sogdian: c_uint = 159
let ucp_Elymaic: c_uint = 160
let ucp_Nyiakeng_Puachue_Hmong: c_uint = 161
let ucp_Wancho: c_uint = 162
let ucp_Chorasmian: c_uint = 163
let ucp_Dives_Akuru: c_uint = 164
let ucp_Khitan_Small_Script: c_uint = 165
let ucp_Tangsa: c_uint = 166
let ucp_Vithkuqi: c_uint = 167
let ucp_Kawi: c_uint = 168
let ucp_Nag_Mundari: c_uint = 169
let ucp_Kirat_Rai: c_uint = 170
let ucp_Sidetic: c_uint = 171
let ucp_Tai_Yo: c_uint = 172
let ucp_Tolong_Siki: c_uint = 173
let ucp_Beria_Erfe: c_uint = 174
let ucp_Script_Count: c_uint = 175
let PCRE2_MATCHEDBY_INTERPRETER: c_uint = 0
let PCRE2_MATCHEDBY_DFA_INTERPRETER: c_uint = 1
let PCRE2_MATCHEDBY_JIT: c_uint = 2
let ESC_A: c_uint = 1
let ESC_G: c_uint = 2
let ESC_K: c_uint = 3
let ESC_B: c_uint = 4
let ESC_b: c_uint = 5
let ESC_D: c_uint = 6
let ESC_d: c_uint = 7
let ESC_S: c_uint = 8
let ESC_s: c_uint = 9
let ESC_W: c_uint = 10
let ESC_w: c_uint = 11
let ESC_N: c_uint = 12
let ESC_dum: c_uint = 13
let ESC_C: c_uint = 14
let ESC_P: c_uint = 15
let ESC_p: c_uint = 16
let ESC_R: c_uint = 17
let ESC_H: c_uint = 18
let ESC_h: c_uint = 19
let ESC_V: c_uint = 20
let ESC_v: c_uint = 21
let ESC_X: c_uint = 22
let ESC_Z: c_uint = 23
let ESC_z: c_uint = 24
let ESC_E: c_uint = 25
let ESC_Q: c_uint = 26
let ESC_g: c_uint = 27
let ESC_k: c_uint = 28
let ESC_ub: c_uint = 29
let OP_END: c_uint = 0
let OP_SOD: c_uint = 1
let OP_SOM: c_uint = 2
let OP_SET_SOM: c_uint = 3
let OP_NOT_WORD_BOUNDARY: c_uint = 4
let OP_WORD_BOUNDARY: c_uint = 5
let OP_NOT_DIGIT: c_uint = 6
let OP_DIGIT: c_uint = 7
let OP_NOT_WHITESPACE: c_uint = 8
let OP_WHITESPACE: c_uint = 9
let OP_NOT_WORDCHAR: c_uint = 10
let OP_WORDCHAR: c_uint = 11
let OP_ANY: c_uint = 12
let OP_ALLANY: c_uint = 13
let OP_ANYBYTE: c_uint = 14
let OP_NOTPROP: c_uint = 15
let OP_PROP: c_uint = 16
let OP_ANYNL: c_uint = 17
let OP_NOT_HSPACE: c_uint = 18
let OP_HSPACE: c_uint = 19
let OP_NOT_VSPACE: c_uint = 20
let OP_VSPACE: c_uint = 21
let OP_EXTUNI: c_uint = 22
let OP_EODN: c_uint = 23
let OP_EOD: c_uint = 24
let OP_DOLL: c_uint = 25
let OP_DOLLM: c_uint = 26
let OP_CIRC: c_uint = 27
let OP_CIRCM: c_uint = 28
let OP_CHAR: c_uint = 29
let OP_CHARI: c_uint = 30
let OP_NOT: c_uint = 31
let OP_NOTI: c_uint = 32
let OP_STAR: c_uint = 33
let OP_MINSTAR: c_uint = 34
let OP_PLUS: c_uint = 35
let OP_MINPLUS: c_uint = 36
let OP_QUERY: c_uint = 37
let OP_MINQUERY: c_uint = 38
let OP_UPTO: c_uint = 39
let OP_MINUPTO: c_uint = 40
let OP_EXACT: c_uint = 41
let OP_POSSTAR: c_uint = 42
let OP_POSPLUS: c_uint = 43
let OP_POSQUERY: c_uint = 44
let OP_POSUPTO: c_uint = 45
let OP_STARI: c_uint = 46
let OP_MINSTARI: c_uint = 47
let OP_PLUSI: c_uint = 48
let OP_MINPLUSI: c_uint = 49
let OP_QUERYI: c_uint = 50
let OP_MINQUERYI: c_uint = 51
let OP_UPTOI: c_uint = 52
let OP_MINUPTOI: c_uint = 53
let OP_EXACTI: c_uint = 54
let OP_POSSTARI: c_uint = 55
let OP_POSPLUSI: c_uint = 56
let OP_POSQUERYI: c_uint = 57
let OP_POSUPTOI: c_uint = 58
let OP_NOTSTAR: c_uint = 59
let OP_NOTMINSTAR: c_uint = 60
let OP_NOTPLUS: c_uint = 61
let OP_NOTMINPLUS: c_uint = 62
let OP_NOTQUERY: c_uint = 63
let OP_NOTMINQUERY: c_uint = 64
let OP_NOTUPTO: c_uint = 65
let OP_NOTMINUPTO: c_uint = 66
let OP_NOTEXACT: c_uint = 67
let OP_NOTPOSSTAR: c_uint = 68
let OP_NOTPOSPLUS: c_uint = 69
let OP_NOTPOSQUERY: c_uint = 70
let OP_NOTPOSUPTO: c_uint = 71
let OP_NOTSTARI: c_uint = 72
let OP_NOTMINSTARI: c_uint = 73
let OP_NOTPLUSI: c_uint = 74
let OP_NOTMINPLUSI: c_uint = 75
let OP_NOTQUERYI: c_uint = 76
let OP_NOTMINQUERYI: c_uint = 77
let OP_NOTUPTOI: c_uint = 78
let OP_NOTMINUPTOI: c_uint = 79
let OP_NOTEXACTI: c_uint = 80
let OP_NOTPOSSTARI: c_uint = 81
let OP_NOTPOSPLUSI: c_uint = 82
let OP_NOTPOSQUERYI: c_uint = 83
let OP_NOTPOSUPTOI: c_uint = 84
let OP_TYPESTAR: c_uint = 85
let OP_TYPEMINSTAR: c_uint = 86
let OP_TYPEPLUS: c_uint = 87
let OP_TYPEMINPLUS: c_uint = 88
let OP_TYPEQUERY: c_uint = 89
let OP_TYPEMINQUERY: c_uint = 90
let OP_TYPEUPTO: c_uint = 91
let OP_TYPEMINUPTO: c_uint = 92
let OP_TYPEEXACT: c_uint = 93
let OP_TYPEPOSSTAR: c_uint = 94
let OP_TYPEPOSPLUS: c_uint = 95
let OP_TYPEPOSQUERY: c_uint = 96
let OP_TYPEPOSUPTO: c_uint = 97
let OP_CRSTAR: c_uint = 98
let OP_CRMINSTAR: c_uint = 99
let OP_CRPLUS: c_uint = 100
let OP_CRMINPLUS: c_uint = 101
let OP_CRQUERY: c_uint = 102
let OP_CRMINQUERY: c_uint = 103
let OP_CRRANGE: c_uint = 104
let OP_CRMINRANGE: c_uint = 105
let OP_CRPOSSTAR: c_uint = 106
let OP_CRPOSPLUS: c_uint = 107
let OP_CRPOSQUERY: c_uint = 108
let OP_CRPOSRANGE: c_uint = 109
let OP_CLASS: c_uint = 110
let OP_NCLASS: c_uint = 111
let OP_XCLASS: c_uint = 112
let OP_ECLASS: c_uint = 113
let OP_REF: c_uint = 114
let OP_REFI: c_uint = 115
let OP_DNREF: c_uint = 116
let OP_DNREFI: c_uint = 117
let OP_RECURSE: c_uint = 118
let OP_CALLOUT: c_uint = 119
let OP_CALLOUT_STR: c_uint = 120
let OP_ALT: c_uint = 121
let OP_KET: c_uint = 122
let OP_KETRMAX: c_uint = 123
let OP_KETRMIN: c_uint = 124
let OP_KETRPOS: c_uint = 125
let OP_REVERSE: c_uint = 126
let OP_VREVERSE: c_uint = 127
let OP_ASSERT: c_uint = 128
let OP_ASSERT_NOT: c_uint = 129
let OP_ASSERTBACK: c_uint = 130
let OP_ASSERTBACK_NOT: c_uint = 131
let OP_ASSERT_NA: c_uint = 132
let OP_ASSERTBACK_NA: c_uint = 133
let OP_ASSERT_SCS: c_uint = 134
let OP_ONCE: c_uint = 135
let OP_SCRIPT_RUN: c_uint = 136
let OP_BRA: c_uint = 137
let OP_BRAPOS: c_uint = 138
let OP_CBRA: c_uint = 139
let OP_CBRAPOS: c_uint = 140
let OP_COND: c_uint = 141
let OP_SBRA: c_uint = 142
let OP_SBRAPOS: c_uint = 143
let OP_SCBRA: c_uint = 144
let OP_SCBRAPOS: c_uint = 145
let OP_SCOND: c_uint = 146
let OP_CREF: c_uint = 147
let OP_DNCREF: c_uint = 148
let OP_RREF: c_uint = 149
let OP_DNRREF: c_uint = 150
let OP_FALSE: c_uint = 151
let OP_TRUE: c_uint = 152
let OP_BRAZERO: c_uint = 153
let OP_BRAMINZERO: c_uint = 154
let OP_BRAPOSZERO: c_uint = 155
let OP_MARK: c_uint = 156
let OP_PRUNE: c_uint = 157
let OP_PRUNE_ARG: c_uint = 158
let OP_SKIP: c_uint = 159
let OP_SKIP_ARG: c_uint = 160
let OP_THEN: c_uint = 161
let OP_THEN_ARG: c_uint = 162
let OP_COMMIT: c_uint = 163
let OP_COMMIT_ARG: c_uint = 164
let OP_FAIL: c_uint = 165
let OP_ACCEPT: c_uint = 166
let OP_ASSERT_ACCEPT: c_uint = 167
let OP_CLOSE: c_uint = 168
let OP_SKIPZERO: c_uint = 169
let OP_DEFINE: c_uint = 170
let OP_NOT_UCP_WORD_BOUNDARY: c_uint = 171
let OP_UCP_WORD_BOUNDARY: c_uint = 172
let OP_TABLE_LENGTH: c_uint = 173
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
@[c_export("_pcre2_check_escape_8")]
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
                escape = 0
                if (if ptr >= ptrend: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = ERR1)
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
                (unsafe: *errorcodeptr = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 2
                continue
            2 =>  // EXIT
                (__goto_pending = 0)
                (unsafe: *ptrptr = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *chptr = c)
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
let ERR0: c_uint = 100
let ERR1: c_uint = 101
let ERR2: c_uint = 102
let ERR3: c_uint = 103
let ERR4: c_uint = 104
let ERR5: c_uint = 105
let ERR6: c_uint = 106
let ERR7: c_uint = 107
let ERR8: c_uint = 108
let ERR9: c_uint = 109
let ERR10: c_uint = 110
let ERR11: c_uint = 111
let ERR12: c_uint = 112
let ERR13: c_uint = 113
let ERR14: c_uint = 114
let ERR15: c_uint = 115
let ERR16: c_uint = 116
let ERR17: c_uint = 117
let ERR18: c_uint = 118
let ERR19: c_uint = 119
let ERR20: c_uint = 120
let ERR21: c_uint = 121
let ERR22: c_uint = 122
let ERR23: c_uint = 123
let ERR24: c_uint = 124
let ERR25: c_uint = 125
let ERR26: c_uint = 126
let ERR27: c_uint = 127
let ERR28: c_uint = 128
let ERR29: c_uint = 129
let ERR30: c_uint = 130
let ERR31: c_uint = 131
let ERR32: c_uint = 132
let ERR33: c_uint = 133
let ERR34: c_uint = 134
let ERR35: c_uint = 135
let ERR36: c_uint = 136
let ERR37: c_uint = 137
let ERR38: c_uint = 138
let ERR39: c_uint = 139
let ERR40: c_uint = 140
let ERR41: c_uint = 141
let ERR42: c_uint = 142
let ERR43: c_uint = 143
let ERR44: c_uint = 144
let ERR45: c_uint = 145
let ERR46: c_uint = 146
let ERR47: c_uint = 147
let ERR48: c_uint = 148
let ERR49: c_uint = 149
let ERR50: c_uint = 150
let ERR51: c_uint = 151
let ERR52: c_uint = 152
let ERR53: c_uint = 153
let ERR54: c_uint = 154
let ERR55: c_uint = 155
let ERR56: c_uint = 156
let ERR57: c_uint = 157
let ERR58: c_uint = 158
let ERR59: c_uint = 159
let ERR60: c_uint = 160
let ERR61: c_uint = 161
let ERR62: c_uint = 162
let ERR63: c_uint = 163
let ERR64: c_uint = 164
let ERR65: c_uint = 165
let ERR66: c_uint = 166
let ERR67: c_uint = 167
let ERR68: c_uint = 168
let ERR69: c_uint = 169
let ERR70: c_uint = 170
let ERR71: c_uint = 171
let ERR72: c_uint = 172
let ERR73: c_uint = 173
let ERR74: c_uint = 174
let ERR75: c_uint = 175
let ERR76: c_uint = 176
let ERR77: c_uint = 177
let ERR78: c_uint = 178
let ERR79: c_uint = 179
let ERR80: c_uint = 180
let ERR81: c_uint = 181
let ERR82: c_uint = 182
let ERR83: c_uint = 183
let ERR84: c_uint = 184
let ERR85: c_uint = 185
let ERR86: c_uint = 186
let ERR87: c_uint = 187
let ERR88: c_uint = 188
let ERR89: c_uint = 189
let ERR90: c_uint = 190
let ERR91: c_uint = 191
let ERR92: c_uint = 192
let ERR93: c_uint = 193
let ERR94: c_uint = 194
let ERR95: c_uint = 195
let ERR96: c_uint = 196
let ERR97: c_uint = 197
let ERR98: c_uint = 198
let ERR99: c_uint = 199
let ERR100: c_uint = 200
let ERR101: c_uint = 201
let ERR102: c_uint = 202
let ERR103: c_uint = 203
let ERR104: c_uint = 204
let ERR105: c_uint = 205
let ERR106: c_uint = 206
let ERR107: c_uint = 207
let ERR108: c_uint = 208
let ERR109: c_uint = 209
let ERR110: c_uint = 210
let ERR111: c_uint = 211
let ERR112: c_uint = 212
let ERR113: c_uint = 213
let ERR114: c_uint = 214
let ERR115: c_uint = 215
let ERR116: c_uint = 216
let ERR117: c_uint = 217
let ERR118: c_uint = 218
let ERR119: c_uint = 219
let ERR120: c_uint = 220
type eclass_op_info { code_start: *mut u8 = null, length: c_ulong = 0, op_single_type: u8 = 0, bits: class_bits_storage }
type struct_eclass_op_info = eclass_op_info
extern var _pcre2_posix_class_maps8: *c_int
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
    var code: *mut u8
    var last_branch: *mut u8
    var start_bracket: *mut u8
    var lookbehind: c_int
    var capitem: open_capitem
    var capnumber: c_int = 0
    var okreturn: c_int = 1
    var pptr: *mut c_uint
    var firstcu: c_uint
    var reqcu: c_uint
    var lookbehindlength: c_uint
    var lookbehindminlength: c_uint
    var firstcuflags: c_uint
    var reqcuflags: c_uint
    var length: c_ulong
    var bc: branch_chain_8
    if (if (if cb.cx.stack_guard != (null as *const fn(c_uint, *mut c_void) -> c_int): 1 else: 0) != 0 and cb.cx.stack_guard(cb.parens_depth, cb.cx.stack_guard_data) != 0: 1 else: 0) != 0:
        (unsafe: *errorcodeptr = ERR33)
        (cb.erroroffset = 0)
        return 0

    (bc.outer = bcptr)
    (bc.current_branch = code)
    (reqcu = 0)
    (firstcu = reqcu)
    (reqcuflags = (4294967295 as c_uint))
    (firstcuflags = reqcuflags)
    (length = (6 +% skipunits))
    (lookbehind = (if (if (if unsafe: *code == OP_ASSERTBACK: 1 else: 0) != 0 or (if unsafe: *code == OP_ASSERTBACK_NOT: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_ASSERTBACK_NA: 1 else: 0) != 0: 1 else: 0))
    if lookbehind != 0:
        (lookbehindminlength = unsafe: *pptr)
        pptr = pptr + 2
    else:
        (lookbehindminlength = 0)
        (lookbehindlength = lookbehindminlength)

    if (if unsafe: *code == OP_CBRA: 1 else: 0) != 0:
        (capitem.number = capnumber)
        (capitem.next = open_caps)
        (capitem.assert_depth = cb.assert_depth)
        (open_caps = (&mut capitem as *mut open_capitem))

    code = code + (3 +% skipunits)
    while true:
        var branch_return: c_int
        var branchfirstcu: c_uint
        var branchreqcu: c_uint
        var branchfirstcuflags: c_uint
        var branchreqcuflags: c_uint
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
            if (if unsafe: *last_branch != OP_ALT: 1 else: 0) != 0:
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
            (code = (((unsafe: *codeptr + (1 as isize as usize)) + (2 as isize as usize)) + skipunits))
            length = length + 3
        else:
            (unsafe: *code = 121)
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
                if (if ((unsafe: *lcptr) = (unsafe: *lcptr) + 1) > 2000: 1 else: 0) != 0:
                    (unsafe: *errcodeptr = ERR35)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return -1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (pptr = pptr + 1) != null:
                    if (if unsafe: *pptr < 2147483648: 1 else: 0) != 0:
                        (itemminlength = 1)
                        (itemlength = itemminlength)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if (2147483647 - branchlength) < (itemlength as c_int): 1 else: 0) != 0 or (if (branchlength = branchlength + itemlength) > ((65535 as c_int)): 1 else: 0) != 0: 1 else: 0) != 0:
                        (unsafe: *errcodeptr = ERR87)
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
                (unsafe: *pptrptr = pptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *minptr = branchminlength)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return branchlength
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 6
                continue
            6 =>  // PARSED_SKIP_FAILED
                (__goto_pending = 0)
                (unsafe: *errcodeptr = ERR90)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return -1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn set_lookbehind_lengths(pptrptr: *mut *mut c_uint, errcodeptr: *mut c_int, lcptr: *mut c_int, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8) -> c_int:
    var offset: c_ulong
    var bptr: *mut c_uint
    var gbptr: *mut c_uint
    var maxlength: c_int = 0
    var minlength: c_int = 2147483647
    var variable: c_int
    0
    unsafe: *pptrptr = unsafe: *pptrptr + 2
    if variable != 0:
        (gbptr[1] = minlength)
    else:
        (gbptr[1] = 65535)

    return 1

fn check_lookbehinds(__param_pptr: *mut c_uint, retptr: *mut *mut c_uint, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8, lcptr: *mut c_int) -> c_int:
    var pptr = __param_pptr
    var errorcode: c_int = 0
    var nestlevel: c_int = 0
    while (if unsafe: *pptr != 2147483648: 1 else: 0) != 0:
        if (if unsafe: *pptr < 2147483648: 1 else: 0) != 0:
            continue
        
        (pptr = pptr + 1)

    return 0

extern var meta_extra_lengths: [73]u8
let PSKIP_ALT: c_uint = 0
let PSKIP_CLASS: c_uint = 1
let PSKIP_KET: c_uint = 2
extern var xdigitab: [256]u8
extern var escapes: [75]c_short
type verbitem { len: c_uint = 0, meta: c_uint = 0, has_arg: c_int = 0 }
type struct_verbitem = verbitem
extern var verbnames: [43]c_char
extern var verbs: [9]verbitem
let verbcount: c_int = 9
extern var verbops: [11]c_uint
type alasitem { len: c_uint = 0, meta: c_uint = 0 }
type struct_alasitem = alasitem
extern var alasnames: [229]c_char
extern var alasmeta: [19]alasitem
let alascount: c_int = 19
extern var chartypeoffset: [4]c_uint
extern var posix_names: [84]c_char
extern var posix_name_lengths: [15]u8
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
extern var pso_list: [23]pso
extern var opcode_possessify: [120]u8
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
                (unsafe: *errorcodeptr = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if allow_sign >= 0: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if unsafe: *ptr == 43: 1 else: 0) != 0:
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
                        if (if unsafe: *ptr == 45: 1 else: 0) != 0:
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
                        (unsafe: *errorcodeptr = ERR26)
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
                (unsafe: *intptr = n)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *ptrptr = ptr)
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
                (unsafe: *errorcodeptr = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (p = p + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (pp = p)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *pp == 32: 1 else: 0) != 0 or (if unsafe: *pp == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (pp = pp + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if pp >= ptrend: 1 else: 0) != 0:
                    return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if unsafe: *pp == 125: 1 else: 0) != 0:
                    if (if had_minimum != 0: 0 else: 1) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    if (if unsafe: *(pp = pp + 1) != 44: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *pp == 32: 1 else: 0) != 0 or (if unsafe: *pp == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (pp = pp + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if pp >= ptrend: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *pp == 32: 1 else: 0) != 0 or (if unsafe: *pp == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (pp = pp + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (if pp >= ptrend: 1 else: 0) != 0 or (if unsafe: *pp != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if read_number((&mut p as *mut *const u8), ptrend, -1, 65535, 105, (&mut min as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                    if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                        __pc = 1
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (p = p + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (p = p + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if read_number((&mut p as *mut *const u8), ptrend, -1, 65535, 105, (&mut max as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                        if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                            __pc = 1
                            __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (p = p + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if unsafe: *p == 125: 1 else: 0) != 0:
                        (max = min)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    else:
                        (p = p + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                            (p = p + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if read_number((&mut p as *mut *const u8), ptrend, -1, 65535, 105, (&mut max as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                            if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                                __pc = 1
                                __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if max < min: 1 else: 0) != 0:
                            (unsafe: *errorcodeptr = ERR4)
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
                while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
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
                (unsafe: *ptrptr = p)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return yield_
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn check_posix_syntax(__param_ptr: *const u8, ptrend: *const u8, endptr: *mut *const u8) -> c_int:
    var ptr = __param_ptr
    var terminator: u8
    (terminator = unsafe: *(ptr = ptr + 1))
    while (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 2: 1 else: 0) != 0:
        if (if (if unsafe: *ptr == 92: 1 else: 0) != 0 and ((if (if ptr[1] == 93: 1 else: 0) != 0 or (if ptr[1] == 92: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
            (ptr = ptr + 1)
        else:
            if (if ((if (if unsafe: *ptr == 91: 1 else: 0) != 0 and (if ptr[1] == terminator: 1 else: 0) != 0: 1 else: 0)) != 0 or (if unsafe: *ptr == 93: 1 else: 0) != 0: 1 else: 0) != 0:
                return 0
            else:
                if (if (if unsafe: *ptr == terminator: 1 else: 0) != 0 and (if ptr[1] == 93: 1 else: 0) != 0: 1 else: 0) != 0:
                    (unsafe: *endptr = ptr)
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
                if is_braced != 0:
                    while (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *ptr == 32: 1 else: 0) != 0 or (if unsafe: *ptr == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (ptr = ptr + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ptr >= ptrend: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = (if is_group != 0: ERR62 else: ERR60))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 1
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *nameptr = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                utf
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if (if ptr < ptrend: 1 else: 0) != 0 and 1 != 0: 1 else: 0) != 0 and (if ((cb.ctypes[unsafe: *ptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (ptr = ptr + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((ptr as usize -% unsafe: *nameptr as usize) / sizeof[u8]()) > 128: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = ERR48)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 1
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if is_group != 0:
                    if (if ptr == unsafe: *nameptr: 1 else: 0) != 0:
                        (unsafe: *errorcodeptr = ERR62)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 1
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if is_braced != 0:
                        while (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *ptr == 32: 1 else: 0) != 0 or (if unsafe: *ptr == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
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
                (unsafe: *ptrptr = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // FAILED
                (__goto_pending = 0)
                (unsafe: *ptrptr = ptr)
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
                if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 40: 1 else: 0) != 0: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = ERR118)
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
                        (unsafe: *errorcodeptr = ERR117)
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
                            (unsafe: *errorcodeptr = ERR15)
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
                        if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                            __pc = 2
                            __goto_pending = 1
                        else:
                            if (if unsafe: *ptr == 60: 1 else: 0) != 0:
                                (terminator = 62)
                            else:
                                if (if unsafe: *ptr == 39: 1 else: 0) != 0:
                                    (terminator = 39)
                                else:
                                    (unsafe: *errorcodeptr = ERR117)
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
                    if (if unsafe: *ptr == 41: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if unsafe: *ptr != 44: 1 else: 0) != 0:
                        (unsafe: *errorcodeptr = ERR24)
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
                (unsafe: *ptrptr = (ptr + (1 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return parsed_pattern
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // UNCLOSED_PARENTHESIS
                (__goto_pending = 0)
                (unsafe: *errorcodeptr = ERR14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 2
                continue
            2 =>  // FAILED
                (__goto_pending = 0)
                (unsafe: *ptrptr = ptr)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return (null as *mut c_uint)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn manage_callouts(ptr: *const u8, pcalloutptr: *mut *mut c_uint, auto_callout: c_int, __param_parsed_pattern: *mut c_uint, cb: *mut compile_block_8) -> *mut c_uint:
    var parsed_pattern = __param_parsed_pattern
    var previous_callout: *mut c_uint
    if (if auto_callout != 0: 0 else: 1) != 0:
        (previous_callout = (null as *mut c_uint))
    else:
        if (if (if (if previous_callout == (null as *mut c_uint): 1 else: 0) != 0 or (if previous_callout != (parsed_pattern - (4 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 or (if previous_callout[3] != 255: 1 else: 0) != 0: 1 else: 0) != 0:
            (previous_callout = parsed_pattern)
            parsed_pattern = parsed_pattern + 4
            (previous_callout[0] = (2147876864 as c_uint))
            (previous_callout[2] = 0)
            (previous_callout[3] = 255)
        

    (unsafe: *pcalloutptr = previous_callout)
    return parsed_pattern

fn handle_escdsw(escape: c_int, __param_parsed_pattern: *mut c_uint, options: c_uint, xoptions: c_uint) -> *mut c_uint:
    var parsed_pattern = __param_parsed_pattern
    var ascii_option: c_uint
    var prop: c_uint
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
    var big32count: c_ulong
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
                after_manual_callout = 0
                expect_cond_assert = 0
                errorcode = 0
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
                        if (if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
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
                        if (if (if unsafe: *ptr == 81: 1 else: 0) != 0 or (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (if (if expect_cond_assert > 0: 1 else: 0) != 0 and (if unsafe: *ptr == 81: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0 and (if ptr[1] == 92: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[2] == 69: 1 else: 0) != 0: 1 else: 0)) != 0: 0 else: 1) != 0: 1 else: 0) != 0:
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
                            (inescq = (if unsafe: *ptr == 81: 1 else: 0))
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
                        while (if (if (ptr = ptr + 1) < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                            (terminator = (if ((if unsafe: *ptr == 60: 1 else: 0)) != 0: 62 else: (if ((if unsafe: *ptr == 39: 1 else: 0)) != 0: 39 else: 125)))
                                            if (if (if escape == ESC_g: 1 else: 0) != 0 and (if terminator != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                                                if read_number((&mut p as *mut *const u8), ptrend, cb.bracount, 65535, 161, (&mut i as *mut c_int), (&mut errorcode as *mut c_int)) != 0:
                                                    if (if (if p >= ptrend: 1 else: 0) != 0 or (if unsafe: *p != terminator: 1 else: 0) != 0: 1 else: 0) != 0:
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
                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *verbstartptr = (2149449728 as c_uint))
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
                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *verbstartptr = (2149449728 as c_uint))
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
                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *verbstartptr = (2149449728 as c_uint))
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
                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
                                    (p[1] = p[0])
                                    (p = p - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *verbstartptr = (2149449728 as c_uint))
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
                                    (unsafe: *has_lookbehind = 1)
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
                            if (if (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if (if unsafe: *ptr == 58: 1 else: 0) != 0 or (if unsafe: *ptr == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *ptr == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend, (&mut tempptr as *mut *const u8)) != 0: 1 else: 0) != 0:
                                (errorcode = (if ((if unsafe: *(ptr = ptr - 1) == 58: 1 else: 0)) != 0: ERR12 else: ERR13))
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
                                if inescq != 0:
                                    if (if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                if (if (if (if (if (if class_depth_m1 >= 0: 1 else: 0) != 0 and (if c == 91: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0: 1 else: 0) != 0 and ((if (if (if unsafe: *ptr == 58: 1 else: 0) != 0 or (if unsafe: *ptr == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *ptr == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend, (&mut tempptr as *mut *const u8)) != 0: 1 else: 0) != 0:
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
                                    if (if unsafe: *ptr != 58: 1 else: 0) != 0:
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
                                    if (if unsafe: *((ptr = ptr + 1)) == 94: 1 else: 0) != 0:
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
                                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                                unsafe: *class_start = unsafe: *class_start | 1
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
                                            unsafe: *class_start = unsafe: *class_start | 1
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
                                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                                    unsafe: *class_start = unsafe: *class_start | 1
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
                                                        unsafe: *class_start = unsafe: *class_start | 1
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
                                                    if (if (if (if (if class_mode_state == 1: 1 else: 0) != 0 and ((if (if (if (if c == 124: 1 else: 0) != 0 or (if c == 45: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 38: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 126: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr == c: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = ptr + 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == c: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            while (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == c: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                                            unsafe: *class_start = unsafe: *class_start | 1
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
                            if (if unsafe: *ptr != 63: 1 else: 0) != 0:
                                if (if unsafe: *ptr != 42: 1 else: 0) != 0:
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
                                            if (if unsafe: *ptr != 58: 1 else: 0) != 0:
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
                                            if (if (if ptr >= ptrend: 1 else: 0) != 0 or ((if (if unsafe: *ptr != 58: 1 else: 0) != 0 and (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
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
                                            if (if (if (if unsafe: *ptr == 58: 1 else: 0) != 0 and (if (ptr + (1 as isize as usize)) < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (ptr = ptr + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if (&verbs[0] as *mut verbitem)[i].has_arg > 0: 1 else: 0) != 0 and (if unsafe: *ptr != 58: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                            if (if unsafe: *(ptr = ptr + 1) == 58: 1 else: 0) != 0:
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
                            match unsafe: *ptr
                                80 =>
                                    if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    if (if unsafe: *ptr == 60: 1 else: 0) != 0:
                                        (terminator = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if unsafe: *ptr == 62: 1 else: 0) != 0:
                                        __pc = 8
                                        __goto_pending = 1
                                    if (if unsafe: *ptr != 61: 1 else: 0) != 0:
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
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or ((if (if unsafe: *ptr != 41: 1 else: 0) != 0 and (if unsafe: *ptr != 40: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
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
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list((&mut ptr as *mut *const u8), ptrend, utf, parsed_pattern, offset, (&mut errorcode as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                    if (if (if unsafe: *ptr == 63: 1 else: 0) != 0 or (if unsafe: *ptr == 42: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                                major = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                minor = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                ptr = ptr + 7
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if unsafe: *ptr == 62: 1 else: 0) != 0:
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
                                                if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 46: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    if (if read_number((&mut ptr as *mut *const u8), ptrend, -1, 1000, 179, (&mut minor as *mut c_int), (&mut errorcode as *mut c_int)) != 0: 0 else: 1) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                                if (if (if (if unsafe: *ptr == 82: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) > 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 38: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                                    if (if unsafe: *ptr == 60: 1 else: 0) != 0:
                                                        (terminator = 62)
                                                    else:
                                                        if (if unsafe: *ptr == 39: 1 else: 0) != 0:
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
                                                    (unsafe: *parsed_pattern = (2148728832 as c_uint))
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr - 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    if (if terminator == 41: 1 else: 0) != 0:
                                                        if (if (if namelen == 6: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name, ((&STRING_DEFINE[0] as *mut c_char) as *const i8), 6) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            (unsafe: *parsed_pattern = (2148532224 as c_uint))
                                                        else:
                                                            (unsafe: *parsed_pattern = (if ((if (if unsafe: *name == 82: 1 else: 0) != 0 and (if i >= (namelen as c_int): 1 else: 0) != 0: 1 else: 0)) != 0: 2148794368 else: 2148597760))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (ptr = ptr - 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    else:
                                                        (unsafe: *parsed_pattern = (2148597760 as c_uint))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if unsafe: *(parsed_pattern = parsed_pattern + 1) != 2148532224: 1 else: 0) != 0:
                                                    (unsafe: *parsed_pattern = namelen)
                                                    (parsed_pattern = parsed_pattern + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                    (unsafe: *has_lookbehind = 1)
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
                                    (unsafe: *has_lookbehind = 1)
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
                                    (unsafe: *has_lookbehind = 1)
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
                                    (unsafe: *has_lookbehind = 1)
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
                                    (c = unsafe: *(ptr = ptr + 1))
                                    __pc = 3
                                    __goto_pending = 1
                                _ =>
                                    (nest_depth = nest_depth + 1)
                                    (top_nest.nest_depth = nest_depth)
                                    (top_nest.flags = 0)
                                    if (if unsafe: *ptr == 124: 1 else: 0) != 0:
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
                                        if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 94: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                        while (if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr != 58: 1 else: 0) != 0: 1 else: 0) != 0:
                                            match unsafe: *(ptr = ptr + 1)
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
                                                        if (if unsafe: *ptr == 68: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 256
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
                                                        if (if unsafe: *ptr == 80: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | ((2048 | 4096))
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
                                                        if (if unsafe: *ptr == 83: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 512
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
                                                        if (if unsafe: *ptr == 84: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 4096
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
                                                        if (if unsafe: *ptr == 87: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 1024
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
                                                    unsafe: *xoptset = unsafe: *xoptset | ((((256 | 512) | 1024) | 4096) | 2048)
                                                74 =>
                                                    unsafe: *optset = unsafe: *optset | 64
                                                    cb.external_flags = cb.external_flags | 1024
                                                105 =>
                                                    unsafe: *optset = unsafe: *optset | 8
                                                109 =>
                                                    unsafe: *optset = unsafe: *optset | 1024
                                                110 =>
                                                    unsafe: *optset = unsafe: *optset | 8192
                                                114 =>
                                                    unsafe: *xoptset = unsafe: *xoptset | 128
                                                115 =>
                                                    unsafe: *optset = unsafe: *optset | 32
                                                85 =>
                                                    unsafe: *optset = unsafe: *optset | 262144
                                                120 =>
                                                    unsafe: *optset = unsafe: *optset | 128
                                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 120: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        unsafe: *optset = unsafe: *optset | 16777216
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
                                        if (if unsafe: *(ptr = ptr + 1) == 41: 1 else: 0) != 0:
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
                (unsafe: *parsed_pattern = (2147483648 as c_uint))
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
        match (unsafe: *code as c_int)
            OP_ASSERT_NOT =>
                code = code + _pcre2_OP_lengths_8[unsafe: *code]
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
                            (unsafe: *errorcodeptr = ERR52)
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
                            (unsafe: *errorcodeptr = ERR86)
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
                            if (if unsafe: *lengthptr > 65536: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR20)
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
                            (unsafe: *firstcuflagsptr = firstcuflags)
                            (unsafe: *reqcuptr = reqcu)
                            (unsafe: *reqcuflagsptr = reqcuflags)
                            (unsafe: *codeptr = code)
                            (unsafe: *pptrptr = pptr)
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
                            if (if ((unsafe: *pptr & 1)) != 0: 1 else: 0) != 0:
                                if (if _pcre2_compile_class_nested_8(options, xoptions, (&mut pptr as *mut *mut c_uint), (&mut code as *mut *mut u8), errorcodeptr, cb, lengthptr) != 0: 0 else: 1) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (if pptr[1] < 2147483648: 1 else: 0) != 0 and (if pptr[2] == 2148335616: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                    unsafe: *lengthptr = unsafe: *lengthptr + 3
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
                            (verbarglen = unsafe: *((pptr = pptr + 1)))
                            (verbculen = 0)
                            (tempcode = code)
                            (code = code + 1)
                            i = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = unsafe: *((pptr = pptr + 1)))
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
                                    unsafe: *lengthptr = unsafe: *lengthptr + mclength
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
                            (unsafe: *tempcode = verbculen)
                            (unsafe: *code = 0)
                            (code = code + 1)
                        2150825984 =>
                            (verbarglen = unsafe: *((pptr = pptr + 1)))
                            (verbculen = 0)
                            (tempcode = code)
                            (code = code + 1)
                            i = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = unsafe: *((pptr = pptr + 1)))
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
                                    unsafe: *lengthptr = unsafe: *lengthptr + mclength
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
                            (unsafe: *tempcode = verbculen)
                            (unsafe: *code = 0)
                            (code = code + 1)
                        2150432768 =>
                            (verbarglen = unsafe: *((pptr = pptr + 1)))
                            (verbculen = 0)
                            (tempcode = code)
                            (code = code + 1)
                            i = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = unsafe: *((pptr = pptr + 1)))
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
                                    unsafe: *lengthptr = unsafe: *lengthptr + mclength
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
                            (unsafe: *tempcode = verbculen)
                            (unsafe: *code = 0)
                            (code = code + 1)
                        2149515264 =>
                            (options = unsafe: *((pptr = pptr + 1)))
                            (unsafe: *optionsptr = options)
                            (xoptions = unsafe: *((pptr = pptr + 1)))
                            (unsafe: *xoptionsptr = xoptions)
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
                                                (unsafe: *errorcodeptr = ERR61)
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
                                        (unsafe: *errorcodeptr = ERR15)
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
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
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
                                                (unsafe: *errorcodeptr = ERR61)
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
                                        (unsafe: *errorcodeptr = ERR15)
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
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
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
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
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
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
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
                            (unsafe: *code = bravalue)
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
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *errorcodeptr = ERR54)
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
                                        (unsafe: *errorcodeptr = ERR27)
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
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
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
                            (unsafe: *code = bravalue)
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
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *errorcodeptr = ERR54)
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
                                        (unsafe: *errorcodeptr = ERR27)
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
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
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
                            (unsafe: *code = bravalue)
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
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *errorcodeptr = ERR54)
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
                                        (unsafe: *errorcodeptr = ERR27)
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
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
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
                            (unsafe: *code = bravalue)
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
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *errorcodeptr = ERR54)
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
                                        (unsafe: *errorcodeptr = ERR27)
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
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
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
                            (unsafe: *code = bravalue)
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
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *errorcodeptr = ERR54)
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
                                        (unsafe: *errorcodeptr = ERR27)
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
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
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
                            (unsafe: *code = bravalue)
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
                                condcount = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount = condcount + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *errorcodeptr = ERR54)
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
                                        (unsafe: *errorcodeptr = ERR27)
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
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
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
                                unsafe: *lengthptr = unsafe: *lengthptr + (pptr[3] +% 9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 3
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr = pptr + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
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
                                (unsafe: *callout_string = unsafe: *(pp = pp + 1))
                                (callout_string = callout_string + 1)
                                (delimiter = unsafe: *(callout_string = callout_string + 1))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if delimiter == 123: 1 else: 0) != 0:
                                    (delimiter = 125)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while (if (length = length - 1) > 1: 1 else: 0) != 0:
                                    if (if (if unsafe: *pp == delimiter: 1 else: 0) != 0 and (if pp[1] == delimiter: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                        (unsafe: *callout_string = unsafe: *(pp = pp + 1))
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
                            (repeat_max = unsafe: *((pptr = pptr + 1)))
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
                            (op_previous = unsafe: *previous)
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
                                    (unsafe: *previous = 137)
                                    (op_previous = unsafe: *previous)
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
                                        (unsafe: *errorcodeptr = ERR10)
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
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
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
                                    repcode = unsafe: *tempcode
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = (&opcode_possessify[0] as *mut u8)[repcode])
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
                            (op_previous = unsafe: *previous)
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
                                    (unsafe: *previous = 137)
                                    (op_previous = unsafe: *previous)
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
                                        (unsafe: *errorcodeptr = ERR10)
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
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
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
                                    repcode = unsafe: *tempcode
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = (&opcode_possessify[0] as *mut u8)[repcode])
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
                            (op_previous = unsafe: *previous)
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
                                    (unsafe: *previous = 137)
                                    (op_previous = unsafe: *previous)
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
                                        (unsafe: *errorcodeptr = ERR10)
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
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
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
                                    repcode = unsafe: *tempcode
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = (&opcode_possessify[0] as *mut u8)[repcode])
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
                            (op_previous = unsafe: *previous)
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
                                    (unsafe: *previous = 137)
                                    (op_previous = unsafe: *previous)
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
                                        (unsafe: *errorcodeptr = ERR10)
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
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
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
                                    repcode = unsafe: *tempcode
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = (&opcode_possessify[0] as *mut u8)[repcode])
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
                                (unsafe: *errorcodeptr = ERR15)
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
                                (unsafe: *errorcodeptr = ERR15)
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
                                (unsafe: *errorcodeptr = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *code = 118)
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
                                (unsafe: *errorcodeptr = ERR99)
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
                                (unsafe: *errorcodeptr = ERR99)
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
                                (unsafe: *errorcodeptr = ERR89)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (meta = unsafe: *pptr)
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
        var scode: *const u8
        var op: c_int = unsafe: *scode
        if (if (if (if (if op == OP_BRA: 1 else: 0) != 0 or (if op == OP_BRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
            if (if is_anchored(scode, bracket_map, cb, atomcount, inassert, dotstar_anchor) != 0: 0 else: 1) != 0:
                return 0
            
        else:
            if (if (if (if (if op == OP_CBRA: 1 else: 0) != 0 or (if op == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                var n: c_int
                var new_map: c_uint
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
        
        if not ((if unsafe: *code == OP_ALT: 1 else: 0) != 0):
            break

    return 1

fn is_startline(__param_code: *const u8, bracket_map: c_uint, cb: *mut compile_block_8, atomcount: c_int, inassert: c_int, dotstar_anchor: c_int) -> c_int:
    var code = __param_code
    while true:
        var scode: *const u8
        var op: c_int = unsafe: *scode
        if (if op == OP_COND: 1 else: 0) != 0:
            scode = scode + (1 + 2)
            if (if unsafe: *scode == OP_CALLOUT: 1 else: 0) != 0:
                scode = scode + _pcre2_OP_lengths_8[OP_CALLOUT]
            
            match unsafe: *scode
                OP_CREF =>
                    if (if is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor) != 0: 0 else: 1) != 0:
                        return 0
                    scode = scode + (1 + 2)
                _ =>
                    if (if is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor) != 0: 0 else: 1) != 0:
                        return 0
                    scode = scode + (1 + 2)
            
            (scode = first_significant_code(scode, 0))
            (op = unsafe: *scode)
        
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
        
        if not ((if unsafe: *code == OP_ALT: 1 else: 0) != 0):
            break

    return 1

fn find_recurse(__param_code: *mut u8, utf: c_int) -> *mut u8:
    var code = __param_code
    while true:
        var c: u8
        if (if c == OP_END: 1 else: 0) != 0:
            return (null as *mut u8)
        
        if (if c == OP_RECURSE: 1 else: 0) != 0:
            return code
        


fn find_firstassertedcu(__param_code: *const u8, flags: *mut c_uint, inassert: c_uint) -> c_uint:
    var code = __param_code
    var c: c_uint
    var cflags: c_uint
    (unsafe: *flags = (4294967294 as c_uint))
    while true:
        var d: c_uint
        var dflags: c_uint
        var xl: c_int = (if ((if (if (if (if unsafe: *code == OP_CBRA: 1 else: 0) != 0 or (if unsafe: *code == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)
        var scode: *const u8
        var op: u8
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
        
        if not ((if unsafe: *code == OP_ALT: 1 else: 0) != 0):
            break

    (unsafe: *flags = cflags)
    return c

fn parsed_skip(__param_pptr: *mut c_uint, skiptype: c_uint) -> *mut c_uint:
    var pptr = __param_pptr
    var nestlevel: c_uint
    while (pptr = pptr + 1) != null:
        var meta: c_uint
        match meta
            2147483648 =>
                return (null as *mut c_uint)
            2147680256 => 0
            2149318656 =>
                if (if (if (unsafe: *pptr -% (2149318656 as c_uint)) == 15: 1 else: 0) != 0 or (if (unsafe: *pptr -% (2149318656 as c_uint)) == 16: 1 else: 0) != 0: 1 else: 0) != 0:
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
                grouplength = -1
                groupminlength = 2147483647
                if (if (if group > 0: 1 else: 0) != 0 and (if ((cb.external_flags & 2097152)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if ((groupinfo & 1073741824)) != 0: 1 else: 0) != 0:
                        return -1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if ((groupinfo & (2147483648 as c_uint))) != 0: 1 else: 0) != 0:
                        if isinline != 0:
                            (unsafe: *pptrptr = parsed_skip(unsafe: *pptrptr, 2))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (unsafe: *minptr = gi[1])
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
                    if (if unsafe: *unsafe: *pptrptr == 2149384192: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    unsafe: *pptrptr = unsafe: *pptrptr + 1
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
                (unsafe: *minptr = groupminlength)
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

let ARG_MAX: c_int = 1048576
let BC_BASE_MAX: c_int = 99
let BC_DIM_MAX: c_int = 2048
let BC_SCALE_MAX: c_int = 99
let BC_STRING_MAX: c_int = 1000
let BUFSIZ: c_int = 1024
let BUS_ADRALN: c_int = 1
let BUS_ADRERR: c_int = 2
let BUS_NOOP: c_int = 0
let BUS_OBJERR: c_int = 3
// untranslatable fn-like macro
fn BYTES2CU() -> Never:
    comptime_error("untranslatable C macro: BYTES2CU")
// untranslatable fn-like macro
fn CAST_USER_ADDR_T() -> Never:
    comptime_error("untranslatable C macro: CAST_USER_ADDR_T")
let CHARCLASS_NAME_MAX: c_int = 14
let CHAR_0: c_int = 48
let CHAR_1: c_int = 49
let CHAR_2: c_int = 50
let CHAR_3: c_int = 51
let CHAR_4: c_int = 52
let CHAR_5: c_int = 53
let CHAR_6: c_int = 54
let CHAR_7: c_int = 55
let CHAR_8: c_int = 56
let CHAR_9: c_int = 57
let CHAR_A: c_int = 65
let CHAR_AMPERSAND: c_int = 38
let CHAR_APOSTROPHE: c_int = 39
let CHAR_ASTERISK: c_int = 42
let CHAR_B: c_int = 66
let CHAR_BACKSLASH: c_int = 92
let CHAR_BEL: c_int = 7
let CHAR_BIT: c_int = 8
let CHAR_BS: c_int = 8
let CHAR_C: c_int = 67
let CHAR_CIRCUMFLEX_ACCENT: c_int = 94
let CHAR_COLON: c_int = 58
let CHAR_COMMA: c_int = 44
let CHAR_COMMERCIAL_AT: c_int = 64
let CHAR_CR: c_int = 13
let CHAR_D: c_int = 68
let CHAR_DOLLAR_SIGN: c_int = 36
let CHAR_DOT: c_int = 46
let CHAR_E: c_int = 69
let CHAR_EQUALS_SIGN: c_int = 61
let CHAR_ESC: c_int = 0
let CHAR_EXCLAMATION_MARK: c_int = 33
let CHAR_F: c_int = 70
let CHAR_FF: c_int = 12
let CHAR_G: c_int = 71
let CHAR_GRAVE_ACCENT: c_int = 96
let CHAR_GREATER_THAN_SIGN: c_int = 62
let CHAR_H: c_int = 72
let CHAR_HT: c_int = 9
let CHAR_I: c_int = 73
let CHAR_J: c_int = 74
let CHAR_K: c_int = 75
let CHAR_L: c_int = 76
let CHAR_LEFT_CURLY_BRACKET: c_int = 123
let CHAR_LEFT_PARENTHESIS: c_int = 40
let CHAR_LEFT_SQUARE_BRACKET: c_int = 91
let CHAR_LESS_THAN_SIGN: c_int = 60
let CHAR_LF: c_int = 10
let CHAR_M: c_int = 77
let CHAR_MAX: c_int = 127
let CHAR_MINUS: c_int = 45
let CHAR_N: c_int = 78
let CHAR_NL: c_int = 10
let CHAR_NUL: c_int = 0
let CHAR_NUMBER_SIGN: c_int = 35
let CHAR_O: c_int = 79
let CHAR_P: c_int = 80
let CHAR_PERCENT_SIGN: c_int = 37
let CHAR_PLUS: c_int = 43
let CHAR_Q: c_int = 81
let CHAR_QUESTION_MARK: c_int = 63
let CHAR_QUOTATION_MARK: c_int = 34
let CHAR_R: c_int = 82
let CHAR_RIGHT_CURLY_BRACKET: c_int = 125
let CHAR_RIGHT_PARENTHESIS: c_int = 41
let CHAR_RIGHT_SQUARE_BRACKET: c_int = 93
let CHAR_S: c_int = 83
let CHAR_SEMICOLON: c_int = 59
let CHAR_SLASH: c_int = 47
let CHAR_SPACE: c_int = 32
let CHAR_T: c_int = 84
let CHAR_TILDE: c_int = 126
let CHAR_U: c_int = 85
let CHAR_UNDERSCORE: c_int = 95
let CHAR_V: c_int = 86
let CHAR_VERTICAL_LINE: c_int = 124
let CHAR_VT: c_int = 11
let CHAR_W: c_int = 87
let CHAR_X: c_int = 88
let CHAR_Y: c_int = 89
let CHAR_Z: c_int = 90
let CHAR_a: c_int = 97
let CHAR_b: c_int = 98
let CHAR_c: c_int = 99
let CHAR_d: c_int = 100
let CHAR_e: c_int = 101
let CHAR_f: c_int = 102
let CHAR_g: c_int = 103
let CHAR_h: c_int = 104
let CHAR_i: c_int = 105
let CHAR_j: c_int = 106
let CHAR_k: c_int = 107
let CHAR_l: c_int = 108
let CHAR_m: c_int = 109
let CHAR_n: c_int = 110
let CHAR_o: c_int = 111
let CHAR_p: c_int = 112
let CHAR_q: c_int = 113
let CHAR_r: c_int = 114
let CHAR_s: c_int = 115
let CHAR_t: c_int = 116
let CHAR_u: c_int = 117
let CHAR_v: c_int = 118
let CHAR_w: c_int = 119
let CHAR_x: c_int = 120
let CHAR_y: c_int = 121
let CHAR_z: c_int = 122
let CHILD_MAX: c_int = 266
// untranslatable fn-like macro
fn CHMAX_255() -> Never:
    comptime_error("untranslatable C macro: CHMAX_255")
let CLASS_IS_ECLASS: c_int = 0x1
let CLD_CONTINUED: c_int = 6
let CLD_DUMPED: c_int = 3
let CLD_EXITED: c_int = 1
let CLD_KILLED: c_int = 2
let CLD_NOOP: c_int = 0
let CLD_STOPPED: c_int = 5
let CLD_TRAPPED: c_int = 4
// untranslatable fn-like macro
fn CLIST_ALIGN_TO() -> Never:
    comptime_error("untranslatable C macro: CLIST_ALIGN_TO")
let COLL_WEIGHTS_MAX: c_int = 2
let COMPILE_ERROR_BASE: c_int = 100
let CONFIGURED_LINK_SIZE: c_int = 2
let CPUMON_MAKE_FATAL: c_int = 0x1000
// untranslatable fn-like macro
fn CU2BYTES() -> Never:
    comptime_error("untranslatable C macro: CU2BYTES")
let DFA_START_RWS_SIZE: c_int = 30720
let ECLASS_NEST_LIMIT: c_int = 15
let ECL_AND: c_int = 1
let ECL_ANY: c_int = 6
let ECL_MAP: c_int = 0x01
let ECL_NONE: c_int = 7
let ECL_NOT: c_int = 4
let ECL_OR: c_int = 2
let ECL_XCLASS: c_int = 5
let ECL_XOR: c_int = 3
let EOF: c_int = -1
let EQUIV_CLASS_MAX: c_int = 2
let ESCAPES_FIRST: c_int = 48
let ESCAPES_LAST: c_int = 122
let EXIT_FAILURE: c_int = 1
let EXIT_SUCCESS: c_int = 0
let EXPR_NEST_MAX: c_int = 32
let FALSE: c_int = 0
let FILENAME_MAX: c_int = 1024
let FIRST_AUTOTAB_OP: c_int = OP_NOT_DIGIT
let FOOTPRINT_INTERVAL_RESET: c_int = 0x1
let FOPEN_MAX: c_int = 20
let FPE_FLTDIV: c_int = 1
let FPE_FLTINV: c_int = 5
let FPE_FLTOVF: c_int = 2
let FPE_FLTRES: c_int = 4
let FPE_FLTSUB: c_int = 6
let FPE_FLTUND: c_int = 3
let FPE_INTDIV: c_int = 7
let FPE_INTOVF: c_int = 8
let FPE_NOOP: c_int = 0
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
let GID_MAX: c_uint = 2147483647
let GI_FIXED_LENGTH_MASK: c_uint = 0x0000ffff
let GI_NOT_FIXED_LENGTH: c_uint = 0x40000000
let GI_SET_FIXED_LENGTH: c_uint = 0x80000000
let GROUPINFO_DEFAULT_SIZE: c_int = 256
fn HASUTF8EXTRALEN[T](c: T) -> T:
    (c >= 0xc0)
let HAVE_CONFIG_H: c_int = 1
let HEAP_LIMIT: c_int = 20000000
// untranslatable fn-like macro
fn HTONL() -> Never:
    comptime_error("untranslatable C macro: HTONL")
// untranslatable fn-like macro
fn HTONLL() -> Never:
    comptime_error("untranslatable C macro: HTONLL")
// untranslatable fn-like macro
fn HTONS() -> Never:
    comptime_error("untranslatable C macro: HTONS")
let ILL_BADSTK: c_int = 8
let ILL_COPROC: c_int = 7
let ILL_ILLADR: c_int = 5
let ILL_ILLOPC: c_int = 1
let ILL_ILLOPN: c_int = 4
let ILL_ILLTRP: c_int = 2
let ILL_NOOP: c_int = 0
let ILL_PRVOPC: c_int = 3
let ILL_PRVREG: c_int = 6
let IMM2_SIZE: c_int = 2
fn INT16_C[T](v: T) -> T:
    v
let INT16_MAX: c_int = 32767
let INT16_MIN: c_int = -32768
fn INT32_C[T](v: T) -> T:
    v
let INT32_MAX: c_int = 2147483647
let INT32_MIN: c_int = -2147483646
fn INT64_C[T](v: T) -> i64:
    (v as i64)
let INT64_MAX: c_longlong = 9223372036854775807
let INT64_MIN: c_int = -9223372036854775806
fn INT8_C[T](v: T) -> T:
    v
let INT8_MAX: c_int = 127
let INT8_MIN: c_int = -128
fn INTMAX_C[T](v: T) -> i64:
    (v as i64)
let INTMAX_MAX: c_int = INTMAX_C(9223372036854775807)
let INTMAX_MIN: c_int = ((0 - INTMAX_MAX) - 1)
let INTPTR_MAX: c_long = 9223372036854775807
let INTPTR_MIN: c_int = -9223372036854775806
let INT_FAST16_MAX: c_int = 32767
let INT_FAST16_MIN: c_int = -32768
let INT_FAST32_MAX: c_int = 2147483647
let INT_FAST32_MIN: c_int = -2147483646
let INT_FAST64_MAX: c_int = 9223372036854775807
let INT_FAST64_MIN: c_int = -9223372036854775806
let INT_FAST8_MAX: c_int = 127
let INT_FAST8_MIN: c_int = -128
let INT_LEAST16_MAX: c_int = 32767
let INT_LEAST16_MIN: c_int = -32768
let INT_LEAST32_MAX: c_int = 2147483647
let INT_LEAST32_MIN: c_int = -2147483646
let INT_LEAST64_MAX: c_int = 9223372036854775807
let INT_LEAST64_MIN: c_int = -9223372036854775806
let INT_LEAST8_MAX: c_int = 127
let INT_LEAST8_MIN: c_int = -128
let INT_MAX: c_int = 2147483647
let INT_MIN: c_int = -2147483646
let IOPOL_ATIME_UPDATES_DEFAULT: c_int = 0
let IOPOL_ATIME_UPDATES_OFF: c_int = 1
let IOPOL_DEFAULT: c_int = 0
let IOPOL_IMPORTANT: c_int = 1
let IOPOL_MATERIALIZE_DATALESS_FILES_BASIC_MASK: c_int = 3
let IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT: c_int = 0
let IOPOL_MATERIALIZE_DATALESS_FILES_OFF: c_int = 1
let IOPOL_MATERIALIZE_DATALESS_FILES_ON: c_int = 2
let IOPOL_MATERIALIZE_DATALESS_FILES_ORIG: c_int = 4
let IOPOL_NORMAL: c_int = 1
let IOPOL_PASSIVE: c_int = 2
let IOPOL_SCOPE_DARWIN_BG: c_int = 2
let IOPOL_SCOPE_PROCESS: c_int = 0
let IOPOL_SCOPE_THREAD: c_int = 1
let IOPOL_STANDARD: c_int = 5
let IOPOL_THROTTLE: c_int = 3
let IOPOL_TYPE_DISK: c_int = 0
let IOPOL_TYPE_VFS_ALLOW_LOW_SPACE_WRITES: c_int = 9
let IOPOL_TYPE_VFS_ATIME_UPDATES: c_int = 2
let IOPOL_TYPE_VFS_DISALLOW_RW_FOR_O_EVTONLY: c_int = 10
let IOPOL_TYPE_VFS_ENTITLED_RESERVE_ACCESS: c_int = 14
let IOPOL_TYPE_VFS_IGNORE_CONTENT_PROTECTION: c_int = 6
let IOPOL_TYPE_VFS_IGNORE_PERMISSIONS: c_int = 7
let IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES: c_int = 3
let IOPOL_TYPE_VFS_SKIP_MTIME_UPDATE: c_int = 8
let IOPOL_TYPE_VFS_STATFS_NO_DATA_VOLUME: c_int = 4
let IOPOL_TYPE_VFS_TRIGGER_RESOLVE: c_int = 5
let IOPOL_UTILITY: c_int = 4
let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_OFF: c_int = 0
let IOPOL_VFS_ALLOW_LOW_SPACE_WRITES_ON: c_int = 1
let IOPOL_VFS_CONTENT_PROTECTION_DEFAULT: c_int = 0
let IOPOL_VFS_CONTENT_PROTECTION_IGNORE: c_int = 1
let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_DEFAULT: c_int = 0
let IOPOL_VFS_DISALLOW_RW_FOR_O_EVTONLY_ON: c_int = 1
let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_OFF: c_int = 0
let IOPOL_VFS_ENTITLED_RESERVE_ACCESS_ON: c_int = 1
let IOPOL_VFS_IGNORE_PERMISSIONS_OFF: c_int = 0
let IOPOL_VFS_IGNORE_PERMISSIONS_ON: c_int = 1
let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_DEFAULT: c_int = 0
let IOPOL_VFS_NOCACHE_WRITE_FS_BLKSIZE_ON: c_int = 1
let IOPOL_VFS_SKIP_MTIME_UPDATE_IGNORE: c_int = 2
let IOPOL_VFS_SKIP_MTIME_UPDATE_OFF: c_int = 0
let IOPOL_VFS_SKIP_MTIME_UPDATE_ON: c_int = 1
let IOPOL_VFS_STATFS_FORCE_NO_DATA_VOLUME: c_int = 1
let IOPOL_VFS_STATFS_NO_DATA_VOLUME_DEFAULT: c_int = 0
let IOPOL_VFS_TRIGGER_RESOLVE_DEFAULT: c_int = 0
let IOPOL_VFS_TRIGGER_RESOLVE_OFF: c_int = 1
let IOV_MAX: c_int = 1024
fn IS_DIGIT[T](x: T) -> T:
    ((x >= CHAR_0) and (x <= CHAR_9))
// untranslatable fn-like macro
fn IS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: IS_NEWLINE")
let LAST_AUTOTAB_LEFT_OP: c_int = OP_EXTUNI
let LAST_AUTOTAB_RIGHT_OP: c_int = OP_DOLLM
let LINE_MAX: c_int = 2048
let LINK_MAX: c_int = 32767
let LINK_SIZE: c_int = 2
let LLONG_MAX: c_int = 9223372036854775807
let LLONG_MIN: c_int = -9223372036854775806
let LONG_BIT: c_int = 64
let LONG_LONG_MAX: c_int = 9223372036854775807
let LONG_LONG_MIN: c_int = -9223372036854775806
let LONG_MAX: c_int = 9223372036854775807
let LONG_MIN: c_int = -9223372036854775806
let LT_OBJDIR = ".libs/"
let L_ctermid: c_int = 1024
let L_tmpnam: c_int = 1024
let MAGIC_NUMBER: c_ulong = 0x50435245
// untranslatable fn-like macro
fn MAPBIT() -> Never:
    comptime_error("untranslatable C macro: MAPBIT")
// untranslatable fn-like macro
fn MAPSET() -> Never:
    comptime_error("untranslatable C macro: MAPSET")
let MATCH_LIMIT: c_int = 10000000
let MATCH_LIMIT_DEPTH: c_int = 10000000
// untranslatable fn-like macro
fn MAX_255() -> Never:
    comptime_error("untranslatable C macro: MAX_255")
let MAX_CANON: c_int = 1024
let MAX_GROUP_NUMBER: c_uint = 65535
let MAX_INPUT: c_int = 1024
let MAX_NAME_COUNT: c_int = 10000
let MAX_NAME_SIZE: c_int = 128
let MAX_NON_UTF_CHAR: f64 = 4294967295.0
let MAX_PATTERN_SIZE: c_int = 65536
let MAX_REPEAT_COUNT: c_uint = 65535
let MAX_UCHAR_VALUE: c_uint = 0xff
let MAX_UTF_CODE_POINT: c_int = 0x10ffff
let MAX_VARLOOKBEHIND: c_int = 255
let MB_LEN_MAX: c_int = 6
let META_ACCEPT: c_uint = 0x802e0000
let META_ALT: c_uint = 0x80010000
let META_ASTERISK: c_uint = 0x80380000
let META_ASTERISK_PLUS: c_uint = 0x80390000
let META_ASTERISK_QUERY: c_uint = 0x803a0000
let META_ATOMIC: c_uint = 0x80020000
let META_ATOMIC_SCRIPT_RUN: c_uint = 0x8fff0000
let META_BACKREF: c_uint = 0x80030000
let META_BACKREF_BYNAME: c_uint = 0x80040000
let META_BIGVALUE: c_uint = 0x80050000
let META_CALLOUT_NUMBER: c_uint = 0x80060000
let META_CALLOUT_STRING: c_uint = 0x80070000
let META_CAPTURE: c_uint = 0x80080000
let META_CAPTURE_NAME: c_uint = 0x80180000
let META_CAPTURE_NUMBER: c_uint = 0x80190000
let META_CIRCUMFLEX: c_uint = 0x80090000
let META_CLASS: c_uint = 0x800a0000
let META_CLASS_EMPTY: c_uint = 0x800b0000
let META_CLASS_EMPTY_NOT: c_uint = 0x800c0000
let META_CLASS_END: c_uint = 0x800d0000
let META_CLASS_NOT: c_uint = 0x800e0000
fn META_CODE[T](x: T) -> T:
    (x & 0xffff0000)
let META_COMMIT: c_uint = 0x80300000
let META_COMMIT_ARG: c_uint = 0x80310000
let META_COND_ASSERT: c_uint = 0x800f0000
let META_COND_DEFINE: c_uint = 0x80100000
let META_COND_NAME: c_uint = 0x80110000
let META_COND_NUMBER: c_uint = 0x80120000
let META_COND_RNAME: c_uint = 0x80130000
let META_COND_RNUMBER: c_uint = 0x80140000
let META_COND_VERSION: c_uint = 0x80150000
fn META_DATA[T](x: T) -> T:
    (x & 0x0000ffff)
// untranslatable fn-like macro
fn META_DIFF() -> Never:
    comptime_error("untranslatable C macro: META_DIFF")
let META_DOLLAR: c_uint = 0x801a0000
let META_DOT: c_uint = 0x801b0000
let META_ECLASS_AND: c_uint = 0x80440000
let META_ECLASS_NOT: c_uint = 0x80480000
let META_ECLASS_OR: c_uint = 0x80450000
let META_ECLASS_SUB: c_uint = 0x80460000
let META_ECLASS_XOR: c_uint = 0x80470000
let META_END: c_uint = 0x80000000
let META_ESCAPE: c_uint = 0x801c0000
let META_FAIL: c_uint = 0x802f0000
let META_FIRST_QUANTIFIER: c_int = 0x80380000
let META_KET: c_uint = 0x801d0000
let META_LOOKAHEAD: c_uint = 0x80270000
let META_LOOKAHEADNOT: c_uint = 0x80280000
let META_LOOKAHEAD_NA: c_uint = 0x802b0000
let META_LOOKBEHIND: c_uint = 0x80290000
let META_LOOKBEHINDNOT: c_uint = 0x802a0000
let META_LOOKBEHIND_NA: c_uint = 0x802c0000
let META_MARK: c_uint = 0x802d0000
let META_MINMAX: c_uint = 0x80410000
let META_MINMAX_PLUS: c_uint = 0x80420000
let META_MINMAX_QUERY: c_uint = 0x80430000
let META_NOCAPTURE: c_uint = 0x801e0000
let META_OFFSET: c_uint = 0x80160000
let META_OPTIONS: c_uint = 0x801f0000
let META_PLUS: c_uint = 0x803b0000
let META_PLUS_PLUS: c_uint = 0x803c0000
let META_PLUS_QUERY: c_uint = 0x803d0000
let META_POSIX: c_uint = 0x80200000
let META_POSIX_NEG: c_uint = 0x80210000
let META_PRUNE: c_uint = 0x80320000
let META_PRUNE_ARG: c_uint = 0x80330000
let META_QUERY: c_uint = 0x803e0000
let META_QUERY_PLUS: c_uint = 0x803f0000
let META_QUERY_QUERY: c_uint = 0x80400000
let META_RANGE_ESCAPED: c_uint = 0x80220000
let META_RANGE_LITERAL: c_uint = 0x80230000
let META_RECURSE: c_uint = 0x80240000
let META_RECURSE_BYNAME: c_uint = 0x80250000
let META_SCRIPT_RUN: c_uint = 0x80260000
let META_SCS: c_uint = 0x80170000
let META_SKIP: c_uint = 0x80340000
let META_SKIP_ARG: c_uint = 0x80350000
let META_THEN: c_uint = 0x80360000
let META_THEN_ARG: c_uint = 0x80370000
let MINSIGSTKSZ: c_int = 32768
// untranslatable fn-like macro
fn NAMED_GROUP_GET_HASH() -> Never:
    comptime_error("untranslatable C macro: NAMED_GROUP_GET_HASH")
let NAMED_GROUP_HASH_MASK: c_int = 0x7fff
let NAMED_GROUP_IS_DUPNAME: c_int = 0x8000
let NAMED_GROUP_LIST_SIZE: c_int = 20
let NAME_MAX: c_int = 255
let NEWLINE_DEFAULT: c_int = 2
let NGROUPS_MAX: c_int = 16
let NLTYPE_ANY: c_int = 1
let NLTYPE_ANYCRLF: c_int = 2
let NLTYPE_FIXED: c_int = 0
let NL_ARGMAX: c_int = 9
let NL_LANGMAX: c_int = 14
let NL_MSGMAX: c_int = 32767
let NL_NMAX: c_int = 1
let NL_SETMAX: c_int = 255
let NL_TEXTMAX: c_int = 2048
let NOTACHAR: c_int = 0xffffffff
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
let NZERO: c_int = 20
let OFF_MAX: c_int = 9223372036854775807
let OFF_MIN: c_int = -9223372036854775806
let OFLOW_MAX: c_int = 2147483627
let OPEN_MAX: c_int = 10240
let PACKAGE = "pcre2"
let PACKAGE_BUGREPORT = ""
let PACKAGE_NAME = "PCRE2"
let PACKAGE_STRING = "PCRE2 10.48-DEV"
let PACKAGE_TARNAME = "pcre2"
let PACKAGE_URL = ""
let PACKAGE_VERSION = "10.48-DEV"
let PARENS_NEST_LIMIT: c_int = 250
// untranslatable fn-like macro
fn PARSED_LITERAL() -> Never:
    comptime_error("untranslatable C macro: PARSED_LITERAL")
let PARSED_PATTERN_DEFAULT_SIZE: c_int = 1024
let PASS_MAX: c_int = 128
let PATH_MAX: c_int = 1024
let PCRE2GREP_BUFSIZE: c_int = 20480
let PCRE2GREP_MAX_BUFSIZE: c_int = 1048576
let PCRE2_ALLOW_EMPTY_CLASS: c_uint = 0x00000001
let PCRE2_ALT_BSUX: c_uint = 0x00000002
let PCRE2_ALT_CIRCUMFLEX: c_uint = 0x00200000
let PCRE2_ALT_EXTENDED_CLASS: c_uint = 0x08000000
let PCRE2_ALT_VERBNAMES: c_uint = 0x00400000
let PCRE2_ANCHORED: c_uint = 0x80000000
// untranslatable fn-like macro
fn PCRE2_ASSERT() -> Never:
    comptime_error("untranslatable C macro: PCRE2_ASSERT")
let PCRE2_AUTO_CALLOUT: c_uint = 0x00000004
let PCRE2_AUTO_POSSESS: c_int = 64
let PCRE2_AUTO_POSSESS_OFF: c_int = 65
let PCRE2_BSR_ANYCRLF: c_int = 2
let PCRE2_BSR_SET: c_uint = 0x00004000
let PCRE2_BSR_UNICODE: c_int = 1
let PCRE2_CALLOUT_BACKTRACK: c_uint = 0x00000002
let PCRE2_CALLOUT_STARTMATCH: c_uint = 0x00000001
let PCRE2_CASELESS: c_uint = 0x00000008
let PCRE2_CODE_UNIT_WIDTH: c_int = 8
let PCRE2_CONFIG_BSR: c_int = 0
let PCRE2_CONFIG_COMPILED_WIDTHS: c_int = 14
let PCRE2_CONFIG_DEPTHLIMIT: c_int = 7
let PCRE2_CONFIG_EFFECTIVE_LINKSIZE: c_int = 16
let PCRE2_CONFIG_HEAPLIMIT: c_int = 12
let PCRE2_CONFIG_JIT: c_int = 1
let PCRE2_CONFIG_JITTARGET: c_int = 2
let PCRE2_CONFIG_LINKSIZE: c_int = 3
let PCRE2_CONFIG_MATCHLIMIT: c_int = 4
let PCRE2_CONFIG_NEVER_BACKSLASH_C: c_int = 13
let PCRE2_CONFIG_NEWLINE: c_int = 5
let PCRE2_CONFIG_PARENSLIMIT: c_int = 6
let PCRE2_CONFIG_RECURSIONLIMIT: c_int = 7
let PCRE2_CONFIG_STACKRECURSE: c_int = 8
let PCRE2_CONFIG_TABLES_LENGTH: c_int = 15
let PCRE2_CONFIG_UNICODE: c_int = 9
let PCRE2_CONFIG_UNICODE_VERSION: c_int = 10
let PCRE2_CONFIG_VERSION: c_int = 11
let PCRE2_CONVERT_GLOB: c_uint = 0x00000010
let PCRE2_CONVERT_GLOB_NO_STARSTAR: c_uint = 0x00000050
let PCRE2_CONVERT_GLOB_NO_WILD_SEPARATOR: c_uint = 0x00000030
let PCRE2_CONVERT_NO_UTF_CHECK: c_uint = 0x00000002
let PCRE2_CONVERT_POSIX_BASIC: c_uint = 0x00000004
let PCRE2_CONVERT_POSIX_EXTENDED: c_uint = 0x00000008
let PCRE2_CONVERT_UTF: c_uint = 0x00000001
let PCRE2_COPY_MATCHED_SUBJECT: c_uint = 0x00004000
let PCRE2_DATE: c_int = 1994
// untranslatable fn-like macro
fn PCRE2_DEBUG_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_DEBUG_UNREACHABLE")
let PCRE2_DEREF_TABLES: c_uint = 0x00040000
let PCRE2_DFA_RESTART: c_uint = 0x00000040
let PCRE2_DFA_SHORTEST: c_uint = 0x00000080
let PCRE2_DISABLE_RECURSELOOP_CHECK: c_uint = 0x00040000
let PCRE2_DOLLAR_ENDONLY: c_uint = 0x00000010
let PCRE2_DOTALL: c_uint = 0x00000020
let PCRE2_DOTSTAR_ANCHOR: c_int = 66
let PCRE2_DOTSTAR_ANCHOR_OFF: c_int = 67
let PCRE2_DUPCAPUSED: c_uint = 0x00200000
let PCRE2_DUPNAMES: c_uint = 0x00000040
let PCRE2_ENDANCHORED: c_uint = 0x20000000
let PCRE2_ERROR_ALPHA_ASSERTION_UNKNOWN: c_int = 195
let PCRE2_ERROR_BACKSLASH_C_CALLER_DISABLED: c_int = 183
let PCRE2_ERROR_BACKSLASH_C_LIBRARY_DISABLED: c_int = 185
let PCRE2_ERROR_BACKSLASH_C_SYNTAX: c_int = 168
let PCRE2_ERROR_BACKSLASH_G_SYNTAX: c_int = 157
let PCRE2_ERROR_BACKSLASH_K_IN_LOOKAROUND: c_int = 199
let PCRE2_ERROR_BACKSLASH_K_SYNTAX: c_int = 169
let PCRE2_ERROR_BACKSLASH_N_IN_CLASS: c_int = 171
let PCRE2_ERROR_BACKSLASH_O_MISSING_BRACE: c_int = 155
let PCRE2_ERROR_BACKSLASH_U_CODE_POINT_TOO_BIG: c_int = 177
let PCRE2_ERROR_BADDATA: c_int = -29
let PCRE2_ERROR_BADMAGIC: c_int = -31
let PCRE2_ERROR_BADMODE: c_int = -32
let PCRE2_ERROR_BADOFFSET: c_int = -33
let PCRE2_ERROR_BADOFFSETLIMIT: c_int = -56
let PCRE2_ERROR_BADOPTION: c_int = -34
let PCRE2_ERROR_BADREPESCAPE: c_int = -57
let PCRE2_ERROR_BADREPLACEMENT: c_int = -35
let PCRE2_ERROR_BADSERIALIZEDDATA: c_int = -62
let PCRE2_ERROR_BADSUBSPATTERN: c_int = -60
let PCRE2_ERROR_BADSUBSTITUTION: c_int = -59
let PCRE2_ERROR_BADUTFOFFSET: c_int = -36
let PCRE2_ERROR_BAD_BACKSLASH_K: c_int = -75
let PCRE2_ERROR_BAD_LITERAL_OPTIONS: c_int = 192
let PCRE2_ERROR_BAD_OPTIONS: c_int = 117
let PCRE2_ERROR_BAD_RELATIVE_REFERENCE: c_int = 129
let PCRE2_ERROR_BAD_SUBPATTERN_REFERENCE: c_int = 115
let PCRE2_ERROR_CALLOUT: c_int = -37
let PCRE2_ERROR_CALLOUT_BAD_STRING_DELIMITER: c_int = 182
let PCRE2_ERROR_CALLOUT_CALLER_DISABLED: c_int = 203
let PCRE2_ERROR_CALLOUT_NO_STRING_DELIMITER: c_int = 181
let PCRE2_ERROR_CALLOUT_NUMBER_TOO_BIG: c_int = 138
let PCRE2_ERROR_CALLOUT_STRING_TOO_LONG: c_int = 172
let PCRE2_ERROR_CLASS_INVALID_RANGE: c_int = 150
let PCRE2_ERROR_CLASS_RANGE_ORDER: c_int = 108
let PCRE2_ERROR_CODE_POINT_TOO_BIG: c_int = 134
let PCRE2_ERROR_CONDITION_ASSERTION_EXPECTED: c_int = 128
let PCRE2_ERROR_CONVERT_SYNTAX: c_int = -64
let PCRE2_ERROR_DEFINE_TOO_MANY_BRANCHES: c_int = 154
let PCRE2_ERROR_DEPTHLIMIT: c_int = -53
let PCRE2_ERROR_DFA_BADRESTART: c_int = -38
let PCRE2_ERROR_DFA_RECURSE: c_int = -39
let PCRE2_ERROR_DFA_UCOND: c_int = -40
let PCRE2_ERROR_DFA_UFUNC: c_int = -41
let PCRE2_ERROR_DFA_UINVALID_UTF: c_int = -66
let PCRE2_ERROR_DFA_UITEM: c_int = -42
let PCRE2_ERROR_DFA_WSSIZE: c_int = -43
let PCRE2_ERROR_DIFFSUBSOFFSET: c_int = -73
let PCRE2_ERROR_DIFFSUBSOPTIONS: c_int = -74
let PCRE2_ERROR_DIFFSUBSPATTERN: c_int = -71
let PCRE2_ERROR_DIFFSUBSSUBJECT: c_int = -72
let PCRE2_ERROR_DUPLICATE_SUBPATTERN_NAME: c_int = 143
let PCRE2_ERROR_ECLASS_EXPECTED_OPERAND: c_int = 210
let PCRE2_ERROR_ECLASS_HINT_SQUARE_BRACKET: c_int = 212
let PCRE2_ERROR_ECLASS_INVALID_OPERATOR: c_int = 208
let PCRE2_ERROR_ECLASS_MIXED_OPERATORS: c_int = 211
let PCRE2_ERROR_ECLASS_NEST_TOO_DEEP: c_int = 207
let PCRE2_ERROR_ECLASS_UNEXPECTED_OPERATOR: c_int = 209
let PCRE2_ERROR_END_BACKSLASH: c_int = 101
let PCRE2_ERROR_END_BACKSLASH_C: c_int = 102
let PCRE2_ERROR_ESCAPE_INVALID_IN_CLASS: c_int = 107
let PCRE2_ERROR_ESCAPE_INVALID_IN_VERB: c_int = 140
let PCRE2_ERROR_EXPECTED_CAPTURE_GROUP: c_int = 217
let PCRE2_ERROR_EXTRA_CASING_INCOMPATIBLE: c_int = 206
let PCRE2_ERROR_EXTRA_CASING_REQUIRES_UNICODE: c_int = 204
let PCRE2_ERROR_HEAPLIMIT: c_int = -63
let PCRE2_ERROR_HEAP_FAILED: c_int = 121
let PCRE2_ERROR_INTERNAL: c_int = -44
let PCRE2_ERROR_INTERNAL_BAD_CODE: c_int = 189
let PCRE2_ERROR_INTERNAL_BAD_CODE_AUTO_POSSESS: c_int = 180
let PCRE2_ERROR_INTERNAL_BAD_CODE_IN_SKIP: c_int = 190
let PCRE2_ERROR_INTERNAL_BAD_CODE_LOOKBEHINDS: c_int = 170
let PCRE2_ERROR_INTERNAL_CODE_OVERFLOW: c_int = 123
let PCRE2_ERROR_INTERNAL_DUPMATCH: c_int = -65
let PCRE2_ERROR_INTERNAL_MISSING_SUBPATTERN: c_int = 153
let PCRE2_ERROR_INTERNAL_OVERRAN_WORKSPACE: c_int = 152
let PCRE2_ERROR_INTERNAL_PARSED_OVERFLOW: c_int = 163
let PCRE2_ERROR_INTERNAL_STUDY_ERROR: c_int = 131
let PCRE2_ERROR_INTERNAL_UNEXPECTED_REPEAT: c_int = 110
let PCRE2_ERROR_INTERNAL_UNKNOWN_NEWLINE: c_int = 156
let PCRE2_ERROR_INVALIDOFFSET: c_int = -67
let PCRE2_ERROR_INVALID_AFTER_PARENS_QUERY: c_int = 111
let PCRE2_ERROR_INVALID_HEXADECIMAL: c_int = 167
let PCRE2_ERROR_INVALID_HYPHEN_IN_OPTIONS: c_int = 194
let PCRE2_ERROR_INVALID_OCTAL: c_int = 164
let PCRE2_ERROR_INVALID_SUBPATTERN_NAME: c_int = 144
let PCRE2_ERROR_JIT_BADOPTION: c_int = -45
let PCRE2_ERROR_JIT_STACKLIMIT: c_int = -46
let PCRE2_ERROR_JIT_UNSUPPORTED: c_int = -68
let PCRE2_ERROR_LOOKBEHIND_INVALID_BACKSLASH_C: c_int = 136
let PCRE2_ERROR_LOOKBEHIND_NOT_FIXED_LENGTH: c_int = 125
let PCRE2_ERROR_LOOKBEHIND_TOO_COMPLICATED: c_int = 135
let PCRE2_ERROR_LOOKBEHIND_TOO_LONG: c_int = 187
let PCRE2_ERROR_MALFORMED_UNICODE_PROPERTY: c_int = 146
let PCRE2_ERROR_MARK_MISSING_ARGUMENT: c_int = 166
let PCRE2_ERROR_MATCHLIMIT: c_int = -47
let PCRE2_ERROR_MAX_VAR_LOOKBEHIND_EXCEEDED: c_int = 200
let PCRE2_ERROR_MISSING_CALLOUT_CLOSING: c_int = 139
let PCRE2_ERROR_MISSING_CLOSING_PARENTHESIS: c_int = 114
let PCRE2_ERROR_MISSING_COMMENT_CLOSING: c_int = 118
let PCRE2_ERROR_MISSING_CONDITION_CLOSING: c_int = 124
let PCRE2_ERROR_MISSING_NAME_TERMINATOR: c_int = 142
let PCRE2_ERROR_MISSING_NUMBER_TERMINATOR: c_int = 219
let PCRE2_ERROR_MISSING_OCTAL_DIGIT: c_int = 198
let PCRE2_ERROR_MISSING_OCTAL_OR_HEX_DIGITS: c_int = 178
let PCRE2_ERROR_MISSING_OPENING_PARENTHESIS: c_int = 218
let PCRE2_ERROR_MISSING_SQUARE_BRACKET: c_int = 106
let PCRE2_ERROR_MIXEDTABLES: c_int = -30
let PCRE2_ERROR_NOMATCH: c_int = -1
let PCRE2_ERROR_NOMEMORY: c_int = -48
let PCRE2_ERROR_NOSUBSTRING: c_int = -49
let PCRE2_ERROR_NOUNIQUESUBSTRING: c_int = -50
let PCRE2_ERROR_NO_SURROGATES_IN_UTF16: c_int = 191
let PCRE2_ERROR_NULL: c_int = -51
let PCRE2_ERROR_NULL_ERROROFFSET: c_int = 220
let PCRE2_ERROR_NULL_PATTERN: c_int = 116
let PCRE2_ERROR_OCTAL_BYTE_TOO_BIG: c_int = 151
let PCRE2_ERROR_OVERSIZE_PYTHON_OCTAL: c_int = 202
let PCRE2_ERROR_PARENS_QUERY_R_MISSING_CLOSING: c_int = 158
let PCRE2_ERROR_PARENTHESES_NEST_TOO_DEEP: c_int = 119
let PCRE2_ERROR_PARENTHESES_STACK_CHECK: c_int = 133
let PCRE2_ERROR_PARTIAL: c_int = -2
let PCRE2_ERROR_PARTIALSUBS: c_int = -76
let PCRE2_ERROR_PATTERN_COMPILED_SIZE_TOO_BIG: c_int = 201
let PCRE2_ERROR_PATTERN_STRING_TOO_LONG: c_int = 188
let PCRE2_ERROR_PATTERN_TOO_COMPLICATED: c_int = 186
let PCRE2_ERROR_PATTERN_TOO_LARGE: c_int = 120
let PCRE2_ERROR_PERL_ECLASS_EMPTY_EXPR: c_int = 214
let PCRE2_ERROR_PERL_ECLASS_MISSING_CLOSE: c_int = 215
let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_CHAR: c_int = 216
let PCRE2_ERROR_PERL_ECLASS_UNEXPECTED_EXPR: c_int = 213
let PCRE2_ERROR_POSIX_CLASS_NOT_IN_CLASS: c_int = 112
let PCRE2_ERROR_POSIX_NO_SUPPORT_COLLATING: c_int = 113
let PCRE2_ERROR_QUANTIFIER_INVALID: c_int = 109
let PCRE2_ERROR_QUANTIFIER_OUT_OF_ORDER: c_int = 104
let PCRE2_ERROR_QUANTIFIER_TOO_BIG: c_int = 105
let PCRE2_ERROR_QUERY_BARJX_NEST_TOO_DEEP: c_int = 184
let PCRE2_ERROR_RECURSELOOP: c_int = -52
let PCRE2_ERROR_RECURSIONLIMIT: c_int = -53
let PCRE2_ERROR_REPLACECASE: c_int = -69
let PCRE2_ERROR_REPMISSINGBRACE: c_int = -58
let PCRE2_ERROR_SCRIPT_RUN_NOT_AVAILABLE: c_int = 196
let PCRE2_ERROR_SUBPATTERN_NAMES_MISMATCH: c_int = 165
let PCRE2_ERROR_SUBPATTERN_NAME_EXPECTED: c_int = 162
let PCRE2_ERROR_SUBPATTERN_NAME_TOO_LONG: c_int = 148
let PCRE2_ERROR_SUBPATTERN_NUMBER_TOO_BIG: c_int = 161
let PCRE2_ERROR_SUPPORTED_ONLY_IN_UNICODE: c_int = 193
let PCRE2_ERROR_TOOLARGEREPLACE: c_int = -70
let PCRE2_ERROR_TOOMANYREPLACE: c_int = -61
let PCRE2_ERROR_TOO_MANY_CAPTURES: c_int = 197
let PCRE2_ERROR_TOO_MANY_CONDITION_BRANCHES: c_int = 127
let PCRE2_ERROR_TOO_MANY_NAMED_SUBPATTERNS: c_int = 149
let PCRE2_ERROR_TURKISH_CASING_REQUIRES_UTF: c_int = 205
let PCRE2_ERROR_UCP_IS_DISABLED: c_int = 175
let PCRE2_ERROR_UNAVAILABLE: c_int = -54
let PCRE2_ERROR_UNICODE_DISALLOWED_CODE_POINT: c_int = 173
let PCRE2_ERROR_UNICODE_NOT_SUPPORTED: c_int = 132
let PCRE2_ERROR_UNICODE_PROPERTIES_UNAVAILABLE: c_int = 145
let PCRE2_ERROR_UNKNOWN_ESCAPE: c_int = 103
let PCRE2_ERROR_UNKNOWN_POSIX_CLASS: c_int = 130
let PCRE2_ERROR_UNKNOWN_UNICODE_PROPERTY: c_int = 147
let PCRE2_ERROR_UNMATCHED_CLOSING_PARENTHESIS: c_int = 122
let PCRE2_ERROR_UNRECOGNIZED_AFTER_QUERY_P: c_int = 141
let PCRE2_ERROR_UNSET: c_int = -55
let PCRE2_ERROR_UNSUPPORTED_ESCAPE_SEQUENCE: c_int = 137
let PCRE2_ERROR_UTF16_ERR1: c_int = -24
let PCRE2_ERROR_UTF16_ERR2: c_int = -25
let PCRE2_ERROR_UTF16_ERR3: c_int = -26
let PCRE2_ERROR_UTF32_ERR1: c_int = -27
let PCRE2_ERROR_UTF32_ERR2: c_int = -28
let PCRE2_ERROR_UTF8_ERR1: c_int = -3
let PCRE2_ERROR_UTF8_ERR10: c_int = -12
let PCRE2_ERROR_UTF8_ERR11: c_int = -13
let PCRE2_ERROR_UTF8_ERR12: c_int = -14
let PCRE2_ERROR_UTF8_ERR13: c_int = -15
let PCRE2_ERROR_UTF8_ERR14: c_int = -16
let PCRE2_ERROR_UTF8_ERR15: c_int = -17
let PCRE2_ERROR_UTF8_ERR16: c_int = -18
let PCRE2_ERROR_UTF8_ERR17: c_int = -19
let PCRE2_ERROR_UTF8_ERR18: c_int = -20
let PCRE2_ERROR_UTF8_ERR19: c_int = -21
let PCRE2_ERROR_UTF8_ERR2: c_int = -4
let PCRE2_ERROR_UTF8_ERR20: c_int = -22
let PCRE2_ERROR_UTF8_ERR21: c_int = -23
let PCRE2_ERROR_UTF8_ERR3: c_int = -5
let PCRE2_ERROR_UTF8_ERR4: c_int = -6
let PCRE2_ERROR_UTF8_ERR5: c_int = -7
let PCRE2_ERROR_UTF8_ERR6: c_int = -8
let PCRE2_ERROR_UTF8_ERR7: c_int = -9
let PCRE2_ERROR_UTF8_ERR8: c_int = -10
let PCRE2_ERROR_UTF8_ERR9: c_int = -11
let PCRE2_ERROR_UTF_IS_DISABLED: c_int = 174
let PCRE2_ERROR_VERB_ARGUMENT_NOT_ALLOWED: c_int = 159
let PCRE2_ERROR_VERB_NAME_TOO_LONG: c_int = 176
let PCRE2_ERROR_VERB_UNKNOWN: c_int = 160
let PCRE2_ERROR_VERSION_CONDITION_SYNTAX: c_int = 179
let PCRE2_ERROR_ZERO_RELATIVE_REFERENCE: c_int = 126
let PCRE2_EXTENDED: c_uint = 0x00000080
let PCRE2_EXTENDED_MORE: c_uint = 0x01000000
let PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK: c_uint = 0x00000040
let PCRE2_EXTRA_ALLOW_SURROGATE_ESCAPES: c_uint = 0x00000001
let PCRE2_EXTRA_ALT_BSUX: c_uint = 0x00000020
let PCRE2_EXTRA_ASCII_BSD: c_uint = 0x00000100
let PCRE2_EXTRA_ASCII_BSS: c_uint = 0x00000200
let PCRE2_EXTRA_ASCII_BSW: c_uint = 0x00000400
let PCRE2_EXTRA_ASCII_DIGIT: c_uint = 0x00001000
let PCRE2_EXTRA_ASCII_POSIX: c_uint = 0x00000800
let PCRE2_EXTRA_BAD_ESCAPE_IS_LITERAL: c_uint = 0x00000002
let PCRE2_EXTRA_CASELESS_RESTRICT: c_uint = 0x00000080
let PCRE2_EXTRA_ESCAPED_CR_IS_LF: c_uint = 0x00000010
let PCRE2_EXTRA_MATCH_LINE: c_uint = 0x00000008
let PCRE2_EXTRA_MATCH_WORD: c_uint = 0x00000004
let PCRE2_EXTRA_NEVER_CALLOUT: c_uint = 0x00008000
let PCRE2_EXTRA_NO_BS0: c_uint = 0x00004000
let PCRE2_EXTRA_PYTHON_OCTAL: c_uint = 0x00002000
let PCRE2_EXTRA_TURKISH_CASING: c_uint = 0x00010000
let PCRE2_FIRSTCASELESS: c_uint = 0x00000020
let PCRE2_FIRSTLINE: c_uint = 0x00000100
let PCRE2_FIRSTMAPSET: c_uint = 0x00000040
let PCRE2_FIRSTSET: c_uint = 0x00000010
// untranslatable fn-like macro
fn PCRE2_GLUE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_GLUE")
let PCRE2_HASACCEPT: c_uint = 0x00800000
let PCRE2_HASBKC: c_uint = 0x00400000
let PCRE2_HASBKPORX: c_uint = 0x00100000
let PCRE2_HASBSK: c_uint = 0x01000000
let PCRE2_HASCRORLF: c_uint = 0x00000800
let PCRE2_HASTHEN: c_uint = 0x00001000
let PCRE2_INFO_ALLOPTIONS: c_int = 0
let PCRE2_INFO_ARGOPTIONS: c_int = 1
let PCRE2_INFO_BACKREFMAX: c_int = 2
let PCRE2_INFO_BSR: c_int = 3
let PCRE2_INFO_CAPTURECOUNT: c_int = 4
let PCRE2_INFO_DEPTHLIMIT: c_int = 21
let PCRE2_INFO_EXTRAOPTIONS: c_int = 26
let PCRE2_INFO_FIRSTBITMAP: c_int = 7
let PCRE2_INFO_FIRSTCODETYPE: c_int = 6
let PCRE2_INFO_FIRSTCODEUNIT: c_int = 5
let PCRE2_INFO_FRAMESIZE: c_int = 24
let PCRE2_INFO_HASBACKSLASHC: c_int = 23
let PCRE2_INFO_HASCRORLF: c_int = 8
let PCRE2_INFO_HEAPLIMIT: c_int = 25
let PCRE2_INFO_JCHANGED: c_int = 9
let PCRE2_INFO_JITSIZE: c_int = 10
let PCRE2_INFO_LASTCODETYPE: c_int = 12
let PCRE2_INFO_LASTCODEUNIT: c_int = 11
let PCRE2_INFO_MATCHEMPTY: c_int = 13
let PCRE2_INFO_MATCHLIMIT: c_int = 14
let PCRE2_INFO_MAXLOOKBEHIND: c_int = 15
let PCRE2_INFO_MINLENGTH: c_int = 16
let PCRE2_INFO_NAMECOUNT: c_int = 17
let PCRE2_INFO_NAMEENTRYSIZE: c_int = 18
let PCRE2_INFO_NAMETABLE: c_int = 19
let PCRE2_INFO_NEWLINE: c_int = 20
let PCRE2_INFO_RECURSIONLIMIT: c_int = 21
let PCRE2_INFO_SIZE: c_int = 22
let PCRE2_JCHANGED: c_uint = 0x00000400
let PCRE2_JIT_COMPLETE: c_uint = 0x00000001
let PCRE2_JIT_INVALID_UTF: c_uint = 0x00000100
let PCRE2_JIT_PARTIAL_HARD: c_uint = 0x00000004
let PCRE2_JIT_PARTIAL_SOFT: c_uint = 0x00000002
let PCRE2_JIT_TEST_ALLOC: c_uint = 0x00000200
// untranslatable fn-like macro
fn PCRE2_JOIN() -> Never:
    comptime_error("untranslatable C macro: PCRE2_JOIN")
let PCRE2_LASTCASELESS: c_uint = 0x00000100
let PCRE2_LASTSET: c_uint = 0x00000080
let PCRE2_LITERAL: c_uint = 0x02000000
let PCRE2_MAJOR: c_int = 10
let PCRE2_MATCH_EMPTY: c_uint = 0x00002000
let PCRE2_MATCH_INVALID_UTF: c_uint = 0x04000000
let PCRE2_MATCH_UNSET_BACKREF: c_uint = 0x00000200
let PCRE2_MD_COPIED_SUBJECT: c_uint = 0x01
let PCRE2_MINOR: c_int = 48
let PCRE2_MODE16: c_uint = 0x00000002
let PCRE2_MODE32: c_uint = 0x00000004
let PCRE2_MODE8: c_uint = 0x00000001
let PCRE2_MODE_MASK: c_int = 7
let PCRE2_MULTILINE: c_uint = 0x00000400
let PCRE2_NEVER_BACKSLASH_C: c_uint = 0x00100000
let PCRE2_NEVER_UCP: c_uint = 0x00000800
let PCRE2_NEVER_UTF: c_uint = 0x00001000
let PCRE2_NEWLINE_ANY: c_int = 4
let PCRE2_NEWLINE_ANYCRLF: c_int = 5
let PCRE2_NEWLINE_CR: c_int = 1
let PCRE2_NEWLINE_CRLF: c_int = 3
let PCRE2_NEWLINE_LF: c_int = 2
let PCRE2_NEWLINE_NUL: c_int = 6
let PCRE2_NE_ATST_SET: c_uint = 0x00020000
let PCRE2_NL_SET: c_uint = 0x00008000
let PCRE2_NOJIT: c_uint = 0x00080000
let PCRE2_NOTBOL: c_uint = 0x00000001
let PCRE2_NOTEMPTY: c_uint = 0x00000004
let PCRE2_NOTEMPTY_ATSTART: c_uint = 0x00000008
let PCRE2_NOTEMPTY_SET: c_uint = 0x00010000
let PCRE2_NOTEOL: c_uint = 0x00000002
let PCRE2_NO_AUTO_CAPTURE: c_uint = 0x00002000
let PCRE2_NO_AUTO_POSSESS: c_uint = 0x00004000
let PCRE2_NO_DOTSTAR_ANCHOR: c_uint = 0x00008000
let PCRE2_NO_JIT: c_uint = 0x00002000
let PCRE2_NO_START_OPTIMIZE: c_uint = 0x00010000
let PCRE2_NO_UTF_CHECK: c_uint = 0x40000000
let PCRE2_OPTIMIZATION_ALL: c_uint = 0x00000007
let PCRE2_OPTIMIZATION_FULL: c_int = 1
let PCRE2_OPTIMIZATION_NONE: c_int = 0
let PCRE2_OPTIM_AUTO_POSSESS: c_uint = 0x00000001
let PCRE2_OPTIM_DOTSTAR_ANCHOR: c_uint = 0x00000002
let PCRE2_OPTIM_START_OPTIMIZE: c_uint = 0x00000004
let PCRE2_PARTIAL_HARD: c_uint = 0x00000020
let PCRE2_PARTIAL_SOFT: c_uint = 0x00000010
let PCRE2_STARTLINE: c_uint = 0x00000200
let PCRE2_START_OPTIMIZE: c_int = 68
let PCRE2_START_OPTIMIZE_OFF: c_int = 69
let PCRE2_SUBSTITUTE_CASE_LOWER: c_int = 1
let PCRE2_SUBSTITUTE_CASE_TITLE_FIRST: c_int = 3
let PCRE2_SUBSTITUTE_CASE_UPPER: c_int = 2
let PCRE2_SUBSTITUTE_EXTENDED: c_uint = 0x00000200
let PCRE2_SUBSTITUTE_GLOBAL: c_uint = 0x00000100
let PCRE2_SUBSTITUTE_LITERAL: c_uint = 0x00008000
let PCRE2_SUBSTITUTE_MATCHED: c_uint = 0x00010000
let PCRE2_SUBSTITUTE_OVERFLOW_LENGTH: c_uint = 0x00001000
let PCRE2_SUBSTITUTE_REPLACEMENT_ONLY: c_uint = 0x00020000
let PCRE2_SUBSTITUTE_UNKNOWN_UNSET: c_uint = 0x00000800
let PCRE2_SUBSTITUTE_UNSET_EMPTY: c_uint = 0x00000400
fn PCRE2_SUFFIX[T](a: T) -> T:
    PCRE2_GLUE(a, PCRE2_CODE_UNIT_WIDTH)
let PCRE2_UCP: c_uint = 0x00020000
let PCRE2_UNGREEDY: c_uint = 0x00040000
// untranslatable fn-like macro
fn PCRE2_UNREACHABLE() -> Never:
    comptime_error("untranslatable C macro: PCRE2_UNREACHABLE")
let PCRE2_USE_OFFSET_LIMIT: c_uint = 0x00800000
let PCRE2_UTF: c_uint = 0x00080000
let PC_DIGIT: c_int = 7
let PC_GRAPH: c_int = 8
let PC_PRINT: c_int = 9
let PC_PUNCT: c_int = 10
let PC_XDIGIT: c_int = 13
let PIPE_BUF: c_int = 512
let POLL_ERR: c_int = 4
let POLL_HUP: c_int = 6
let POLL_IN: c_int = 1
let POLL_MSG: c_int = 3
let POLL_OUT: c_int = 2
let POLL_PRI: c_int = 5
let PRIO_DARWIN_BG: c_int = 0x1000
let PRIO_DARWIN_NONUI: c_int = 0x1001
let PRIO_DARWIN_PROCESS: c_int = 4
let PRIO_DARWIN_THREAD: c_int = 3
let PRIO_MAX: c_int = 20
let PRIO_MIN: c_int = -20
let PRIO_PGRP: c_int = 1
let PRIO_PROCESS: c_int = 0
let PRIO_USER: c_int = 2
// untranslatable fn-like macro
fn PRIV() -> Never:
    comptime_error("untranslatable C macro: PRIV")
let PRIX16 = "hX"
let PRIX32 = "X"
let PRIXFAST16: c_int = PRIX16
let PRIXFAST32: c_int = PRIX32
let PRIXLEAST16: c_int = PRIX16
let PRIXLEAST32: c_int = PRIX32
let PRIXPTR = "lX"
let PRId16 = "hd"
let PRId32 = "d"
let PRIdFAST16: c_int = PRId16
let PRIdFAST32: c_int = PRId32
let PRIdLEAST16: c_int = PRId16
let PRIdLEAST32: c_int = PRId32
let PRIdPTR = "ld"
let PRIi16 = "hi"
let PRIi32 = "i"
let PRIiFAST16: c_int = PRIi16
let PRIiFAST32: c_int = PRIi32
let PRIiLEAST16: c_int = PRIi16
let PRIiLEAST32: c_int = PRIi32
let PRIiPTR = "li"
let PRIo16 = "ho"
let PRIo32 = "o"
let PRIoFAST16: c_int = PRIo16
let PRIoFAST32: c_int = PRIo32
let PRIoLEAST16: c_int = PRIo16
let PRIoLEAST32: c_int = PRIo32
let PRIoPTR = "lo"
let PRIu16 = "hu"
let PRIu32 = "u"
let PRIuFAST16: c_int = PRIu16
let PRIuFAST32: c_int = PRIu32
let PRIuLEAST16: c_int = PRIu16
let PRIuLEAST32: c_int = PRIu32
let PRIuPTR = "lu"
let PRIx16 = "hx"
let PRIx32 = "x"
let PRIxFAST16: c_int = PRIx16
let PRIxFAST32: c_int = PRIx32
let PRIxLEAST16: c_int = PRIx16
let PRIxLEAST32: c_int = PRIx32
let PRIxPTR = "lx"
let PTHREAD_DESTRUCTOR_ITERATIONS: c_int = 4
let PTHREAD_KEYS_MAX: c_int = 512
let PTHREAD_STACK_MIN: c_int = 16384
let PTRDIFF_MAX: c_int = INTMAX_MAX
let PTRDIFF_MIN: c_int = INTMAX_MIN
let PT_ALNUM: c_int = 5
let PT_ANY: c_int = 13
let PT_BIDICL: c_int = 11
let PT_BOOL: c_int = 12
let PT_CLIST: c_int = 9
let PT_GC: c_int = 1
let PT_LAMP: c_int = 0
let PT_NOTSCRIPT: c_int = 255
let PT_PC: c_int = 2
let PT_PXGRAPH: c_int = 14
let PT_PXPRINT: c_int = 15
let PT_PXPUNCT: c_int = 16
let PT_PXSPACE: c_int = 7
let PT_PXXDIGIT: c_int = 17
let PT_SC: c_int = 3
let PT_SCX: c_int = 4
let PT_SPACE: c_int = 6
let PT_TABSIZE: c_int = 13
let PT_UCNC: c_int = 10
let PT_WORD: c_int = 8
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
let P_tmpdir = "/var/tmp/"
let QUAD_MAX: c_int = 9223372036854775807
let QUAD_MIN: c_int = -9223372036854775806
let RAND_MAX: c_int = 0x7fffffff
// untranslatable fn-like macro
fn READPLUSOFFSET() -> Never:
    comptime_error("untranslatable C macro: READPLUSOFFSET")
// untranslatable fn-like macro
fn REAL_GET_UCD() -> Never:
    comptime_error("untranslatable C macro: REAL_GET_UCD")
let REFI_FLAG_CASELESS_RESTRICT: c_int = 0x1
let REFI_FLAG_TURKISH_CASING: c_int = 0x2
let RENAME_EXCL: c_int = 0x00000004
let RENAME_NOFOLLOW_ANY: c_int = 0x00000010
let RENAME_RESERVED1: c_int = 0x00000008
let RENAME_RESOLVE_BENEATH: c_int = 0x00000020
let RENAME_SECLUDE: c_int = 0x00000001
let RENAME_SWAP: c_int = 0x00000002
let REPEAT_UNLIMITED: c_int = 65536
let REQ_CASELESS: c_uint = 0x00000001
let REQ_CU_MAX: c_int = 5000
let REQ_NONE: c_uint = 0xfffffffe
let REQ_UNSET: c_uint = 0xffffffff
let REQ_VARY: c_uint = 0x00000002
let RE_DUP_MAX: c_int = 255
let RLIMIT_AS: c_int = 5
let RLIMIT_CORE: c_int = 4
let RLIMIT_CPU: c_int = 0
let RLIMIT_CPU_USAGE_MONITOR: c_int = 0x2
let RLIMIT_DATA: c_int = 2
let RLIMIT_FOOTPRINT_INTERVAL: c_int = 0x4
let RLIMIT_FSIZE: c_int = 1
let RLIMIT_MEMLOCK: c_int = 6
let RLIMIT_NOFILE: c_int = 8
let RLIMIT_NPROC: c_int = 7
let RLIMIT_RSS: c_int = 5
let RLIMIT_STACK: c_int = 3
let RLIMIT_THREAD_CPULIMITS: c_int = 0x3
let RLIMIT_WAKEUPS_MONITOR: c_int = 0x1
let RLIM_NLIMITS: c_int = 9
let RREF_ANY: c_int = 0xffff
let RSCAN_CACHE_SIZE: c_int = 8
let RUSAGE_CHILDREN: c_int = -1
let RUSAGE_INFO_V0: c_int = 0
let RUSAGE_INFO_V1: c_int = 1
let RUSAGE_INFO_V2: c_int = 2
let RUSAGE_INFO_V3: c_int = 3
let RUSAGE_INFO_V4: c_int = 4
let RUSAGE_INFO_V5: c_int = 5
let RUSAGE_INFO_V6: c_int = 6
let RUSAGE_SELF: c_int = 0
let RU_PROC_RUNS_RESLIDE: c_int = 0x00000001
let SA_64REGSET: c_int = 0x0200
let SA_NOCLDSTOP: c_int = 0x0008
let SA_NOCLDWAIT: c_int = 0x0020
let SA_NODEFER: c_int = 0x0010
let SA_ONSTACK: c_int = 0x0001
let SA_RESETHAND: c_int = 0x0004
let SA_RESTART: c_int = 0x0002
let SA_SIGINFO: c_int = 0x0040
let SA_USERSPACE_MASK: c_int = 127
let SA_USERTRAMP: c_int = 0x0100
let SCHAR_MAX: c_int = 127
let SCHAR_MIN: c_int = -126
let SCNd16 = "hd"
let SCNd32 = "d"
let SCNdFAST16: c_int = SCNd16
let SCNdFAST32: c_int = SCNd32
let SCNdLEAST16: c_int = SCNd16
let SCNdLEAST32: c_int = SCNd32
let SCNdPTR = "ld"
let SCNi16 = "hi"
let SCNi32 = "i"
let SCNiFAST16: c_int = SCNi16
let SCNiFAST32: c_int = SCNi32
let SCNiLEAST16: c_int = SCNi16
let SCNiLEAST32: c_int = SCNi32
let SCNiPTR = "li"
let SCNo16 = "ho"
let SCNo32 = "o"
let SCNoFAST16: c_int = SCNo16
let SCNoFAST32: c_int = SCNo32
let SCNoLEAST16: c_int = SCNo16
let SCNoLEAST32: c_int = SCNo32
let SCNoPTR = "lo"
let SCNu16 = "hu"
let SCNu32 = "u"
let SCNuFAST16: c_int = SCNu16
let SCNuFAST32: c_int = SCNu32
let SCNuLEAST16: c_int = SCNu16
let SCNuLEAST32: c_int = SCNu32
let SCNuPTR = "lu"
let SCNx16 = "hx"
let SCNx32 = "x"
let SCNxFAST16: c_int = SCNx16
let SCNxFAST32: c_int = SCNx32
let SCNxLEAST16: c_int = SCNx16
let SCNxLEAST32: c_int = SCNx32
let SCNxPTR = "lx"
let SEEK_CUR: c_int = 1
let SEEK_DATA: c_int = 4
let SEEK_END: c_int = 2
let SEEK_HOLE: c_int = 3
let SEEK_SET: c_int = 0
let SEGV_ACCERR: c_int = 2
let SEGV_MAPERR: c_int = 1
let SEGV_NOOP: c_int = 0
fn SELECT_VALUE8[T](value8: T, value: T) -> T:
    value8
// untranslatable fn-like macro
fn SETBIT() -> Never:
    comptime_error("untranslatable C macro: SETBIT")
let SHRT_MAX: c_int = 32767
let SHRT_MIN: c_int = -32766
let SIGABRT: c_int = 6
let SIGALRM: c_int = 14
let SIGBUS: c_int = 10
let SIGCHLD: c_int = 20
let SIGCONT: c_int = 19
let SIGEMT: c_int = 7
let SIGEV_KEVENT: c_int = 4
let SIGEV_NONE: c_int = 0
let SIGEV_SIGNAL: c_int = 1
let SIGEV_THREAD: c_int = 3
let SIGFPE: c_int = 8
let SIGHUP: c_int = 1
let SIGILL: c_int = 4
let SIGINFO: c_int = 29
let SIGINT: c_int = 2
let SIGIO: c_int = 23
let SIGIOT: c_int = 6
let SIGKILL: c_int = 9
let SIGPIPE: c_int = 13
let SIGPROF: c_int = 27
let SIGQUIT: c_int = 3
let SIGSEGV: c_int = 11
let SIGSTKSZ: c_int = 131072
let SIGSTOP: c_int = 17
let SIGSYS: c_int = 12
let SIGTERM: c_int = 15
let SIGTRAP: c_int = 5
let SIGTSTP: c_int = 18
let SIGTTIN: c_int = 21
let SIGTTOU: c_int = 22
let SIGURG: c_int = 16
let SIGUSR1: c_int = 30
let SIGUSR2: c_int = 31
let SIGVTALRM: c_int = 26
let SIGWINCH: c_int = 28
let SIGXCPU: c_int = 24
let SIGXFSZ: c_int = 25
let SIG_ATOMIC_MAX: c_int = 2147483647
let SIG_ATOMIC_MIN: c_int = -2147483646
let SIG_BLOCK: c_int = 1
let SIG_SETMASK: c_int = 3
let SIG_UNBLOCK: c_int = 2
let SIZEOFFSET: c_int = 2
let SI_ASYNCIO: c_int = 0x10004
let SI_MESGQ: c_int = 0x10005
let SI_QUEUE: c_int = 0x10002
let SI_TIMER: c_int = 0x10003
let SI_USER: c_int = 0x10001
// untranslatable fn-like macro
fn SKIPOFFSET() -> Never:
    comptime_error("untranslatable C macro: SKIPOFFSET")
let SSIZE_MAX: c_int = 9223372036854775807
let SS_DISABLE: c_int = 0x0004
let SS_ONSTACK: c_int = 0x0001
let START_FRAMES_SIZE: c_int = 20480
// untranslatable fn-like macro
fn STATIC_ASSERT() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT")
// untranslatable fn-like macro
fn STATIC_ASSERT_JOIN() -> Never:
    comptime_error("untranslatable C macro: STATIC_ASSERT_JOIN")
let STR_0 = "0"
let STR_1 = "1"
let STR_2 = "2"
let STR_3 = "3"
let STR_4 = "4"
let STR_5 = "5"
let STR_6 = "6"
let STR_7 = "7"
let STR_8 = "8"
let STR_9 = "9"
let STR_A = "A"
let STR_AMPERSAND = "&"
let STR_APOSTROPHE = "'"
let STR_ASTERISK = "*"
let STR_B = "B"
let STR_BACKSLASH = "\\"
let STR_BEL = "\a"
let STR_BS = "\b"
let STR_C = "C"
let STR_CIRCUMFLEX_ACCENT = "^"
let STR_COLON = ":"
let STR_COMMA = ","
let STR_COMMERCIAL_AT = "@"
let STR_CR = "\r"
let STR_D = "D"
let STR_DEL = "\177"
let STR_DOLLAR_SIGN = "$"
let STR_DOT = "."
let STR_E = "E"
let STR_EQUALS_SIGN = "="
let STR_ESC = "\033"
let STR_EXCLAMATION_MARK = "!"
let STR_F = "F"
let STR_FF = "\f"
let STR_G = "G"
let STR_GRAVE_ACCENT = "`"
let STR_GREATER_THAN_SIGN = ">"
let STR_H = "H"
let STR_HT = "\t"
let STR_I = "I"
let STR_J = "J"
let STR_K = "K"
let STR_L = "L"
let STR_LEFT_CURLY_BRACKET = "{"
let STR_LEFT_PARENTHESIS = "("
let STR_LEFT_SQUARE_BRACKET = "["
let STR_LESS_THAN_SIGN = "<"
let STR_LF = "\n"
let STR_M = "M"
let STR_MINUS = "-"
let STR_N = "N"
let STR_NEL = "\x85"
let STR_NL: c_int = STR_LF
let STR_NUMBER_SIGN = "#"
let STR_O = "O"
let STR_P = "P"
let STR_PERCENT_SIGN = "%"
let STR_PLUS = "+"
let STR_Q = "Q"
let STR_QUESTION_MARK = "?"
let STR_QUOTATION_MARK = "\""
let STR_R = "R"
let STR_RIGHT_CURLY_BRACKET = "}"
let STR_RIGHT_PARENTHESIS = ")"
let STR_RIGHT_SQUARE_BRACKET = "]"
let STR_S = "S"
let STR_SEMICOLON = ";"
let STR_SLASH = "/"
let STR_SPACE = " "
let STR_T = "T"
let STR_TILDE = "~"
let STR_U = "U"
let STR_UNDERSCORE = "_"
let STR_V = "V"
let STR_VERTICAL_LINE = "|"
let STR_VT = "\v"
let STR_W = "W"
let STR_X = "X"
let STR_Y = "Y"
let STR_Z = "Z"
let STR_a = "a"
let STR_b = "b"
let STR_c = "c"
let STR_d = "d"
let STR_e = "e"
let STR_f = "f"
let STR_g = "g"
let STR_h = "h"
let STR_i = "i"
let STR_j = "j"
let STR_k = "k"
let STR_l = "l"
let STR_m = "m"
let STR_n = "n"
let STR_o = "o"
let STR_p = "p"
let STR_q = "q"
let STR_r = "r"
let STR_s = "s"
let STR_t = "t"
let STR_u = "u"
let STR_v = "v"
let STR_w = "w"
let STR_x = "x"
let STR_y = "y"
let STR_z = "z"
let SUPPORT_PCRE2_8: c_int = 1
let SV_INTERRUPT: c_int = 0x0002
let SV_NOCLDSTOP: c_int = 0x0008
let SV_NODEFER: c_int = 0x0010
let SV_ONSTACK: c_int = 0x0001
let SV_RESETHAND: c_int = 0x0004
let SV_SIGINFO: c_int = 0x0040
// untranslatable fn-like macro
fn TABLE_GET() -> Never:
    comptime_error("untranslatable C macro: TABLE_GET")
let TARGET_IPHONE_SIMULATOR: c_int = 0
let TARGET_OS_ARROW: c_int = 1
let TARGET_OS_BRIDGE: c_int = 0
let TARGET_OS_DRIVERKIT: c_int = 0
let TARGET_OS_EMBEDDED: c_int = 0
let TARGET_OS_IOS: c_int = 0
let TARGET_OS_IOSMAC: c_int = 0
let TARGET_OS_IPHONE: c_int = 0
let TARGET_OS_LINUX: c_int = 0
let TARGET_OS_MAC: c_int = 1
let TARGET_OS_MACCATALYST: c_int = 0
let TARGET_OS_NANO: c_int = 0
let TARGET_OS_OSX: c_int = 1
let TARGET_OS_SIMULATOR: c_int = 0
let TARGET_OS_TV: c_int = 0
let TARGET_OS_UIKITFORMAC: c_int = 0
let TARGET_OS_UNIX: c_int = 0
let TARGET_OS_VISION: c_int = 0
let TARGET_OS_WATCH: c_int = 0
let TARGET_OS_WIN32: c_int = 0
let TARGET_OS_WINDOWS: c_int = 0
let TARGET_OS_XR: c_int = 0
let TMP_MAX: c_int = 308915776
let TRAP_BRKPT: c_int = 1
let TRAP_TRACE: c_int = 2
let TRUE: c_int = 1
// untranslatable fn-like macro
fn UCD_ANY_I() -> Never:
    comptime_error("untranslatable C macro: UCD_ANY_I")
// untranslatable fn-like macro
fn UCD_BIDICLASS() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS")
// untranslatable fn-like macro
fn UCD_BIDICLASS_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_BIDICLASS_PROP")
let UCD_BIDICLASS_SHIFT: c_int = 11
let UCD_BLOCK_SIZE: c_int = 128
// untranslatable fn-like macro
fn UCD_BPROPS() -> Never:
    comptime_error("untranslatable C macro: UCD_BPROPS")
let UCD_BPROPS_MASK: c_int = 0xfff
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
let UCD_SCRIPTX_MASK: c_int = 0x3ff
// untranslatable fn-like macro
fn UCD_SCRIPTX_PROP() -> Never:
    comptime_error("untranslatable C macro: UCD_SCRIPTX_PROP")
let UCHAR_MAX: c_int = 255
let UID_MAX: c_uint = 2147483647
fn UINT16_C[T](v: T) -> T:
    v
let UINT16_MAX: c_int = 65535
fn UINT32_C[T](v: T) -> u32:
    (v as u32)
let UINT32_MAX: c_uint = 4294967295
fn UINT64_C[T](v: T) -> u64:
    (v as u64)
let UINT64_MAX: c_ulonglong = 18446744073709551615
fn UINT8_C[T](v: T) -> T:
    v
let UINT8_MAX: c_int = 255
fn UINTMAX_C[T](v: T) -> u64:
    (v as u64)
let UINTMAX_MAX: c_int = UINTMAX_C(18446744073709551615)
let UINTPTR_MAX: c_ulong = 18446744073709551615
let UINT_FAST16_MAX: c_int = 65535
let UINT_FAST32_MAX: c_int = 4294967295
let UINT_FAST64_MAX: c_int = 18446744073709551615
let UINT_FAST8_MAX: c_int = 255
let UINT_LEAST16_MAX: c_int = 65535
let UINT_LEAST32_MAX: c_int = 4294967295
let UINT_LEAST64_MAX: c_int = 18446744073709551615
let UINT_LEAST8_MAX: c_int = 255
let UINT_MAX: c_int = 4294967295
let ULLONG_MAX: c_int = -1
let ULONG_LONG_MAX: c_int = -1
let ULONG_MAX: c_int = -1
fn UPPER_CASE[T](c: T) -> T:
    (c - 32)
let UQUAD_MAX: c_int = -1
let USHRT_MAX: c_int = 65535
let VERSION = "10.48-DEV"
let WAIT_ANY: c_int = -1
let WAIT_MYPGRP: c_int = 0
let WAKEMON_DISABLE: c_int = 0x02
let WAKEMON_ENABLE: c_int = 0x01
let WAKEMON_GET_PARAMS: c_int = 0x04
let WAKEMON_MAKE_FATAL: c_int = 0x10
let WAKEMON_SET_DEFAULTS: c_int = 0x08
// untranslatable fn-like macro
fn WAS_NEWLINE() -> Never:
    comptime_error("untranslatable C macro: WAS_NEWLINE")
let WCONTINUED: c_int = 0x00000010
// untranslatable fn-like macro
fn WCOREDUMP() -> Never:
    comptime_error("untranslatable C macro: WCOREDUMP")
let WCOREFLAG: c_int = 0200
let WEXITED: c_int = 0x00000004
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
let WINT_MAX: c_int = 2147483647
let WINT_MIN: c_int = -2147483646
let WNOHANG: c_int = 0x00000001
let WNOWAIT: c_int = 0x00000020
let WORD_BIT: c_int = 32
let WORK_SIZE_SAFETY_MARGIN: c_int = 100
let WSTOPPED: c_int = 0x00000008
// untranslatable fn-like macro
fn WSTOPSIG() -> Never:
    comptime_error("untranslatable C macro: WSTOPSIG")
// untranslatable fn-like macro
fn WTERMSIG() -> Never:
    comptime_error("untranslatable C macro: WTERMSIG")
let WUNTRACED: c_int = 0x00000002
fn W_EXITCODE[T](ret: T, sig: T) -> T:
    ((ret << 8) | sig)
// untranslatable fn-like macro
fn W_STOPCODE() -> Never:
    comptime_error("untranslatable C macro: W_STOPCODE")
let XCL_BEGIN_WITH_RANGE: c_int = 0x4
let XCL_CHAR_END: c_int = 0x1
let XCL_CHAR_LIST_HIGH_16_ADD: c_int = 0x8000
let XCL_CHAR_LIST_HIGH_16_END: c_int = 0xffff
let XCL_CHAR_LIST_HIGH_16_START: c_int = 0x8000
let XCL_CHAR_LIST_HIGH_32_ADD: c_int = 0x80000000
let XCL_CHAR_LIST_HIGH_32_END: c_int = 0xffffffff
let XCL_CHAR_LIST_HIGH_32_START: c_int = 0x80000000
let XCL_CHAR_LIST_LOW_16_ADD: c_int = 0x0
let XCL_CHAR_LIST_LOW_16_END: c_int = 0x7fff
let XCL_CHAR_LIST_LOW_16_START: c_int = 0x100
let XCL_CHAR_LIST_LOW_32_ADD: c_int = 0x0
let XCL_CHAR_LIST_LOW_32_END: c_int = 0x7fffffff
let XCL_CHAR_LIST_LOW_32_START: c_int = 0x10000
let XCL_CHAR_SHIFT: c_int = 1
let XCL_END: c_int = 0
let XCL_HASPROP: c_int = 0x04
let XCL_ITEM_COUNT_MASK: c_int = 0x3
let XCL_LIST: c_int = (if (sizeof[PCRE2_UCHAR]() == 1): 0x10 else: 0x1000)
let XCL_MAP: c_int = 0x02
let XCL_NOT: c_int = 0x01
let XCL_NOTPROP: c_int = 4
let XCL_PROP: c_int = 3
let XCL_RANGE: c_int = 2
let XCL_SINGLE: c_int = 1
let XCL_TYPE_BIT_LEN: c_int = 3
let XCL_TYPE_MASK: c_int = 0xfff
fn XDIGIT[T](c: T) -> T:
    xdigitab[c]
// untranslatable fn-like macro
fn alloca() -> Never:
    comptime_error("untranslatable C macro: alloca")
fn bcopy() -> Never:
    comptime_error("variadic macro — use direct call")
fn bzero() -> Never:
    comptime_error("variadic macro — use direct call")
let cbit_cntrl: c_int = 288
let cbit_digit: c_int = 64
let cbit_graph: c_int = 192
let cbit_length: c_int = 320
let cbit_lower: c_int = 128
let cbit_print: c_int = 224
let cbit_punct: c_int = 256
let cbit_space: c_int = 0
let cbit_upper: c_int = 96
let cbit_word: c_int = 160
let cbit_xdigit: c_int = 32
let cbits_offset: c_int = 512
// untranslatable fn-like macro
fn clearerr_unlocked() -> Never:
    comptime_error("untranslatable C macro: clearerr_unlocked")
let ctype_digit: c_int = 0x08
let ctype_lcletter: c_int = 0x04
let ctype_letter: c_int = 0x02
let ctype_space: c_int = 0x01
let ctype_word: c_int = 0x10
let ctypes_offset: c_int = 832
let fcc_offset: c_int = 256
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
let lcc_offset: c_int = 0
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
let ucd_boolprop_sets_item_size: c_int = 2
let ucd_script_sets_item_size: c_int = 4
fn vsnprintf() -> Never:
    comptime_error("variadic macro — use direct call")
fn vsprintf() -> Never:
    comptime_error("variadic macro — use direct call")
