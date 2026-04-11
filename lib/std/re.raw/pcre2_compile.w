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
type pcre2_substitute_callout_block_8 { version: c_uint = 0, input: *const u8 = null, output: *const u8 = null, output_offsets: [2]c_ulong, ovector: *mut c_ulong = null, oveccount: c_uint = 0, subscount: c_uint = 0 }
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
    var tables: *const u8 = null
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
    while true:
        match __pc
            0 =>
                newline = 0
                bsr = 0
                errorcode = 0
                if (if errorptr == null: 1 else: 0) != 0:
                    if (if erroroffset != null: 1 else: 0) != 0:
                        (unsafe: *erroroffset = 0)

                    return null

                if (if erroroffset == null: 1 else: 0) != 0:
                    if (if errorptr != null: 1 else: 0) != 0:
                        (unsafe: *errorptr = ERR120)

                    return null

                (unsafe: *errorptr = ERR0)
                (unsafe: *erroroffset = 0)
                if (if pattern == null: 1 else: 0) != 0:
                    if (if patlen == 0: 1 else: 0) != 0:
                        (pattern = null_str)
                    else:
                        (unsafe: *errorptr = ERR16)
                        return null


                if (if ((options & 67108864)) != 0: 1 else: 0) != 0:
                    options = options | 524288

                zero_terminated
                if (if patlen > ccontext.max_pattern_length: 1 else: 0) != 0:
                    (unsafe: *errorptr = ERR88)
                    return null

                if (if ((options & 16384)) != 0: 1 else: 0) != 0:
                    optim_flags = optim_flags & (0 - 1 - 1)

                if (if ((options & 32768)) != 0: 1 else: 0) != 0:
                    optim_flags = optim_flags & (0 - 2 - 1)

                if (if ((options & 65536)) != 0: 1 else: 0) != 0:
                    optim_flags = optim_flags & (0 - 4 - 1)

                (tables = (if ((if ccontext.tables != null: 1 else: 0)) != 0: ccontext.tables else: _pcre2_default_tables_8))
                (cb.lcc = (tables + (0 as isize as usize)))
                (cb.fcc = (tables + (256 as isize as usize)))
                (cb.cbits = (tables + (512 as isize as usize)))
                (cb.assert_depth = 0)
                (cb.bracount = 0)
                (cb.cx = ccontext)
                (cb.dupnames = 0)
                (cb.end_pattern = (pattern + patlen))
                (cb.erroroffset = 0)
                (cb.external_flags = 0)
                (cb.external_options = options)
                (cb.groupinfo = stack_groupinfo)
                (cb.had_recurse = 0)
                (cb.lastcapture = 0)
                (cb.max_lookbehind = 0)
                (cb.max_varlookbehind = ccontext.max_varlookbehind)
                (cb.name_entry_size = 0)
                (cb.name_table = null)
                (cb.named_groups = named_groups)
                (cb.named_group_list_size = 20)
                (cb.names_found = 0)
                (cb.parens_depth = 0)
                (cb.parsed_pattern = stack_parsed_pattern)
                (cb.req_varyopt = 0)
                (cb.start_code = cworkspace)
                (cb.start_pattern = pattern)
                (cb.start_workspace = cworkspace)
                (cb.workspace_size = 6000)
                (cb.first_data = null)
                (cb.last_data = null)
                (cb.top_backref = 0)
                (cb.backref_map = 0)
                (xoptions = ccontext.extra_options)
                (ptr = pattern)
                (skipatstart = 0)
                if (if ((options & 33554432)) == 0: 1 else: 0) != 0:
                    while (if (if (if (patlen -% skipatstart) >= 2: 1 else: 0) != 0 and (if ptr[skipatstart] == 40: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[(skipatstart +% 1)] == 42: 1 else: 0) != 0: 1 else: 0) != 0:
                        (i = 0)
                        while (if i < (sizeof[[23]pso]() / sizeof[pso]()): 1 else: 0) != 0:
                            var p: *const pso = null // init: untranslatable
                            if (if (if ((patlen -% skipatstart) -% 2) >= p.length: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(((ptr + skipatstart) + (2 as isize as usize)), p.name, p.length) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                var c: c_uint = 0 // init: untranslatable
                                var pp: c_uint = 0 // init: untranslatable
                                skipatstart = skipatstart + (p.length + 2)
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
                                            ptr = ptr + pp
                                            (utf = 0)
                                            comptime_error("goto not supported")

                                        if (if p.type_ == PSO_LIMH: 1 else: 0) != 0:
                                            (limit_heap = c)
                                        else:
                                            if (if p.type_ == PSO_LIMM: 1 else: 0) != 0:
                                                (limit_match = c)
                                            else:
                                                (limit_depth = c)


                                        (skipatstart = (pp = pp + 1))
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

                                break

                            (i = i + 1)

                        if (if i >= (sizeof[[23]pso]() / sizeof[pso]()): 1 else: 0) != 0:
                            break



                ptr = ptr + skipatstart
                if (if ((cb.external_options & ((524288 | 131072)))) != 0: 1 else: 0) != 0:
                    (errorcode = ERR32)
                    __pc = 3
                    continue

                (utf = (if ((cb.external_options & 524288)) != 0: 1 else: 0))
                if utf != 0:
                    if (if ((options & 4096)) != 0: 1 else: 0) != 0:
                        (errorcode = ERR74)
                        __pc = 3
                        continue

                    if (if (if ((options & 1073741824)) == 0: 1 else: 0) != 0 and (if ((errorcode = _pcre2_valid_utf_8(pattern, patlen, erroroffset))) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                        __pc = 4
                        continue


                (ucp = (if ((cb.external_options & 131072)) != 0: 1 else: 0))
                if (if ucp != 0 and (if ((cb.external_options & 2048)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (errorcode = ERR75)
                    __pc = 3
                    continue

                if (if ((xoptions & 65536)) != 0: 1 else: 0) != 0:
                    if (if (not utf) != 0 and (not ucp) != 0: 1 else: 0) != 0:
                        (errorcode = ERR104)
                        __pc = 3
                        continue

                    if (not utf) != 0:
                        (errorcode = ERR105)
                        __pc = 3
                        continue

                    if (if ((xoptions & 128)) != 0: 1 else: 0) != 0:
                        (errorcode = ERR106)
                        __pc = 3
                        continue


                if (if bsr == 0: 1 else: 0) != 0:
                    (bsr = ccontext.bsr_convention)

                if (if newline == 0: 1 else: 0) != 0:
                    (newline = ccontext.newline_convention)

                (cb.nltype = 0)
                match newline
                    1 =>
                        (cb.nllen = 1)
                        (cb.nl[0] = 13)
                    2 =>
                        (cb.nllen = 1)
                        (cb.nl[0] = 10)
                    6 =>
                        (cb.nllen = 1)
                        (cb.nl[0] = 0)
                    3 =>
                        (cb.nllen = 2)
                        (cb.nl[0] = 13)
                        (cb.nl[1] = 10)
                    4 =>
                        (cb.nltype = 1)
                    5 =>
                        (cb.nltype = 2)
                    _ =>
                        (errorcode = ERR56)
                        comptime_error("goto not supported")

                (parsed_size_needed = max_parsed_pattern(ptr, cb.end_pattern, utf, options))
                if (if ((ccontext.extra_options & ((4 | 8)))) != 0: 1 else: 0) != 0:
                    parsed_size_needed = parsed_size_needed + 4

                if (if ((options & 4)) != 0: 1 else: 0) != 0:
                    parsed_size_needed = parsed_size_needed + 4

                parsed_size_needed = parsed_size_needed + 1
                if (if parsed_size_needed > 1024: 1 else: 0) != 0:
                    var heap_parsed_pattern: *mut c_uint = null // init failed
                    if (if heap_parsed_pattern == null: 1 else: 0) != 0:
                        (unsafe: *errorptr = ERR21)
                        __pc = 1
                        continue

                    (cb.parsed_pattern = heap_parsed_pattern)

                (cb.parsed_pattern_end = (cb.parsed_pattern + parsed_size_needed))
                (errorcode = parse_regex(ptr, cb.external_options, xoptions, &has_lookbehind, &cb))
                if (if errorcode != 0: 1 else: 0) != 0:
                    __pc = 2
                    continue

                if has_lookbehind != 0:
                    var loopcount: c_int = 0
                    if (if cb.bracount >= 128: 1 else: 0) != 0:
                        (cb.groupinfo = ccontext.memctl.malloc((((2 *% ((cb.bracount +% 1)))) *% sizeof[c_uint]()), ccontext.memctl.memory_data))
                        if (if cb.groupinfo == null: 1 else: 0) != 0:
                            (errorcode = ERR21)
                            (cb.erroroffset = 0)
                            __pc = 2
                            continue


                    with_memset(cb.groupinfo as *i8, 0, ((((2 *% cb.bracount) +% 1)) *% sizeof[c_uint]()) as i64)
                    (errorcode = check_lookbehinds(cb.parsed_pattern, null, null, &cb, &loopcount))
                    if (if errorcode != 0: 1 else: 0) != 0:
                        __pc = 2
                        continue


                (cb.erroroffset = patlen)
                (pptr = cb.parsed_pattern)
                (code = cworkspace)
                (unsafe: *code = 137)
                compile_regex(cb.external_options, xoptions, &code, &pptr, &errorcode, 0, &firstcu, &firstcuflags, &reqcu, &reqcuflags, null, null, &cb, &length)
                if (if errorcode != 0: 1 else: 0) != 0:
                    __pc = 2
                    continue

                if (if length > 65536: 1 else: 0) != 0:
                    (errorcode = ERR20)
                    (cb.erroroffset = 0)
                    __pc = 2
                    continue

                if (if re_blocksize > ccontext.max_pattern_compiled_length: 1 else: 0) != 0:
                    (errorcode = ERR101)
                    (cb.erroroffset = 0)
                    __pc = 2
                    continue

                re_blocksize = re_blocksize + sizeof[pcre2_real_code_8]()
                if (if re == null: 1 else: 0) != 0:
                    (errorcode = ERR21)
                    (cb.erroroffset = 0)
                    __pc = 2
                    continue

                with_memset((((re as *mut i8) + sizeof[pcre2_real_code_8]()) - (8 as isize as usize)) as *i8, 0, 8 as i64)
                (re.memctl = ccontext.memctl)
                (re.tables = tables)
                (re.executable_jit = null)
                with_memset(re.start_bitmap as *i8, 0, (32 *% sizeof[u8]()) as i64)
                (re.blocksize = re_blocksize)
                (re.magic_number = 1346589253)
                (re.compile_options = options)
                (re.overall_options = cb.external_options)
                (re.extra_options = xoptions)
                (re.flags = ((1 | cb.external_flags) | setflags))
                (re.limit_heap = limit_heap)
                (re.limit_match = limit_match)
                (re.limit_depth = limit_depth)
                (re.first_codeunit = 0)
                (re.last_codeunit = 0)
                (re.bsr_convention = bsr)
                (re.newline_convention = newline)
                (re.max_lookbehind = 0)
                (re.minlength = 0)
                (re.top_bracket = 0)
                (re.top_backref = 0)
                (re.name_entry_size = cb.name_entry_size)
                (re.name_count = cb.names_found)
                (re.optimization_flags = optim_flags)
                (cb.parens_depth = 0)
                (cb.assert_depth = 0)
                (cb.lastcapture = 0)
                (cb.start_code = codestart)
                (cb.req_varyopt = 0)
                (cb.had_accept = 0)
                (cb.had_pruneorskip = 0)
                if (if cb.names_found > 0: 1 else: 0) != 0:
                    var ng: *mut named_group_8 = null // init failed
                    var tablecount: c_uint = 0 // init failed
                    (i = 0)
                    while (if i < cb.names_found: 1 else: 0) != 0:
if (if ng.length > 0: 1 else: 0) != 0:
                            (tablecount = _pcre2_compile_add_name_to_table8(&cb, ng, tablecount))


                (pptr = cb.parsed_pattern)
                (unsafe: *code = 137)
                (regexrc = compile_regex(re.overall_options, re.extra_options, &code, &pptr, &errorcode, 0, &firstcu, &firstcuflags, &reqcu, &reqcuflags, null, null, &cb, null))
                if (if regexrc < 0: 1 else: 0) != 0:
                    re.flags = re.flags | 8192

                (re.top_bracket = cb.bracount)
                (re.top_backref = cb.top_backref)
                (re.max_lookbehind = cb.max_lookbehind)
                if cb.had_accept != 0:
                    (reqcu = 0)
                    (reqcuflags = 4294967294)
                    re.flags = re.flags | 8388608

                (unsafe: *(code = code + 1) = 0)
                (usedlength = ((code as usize -% codestart as usize) / sizeof[u8]()))
                if (if usedlength > length: 1 else: 0) != 0:
                    (errorcode = ERR23)
                    (cb.erroroffset = 0)
                    __pc = 2
                    continue

                if (if (if errorcode == 0: 1 else: 0) != 0 and cb.had_recurse != 0: 1 else: 0) != 0:
                    var rcode: *mut u8 = null // init failed
                    var rgroup: *const u8 = null // init failed
                    var ccount: c_uint = 0
                    var start: c_int = 8
                    var rc = 0 // init failed: [8]recurse_cache
                    (rcode = find_recurse(codestart, utf))
                    while (if rcode != null: 1 else: 0) != 0:
                        var p: c_int = 0
                        var groupnumber: c_int = 0
                        if (if groupnumber == 0: 1 else: 0) != 0:
                            (rgroup = codestart)
                        else:
                            var search_from: *const u8 = null // init: untranslatable
                            (rgroup = null)
                            while (if i < ccount: 1 else: 0) != 0:
                                if (if groupnumber == rc[p].groupnumber: 1 else: 0) != 0:
                                    (rgroup = rc[p].group)
                                    break

                                if (if groupnumber > rc[p].groupnumber: 1 else: 0) != 0:
                                    (search_from = rc[p].group)


                            if (if rgroup == null: 1 else: 0) != 0:
                                (rgroup = _pcre2_find_bracket_8(search_from, utf, groupnumber))
                                if (if rgroup == null: 1 else: 0) != 0:
                                    (errorcode = ERR53)
                                    break

                                if (if (start = start - 1) < 0: 1 else: 0) != 0:
                                    (start = (8 - 1))

                                (rc[start].groupnumber = groupnumber)
                                (rc[start].group = rgroup)
                                if (if ccount < 8: 1 else: 0) != 0:
                                    (ccount = ccount + 1)



                        (rcode = find_recurse(((rcode + (1 as isize as usize)) + (2 as isize as usize)), utf))


                if (if (if errorcode == 0: 1 else: 0) != 0 and (if ((optim_flags & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    var temp: *mut u8 = null // init failed
                    var possessify_rc: c_int = _pcre2_auto_possessify_8(temp, &cb)
                    if (if possessify_rc != 0: 1 else: 0) != 0:
                        (errorcode = ERR80)
                        (cb.erroroffset = 0)


                if (if errorcode != 0: 1 else: 0) != 0:
                    __pc = 2
                    continue

                if (if ((re.overall_options & 2147483648)) == 0: 1 else: 0) != 0:
                    var dotstar_anchor: c_int = 0 // init failed
                    if is_anchored(codestart, 0, &cb, 0, 0, dotstar_anchor) != 0:
                        re.overall_options = re.overall_options | 2147483648


                if (if ((optim_flags & 4)) != 0: 1 else: 0) != 0:
                    var minminlength: c_int = 0
                    var study_rc: c_int = 0
                    if (if firstcuflags >= 4294967294: 1 else: 0) != 0:
                        var assertedcuflags: c_uint = 0 // init failed
                        var assertedcu: c_uint = 0 // init failed
                        if (if (if assertedcuflags < 4294967294: 1 else: 0) != 0 and (if assertedcu != reqcu: 1 else: 0) != 0: 1 else: 0) != 0:
                            (firstcu = assertedcu)
                            (firstcuflags = assertedcuflags)


                    if (if firstcuflags < 4294967294: 1 else: 0) != 0:
                        (re.first_codeunit = firstcu)
                        re.flags = re.flags | 16
                        (minminlength = minminlength + 1)
                        if (if ((firstcuflags & 1)) != 0: 1 else: 0) != 0:
                            if (if (if firstcu < 128: 1 else: 0) != 0 or ((if (if (not utf) != 0 and (not ucp) != 0: 1 else: 0) != 0 and (if firstcu < 255: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                if (if cb.fcc[firstcu] != firstcu: 1 else: 0) != 0:
                                    re.flags = re.flags | 32



                    else:
                        if (if ((re.overall_options & 2147483648)) == 0: 1 else: 0) != 0:
                            var dotstar_anchor: c_int = 0 // init failed
                            if is_startline(codestart, 0, &cb, 0, 0, dotstar_anchor) != 0:
                                re.flags = re.flags | 512



                    if (if reqcuflags < 4294967294: 1 else: 0) != 0:
                        if (if (if ((re.overall_options & 2147483648)) == 0: 1 else: 0) != 0 or (if ((reqcuflags & 2)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                            (re.last_codeunit = reqcu)
                            re.flags = re.flags | 128
                            if (if ((reqcuflags & 1)) != 0: 1 else: 0) != 0:
                                if (if (if reqcu < 128: 1 else: 0) != 0 or ((if (if (not utf) != 0 and (not ucp) != 0: 1 else: 0) != 0 and (if reqcu < 255: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                    if (if cb.fcc[reqcu] != reqcu: 1 else: 0) != 0:
                                        re.flags = re.flags | 256





                    (study_rc = _pcre2_study_8(re))
                    if (if study_rc != 0: 1 else: 0) != 0:
                        (errorcode = ERR31)
                        (cb.erroroffset = 0)
                        __pc = 2
                        continue

                    if (if (if ((re.flags & 64)) != 0: 1 else: 0) != 0 and (if minminlength == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                        (minminlength = 1)

                    if (if re.minlength < minminlength: 1 else: 0) != 0:
                        (re.minlength = minminlength)


                __pc = 1
                continue
            1 =>  // EXIT
                if (if cb.parsed_pattern != stack_parsed_pattern: 1 else: 0) != 0:
                    ccontext.memctl.free(cb.parsed_pattern, ccontext.memctl.memory_data)

                if (if cb.named_group_list_size > 20: 1 else: 0) != 0:
                    ccontext.memctl.free((cb.named_groups as *mut c_void), ccontext.memctl.memory_data)

                if (if cb.groupinfo != stack_groupinfo: 1 else: 0) != 0:
                    ccontext.memctl.free((cb.groupinfo as *mut c_void), ccontext.memctl.memory_data)

                return re
                __pc = 2
                continue
            2 =>  // HAD_CB_ERROR
                (ptr = (pattern + cb.erroroffset))
                __pc = 3
                continue
            3 =>  // HAD_EARLY_ERROR
                (unsafe: *erroroffset = ((ptr as usize -% pattern as usize) / sizeof[u8]()))
                __pc = 4
                continue
            4 =>  // HAD_ERROR
                (unsafe: *errorptr = errorcode)
                pcre2_code_free_8(re)
                (re = null)
                if (if cb.first_data != null: 1 else: 0) != 0:
                    var current_data: *mut compile_data = null // init failed
                    while true:
                        var next_data: *mut compile_data = null // init: untranslatable
                        cb.cx.memctl.free(current_data, cb.cx.memctl.memory_data)
                        (current_data = next_data)
                        if not ((if current_data != null: 1 else: 0) != 0):
                            break


                __pc = 1
                continue
            _ => break

@[c_export("pcre2_code_free_8")]
fn pcre2_code_free_8(code: *mut pcre2_real_code_8):
    var ref_count: *mut c_ulong = null // init: untranslatable
    if (if code != null: 1 else: 0) != 0:
        if (if ((code.flags & 262144)) != 0: 1 else: 0) != 0:
            if (if unsafe: *ref_count > 0: 1 else: 0) != 0:
                ((unsafe: *ref_count) = (unsafe: *ref_count) - 1)
                if (if unsafe: *ref_count == 0: 1 else: 0) != 0:
                    code.memctl.free((code.tables as *mut c_void), code.memctl.memory_data)



        code.memctl.free(code, code.memctl.memory_data)


@[c_export("pcre2_code_copy_8")]
fn pcre2_code_copy_8(code: *const pcre2_real_code_8) -> *mut pcre2_real_code_8:
    var ref_count: *mut c_ulong = null // init: untranslatable
    var newcode: *mut pcre2_real_code_8 = null // init: untranslatable
    if (if code == null: 1 else: 0) != 0:
        return null

    (newcode = code.memctl.malloc(code.blocksize, code.memctl.memory_data))
    if (if newcode == null: 1 else: 0) != 0:
        return null

    with_memcpy(newcode as *i8, code as *i8, code.blocksize as i64)
    (newcode.executable_jit = null)
    if (if ((code.flags & 262144)) != 0: 1 else: 0) != 0:
        ((unsafe: *ref_count) = (unsafe: *ref_count) + 1)

    return newcode

@[c_export("pcre2_code_copy_with_tables_8")]
fn pcre2_code_copy_with_tables_8(code: *const pcre2_real_code_8) -> *mut pcre2_real_code_8:
    var ref_count: *mut c_ulong = null // init: untranslatable
    var newcode: *mut pcre2_real_code_8 = null // init: untranslatable
    var newtables: *mut u8 = null // init: untranslatable
    if (if code == null: 1 else: 0) != 0:
        return null

    (newcode = code.memctl.malloc(code.blocksize, code.memctl.memory_data))
    if (if newcode == null: 1 else: 0) != 0:
        return null

    with_memcpy(newcode as *i8, code as *i8, code.blocksize as i64)
    (newcode.executable_jit = null)
    (newtables = code.memctl.malloc((1088 +% sizeof[c_ulong]()), code.memctl.memory_data))
    if (if newtables == null: 1 else: 0) != 0:
        code.memctl.free((newcode as *mut c_void), code.memctl.memory_data)
        return null

    with_memcpy(newtables as *i8, code.tables as *i8, 1088 as i64)
    (unsafe: *ref_count = 1)
    (newcode.tables = newtables)
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
type pcre2_real_general_context_8 { memctl: pcre2_memctl }
type struct_pcre2_real_general_context_8 = pcre2_real_general_context_8
type pcre2_real_compile_context_8 { memctl: pcre2_memctl, stack_guard: *const fn(c_uint, *mut c_void) -> c_int = null, stack_guard_data: *mut c_void = null, tables: *const u8 = null, max_pattern_length: c_ulong = 0, max_pattern_compiled_length: c_ulong = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, parens_nest_limit: c_uint = 0, extra_options: c_uint = 0, max_varlookbehind: c_uint = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_compile_context_8 = pcre2_real_compile_context_8
type pcre2_real_match_context_8 { memctl: pcre2_memctl, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, callout_data: *mut c_void = null, substitute_callout: *const fn(*mut pcre2_substitute_callout_block_8, *mut c_void) -> c_int = null, substitute_callout_data: *mut c_void = null, substitute_case_callout: *const fn(*const u8, c_ulong, *mut u8, c_ulong, c_int, *mut c_void) -> c_ulong = null, substitute_case_callout_data: *mut c_void = null, offset_limit: c_ulong = 0, heap_limit: c_uint = 0, match_limit: c_uint = 0, depth_limit: c_uint = 0 }
type struct_pcre2_real_match_context_8 = pcre2_real_match_context_8
type pcre2_real_convert_context_8 { memctl: pcre2_memctl, glob_separator: c_uint = 0, glob_escape: c_uint = 0 }
type struct_pcre2_real_convert_context_8 = pcre2_real_convert_context_8
type pcre2_real_code_8 { memctl: pcre2_memctl, tables: *const u8 = null, executable_jit: *mut c_void = null, start_bitmap: [32]u8, blocksize: c_ulong = 0, code_start: c_ulong = 0, magic_number: c_uint = 0, compile_options: c_uint = 0, overall_options: c_uint = 0, extra_options: c_uint = 0, flags: c_uint = 0, limit_heap: c_uint = 0, limit_match: c_uint = 0, limit_depth: c_uint = 0, first_codeunit: c_uint = 0, last_codeunit: c_uint = 0, bsr_convention: c_ushort = 0, newline_convention: c_ushort = 0, max_lookbehind: c_ushort = 0, minlength: c_ushort = 0, top_bracket: c_ushort = 0, top_backref: c_ushort = 0, name_entry_size: c_ushort = 0, name_count: c_ushort = 0, optimization_flags: c_uint = 0 }
type struct_pcre2_real_code_8 = pcre2_real_code_8
type pcre2_real_match_data_8 { memctl: pcre2_memctl, code: *const pcre2_real_code_8 = null, subject: *const u8 = null, mark: *const u8 = null, heapframes: *mut heapframe = null, heapframes_size: c_ulong = 0, subject_length: c_ulong = 0, start_offset: c_ulong = 0, leftchar: c_ulong = 0, rightchar: c_ulong = 0, startchar: c_ulong = 0, matchedby: u8 = 0, flags: u8 = 0, oveccount: c_ushort = 0, options: c_uint = 0, rc: c_int = 0, ovector: [131072]c_ulong }
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
type class_bits_storage { classbits: [32]u8, classwords: [8]c_uint }
type struct_class_bits_storage = class_bits_storage
type compile_block_8 { cx: *mut pcre2_real_compile_context_8 = null, lcc: *const u8 = null, fcc: *const u8 = null, cbits: *const u8 = null, ctypes: *const u8 = null, start_workspace: *mut u8 = null, start_code: *mut u8 = null, start_pattern: *const u8 = null, end_pattern: *const u8 = null, name_table: *mut u8 = null, workspace_size: c_ulong = 0, small_ref_offset: [10]c_ulong, erroroffset: c_ulong = 0, classbits: class_bits_storage, names_found: c_ushort = 0, name_entry_size: c_ushort = 0, parens_depth: c_ushort = 0, assert_depth: c_ushort = 0, named_groups: *mut named_group_8 = null, named_group_list_size: c_uint = 0, external_options: c_uint = 0, external_flags: c_uint = 0, bracount: c_uint = 0, lastcapture: c_uint = 0, parsed_pattern: *mut c_uint = null, parsed_pattern_end: *mut c_uint = null, groupinfo: *mut c_uint = null, top_backref: c_uint = 0, backref_map: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8, class_op_used: [15]u8, req_varyopt: c_uint = 0, max_varlookbehind: c_uint = 0, max_lookbehind: c_int = 0, had_accept: c_int = 0, had_pruneorskip: c_int = 0, had_recurse: c_int = 0, dupnames: c_int = 0, first_data: *mut compile_data = null, last_data: *mut compile_data = null }
type struct_compile_block_8 = compile_block_8
type pcre2_real_jit_stack_8 { memctl: pcre2_memctl, stack: *mut c_void = null }
type struct_pcre2_real_jit_stack_8 = pcre2_real_jit_stack_8
type dfa_recursion_info { prevrec: *mut dfa_recursion_info = null, subject_position: *const u8 = null, last_used_ptr: *const u8 = null, group_num: c_uint = 0 }
type struct_dfa_recursion_info = dfa_recursion_info
// .reference/pcre2/src/pcre2_intmodedep.h:696:8: demoted to opaque
type heapframe = opaque
type struct_heapframe = heapframe
type static_assertion_heapframe_size = [1]c_int
// .reference/pcre2/src/pcre2_intmodedep.h:1024:16: demoted to opaque
type heapframe_align = opaque
type struct_heapframe_align = heapframe_align
type match_block_8 { memctl: pcre2_memctl, heap_limit: c_uint = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, hitend: c_int = 0, hasthen: c_int = 0, hasbsk: c_int = 0, allowemptypartial: c_int = 0, allowlookaroundbsk: c_int = 0, lcc: *const u8 = null, fcc: *const u8 = null, ctypes: *const u8 = null, start_offset: c_ulong = 0, end_offset_top: c_ulong = 0, partial: c_ushort = 0, bsr_convention: c_ushort = 0, name_count: c_ushort = 0, name_entry_size: c_ushort = 0, name_table: *const u8 = null, start_code: *const u8 = null, start_subject: *const u8 = null, check_subject: *const u8 = null, end_subject: *const u8 = null, true_end_subject: *const u8 = null, end_match_ptr: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, mark: *const u8 = null, nomatch_mark: *const u8 = null, verb_ecode_ptr: *const u8 = null, verb_skip_ptr: *const u8 = null, verb_current_recurse: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, skip_arg_count: c_uint = 0, ignore_skip_arg: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null }
type struct_match_block_8 = match_block_8
type dfa_match_block_8 { memctl: pcre2_memctl, start_code: *const u8 = null, start_subject: *const u8 = null, end_subject: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, tables: *const u8 = null, start_offset: c_ulong = 0, heap_limit: c_uint = 0, heap_used: c_ulong = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, allowemptypartial: c_int = 0, nl: [4]u8, bsr_convention: c_ushort = 0, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, recursive: *mut dfa_recursion_info = null }
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
    while true:
        match __pc
            0 =>
                escape = 0
                if (if ptr >= ptrend: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = ERR1)
                    return 0

                // (empty)
                (unsafe: *errorcodeptr = 0)
                __pc = 2
                continue
            2 =>  // EXIT
                (unsafe: *ptrptr = ptr)
                (unsafe: *chptr = c)
                return escape
                __pc = 3
                continue
            3 =>  // ESCAPE_FAILED_FORWARD
                (ptr = ptr + 1)
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
extern fn _pcre2_update_classbits_8(ptype: c_uint, pdata: c_uint, negated: c_int, classbits: *mut u8) -> void
extern fn _pcre2_compile_class_not_nested_8(options: c_uint, xoptions: c_uint, start_ptr: *mut c_uint, pcode: *mut *mut u8, negate_class: c_int, has_bitmap: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint
extern fn _pcre2_compile_class_nested_8(options: c_uint, xoptions: c_uint, pptr: *mut *mut c_uint, pcode: *mut *mut u8, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int
extern fn _pcre2_compile_get_hash_from_name8(name: *const u8, length: c_uint) -> c_ushort
extern fn _pcre2_compile_find_named_group8(name: *const u8, length: c_uint, cb: *mut compile_block_8) -> *mut named_group_8
extern fn _pcre2_compile_add_name_to_table8(cb: *mut compile_block_8, ng: *mut named_group_8, tablecount: c_uint) -> c_uint
extern fn _pcre2_compile_find_dupname_details8(name: *const u8, length: c_uint, indexptr: *mut c_int, countptr: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int
extern fn _pcre2_compile_parse_scan_substr_args8(pptr: *mut c_uint, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint
extern fn _pcre2_compile_parse_recurse_args8(pptr_start: *mut c_uint, offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int
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
