// Migrated from PCRE2
use std.re.defs

type BOOL = c_int
extern fn imaxabs(j: c_long) -> c_long
type imaxdiv_t { quot: c_long = 0, rem: c_long = 0 }
type struct_imaxdiv_t = imaxdiv_t
extern fn imaxdiv(__numer: c_long, __denom: c_long) -> imaxdiv_t
extern fn strtoimax(__nptr: *const i8, __endptr: *mut *mut i8, __base: c_int) -> c_long
extern fn strtoumax(__nptr: *const i8, __endptr: *mut *mut i8, __base: c_int) -> c_ulong
extern fn wcstoimax(__nptr: *const c_int, __endptr: *mut *mut c_int, __base: c_int) -> c_long
extern fn wcstoumax(__nptr: *const c_int, __endptr: *mut *mut c_int, __base: c_int) -> c_ulong
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
fn pcre2_compile_8(pattern: *const u8, patlen: c_ulong, options: c_uint, errorptr: *mut c_int, erroroffset: *mut c_ulong, ccontext: *mut pcre2_real_compile_context_8) -> *mut pcre2_real_code_8:
    var pattern = pattern
    var patlen = patlen
    var options = options
    var ccontext = ccontext
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
fn compile_regex(options: c_uint, xoptions: c_uint, codeptr: *mut *mut u8, pptrptr: *mut *mut c_uint, errorcodeptr: *mut c_int, skipunits: c_uint, firstcuptr: *mut c_uint, firstcuflagsptr: *mut c_uint, reqcuptr: *mut c_uint, reqcuflagsptr: *mut c_uint, bcptr: *mut branch_chain_8, open_caps: *mut open_capitem, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> c_int:
    var open_caps = open_caps
    var code: *mut u8 = null // init: untranslatable
    var last_branch: *mut u8 = null // init: untranslatable
    var start_bracket: *mut u8 = null // init: untranslatable
    var lookbehind: c_int = 0 // init: untranslatable
    var capitem = 0 // init: untranslatable (open_capitem)
    var capnumber: c_int = 0
    var okreturn: c_int = 1
    var pptr: *mut c_uint = null // init: untranslatable
    var firstcu: c_uint = 0 // init: untranslatable
    var reqcu: c_uint = 0 // init: untranslatable
    var lookbehindlength: c_uint = 0 // init: untranslatable
    var lookbehindminlength: c_uint = 0 // init: untranslatable
    var firstcuflags: c_uint = 0 // init: untranslatable
    var reqcuflags: c_uint = 0 // init: untranslatable
    var length: c_ulong = 0 // init: untranslatable
    var bc = 0 // init: untranslatable (branch_chain_8)
    if (if (if cb.cx.stack_guard != null: 1 else: 0) != 0 and cb.cx.stack_guard(cb.parens_depth, cb.cx.stack_guard_data) != 0: 1 else: 0) != 0:
        (unsafe: *errorcodeptr = ERR33)
        (cb.erroroffset = 0)
        return 0

    (bc.outer = bcptr)
    (bc.current_branch = code)
    (firstcu = (reqcu = 0))
    (firstcuflags = (reqcuflags = 4294967295))
    (length = (6 +% skipunits))
    (lookbehind = (if (if (if unsafe: *code == OP_ASSERTBACK: 1 else: 0) != 0 or (if unsafe: *code == OP_ASSERTBACK_NOT: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_ASSERTBACK_NA: 1 else: 0) != 0: 1 else: 0))
    if lookbehind != 0:
        (lookbehindminlength = unsafe: *pptr)
        pptr = pptr + 2
    else:
        (lookbehindlength = (lookbehindminlength = 0))

    if (if unsafe: *code == OP_CBRA: 1 else: 0) != 0:
        (capitem.number = capnumber)
        (capitem.next = open_caps)
        (capitem.assert_depth = cb.assert_depth)
        (open_caps = &capitem)

    code = code + (3 +% skipunits)
    while true:
        var branch_return: c_int = 0
        var branchfirstcu: c_uint = 0 // init: untranslatable
        var branchreqcu: c_uint = 0 // init: untranslatable
        var branchfirstcuflags: c_uint = 0 // init: untranslatable
        var branchreqcuflags: c_uint = 0 // init: untranslatable
        if (if lookbehind != 0 and (if lookbehindlength > 0: 1 else: 0) != 0: 1 else: 0) != 0:
            if (if (if lookbehindminlength == 65535: 1 else: 0) != 0 or (if lookbehindminlength == lookbehindlength: 1 else: 0) != 0: 1 else: 0) != 0:
                (unsafe: *(code = code + 1) = 126)
                length = length + 3
            else:
                (unsafe: *(code = code + 1) = 127)
                length = length + 5


        if (if ((branch_return = compile_branch(&options, &xoptions, &code, &pptr, errorcodeptr, &branchfirstcu, &branchfirstcuflags, &branchreqcu, &branchreqcuflags, &bc, open_caps, cb, (if ((if lengthptr == null: 1 else: 0)) != 0: null else: &length)))) == 0: 1 else: 0) != 0:
            return 0

        if (if branch_return < 0: 1 else: 0) != 0:
            (okreturn = (0 - 1))

        if (if lengthptr == null: 1 else: 0) != 0:
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


                    (firstcuflags = 4294967294)

                if (if (if (if firstcuflags >= 4294967294: 1 else: 0) != 0 and (if branchfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if branchreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                    (branchreqcu = branchfirstcu)
                    (branchreqcuflags = branchfirstcuflags)

                if (if ((if ((reqcuflags & (0 - 2 - 1))) != ((branchreqcuflags & (0 - 2 - 1))): 1 else: 0)) != 0 or (if reqcu != branchreqcu: 1 else: 0) != 0: 1 else: 0) != 0:
                    (reqcuflags = 4294967294)
                else:
                    (reqcu = branchreqcu)
                    reqcuflags = reqcuflags | branchreqcuflags



        if (if lengthptr != null: 1 else: 0) != 0:
            (code = (((unsafe: *codeptr + (1 as isize as usize)) + (2 as isize as usize)) + skipunits))
            length = length + 3
        else:
            (unsafe: *code = 121)
            (bc.current_branch = (last_branch = code))
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
    while true:
        match __pc
            0 =>
                branchlength = 0
                branchminlength = 0
                if (if ((unsafe: *lcptr) = (unsafe: *lcptr) + 1) > 2000: 1 else: 0) != 0:
                    (unsafe: *errcodeptr = ERR35)
                    return (0 - 1)

                while (pptr = pptr + 1) != null:
                    var r: *mut parsed_recurse_check = null // init: untranslatable
                    var gptr: *mut c_uint = null // init: untranslatable
                    var gptrend: *mut c_uint = null // init: untranslatable
                    var escape: c_uint = 0 // init: untranslatable
                    var min: c_uint = 0 // init: untranslatable
                    var max: c_uint = 0 // init: untranslatable
                    var group: c_uint = 0 // init: untranslatable
                    var itemlength: c_uint = 0 // init: untranslatable
                    var itemminlength: c_uint = 0 // init: untranslatable
                    if (if unsafe: *pptr < 2147483648: 1 else: 0) != 0:
                        (itemlength = (itemminlength = 1))

                    if (if (if (2147483647 - branchlength) < (itemlength as c_int): 1 else: 0) != 0 or (if (branchlength = branchlength + itemlength) > ((65535 as c_int)): 1 else: 0) != 0: 1 else: 0) != 0:
                        (unsafe: *errcodeptr = ERR87)
                        return (0 - 1)

                    branchminlength = branchminlength + itemminlength
                    (lastitemlength = itemlength)
                    (lastitemminlength = itemminlength)

                __pc = 5
                continue
            5 =>  // EXIT
                (unsafe: *pptrptr = pptr)
                (unsafe: *minptr = branchminlength)
                return branchlength
                __pc = 6
                continue
            6 =>  // PARSED_SKIP_FAILED
                (unsafe: *errcodeptr = ERR90)
                return (0 - 1)
            _ => break

fn set_lookbehind_lengths(pptrptr: *mut *mut c_uint, errcodeptr: *mut c_int, lcptr: *mut c_int, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8) -> c_int:
    var offset: c_ulong = 0 // init: untranslatable
    var bptr: *mut c_uint = null // init: untranslatable
    var gbptr: *mut c_uint = null // init: untranslatable
    var maxlength: c_int = 0
    var minlength: c_int = 2147483647
    var variable: c_int = 0 // init: untranslatable
    // (empty)
    unsafe: *pptrptr = unsafe: *pptrptr + 2
    if variable != 0:
        (gbptr[1] = minlength)
    else:
        (gbptr[1] = 65535)

    return 1

fn check_lookbehinds(pptr: *mut c_uint, retptr: *mut *mut c_uint, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8, lcptr: *mut c_int) -> c_int:
    var pptr = pptr
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
fn read_number(ptrptr: *mut *const u8, ptrend: *const u8, allow_sign: c_int, max_value: c_uint, max_error: c_uint, intptr: *mut c_int, errorcodeptr: *mut c_int) -> c_int:
    var max_value = max_value
    var sign: c_int = 0
    var n: c_uint = 0
    var ptr: *const u8 = null
    var yield_: c_int = 0
    var __pc: i32 = 0
    while true:
        match __pc
            0 =>
                sign = 0
                (unsafe: *errorcodeptr = 0)
                if (if (if allow_sign >= 0: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if unsafe: *ptr == 43: 1 else: 0) != 0:
                        (sign = 1)
                        max_value = max_value - allow_sign
                        (ptr = ptr + 1)
                    else:
                        if (if unsafe: *ptr == 45: 1 else: 0) != 0:
                            (sign = (0 - 1))
                            (ptr = ptr + 1)



                if (if (if allow_sign >= 0: 1 else: 0) != 0 and (if sign != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if n == 0: 1 else: 0) != 0:
                        (unsafe: *errorcodeptr = ERR26)
                        __pc = 1
            continue

                    if (if sign > 0: 1 else: 0) != 0:
                        n = n + allow_sign


                (yield_ = 1)
                __pc = 1
                continue
            1 =>  // EXIT
                (unsafe: *intptr = n)
                (unsafe: *ptrptr = ptr)
                return yield_
            _ => break

fn read_repeat_counts(ptrptr: *mut *const u8, ptrend: *const u8, minp: *mut c_uint, maxp: *mut c_uint, errorcodeptr: *mut c_int) -> c_int:
    var p: *const u8 = null
    var pp: *const u8 = null
    var yield_: c_int = 0
    var had_minimum: c_int = 0
    var min: c_int = 0
    var max: c_int = 0
    var __pc: i32 = 0
    while true:
        match __pc
            0 =>
                (unsafe: *errorcodeptr = 0)
                while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(p = p + 1)
                (pp = p)
                while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *pp == 32: 1 else: 0) != 0 or (if unsafe: *pp == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(pp = pp + 1)
                if (if pp >= ptrend: 1 else: 0) != 0:
                    return 0

                if (if unsafe: *pp == 125: 1 else: 0) != 0:
                    if (not had_minimum) != 0:
                        return 0

                else:
                    if (if unsafe: *(pp = pp + 1) != 44: 1 else: 0) != 0:
                        return 0

                    while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *pp == 32: 1 else: 0) != 0 or (if unsafe: *pp == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(pp = pp + 1)
                    if (if pp >= ptrend: 1 else: 0) != 0:
                        return 0

                    while (if (if pp < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *pp == 32: 1 else: 0) != 0 or (if unsafe: *pp == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(pp = pp + 1)
                    if (if (if pp >= ptrend: 1 else: 0) != 0 or (if unsafe: *pp != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                        return 0


                if (not read_number(&p, ptrend, (0 - 1), 65535, 105, &min, errorcodeptr)) != 0:
                    if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                        __pc = 1
            continue

                    (p = p + 1)
                    while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(p = p + 1)
                    if (not read_number(&p, ptrend, (0 - 1), 65535, 105, &max, errorcodeptr)) != 0:
                        if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                            __pc = 1
            continue


                else:
                    while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(p = p + 1)
                    if (if unsafe: *p == 125: 1 else: 0) != 0:
                        (max = min)
                    else:
                        (p = p + 1)
                        while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(p = p + 1)
                        if (not read_number(&p, ptrend, (0 - 1), 65535, 105, &max, errorcodeptr)) != 0:
                            if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                                __pc = 1
            continue


                        if (if max < min: 1 else: 0) != 0:
                            (unsafe: *errorcodeptr = ERR4)
                            __pc = 1
            continue



                while (if (if p < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *p == 32: 1 else: 0) != 0 or (if unsafe: *p == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(p = p + 1)
                (p = p + 1)
                (yield_ = 1)
                __pc = 1
                continue
            1 =>  // EXIT
                (unsafe: *ptrptr = p)
                return yield_
            _ => break

fn check_posix_syntax(ptr: *const u8, ptrend: *const u8, endptr: *mut *const u8) -> c_int:
    var ptr = ptr
    var terminator: u8 = 0 // init: untranslatable
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
    var pn: *const i8 = posix_names
    var yield_: c_int = 0
    while (if posix_name_lengths[yield_] != 0: 1 else: 0) != 0:
        if (if (if len == posix_name_lengths[yield_]: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, pn, (len as c_uint)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
            return yield_

        pn = pn + (posix_name_lengths[yield_] + 1)
        (yield_ = yield_ + 1)

    return (0 - 1)

fn read_name(ptrptr: *mut *const u8, ptrend: *const u8, utf: c_int, terminator: c_uint, offsetptr: *mut c_ulong, nameptr: *mut *const u8, namelenptr: *mut c_uint, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int:
    var ptr: *const u8 = null
    var is_group: c_int = 0
    var is_braced: c_int = 0
    var __pc: i32 = 0
    while true:
        match __pc
            0 =>
                if is_braced != 0:
                    while (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *ptr == 32: 1 else: 0) != 0 or (if unsafe: *ptr == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(ptr = ptr + 1)

                if (if ptr >= ptrend: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = (if is_group != 0: ERR62 else: ERR60))
                    __pc = 1
            continue

                (unsafe: *nameptr = ptr)
                utf
                                while (if (if (if ptr < ptrend: 1 else: 0) != 0 and 1 != 0: 1 else: 0) != 0 and (if ((cb.ctypes[unsafe: *ptr] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (ptr = ptr + 1)


                if (if ((ptr as usize -% unsafe: *nameptr as usize) / sizeof[u8]()) > 128: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = ERR48)
                    __pc = 1
            continue

                if is_group != 0:
                    if (if ptr == unsafe: *nameptr: 1 else: 0) != 0:
                        (unsafe: *errorcodeptr = ERR62)
                        __pc = 1
            continue

                    if is_braced != 0:
                        while (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if unsafe: *ptr == 32: 1 else: 0) != 0 or (if unsafe: *ptr == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
(ptr = ptr + 1)

                    if (if terminator != 0: 1 else: 0) != 0:
                        (ptr = ptr + 1)


                (unsafe: *ptrptr = ptr)
                return 1
                __pc = 1
                continue
            1 =>  // FAILED
                (unsafe: *ptrptr = ptr)
                return 0
            _ => break

fn parse_capture_list(ptrptr: *mut *const u8, ptrend: *const u8, utf: c_int, parsed_pattern: *mut c_uint, offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> *mut c_uint:
    var parsed_pattern = parsed_pattern
    var offset = offset
    var next_offset: c_ulong = 0
    var ptr: *const u8 = null
    var name: *const u8 = null
    var terminator: u8 = 0
    var meta: c_uint = 0
    var namelen: c_uint = 0
    var i: c_int = 0
    var __pc: i32 = 0
    while true:
        match __pc
            0 =>
                if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 40: 1 else: 0) != 0: 1 else: 0) != 0:
                    (unsafe: *errorcodeptr = ERR118)
                    __pc = 2
            continue

                while true:
                    (ptr = ptr + 1)
                    if (if ptr >= ptrend: 1 else: 0) != 0:
                        (unsafe: *errorcodeptr = ERR117)
                        comptime_error("goto not supported")

                    if read_number(&ptr, ptrend, cb.bracount, 65535, 161, &i, errorcodeptr) != 0:
                        if (if i <= 0: 1 else: 0) != 0:
                            (unsafe: *errorcodeptr = ERR15)
                            comptime_error("goto not supported")

                        (meta = 2149122048)
                    else:
                        if (if unsafe: *errorcodeptr != 0: 1 else: 0) != 0:
                            comptime_error("goto not supported")
                        else:
                            if (if unsafe: *ptr == 60: 1 else: 0) != 0:
                                (terminator = 62)
                            else:
                                if (if unsafe: *ptr == 39: 1 else: 0) != 0:
                                    (terminator = 39)
                                else:
                                    (unsafe: *errorcodeptr = ERR117)
                                    comptime_error("goto not supported")


                            if (not read_name(&ptr, ptrend, utf, terminator, &next_offset, &name, &namelen, errorcodeptr, cb)) != 0:
                                comptime_error("goto not supported")

                            (meta = 2149056512)


                    if (if (if offset == 0: 1 else: 0) != 0 or (if ((next_offset -% offset)) >= 65536: 1 else: 0) != 0: 1 else: 0) != 0:
                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148925440)
                        // (empty)
                        (offset = next_offset)

                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)
                    (offset = next_offset)
                    if (if ptr >= ptrend: 1 else: 0) != 0:
                        comptime_error("goto not supported")

                    if (if unsafe: *ptr == 41: 1 else: 0) != 0:
                        break

                    if (if unsafe: *ptr != 44: 1 else: 0) != 0:
                        (unsafe: *errorcodeptr = ERR24)
                        comptime_error("goto not supported")


                (unsafe: *ptrptr = (ptr + (1 as isize as usize)))
                return parsed_pattern
                __pc = 1
                continue
            1 =>  // UNCLOSED_PARENTHESIS
                (unsafe: *errorcodeptr = ERR14)
                __pc = 2
                continue
            2 =>  // FAILED
                (unsafe: *ptrptr = ptr)
                return null
            _ => break

fn manage_callouts(ptr: *const u8, pcalloutptr: *mut *mut c_uint, auto_callout: c_int, parsed_pattern: *mut c_uint, cb: *mut compile_block_8) -> *mut c_uint:
    var parsed_pattern = parsed_pattern
    var previous_callout: *mut c_uint = null // init: untranslatable
    if (not auto_callout) != 0:
        (previous_callout = null)
    else:
        if (if (if (if previous_callout == null: 1 else: 0) != 0 or (if previous_callout != (parsed_pattern - (4 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 or (if previous_callout[3] != 255: 1 else: 0) != 0: 1 else: 0) != 0:
            (previous_callout = parsed_pattern)
            parsed_pattern = parsed_pattern + 4
            (previous_callout[0] = 2147876864)
            (previous_callout[2] = 0)
            (previous_callout[3] = 255)


    (unsafe: *pcalloutptr = previous_callout)
    return parsed_pattern

fn handle_escdsw(escape: c_int, parsed_pattern: *mut c_uint, options: c_uint, xoptions: c_uint) -> *mut c_uint:
    var parsed_pattern = parsed_pattern
    var ascii_option: c_uint = 0 // init: untranslatable
    var prop: c_uint = 0 // init: untranslatable
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
        (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% escape))
    else:
        (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% prop))
        match escape
            ESC_d => 0
            ESC_s => 0
            ESC_w => 0
            _ => 0


    return parsed_pattern

fn max_parsed_pattern(ptr: *const u8, ptrend: *const u8, utf: c_int, options: c_uint) -> c_long:
    var big32count: c_ulong = 0 // init: untranslatable
    var parsed_size_needed: c_long = 0 // init: untranslatable
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
fn parse_regex(ptr: *const u8, options: c_uint, xoptions: c_uint, has_lookbehind: *mut c_int, cb: *mut compile_block_8) -> c_int:
    var ptr = ptr
    var options = options
    var xoptions = xoptions
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
    while true:
        match __pc
            0 =>
                after_manual_callout = 0
                expect_cond_assert = 0
                errorcode = 0
                if (if ((xoptions & 8)) != 0: 1 else: 0) != 0:
                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148073472)
                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149449728)
                else:
                    if (if ((xoptions & 4)) != 0: 1 else: 0) != 0:
                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% 5))
                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149449728)


                if (if ((options & 33554432)) != 0: 1 else: 0) != 0:
                    while (if ptr < ptrend: 1 else: 0) != 0:
                        if (if parsed_pattern >= parsed_pattern_end: 1 else: 0) != 0:
                            (errorcode = ERR63)
                            __pc = 19
            continue

                        (thisptr = ptr)
                        // (empty)
                        if auto_callout != 0:
                            (parsed_pattern = manage_callouts(thisptr, &previous_callout, auto_callout, parsed_pattern, cb))

                        // (empty)

                    __pc = 17
            continue

                (top_nest = null)
                if (if ((options & 16777216)) != 0: 1 else: 0) != 0:
                    options = options | 128

                while (if ptr < ptrend: 1 else: 0) != 0:
                    var prev_expect_cond_assert: c_int = 0
                    var min_repeat: c_uint = 0 // init failed
                    var max_repeat: c_uint = 0 // init failed
                    var set: c_uint = 0 // init failed
                    var unset: c_uint = 0 // init failed
                    var optset: *mut c_uint = null // init failed
                    var xset: c_uint = 0 // init failed
                    var xunset: c_uint = 0 // init failed
                    var xoptset: *mut c_uint = null // init failed
                    var terminator: c_uint = 0 // init failed
                    var prev_meta_quantifier: c_uint = 0 // init failed
                    var prev_okquantifier: c_int = 0 // init failed
                    var tempptr: *const u8 = null // init failed
                    var offset: c_ulong = 0 // init failed
                    if (if nest_depth > cb.cx.parens_nest_limit: 1 else: 0) != 0:
                        (errorcode = ERR19)
                        __pc = 19
            continue

                    if (if parsed_pattern >= parsed_pattern_end: 1 else: 0) != 0:
                        (errorcode = ERR63)
                        __pc = 19
            continue

                    if (if this_parsed_item != parsed_pattern: 1 else: 0) != 0:
                        (prev_parsed_item = this_parsed_item)
                        (this_parsed_item = parsed_pattern)

                    (thisptr = ptr)
                    // (empty)
                    if inescq != 0:
                        if (if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                            (inescq = 0)
                            (ptr = ptr + 1)
                        else:
                            if inverbname != 0:
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = c)
                            else:
                                if (if (after_manual_callout = after_manual_callout - 1) <= 0: 1 else: 0) != 0:
                                    (parsed_pattern = manage_callouts(thisptr, &previous_callout, auto_callout, parsed_pattern, cb))

                                // (empty)

                            (meta_quantifier = 0)

                        continue

                    if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                        if (if (if unsafe: *ptr == 81: 1 else: 0) != 0 or (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (if (if expect_cond_assert > 0: 1 else: 0) != 0 and (if unsafe: *ptr == 81: 1 else: 0) != 0: 1 else: 0) != 0 and (not ((if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0 and (if ptr[1] == 92: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[2] == 69: 1 else: 0) != 0: 1 else: 0))) != 0: 1 else: 0) != 0:
                                (ptr = ptr - 1)
                                (errorcode = ERR28)
                                __pc = 19
            continue

                            (inescq = (if unsafe: *ptr == 81: 1 else: 0))
                            (ptr = ptr + 1)
                            continue


                    if (if ((options & 128)) != 0: 1 else: 0) != 0:
                        if (if (if c < 256: 1 else: 0) != 0 and (if ((cb.ctypes[c] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                            continue

                        if (if c == 35: 1 else: 0) != 0:
                            while (if ptr < ptrend: 1 else: 0) != 0:
                                (ptr = ptr + 1)

                            continue


                    if (if (if (if (if c == 40: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[0] == 63: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 35: 1 else: 0) != 0: 1 else: 0) != 0:
                        while (if (if (ptr = ptr + 1) < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
// (empty)
                        if (if ptr >= ptrend: 1 else: 0) != 0:
                            (errorcode = ERR18)
                            __pc = 19
            continue

                        (ptr = ptr + 1)
                        continue

                    if (if expect_cond_assert > 0: 1 else: 0) != 0:
                        var ok: c_int = 0 // init failed
                        if ok != 0:
                            if (if ptr[0] == 42: 1 else: 0) != 0:
                                (ok = (if 1 != 0 and (if ((cb.ctypes[ptr[1]] & 4)) != 0: 1 else: 0) != 0: 1 else: 0))
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



                        if (not ok) != 0:
                            (errorcode = ERR28)
                            if (if expect_cond_assert == 2: 1 else: 0) != 0:
                                __pc = 19
            continue

                            __pc = 20
            continue


                    (prev_expect_cond_assert = expect_cond_assert)
                    (expect_cond_assert = 0)
                    (prev_okquantifier = okquantifier)
                    (prev_meta_quantifier = meta_quantifier)
                    (okquantifier = 0)
                    (meta_quantifier = 0)
                    if (if (if prev_meta_quantifier != 0: 1 else: 0) != 0 and ((if (if c == 63: 1 else: 0) != 0 or (if c == 43: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (parsed_pattern[(if ((if prev_meta_quantifier == 2151743488: 1 else: 0)) != 0: (0 - 3) else: (0 - 1))] = (prev_meta_quantifier +% ((if ((if c == 63: 1 else: 0)) != 0: 131072 else: 65536))))
                        continue

                    match c
                        _ =>
                            // (empty)
                        92 =>
                            (tempptr = ptr)
                            (escape = _pcre2_check_escape_8(&ptr, ptrend, &c, &errorcode, options, xoptions, cb.bracount, 0, cb))
                            if (if errorcode != 0: 1 else: 0) != 0:
                                // label: ESCAPE_FAILED
if (if ((xoptions & 2)) == 0: 1 else: 0) != 0:
                                    comptime_error("goto not supported")

                                (ptr = tempptr)
                                if (if ptr >= ptrend: 1 else: 0) != 0:
                                    (c = 92)
                                else:
                                    // (empty)

                                (escape = 0)

                            if (if escape == 0: 1 else: 0) != 0:
                                // (empty)
                            else:
                                if (if escape < 0: 1 else: 0) != 0:
                                    (escape = ((0 - escape) - 1))
                                    (okquantifier = 1)
                                else:
                                    match escape
                                        ESC_C =>
                                            if (if ((options & 1048576)) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR83)
                                                comptime_error("goto not supported")

                                            (okquantifier = 1)
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% escape))
                                        ESC_ub =>
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 117)
                                            // (empty)
                                        ESC_X =>
                                            (errorcode = ERR45)
                                            comptime_error("goto not supported")
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% escape))
                                        ESC_H =>
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% escape))
                                        _ =>
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% escape))
                                        ESC_d =>
                                            (parsed_pattern = handle_escdsw(escape, parsed_pattern, options, xoptions))
                                        ESC_P =>
                                            comptime_error("goto not supported")
                                        ESC_g =>
                                            (terminator = (if ((if unsafe: *ptr == 60: 1 else: 0)) != 0: 62 else: (if ((if unsafe: *ptr == 39: 1 else: 0)) != 0: 39 else: 125)))
                                            if (if (if escape == ESC_g: 1 else: 0) != 0 and (if terminator != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                                                var p: *const u8 = null // init: untranslatable
                                                if read_number(&p, ptrend, cb.bracount, 65535, 161, &i, &errorcode) != 0:
                                                    if (if (if p >= ptrend: 1 else: 0) != 0 or (if unsafe: *p != terminator: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = p)
                                                        (errorcode = ERR119)
                                                        comptime_error("goto not supported")

                                                    (ptr = (p + (1 as isize as usize)))
                                                    comptime_error("goto not supported")

                                                if (if errorcode != 0: 1 else: 0) != 0:
                                                    comptime_error("goto not supported")


                                            if (not read_name(&ptr, ptrend, utf, terminator, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                                comptime_error("goto not supported")

                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if ((if (if escape == ESC_k: 1 else: 0) != 0 or (if terminator == 125: 1 else: 0) != 0: 1 else: 0)) != 0: 2147745792 else: 2149908480))
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)
                                            // (empty)
                                            (okquantifier = 1)



                        94 =>
                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148073472)
                        36 =>
                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149187584)
                        46 =>
                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149253120)
                            (okquantifier = 1)
                        42 =>
                            (meta_quantifier = 2151153664)
                            comptime_error("goto not supported")
                            (meta_quantifier = 2151350272)
                            comptime_error("goto not supported")
                            (meta_quantifier = 2151546880)
                            comptime_error("goto not supported")
                            if (not read_repeat_counts(&ptr, ptrend, &min_repeat, &max_repeat, &errorcode)) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    comptime_error("goto not supported")

                                // (empty)
                                break

                            (meta_quantifier = 2151743488)
                            // label: CHECK_QUANTIFIER
if (not prev_okquantifier) != 0:
                                (errorcode = ERR9)
                                comptime_error("goto not supported")

                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                var p: *mut c_uint = null // init: untranslatable
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
(p[1] = p[0])                                    (p = p - 1)

                                (unsafe: *verbstartptr = 2149449728)
                                (parsed_pattern[1] = 2149384192)
                                parsed_pattern = parsed_pattern + 2

                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = meta_quantifier)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = min_repeat)
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = max_repeat)

                        43 =>
                            (meta_quantifier = 2151350272)
                            comptime_error("goto not supported")
                            (meta_quantifier = 2151546880)
                            comptime_error("goto not supported")
                            if (not read_repeat_counts(&ptr, ptrend, &min_repeat, &max_repeat, &errorcode)) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    comptime_error("goto not supported")

                                // (empty)
                                break

                            (meta_quantifier = 2151743488)
                            // label: CHECK_QUANTIFIER
if (not prev_okquantifier) != 0:
                                (errorcode = ERR9)
                                comptime_error("goto not supported")

                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                var p: *mut c_uint = null // init: untranslatable
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
(p[1] = p[0])                                    (p = p - 1)

                                (unsafe: *verbstartptr = 2149449728)
                                (parsed_pattern[1] = 2149384192)
                                parsed_pattern = parsed_pattern + 2

                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = meta_quantifier)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = min_repeat)
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = max_repeat)

                        63 =>
                            (meta_quantifier = 2151546880)
                            comptime_error("goto not supported")
                            if (not read_repeat_counts(&ptr, ptrend, &min_repeat, &max_repeat, &errorcode)) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    comptime_error("goto not supported")

                                // (empty)
                                break

                            (meta_quantifier = 2151743488)
                            // label: CHECK_QUANTIFIER
if (not prev_okquantifier) != 0:
                                (errorcode = ERR9)
                                comptime_error("goto not supported")

                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                var p: *mut c_uint = null // init: untranslatable
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
(p[1] = p[0])                                    (p = p - 1)

                                (unsafe: *verbstartptr = 2149449728)
                                (parsed_pattern[1] = 2149384192)
                                parsed_pattern = parsed_pattern + 2

                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = meta_quantifier)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = min_repeat)
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = max_repeat)

                        123 =>
                            if (not read_repeat_counts(&ptr, ptrend, &min_repeat, &max_repeat, &errorcode)) != 0:
                                if (if errorcode != 0: 1 else: 0) != 0:
                                    comptime_error("goto not supported")

                                // (empty)
                                break

                            (meta_quantifier = 2151743488)
                            // label: CHECK_QUANTIFIER
if (not prev_okquantifier) != 0:
                                (errorcode = ERR9)
                                comptime_error("goto not supported")

                            if (if unsafe: *prev_parsed_item == 2150498304: 1 else: 0) != 0:
                                var p: *mut c_uint = null // init: untranslatable
                                (p = (parsed_pattern - (1 as isize as usize)))
                                while (if p >= verbstartptr: 1 else: 0) != 0:
(p[1] = p[0])                                    (p = p - 1)

                                (unsafe: *verbstartptr = 2149449728)
                                (parsed_pattern[1] = 2149384192)
                                parsed_pattern = parsed_pattern + 2

                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = meta_quantifier)
                            if (if c == 123: 1 else: 0) != 0:
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = min_repeat)
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = max_repeat)

                        91 =>
                            if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 6: 1 else: 0) != 0 and ((if (if _pcre2_strncmp_c8_8(ptr, STRING_WEIRD_STARTWORD, 6) == 0: 1 else: 0) != 0 or (if _pcre2_strncmp_c8_8(ptr, STRING_WEIRD_ENDWORD, 6) == 0: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% 5))
                                if (if ptr[2] == 60: 1 else: 0) != 0:
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150039552)
                                else:
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150170624)
                                    (unsafe: *has_lookbehind = 1)
                                    // (empty)

                                if (if ((options & 131072)) == 0: 1 else: 0) != 0:
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% 11))
                                else:
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% 16))
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 524288)

                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149384192)
                                ptr = ptr + 6
                                (okquantifier = 1)
                                break

                            if (if (if (if ptr < ptrend: 1 else: 0) != 0 and ((if (if (if unsafe: *ptr == 58: 1 else: 0) != 0 or (if unsafe: *ptr == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *ptr == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend, &tempptr) != 0: 1 else: 0) != 0:
                                (errorcode = (if ((if unsafe: *(ptr = ptr - 1) == 58: 1 else: 0)) != 0: ERR12 else: ERR13))
                                (ptr = (tempptr + (2 as isize as usize)))
                                comptime_error("goto not supported")

                            (class_mode_state = (if ((if ((options & 134217728)) != 0: 1 else: 0)) != 0: CLASS_MODE_ALT_EXT else: CLASS_MODE_NORMAL))
                            // label: FROM_PERL_EXTENDED_CLASS
(okquantifier = 1)
                            (class_depth_m1 = -1)
                            (class_maxdepth_m1 = -1)
                            (class_range_state = 0)
                            (class_op_state = 0)
                            (class_start = null)
                            while true:
                                var char_is_literal: c_int = 0 // init: untranslatable
                                if inescq != 0:
                                    if (if (if (if c == 92: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (inescq = 0)
                                        (ptr = ptr + 1)
                                        comptime_error("goto not supported")

                                    if (if class_mode_state == 2: 1 else: 0) != 0:
                                        (errorcode = ERR116)
                                        comptime_error("goto not supported")

                                    comptime_error("goto not supported")

                                if (if ((if (if c == 32: 1 else: 0) != 0 or (if c == 9: 1 else: 0) != 0: 1 else: 0)) != 0 and ((if (if ((options & 16777216)) != 0: 1 else: 0) != 0 or (if class_mode_state >= 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                    comptime_error("goto not supported")

                                if (if (if (if (if (if class_depth_m1 >= 0: 1 else: 0) != 0 and (if c == 91: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0: 1 else: 0) != 0 and ((if (if (if unsafe: *ptr == 58: 1 else: 0) != 0 or (if unsafe: *ptr == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *ptr == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend, &tempptr) != 0: 1 else: 0) != 0:
                                    var posix_negate: c_int = 0 // init: untranslatable
                                    var posix_class: c_int = 0
                                    if (if class_range_state == 1: 1 else: 0) != 0:
                                        (ptr = (tempptr + (2 as isize as usize)))
                                        (errorcode = ERR50)
                                        comptime_error("goto not supported")

                                    if (if class_range_state == 3: 1 else: 0) != 0:
                                        (ptr = class_range_forbid_ptr)
                                        (errorcode = ERR50)
                                        comptime_error("goto not supported")

                                    if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (ptr = (tempptr + (2 as isize as usize)))
                                        (errorcode = ERR113)
                                        comptime_error("goto not supported")

                                    if (if unsafe: *ptr != 58: 1 else: 0) != 0:
                                        (ptr = (tempptr + (2 as isize as usize)))
                                        (errorcode = ERR13)
                                        comptime_error("goto not supported")

                                    if (if unsafe: *((ptr = ptr + 1)) == 94: 1 else: 0) != 0:
                                        (posix_negate = 1)
                                        (ptr = ptr + 1)

                                    (posix_class = check_posix_name(ptr, ((((tempptr as usize -% ptr as usize) / sizeof[u8]())) as c_int)))
                                    (ptr = (tempptr + (2 as isize as usize)))
                                    if (if posix_class < 0: 1 else: 0) != 0:
                                        (errorcode = ERR30)
                                        comptime_error("goto not supported")

                                    (class_range_state = 2)
                                    (class_op_state = 1)
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if posix_negate != 0: 2149646336 else: 2149580800))
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = posix_class)
                                else:
                                    if (if ((if (if c == 91: 1 else: 0) != 0 and ((if (if (if class_depth_m1 < 0: 1 else: 0) != 0 or (if class_mode_state == 1: 1 else: 0) != 0: 1 else: 0) != 0 or (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0 or ((if (if c == 40: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        var start_c: c_uint = 0 // init: untranslatable
                                        var new_class_mode_state: c_uint = 0 // init: untranslatable
                                        if (if (if (if start_c == 91: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if class_depth_m1 >= 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (new_class_mode_state = 3)
                                        else:
                                            (new_class_mode_state = class_mode_state)

                                        if (if class_range_state == 1: 1 else: 0) != 0:
                                            (parsed_pattern[(0 - 1)] = 45)

                                        if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (errorcode = ERR113)
                                            comptime_error("goto not supported")

                                        if (if class_depth_m1 >= (15 - 1): 1 else: 0) != 0:
                                            (ptr = ptr - 1)
                                            (errorcode = ERR107)
                                            comptime_error("goto not supported")

                                        (negate_class = 0)
                                        while true:
                                            if (if ptr >= ptrend: 1 else: 0) != 0:
                                                if (if start_c == 40: 1 else: 0) != 0:
                                                    (errorcode = ERR14)
                                                else:
                                                    (errorcode = ERR6)

                                                comptime_error("goto not supported")

                                            // (empty)
                                            if (if new_class_mode_state == 2: 1 else: 0) != 0:
                                                break
                                            else:
                                                if (if c == 92: 1 else: 0) != 0:
                                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = ptr + 1)
                                                    else:
                                                        if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, STR_Q STR_BACKSLASH STR_E, 3) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            ptr = ptr + 3
                                                        else:
                                                            break





                                        if (if (if (if c == 93: 1 else: 0) != 0 and (if ((cb.external_options & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if new_class_mode_state < 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            if (if class_start != null: 1 else: 0) != 0:
                                                unsafe: *class_start = unsafe: *class_start | 1
                                                (class_start = null)

                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if negate_class != 0: 2148270080 else: 2148204544))
                                            if (if class_depth_m1 < 0: 1 else: 0) != 0:
                                                break

                                            (class_range_state = 0)
                                            (class_op_state = 1)
                                            comptime_error("goto not supported")

                                        if (if class_start != null: 1 else: 0) != 0:
                                            unsafe: *class_start = unsafe: *class_start | 1
                                            (class_start = null)

                                        (class_start = parsed_pattern)
                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if negate_class != 0: 2148401152 else: 2148139008))
                                        (class_range_state = 0)
                                        (class_op_state = 0)
                                        (class_mode_state = new_class_mode_state)
                                        (class_depth_m1 = class_depth_m1 + 1)
                                        if (if class_maxdepth_m1 < class_depth_m1: 1 else: 0) != 0:
                                            (class_maxdepth_m1 = class_depth_m1)

                                        (cb.class_op_used[class_depth_m1] = 0)
                                        if (if (if c == 93: 1 else: 0) != 0 and (if new_class_mode_state != 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (class_range_state = 5)
                                            (class_op_state = 1)
                                            // (empty)
                                            comptime_error("goto not supported")

                                        continue
                                    else:
                                        if (if (if c == 93: 1 else: 0) != 0 or ((if (if c == 41: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                            if (if class_mode_state == 2: 1 else: 0) != 0:
                                                if (if (if c == 93: 1 else: 0) != 0 and (if class_depth_m1 != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode = ERR14)
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")

                                                if (if (if c == 41: 1 else: 0) != 0 and (if class_depth_m1 < 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode = ERR22)
                                                    comptime_error("goto not supported")


                                            if (if class_op_state == 2: 1 else: 0) != 0:
                                                (errorcode = ERR110)
                                                comptime_error("goto not supported")

                                            if (if (if class_mode_state == 2: 1 else: 0) != 0 and (if class_op_state == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR114)
                                                comptime_error("goto not supported")

                                            if (if class_range_state == 1: 1 else: 0) != 0:
                                                (parsed_pattern[(0 - 1)] = 45)

                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148335616)
                                            if (if (class_depth_m1 = class_depth_m1 - 1) < 0: 1 else: 0) != 0:
                                                if (if class_mode_state == 2: 1 else: 0) != 0:
                                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (errorcode = ERR115)
                                                        comptime_error("goto not supported")

                                                    (ptr = ptr + 1)

                                                break

                                            (class_range_state = 0)
                                            (class_op_state = 1)
                                            if (if class_mode_state == 3: 1 else: 0) != 0:
                                                (class_mode_state = 2)

                                            (class_start = null)
                                        else:
                                            if (if (if class_mode_state == 2: 1 else: 0) != 0 and ((if (if (if (if (if c == 43: 1 else: 0) != 0 or (if c == 124: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 45: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 38: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 94: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                if (if class_op_state != 1: 1 else: 0) != 0:
                                                    (errorcode = ERR109)
                                                    comptime_error("goto not supported")

                                                if (if class_start != null: 1 else: 0) != 0:
                                                    unsafe: *class_start = unsafe: *class_start | 1
                                                    (class_start = null)

                                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if (if c == 43: 1 else: 0) != 0: 2152005632 else: (if (if c == 124: 1 else: 0) != 0: 2152005632 else: (if (if c == 45: 1 else: 0) != 0: 2152071168 else: (if (if c == 38: 1 else: 0) != 0: 2151940096 else: 2152136704)))))
                                                (class_range_state = 0)
                                                (class_op_state = 2)
                                            else:
                                                if (if (if class_mode_state == 2: 1 else: 0) != 0 and (if c == 33: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    if (if class_op_state == 1: 1 else: 0) != 0:
                                                        (errorcode = ERR113)
                                                        comptime_error("goto not supported")

                                                    if (if class_start != null: 1 else: 0) != 0:
                                                        unsafe: *class_start = unsafe: *class_start | 1
                                                        (class_start = null)

                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2152202240)
                                                    (class_range_state = 0)
                                                    (class_op_state = 2)
                                                else:
                                                    if (if (if (if (if class_mode_state == 1: 1 else: 0) != 0 and ((if (if (if (if c == 124: 1 else: 0) != 0 or (if c == 45: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 38: 1 else: 0) != 0: 1 else: 0) != 0 or (if c == 126: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and (if ptr < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr == c: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = ptr + 1)
                                                        if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == c: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            while (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == c: 1 else: 0) != 0: 1 else: 0) != 0:
(ptr = ptr + 1)
                                                            (errorcode = ERR108)
                                                            comptime_error("goto not supported")

                                                        if (if class_op_state != 1: 1 else: 0) != 0:
                                                            (errorcode = ERR109)
                                                            comptime_error("goto not supported")

                                                        if (if class_start != null: 1 else: 0) != 0:
                                                            unsafe: *class_start = unsafe: *class_start | 1
                                                            (class_start = null)

                                                        if (if class_range_state == 1: 1 else: 0) != 0:
                                                            (parsed_pattern[(0 - 1)] = 45)

                                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if (if c == 124: 1 else: 0) != 0: 2152005632 else: (if (if c == 45: 1 else: 0) != 0: 2152071168 else: (if (if c == 38: 1 else: 0) != 0: 2151940096 else: 2152136704))))
                                                        (class_range_state = 0)
                                                        (class_op_state = 2)
                                                    else:
                                                        if (if c == 92: 1 else: 0) != 0:
                                                            (tempptr = ptr)
                                                            (escape = _pcre2_check_escape_8(&ptr, ptrend, &c, &errorcode, options, xoptions, cb.bracount, 1, cb))
                                                            if (if errorcode != 0: 1 else: 0) != 0:
                                                                if (if (if ((xoptions & 2)) == 0: 1 else: 0) != 0 or (if class_mode_state >= 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                    comptime_error("goto not supported")

                                                                (ptr = tempptr)
                                                                if (if ptr >= ptrend: 1 else: 0) != 0:
                                                                    (c = 92)
                                                                else:
                                                                    // (empty)

                                                                (escape = 0)

                                                            match escape
                                                                0 =>
                                                                    (char_is_literal = 0)
                                                                    comptime_error("goto not supported")
                                                                    (c = 8)
                                                                    (char_is_literal = 0)
                                                                    comptime_error("goto not supported")
                                                                    (c = 107)
                                                                    (char_is_literal = 0)
                                                                    comptime_error("goto not supported")
                                                                    (inescq = 1)
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    (errorcode = ERR71)
                                                                    comptime_error("goto not supported")
                                                                ESC_b =>
                                                                    (c = 8)
                                                                    (char_is_literal = 0)
                                                                    comptime_error("goto not supported")
                                                                    (c = 107)
                                                                    (char_is_literal = 0)
                                                                    comptime_error("goto not supported")
                                                                    (inescq = 1)
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    (errorcode = ERR71)
                                                                    comptime_error("goto not supported")
                                                                ESC_k =>
                                                                    (c = 107)
                                                                    (char_is_literal = 0)
                                                                    comptime_error("goto not supported")
                                                                    (inescq = 1)
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    (errorcode = ERR71)
                                                                    comptime_error("goto not supported")
                                                                ESC_Q =>
                                                                    (inescq = 1)
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    (errorcode = ERR71)
                                                                    comptime_error("goto not supported")
                                                                ESC_E =>
                                                                    comptime_error("goto not supported")
                                                                    comptime_error("goto not supported")
                                                                    (errorcode = ERR71)
                                                                    comptime_error("goto not supported")
                                                                ESC_B =>
                                                                    comptime_error("goto not supported")
                                                                    (errorcode = ERR71)
                                                                    comptime_error("goto not supported")
                                                                ESC_N =>
                                                                    (errorcode = ERR71)
                                                                    comptime_error("goto not supported")
                                                                ESC_H => 0
                                                                ESC_d => 0
                                                                ESC_P =>
                                                                    comptime_error("goto not supported")
                                                                _ =>
                                                                    comptime_error("goto not supported")
                                                                ESC_A =>
                                                                    comptime_error("goto not supported")

                                                            if (if class_range_state == 1: 1 else: 0) != 0:
                                                                (errorcode = ERR50)
                                                                comptime_error("goto not supported")

                                                            if (if class_range_state == 3: 1 else: 0) != 0:
                                                                (ptr = class_range_forbid_ptr)
                                                                (errorcode = ERR50)
                                                                comptime_error("goto not supported")

                                                            if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                (errorcode = ERR113)
                                                                comptime_error("goto not supported")

                                                            (class_range_state = 2)
                                                            (class_op_state = 1)
                                                        else:
                                                            if (if class_mode_state == 2: 1 else: 0) != 0:
                                                                (errorcode = ERR116)
                                                                comptime_error("goto not supported")
                                                            else:
                                                                if (if (if c == 45: 1 else: 0) != 0 and (if class_range_state >= 4: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if ((if class_range_state == 5: 1 else: 0)) != 0: 2149777408 else: 2149711872))
                                                                    (class_range_state = 1)
                                                                else:
                                                                    if (if (if c == 45: 1 else: 0) != 0 and (if class_range_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 45)
                                                                        (class_range_state = 3)
                                                                        (class_range_forbid_ptr = ptr)
                                                                    else:
                                                                        // label: CLASS_LITERAL
if (if (if class_op_state == 1: 1 else: 0) != 0 and (if class_mode_state == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                            (errorcode = ERR113)
                                                                            comptime_error("goto not supported")

                                                                        if (if class_range_state == 1: 1 else: 0) != 0:
                                                                            if (if c == parsed_pattern[(0 - 2)]: 1 else: 0) != 0:
                                                                                (parsed_pattern = parsed_pattern - 1)
                                                                            else:
                                                                                if (if parsed_pattern[(0 - 2)] > c: 1 else: 0) != 0:
                                                                                    (errorcode = ERR8)
                                                                                    comptime_error("goto not supported")
                                                                                else:
                                                                                    if (if (not char_is_literal) != 0 and (if parsed_pattern[(0 - 1)] == 2149777408: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                                        (parsed_pattern[(0 - 1)] = 2149711872)

                                                                                    // (empty)


                                                                            (class_range_state = 0)
                                                                            (class_op_state = 1)
                                                                        else:
                                                                            if (if class_range_state == 3: 1 else: 0) != 0:
                                                                                (ptr = class_range_forbid_ptr)
                                                                                (errorcode = ERR50)
                                                                                comptime_error("goto not supported")
                                                                            else:
                                                                                (class_range_state = (if char_is_literal != 0: RANGE_OK_LITERAL else: RANGE_OK_ESCAPED))
                                                                                (class_op_state = 1)
                                                                                // (empty)












                                // label: CLASS_CONTINUE
if (if ptr >= ptrend: 1 else: 0) != 0:
                                    if (if (if class_mode_state == 2: 1 else: 0) != 0 and (if class_depth_m1 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR14)

                                    if (if (if (if class_mode_state == 1: 1 else: 0) != 0 and (if class_depth_m1 == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if class_maxdepth_m1 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR112)
                                    else:
                                        (errorcode = ERR6)

                                    comptime_error("goto not supported")

                                // (empty)

                        40 =>
                            if (if ptr >= ptrend: 1 else: 0) != 0:
                                comptime_error("goto not supported")

                            if (if unsafe: *ptr != 63: 1 else: 0) != 0:
                                var vn: *const i8 = null
                                if (if unsafe: *ptr != 42: 1 else: 0) != 0:
                                    (nest_depth = nest_depth + 1)
                                    if (if ((options & 8192)) == 0: 1 else: 0) != 0:
                                        if (if cb.bracount >= 65535: 1 else: 0) != 0:
                                            (errorcode = ERR97)
                                            comptime_error("goto not supported")

                                        (cb.bracount = cb.bracount + 1)
                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2148007936 | cb.bracount))
                                    else:
                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149449728)

                                else:
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or (if ((c = ptr[1])) == 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        break
                                    else:
                                        if (if 1 != 0 and (if ((cb.ctypes[c] & 4)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            var meta: c_uint = 0 // init: untranslatable
                                            (vn = alasnames)
                                            if (not read_name(&ptr, ptrend, utf, 0, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                                comptime_error("goto not supported")

                                            if (if ptr >= ptrend: 1 else: 0) != 0:
                                                comptime_error("goto not supported")

                                            if (if unsafe: *ptr != 58: 1 else: 0) != 0:
                                                (errorcode = ERR95)
                                                comptime_error("goto not supported")

                                            (i = 0)
                                            while (if i < 19: 1 else: 0) != 0:
                                                if (if (if namelen == alasmeta[i].len: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name, vn, namelen) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    break

                                                vn = vn + (alasmeta[i].len +% 1)
                                                (i = i + 1)

                                            if (if i >= 19: 1 else: 0) != 0:
                                                (errorcode = ERR95)
                                                comptime_error("goto not supported")

                                            (meta = alasmeta[i].meta)
                                            if (if (if prev_expect_cond_assert > 0: 1 else: 0) != 0 and ((if (if meta < 2150039552: 1 else: 0) != 0 or (if meta > 2150236160: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR28)
                                                comptime_error("goto not supported")

                                            match meta
                                                _ =>
                                                    (errorcode = ERR89)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    (ptr = ptr + 1)
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148990976)
                                                    (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, 0, &errorcode, cb))
                                                    if (if parsed_pattern == null: 1 else: 0) != 0:
                                                        comptime_error("goto not supported")

                                                    comptime_error("goto not supported")
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                2147614720 =>
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    (ptr = ptr + 1)
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148990976)
                                                    (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, 0, &errorcode, cb))
                                                    if (if parsed_pattern == null: 1 else: 0) != 0:
                                                        comptime_error("goto not supported")

                                                    comptime_error("goto not supported")
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                2150039552 =>
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    (ptr = ptr + 1)
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148990976)
                                                    (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, 0, &errorcode, cb))
                                                    if (if parsed_pattern == null: 1 else: 0) != 0:
                                                        comptime_error("goto not supported")

                                                    comptime_error("goto not supported")
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                2150301696 =>
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                    (ptr = ptr + 1)
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148990976)
                                                    (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, 0, &errorcode, cb))
                                                    if (if parsed_pattern == null: 1 else: 0) != 0:
                                                        comptime_error("goto not supported")

                                                    comptime_error("goto not supported")
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                2150105088 =>
                                                    comptime_error("goto not supported")
                                                    (ptr = ptr + 1)
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148990976)
                                                    (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, 0, &errorcode, cb))
                                                    if (if parsed_pattern == null: 1 else: 0) != 0:
                                                        comptime_error("goto not supported")

                                                    comptime_error("goto not supported")
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                2148990976 =>
                                                    (ptr = ptr + 1)
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148990976)
                                                    (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, 0, &errorcode, cb))
                                                    if (if parsed_pattern == null: 1 else: 0) != 0:
                                                        comptime_error("goto not supported")

                                                    comptime_error("goto not supported")
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                2150170624 =>
                                                    (ptr = ptr - 1)
                                                    comptime_error("goto not supported")
                                                    comptime_error("goto not supported")
                                                2149974016 =>
                                                    comptime_error("goto not supported")

                                        else:
                                            (vn = verbnames)
                                            if (not read_name(&ptr, ptrend, utf, 0, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                                comptime_error("goto not supported")

                                            if (if (if ptr >= ptrend: 1 else: 0) != 0 or ((if (if unsafe: *ptr != 58: 1 else: 0) != 0 and (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR60)
                                                comptime_error("goto not supported")

                                            (i = 0)
                                            while (if i < 9: 1 else: 0) != 0:
                                                if (if (if namelen == verbs[i].len: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name, vn, namelen) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    break

                                                vn = vn + (verbs[i].len +% 1)
                                                (i = i + 1)

                                            if (if i >= 9: 1 else: 0) != 0:
                                                (errorcode = ERR60)
                                                comptime_error("goto not supported")

                                            if (if (if (if unsafe: *ptr == 58: 1 else: 0) != 0 and (if (ptr + (1 as isize as usize)) < ptrend: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (ptr = ptr + 1)

                                            if (if (if verbs[i].has_arg > 0: 1 else: 0) != 0 and (if unsafe: *ptr != 58: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (errorcode = ERR66)
                                                comptime_error("goto not supported")

                                            (verbstartptr = parsed_pattern)
                                            (okquantifier = ((if verbs[i].meta == 2150498304: 1 else: 0)))
                                            if (if unsafe: *(ptr = ptr + 1) == 58: 1 else: 0) != 0:
                                                if (if verbs[i].has_arg < 0: 1 else: 0) != 0:
                                                    (add_after_mark = verbs[i].meta)
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150432768)
                                                else:
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (verbs[i].meta +% ((if ((if verbs[i].meta != 2150432768: 1 else: 0)) != 0: 65536 else: 0))))

                                                (verblengthptr = (parsed_pattern = parsed_pattern + 1))
                                                (verbnamestart = ptr)
                                                (inverbname = 1)
                                            else:
                                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = verbs[i].meta)




                                break

                            if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                comptime_error("goto not supported")

                            match unsafe: *ptr
                                _ =>
                                    (nest_depth = nest_depth + 1)
                                    (top_nest.nest_depth = nest_depth)
                                    (top_nest.flags = 0)
                                    if (if unsafe: *ptr == 124: 1 else: 0) != 0:
                                        top_nest.flags = top_nest.flags | 1
                                        cb.external_flags = cb.external_flags | 2097152
                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149449728)
                                        (ptr = ptr + 1)
                                    else:
                                        var hyphenok: c_int = 0 // init: untranslatable
                                        var oldoptions: c_uint = 0 // init: untranslatable
                                        var oldxoptions: c_uint = 0 // init: untranslatable
                                        (top_nest.reset_group = 0)
                                        (top_nest.max_group = 0)
                                        (set = (unset = 0))
                                        (optset = &set)
                                        (xset = (xunset = 0))
                                        (xoptset = &xset)
                                        if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 94: 1 else: 0) != 0: 1 else: 0) != 0:
                                            options = options & (0 - ((((((8 | 1024) | 8192) | 32) | 128) | 16777216)) - 1)
                                            xoptions = xoptions & (0 - (128) - 1)
                                            (hyphenok = 0)
                                            (ptr = ptr + 1)

                                        while (if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0 and (if unsafe: *ptr != 58: 1 else: 0) != 0: 1 else: 0) != 0:
                                            match unsafe: *(ptr = ptr + 1)
                                                45 =>
                                                    if (not hyphenok) != 0:
                                                        (errorcode = ERR94)
                                                        comptime_error("goto not supported")

                                                    (optset = &unset)
                                                    (xoptset = &xunset)
                                                    (hyphenok = 0)
                                                97 =>
                                                    if (if ptr < ptrend: 1 else: 0) != 0:
                                                        if (if unsafe: *ptr == 68: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 256
                                                            (ptr = ptr + 1)
                                                            break

                                                        if (if unsafe: *ptr == 80: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | ((2048 | 4096))
                                                            (ptr = ptr + 1)
                                                            break

                                                        if (if unsafe: *ptr == 83: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 512
                                                            (ptr = ptr + 1)
                                                            break

                                                        if (if unsafe: *ptr == 84: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 4096
                                                            (ptr = ptr + 1)
                                                            break

                                                        if (if unsafe: *ptr == 87: 1 else: 0) != 0:
                                                            unsafe: *xoptset = unsafe: *xoptset | 1024
                                                            (ptr = ptr + 1)
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
                                                        (ptr = ptr + 1)

                                                _ =>
                                                    (errorcode = ERR11)
                                                    comptime_error("goto not supported")


                                        if (if (if ((set & ((128 | 16777216)))) == 128: 1 else: 0) != 0 or (if ((unset & 128)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            unset = unset | 16777216

                                        (options = (((options | set)) & ((0 - unset - 1))))
                                        (xoptions = (((xoptions | xset)) & ((0 - xunset - 1))))
                                        if (if ptr >= ptrend: 1 else: 0) != 0:
                                            comptime_error("goto not supported")

                                        if (if unsafe: *(ptr = ptr + 1) == 41: 1 else: 0) != 0:
                                            (nest_depth = nest_depth - 1)
                                        else:
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149449728)

                                        if (if (if options != oldoptions: 1 else: 0) != 0 or (if xoptions != oldxoptions: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149515264)
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = options)
                                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = xoptions)


                                80 =>
                                    if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    if (if unsafe: *ptr == 60: 1 else: 0) != 0:
                                        (terminator = 62)
                                        comptime_error("goto not supported")

                                    if (if unsafe: *ptr == 62: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    if (if unsafe: *ptr != 61: 1 else: 0) != 0:
                                        (errorcode = ERR41)
                                        comptime_error("goto not supported")

                                    if (not read_name(&ptr, ptrend, utf, 41, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2147745792)
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)
                                    // (empty)
                                    (okquantifier = 1)
                                82 =>
                                    (i = 0)
                                    (ptr = ptr + 1)
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or ((if (if unsafe: *ptr != 41: 1 else: 0) != 0 and (if unsafe: *ptr != 40: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR58)
                                        comptime_error("goto not supported")

                                    (terminator = 0)
                                    comptime_error("goto not supported")
                                    if (if (ptr + (1 as isize as usize)) >= ptrend: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        comptime_error("goto not supported")

                                    (terminator = 0)
                                    // label: SET_RECURSION

                                    comptime_error("goto not supported")
                                    // label: RECURSE_BY_NAME
if (not read_name(&ptr, ptrend, utf, 0, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149908480)
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)
                                    (terminator = 0)
                                    // label: READ_RECURSION_ARGUMENTS

                                    // (empty)
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break

                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, offset, &errorcode, cb))
                                        if (if parsed_pattern == null: 1 else: 0) != 0:
                                            comptime_error("goto not supported")


                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (ptr = ptr + 1)
                                43 =>
                                    if (if (ptr + (1 as isize as usize)) >= ptrend: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        comptime_error("goto not supported")

                                    (terminator = 0)
                                    // label: SET_RECURSION

                                    comptime_error("goto not supported")
                                    // label: RECURSE_BY_NAME
if (not read_name(&ptr, ptrend, utf, 0, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149908480)
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)
                                    (terminator = 0)
                                    // label: READ_RECURSION_ARGUMENTS

                                    // (empty)
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break

                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, offset, &errorcode, cb))
                                        if (if parsed_pattern == null: 1 else: 0) != 0:
                                            comptime_error("goto not supported")


                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (ptr = ptr + 1)
                                48 =>
                                    (terminator = 0)
                                    // label: SET_RECURSION

                                    comptime_error("goto not supported")
                                    // label: RECURSE_BY_NAME
if (not read_name(&ptr, ptrend, utf, 0, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149908480)
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)
                                    (terminator = 0)
                                    // label: READ_RECURSION_ARGUMENTS

                                    // (empty)
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break

                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, offset, &errorcode, cb))
                                        if (if parsed_pattern == null: 1 else: 0) != 0:
                                            comptime_error("goto not supported")


                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (ptr = ptr + 1)
                                38 =>
                                    // label: RECURSE_BY_NAME
if (not read_name(&ptr, ptrend, utf, 0, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149908480)
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)
                                    (terminator = 0)
                                    // label: READ_RECURSION_ARGUMENTS

                                    // (empty)
                                    (okquantifier = 1)
                                    if (if terminator != 0: 1 else: 0) != 0:
                                        break

                                    if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = parse_capture_list(&ptr, ptrend, utf, parsed_pattern, offset, &errorcode, cb))
                                        if (if parsed_pattern == null: 1 else: 0) != 0:
                                            comptime_error("goto not supported")


                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (ptr = ptr + 1)
                                67 =>
                                    if (if ((xoptions & 32768)) != 0: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        (errorcode = ERR103)
                                        comptime_error("goto not supported")

                                    if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (expect_cond_assert = (prev_expect_cond_assert - 1))
                                    if (if (if (if (if previous_callout != null: 1 else: 0) != 0 and (if ((options & 4)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if previous_callout == (parsed_pattern - (4 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 and (if parsed_pattern[(0 - 1)] == 255: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern = previous_callout)

                                    (previous_callout = parsed_pattern)
                                    (after_manual_callout = 1)
                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR39)
                                        comptime_error("goto not supported")

                                    (ptr = ptr + 1)
                                    (previous_callout[2] = 0)
                                40 =>
                                    if (if (ptr = ptr + 1) >= ptrend: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (nest_depth = nest_depth + 1)
                                    if (if (if unsafe: *ptr == 63: 1 else: 0) != 0 or (if unsafe: *ptr == 42: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148466688)
                                        (ptr = ptr - 1)
                                        (expect_cond_assert = 2)
                                        break

                                    if read_number(&ptr, ptrend, cb.bracount, 65535, 161, &i, &errorcode) != 0:
                                        if (if i <= 0: 1 else: 0) != 0:
                                            (errorcode = ERR15)
                                            comptime_error("goto not supported")

                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148663296)
                                        // (empty)
                                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = i)
                                    else:
                                        if (if errorcode != 0: 1 else: 0) != 0:
                                            comptime_error("goto not supported")
                                        else:
                                            if (if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) >= 10: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, STRING_VERSION, 7) == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[7] != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                var ge: c_uint = 0 // init: untranslatable
                                                var major: c_int = 0
                                                var minor: c_int = 0
                                                ptr = ptr + 7
                                                if (if unsafe: *ptr == 62: 1 else: 0) != 0:
                                                    (ge = 1)
                                                    (ptr = ptr + 1)

                                                if (not read_number(&ptr, ptrend, (0 - 1), 1000, 179, &major, &errorcode)) != 0:
                                                    comptime_error("goto not supported")

                                                if (if (if ptr < ptrend: 1 else: 0) != 0 and (if unsafe: *ptr == 46: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    if (not read_number(&ptr, ptrend, (0 - 1), 1000, 179, &minor, &errorcode)) != 0:
                                                        comptime_error("goto not supported")


                                                if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode = ERR79)
                                                    if (if ptr < ptrend: 1 else: 0) != 0:
                                                        comptime_error("goto not supported")

                                                    comptime_error("goto not supported")

                                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2148859904)
                                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = ge)
                                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = major)
                                                (unsafe: *(parsed_pattern = parsed_pattern + 1) = minor)
                                            else:
                                                var was_r_ampersand: c_int = 0 // init: untranslatable
                                                if (if (if (if unsafe: *ptr == 82: 1 else: 0) != 0 and (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) > 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 38: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (terminator = 41)
                                                    (was_r_ampersand = 1)
                                                    (ptr = ptr + 1)
                                                else:
                                                    if (if unsafe: *ptr == 60: 1 else: 0) != 0:
                                                        (terminator = 62)
                                                    else:
                                                        if (if unsafe: *ptr == 39: 1 else: 0) != 0:
                                                            (terminator = 39)
                                                        else:
                                                            (terminator = 41)
                                                            (ptr = ptr - 1)



                                                if (not read_name(&ptr, ptrend, utf, terminator, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                                    comptime_error("goto not supported")

                                                if was_r_ampersand != 0:
                                                    (unsafe: *parsed_pattern = 2148728832)
                                                    (ptr = ptr - 1)
                                                else:
                                                    if (if terminator == 41: 1 else: 0) != 0:
                                                        if (if (if namelen == 6: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name, STRING_DEFINE, 6) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            (unsafe: *parsed_pattern = 2148532224)
                                                        else:
                                                            (unsafe: *parsed_pattern = (if ((if (if unsafe: *name == 82: 1 else: 0) != 0 and (if i >= (namelen as c_int): 1 else: 0) != 0: 1 else: 0)) != 0: 2148794368 else: 2148597760))

                                                        (ptr = ptr - 1)
                                                    else:
                                                        (unsafe: *parsed_pattern = 2148597760)


                                                if (if unsafe: *(parsed_pattern = parsed_pattern + 1) != 2148532224: 1 else: 0) != 0:
                                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = namelen)

                                                // (empty)



                                    if (if (if ptr >= ptrend: 1 else: 0) != 0 or (if unsafe: *ptr != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode = ERR24)
                                        comptime_error("goto not supported")

                                    (ptr = ptr + 1)
                                62 =>
                                    // label: ATOMIC_GROUP
(unsafe: *(parsed_pattern = parsed_pattern + 1) = 2147614720)
                                    (nest_depth = nest_depth + 1)
                                    (ptr = ptr + 1)
                                61 =>
                                    // label: POSITIVE_LOOK_AHEAD
(unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150039552)
                                    (ptr = ptr + 1)
                                    comptime_error("goto not supported")
                                    // label: POSITIVE_NONATOMIC_LOOK_AHEAD
(unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150301696)
                                    (ptr = ptr + 1)
                                    comptime_error("goto not supported")
                                    // label: NEGATIVE_LOOK_AHEAD
(unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150105088)
                                    (ptr = ptr + 1)
                                    comptime_error("goto not supported")
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    // label: POST_LOOKBEHIND
(unsafe: *has_lookbehind = 1)
                                    // (empty)
                                    ptr = ptr + 2
                                    // label: POST_ASSERTION
(nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        (top_nest.flags = 2)

                                42 =>
                                    // label: POSITIVE_NONATOMIC_LOOK_AHEAD
(unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150301696)
                                    (ptr = ptr + 1)
                                    comptime_error("goto not supported")
                                    // label: NEGATIVE_LOOK_AHEAD
(unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150105088)
                                    (ptr = ptr + 1)
                                    comptime_error("goto not supported")
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    // label: POST_LOOKBEHIND
(unsafe: *has_lookbehind = 1)
                                    // (empty)
                                    ptr = ptr + 2
                                    // label: POST_ASSERTION
(nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        (top_nest.flags = 2)

                                33 =>
                                    // label: NEGATIVE_LOOK_AHEAD
(unsafe: *(parsed_pattern = parsed_pattern + 1) = 2150105088)
                                    (ptr = ptr + 1)
                                    comptime_error("goto not supported")
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    // label: POST_LOOKBEHIND
(unsafe: *has_lookbehind = 1)
                                    // (empty)
                                    ptr = ptr + 2
                                    // label: POST_ASSERTION
(nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        (top_nest.flags = 2)

                                60 =>
                                    if (if (if ((ptrend as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator = 62)
                                        comptime_error("goto not supported")

                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    // label: POST_LOOKBEHIND
(unsafe: *has_lookbehind = 1)
                                    // (empty)
                                    ptr = ptr + 2
                                    // label: POST_ASSERTION
(nest_depth = nest_depth + 1)
                                    if (if prev_expect_cond_assert > 0: 1 else: 0) != 0:
                                        (top_nest.nest_depth = nest_depth)
                                        (top_nest.flags = 2)

                                39 =>
                                    (terminator = 39)
                                    // label: DEFINE_NAME
if (not read_name(&ptr, ptrend, utf, terminator, &offset, &name, &namelen, &errorcode, cb)) != 0:
                                        comptime_error("goto not supported")

                                    if (if cb.bracount >= 65535: 1 else: 0) != 0:
                                        (errorcode = ERR97)
                                        comptime_error("goto not supported")

                                    (cb.bracount = cb.bracount + 1)
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2148007936 | cb.bracount))
                                    (nest_depth = nest_depth + 1)
                                    if (if cb.names_found >= 10000: 1 else: 0) != 0:
                                        (errorcode = ERR49)
                                        comptime_error("goto not supported")

                                    (is_dupname = 0)
                                    (hash = _pcre2_compile_get_hash_from_name8(name, namelen))
                                    (ng = cb.named_groups)
                                    if (if i < cb.names_found: 1 else: 0) != 0:
                                        break

                                    if (if cb.names_found >= cb.named_group_list_size: 1 else: 0) != 0:
                                        var newsize: c_uint = 0 // init: untranslatable
                                        var newspace: *mut named_group_8 = null // init: untranslatable
                                        if (if newspace == null: 1 else: 0) != 0:
                                            (errorcode = ERR21)
                                            comptime_error("goto not supported")

                                        with_memcpy(newspace as *i8, cb.named_groups as *i8, (cb.named_group_list_size *% sizeof[named_group_8]()) as i64)
                                        if (if cb.named_group_list_size > 20: 1 else: 0) != 0:
                                            cb.cx.memctl.free((cb.named_groups as *mut c_void), cb.cx.memctl.memory_data)

                                        (cb.named_groups = newspace)
                                        (cb.named_group_list_size = newsize)

                                    if is_dupname != 0:
                                        hash = hash | 32768

                                    (cb.named_groups[cb.names_found].name = name)
                                    (cb.named_groups[cb.names_found].number = cb.bracount)
                                    (cb.named_groups[cb.names_found].hash_dup = hash)
                                    (cb.names_found = cb.names_found + 1)
                                91 =>
                                    (class_mode_state = 2)
                                    (c = unsafe: *(ptr = ptr + 1))
                                    comptime_error("goto not supported")

                        124 =>
                            if (if (if (if top_nest != null: 1 else: 0) != 0 and (if top_nest.nest_depth == nest_depth: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((top_nest.flags & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (cb.bracount = top_nest.reset_group)

                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2147549184)
                        41 =>
                            (okquantifier = 1)
                            if (if (if top_nest != null: 1 else: 0) != 0 and (if top_nest.nest_depth == nest_depth: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if (if ((top_nest.flags & 1)) != 0: 1 else: 0) != 0 and (if top_nest.max_group > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (cb.bracount = top_nest.max_group)

                                if (if ((top_nest.flags & 2)) != 0: 1 else: 0) != 0:
                                    (okquantifier = 0)

                                if (if ((top_nest.flags & 4)) != 0: 1 else: 0) != 0:
                                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149384192)


                            if (if nest_depth == 0: 1 else: 0) != 0:
                                (errorcode = ERR22)
                                comptime_error("goto not supported")

                            (nest_depth = nest_depth - 1)
                            (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149384192)


                if (if inverbname != 0 and (if ptr >= ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                    (errorcode = ERR60)
                    __pc = 19
            continue

                __pc = 17
                continue
            17 =>  // PARSED_END
                (parsed_pattern = manage_callouts(ptr, &previous_callout, auto_callout, parsed_pattern, cb))
                if (if ((xoptions & 8)) != 0: 1 else: 0) != 0:
                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149384192)
                    (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149187584)
                else:
                    if (if ((xoptions & 4)) != 0: 1 else: 0) != 0:
                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = 2149384192)
                        (unsafe: *(parsed_pattern = parsed_pattern + 1) = (2149318656 +% 5))


                if (if parsed_pattern >= parsed_pattern_end: 1 else: 0) != 0:
                    (errorcode = ERR63)
                    __pc = 19
            continue

                (unsafe: *parsed_pattern = 2147483648)
                if (if nest_depth == 0: 1 else: 0) != 0:
                    return 0

                __pc = 18
                continue
            18 =>  // UNCLOSED_PARENTHESIS
                (errorcode = ERR14)
                __pc = 19
                continue
            19 =>  // FAILED
                return errorcode
                __pc = 20
                continue
            20 =>  // FAILED_BACK
                (ptr = ptr - 1)
                __pc = 19
                continue
                __pc = 21
                continue
            21 =>  // FAILED_FORWARD
                (ptr = ptr + 1)
                __pc = 19
                continue
            _ => break

fn first_significant_code(code: *const u8, skipassert: c_int) -> *const u8:
    var code = code
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
    while true:
        match __pc
            0 =>
                bravalue = 0
                okreturn = (0 - 1)
                group_return = 0
                (greedy_default = ((if ((options & 262144)) != 0: 1 else: 0)))
                (greedy_non_default = (greedy_default ^ 1))
                (firstcu = (reqcu = (zerofirstcu = (zeroreqcu = 0))))
                (firstcuflags = (reqcuflags = (zerofirstcuflags = (zeroreqcuflags = 4294967295))))
                (req_caseopt = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: 1 else: 0))
                while (pptr = pptr + 1) != null:
                    var possessive_quantifier: c_int = 0 // init: untranslatable
                    var note_group_empty: c_int = 0 // init: untranslatable
                    var mclength: c_uint = 0 // init: untranslatable
                    var skipunits: c_uint = 0 // init: untranslatable
                    var subreqcu: c_uint = 0 // init: untranslatable
                    var subfirstcu: c_uint = 0 // init: untranslatable
                    var groupnumber: c_uint = 0 // init: untranslatable
                    var verbarglen: c_uint = 0 // init: untranslatable
                    var verbculen: c_uint = 0 // init: untranslatable
                    var subreqcuflags: c_uint = 0 // init: untranslatable
                    var subfirstcuflags: c_uint = 0 // init: untranslatable
                    var oc: *mut open_capitem = null // init: untranslatable
                    var mcbuffer = 0 // init: untranslatable ([8]u8)
                    if (if lengthptr != null: 1 else: 0) != 0:
                        if (if code >= (cb.start_workspace + cb.workspace_size): 1 else: 0) != 0:
                            (unsafe: *errorcodeptr = ERR52)
                            (cb.erroroffset = 0)
                            return 0

                        if (if code > ((cb.start_workspace + cb.workspace_size) - ((100) as isize as usize)): 1 else: 0) != 0:
                            (unsafe: *errorcodeptr = ERR86)
                            (cb.erroroffset = 0)
                            return 0

                        if (if code < last_code: 1 else: 0) != 0:
                            (code = last_code)

                        if (if (if meta < 2151153664: 1 else: 0) != 0 or (if meta > 2151874560: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if unsafe: *lengthptr > 65536: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR20)
                                (cb.erroroffset = 0)
                                return 0

                            (code = orig_code)

                        (last_code = code)

                    if (if (if meta < 2151153664: 1 else: 0) != 0 or (if meta > 2151874560: 1 else: 0) != 0: 1 else: 0) != 0:
                        (previous = code)
                        if (if matched_char != 0 and (not had_accept) != 0: 1 else: 0) != 0:
                            (okreturn = 1)


                    (previous_matched_char = matched_char)
                    (matched_char = 0)
                    (note_group_empty = 0)
                    (skipunits = 0)
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
                                    (zerofirstcuflags = (firstcuflags = 4294967294))

                                (unsafe: *(code = code + 1) = 28)
                            else:
                                (unsafe: *(code = code + 1) = 27)

                        2149187584 =>
                            (unsafe: *(code = code + 1) = (if ((if ((options & 1024)) != 0: 1 else: 0)) != 0: OP_DOLLM else: OP_DOLL))
                        2149253120 =>
                            (matched_char = 1)
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = 4294967294)

                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            (unsafe: *(code = code + 1) = (if ((if ((options & 32)) != 0: 1 else: 0)) != 0: OP_ALLANY else: OP_ANY))
                        2148204544 =>
                            if (if meta == 2148270080: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 13)
                            else:
                                (unsafe: *(code = code + 1) = 110)
                                with_memset(code as *i8, 0, 32 as i64)
                                code = code + (32 / sizeof[u8]())

                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = 4294967294)

                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                        2148401152 =>
                            if (if ((unsafe: *pptr & 1)) != 0: 1 else: 0) != 0:
                                if (not _pcre2_compile_class_nested_8(options, xoptions, &pptr, &code, errorcodeptr, cb, lengthptr)) != 0:
                                    return 0

                                comptime_error("goto not supported")

                            if (if (if pptr[1] < 2147483648: 1 else: 0) != 0 and (if pptr[2] == 2148335616: 1 else: 0) != 0: 1 else: 0) != 0:
                                var c: c_uint = 0 // init: untranslatable
                                pptr = pptr + 2
                                if (if meta == 2148139008: 1 else: 0) != 0:
                                    (meta = c)
                                    comptime_error("goto not supported")

                                (zeroreqcu = reqcu)
                                (zeroreqcuflags = reqcuflags)
                                if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags = 4294967294)

                                (zerofirstcu = firstcu)
                                (zerofirstcuflags = firstcuflags)
                                (unsafe: *(code = code + 1) = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_NOTI else: OP_NOT))
                                break

                            if (if (if (if (if meta == 2148139008: 1 else: 0) != 0 and (if pptr[1] < 2147483648: 1 else: 0) != 0: 1 else: 0) != 0 and (if pptr[2] < 2147483648: 1 else: 0) != 0: 1 else: 0) != 0 and (if pptr[3] == 2148335616: 1 else: 0) != 0: 1 else: 0) != 0:
                                var c: c_uint = 0 // init: untranslatable
                                                                var d: c_uint = 0 // init: untranslatable
                                                                (d = ((cb.fcc)[c]))

                                if (if (if c != d: 1 else: 0) != 0 and (if pptr[2] == d: 1 else: 0) != 0: 1 else: 0) != 0:
                                    pptr = pptr + 3
                                    (meta = c)
                                    if (if ((options & 8)) == 0: 1 else: 0) != 0:
                                        (reset_caseful = 1)
                                        options = options | 8
                                        (req_caseopt = 1)

                                    comptime_error("goto not supported")



                            (pptr = _pcre2_compile_class_not_nested_8(options, xoptions, (pptr + (1 as isize as usize)), &code, (if meta == 2148401152: 1 else: 0), null, errorcodeptr, cb, lengthptr))
                            if (if pptr == null: 1 else: 0) != 0:
                                return 0

                            // label: CLASS_END_PROCESSING
if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = 4294967294)

                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                        2150498304 =>
                            (cb.had_accept = (had_accept = 1))
                            (oc = open_caps)
                            while (if (if oc != null: 1 else: 0) != 0 and (if oc.assert_depth >= cb.assert_depth: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if lengthptr != null: 1 else: 0) != 0:
                                    unsafe: *lengthptr = unsafe: *lengthptr + 3
                                else:
                                    (unsafe: *(code = code + 1) = 168)

                                (oc = oc.next)

                            (unsafe: *(code = code + 1) = (if ((if cb.assert_depth > 0: 1 else: 0)) != 0: OP_ASSERT_ACCEPT else: OP_ACCEPT))
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = 4294967294)

                        2150760448 => 0
                        2150629376 => 0
                        2151022592 =>
                            cb.external_flags = cb.external_flags | 4096
                            (unsafe: *(code = code + 1) = 161)
                        2151088128 =>
                            cb.external_flags = cb.external_flags | 4096
                            comptime_error("goto not supported")
                            (verbarglen = unsafe: *((pptr = pptr + 1)))
                            (verbculen = 0)
                            (tempcode = (code = code + 1))
                            var i: c_int = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = unsafe: *((pptr = pptr + 1)))
                                                                (mclength = 1)
                                (mcbuffer[0] = meta)

                                if (if lengthptr != null: 1 else: 0) != 0:
                                    unsafe: *lengthptr = unsafe: *lengthptr + mclength
                                else:
                                    code = code + mclength
                                    verbculen = verbculen + mclength

                                (i = i + 1)

                            (unsafe: *tempcode = verbculen)
                            (unsafe: *(code = code + 1) = 0)
                        2150825984 =>
                            (verbarglen = unsafe: *((pptr = pptr + 1)))
                            (verbculen = 0)
                            (tempcode = (code = code + 1))
                            var i: c_int = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = unsafe: *((pptr = pptr + 1)))
                                                                (mclength = 1)
                                (mcbuffer[0] = meta)

                                if (if lengthptr != null: 1 else: 0) != 0:
                                    unsafe: *lengthptr = unsafe: *lengthptr + mclength
                                else:
                                    code = code + mclength
                                    verbculen = verbculen + mclength

                                (i = i + 1)

                            (unsafe: *tempcode = verbculen)
                            (unsafe: *(code = code + 1) = 0)
                        2150432768 =>
                            (verbarglen = unsafe: *((pptr = pptr + 1)))
                            (verbculen = 0)
                            (tempcode = (code = code + 1))
                            var i: c_int = 0
                            while (if i < (verbarglen as c_int): 1 else: 0) != 0:
                                (meta = unsafe: *((pptr = pptr + 1)))
                                                                (mclength = 1)
                                (mcbuffer[0] = meta)

                                if (if lengthptr != null: 1 else: 0) != 0:
                                    unsafe: *lengthptr = unsafe: *lengthptr + mclength
                                else:
                                    code = code + mclength
                                    verbculen = verbculen + mclength

                                (i = i + 1)

                            (unsafe: *tempcode = verbculen)
                            (unsafe: *(code = code + 1) = 0)
                        2149515264 =>
                            (unsafe: *optionsptr = (options = unsafe: *((pptr = pptr + 1))))
                            (unsafe: *xoptionsptr = (xoptions = unsafe: *((pptr = pptr + 1))))
                            (greedy_default = ((if ((options & 262144)) != 0: 1 else: 0)))
                            (greedy_non_default = (greedy_default ^ 1))
                            (req_caseopt = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: 1 else: 0))
                        2148925440 =>
                            if (if lengthptr != null: 1 else: 0) != 0:
                                (pptr = _pcre2_compile_parse_scan_substr_args8(pptr, errorcodeptr, cb, lengthptr))
                                if (if pptr == null: 1 else: 0) != 0:
                                    return 0

                                break

                            while 1 != 0:
                                var count: c_int = 0
                                var index: c_int = 0
                                var ng: *mut named_group_8 = null // init: untranslatable
                                break

                            (pptr = pptr - 1)
                        2148990976 =>
                            (bravalue = OP_ASSERT_SCS)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if lengthptr != null: 1 else: 0) != 0:
                                var i: c_uint = 0 // init: untranslatable
                                var name: *const u8 = null // init: untranslatable
                                var ng: *mut named_group_8 = null // init: untranslatable
                                var start_pptr: *mut c_uint = null // init: untranslatable
                                var length: c_uint = 0 // init: untranslatable
                                                                pptr = pptr + 2

                                // (empty)
                                (name = (cb.start_pattern + offset))
                                (ng = _pcre2_compile_find_named_group8(name, length, cb))
                                if (if ng == null: 1 else: 0) != 0:
                                    (groupnumber = 0)
                                    if (if meta == 2148794368: 1 else: 0) != 0:
                                        (i = 1)
                                        while (if i < length: 1 else: 0) != 0:
                                            (groupnumber = ((groupnumber *% 10) +% ((name[i] - 48))))
                                            if (if groupnumber > 65535: 1 else: 0) != 0:
                                                (unsafe: *errorcodeptr = ERR61)
                                                (cb.erroroffset = (offset +% i))
                                                return 0

                                            (i = i + 1)


                                    if (if (if meta != 2148794368: 1 else: 0) != 0 or (if groupnumber > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *errorcodeptr = ERR15)
                                        (cb.erroroffset = offset)
                                        return 0

                                    if (if groupnumber == 0: 1 else: 0) != 0:
                                        (groupnumber = 65535)

                                    (start_pptr[1] = groupnumber)
                                    (skipunits = 3)
                                    comptime_error("goto not supported")

                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (meta = 2148597760)

                                if (if ((ng.hash_dup & 32768)) == 0: 1 else: 0) != 0:
                                    if (if ng.number > cb.top_backref: 1 else: 0) != 0:
                                        (cb.top_backref = ng.number)

                                    (start_pptr[0] = meta)
                                    (start_pptr[1] = ng.number)
                                    (skipunits = 3)
                                    comptime_error("goto not supported")

                                (start_pptr[0] = (meta | 1))
                                (skipunits = 5)
                            else:
                                var count: c_int = 0
                                var index: c_int = 0
                                var ng: *mut named_group_8 = null // init: untranslatable
                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (code[(1 + 2)] = 149)
                                    (skipunits = 3)
                                    pptr = pptr + (1 + 2)
                                    comptime_error("goto not supported")

                                if (if meta_arg == 0: 1 else: 0) != 0:
                                    (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_RREF else: OP_CREF))
                                    (skipunits = 3)
                                    pptr = pptr + (1 + 2)
                                    comptime_error("goto not supported")

                                (ng = (cb.named_groups + pptr[1]))
                                (count = 0)
                                (index = 0)
                                if (not _pcre2_compile_find_dupname_details8(ng.name, ng.length, &index, &count, errorcodeptr, cb)) != 0:
                                    return 0

                                (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_DNRREF else: OP_DNCREF))
                                (skipunits = 5)
                                pptr = pptr + (1 + 2)

                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                                                        pptr = pptr + 2

                            // (empty)
                            (code[(1 + 2)] = 170)
                            (skipunits = 1)
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                                                        pptr = pptr + 2

                            // (empty)
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
                                (cb.erroroffset = offset)
                                return 0

                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)

                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))

                            (skipunits = 1)
                            pptr = pptr + 3
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2148794368 =>
                            if (if lengthptr != null: 1 else: 0) != 0:
                                var i: c_uint = 0 // init: untranslatable
                                var name: *const u8 = null // init: untranslatable
                                var ng: *mut named_group_8 = null // init: untranslatable
                                var start_pptr: *mut c_uint = null // init: untranslatable
                                var length: c_uint = 0 // init: untranslatable
                                                                pptr = pptr + 2

                                // (empty)
                                (name = (cb.start_pattern + offset))
                                (ng = _pcre2_compile_find_named_group8(name, length, cb))
                                if (if ng == null: 1 else: 0) != 0:
                                    (groupnumber = 0)
                                    if (if meta == 2148794368: 1 else: 0) != 0:
                                        (i = 1)
                                        while (if i < length: 1 else: 0) != 0:
                                            (groupnumber = ((groupnumber *% 10) +% ((name[i] - 48))))
                                            if (if groupnumber > 65535: 1 else: 0) != 0:
                                                (unsafe: *errorcodeptr = ERR61)
                                                (cb.erroroffset = (offset +% i))
                                                return 0

                                            (i = i + 1)


                                    if (if (if meta != 2148794368: 1 else: 0) != 0 or (if groupnumber > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *errorcodeptr = ERR15)
                                        (cb.erroroffset = offset)
                                        return 0

                                    if (if groupnumber == 0: 1 else: 0) != 0:
                                        (groupnumber = 65535)

                                    (start_pptr[1] = groupnumber)
                                    (skipunits = 3)
                                    comptime_error("goto not supported")

                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (meta = 2148597760)

                                if (if ((ng.hash_dup & 32768)) == 0: 1 else: 0) != 0:
                                    if (if ng.number > cb.top_backref: 1 else: 0) != 0:
                                        (cb.top_backref = ng.number)

                                    (start_pptr[0] = meta)
                                    (start_pptr[1] = ng.number)
                                    (skipunits = 3)
                                    comptime_error("goto not supported")

                                (start_pptr[0] = (meta | 1))
                                (skipunits = 5)
                            else:
                                var count: c_int = 0
                                var index: c_int = 0
                                var ng: *mut named_group_8 = null // init: untranslatable
                                if (if meta == 2148794368: 1 else: 0) != 0:
                                    (code[(1 + 2)] = 149)
                                    (skipunits = 3)
                                    pptr = pptr + (1 + 2)
                                    comptime_error("goto not supported")

                                if (if meta_arg == 0: 1 else: 0) != 0:
                                    (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_RREF else: OP_CREF))
                                    (skipunits = 3)
                                    pptr = pptr + (1 + 2)
                                    comptime_error("goto not supported")

                                (ng = (cb.named_groups + pptr[1]))
                                (count = 0)
                                (index = 0)
                                if (not _pcre2_compile_find_dupname_details8(ng.name, ng.length, &index, &count, errorcodeptr, cb)) != 0:
                                    return 0

                                (code[(1 + 2)] = (if ((if meta == 2148728832: 1 else: 0)) != 0: OP_DNRREF else: OP_DNCREF))
                                (skipunits = 5)
                                pptr = pptr + (1 + 2)

                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                                                        pptr = pptr + 2

                            // (empty)
                            (code[(1 + 2)] = 170)
                            (skipunits = 1)
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                                                        pptr = pptr + 2

                            // (empty)
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
                                (cb.erroroffset = offset)
                                return 0

                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)

                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))

                            (skipunits = 1)
                            pptr = pptr + 3
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2148532224 =>
                            (bravalue = OP_COND)
                                                        pptr = pptr + 2

                            // (empty)
                            (code[(1 + 2)] = 170)
                            (skipunits = 1)
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                                                        pptr = pptr + 2

                            // (empty)
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
                                (cb.erroroffset = offset)
                                return 0

                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)

                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))

                            (skipunits = 1)
                            pptr = pptr + 3
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2148663296 =>
                            (bravalue = OP_COND)
                                                        pptr = pptr + 2

                            // (empty)
                            (groupnumber = unsafe: *((pptr = pptr + 1)))
                            if (if groupnumber > cb.bracount: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR15)
                                (cb.erroroffset = offset)
                                return 0

                            if (if groupnumber > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber)

                            offset = offset - 2
                            (code[(1 + 2)] = 147)
                            (skipunits = 3)
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))

                            (skipunits = 1)
                            pptr = pptr + 3
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2148859904 =>
                            (bravalue = OP_COND)
                            if (if pptr[1] > 0: 1 else: 0) != 0:
                                (code[(1 + 2)] = (if ((if ((if 10 > pptr[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 >= pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code[(1 + 2)] = (if ((if (if 10 == pptr[2]: 1 else: 0) != 0 and (if 48 == pptr[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))

                            (skipunits = 1)
                            pptr = pptr + 3
                            comptime_error("goto not supported")
                            (bravalue = OP_COND)
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2148466688 =>
                            (bravalue = OP_COND)
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2150039552 =>
                            (bravalue = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2150301696 =>
                            (bravalue = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2150105088 =>
                            if (if (if pptr[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr[2] < 2151153664: 1 else: 0) != 0 or (if pptr[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = 165)
                                (pptr = pptr + 1)
                            else:
                                (bravalue = OP_ASSERT_NOT)
                                cb.assert_depth = cb.assert_depth + 1
                                comptime_error("goto not supported")

                        2150170624 =>
                            (bravalue = OP_ASSERTBACK)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERTBACK_NOT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ONCE)
                            comptime_error("goto not supported")
                            (bravalue = OP_SCRIPT_RUN)
                            comptime_error("goto not supported")
                            (bravalue = OP_BRA)
                            // label: GROUP_PROCESS_NOTE_EMPTY
(note_group_empty = 1)
                            // label: GROUP_PROCESS
cb.parens_depth = cb.parens_depth + 1
                            (unsafe: *code = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, &tempcode, &pptr, errorcodeptr, skipunits, &subfirstcu, &subfirstcuflags, &subreqcu, &subreqcuflags, bcptr, open_caps, cb, (if ((if lengthptr == null: 1 else: 0)) != 0: null else: &length_prevgroup)))) == 0: 1 else: 0) != 0:
                                return 0

                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1

                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == null: 1 else: 0) != 0: 1 else: 0) != 0:
                                var tc: *mut u8 = null // init: untranslatable
                                var condcount: c_int = 0
                                while true:
                                    (condcount = condcount + 1)
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break

                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR54)
                                        return 0

                                    (code[(2 + 1)] = 151)
                                    (bravalue = OP_DEFINE)
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR27)
                                        return 0

                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subfirstcuflags = (subreqcuflags = 4294967294))
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)




                            if (if lengthptr != null: 1 else: 0) != 0:
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    return 0

                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
                                (code = code + 1)
                                (unsafe: *(code = code + 1) = 122)
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
                                        (firstcuflags = subfirstcuflags)
                                        (groupsetfirstcu = 1)
                                    else:
                                        (firstcuflags = 4294967294)

                                    (zerofirstcuflags = 4294967294)
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))


                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)

                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)


                        2150236160 =>
                            (bravalue = OP_ASSERTBACK_NOT)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ONCE)
                            comptime_error("goto not supported")
                            (bravalue = OP_SCRIPT_RUN)
                            comptime_error("goto not supported")
                            (bravalue = OP_BRA)
                            // label: GROUP_PROCESS_NOTE_EMPTY
(note_group_empty = 1)
                            // label: GROUP_PROCESS
cb.parens_depth = cb.parens_depth + 1
                            (unsafe: *code = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, &tempcode, &pptr, errorcodeptr, skipunits, &subfirstcu, &subfirstcuflags, &subreqcu, &subreqcuflags, bcptr, open_caps, cb, (if ((if lengthptr == null: 1 else: 0)) != 0: null else: &length_prevgroup)))) == 0: 1 else: 0) != 0:
                                return 0

                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1

                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == null: 1 else: 0) != 0: 1 else: 0) != 0:
                                var tc: *mut u8 = null // init: untranslatable
                                var condcount: c_int = 0
                                while true:
                                    (condcount = condcount + 1)
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break

                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR54)
                                        return 0

                                    (code[(2 + 1)] = 151)
                                    (bravalue = OP_DEFINE)
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR27)
                                        return 0

                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subfirstcuflags = (subreqcuflags = 4294967294))
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)




                            if (if lengthptr != null: 1 else: 0) != 0:
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    return 0

                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
                                (code = code + 1)
                                (unsafe: *(code = code + 1) = 122)
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
                                        (firstcuflags = subfirstcuflags)
                                        (groupsetfirstcu = 1)
                                    else:
                                        (firstcuflags = 4294967294)

                                    (zerofirstcuflags = 4294967294)
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))


                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)

                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)


                        2150367232 =>
                            (bravalue = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            comptime_error("goto not supported")
                            (bravalue = OP_ONCE)
                            comptime_error("goto not supported")
                            (bravalue = OP_SCRIPT_RUN)
                            comptime_error("goto not supported")
                            (bravalue = OP_BRA)
                            // label: GROUP_PROCESS_NOTE_EMPTY
(note_group_empty = 1)
                            // label: GROUP_PROCESS
cb.parens_depth = cb.parens_depth + 1
                            (unsafe: *code = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, &tempcode, &pptr, errorcodeptr, skipunits, &subfirstcu, &subfirstcuflags, &subreqcu, &subreqcuflags, bcptr, open_caps, cb, (if ((if lengthptr == null: 1 else: 0)) != 0: null else: &length_prevgroup)))) == 0: 1 else: 0) != 0:
                                return 0

                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1

                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == null: 1 else: 0) != 0: 1 else: 0) != 0:
                                var tc: *mut u8 = null // init: untranslatable
                                var condcount: c_int = 0
                                while true:
                                    (condcount = condcount + 1)
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break

                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR54)
                                        return 0

                                    (code[(2 + 1)] = 151)
                                    (bravalue = OP_DEFINE)
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR27)
                                        return 0

                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subfirstcuflags = (subreqcuflags = 4294967294))
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)




                            if (if lengthptr != null: 1 else: 0) != 0:
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    return 0

                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
                                (code = code + 1)
                                (unsafe: *(code = code + 1) = 122)
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
                                        (firstcuflags = subfirstcuflags)
                                        (groupsetfirstcu = 1)
                                    else:
                                        (firstcuflags = 4294967294)

                                    (zerofirstcuflags = 4294967294)
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))


                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)

                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)


                        2147614720 =>
                            (bravalue = OP_ONCE)
                            comptime_error("goto not supported")
                            (bravalue = OP_SCRIPT_RUN)
                            comptime_error("goto not supported")
                            (bravalue = OP_BRA)
                            // label: GROUP_PROCESS_NOTE_EMPTY
(note_group_empty = 1)
                            // label: GROUP_PROCESS
cb.parens_depth = cb.parens_depth + 1
                            (unsafe: *code = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, &tempcode, &pptr, errorcodeptr, skipunits, &subfirstcu, &subfirstcuflags, &subreqcu, &subreqcuflags, bcptr, open_caps, cb, (if ((if lengthptr == null: 1 else: 0)) != 0: null else: &length_prevgroup)))) == 0: 1 else: 0) != 0:
                                return 0

                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1

                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == null: 1 else: 0) != 0: 1 else: 0) != 0:
                                var tc: *mut u8 = null // init: untranslatable
                                var condcount: c_int = 0
                                while true:
                                    (condcount = condcount + 1)
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break

                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR54)
                                        return 0

                                    (code[(2 + 1)] = 151)
                                    (bravalue = OP_DEFINE)
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR27)
                                        return 0

                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subfirstcuflags = (subreqcuflags = 4294967294))
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)




                            if (if lengthptr != null: 1 else: 0) != 0:
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    return 0

                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
                                (code = code + 1)
                                (unsafe: *(code = code + 1) = 122)
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
                                        (firstcuflags = subfirstcuflags)
                                        (groupsetfirstcu = 1)
                                    else:
                                        (firstcuflags = 4294967294)

                                    (zerofirstcuflags = 4294967294)
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))


                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)

                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)


                        2149974016 =>
                            (bravalue = OP_SCRIPT_RUN)
                            comptime_error("goto not supported")
                            (bravalue = OP_BRA)
                            // label: GROUP_PROCESS_NOTE_EMPTY
(note_group_empty = 1)
                            // label: GROUP_PROCESS
cb.parens_depth = cb.parens_depth + 1
                            (unsafe: *code = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, &tempcode, &pptr, errorcodeptr, skipunits, &subfirstcu, &subfirstcuflags, &subreqcu, &subreqcuflags, bcptr, open_caps, cb, (if ((if lengthptr == null: 1 else: 0)) != 0: null else: &length_prevgroup)))) == 0: 1 else: 0) != 0:
                                return 0

                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1

                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == null: 1 else: 0) != 0: 1 else: 0) != 0:
                                var tc: *mut u8 = null // init: untranslatable
                                var condcount: c_int = 0
                                while true:
                                    (condcount = condcount + 1)
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break

                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR54)
                                        return 0

                                    (code[(2 + 1)] = 151)
                                    (bravalue = OP_DEFINE)
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR27)
                                        return 0

                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subfirstcuflags = (subreqcuflags = 4294967294))
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)




                            if (if lengthptr != null: 1 else: 0) != 0:
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    return 0

                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
                                (code = code + 1)
                                (unsafe: *(code = code + 1) = 122)
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
                                        (firstcuflags = subfirstcuflags)
                                        (groupsetfirstcu = 1)
                                    else:
                                        (firstcuflags = 4294967294)

                                    (zerofirstcuflags = 4294967294)
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))


                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)

                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)


                        2149449728 =>
                            (bravalue = OP_BRA)
                            // label: GROUP_PROCESS_NOTE_EMPTY
(note_group_empty = 1)
                            // label: GROUP_PROCESS
cb.parens_depth = cb.parens_depth + 1
                            (unsafe: *code = bravalue)
                            (pptr = pptr + 1)
                            (tempcode = code)
                            (tempreqvary = cb.req_varyopt)
                            (length_prevgroup = 0)
                            if (if ((group_return = compile_regex(options, xoptions, &tempcode, &pptr, errorcodeptr, skipunits, &subfirstcu, &subfirstcuflags, &subreqcu, &subreqcuflags, bcptr, open_caps, cb, (if ((if lengthptr == null: 1 else: 0)) != 0: null else: &length_prevgroup)))) == 0: 1 else: 0) != 0:
                                return 0

                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty != 0 and (if bravalue != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            if (if (if bravalue >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1

                            if (if (if bravalue == OP_COND: 1 else: 0) != 0 and (if lengthptr == null: 1 else: 0) != 0: 1 else: 0) != 0:
                                var tc: *mut u8 = null // init: untranslatable
                                var condcount: c_int = 0
                                while true:
                                    (condcount = condcount + 1)
                                    if not ((if unsafe: *tc != OP_KET: 1 else: 0) != 0):
                                        break

                                if (if code[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR54)
                                        return 0

                                    (code[(2 + 1)] = 151)
                                    (bravalue = OP_DEFINE)
                                else:
                                    if (if condcount > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset)
                                        (unsafe: *errorcodeptr = ERR27)
                                        return 0

                                    if (if condcount == 1: 1 else: 0) != 0:
                                        (subfirstcuflags = (subreqcuflags = 4294967294))
                                    else:
                                        if (if group_return > 0: 1 else: 0) != 0:
                                            (matched_char = 1)




                            if (if lengthptr != null: 1 else: 0) != 0:
                                if (if (2147483627 -% unsafe: *lengthptr) < ((length_prevgroup -% 2) -% 4): 1 else: 0) != 0:
                                    (unsafe: *errorcodeptr = ERR20)
                                    return 0

                                unsafe: *lengthptr = unsafe: *lengthptr + ((length_prevgroup -% 2) -% 4)
                                (code = code + 1)
                                (unsafe: *(code = code + 1) = 122)
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
                                        (firstcuflags = subfirstcuflags)
                                        (groupsetfirstcu = 1)
                                    else:
                                        (firstcuflags = 4294967294)

                                    (zerofirstcuflags = 4294967294)
                                else:
                                    if (if (if subfirstcuflags < 4294967294: 1 else: 0) != 0 and (if subreqcuflags >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu = subfirstcu)
                                        (subreqcuflags = (subfirstcuflags | tempreqvary))


                                if (if subreqcuflags < 4294967294: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)

                            else:
                                if (if (if ((if (if bravalue == OP_ASSERT: 1 else: 0) != 0 or (if bravalue == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = subreqcu)
                                    (reqcuflags = subreqcuflags)


                        2147745792 => 0
                        2147876864 =>
                            (code[0] = 119)
                            (code[(1 + (2 * 2))] = pptr[3])
                            pptr = pptr + 3
                            code = code + _pcre2_OP_lengths_8[OP_CALLOUT]
                        2147942400 =>
                            if (if lengthptr != null: 1 else: 0) != 0:
                                unsafe: *lengthptr = unsafe: *lengthptr + (pptr[3] +% 9)
                                pptr = pptr + 3
                                pptr = pptr + 2
                            else:
                                var pp: *const u8 = null // init: untranslatable
                                var delimiter: c_uint = 0 // init: untranslatable
                                var length: c_uint = 0 // init: untranslatable
                                var callout_string: *mut u8 = null // init: untranslatable
                                (code[0] = 120)
                                pptr = pptr + 3
                                                                pptr = pptr + 2

                                // (empty)
                                (pp = (cb.start_pattern + offset))
                                (delimiter = (unsafe: *(callout_string = callout_string + 1) = unsafe: *(pp = pp + 1)))
                                if (if delimiter == 123: 1 else: 0) != 0:
                                    (delimiter = 125)

                                while (if (length = length - 1) > 1: 1 else: 0) != 0:
                                    if (if (if unsafe: *pp == delimiter: 1 else: 0) != 0 and (if pp[1] == delimiter: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *(callout_string = callout_string + 1) = delimiter)
                                        pp = pp + 2
                                        (length = length - 1)
                                    else:
                                        (unsafe: *(callout_string = callout_string + 1) = unsafe: *(pp = pp + 1))


                                (unsafe: *(callout_string = callout_string + 1) = 0)
                                (code = callout_string)

                        2151809024 =>
                            (repeat_max = unsafe: *((pptr = pptr + 1)))
                            comptime_error("goto not supported")
                            comptime_error("goto not supported")
                            comptime_error("goto not supported")
                            (repeat_max = 1)
                            // label: REPEAT
if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                (firstcuflags = zerofirstcuflags)
                                (reqcu = zeroreqcu)
                                (reqcuflags = zeroreqcuflags)

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
                                    (op_type = chartypeoffset[(op_previous - OP_CHAR)])
                                                                        (mcbuffer[0] = code[(0 - 1)])
                                    (mclength = 1)
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = mcbuffer[0])
                                        (reqcuflags = cb.req_varyopt)
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1



                                    comptime_error("goto not supported")
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (not possessive_quantifier) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                                                        var length: c_ulong = 0 // init: untranslatable
                                    (op_previous = (unsafe: *previous = 137))
                                    (previous[(3 +% length)] = 122)

                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = (0 - 1))
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *errorcodeptr = ERR10)
                                        return 0

                                                                        var prop_type: c_int = 0
                                    var prop_value: c_int = 0
                                    var oldcode: *mut u8 = null // init: untranslatable
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (op_type = 52)
                                    (mclength = 0)
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        (prop_value = previous[2])
                                    else:
                                        // label: OUTPUT_SINGLE_REPEAT
(prop_type = (prop_value = (0 - 1)))

                                    (oldcode = code)
                                    (code = previous)
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    repeat_type = repeat_type + op_type
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                    else:
                                        (unsafe: *(code = code + 1) = op_previous)
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *(code = code + 1) = prop_type)
                                            (unsafe: *(code = code + 1) = prop_value)




                            if possessive_quantifier != 0:
                                var len: c_int = 0
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0

                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if len > 0: 1 else: 0) != 0:
                                    var repcode: c_uint = unsafe: *tempcode
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if opcode_possessify[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = opcode_possessify[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        len = len + (1 + 2)
                                        (tempcode[0] = 135)
                                        (unsafe: *(code = code + 1) = 122)



                            // label: END_REPEAT
cb.req_varyopt = cb.req_varyopt | reqvary
                        2151153664 =>
                            comptime_error("goto not supported")
                            comptime_error("goto not supported")
                            (repeat_max = 1)
                            // label: REPEAT
if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                (firstcuflags = zerofirstcuflags)
                                (reqcu = zeroreqcu)
                                (reqcuflags = zeroreqcuflags)

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
                                    (op_type = chartypeoffset[(op_previous - OP_CHAR)])
                                                                        (mcbuffer[0] = code[(0 - 1)])
                                    (mclength = 1)
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = mcbuffer[0])
                                        (reqcuflags = cb.req_varyopt)
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1



                                    comptime_error("goto not supported")
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (not possessive_quantifier) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                                                        var length: c_ulong = 0 // init: untranslatable
                                    (op_previous = (unsafe: *previous = 137))
                                    (previous[(3 +% length)] = 122)

                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = (0 - 1))
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *errorcodeptr = ERR10)
                                        return 0

                                                                        var prop_type: c_int = 0
                                    var prop_value: c_int = 0
                                    var oldcode: *mut u8 = null // init: untranslatable
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (op_type = 52)
                                    (mclength = 0)
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        (prop_value = previous[2])
                                    else:
                                        // label: OUTPUT_SINGLE_REPEAT
(prop_type = (prop_value = (0 - 1)))

                                    (oldcode = code)
                                    (code = previous)
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    repeat_type = repeat_type + op_type
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                    else:
                                        (unsafe: *(code = code + 1) = op_previous)
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *(code = code + 1) = prop_type)
                                            (unsafe: *(code = code + 1) = prop_value)




                            if possessive_quantifier != 0:
                                var len: c_int = 0
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0

                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if len > 0: 1 else: 0) != 0:
                                    var repcode: c_uint = unsafe: *tempcode
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if opcode_possessify[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = opcode_possessify[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        len = len + (1 + 2)
                                        (tempcode[0] = 135)
                                        (unsafe: *(code = code + 1) = 122)



                            // label: END_REPEAT
cb.req_varyopt = cb.req_varyopt | reqvary
                        2151350272 =>
                            comptime_error("goto not supported")
                            (repeat_max = 1)
                            // label: REPEAT
if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                (firstcuflags = zerofirstcuflags)
                                (reqcu = zeroreqcu)
                                (reqcuflags = zeroreqcuflags)

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
                                    (op_type = chartypeoffset[(op_previous - OP_CHAR)])
                                                                        (mcbuffer[0] = code[(0 - 1)])
                                    (mclength = 1)
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = mcbuffer[0])
                                        (reqcuflags = cb.req_varyopt)
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1



                                    comptime_error("goto not supported")
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (not possessive_quantifier) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                                                        var length: c_ulong = 0 // init: untranslatable
                                    (op_previous = (unsafe: *previous = 137))
                                    (previous[(3 +% length)] = 122)

                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = (0 - 1))
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *errorcodeptr = ERR10)
                                        return 0

                                                                        var prop_type: c_int = 0
                                    var prop_value: c_int = 0
                                    var oldcode: *mut u8 = null // init: untranslatable
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (op_type = 52)
                                    (mclength = 0)
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        (prop_value = previous[2])
                                    else:
                                        // label: OUTPUT_SINGLE_REPEAT
(prop_type = (prop_value = (0 - 1)))

                                    (oldcode = code)
                                    (code = previous)
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    repeat_type = repeat_type + op_type
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                    else:
                                        (unsafe: *(code = code + 1) = op_previous)
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *(code = code + 1) = prop_type)
                                            (unsafe: *(code = code + 1) = prop_value)




                            if possessive_quantifier != 0:
                                var len: c_int = 0
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0

                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if len > 0: 1 else: 0) != 0:
                                    var repcode: c_uint = unsafe: *tempcode
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if opcode_possessify[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = opcode_possessify[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        len = len + (1 + 2)
                                        (tempcode[0] = 135)
                                        (unsafe: *(code = code + 1) = 122)



                            // label: END_REPEAT
cb.req_varyopt = cb.req_varyopt | reqvary
                        2151546880 =>
                            (repeat_max = 1)
                            // label: REPEAT
if (if previous_matched_char != 0 and (if repeat_min > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)

                            (reqvary = (if ((if repeat_min == repeat_max: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min == 0: 1 else: 0) != 0:
                                (firstcu = zerofirstcu)
                                (firstcuflags = zerofirstcuflags)
                                (reqcu = zeroreqcu)
                                (reqcuflags = zeroreqcuflags)

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
                                    (op_type = chartypeoffset[(op_previous - OP_CHAR)])
                                                                        (mcbuffer[0] = code[(0 - 1)])
                                    (mclength = 1)
                                    if (if (if op_previous <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu = mcbuffer[0])
                                        (reqcuflags = cb.req_varyopt)
                                        if (if op_previous == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags = reqcuflags | 1



                                    comptime_error("goto not supported")
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_CLASS =>
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                OP_RECURSE =>
                                    if (if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (not possessive_quantifier) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                                                        var length: c_ulong = 0 // init: untranslatable
                                    (op_previous = (unsafe: *previous = 137))
                                    (previous[(3 +% length)] = 122)

                                    code = code + (2 + (2 * 2))
                                    length_prevgroup = length_prevgroup + 6
                                    (group_return = (0 - 1))
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous >= OP_EODN: 1 else: 0) != 0 or (if op_previous <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *errorcodeptr = ERR10)
                                        return 0

                                                                        var prop_type: c_int = 0
                                    var prop_value: c_int = 0
                                    var oldcode: *mut u8 = null // init: untranslatable
                                    if (if (if repeat_max == 1: 1 else: 0) != 0 and (if repeat_min == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    (op_type = 52)
                                    (mclength = 0)
                                    if (if (if op_previous == OP_PROP: 1 else: 0) != 0 or (if op_previous == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type = previous[1])
                                        (prop_value = previous[2])
                                    else:
                                        // label: OUTPUT_SINGLE_REPEAT
(prop_type = (prop_value = (0 - 1)))

                                    (oldcode = code)
                                    (code = previous)
                                    if (if repeat_max == 0: 1 else: 0) != 0:
                                        comptime_error("goto not supported")

                                    repeat_type = repeat_type + op_type
                                    if (if mclength > 0: 1 else: 0) != 0:
                                        code = code + mclength
                                    else:
                                        (unsafe: *(code = code + 1) = op_previous)
                                        if (if prop_type >= 0: 1 else: 0) != 0:
                                            (unsafe: *(code = code + 1) = prop_type)
                                            (unsafe: *(code = code + 1) = prop_value)




                            if possessive_quantifier != 0:
                                var len: c_int = 0
                                match unsafe: *tempcode
                                    OP_TYPEEXACT =>
                                        tempcode = tempcode + (_pcre2_OP_lengths_8[unsafe: *tempcode] + ((if ((if (if tempcode[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0

                                (len = ((((code as usize -% tempcode as usize) / sizeof[u8]())) as c_int))
                                if (if len > 0: 1 else: 0) != 0:
                                    var repcode: c_uint = unsafe: *tempcode
                                    if (if (if repcode < 119: 1 else: 0) != 0 and (if opcode_possessify[repcode] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *tempcode = opcode_possessify[repcode])
                                    else:
                                        code = code + (1 + 2)
                                        len = len + (1 + 2)
                                        (tempcode[0] = 135)
                                        (unsafe: *(code = code + 1) = 122)



                            // label: END_REPEAT
cb.req_varyopt = cb.req_varyopt | reqvary
                        2147811328 =>
                            (pptr = pptr + 1)
                            comptime_error("goto not supported")
                            if (if meta_arg < 10: 1 else: 0) != 0:
                                (offset = cb.small_ref_offset[meta_arg])
                            else:
                                pptr = pptr + 2

                            // (empty)
                            if (if meta_arg > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset)
                                (unsafe: *errorcodeptr = ERR15)
                                return 0

                            // label: HANDLE_SINGLE_REFERENCE
if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (zerofirstcuflags = (firstcuflags = 4294967294))

                            (unsafe: *(code = code + 1) = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_REFI else: OP_REF))
                            if (if ((options & 8)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = (((if ((if ((xoptions & 128)) != 0: 1 else: 0)) != 0: 1 else: 0)) | ((if ((if ((xoptions & 65536)) != 0: 1 else: 0)) != 0: 2 else: 0))))

                            cb.backref_map = cb.backref_map | (if ((if meta_arg < 32: 1 else: 0)) != 0: ((1 << meta_arg)) else: 1)
                            if (if meta_arg > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = meta_arg)

                        2147680256 =>
                            if (if meta_arg < 10: 1 else: 0) != 0:
                                (offset = cb.small_ref_offset[meta_arg])
                            else:
                                pptr = pptr + 2

                            // (empty)
                            if (if meta_arg > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset)
                                (unsafe: *errorcodeptr = ERR15)
                                return 0

                            // label: HANDLE_SINGLE_REFERENCE
if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (zerofirstcuflags = (firstcuflags = 4294967294))

                            (unsafe: *(code = code + 1) = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_REFI else: OP_REF))
                            if (if ((options & 8)) != 0: 1 else: 0) != 0:
                                (unsafe: *(code = code + 1) = (((if ((if ((xoptions & 128)) != 0: 1 else: 0)) != 0: 1 else: 0)) | ((if ((if ((xoptions & 65536)) != 0: 1 else: 0)) != 0: 2 else: 0))))

                            cb.backref_map = cb.backref_map | (if ((if meta_arg < 32: 1 else: 0)) != 0: ((1 << meta_arg)) else: 1)
                            if (if meta_arg > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = meta_arg)

                        2149842944 =>
                                                        pptr = pptr + 2

                            // (empty)
                            if (if meta_arg > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset)
                                (unsafe: *errorcodeptr = ERR15)
                                return 0

                            // label: HANDLE_NUMERICAL_RECURSION
(unsafe: *code = 118)
                            code = code + (1 + 2)
                            (length_prevgroup = 3)
                            (groupsetfirstcu = 0)
                            (cb.had_recurse = 1)
                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (firstcuflags = 4294967294)

                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                        2148007936 =>
                            (bravalue = OP_CBRA)
                            (skipunits = 2)
                            (cb.lastcapture = meta_arg)
                            comptime_error("goto not supported")
                            if (if (if meta_arg > 5: 1 else: 0) != 0 and (if meta_arg < 23: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                                if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags = 4294967294)


                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            if (if (if (if cb.assert_depth > 0: 1 else: 0) != 0 and (if meta_arg == 3: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((xoptions & 64)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR99)
                                return 0

                            match meta_arg
                                14 =>
                                    cb.external_flags = cb.external_flags | 4194304
                                    if (not utf) != 0:
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

                            (unsafe: *(code = code + 1) = meta_arg)
                        2149318656 =>
                            if (if (if meta_arg > 5: 1 else: 0) != 0 and (if meta_arg < 23: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char = 1)
                                if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags = 4294967294)


                            (zerofirstcu = firstcu)
                            (zerofirstcuflags = firstcuflags)
                            (zeroreqcu = reqcu)
                            (zeroreqcuflags = reqcuflags)
                            if (if (if (if cb.assert_depth > 0: 1 else: 0) != 0 and (if meta_arg == 3: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((xoptions & 64)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR99)
                                return 0

                            match meta_arg
                                14 =>
                                    cb.external_flags = cb.external_flags | 4194304
                                    if (not utf) != 0:
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

                            (unsafe: *(code = code + 1) = meta_arg)
                        _ =>
                            if (if meta >= 2147483648: 1 else: 0) != 0:
                                (unsafe: *errorcodeptr = ERR89)
                                return 0

                            // label: NORMAL_CHAR
(meta = unsafe: *pptr)
                            // label: NORMAL_CHAR_SET
(matched_char = 1)
                            // label: CLASS_CASELESS_CHAR
                            (mclength = 1)
                            (mcbuffer[0] = meta)

                            (unsafe: *(code = code + 1) = (if ((if ((options & 8)) != 0: 1 else: 0)) != 0: OP_CHARI else: OP_CHAR))
                            code = code + mclength
                            if (if (if mcbuffer[0] == 13: 1 else: 0) != 0 or (if mcbuffer[0] == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.external_flags = cb.external_flags | 2048

                            if (if firstcuflags == 4294967295: 1 else: 0) != 0:
                                (zerofirstcuflags = 4294967294)
                                (zeroreqcu = reqcu)
                                (zeroreqcuflags = reqcuflags)
                                if (if (if mclength == 1: 1 else: 0) != 0 or (if req_caseopt == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (firstcu = mcbuffer[0])
                                    (firstcuflags = req_caseopt)
                                    if (if mclength != 1: 1 else: 0) != 0:
                                        (reqcu = code[(0 - 1)])
                                        (reqcuflags = cb.req_varyopt)

                                else:
                                    (firstcuflags = (reqcuflags = 4294967294))

                            else:
                                (zerofirstcu = firstcu)
                                (zerofirstcuflags = firstcuflags)
                                (zeroreqcu = reqcu)
                                (zeroreqcuflags = reqcuflags)
                                if (if (if mclength == 1: 1 else: 0) != 0 or (if req_caseopt == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu = code[(0 - 1)])
                                    (reqcuflags = (req_caseopt | cb.req_varyopt))


                            if reset_caseful != 0:
                                options = options & (0 - 8 - 1)
                                (req_caseopt = 0)
                                (reset_caseful = 0)



                return 0
            _ => break

fn is_anchored(code: *const u8, bracket_map: c_uint, cb: *mut compile_block_8, atomcount: c_int, inassert: c_int, dotstar_anchor: c_int) -> c_int:
    var code = code
    while true:
        var scode: *const u8 = null // init: untranslatable
        var op: c_int = unsafe: *scode
        if (if (if (if (if op == OP_BRA: 1 else: 0) != 0 or (if op == OP_BRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
            if (not is_anchored(scode, bracket_map, cb, atomcount, inassert, dotstar_anchor)) != 0:
                return 0

        else:
            if (if (if (if (if op == OP_CBRA: 1 else: 0) != 0 or (if op == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                var n: c_int = 0 // init: untranslatable
                var new_map: c_uint = 0 // init: untranslatable
                if (not is_anchored(scode, new_map, cb, atomcount, inassert, dotstar_anchor)) != 0:
                    return 0

            else:
                if (if (if op == OP_ASSERT: 1 else: 0) != 0 or (if op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (not is_anchored(scode, bracket_map, cb, atomcount, 1, dotstar_anchor)) != 0:
                        return 0

                else:
                    if (if (if op == OP_COND: 1 else: 0) != 0 or (if op == OP_SCOND: 1 else: 0) != 0: 1 else: 0) != 0:
                        if (not is_anchored(scode, bracket_map, cb, atomcount, inassert, dotstar_anchor)) != 0:
                            return 0

                    else:
                        if (if op == OP_ONCE: 1 else: 0) != 0:
                            if (not is_anchored(scode, bracket_map, cb, (atomcount + 1), inassert, dotstar_anchor)) != 0:
                                return 0

                        else:
                            if ((if (if (if op == OP_TYPESTAR: 1 else: 0) != 0 or (if op == OP_TYPEMINSTAR: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_TYPEPOSSTAR: 1 else: 0) != 0: 1 else: 0)) != 0:
                                if (if (if (if (if (if (if scode[1] != OP_ALLANY: 1 else: 0) != 0 or (if ((bracket_map & cb.backref_map)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 or (if atomcount > 0: 1 else: 0) != 0: 1 else: 0) != 0 or cb.had_pruneorskip != 0: 1 else: 0) != 0 or inassert != 0: 1 else: 0) != 0 or (not dotstar_anchor) != 0: 1 else: 0) != 0:
                                    return 0

                            else:
                                if (if (if (if op != OP_SOD: 1 else: 0) != 0 and (if op != OP_SOM: 1 else: 0) != 0: 1 else: 0) != 0 and (if op != OP_CIRC: 1 else: 0) != 0: 1 else: 0) != 0:
                                    return 0







        if not ((if unsafe: *code == OP_ALT: 1 else: 0) != 0):
            break

    return 1

fn is_startline(code: *const u8, bracket_map: c_uint, cb: *mut compile_block_8, atomcount: c_int, inassert: c_int, dotstar_anchor: c_int) -> c_int:
    var code = code
    while true:
        var scode: *const u8 = null // init: untranslatable
        var op: c_int = unsafe: *scode
        if (if op == OP_COND: 1 else: 0) != 0:
            scode = scode + (1 + 2)
            if (if unsafe: *scode == OP_CALLOUT: 1 else: 0) != 0:
                scode = scode + _pcre2_OP_lengths_8[OP_CALLOUT]

            match unsafe: *scode
                OP_CREF =>
                    if (not is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor)) != 0:
                        return 0

                    scode = scode + (1 + 2)
                _ =>
                    if (not is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor)) != 0:
                        return 0

                    scode = scode + (1 + 2)

            (scode = first_significant_code(scode, 0))
            (op = unsafe: *scode)

        if (if (if (if (if op == OP_BRA: 1 else: 0) != 0 or (if op == OP_BRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
            if (not is_startline(scode, bracket_map, cb, atomcount, inassert, dotstar_anchor)) != 0:
                return 0

        else:
            if (if (if (if (if op == OP_CBRA: 1 else: 0) != 0 or (if op == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0:
                var n: c_int = 0 // init: untranslatable
                var new_map: c_uint = (bracket_map | ((if ((if n < 32: 1 else: 0)) != 0: ((1 << n)) else: 1)))
                if (not is_startline(scode, new_map, cb, atomcount, inassert, dotstar_anchor)) != 0:
                    return 0

            else:
                if (if (if op == OP_ASSERT: 1 else: 0) != 0 or (if op == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (not is_startline(scode, bracket_map, cb, atomcount, 1, dotstar_anchor)) != 0:
                        return 0

                else:
                    if (if op == OP_ONCE: 1 else: 0) != 0:
                        if (not is_startline(scode, bracket_map, cb, (atomcount + 1), inassert, dotstar_anchor)) != 0:
                            return 0

                    else:
                        if (if (if (if op == OP_TYPESTAR: 1 else: 0) != 0 or (if op == OP_TYPEMINSTAR: 1 else: 0) != 0: 1 else: 0) != 0 or (if op == OP_TYPEPOSSTAR: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (if (if (if (if (if scode[1] != OP_ANY: 1 else: 0) != 0 or (if ((bracket_map & cb.backref_map)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 or (if atomcount > 0: 1 else: 0) != 0: 1 else: 0) != 0 or cb.had_pruneorskip != 0: 1 else: 0) != 0 or inassert != 0: 1 else: 0) != 0 or (not dotstar_anchor) != 0: 1 else: 0) != 0:
                                return 0

                        else:
                            if (if (if op != OP_CIRC: 1 else: 0) != 0 and (if op != OP_CIRCM: 1 else: 0) != 0: 1 else: 0) != 0:
                                return 0






        if not ((if unsafe: *code == OP_ALT: 1 else: 0) != 0):
            break

    return 1

fn find_recurse(code: *mut u8, utf: c_int) -> *mut u8:
    var code = code
    while true:
        var c: u8 = 0 // init: untranslatable
        if (if c == OP_END: 1 else: 0) != 0:
            return null

        if (if c == OP_RECURSE: 1 else: 0) != 0:
            return code



fn find_firstassertedcu(code: *const u8, flags: *mut c_uint, inassert: c_uint) -> c_uint:
    var code = code
    var c: c_uint = 0 // init: untranslatable
    var cflags: c_uint = 0 // init: untranslatable
    (unsafe: *flags = 4294967294)
    while true:
        var d: c_uint = 0 // init: untranslatable
        var dflags: c_uint = 0 // init: untranslatable
        var xl: c_int = (if ((if (if (if (if unsafe: *code == OP_CBRA: 1 else: 0) != 0 or (if unsafe: *code == OP_SCBRA: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_CBRAPOS: 1 else: 0) != 0: 1 else: 0) != 0 or (if unsafe: *code == OP_SCBRAPOS: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)
        var scode: *const u8 = null // init: untranslatable
        var op: u8 = 0 // init: untranslatable
        match op
            _ =>
                return 0
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



        if not ((if unsafe: *code == OP_ALT: 1 else: 0) != 0):
            break

    (unsafe: *flags = cflags)
    return c

fn parsed_skip(pptr: *mut c_uint, skiptype: c_uint) -> *mut c_uint:
    var pptr = pptr
    var nestlevel: c_uint = 0 // init: untranslatable
    while (pptr = pptr + 1) != null:
        var meta: c_uint = 0 // init: untranslatable
        match meta
            _ =>
                if (if meta < 2147483648: 1 else: 0) != 0:
                    continue

            2147483648 =>
                return null
            2147680256 => 0
            2149318656 =>
                if (if (if (unsafe: *pptr -% 2149318656) == 15: 1 else: 0) != 0 or (if (unsafe: *pptr -% 2149318656) == 16: 1 else: 0) != 0: 1 else: 0) != 0:
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

        (meta = (((meta >> 16)) & 32767))
        if (if meta >= sizeof[[73]u8](): 1 else: 0) != 0:
            return null

        pptr = pptr + meta_extra_lengths[meta]


fn get_grouplength(pptrptr: *mut *mut c_uint, minptr: *mut c_int, isinline: c_int, errcodeptr: *mut c_int, lcptr: *mut c_int, group: c_int, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8) -> c_int:
    var gi: *mut c_uint = null
    var branchlength: c_int = 0
    var branchminlength: c_int = 0
    var grouplength: c_int = 0
    var groupminlength: c_int = 0
    var groupinfo: c_uint = 0
    var __pc: i32 = 0
    while true:
        match __pc
            0 =>
                grouplength = (0 - 1)
                groupminlength = 2147483647
                if (if (if group > 0: 1 else: 0) != 0 and (if ((cb.external_flags & 2097152)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    var groupinfo: c_uint = 0 // init failed
                    if (if ((groupinfo & 1073741824)) != 0: 1 else: 0) != 0:
                        return (0 - 1)

                    if (if ((groupinfo & 2147483648)) != 0: 1 else: 0) != 0:
                        if isinline != 0:
                            (unsafe: *pptrptr = parsed_skip(unsafe: *pptrptr, 2))

                        (unsafe: *minptr = gi[1])
                        return (groupinfo & 65535)


                while true:
                    (branchlength = get_branchlength(pptrptr, &branchminlength, errcodeptr, lcptr, recurses, cb))
                    if (if branchlength < 0: 1 else: 0) != 0:
                        comptime_error("goto not supported")

                    if (if branchlength > grouplength: 1 else: 0) != 0:
                        (grouplength = branchlength)

                    if (if branchminlength < groupminlength: 1 else: 0) != 0:
                        (groupminlength = branchminlength)

                    if (if unsafe: *unsafe: *pptrptr == 2149384192: 1 else: 0) != 0:
                        break

                    unsafe: *pptrptr = unsafe: *pptrptr + 1

                if (if group > 0: 1 else: 0) != 0:
                    (gi[1] = groupminlength)

                (unsafe: *minptr = groupminlength)
                return grouplength
                __pc = 1
                continue
            1 =>  // ISNOTFIXED
                if (if group > 0: 1 else: 0) != 0:
                    gi[0] = gi[0] | 1073741824

                return (0 - 1)
            _ => break

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
