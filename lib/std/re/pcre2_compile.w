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
    var utf__goto_10299_6: c_int = 0
    var ucp__goto_10300_6: c_int = 0
    var has_lookbehind__goto_10301_6: c_int = 0
    var zero_terminated__goto_10302_6: c_int = 0
    var re__goto_10303_18: *mut pcre2_real_code_8 = null
    var cb__goto_10304_15: compile_block_8
    var tables__goto_10305_16: *const u8 = null
    var null_str__goto_10307_13: [1]u8 = [0 as u8; 1]
    var code__goto_10308_14: *mut u8 = null
    var codestart__goto_10309_14: *mut u8 = null
    var ptr__goto_10310_12: *const u8 = null
    var pptr__goto_10311_11: *mut c_uint = null
    var length__goto_10313_12: c_ulong = 0
    var usedlength__goto_10314_12: c_ulong = 0
    var re_blocksize__goto_10315_12: c_ulong = 0
    var parsed_size_needed__goto_10316_12: c_ulong = 0
    var firstcuflags__goto_10318_10: c_uint = 0
    var reqcuflags__goto_10318_24: c_uint = 0
    var firstcu__goto_10319_10: c_uint = 0
    var reqcu__goto_10319_19: c_uint = 0
    var setflags__goto_10320_10: c_uint = 0
    var xoptions__goto_10321_10: c_uint = 0
    var skipatstart__goto_10323_10: c_uint = 0
    var limit_heap__goto_10324_10: c_uint = 0
    var limit_match__goto_10325_10: c_uint = 0
    var limit_depth__goto_10326_10: c_uint = 0
    var newline__goto_10328_5: c_int = 0
    var bsr__goto_10329_5: c_int = 0
    var errorcode__goto_10330_5: c_int = 0
    var regexrc__goto_10331_5: c_int = 0
    var i__goto_10333_10: c_uint = 0
    var optim_flags__goto_10336_10: c_uint = 0
    var stack_groupinfo__goto_10341_10: [256]c_uint = [0 as c_uint; 256]
    var stack_parsed_pattern__goto_10342_10: [1024]c_uint = [0 as c_uint; 1024]
    var named_groups__goto_10343_13: [20]named_group_8
    var c16workspace__goto_10348_10: [3000]c_uint = [0 as c_uint; 3000]
    var cworkspace__goto_10349_14: *mut u8 = null
    var p__goto_10521_18: *const pso = null
    var c__goto_10526_18: c_uint = 0
    var pp__goto_10526_21: c_uint = 0
    var heap_parsed_pattern__goto_10764_13: *mut c_uint = null
    var loopcount__goto_10792_7: c_int = 0
    var ng__goto_10967_16: *mut named_group_8 = null
    var tablecount__goto_10968_12: c_uint = 0
    var rcode__goto_11030_16: *mut u8 = null
    var rgroup__goto_11031_14: *const u8 = null
    var ccount__goto_11032_16: c_uint = 0
    var start__goto_11033_7: c_int = 0
    var rc__goto_11034_17: [8]recurse_cache
    var p__goto_11040_9: c_int = 0
    var groupnumber__goto_11040_12: c_int = 0
    var search_from__goto_11045_18: *const u8 = null
    var temp__goto_11102_16: *mut u8 = null
    var possessify_rc__goto_11103_7: c_int = 0
    var dotstar_anchor__goto_11126_8: c_int = 0
    var minminlength__goto_11140_7: c_int = 0
    var study_rc__goto_11141_7: c_int = 0
    var assertedcuflags__goto_11148_14: c_uint = 0
    var assertedcu__goto_11149_14: c_uint = 0
    var dotstar_anchor__goto_11204_10: c_int = 0
    var current_data__goto_11347_17: *mut compile_data = null
    var next_data__goto_11350_19: *mut compile_data = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                has_lookbehind__goto_10301_6 = 0
                re__goto_10303_18 = (null as *mut pcre2_real_code_8)
                length__goto_10313_12 = 1
                setflags__goto_10320_10 = 0
                limit_heap__goto_10324_10 = 4294967295
                limit_match__goto_10325_10 = 4294967295
                limit_depth__goto_10326_10 = 4294967295
                newline__goto_10328_5 = 0
                bsr__goto_10329_5 = 0
                errorcode__goto_10330_5 = 0
                optim_flags__goto_10336_10 = (if (if ccontext != (null as *mut pcre2_real_compile_context_8): 1 else: 0) != 0: ccontext.optimization_flags else: 7)
                cworkspace__goto_10349_14 = ((&c16workspace__goto_10348_10[0] as *mut c_uint) as *mut u8)
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
                        (pattern = ((&null_str__goto_10307_13[0] as *mut u8) as *const u8))
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
                if (if ccontext == (null as *mut pcre2_real_compile_context_8): 1 else: 0) != 0:
                    (ccontext = (((&mut _pcre2_default_compile_context_8 as *mut pcre2_real_compile_context_8)) as *mut pcre2_real_compile_context_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 67108864)) != 0: 1 else: 0) != 0:
                    options = options | 524288
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (zero_terminated__goto_10302_6 = ((if patlen == ((0 -% 1)): 1 else: 0)))
                if zero_terminated__goto_10302_6 != 0:
                    (patlen = _pcre2_strlen_8(pattern))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                zero_terminated__goto_10302_6
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
                    optim_flags__goto_10336_10 = optim_flags__goto_10336_10 & (0 - 1 - 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 32768)) != 0: 1 else: 0) != 0:
                    optim_flags__goto_10336_10 = optim_flags__goto_10336_10 & (0 - 2 - 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 65536)) != 0: 1 else: 0) != 0:
                    optim_flags__goto_10336_10 = optim_flags__goto_10336_10 & (0 - 4 - 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                eprint(f"[compile] tables check: ccontext.tables={ccontext.tables as i64}")
                (tables__goto_10305_16 = (if ((if ccontext.tables != (null as *const u8): 1 else: 0)) != 0: ccontext.tables else: _pcre2_default_tables_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.lcc = (tables__goto_10305_16 + (0 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.fcc = (tables__goto_10305_16 + (256 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.cbits = (tables__goto_10305_16 + (512 as isize as usize)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.assert_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.bracount = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.cx = ccontext)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.dupnames = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.end_pattern = (pattern + patlen))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.erroroffset = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.external_flags = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.external_options = options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.groupinfo = (&stack_groupinfo__goto_10341_10[0] as *mut c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.had_recurse = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.lastcapture = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.max_lookbehind = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.max_varlookbehind = ccontext.max_varlookbehind)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.name_entry_size = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.name_table = (null as *mut u8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.named_groups = (&named_groups__goto_10343_13[0] as *mut named_group_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.named_group_list_size = 20)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.names_found = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.parens_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.parsed_pattern = (&stack_parsed_pattern__goto_10342_10[0] as *mut c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.req_varyopt = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.start_code = cworkspace__goto_10349_14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.start_pattern = pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                eprint("[compile] CHECKPOINT 300")
                (cb__goto_10304_15.start_workspace = cworkspace__goto_10349_14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.workspace_size = 6000)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.first_data = (null as *mut compile_data))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.last_data = (null as *mut compile_data))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.top_backref = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.backref_map = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (i__goto_10333_10 = 0)
                while (if i__goto_10333_10 < 10: 1 else: 0) != 0:
                    ((&cb__goto_10304_15.small_ref_offset[0] as *mut c_ulong)[i__goto_10333_10] = ((0 -% 1)))
                    (i__goto_10333_10 = i__goto_10333_10 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (xoptions__goto_10321_10 = ccontext.extra_options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (ptr__goto_10310_12 = pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (skipatstart__goto_10323_10 = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 33554432)) == 0: 1 else: 0) != 0:
                    while (if (if (if (patlen -% skipatstart__goto_10323_10) >= 2: 1 else: 0) != 0 and (if ptr__goto_10310_12[skipatstart__goto_10323_10] == 40: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr__goto_10310_12[(skipatstart__goto_10323_10 +% 1)] == 42: 1 else: 0) != 0: 1 else: 0) != 0:
                        (i__goto_10333_10 = 0)
                        while (if i__goto_10333_10 < ((23 * sizeof[pso]()) / sizeof[pso]()): 1 else: 0) != 0:
                            p__goto_10521_18 = ((&pso_list[0] as *mut pso) + i__goto_10333_10)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if (if ((patlen -% skipatstart__goto_10323_10) -% 2) >= p__goto_10521_18.length: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(((ptr__goto_10310_12 + skipatstart__goto_10323_10) + (2 as isize as usize)), p__goto_10521_18.name, p__goto_10521_18.length) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                skipatstart__goto_10323_10 = skipatstart__goto_10323_10 + (p__goto_10521_18.length + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                match p__goto_10521_18.type_
                                    PSO_OPT =>
                                        cb__goto_10304_15.external_options = cb__goto_10304_15.external_options | p__goto_10521_18.value
                                    PSO_XOPT =>
                                        xoptions__goto_10321_10 = xoptions__goto_10321_10 | p__goto_10521_18.value
                                    PSO_FLG =>
                                        setflags__goto_10320_10 = setflags__goto_10320_10 | p__goto_10521_18.value
                                    PSO_NL =>
                                        (newline__goto_10328_5 = p__goto_10521_18.value)
                                        setflags__goto_10320_10 = setflags__goto_10320_10 | 32768
                                    PSO_BSR =>
                                        (bsr__goto_10329_5 = p__goto_10521_18.value)
                                        setflags__goto_10320_10 = setflags__goto_10320_10 | 16384
                                    PSO_LIMM =>
                                        (pp__goto_10526_21 = skipatstart__goto_10323_10)
                                        if (if (if (if pp__goto_10526_21 >= patlen: 1 else: 0) != 0 or (if pp__goto_10526_21 == skipatstart__goto_10323_10: 1 else: 0) != 0: 1 else: 0) != 0 or (if ptr__goto_10310_12[pp__goto_10526_21] != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (errorcode__goto_10330_5 = ERR60)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            ptr__goto_10310_12 = ptr__goto_10310_12 + pp__goto_10526_21
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (utf__goto_10299_6 = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 3
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if p__goto_10521_18.type_ == PSO_LIMH: 1 else: 0) != 0:
                                            (limit_heap__goto_10324_10 = c__goto_10526_18)
                                        else:
                                            if (if p__goto_10521_18.type_ == PSO_LIMM: 1 else: 0) != 0:
                                                (limit_match__goto_10325_10 = c__goto_10526_18)
                                            else:
                                                (limit_depth__goto_10326_10 = c__goto_10526_18)
                                        (pp__goto_10526_21 = pp__goto_10526_21 + 1)
                                        (skipatstart__goto_10323_10 = pp__goto_10526_21)
                                    PSO_OPTMZ =>
                                        optim_flags__goto_10336_10 = optim_flags__goto_10336_10 & (0 - (p__goto_10521_18.value) - 1)
                                        match p__goto_10521_18.value
                                            1 =>
                                                cb__goto_10304_15.external_options = cb__goto_10304_15.external_options | 16384
                                            2 =>
                                                cb__goto_10304_15.external_options = cb__goto_10304_15.external_options | 32768
                                            4 =>
                                                cb__goto_10304_15.external_options = cb__goto_10304_15.external_options | 65536
                                            _ => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                eprint("[compile] CHECKPOINT 400")
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (i__goto_10333_10 = i__goto_10333_10 + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if i__goto_10333_10 >= ((23 * sizeof[pso]()) / sizeof[pso]()): 1 else: 0) != 0:
                            break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ptr__goto_10310_12 = ptr__goto_10310_12 + skipatstart__goto_10323_10
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((cb__goto_10304_15.external_options & ((524288 | 131072)))) != 0: 1 else: 0) != 0:
                    (errorcode__goto_10330_5 = ERR32)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 3
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (utf__goto_10299_6 = (if ((cb__goto_10304_15.external_options & 524288)) != 0: 1 else: 0))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if utf__goto_10299_6 != 0:
                    if (if ((options & 4096)) != 0: 1 else: 0) != 0:
                        (errorcode__goto_10330_5 = ERR74)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 3
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (if ((options & 1073741824)) == 0: 1 else: 0) != 0 and (if ((errorcode__goto_10330_5 = _pcre2_valid_utf_8(pattern, patlen, erroroffset))) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                        __pc = 4
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (ucp__goto_10300_6 = (if ((cb__goto_10304_15.external_options & 131072)) != 0: 1 else: 0))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ucp__goto_10300_6 != 0 and (if ((cb__goto_10304_15.external_options & 2048)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (errorcode__goto_10330_5 = ERR75)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 3
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((xoptions__goto_10321_10 & 65536)) != 0: 1 else: 0) != 0:
                    if (if (if utf__goto_10299_6 != 0: 0 else: 1) != 0 and (if ucp__goto_10300_6 != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                        (errorcode__goto_10330_5 = ERR104)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 3
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if utf__goto_10299_6 != 0: 0 else: 1) != 0:
                        (errorcode__goto_10330_5 = ERR105)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 3
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if ((xoptions__goto_10321_10 & 128)) != 0: 1 else: 0) != 0:
                        (errorcode__goto_10330_5 = ERR106)
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
                if (if bsr__goto_10329_5 == 0: 1 else: 0) != 0:
                eprint("[compile] CHECKPOINT 500")
                    (bsr__goto_10329_5 = ccontext.bsr_convention)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if newline__goto_10328_5 == 0: 1 else: 0) != 0:
                    (newline__goto_10328_5 = ccontext.newline_convention)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.nltype = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                match newline__goto_10328_5
                    1 =>
                        (cb__goto_10304_15.nllen = 1)
                        ((&cb__goto_10304_15.nl[0] as *mut u8)[0] = 13)
                    2 =>
                        (cb__goto_10304_15.nllen = 1)
                        ((&cb__goto_10304_15.nl[0] as *mut u8)[0] = 10)
                    6 =>
                        (cb__goto_10304_15.nllen = 1)
                        ((&cb__goto_10304_15.nl[0] as *mut u8)[0] = 0)
                    3 =>
                        (cb__goto_10304_15.nllen = 2)
                        ((&cb__goto_10304_15.nl[0] as *mut u8)[0] = 13)
                        ((&cb__goto_10304_15.nl[0] as *mut u8)[1] = 10)
                    4 =>
                        (cb__goto_10304_15.nltype = 1)
                    5 =>
                        (cb__goto_10304_15.nltype = 2)
                    _ =>
                        (errorcode__goto_10330_5 = ERR56)
                        __pc = 3
                        __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (parsed_size_needed__goto_10316_12 = max_parsed_pattern(ptr__goto_10310_12, cb__goto_10304_15.end_pattern, utf__goto_10299_6, options))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((ccontext.extra_options & ((4 | 8)))) != 0: 1 else: 0) != 0:
                    parsed_size_needed__goto_10316_12 = parsed_size_needed__goto_10316_12 + 4
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 4)) != 0: 1 else: 0) != 0:
                    parsed_size_needed__goto_10316_12 = parsed_size_needed__goto_10316_12 + 4
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                parsed_size_needed__goto_10316_12 = parsed_size_needed__goto_10316_12 + 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if parsed_size_needed__goto_10316_12 > 1024: 1 else: 0) != 0:
                    heap_parsed_pattern__goto_10764_13 = (ccontext.memctl.malloc((parsed_size_needed__goto_10316_12 *% sizeof[c_uint]()), ccontext.memctl.memory_data) as *mut c_uint)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if heap_parsed_pattern__goto_10764_13 == (null as *mut c_uint): 1 else: 0) != 0:
                        ((unsafe: *errorptr) = ERR21)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 1
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb__goto_10304_15.parsed_pattern = heap_parsed_pattern__goto_10764_13)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.parsed_pattern_end = (cb__goto_10304_15.parsed_pattern + parsed_size_needed__goto_10316_12))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (errorcode__goto_10330_5 = parse_regex(ptr__goto_10310_12, cb__goto_10304_15.external_options, xoptions__goto_10321_10, (&mut has_lookbehind__goto_10301_6 as *mut c_int), (&mut cb__goto_10304_15 as *mut compile_block_8)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if errorcode__goto_10330_5 != 0: 1 else: 0) != 0:
                    __pc = 2
                    __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if has_lookbehind__goto_10301_6 != 0:
                    loopcount__goto_10792_7 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if cb__goto_10304_15.bracount >= 128: 1 else: 0) != 0:
                        (cb__goto_10304_15.groupinfo = (ccontext.memctl.malloc((((2 *% ((cb__goto_10304_15.bracount +% 1)))) *% sizeof[c_uint]()), ccontext.memctl.memory_data) as *mut c_uint))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if cb__goto_10304_15.groupinfo == (null as *mut c_uint): 1 else: 0) != 0:
                            (errorcode__goto_10330_5 = ERR21)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (cb__goto_10304_15.erroroffset = 0)
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
                    with_memset((cb__goto_10304_15.groupinfo as *mut c_void) as *i8, 0, ((((2 *% cb__goto_10304_15.bracount) +% 1)) *% sizeof[c_uint]()) as i64)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (errorcode__goto_10330_5 = check_lookbehinds(cb__goto_10304_15.parsed_pattern, (null as *mut *mut c_uint), (null as *mut parsed_recurse_check), (&mut cb__goto_10304_15 as *mut compile_block_8), (&mut loopcount__goto_10792_7 as *mut c_int)))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if errorcode__goto_10330_5 != 0: 1 else: 0) != 0:
                        __pc = 2
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.erroroffset = patlen)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (pptr__goto_10311_11 = cb__goto_10304_15.parsed_pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (code__goto_10308_14 = cworkspace__goto_10349_14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *code__goto_10308_14) = 137)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                compile_regex(cb__goto_10304_15.external_options, xoptions__goto_10321_10, (&mut code__goto_10308_14 as *mut *mut u8), (&mut pptr__goto_10311_11 as *mut *mut c_uint), (&mut errorcode__goto_10330_5 as *mut c_int), 0, (&mut firstcu__goto_10319_10 as *mut c_uint), (&mut firstcuflags__goto_10318_10 as *mut c_uint), (&mut reqcu__goto_10319_19 as *mut c_uint), (&mut reqcuflags__goto_10318_24 as *mut c_uint), (null as *mut branch_chain_8), (null as *mut open_capitem), (&mut cb__goto_10304_15 as *mut compile_block_8), (&mut length__goto_10313_12 as *mut c_ulong))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if errorcode__goto_10330_5 != 0: 1 else: 0) != 0:
                    __pc = 2
                    __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if length__goto_10313_12 > 65536: 1 else: 0) != 0:
                    (errorcode__goto_10330_5 = ERR20)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb__goto_10304_15.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if re_blocksize__goto_10315_12 > ccontext.max_pattern_compiled_length: 1 else: 0) != 0:
                    (errorcode__goto_10330_5 = ERR101)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb__goto_10304_15.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                re_blocksize__goto_10315_12 = re_blocksize__goto_10315_12 + sizeof[pcre2_real_code_8]()
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18 = (ccontext.memctl.malloc(re_blocksize__goto_10315_12, ccontext.memctl.memory_data) as *mut pcre2_real_code_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if re__goto_10303_18 == (null as *mut pcre2_real_code_8): 1 else: 0) != 0:
                    (errorcode__goto_10330_5 = ERR21)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb__goto_10304_15.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                with_memset(((((re__goto_10303_18 as *mut i8) + sizeof[pcre2_real_code_8]()) - (8 as isize as usize)) as *mut c_void) as *i8, 0, 8 as i64)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.memctl = ccontext.memctl)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.tables = tables__goto_10305_16)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.executable_jit = null)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                with_memset(((&re__goto_10303_18.start_bitmap[0] as *mut u8) as *mut c_void) as *i8, 0, (32 *% sizeof[u8]()) as i64)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.blocksize = re_blocksize__goto_10315_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.magic_number = 1346589253)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.compile_options = options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.overall_options = cb__goto_10304_15.external_options)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.extra_options = xoptions__goto_10321_10)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.flags = ((1 | cb__goto_10304_15.external_flags) | setflags__goto_10320_10))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.limit_heap = limit_heap__goto_10324_10)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.limit_match = limit_match__goto_10325_10)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.limit_depth = limit_depth__goto_10326_10)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.first_codeunit = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.last_codeunit = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.bsr_convention = bsr__goto_10329_5)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.newline_convention = newline__goto_10328_5)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.max_lookbehind = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.minlength = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.top_bracket = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.top_backref = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.name_entry_size = cb__goto_10304_15.name_entry_size)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.name_count = cb__goto_10304_15.names_found)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.optimization_flags = optim_flags__goto_10336_10)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (codestart__goto_10309_14 = ((((re__goto_10303_18 as *mut u8) + re__goto_10303_18.code_start)) as *mut u8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.parens_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.assert_depth = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.lastcapture = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.name_table = ((((re__goto_10303_18 as *mut u8) + sizeof[pcre2_real_code_8]())) as *mut u8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.start_code = codestart__goto_10309_14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.req_varyopt = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.had_accept = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (cb__goto_10304_15.had_pruneorskip = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb__goto_10304_15.names_found > 0: 1 else: 0) != 0:
                    ng__goto_10967_16 = cb__goto_10304_15.named_groups
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    tablecount__goto_10968_12 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (i__goto_10333_10 = 0)
                    while (if i__goto_10333_10 < cb__goto_10304_15.names_found: 1 else: 0) != 0:
                        if (if ng__goto_10967_16.length > 0: 1 else: 0) != 0:
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (pptr__goto_10311_11 = cb__goto_10304_15.parsed_pattern)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (code__goto_10308_14 = (codestart__goto_10309_14 as *mut u8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *code__goto_10308_14) = 137)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (regexrc__goto_10331_5 = compile_regex(re__goto_10303_18.overall_options, re__goto_10303_18.extra_options, (&mut code__goto_10308_14 as *mut *mut u8), (&mut pptr__goto_10311_11 as *mut *mut c_uint), (&mut errorcode__goto_10330_5 as *mut c_int), 0, (&mut firstcu__goto_10319_10 as *mut c_uint), (&mut firstcuflags__goto_10318_10 as *mut c_uint), (&mut reqcu__goto_10319_19 as *mut c_uint), (&mut reqcuflags__goto_10318_24 as *mut c_uint), (null as *mut branch_chain_8), (null as *mut open_capitem), (&mut cb__goto_10304_15 as *mut compile_block_8), (null as *mut c_ulong)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if regexrc__goto_10331_5 < 0: 1 else: 0) != 0:
                    re__goto_10303_18.flags = re__goto_10303_18.flags | 8192
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.top_bracket = cb__goto_10304_15.bracount)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.top_backref = cb__goto_10304_15.top_backref)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18.max_lookbehind = cb__goto_10304_15.max_lookbehind)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if cb__goto_10304_15.had_accept != 0:
                    (reqcu__goto_10319_19 = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (reqcuflags__goto_10318_24 = (4294967294 as c_uint))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    re__goto_10303_18.flags = re__goto_10303_18.flags | 8388608
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (unsafe: *code__goto_10308_14 = 0)
                (code__goto_10308_14 = code__goto_10308_14 + 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (usedlength__goto_10314_12 = ((code__goto_10308_14 as usize -% codestart__goto_10309_14 as usize) / sizeof[u8]()))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if usedlength__goto_10314_12 > length__goto_10313_12: 1 else: 0) != 0:
                    (errorcode__goto_10330_5 = ERR23)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (cb__goto_10304_15.erroroffset = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 2
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if errorcode__goto_10330_5 == 0: 1 else: 0) != 0 and cb__goto_10304_15.had_recurse != 0: 1 else: 0) != 0:
                    ccount__goto_11032_16 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    start__goto_11033_7 = 8
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (rcode__goto_11030_16 = find_recurse(codestart__goto_10309_14, utf__goto_10299_6))
                    while (if rcode__goto_11030_16 != (null as *mut u8): 1 else: 0) != 0:
                        if (if groupnumber__goto_11040_12 == 0: 1 else: 0) != 0:
                            (rgroup__goto_11031_14 = (codestart__goto_10309_14 as *const u8))
                        else:
                            search_from__goto_11045_18 = (codestart__goto_10309_14 as *const u8)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (rgroup__goto_11031_14 = (null as *const u8))
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            while (if i__goto_10333_10 < ccount__goto_11032_16: 1 else: 0) != 0:
                                if (if groupnumber__goto_11040_12 == (&rc__goto_11034_17[0] as *mut recurse_cache)[p__goto_11040_9].groupnumber: 1 else: 0) != 0:
                                    (rgroup__goto_11031_14 = (&rc__goto_11034_17[0] as *mut recurse_cache)[p__goto_11040_9].group)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if groupnumber__goto_11040_12 > (&rc__goto_11034_17[0] as *mut recurse_cache)[p__goto_11040_9].groupnumber: 1 else: 0) != 0:
                                    (search_from__goto_11045_18 = (&rc__goto_11034_17[0] as *mut recurse_cache)[p__goto_11040_9].group)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if rgroup__goto_11031_14 == (null as *const u8): 1 else: 0) != 0:
                                (rgroup__goto_11031_14 = _pcre2_find_bracket_8(search_from__goto_11045_18, utf__goto_10299_6, groupnumber__goto_11040_12))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if rgroup__goto_11031_14 == (null as *const u8): 1 else: 0) != 0:
                                    (errorcode__goto_10330_5 = ERR53)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (start__goto_11033_7 = start__goto_11033_7 - 1) < 0: 1 else: 0) != 0:
                                    (start__goto_11033_7 = (8 - 1))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&rc__goto_11034_17[0] as *mut recurse_cache)[start__goto_11033_7].groupnumber = groupnumber__goto_11040_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&rc__goto_11034_17[0] as *mut recurse_cache)[start__goto_11033_7].group = rgroup__goto_11031_14)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ccount__goto_11032_16 < 8: 1 else: 0) != 0:
                                    (ccount__goto_11032_16 = ccount__goto_11032_16 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (rcode__goto_11030_16 = find_recurse(((rcode__goto_11030_16 + (1 as isize as usize)) + (2 as isize as usize)), utf__goto_10299_6))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if errorcode__goto_10330_5 == 0: 1 else: 0) != 0 and (if ((optim_flags__goto_10336_10 & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    temp__goto_11102_16 = (codestart__goto_10309_14 as *mut u8)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if possessify_rc__goto_11103_7 != 0: 1 else: 0) != 0:
                        (errorcode__goto_10330_5 = ERR80)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (cb__goto_10304_15.erroroffset = 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if errorcode__goto_10330_5 != 0: 1 else: 0) != 0:
                    __pc = 2
                    __goto_pending = 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((re__goto_10303_18.overall_options & (2147483648 as c_uint))) == 0: 1 else: 0) != 0:
                    dotstar_anchor__goto_11126_8 = ((if ((optim_flags__goto_10336_10 & 2)) != 0: 1 else: 0))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if is_anchored((codestart__goto_10309_14 as *const u8), 0, (&mut cb__goto_10304_15 as *mut compile_block_8), 0, 0, dotstar_anchor__goto_11126_8) != 0:
                        re__goto_10303_18.overall_options = re__goto_10303_18.overall_options | 2147483648
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((optim_flags__goto_10336_10 & 4)) != 0: 1 else: 0) != 0:
                    minminlength__goto_11140_7 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if firstcuflags__goto_10318_10 >= 4294967294: 1 else: 0) != 0:
                        assertedcuflags__goto_11148_14 = 0
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        assertedcu__goto_11149_14 = find_firstassertedcu((codestart__goto_10309_14 as *const u8), (&mut assertedcuflags__goto_11148_14 as *mut c_uint), 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if (if assertedcuflags__goto_11148_14 < 4294967294: 1 else: 0) != 0 and (if assertedcu__goto_11149_14 != reqcu__goto_10319_19: 1 else: 0) != 0: 1 else: 0) != 0:
                            (firstcu__goto_10319_10 = assertedcu__goto_11149_14)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (firstcuflags__goto_10318_10 = assertedcuflags__goto_11148_14)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if firstcuflags__goto_10318_10 < 4294967294: 1 else: 0) != 0:
                        (re__goto_10303_18.first_codeunit = firstcu__goto_10319_10)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        re__goto_10303_18.flags = re__goto_10303_18.flags | 16
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (minminlength__goto_11140_7 = minminlength__goto_11140_7 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if ((firstcuflags__goto_10318_10 & 1)) != 0: 1 else: 0) != 0:
                            if (if (if firstcu__goto_10319_10 < 128: 1 else: 0) != 0 or ((if (if (if utf__goto_10299_6 != 0: 0 else: 1) != 0 and (if ucp__goto_10300_6 != 0: 0 else: 1) != 0: 1 else: 0) != 0 and (if firstcu__goto_10319_10 < 255: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                if (if cb__goto_10304_15.fcc[firstcu__goto_10319_10] != firstcu__goto_10319_10: 1 else: 0) != 0:
                                    re__goto_10303_18.flags = re__goto_10303_18.flags | 32
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    continue
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    else:
                        if (if ((re__goto_10303_18.overall_options & (2147483648 as c_uint))) == 0: 1 else: 0) != 0:
                            dotstar_anchor__goto_11204_10 = ((if ((optim_flags__goto_10336_10 & 2)) != 0: 1 else: 0))
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            if is_startline((codestart__goto_10309_14 as *const u8), 0, (&mut cb__goto_10304_15 as *mut compile_block_8), 0, 0, dotstar_anchor__goto_11204_10) != 0:
                                re__goto_10303_18.flags = re__goto_10303_18.flags | 512
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if reqcuflags__goto_10318_24 < 4294967294: 1 else: 0) != 0:
                        if (if (if ((re__goto_10303_18.overall_options & (2147483648 as c_uint))) == 0: 1 else: 0) != 0 or (if ((reqcuflags__goto_10318_24 & 2)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                            (re__goto_10303_18.last_codeunit = reqcu__goto_10319_19)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            re__goto_10303_18.flags = re__goto_10303_18.flags | 128
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            if (if ((reqcuflags__goto_10318_24 & 1)) != 0: 1 else: 0) != 0:
                                if (if (if reqcu__goto_10319_19 < 128: 1 else: 0) != 0 or ((if (if (if utf__goto_10299_6 != 0: 0 else: 1) != 0 and (if ucp__goto_10300_6 != 0: 0 else: 1) != 0: 1 else: 0) != 0 and (if reqcu__goto_10319_19 < 255: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                    if (if cb__goto_10304_15.fcc[reqcu__goto_10319_19] != reqcu__goto_10319_19: 1 else: 0) != 0:
                                        re__goto_10303_18.flags = re__goto_10303_18.flags | 256
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
                    (study_rc__goto_11141_7 = _pcre2_study_8(re__goto_10303_18))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if study_rc__goto_11141_7 != 0: 1 else: 0) != 0:
                        (errorcode__goto_10330_5 = ERR31)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (cb__goto_10304_15.erroroffset = 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 2
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (if ((re__goto_10303_18.flags & 64)) != 0: 1 else: 0) != 0 and (if minminlength__goto_11140_7 == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                        (minminlength__goto_11140_7 = 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if re__goto_10303_18.minlength < minminlength__goto_11140_7: 1 else: 0) != 0:
                        (re__goto_10303_18.minlength = minminlength__goto_11140_7)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // EXIT
                eprint("[compile] STATE 1: EXIT")
                (__goto_pending = 0)
                if (if cb__goto_10304_15.parsed_pattern != (&stack_parsed_pattern__goto_10342_10[0] as *mut c_uint): 1 else: 0) != 0:
                    ccontext.memctl.free((cb__goto_10304_15.parsed_pattern as *mut c_void), ccontext.memctl.memory_data)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb__goto_10304_15.named_group_list_size > 20: 1 else: 0) != 0:
                    ccontext.memctl.free((cb__goto_10304_15.named_groups as *mut c_void), ccontext.memctl.memory_data)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb__goto_10304_15.groupinfo != (&stack_groupinfo__goto_10341_10[0] as *mut c_uint): 1 else: 0) != 0:
                    ccontext.memctl.free((cb__goto_10304_15.groupinfo as *mut c_void), ccontext.memctl.memory_data)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return re__goto_10303_18
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 2
                continue
            2 =>  // HAD_CB_ERROR
                eprint("[compile] STATE 2: HAD_CB_ERROR")
                (__goto_pending = 0)
                (ptr__goto_10310_12 = (pattern + cb__goto_10304_15.erroroffset))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 3
                continue
            3 =>  // HAD_EARLY_ERROR
                eprint("[compile] STATE 3: HAD_EARLY_ERROR")
                (__goto_pending = 0)
                ((unsafe: *erroroffset) = ((ptr__goto_10310_12 as usize -% pattern as usize) / sizeof[u8]()))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 4
                continue
            4 =>  // HAD_ERROR
                eprint("[compile] STATE 4: HAD_ERROR")
                (__goto_pending = 0)
                ((unsafe: *errorptr) = errorcode__goto_10330_5)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                pcre2_code_free_8(re__goto_10303_18)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (re__goto_10303_18 = (null as *mut pcre2_real_code_8))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if cb__goto_10304_15.first_data != (null as *mut compile_data): 1 else: 0) != 0:
                    current_data__goto_11347_17 = cb__goto_10304_15.first_data
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while true:
                        next_data__goto_11350_19 = current_data__goto_11347_17.next
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        cb__goto_10304_15.cx.memctl.free((current_data__goto_11347_17 as *mut c_void), cb__goto_10304_15.cx.memctl.memory_data)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (current_data__goto_11347_17 = next_data__goto_11350_19)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if not ((if current_data__goto_11347_17 != (null as *mut compile_data): 1 else: 0) != 0):
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
// union
type heapframe_fields_char_repeat_oc { oc: c_uint = 0, occu: [4]u8 = [0 as u8; 4] }
type heapframe_fields_char_repeat { start_eptr: *const u8 = null, charptr: *const u8 = null, min: c_uint = 0, max: c_uint = 0, c: c_uint = 0, oc: heapframe_fields_char_repeat_oc }
type heapframe_fields_charnot_repeat { start_eptr: *const u8 = null, min: c_uint = 0, max: c_uint = 0, c: c_uint = 0, oc: c_uint = 0 }
type heapframe_fields_class_repeat { start_eptr: *const u8 = null, byte_map_address: *const u8 = null, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_xclass_repeat { start_eptr: *const u8 = null, xclass_data: *const u8 = null, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_eclass_repeat { start_eptr: *const u8 = null, eclass_data: *const u8 = null, eclass_len: c_ulong = 0, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_type_repeat { start_eptr: *const u8 = null, min: c_uint = 0, max: c_uint = 0, ctype: c_uint = 0, propvalue: c_uint = 0 }
type heapframe_fields_ref_repeat { start: *const u8 = null, offset: c_ulong = 0, length: c_ulong = 0, min: c_uint = 0, max: c_uint = 0 }
type heapframe_fields_op_bra { frame_type: c_uint = 0 }
type heapframe_fields_op_brapos { start_eptr: *const u8 = null, start_group: *const u8 = null, frame_type: c_uint = 0 }
type heapframe_fields_op_recurse { start_branch: *const u8 = null, frame_type: c_uint = 0 }
type heapframe_fields_op_assert_scs { saved_end_subject: *const u8 = null, saved_eptr: *const u8 = null, true_end_extra: c_ulong = 0, saved_moptions: c_uint = 0 }
type heapframe_fields_op_cond { start_branch: *const u8 = null, length: c_ulong = 0 }
type heapframe_fields_op_vreverse { min: c_uint = 0, max: c_uint = 0 }
// union
type heapframe_fields { char_repeat: heapframe_fields_char_repeat, charnot_repeat: heapframe_fields_charnot_repeat, class_repeat: heapframe_fields_class_repeat, xclass_repeat: heapframe_fields_xclass_repeat, eclass_repeat: heapframe_fields_eclass_repeat, type_repeat: heapframe_fields_type_repeat, ref_repeat: heapframe_fields_ref_repeat, op_bra: heapframe_fields_op_bra, op_brapos: heapframe_fields_op_brapos, op_recurse: heapframe_fields_op_recurse, op_assert_scs: heapframe_fields_op_assert_scs, op_cond: heapframe_fields_op_cond, op_vreverse: heapframe_fields_op_vreverse }
type heapframe { ecode: *const u8 = null, back_frame: c_ulong = 0, rdepth: c_uint = 0, group_frame_type: c_uint = 0, return_id: u8 = 0, op: u8 = 0, byte1: u8 = 0, byte2: u8 = 0, fields: heapframe_fields, eptr: *const u8 = null, start_match: *const u8 = null, mark: *const u8 = null, recurse_last_used: *const u8 = null, current_recurse: c_uint = 0, capture_last: c_uint = 0, last_group_offset: c_ulong = 0, offset_top: c_ulong = 0, ovector: [131072]c_ulong = [0 as c_ulong; 131072] }
type struct_heapframe = heapframe
type static_assertion_heapframe_size = [1]c_int
type heapframe_align { unalign: c_char = 0, frame: heapframe }
type struct_heapframe_align = heapframe_align
type match_block_8 { memctl: pcre2_memctl, heap_limit: c_uint = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, hitend: c_int = 0, hasthen: c_int = 0, hasbsk: c_int = 0, allowemptypartial: c_int = 0, allowlookaroundbsk: c_int = 0, lcc: *const u8 = null, fcc: *const u8 = null, ctypes: *const u8 = null, start_offset: c_ulong = 0, end_offset_top: c_ulong = 0, partial: c_ushort = 0, bsr_convention: c_ushort = 0, name_count: c_ushort = 0, name_entry_size: c_ushort = 0, name_table: *const u8 = null, start_code: *const u8 = null, start_subject: *const u8 = null, check_subject: *const u8 = null, end_subject: *const u8 = null, true_end_subject: *const u8 = null, end_match_ptr: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, mark: *const u8 = null, nomatch_mark: *const u8 = null, verb_ecode_ptr: *const u8 = null, verb_skip_ptr: *const u8 = null, verb_current_recurse: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, skip_arg_count: c_uint = 0, ignore_skip_arg: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, nl: [4]u8 = [0 as u8; 4], cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null }
type struct_match_block_8 = match_block_8
type dfa_match_block_8 { memctl: pcre2_memctl, start_code: *const u8 = null, start_subject: *const u8 = null, end_subject: *const u8 = null, start_used_ptr: *const u8 = null, last_used_ptr: *const u8 = null, tables: *const u8 = null, start_offset: c_ulong = 0, heap_limit: c_uint = 0, heap_used: c_ulong = 0, match_limit: c_uint = 0, match_limit_depth: c_uint = 0, match_call_count: c_uint = 0, moptions: c_uint = 0, poptions: c_uint = 0, nltype: c_uint = 0, nllen: c_uint = 0, allowemptypartial: c_int = 0, nl: [4]u8 = [0 as u8; 4], bsr_convention: c_ushort = 0, cb: *mut pcre2_callout_block_8 = null, callout_data: *mut c_void = null, callout: *const fn(*mut pcre2_callout_block_8, *mut c_void) -> c_int = null, recursive: *mut dfa_recursion_info = null }
type struct_dfa_match_block_8 = dfa_match_block_8
extern fn _pcre2_auto_possessify_8(p0: *mut u8, p1: *const compile_block_8) -> c_int
fn _pcre2_check_escape_8(ptrptr: *mut *const u8, ptrend: *const u8, chptr: *mut c_uint, errorcodeptr: *mut c_int, options: c_uint, xoptions: c_uint, bracount: c_uint, isclass: c_int, cb: *mut compile_block_8) -> c_int:
    var utf__goto_1510_6: c_int = 0
    var alt_bsux__goto_1511_6: c_int = 0
    var ptr__goto_1513_12: *const u8 = null
    var c__goto_1514_10: c_uint = 0
    var cc__goto_1514_13: c_uint = 0
    var escape__goto_1515_5: c_int = 0
    var i__goto_1516_5: c_int = 0
    var p__goto_1562_18: *const u8 = null
    var s__goto_1627_7: c_int = 0
    var oldptr__goto_1628_14: *const u8 = null
    var overflow__goto_1629_8: c_int = 0
    var xc__goto_1668_16: c_uint = 0
    var hptr__goto_1674_20: *const u8 = null
    var p__goto_1773_18: *const u8 = null
    var p__goto_1816_18: *const u8 = null
    var xc__goto_2049_16: c_uint = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                utf__goto_1510_6 = (if ((options & 524288)) != 0: 1 else: 0)
                alt_bsux__goto_1511_6 = (if ((((options & 2)) | ((xoptions & 32)))) != 0: 1 else: 0)
                ptr__goto_1513_12 = (unsafe: *ptrptr)
                escape__goto_1515_5 = 0
                if (if ptr__goto_1513_12 >= ptrend: 1 else: 0) != 0:
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
                ((unsafe: *ptrptr) = ptr__goto_1513_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *chptr) = c__goto_1514_10)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return escape__goto_1515_5
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 3
                continue
            3 =>  // ESCAPE_FAILED_FORWARD
                (__goto_pending = 0)
                (ptr__goto_1513_12 = ptr__goto_1513_12 + 1)
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
    var branchlength__goto_9603_5: c_int = 0
    var branchminlength__goto_9604_5: c_int = 0
    var grouplength__goto_9605_5: c_int = 0
    var groupminlength__goto_9605_18: c_int = 0
    var lastitemlength__goto_9606_10: c_uint = 0
    var lastitemminlength__goto_9607_10: c_uint = 0
    var pptr__goto_9608_11: *mut c_uint = null
    var offset__goto_9609_12: c_ulong = 0
    var this_recurse__goto_9610_22: parsed_recurse_check
    var r__goto_9626_25: *mut parsed_recurse_check = null
    var gptr__goto_9627_13: *mut c_uint = null
    var gptrend__goto_9627_20: *mut c_uint = null
    var escape__goto_9628_12: c_uint = 0
    var min__goto_9629_12: c_uint = 0
    var max__goto_9629_17: c_uint = 0
    var group__goto_9630_12: c_uint = 0
    var itemlength__goto_9631_12: c_uint = 0
    var itemminlength__goto_9632_12: c_uint = 0
    var name__goto_9787_18: *const u8 = null
    var is_dupname__goto_9788_12: c_int = 0
    var ng__goto_9789_20: *mut named_group_8 = null
    var meta_code__goto_9790_16: c_uint = 0
    var length__goto_9791_16: c_uint = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                branchlength__goto_9603_5 = 0
                branchminlength__goto_9604_5 = 0
                lastitemlength__goto_9606_10 = 0
                lastitemminlength__goto_9607_10 = 0
                pptr__goto_9608_11 = (unsafe: *pptrptr)
                if (if (((unsafe: *lcptr)) = ((unsafe: *lcptr)) + 1) > 2000: 1 else: 0) != 0:
                    ((unsafe: *errcodeptr) = ERR35)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    return -1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (pptr__goto_9608_11 = pptr__goto_9608_11 + 1) != null:
                    group__goto_9630_12 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    itemlength__goto_9631_12 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    itemminlength__goto_9632_12 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (unsafe: *pptr__goto_9608_11) < 2147483648: 1 else: 0) != 0:
                        (itemminlength__goto_9632_12 = 1)
                        (itemlength__goto_9631_12 = itemminlength__goto_9632_12)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if (2147483647 - branchlength__goto_9603_5) < (itemlength__goto_9631_12 as c_int): 1 else: 0) != 0 or (if (branchlength__goto_9603_5 = branchlength__goto_9603_5 + itemlength__goto_9631_12) > ((65535 as c_int)): 1 else: 0) != 0: 1 else: 0) != 0:
                        ((unsafe: *errcodeptr) = ERR87)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        return -1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    branchminlength__goto_9604_5 = branchminlength__goto_9604_5 + itemminlength__goto_9632_12
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (lastitemlength__goto_9606_10 = itemlength__goto_9631_12)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (lastitemminlength__goto_9607_10 = itemminlength__goto_9632_12)
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
                ((unsafe: *pptrptr) = pptr__goto_9608_11)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *minptr) = branchminlength__goto_9604_5)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return branchlength__goto_9603_5
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
        if (if (maxlength as c_ulong) > cb.max_varlookbehind: 1 else: 0) != 0:
            ((unsafe: *errcodeptr) = ERR100)
            (cb.erroroffset = offset)
            return 0
        
    else:
        (gbptr[1] = 65535)

    return 1

fn check_lookbehinds(__param_pptr: *mut c_uint, retptr: *mut *mut c_uint, recurses: *mut parsed_recurse_check, cb: *mut compile_block_8, lcptr: *mut c_int) -> c_int:
    var pptr = __param_pptr
    var errorcode: c_int = 0
    var nestlevel: c_int = 0
    (cb.erroroffset = ((0 -% 1)))
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
var verbnames: [43]c_char = "\0MARK\0ACCEPT\0F\0FAIL\0COMMIT\0PRUNE\0SKIP\0THEN"
var verbs: [9]verbitem = [verbitem { len: 0, meta: 2150432768, has_arg: 1 }, verbitem { len: 4, meta: 2150432768, has_arg: 1 }, verbitem { len: 6, meta: 2150498304, has_arg: -1 }, verbitem { len: 1, meta: 2150563840, has_arg: -1 }, verbitem { len: 4, meta: 2150563840, has_arg: -1 }, verbitem { len: 6, meta: 2150629376, has_arg: 0 }, verbitem { len: 5, meta: 2150760448, has_arg: 0 }, verbitem { len: 4, meta: 2150891520, has_arg: 0 }, verbitem { len: 4, meta: 2151022592, has_arg: 0 }]
let verbcount: c_int = 9
var verbops: [11]c_uint = [156, 166, 165, 163, 164, 157, 158, 159, 160, 161, 162]
type alasitem { len: c_uint = 0, meta: c_uint = 0 }
type struct_alasitem = alasitem
var alasnames: [229]c_char = "pla\0plb\0napla\0naplb\0nla\0nlb\0positive_lookahead\0positive_lookbehind\0non_atomic_positive_lookahead\0non_atomic_positive_lookbehind\0negative_lookahead\0negative_lookbehind\0scs\0scan_substring\0atomic\0sr\0asr\0script_run\0atomic_script_run"
var alasmeta: [19]alasitem = [alasitem { len: 3, meta: 2150039552 }, alasitem { len: 3, meta: 2150170624 }, alasitem { len: 5, meta: 2150301696 }, alasitem { len: 5, meta: 2150367232 }, alasitem { len: 3, meta: 2150105088 }, alasitem { len: 3, meta: 2150236160 }, alasitem { len: 18, meta: 2150039552 }, alasitem { len: 19, meta: 2150170624 }, alasitem { len: 29, meta: 2150301696 }, alasitem { len: 30, meta: 2150367232 }, alasitem { len: 18, meta: 2150105088 }, alasitem { len: 19, meta: 2150236160 }, alasitem { len: 3, meta: 2148990976 }, alasitem { len: 14, meta: 2148990976 }, alasitem { len: 6, meta: 2147614720 }, alasitem { len: 2, meta: 2149974016 }, alasitem { len: 3, meta: 2415853568 }, alasitem { len: 10, meta: 2149974016 }, alasitem { len: 17, meta: 2415853568 }]
let alascount: c_int = 19
var chartypeoffset: [4]c_uint = [0, 13, 26, 39]
var posix_names: [84]c_char = "alpha\0lower\0upper\0alnum\0ascii\0blank\0cntrl\0digit\0graph\0print\0punct\0space\0word\0xdigit"
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
    var sign__goto_1279_5: c_int = 0
    var n__goto_1280_10: c_uint = 0
    var ptr__goto_1281_12: *const u8 = null
    var yield___goto_1282_6: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                sign__goto_1279_5 = 0
                n__goto_1280_10 = 0
                ptr__goto_1281_12 = (unsafe: *ptrptr)
                yield___goto_1282_6 = 0
                ((unsafe: *errorcodeptr) = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if allow_sign >= 0: 1 else: 0) != 0 and (if ptr__goto_1281_12 < ptrend: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if (unsafe: *ptr__goto_1281_12) == 43: 1 else: 0) != 0:
                        (sign__goto_1279_5 = 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        max_value = max_value - allow_sign
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (ptr__goto_1281_12 = ptr__goto_1281_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    else:
                        if (if (unsafe: *ptr__goto_1281_12) == 45: 1 else: 0) != 0:
                            (sign__goto_1279_5 = -1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            (ptr__goto_1281_12 = ptr__goto_1281_12 + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (if allow_sign >= 0: 1 else: 0) != 0 and (if sign__goto_1279_5 != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    if (if n__goto_1280_10 == 0: 1 else: 0) != 0:
                        ((unsafe: *errorcodeptr) = ERR26)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 1
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if sign__goto_1279_5 > 0: 1 else: 0) != 0:
                        n__goto_1280_10 = n__goto_1280_10 + allow_sign
                    else:
                        if (if n__goto_1280_10 > (allow_sign as c_uint): 1 else: 0) != 0:
                            ((unsafe: *errorcodeptr) = ERR15)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            __pc = 1
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        else:
                            (n__goto_1280_10 = ((allow_sign + 1) -% n__goto_1280_10))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (yield___goto_1282_6 = 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *intptr) = n__goto_1280_10)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *ptrptr) = ptr__goto_1281_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return yield___goto_1282_6
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn read_repeat_counts(ptrptr: *mut *const u8, ptrend: *const u8, minp: *mut c_uint, maxp: *mut c_uint, errorcodeptr: *mut c_int) -> c_int:
    var p__goto_1369_12: *const u8 = null
    var pp__goto_1370_12: *const u8 = null
    var yield___goto_1371_6: c_int = 0
    var had_minimum__goto_1372_6: c_int = 0
    var min__goto_1373_9: c_int = 0
    var max__goto_1374_9: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                p__goto_1369_12 = (unsafe: *ptrptr)
                yield___goto_1371_6 = 0
                had_minimum__goto_1372_6 = 0
                min__goto_1373_9 = 0
                max__goto_1374_9 = 65536
                ((unsafe: *errorcodeptr) = 0)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if p__goto_1369_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p__goto_1369_12) == 32: 1 else: 0) != 0 or (if (unsafe: *p__goto_1369_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (p__goto_1369_12 = p__goto_1369_12 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (pp__goto_1370_12 = p__goto_1369_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if pp__goto_1370_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *pp__goto_1370_12) == 32: 1 else: 0) != 0 or (if (unsafe: *pp__goto_1370_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (pp__goto_1370_12 = pp__goto_1370_12 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if pp__goto_1370_12 >= ptrend: 1 else: 0) != 0:
                    return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if (unsafe: *pp__goto_1370_12) == 125: 1 else: 0) != 0:
                    if (if had_minimum__goto_1372_6 != 0: 0 else: 1) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    if (if (unsafe: *(pp__goto_1370_12 = pp__goto_1370_12 + 1)) != 44: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if pp__goto_1370_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *pp__goto_1370_12) == 32: 1 else: 0) != 0 or (if (unsafe: *pp__goto_1370_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (pp__goto_1370_12 = pp__goto_1370_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if pp__goto_1370_12 >= ptrend: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if pp__goto_1370_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *pp__goto_1370_12) == 32: 1 else: 0) != 0 or (if (unsafe: *pp__goto_1370_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (pp__goto_1370_12 = pp__goto_1370_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (if pp__goto_1370_12 >= ptrend: 1 else: 0) != 0 or (if (unsafe: *pp__goto_1370_12) != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                        return 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if read_number((&mut p__goto_1369_12 as *mut *const u8), ptrend, -1, 65535, 105, (&mut min__goto_1373_9 as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                    if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                        __pc = 1
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (p__goto_1369_12 = p__goto_1369_12 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    while (if (if p__goto_1369_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p__goto_1369_12) == 32: 1 else: 0) != 0 or (if (unsafe: *p__goto_1369_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (p__goto_1369_12 = p__goto_1369_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if read_number((&mut p__goto_1369_12 as *mut *const u8), ptrend, -1, 65535, 105, (&mut max__goto_1374_9 as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                        if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                            __pc = 1
                            __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    while (if (if p__goto_1369_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p__goto_1369_12) == 32: 1 else: 0) != 0 or (if (unsafe: *p__goto_1369_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (p__goto_1369_12 = p__goto_1369_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if (unsafe: *p__goto_1369_12) == 125: 1 else: 0) != 0:
                        (max__goto_1374_9 = min__goto_1373_9)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    else:
                        (p__goto_1369_12 = p__goto_1369_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        while (if (if p__goto_1369_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p__goto_1369_12) == 32: 1 else: 0) != 0 or (if (unsafe: *p__goto_1369_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                            (p__goto_1369_12 = p__goto_1369_12 + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if read_number((&mut p__goto_1369_12 as *mut *const u8), ptrend, -1, 65535, 105, (&mut max__goto_1374_9 as *mut c_int), errorcodeptr) != 0: 0 else: 1) != 0:
                            if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                                __pc = 1
                                __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        if (if max__goto_1374_9 < min__goto_1373_9: 1 else: 0) != 0:
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
                while (if (if p__goto_1369_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *p__goto_1369_12) == 32: 1 else: 0) != 0 or (if (unsafe: *p__goto_1369_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                    (p__goto_1369_12 = p__goto_1369_12 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (p__goto_1369_12 = p__goto_1369_12 + 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (yield___goto_1371_6 = 1)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if minp != (null as *mut c_uint): 1 else: 0) != 0:
                    ((unsafe: *minp) = (min__goto_1373_9 as c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if maxp != (null as *mut c_uint): 1 else: 0) != 0:
                    ((unsafe: *maxp) = (max__goto_1374_9 as c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // EXIT
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = p__goto_1369_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return yield___goto_1371_6
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
    var ptr__goto_2613_12: *const u8 = null
    var is_group__goto_2614_6: c_int = 0
    var is_braced__goto_2615_6: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                ptr__goto_2613_12 = (unsafe: *ptrptr)
                is_group__goto_2614_6 = ((if (unsafe: *(ptr__goto_2613_12 = ptr__goto_2613_12 + 1)) != 42: 1 else: 0))
                is_braced__goto_2615_6 = (if terminator == 125: 1 else: 0)
                if is_braced__goto_2615_6 != 0:
                    while (if (if ptr__goto_2613_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *ptr__goto_2613_12) == 32: 1 else: 0) != 0 or (if (unsafe: *ptr__goto_2613_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (ptr__goto_2613_12 = ptr__goto_2613_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ptr__goto_2613_12 >= ptrend: 1 else: 0) != 0:
                    ((unsafe: *errorcodeptr) = (if is_group__goto_2614_6 != 0: ERR62 else: ERR60))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 1
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *nameptr) = ptr__goto_2613_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *offsetptr) = ((((ptr__goto_2613_12 as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_ulong))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                utf
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if (if (if ptr__goto_2613_12 < ptrend: 1 else: 0) != 0 and 1 != 0: 1 else: 0) != 0 and (if ((cb.ctypes[(unsafe: *ptr__goto_2613_12)] & 16)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    (ptr__goto_2613_12 = ptr__goto_2613_12 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((ptr__goto_2613_12 as usize -% (unsafe: *nameptr) as usize) / sizeof[u8]()) > 128: 1 else: 0) != 0:
                    ((unsafe: *errorcodeptr) = ERR48)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 1
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *namelenptr) = ((((ptr__goto_2613_12 as usize -% (unsafe: *nameptr) as usize) / sizeof[u8]())) as c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if is_group__goto_2614_6 != 0:
                    if (if ptr__goto_2613_12 == (unsafe: *nameptr): 1 else: 0) != 0:
                        ((unsafe: *errorcodeptr) = ERR62)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        __pc = 1
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if is_braced__goto_2615_6 != 0:
                        while (if (if ptr__goto_2613_12 < ptrend: 1 else: 0) != 0 and ((if (if (unsafe: *ptr__goto_2613_12) == 32: 1 else: 0) != 0 or (if (unsafe: *ptr__goto_2613_12) == 9: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                            (ptr__goto_2613_12 = ptr__goto_2613_12 + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if terminator != 0: 1 else: 0) != 0:
                        if (if (if ptr__goto_2613_12 >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr__goto_2613_12) != (terminator as u8): 1 else: 0) != 0: 1 else: 0) != 0:
                            ((unsafe: *errorcodeptr) = ERR42)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                            __pc = 1
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (ptr__goto_2613_12 = ptr__goto_2613_12 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *ptrptr) = ptr__goto_2613_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 1
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // FAILED
                (__goto_pending = 0)
                ((unsafe: *ptrptr) = ptr__goto_2613_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn parse_capture_list(ptrptr: *mut *const u8, ptrend: *const u8, utf: c_int, __param_parsed_pattern: *mut c_uint, __param_offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> *mut c_uint:
    var parsed_pattern = __param_parsed_pattern
    var offset = __param_offset
    var next_offset__goto_2752_12: c_ulong = 0
    var ptr__goto_2753_12: *const u8 = null
    var name__goto_2754_12: *const u8 = null
    var terminator__goto_2755_13: u8 = 0
    var meta__goto_2756_10: c_uint = 0
    var namelen__goto_2756_16: c_uint = 0
    var i__goto_2757_5: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                ptr__goto_2753_12 = (unsafe: *ptrptr)
                if (if (if ptr__goto_2753_12 >= ptrend: 1 else: 0) != 0 or (if (unsafe: *ptr__goto_2753_12) != 40: 1 else: 0) != 0: 1 else: 0) != 0:
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
                    (ptr__goto_2753_12 = ptr__goto_2753_12 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (next_offset__goto_2752_12 = ((((ptr__goto_2753_12 as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_ulong))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if ptr__goto_2753_12 >= ptrend: 1 else: 0) != 0:
                        ((unsafe: *errorcodeptr) = ERR117)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        __pc = 2
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if read_number((&mut ptr__goto_2753_12 as *mut *const u8), ptrend, cb.bracount, 65535, 161, (&mut i__goto_2757_5 as *mut c_int), errorcodeptr) != 0:
                        if (if i__goto_2757_5 <= 0: 1 else: 0) != 0:
                            ((unsafe: *errorcodeptr) = ERR15)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            __pc = 2
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (meta__goto_2756_10 = (2149122048 as c_uint))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (namelen__goto_2756_16 = (i__goto_2757_5 as c_uint))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    else:
                        if (if (unsafe: *errorcodeptr) != 0: 1 else: 0) != 0:
                            __pc = 2
                            __goto_pending = 1
                        else:
                            if (if (unsafe: *ptr__goto_2753_12) == 60: 1 else: 0) != 0:
                                (terminator__goto_2755_13 = 62)
                            else:
                                if (if (unsafe: *ptr__goto_2753_12) == 39: 1 else: 0) != 0:
                                    (terminator__goto_2755_13 = 39)
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
                            if (if read_name((&mut ptr__goto_2753_12 as *mut *const u8), ptrend, utf, terminator__goto_2755_13, (&mut next_offset__goto_2752_12 as *mut c_ulong), (&mut name__goto_2754_12 as *mut *const u8), (&mut namelen__goto_2756_16 as *mut c_uint), errorcodeptr, cb) != 0: 0 else: 1) != 0:
                                __pc = 2
                                __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (meta__goto_2756_10 = (2149056512 as c_uint))
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if offset == 0: 1 else: 0) != 0 or (if ((next_offset__goto_2752_12 -% offset)) >= 65536: 1 else: 0) != 0: 1 else: 0) != 0:
                        (unsafe: *parsed_pattern = 2148925440)
                        (parsed_pattern = parsed_pattern + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        0
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (offset = next_offset__goto_2752_12)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (unsafe: *parsed_pattern = (meta__goto_2756_10 | (((next_offset__goto_2752_12 -% offset)) as c_uint)))
                    (parsed_pattern = parsed_pattern + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (unsafe: *parsed_pattern = namelen__goto_2756_16)
                    (parsed_pattern = parsed_pattern + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (offset = next_offset__goto_2752_12)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if ptr__goto_2753_12 >= ptrend: 1 else: 0) != 0:
                        __pc = 1
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (unsafe: *ptr__goto_2753_12) == 41: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (unsafe: *ptr__goto_2753_12) != 44: 1 else: 0) != 0:
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
                ((unsafe: *ptrptr) = (ptr__goto_2753_12 + (1 as isize as usize)))
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
                ((unsafe: *ptrptr) = ptr__goto_2753_12)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return (null as *mut c_uint)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
            _ => break

fn manage_callouts(ptr: *const u8, pcalloutptr: *mut *mut c_uint, auto_callout: c_int, __param_parsed_pattern: *mut c_uint, cb: *mut compile_block_8) -> *mut c_uint:
    var parsed_pattern = __param_parsed_pattern
    var previous_callout: *mut c_uint = (unsafe: *pcalloutptr)
    if (if previous_callout != (null as *mut c_uint): 1 else: 0) != 0:
        (previous_callout[2] = (((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]()) -% (previous_callout[1] as c_ulong))) as c_uint))

    if (if auto_callout != 0: 0 else: 1) != 0:
        (previous_callout = (null as *mut c_uint))
    else:
        if (if (if (if previous_callout == (null as *mut c_uint): 1 else: 0) != 0 or (if previous_callout != (parsed_pattern - (4 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 or (if previous_callout[3] != 255: 1 else: 0) != 0: 1 else: 0) != 0:
            (previous_callout = parsed_pattern)
            parsed_pattern = parsed_pattern + 4
            (previous_callout[0] = (2147876864 as c_uint))
            (previous_callout[2] = 0)
            (previous_callout[3] = 255)
        
        (previous_callout[1] = ((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_uint))

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
    var c__goto_3131_10: c_uint = 0
    var delimiter__goto_3132_10: c_uint = 0
    var namelen__goto_3133_10: c_uint = 0
    var class_range_state__goto_3134_10: c_uint = 0
    var class_op_state__goto_3135_10: c_uint = 0
    var class_mode_state__goto_3136_10: c_uint = 0
    var class_start__goto_3137_11: *mut c_uint = null
    var verblengthptr__goto_3138_11: *mut c_uint = null
    var verbstartptr__goto_3139_11: *mut c_uint = null
    var previous_callout__goto_3140_11: *mut c_uint = null
    var parsed_pattern__goto_3141_11: *mut c_uint = null
    var parsed_pattern_end__goto_3142_11: *mut c_uint = null
    var this_parsed_item__goto_3143_11: *mut c_uint = null
    var prev_parsed_item__goto_3144_11: *mut c_uint = null
    var meta_quantifier__goto_3145_10: c_uint = 0
    var add_after_mark__goto_3146_10: c_uint = 0
    var nest_depth__goto_3147_10: c_ushort = 0
    var class_depth_m1__goto_3148_9: c_short = 0
    var class_maxdepth_m1__goto_3149_9: c_short = 0
    var hash__goto_3150_10: c_ushort = 0
    var after_manual_callout__goto_3151_5: c_int = 0
    var expect_cond_assert__goto_3152_5: c_int = 0
    var errorcode__goto_3153_5: c_int = 0
    var escape__goto_3154_5: c_int = 0
    var i__goto_3155_5: c_int = 0
    var inescq__goto_3156_6: c_int = 0
    var inverbname__goto_3157_6: c_int = 0
    var utf__goto_3158_6: c_int = 0
    var auto_callout__goto_3159_6: c_int = 0
    var is_dupname__goto_3160_6: c_int = 0
    var negate_class__goto_3161_6: c_int = 0
    var okquantifier__goto_3162_6: c_int = 0
    var thisptr__goto_3163_12: *const u8 = null
    var name__goto_3164_12: *const u8 = null
    var ptrend__goto_3165_12: *const u8 = null
    var verbnamestart__goto_3166_12: *const u8 = null
    var class_range_forbid_ptr__goto_3167_12: *const u8 = null
    var ng__goto_3168_14: *mut named_group_8 = null
    var top_nest__goto_3169_12: *mut nest_save = null
    var end_nests__goto_3169_23: *mut nest_save = null
    var prev_expect_cond_assert__goto_3244_7: c_int = 0
    var min_repeat__goto_3245_12: c_uint = 0
    var max_repeat__goto_3245_28: c_uint = 0
    var set__goto_3246_12: c_uint = 0
    var unset__goto_3246_17: c_uint = 0
    var optset__goto_3246_25: *mut c_uint = null
    var xset__goto_3247_12: c_uint = 0
    var xunset__goto_3247_18: c_uint = 0
    var xoptset__goto_3247_27: *mut c_uint = null
    var terminator__goto_3248_12: c_uint = 0
    var prev_meta_quantifier__goto_3249_12: c_uint = 0
    var prev_okquantifier__goto_3250_8: c_int = 0
    var tempptr__goto_3251_14: *const u8 = null
    var offset__goto_3252_14: c_ulong = 0
    var verbnamelength__goto_3364_16: c_ulong = 0
    var ok__goto_3535_10: c_int = 0
    var p__goto_3775_20: *const u8 = null
    var p__goto_3878_17: *mut c_uint = null
    var char_is_literal__goto_3990_12: c_int = 0
    var posix_negate__goto_4037_14: c_int = 0
    var posix_class__goto_4038_13: c_int = 0
    var start_c__goto_4154_18: c_uint = 0
    var new_class_mode_state__goto_4155_18: c_uint = 0
    var vn__goto_4741_19: *const i8 = null
    var meta__goto_4776_18: c_uint = 0
    var hyphenok__goto_5041_14: c_int = 0
    var oldoptions__goto_5042_18: c_uint = 0
    var oldxoptions__goto_5043_18: c_uint = 0
    var calloutlength__goto_5344_20: c_ulong = 0
    var startptr__goto_5345_20: *const u8 = null
    var n__goto_5393_13: c_int = 0
    var ge__goto_5488_18: c_uint = 0
    var major__goto_5489_13: c_int = 0
    var minor__goto_5490_13: c_int = 0
    var was_r_ampersand__goto_5544_14: c_int = 0
    var newsize__goto_5787_18: c_uint = 0
    var newspace__goto_5788_22: *mut named_group_8 = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                verblengthptr__goto_3138_11 = (null as *mut c_uint)
                verbstartptr__goto_3139_11 = (null as *mut c_uint)
                previous_callout__goto_3140_11 = (null as *mut c_uint)
                parsed_pattern__goto_3141_11 = cb.parsed_pattern
                parsed_pattern_end__goto_3142_11 = cb.parsed_pattern_end
                this_parsed_item__goto_3143_11 = (null as *mut c_uint)
                prev_parsed_item__goto_3144_11 = (null as *mut c_uint)
                meta_quantifier__goto_3145_10 = 0
                add_after_mark__goto_3146_10 = 0
                nest_depth__goto_3147_10 = 0
                class_depth_m1__goto_3148_9 = -1
                class_maxdepth_m1__goto_3149_9 = -1
                after_manual_callout__goto_3151_5 = 0
                expect_cond_assert__goto_3152_5 = 0
                errorcode__goto_3153_5 = 0
                inescq__goto_3156_6 = 0
                inverbname__goto_3157_6 = 0
                utf__goto_3158_6 = (if ((options & 524288)) != 0: 1 else: 0)
                auto_callout__goto_3159_6 = (if ((options & 4)) != 0: 1 else: 0)
                okquantifier__goto_3162_6 = 0
                ptrend__goto_3165_12 = cb.end_pattern
                verbnamestart__goto_3166_12 = (null as *const u8)
                class_range_forbid_ptr__goto_3167_12 = (null as *const u8)
                if (if ((xoptions & 8)) != 0: 1 else: 0) != 0:
                    (unsafe: *parsed_pattern__goto_3141_11 = 2148073472)
                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (unsafe: *parsed_pattern__goto_3141_11 = 2149449728)
                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    if (if ((xoptions & 4)) != 0: 1 else: 0) != 0:
                        (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% 5))
                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (unsafe: *parsed_pattern__goto_3141_11 = 2149449728)
                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 33554432)) != 0: 1 else: 0) != 0:
                    while (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0:
                        if (if parsed_pattern__goto_3141_11 >= parsed_pattern_end__goto_3142_11: 1 else: 0) != 0:
                            (errorcode__goto_3153_5 = ERR63)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            __pc = 19
                            __goto_pending = 1
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (thisptr__goto_3163_12 = ptr)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        0
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if auto_callout__goto_3159_6 != 0:
                            (parsed_pattern__goto_3141_11 = manage_callouts(thisptr__goto_3163_12, (&mut previous_callout__goto_3140_11 as *mut *mut c_uint), auto_callout__goto_3159_6, parsed_pattern__goto_3141_11, cb))
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
                (top_nest__goto_3169_12 = (null as *mut nest_save))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (end_nests__goto_3169_23 = (((cb.start_workspace + cb.workspace_size)) as *mut nest_save))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (end_nests__goto_3169_23 = ((((end_nests__goto_3169_23 as *mut i8) - ((((cb.workspace_size *% sizeof[u8]())) % sizeof[nest_save]())))) as *mut nest_save))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((options & 16777216)) != 0: 1 else: 0) != 0:
                    options = options | 128
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0:
                    min_repeat__goto_3245_12 = 0
                    max_repeat__goto_3245_28 = 0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if nest_depth__goto_3147_10 > cb.cx.parens_nest_limit: 1 else: 0) != 0:
                        (errorcode__goto_3153_5 = ERR19)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        __pc = 19
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if parsed_pattern__goto_3141_11 >= parsed_pattern_end__goto_3142_11: 1 else: 0) != 0:
                        (errorcode__goto_3153_5 = ERR63)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        __pc = 19
                        __goto_pending = 1
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if this_parsed_item__goto_3143_11 != parsed_pattern__goto_3141_11: 1 else: 0) != 0:
                        (prev_parsed_item__goto_3144_11 = this_parsed_item__goto_3143_11)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (this_parsed_item__goto_3143_11 = parsed_pattern__goto_3141_11)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (thisptr__goto_3163_12 = ptr)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if inescq__goto_3156_6 != 0:
                        if (if (if (if c__goto_3131_10 == 92: 1 else: 0) != 0 and (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                            (inescq__goto_3156_6 = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (ptr = ptr + 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        else:
                            if inverbname__goto_3157_6 != 0:
                                (unsafe: *parsed_pattern__goto_3141_11 = c__goto_3131_10)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (after_manual_callout__goto_3151_5 = after_manual_callout__goto_3151_5 - 1) <= 0: 1 else: 0) != 0:
                                    (parsed_pattern__goto_3141_11 = manage_callouts(thisptr__goto_3163_12, (&mut previous_callout__goto_3140_11 as *mut *mut c_uint), auto_callout__goto_3159_6, parsed_pattern__goto_3141_11, cb))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (meta_quantifier__goto_3145_10 = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if c__goto_3131_10 == 92: 1 else: 0) != 0 and (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0: 1 else: 0) != 0:
                        if (if (if (unsafe: *ptr) == 81: 1 else: 0) != 0 or (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (if (if expect_cond_assert__goto_3152_5 > 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == 81: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0 and (if ptr[1] == 92: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[2] == 69: 1 else: 0) != 0: 1 else: 0)) != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                (ptr = ptr - 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (errorcode__goto_3153_5 = ERR28)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (inescq__goto_3156_6 = (if (unsafe: *ptr) == 81: 1 else: 0))
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
                        if (if (if c__goto_3131_10 < 256: 1 else: 0) != 0 and (if ((cb.ctypes[c__goto_3131_10] & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                            continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if c__goto_3131_10 == 35: 1 else: 0) != 0:
                            while (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0:
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
                    if (if (if (if (if c__goto_3131_10 == 40: 1 else: 0) != 0 and (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) >= 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[0] == 63: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 35: 1 else: 0) != 0: 1 else: 0) != 0:
                        while (if (if (ptr = ptr + 1) < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                            0
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                            (errorcode__goto_3153_5 = ERR18)
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
                    if (if expect_cond_assert__goto_3152_5 > 0: 1 else: 0) != 0:
                        ok__goto_3535_10 = (if (if (if c__goto_3131_10 == 40: 1 else: 0) != 0 and (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0: 1 else: 0) != 0 and ((if (if ptr[0] == 63: 1 else: 0) != 0 or (if ptr[0] == 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if ok__goto_3535_10 != 0:
                            if (if ptr[0] == 42: 1 else: 0) != 0:
                                (ok__goto_3535_10 = (if 1 != 0 and (if ((cb.ctypes[ptr[1]] & 4)) != 0: 1 else: 0) != 0: 1 else: 0))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                match ptr[1]
                                    67 =>
                                        (ok__goto_3535_10 = (if expect_cond_assert__goto_3152_5 == 2: 1 else: 0))
                                    61 =>
                                        (ok__goto_3535_10 = (if (if ptr[2] == 61: 1 else: 0) != 0 or (if ptr[2] == 33: 1 else: 0) != 0: 1 else: 0))
                                    60 =>
                                        (ok__goto_3535_10 = (if (if ptr[2] == 61: 1 else: 0) != 0 or (if ptr[2] == 33: 1 else: 0) != 0: 1 else: 0))
                                    _ =>
                                        (ok__goto_3535_10 = 0)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if ok__goto_3535_10 != 0: 0 else: 1) != 0:
                            (errorcode__goto_3153_5 = ERR28)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            if (if expect_cond_assert__goto_3152_5 == 2: 1 else: 0) != 0:
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
                    (prev_expect_cond_assert__goto_3244_7 = expect_cond_assert__goto_3152_5)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (expect_cond_assert__goto_3152_5 = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (prev_okquantifier__goto_3250_8 = okquantifier__goto_3162_6)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (prev_meta_quantifier__goto_3249_12 = meta_quantifier__goto_3145_10)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (okquantifier__goto_3162_6 = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (meta_quantifier__goto_3145_10 = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if prev_meta_quantifier__goto_3249_12 != 0: 1 else: 0) != 0 and ((if (if c__goto_3131_10 == 63: 1 else: 0) != 0 or (if c__goto_3131_10 == 43: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                        (parsed_pattern__goto_3141_11[(if ((if prev_meta_quantifier__goto_3249_12 == 2151743488: 1 else: 0)) != 0: -3 else: -1)] = (prev_meta_quantifier__goto_3249_12 +% ((if ((if c__goto_3131_10 == 63: 1 else: 0)) != 0: 131072 else: 65536))))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        continue
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    match c__goto_3131_10
                        92 =>
                            (tempptr__goto_3251_14 = ptr)
                            (escape__goto_3154_5 = _pcre2_check_escape_8((&mut ptr as *mut *const u8), ptrend__goto_3165_12, (&mut c__goto_3131_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), options, xoptions, cb.bracount, 0, cb))
                            if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
                                if (if ((xoptions & 2)) == 0: 1 else: 0) != 0:
                                    __pc = 19
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ptr = tempptr__goto_3251_14)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                    (c__goto_3131_10 = 92)
                                else:
                                    0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (escape__goto_3154_5 = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if escape__goto_3154_5 == 0: 1 else: 0) != 0:
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if escape__goto_3154_5 < 0: 1 else: 0) != 0:
                                    (offset__goto_3252_14 = ((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_ulong))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (escape__goto_3154_5 = ((0 - escape__goto_3154_5) - 1))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (unsafe: *parsed_pattern__goto_3141_11 = ((2147680256 as c_uint) | (escape__goto_3154_5 as c_uint)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if escape__goto_3154_5 < 10: 1 else: 0) != 0:
                                        if (if (&cb.small_ref_offset[0] as *mut c_ulong)[escape__goto_3154_5] == ((0 -% 1)): 1 else: 0) != 0:
                                            ((&cb.small_ref_offset[0] as *mut c_ulong)[escape__goto_3154_5] = offset__goto_3252_14)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (okquantifier__goto_3162_6 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    match escape__goto_3154_5
                                        ESC_C =>
                                            if (if ((options & 1048576)) != 0: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR83)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 1
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            (okquantifier__goto_3162_6 = 1)
                                            (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% escape__goto_3154_5))
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        ESC_ub =>
                                            (unsafe: *parsed_pattern__goto_3141_11 = 117)
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            0
                                        ESC_X =>
                                            (errorcode__goto_3153_5 = ERR45)
                                            __pc = 1
                                            __goto_pending = 1
                                            (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% escape__goto_3154_5))
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        ESC_H =>
                                            (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% escape__goto_3154_5))
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        ESC_d =>
                                            (parsed_pattern__goto_3141_11 = handle_escdsw(escape__goto_3154_5, parsed_pattern__goto_3141_11, options, xoptions))
                                        ESC_P =>
                                            __pc = 1
                                            __goto_pending = 1
                                        ESC_g =>
                                            (terminator__goto_3248_12 = (if ((if (unsafe: *ptr) == 60: 1 else: 0)) != 0: 62 else: (if ((if (unsafe: *ptr) == 39: 1 else: 0)) != 0: 39 else: 125)))
                                            if (if (if escape__goto_3154_5 == ESC_g: 1 else: 0) != 0 and (if terminator__goto_3248_12 != 125: 1 else: 0) != 0: 1 else: 0) != 0:
                                                p__goto_3775_20 = (ptr + (1 as isize as usize))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if read_number((&mut p__goto_3775_20 as *mut *const u8), ptrend__goto_3165_12, cb.bracount, 65535, 161, (&mut i__goto_3155_5 as *mut c_int), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0:
                                                    if (if (if p__goto_3775_20 >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *p__goto_3775_20) != terminator__goto_3248_12: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = p__goto_3775_20)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (errorcode__goto_3153_5 = ERR119)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        __pc = 1
                                                        __goto_pending = 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = (p__goto_3775_20 + (1 as isize as usize)))
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    __pc = 7
                                                    __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
                                                    __pc = 1
                                                    __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, terminator__goto_3248_12, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                __pc = 1
                                                __goto_pending = 1
                                            (unsafe: *parsed_pattern__goto_3141_11 = (if ((if (if escape__goto_3154_5 == ESC_k: 1 else: 0) != 0 or (if terminator__goto_3248_12 == 125: 1 else: 0) != 0: 1 else: 0)) != 0: 2147745792 else: 2149908480))
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            (unsafe: *parsed_pattern__goto_3141_11 = namelen__goto_3133_10)
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            0
                                            (okquantifier__goto_3162_6 = 1)
                                        _ =>
                                            (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% escape__goto_3154_5))
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        94 =>
                            (unsafe: *parsed_pattern__goto_3141_11 = 2148073472)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        36 =>
                            (unsafe: *parsed_pattern__goto_3141_11 = 2149187584)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        46 =>
                            (unsafe: *parsed_pattern__goto_3141_11 = 2149253120)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                            (okquantifier__goto_3162_6 = 1)
                        42 =>
                            (meta_quantifier__goto_3145_10 = (2151153664 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            (meta_quantifier__goto_3145_10 = (2151350272 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            (meta_quantifier__goto_3145_10 = (2151546880 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend__goto_3165_12, (&mut min_repeat__goto_3245_12 as *mut c_uint), (&mut max_repeat__goto_3245_28 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
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
                            (meta_quantifier__goto_3145_10 = (2151743488 as c_uint))
                            if (if prev_okquantifier__goto_3250_8 != 0: 0 else: 1) != 0:
                                (errorcode__goto_3153_5 = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item__goto_3144_11) == 2150498304: 1 else: 0) != 0:
                                (p__goto_3878_17 = (parsed_pattern__goto_3141_11 - (1 as isize as usize)))
                                while (if p__goto_3878_17 >= verbstartptr__goto_3139_11: 1 else: 0) != 0:
                                    (p__goto_3878_17[1] = p__goto_3878_17[0])
                                    (p__goto_3878_17 = p__goto_3878_17 - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr__goto_3139_11) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern__goto_3141_11[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern__goto_3141_11 = meta_quantifier__goto_3145_10)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                            if (if c__goto_3131_10 == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern__goto_3141_11 = min_repeat__goto_3245_12)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern__goto_3141_11 = max_repeat__goto_3245_28)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        43 =>
                            (meta_quantifier__goto_3145_10 = (2151350272 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            (meta_quantifier__goto_3145_10 = (2151546880 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend__goto_3165_12, (&mut min_repeat__goto_3245_12 as *mut c_uint), (&mut max_repeat__goto_3245_28 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
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
                            (meta_quantifier__goto_3145_10 = (2151743488 as c_uint))
                            if (if prev_okquantifier__goto_3250_8 != 0: 0 else: 1) != 0:
                                (errorcode__goto_3153_5 = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item__goto_3144_11) == 2150498304: 1 else: 0) != 0:
                                (p__goto_3878_17 = (parsed_pattern__goto_3141_11 - (1 as isize as usize)))
                                while (if p__goto_3878_17 >= verbstartptr__goto_3139_11: 1 else: 0) != 0:
                                    (p__goto_3878_17[1] = p__goto_3878_17[0])
                                    (p__goto_3878_17 = p__goto_3878_17 - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr__goto_3139_11) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern__goto_3141_11[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern__goto_3141_11 = meta_quantifier__goto_3145_10)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                            if (if c__goto_3131_10 == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern__goto_3141_11 = min_repeat__goto_3245_12)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern__goto_3141_11 = max_repeat__goto_3245_28)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        63 =>
                            (meta_quantifier__goto_3145_10 = (2151546880 as c_uint))
                            __pc = 2
                            __goto_pending = 1
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend__goto_3165_12, (&mut min_repeat__goto_3245_12 as *mut c_uint), (&mut max_repeat__goto_3245_28 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
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
                            (meta_quantifier__goto_3145_10 = (2151743488 as c_uint))
                            if (if prev_okquantifier__goto_3250_8 != 0: 0 else: 1) != 0:
                                (errorcode__goto_3153_5 = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item__goto_3144_11) == 2150498304: 1 else: 0) != 0:
                                (p__goto_3878_17 = (parsed_pattern__goto_3141_11 - (1 as isize as usize)))
                                while (if p__goto_3878_17 >= verbstartptr__goto_3139_11: 1 else: 0) != 0:
                                    (p__goto_3878_17[1] = p__goto_3878_17[0])
                                    (p__goto_3878_17 = p__goto_3878_17 - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr__goto_3139_11) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern__goto_3141_11[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern__goto_3141_11 = meta_quantifier__goto_3145_10)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                            if (if c__goto_3131_10 == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern__goto_3141_11 = min_repeat__goto_3245_12)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern__goto_3141_11 = max_repeat__goto_3245_28)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        123 =>
                            if (if read_repeat_counts((&mut ptr as *mut *const u8), ptrend__goto_3165_12, (&mut min_repeat__goto_3245_12 as *mut c_uint), (&mut max_repeat__goto_3245_28 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0: 0 else: 1) != 0:
                                if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
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
                            (meta_quantifier__goto_3145_10 = (2151743488 as c_uint))
                            if (if prev_okquantifier__goto_3250_8 != 0: 0 else: 1) != 0:
                                (errorcode__goto_3153_5 = ERR9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (unsafe: *prev_parsed_item__goto_3144_11) == 2150498304: 1 else: 0) != 0:
                                (p__goto_3878_17 = (parsed_pattern__goto_3141_11 - (1 as isize as usize)))
                                while (if p__goto_3878_17 >= verbstartptr__goto_3139_11: 1 else: 0) != 0:
                                    (p__goto_3878_17[1] = p__goto_3878_17[0])
                                    (p__goto_3878_17 = p__goto_3878_17 - 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *verbstartptr__goto_3139_11) = (2149449728 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (parsed_pattern__goto_3141_11[1] = (2149384192 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern__goto_3141_11 = meta_quantifier__goto_3145_10)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                            if (if c__goto_3131_10 == 123: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern__goto_3141_11 = min_repeat__goto_3245_12)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern__goto_3141_11 = max_repeat__goto_3245_28)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        91 =>
                            if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) >= 6: 1 else: 0) != 0 and ((if (if _pcre2_strncmp_c8_8(ptr, "[:<:]]", 6) == 0: 1 else: 0) != 0 or (if _pcre2_strncmp_c8_8(ptr, "[:>:]]", 6) == 0: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% 5))
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ptr[2] == 60: 1 else: 0) != 0:
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150039552)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150170624)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
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
                                    (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% 11))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                else:
                                    (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% 16))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (unsafe: *parsed_pattern__goto_3141_11 = 524288)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *parsed_pattern__goto_3141_11 = 2149384192)
                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ptr = ptr + 6
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (okquantifier__goto_3162_6 = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and ((if (if (if (unsafe: *ptr) == 58: 1 else: 0) != 0 or (if (unsafe: *ptr) == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *ptr) == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend__goto_3165_12, (&mut tempptr__goto_3251_14 as *mut *const u8)) != 0: 1 else: 0) != 0:
                                (errorcode__goto_3153_5 = (if ((if (unsafe: *(ptr = ptr - 1)) == 58: 1 else: 0)) != 0: ERR12 else: ERR13))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ptr = (tempptr__goto_3251_14 + (2 as isize as usize)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (class_mode_state__goto_3136_10 = (if ((if ((options & 134217728)) != 0: 1 else: 0)) != 0: CLASS_MODE_ALT_EXT else: CLASS_MODE_NORMAL))
                            (okquantifier__goto_3162_6 = 1)
                            (class_depth_m1__goto_3148_9 = -1)
                            (class_maxdepth_m1__goto_3149_9 = -1)
                            (class_range_state__goto_3134_10 = 0)
                            (class_op_state__goto_3135_10 = 0)
                            (class_start__goto_3137_11 = (null as *mut c_uint))
                            while true:
                                char_is_literal__goto_3990_12 = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if inescq__goto_3156_6 != 0:
                                    if (if (if (if c__goto_3131_10 == 92: 1 else: 0) != 0 and (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (inescq__goto_3156_6 = 0)
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
                                    if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR116)
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
                                if (if ((if (if c__goto_3131_10 == 32: 1 else: 0) != 0 or (if c__goto_3131_10 == 9: 1 else: 0) != 0: 1 else: 0)) != 0 and ((if (if ((options & 16777216)) != 0: 1 else: 0) != 0 or (if class_mode_state__goto_3136_10 >= 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                    __pc = 5
                                    __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if (if (if (if class_depth_m1__goto_3148_9 >= 0: 1 else: 0) != 0 and (if c__goto_3131_10 == 91: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0: 1 else: 0) != 0 and ((if (if (if (unsafe: *ptr) == 58: 1 else: 0) != 0 or (if (unsafe: *ptr) == 46: 1 else: 0) != 0: 1 else: 0) != 0 or (if (unsafe: *ptr) == 61: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and check_posix_syntax(ptr, ptrend__goto_3165_12, (&mut tempptr__goto_3251_14 as *mut *const u8)) != 0: 1 else: 0) != 0:
                                    posix_negate__goto_4037_14 = 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if class_range_state__goto_3134_10 == 1: 1 else: 0) != 0:
                                        (ptr = (tempptr__goto_3251_14 + (2 as isize as usize)))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode__goto_3153_5 = ERR50)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if class_range_state__goto_3134_10 == 3: 1 else: 0) != 0:
                                        (ptr = class_range_forbid_ptr__goto_3167_12)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode__goto_3153_5 = ERR50)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if class_op_state__goto_3135_10 == 1: 1 else: 0) != 0 and (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (ptr = (tempptr__goto_3251_14 + (2 as isize as usize)))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode__goto_3153_5 = ERR113)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (unsafe: *ptr) != 58: 1 else: 0) != 0:
                                        (ptr = (tempptr__goto_3251_14 + (2 as isize as usize)))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode__goto_3153_5 = ERR13)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (unsafe: *((ptr = ptr + 1))) == 94: 1 else: 0) != 0:
                                        (posix_negate__goto_4037_14 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (posix_class__goto_4038_13 = check_posix_name(ptr, ((((tempptr__goto_3251_14 as usize -% ptr as usize) / sizeof[u8]())) as c_int)))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (ptr = (tempptr__goto_3251_14 + (2 as isize as usize)))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if posix_class__goto_4038_13 < 0: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR30)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (class_range_state__goto_3134_10 = 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (class_op_state__goto_3135_10 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (unsafe: *parsed_pattern__goto_3141_11 = (if posix_negate__goto_4037_14 != 0: 2149646336 else: 2149580800))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (unsafe: *parsed_pattern__goto_3141_11 = posix_class__goto_4038_13)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if ((if (if c__goto_3131_10 == 91: 1 else: 0) != 0 and ((if (if (if class_depth_m1__goto_3148_9 < 0: 1 else: 0) != 0 or (if class_mode_state__goto_3136_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0 or (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0 or ((if (if c__goto_3131_10 == 40: 1 else: 0) != 0 and (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        start_c__goto_4154_18 = c__goto_3131_10
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if (if start_c__goto_4154_18 == 91: 1 else: 0) != 0 and (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0) != 0 and (if class_depth_m1__goto_3148_9 >= 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (new_class_mode_state__goto_4155_18 = 3)
                                        else:
                                            (new_class_mode_state__goto_4155_18 = class_mode_state__goto_3136_10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_range_state__goto_3134_10 == 1: 1 else: 0) != 0:
                                            (parsed_pattern__goto_3141_11[-1] = 45)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if class_op_state__goto_3135_10 == 1: 1 else: 0) != 0 and (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (errorcode__goto_3153_5 = ERR113)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_depth_m1__goto_3148_9 >= (15 - 1): 1 else: 0) != 0:
                                            (ptr = ptr - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (errorcode__goto_3153_5 = ERR107)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (negate_class__goto_3161_6 = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        while true:
                                            if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                                if (if start_c__goto_4154_18 == 40: 1 else: 0) != 0:
                                                    (errorcode__goto_3153_5 = ERR14)
                                                else:
                                                    (errorcode__goto_3153_5 = ERR6)
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
                                            if (if new_class_mode_state__goto_4155_18 == 2: 1 else: 0) != 0:
                                                break
                                            else:
                                                if (if c__goto_3131_10 == 92: 1 else: 0) != 0:
                                                    if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 69: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = ptr + 1)
                                                    else:
                                                        if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) >= 3: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, "Q\\E", 3) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
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
                                        if (if (if (if c__goto_3131_10 == 93: 1 else: 0) != 0 and (if ((cb.external_options & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if new_class_mode_state__goto_4155_18 < 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            if (if class_start__goto_3137_11 != (null as *mut c_uint): 1 else: 0) != 0:
                                                (unsafe: *class_start__goto_3137_11) = (unsafe: *class_start__goto_3137_11) | 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (class_start__goto_3137_11 = (null as *mut c_uint))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern__goto_3141_11 = (if negate_class__goto_3161_6 != 0: 2148270080 else: 2148204544))
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if class_depth_m1__goto_3148_9 < 0: 1 else: 0) != 0:
                                                break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_range_state__goto_3134_10 = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_op_state__goto_3135_10 = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 5
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_start__goto_3137_11 != (null as *mut c_uint): 1 else: 0) != 0:
                                            (unsafe: *class_start__goto_3137_11) = (unsafe: *class_start__goto_3137_11) | 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_start__goto_3137_11 = (null as *mut c_uint))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_start__goto_3137_11 = parsed_pattern__goto_3141_11)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern__goto_3141_11 = (if negate_class__goto_3161_6 != 0: 2148401152 else: 2148139008))
                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_range_state__goto_3134_10 = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_op_state__goto_3135_10 = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_mode_state__goto_3136_10 = new_class_mode_state__goto_4155_18)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (class_depth_m1__goto_3148_9 = class_depth_m1__goto_3148_9 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if class_maxdepth_m1__goto_3149_9 < class_depth_m1__goto_3148_9: 1 else: 0) != 0:
                                            (class_maxdepth_m1__goto_3149_9 = class_depth_m1__goto_3148_9)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        ((&cb.class_op_used[0] as *mut u8)[class_depth_m1__goto_3148_9] = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if c__goto_3131_10 == 93: 1 else: 0) != 0 and (if new_class_mode_state__goto_4155_18 != 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (class_range_state__goto_3134_10 = 5)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_op_state__goto_3135_10 = 1)
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
                                        if (if (if c__goto_3131_10 == 93: 1 else: 0) != 0 or ((if (if c__goto_3131_10 == 41: 1 else: 0) != 0 and (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                            if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0:
                                                if (if (if c__goto_3131_10 == 93: 1 else: 0) != 0 and (if class_depth_m1__goto_3148_9 != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode__goto_3153_5 = ERR14)
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
                                                if (if (if c__goto_3131_10 == 41: 1 else: 0) != 0 and (if class_depth_m1__goto_3148_9 < 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode__goto_3153_5 = ERR22)
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
                                            if (if class_op_state__goto_3135_10 == 2: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR110)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0 and (if class_op_state__goto_3135_10 == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR114)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if class_range_state__goto_3134_10 == 1: 1 else: 0) != 0:
                                                (parsed_pattern__goto_3141_11[-1] = 45)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern__goto_3141_11 = 2148335616)
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (class_depth_m1__goto_3148_9 = class_depth_m1__goto_3148_9 - 1) < 0: 1 else: 0) != 0:
                                                if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0:
                                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (errorcode__goto_3153_5 = ERR115)
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
                                            (class_range_state__goto_3134_10 = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_op_state__goto_3135_10 = 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if class_mode_state__goto_3136_10 == 3: 1 else: 0) != 0:
                                                (class_mode_state__goto_3136_10 = 2)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (class_start__goto_3137_11 = (null as *mut c_uint))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            if (if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0 and ((if (if (if (if (if c__goto_3131_10 == 43: 1 else: 0) != 0 or (if c__goto_3131_10 == 124: 1 else: 0) != 0: 1 else: 0) != 0 or (if c__goto_3131_10 == 45: 1 else: 0) != 0: 1 else: 0) != 0 or (if c__goto_3131_10 == 38: 1 else: 0) != 0: 1 else: 0) != 0 or (if c__goto_3131_10 == 94: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                if (if class_op_state__goto_3135_10 != 1: 1 else: 0) != 0:
                                                    (errorcode__goto_3153_5 = ERR109)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    __pc = 19
                                                    __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if class_start__goto_3137_11 != (null as *mut c_uint): 1 else: 0) != 0:
                                                    (unsafe: *class_start__goto_3137_11) = (unsafe: *class_start__goto_3137_11) | 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (class_start__goto_3137_11 = (null as *mut c_uint))
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern__goto_3141_11 = (if (if c__goto_3131_10 == 43: 1 else: 0) != 0: 2152005632 else: (if (if c__goto_3131_10 == 124: 1 else: 0) != 0: 2152005632 else: (if (if c__goto_3131_10 == 45: 1 else: 0) != 0: 2152071168 else: (if (if c__goto_3131_10 == 38: 1 else: 0) != 0: 2151940096 else: 2152136704)))))
                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (class_range_state__goto_3134_10 = 0)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (class_op_state__goto_3135_10 = 2)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                if (if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0 and (if c__goto_3131_10 == 33: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    if (if class_op_state__goto_3135_10 == 1: 1 else: 0) != 0:
                                                        (errorcode__goto_3153_5 = ERR113)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        __pc = 19
                                                        __goto_pending = 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    if (if class_start__goto_3137_11 != (null as *mut c_uint): 1 else: 0) != 0:
                                                        (unsafe: *class_start__goto_3137_11) = (unsafe: *class_start__goto_3137_11) | 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (class_start__goto_3137_11 = (null as *mut c_uint))
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2152202240)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (class_range_state__goto_3134_10 = 0)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (class_op_state__goto_3135_10 = 2)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    if (if (if (if (if class_mode_state__goto_3136_10 == 1: 1 else: 0) != 0 and ((if (if (if (if c__goto_3131_10 == 124: 1 else: 0) != 0 or (if c__goto_3131_10 == 45: 1 else: 0) != 0: 1 else: 0) != 0 or (if c__goto_3131_10 == 38: 1 else: 0) != 0: 1 else: 0) != 0 or (if c__goto_3131_10 == 126: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0 and (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) == c__goto_3131_10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (ptr = ptr + 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == c__goto_3131_10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            while (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == c__goto_3131_10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                (ptr = ptr + 1)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (errorcode__goto_3153_5 = ERR108)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            __pc = 19
                                                            __goto_pending = 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if class_op_state__goto_3135_10 != 1: 1 else: 0) != 0:
                                                            (errorcode__goto_3153_5 = ERR109)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            __pc = 19
                                                            __goto_pending = 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if (if (&cb.class_op_used[0] as *mut u8)[class_depth_m1__goto_3148_9] != 0: 1 else: 0) != 0 and (if (&cb.class_op_used[0] as *mut u8)[class_depth_m1__goto_3148_9] != (c__goto_3131_10 as u8): 1 else: 0) != 0: 1 else: 0) != 0:
                                                            (errorcode__goto_3153_5 = ERR111)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            __pc = 19
                                                            __goto_pending = 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if class_start__goto_3137_11 != (null as *mut c_uint): 1 else: 0) != 0:
                                                            (unsafe: *class_start__goto_3137_11) = (unsafe: *class_start__goto_3137_11) | 1
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (class_start__goto_3137_11 = (null as *mut c_uint))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        if (if class_range_state__goto_3134_10 == 1: 1 else: 0) != 0:
                                                            (parsed_pattern__goto_3141_11[-1] = 45)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (unsafe: *parsed_pattern__goto_3141_11 = (if (if c__goto_3131_10 == 124: 1 else: 0) != 0: 2152005632 else: (if (if c__goto_3131_10 == 45: 1 else: 0) != 0: 2152071168 else: (if (if c__goto_3131_10 == 38: 1 else: 0) != 0: 2151940096 else: 2152136704))))
                                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (class_range_state__goto_3134_10 = 0)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (class_op_state__goto_3135_10 = 2)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        ((&cb.class_op_used[0] as *mut u8)[class_depth_m1__goto_3148_9] = (c__goto_3131_10 as u8))
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    else:
                                                        if (if c__goto_3131_10 == 92: 1 else: 0) != 0:
                                                            (tempptr__goto_3251_14 = ptr)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (escape__goto_3154_5 = _pcre2_check_escape_8((&mut ptr as *mut *const u8), ptrend__goto_3165_12, (&mut c__goto_3131_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), options, xoptions, cb.bracount, 1, cb))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
                                                                if (if (if ((xoptions & 2)) == 0: 1 else: 0) != 0 or (if class_mode_state__goto_3136_10 >= 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                (ptr = tempptr__goto_3251_14)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                                                    (c__goto_3131_10 = 92)
                                                                else:
                                                                    0
                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                        break
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                (escape__goto_3154_5 = 0)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            match escape__goto_3154_5
                                                                0 =>
                                                                    (char_is_literal__goto_3990_12 = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (c__goto_3131_10 = 8)
                                                                    (char_is_literal__goto_3990_12 = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (c__goto_3131_10 = 107)
                                                                    (char_is_literal__goto_3990_12 = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (inescq__goto_3156_6 = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode__goto_3153_5 = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_b =>
                                                                    (c__goto_3131_10 = 8)
                                                                    (char_is_literal__goto_3990_12 = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (c__goto_3131_10 = 107)
                                                                    (char_is_literal__goto_3990_12 = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (inescq__goto_3156_6 = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode__goto_3153_5 = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_k =>
                                                                    (c__goto_3131_10 = 107)
                                                                    (char_is_literal__goto_3990_12 = 0)
                                                                    __pc = 4
                                                                    __goto_pending = 1
                                                                    (inescq__goto_3156_6 = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode__goto_3153_5 = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_Q =>
                                                                    (inescq__goto_3156_6 = 1)
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode__goto_3153_5 = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_E =>
                                                                    __pc = 5
                                                                    __goto_pending = 1
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode__goto_3153_5 = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_B =>
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                    (errorcode__goto_3153_5 = ERR71)
                                                                    __pc = 19
                                                                    __goto_pending = 1
                                                                ESC_N =>
                                                                    (errorcode__goto_3153_5 = ERR71)
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
                                                            if (if class_range_state__goto_3134_10 == 1: 1 else: 0) != 0:
                                                                (errorcode__goto_3153_5 = ERR50)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            if (if class_range_state__goto_3134_10 == 3: 1 else: 0) != 0:
                                                                (ptr = class_range_forbid_ptr__goto_3167_12)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                (errorcode__goto_3153_5 = ERR50)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            if (if (if class_op_state__goto_3135_10 == 1: 1 else: 0) != 0 and (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                (errorcode__goto_3153_5 = ERR113)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (class_range_state__goto_3134_10 = 2)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (class_op_state__goto_3135_10 = 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        else:
                                                            if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0:
                                                                (errorcode__goto_3153_5 = ERR116)
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                                __pc = 19
                                                                __goto_pending = 1
                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                    break
                                                            else:
                                                                if (if (if c__goto_3131_10 == 45: 1 else: 0) != 0 and (if class_range_state__goto_3134_10 >= 4: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                    (unsafe: *parsed_pattern__goto_3141_11 = (if ((if class_range_state__goto_3134_10 == 5: 1 else: 0)) != 0: 2149777408 else: 2149711872))
                                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                        break
                                                                    (class_range_state__goto_3134_10 = 1)
                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                        break
                                                                else:
                                                                    if (if (if c__goto_3131_10 == 45: 1 else: 0) != 0 and (if class_range_state__goto_3134_10 == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                        (unsafe: *parsed_pattern__goto_3141_11 = 45)
                                                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                        (class_range_state__goto_3134_10 = 3)
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                        (class_range_forbid_ptr__goto_3167_12 = ptr)
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                    else:
                                                                        if (if (if class_op_state__goto_3135_10 == 1: 1 else: 0) != 0 and (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                            (errorcode__goto_3153_5 = ERR113)
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                            __pc = 19
                                                                            __goto_pending = 1
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                                                        if (if class_range_state__goto_3134_10 == 1: 1 else: 0) != 0:
                                                                            if (if c__goto_3131_10 == parsed_pattern__goto_3141_11[-2]: 1 else: 0) != 0:
                                                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 - 1)
                                                                            else:
                                                                                if (if parsed_pattern__goto_3141_11[-2] > c__goto_3131_10: 1 else: 0) != 0:
                                                                                    (errorcode__goto_3153_5 = ERR8)
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                                    __pc = 19
                                                                                    __goto_pending = 1
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                                else:
                                                                                    if (if (if char_is_literal__goto_3990_12 != 0: 0 else: 1) != 0 and (if parsed_pattern__goto_3141_11[-1] == 2149777408: 1 else: 0) != 0: 1 else: 0) != 0:
                                                                                        (parsed_pattern__goto_3141_11[-1] = (2149711872 as c_uint))
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                                    0
                                                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                        break
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                            (class_range_state__goto_3134_10 = 0)
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                            (class_op_state__goto_3135_10 = 1)
                                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                break
                                                                        else:
                                                                            if (if class_range_state__goto_3134_10 == 3: 1 else: 0) != 0:
                                                                                (ptr = class_range_forbid_ptr__goto_3167_12)
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                (errorcode__goto_3153_5 = ERR50)
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                __pc = 19
                                                                                __goto_pending = 1
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                            else:
                                                                                (class_range_state__goto_3134_10 = (if char_is_literal__goto_3990_12 != 0: RANGE_OK_LITERAL else: RANGE_OK_ESCAPED))
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                (class_op_state__goto_3135_10 = 1)
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                                0
                                                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                                    break
                                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                    if (if (if class_mode_state__goto_3136_10 == 2: 1 else: 0) != 0 and (if class_depth_m1__goto_3148_9 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if (if class_mode_state__goto_3136_10 == 1: 1 else: 0) != 0 and (if class_depth_m1__goto_3148_9 == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if class_maxdepth_m1__goto_3149_9 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR112)
                                    else:
                                        (errorcode__goto_3153_5 = ERR6)
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
                            if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                __pc = 18
                                __goto_pending = 1
                            if (if (unsafe: *ptr) != 63: 1 else: 0) != 0:
                                if (if (unsafe: *ptr) != 42: 1 else: 0) != 0:
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if ((options & 8192)) == 0: 1 else: 0) != 0:
                                        if (if cb.bracount >= 65535: 1 else: 0) != 0:
                                            (errorcode__goto_3153_5 = ERR97)
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
                                        (unsafe: *parsed_pattern__goto_3141_11 = ((2148007936 as c_uint) | cb.bracount))
                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *parsed_pattern__goto_3141_11 = 2149449728)
                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or (if ((c__goto_3131_10 = ptr[1])) == 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        break
                                    else:
                                        if (if 1 != 0 and (if ((cb.ctypes[c__goto_3131_10] & 4)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (vn__goto_4741_19 = (&alasnames[0] as *mut c_char))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, 0, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                __pc = 19
                                                __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                                __pc = 18
                                                __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (unsafe: *ptr) != 58: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR95)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 21
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i__goto_3155_5 = 0)
                                            while (if i__goto_3155_5 < 19: 1 else: 0) != 0:
                                                if (if (if namelen__goto_3133_10 == (&alasmeta[0] as *mut alasitem)[i__goto_3155_5].len: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name__goto_3164_12, vn__goto_4741_19, namelen__goto_3133_10) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                vn__goto_4741_19 = vn__goto_4741_19 + ((&alasmeta[0] as *mut alasitem)[i__goto_3155_5].len +% 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (i__goto_3155_5 = i__goto_3155_5 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if i__goto_3155_5 >= 19: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR95)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (meta__goto_4776_18 = (&alasmeta[0] as *mut alasitem)[i__goto_3155_5].meta)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if prev_expect_cond_assert__goto_3244_7 > 0: 1 else: 0) != 0 and ((if (if meta__goto_4776_18 < 2150039552: 1 else: 0) != 0 or (if meta__goto_4776_18 > 2150236160: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR28)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            match meta__goto_4776_18
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
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2148990976)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, 0, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                                    if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
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
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2148990976)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, 0, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                                    if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
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
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2148990976)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, 0, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                                    if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
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
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2148990976)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, 0, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                                    if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
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
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2148990976)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, 0, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                                    if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
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
                                                    (errorcode__goto_3153_5 = ERR89)
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
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2148990976)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, 0, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                                    if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
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
                                            (vn__goto_4741_19 = (&verbnames[0] as *mut c_char))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, 0, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                __pc = 19
                                                __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or ((if (if (unsafe: *ptr) != 58: 1 else: 0) != 0 and (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR60)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i__goto_3155_5 = 0)
                                            while (if i__goto_3155_5 < 9: 1 else: 0) != 0:
                                                if (if (if namelen__goto_3133_10 == (&verbs[0] as *mut verbitem)[i__goto_3155_5].len: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name__goto_3164_12, vn__goto_4741_19, namelen__goto_3133_10) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                vn__goto_4741_19 = vn__goto_4741_19 + ((&verbs[0] as *mut verbitem)[i__goto_3155_5].len +% 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (i__goto_3155_5 = i__goto_3155_5 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if i__goto_3155_5 >= 9: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR60)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if (if (unsafe: *ptr) == 58: 1 else: 0) != 0 and (if (ptr + (1 as isize as usize)) < ptrend__goto_3165_12: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (ptr = ptr + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if (&verbs[0] as *mut verbitem)[i__goto_3155_5].has_arg > 0: 1 else: 0) != 0 and (if (unsafe: *ptr) != 58: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR66)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (verbstartptr__goto_3139_11 = parsed_pattern__goto_3141_11)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (okquantifier__goto_3162_6 = ((if (&verbs[0] as *mut verbitem)[i__goto_3155_5].meta == 2150498304: 1 else: 0)))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (unsafe: *(ptr = ptr + 1)) == 58: 1 else: 0) != 0:
                                                if (if (&verbs[0] as *mut verbitem)[i__goto_3155_5].has_arg < 0: 1 else: 0) != 0:
                                                    (add_after_mark__goto_3146_10 = (&verbs[0] as *mut verbitem)[i__goto_3155_5].meta)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150432768)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    (unsafe: *parsed_pattern__goto_3141_11 = ((&verbs[0] as *mut verbitem)[i__goto_3155_5].meta +% ((if ((if (&verbs[0] as *mut verbitem)[i__goto_3155_5].meta != 2150432768: 1 else: 0)) != 0: 65536 else: 0))))
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (verblengthptr__goto_3138_11 = parsed_pattern__goto_3141_11)
                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (verbnamestart__goto_3166_12 = ptr)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (inverbname__goto_3157_6 = 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                (unsafe: *parsed_pattern__goto_3141_11 = (&verbs[0] as *mut verbitem)[i__goto_3155_5].meta)
                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (ptr = ptr + 1) >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                __pc = 18
                                __goto_pending = 1
                            match (unsafe: *ptr)
                                80 =>
                                    if (if (ptr = ptr + 1) >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    if (if (unsafe: *ptr) == 60: 1 else: 0) != 0:
                                        (terminator__goto_3248_12 = 62)
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
                                        (errorcode__goto_3153_5 = ERR41)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 21
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, 41, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2147745792)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (unsafe: *parsed_pattern__goto_3141_11 = namelen__goto_3133_10)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    0
                                    (okquantifier__goto_3162_6 = 1)
                                82 =>
                                    (i__goto_3155_5 = 0)
                                    (ptr = ptr + 1)
                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or ((if (if (unsafe: *ptr) != 41: 1 else: 0) != 0 and (if (unsafe: *ptr) != 40: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR58)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (terminator__goto_3248_12 = 0)
                                    __pc = 7
                                    __goto_pending = 1
                                    if (if (ptr + (1 as isize as usize)) >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 18
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (terminator__goto_3248_12 = 0)
                                    (unsafe: *parsed_pattern__goto_3141_11 = ((2149842944 as c_uint) | (i__goto_3155_5 as c_uint)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (offset__goto_3252_14 = ((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_ulong))
                                    __pc = 9
                                    __goto_pending = 1
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, 0, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2149908480)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (unsafe: *parsed_pattern__goto_3141_11 = namelen__goto_3133_10)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (terminator__goto_3248_12 = 0)
                                    0
                                    (okquantifier__goto_3162_6 = 1)
                                    if (if terminator__goto_3248_12 != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, offset__goto_3252_14, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                43 =>
                                    if (if (ptr + (1 as isize as usize)) >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 18
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (terminator__goto_3248_12 = 0)
                                    (unsafe: *parsed_pattern__goto_3141_11 = ((2149842944 as c_uint) | (i__goto_3155_5 as c_uint)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (offset__goto_3252_14 = ((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_ulong))
                                    __pc = 9
                                    __goto_pending = 1
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, 0, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2149908480)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (unsafe: *parsed_pattern__goto_3141_11 = namelen__goto_3133_10)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (terminator__goto_3248_12 = 0)
                                    0
                                    (okquantifier__goto_3162_6 = 1)
                                    if (if terminator__goto_3248_12 != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, offset__goto_3252_14, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                48 =>
                                    (terminator__goto_3248_12 = 0)
                                    (unsafe: *parsed_pattern__goto_3141_11 = ((2149842944 as c_uint) | (i__goto_3155_5 as c_uint)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (offset__goto_3252_14 = ((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_ulong))
                                    __pc = 9
                                    __goto_pending = 1
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, 0, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2149908480)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (unsafe: *parsed_pattern__goto_3141_11 = namelen__goto_3133_10)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (terminator__goto_3248_12 = 0)
                                    0
                                    (okquantifier__goto_3162_6 = 1)
                                    if (if terminator__goto_3248_12 != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, offset__goto_3252_14, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                38 =>
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, 0, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2149908480)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (unsafe: *parsed_pattern__goto_3141_11 = namelen__goto_3133_10)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (terminator__goto_3248_12 = 0)
                                    0
                                    (okquantifier__goto_3162_6 = 1)
                                    if (if terminator__goto_3248_12 != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 40: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern__goto_3141_11 = parse_capture_list((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, parsed_pattern__goto_3141_11, offset__goto_3252_14, (&mut errorcode__goto_3153_5 as *mut c_int), cb))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if parsed_pattern__goto_3141_11 == (null as *mut c_uint): 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (ptr = ptr + 1)
                                67 =>
                                    if (if ((xoptions & 32768)) != 0: 1 else: 0) != 0:
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (errorcode__goto_3153_5 = ERR103)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (ptr = ptr + 1) >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (expect_cond_assert__goto_3152_5 = (prev_expect_cond_assert__goto_3244_7 - 1))
                                    if (if (if (if (if previous_callout__goto_3140_11 != (null as *mut c_uint): 1 else: 0) != 0 and (if ((options & 4)) != 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if previous_callout__goto_3140_11 == (parsed_pattern__goto_3141_11 - (4 as isize as usize)): 1 else: 0) != 0: 1 else: 0) != 0 and (if parsed_pattern__goto_3141_11[-1] == 255: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (parsed_pattern__goto_3141_11 = previous_callout__goto_3140_11)
                                    (previous_callout__goto_3140_11 = parsed_pattern__goto_3141_11)
                                    (after_manual_callout__goto_3151_5 = 1)
                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR39)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (ptr = ptr + 1)
                                    (previous_callout__goto_3140_11[1] = ((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_uint))
                                    (previous_callout__goto_3140_11[2] = 0)
                                40 =>
                                    if (if (ptr = ptr + 1) >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                        __pc = 18
                                        __goto_pending = 1
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if (if (unsafe: *ptr) == 63: 1 else: 0) != 0 or (if (unsafe: *ptr) == 42: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *parsed_pattern__goto_3141_11 = 2148466688)
                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (ptr = ptr - 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (expect_cond_assert__goto_3152_5 = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if read_number((&mut ptr as *mut *const u8), ptrend__goto_3165_12, cb.bracount, 65535, 161, (&mut i__goto_3155_5 as *mut c_int), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0:
                                        if (if i__goto_3155_5 <= 0: 1 else: 0) != 0:
                                            (errorcode__goto_3153_5 = ERR15)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern__goto_3141_11 = 2148663296)
                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (offset__goto_3252_14 = (((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]()) - 2)) as c_ulong))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern__goto_3141_11 = i__goto_3155_5)
                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        if (if errorcode__goto_3153_5 != 0: 1 else: 0) != 0:
                                            __pc = 19
                                            __goto_pending = 1
                                        else:
                                            if (if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) >= 10: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(ptr, "VERSION", 7) == 0: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[7] != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                ge__goto_5488_18 = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                major__goto_5489_13 = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                minor__goto_5490_13 = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                ptr = ptr + 7
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (unsafe: *ptr) == 62: 1 else: 0) != 0:
                                                    (ge__goto_5488_18 = 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if read_number((&mut ptr as *mut *const u8), ptrend__goto_3165_12, -1, 1000, 179, (&mut major__goto_5489_13 as *mut c_int), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0: 0 else: 1) != 0:
                                                    __pc = 19
                                                    __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 46: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    if (if read_number((&mut ptr as *mut *const u8), ptrend__goto_3165_12, -1, 1000, 179, (&mut minor__goto_5490_13 as *mut c_int), (&mut errorcode__goto_3153_5 as *mut c_int)) != 0: 0 else: 1) != 0:
                                                        __pc = 19
                                                        __goto_pending = 1
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (errorcode__goto_3153_5 = ERR79)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0:
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
                                                (unsafe: *parsed_pattern__goto_3141_11 = 2148859904)
                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern__goto_3141_11 = ge__goto_5488_18)
                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern__goto_3141_11 = major__goto_5489_13)
                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (unsafe: *parsed_pattern__goto_3141_11 = minor__goto_5490_13)
                                                (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            else:
                                                was_r_ampersand__goto_5544_14 = 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (if (if (unsafe: *ptr) == 82: 1 else: 0) != 0 and (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) > 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] == 38: 1 else: 0) != 0: 1 else: 0) != 0:
                                                    (terminator__goto_3248_12 = 41)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (was_r_ampersand__goto_5544_14 = 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr + 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    if (if (unsafe: *ptr) == 60: 1 else: 0) != 0:
                                                        (terminator__goto_3248_12 = 62)
                                                    else:
                                                        if (if (unsafe: *ptr) == 39: 1 else: 0) != 0:
                                                            (terminator__goto_3248_12 = 39)
                                                        else:
                                                            (terminator__goto_3248_12 = 41)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                            (ptr = ptr - 1)
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, terminator__goto_3248_12, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                                    __pc = 19
                                                    __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if was_r_ampersand__goto_5544_14 != 0:
                                                    ((unsafe: *parsed_pattern__goto_3141_11) = (2148728832 as c_uint))
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                    (ptr = ptr - 1)
                                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                                        break
                                                else:
                                                    if (if terminator__goto_3248_12 == 41: 1 else: 0) != 0:
                                                        if (if (if namelen__goto_3133_10 == 6: 1 else: 0) != 0 and (if _pcre2_strncmp_c8_8(name__goto_3164_12, "DEFINE", 6) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                                            ((unsafe: *parsed_pattern__goto_3141_11) = (2148532224 as c_uint))
                                                        else:
                                                            ((unsafe: *parsed_pattern__goto_3141_11) = (if ((if (if (unsafe: *name__goto_3164_12) == 82: 1 else: 0) != 0 and (if i__goto_3155_5 >= (namelen__goto_3133_10 as c_int): 1 else: 0) != 0: 1 else: 0)) != 0: 2148794368 else: 2148597760))
                                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                                break
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (ptr = ptr - 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    else:
                                                        ((unsafe: *parsed_pattern__goto_3141_11) = (2148597760 as c_uint))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                if (if (unsafe: *(parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)) != 2148532224: 1 else: 0) != 0:
                                                    (unsafe: *parsed_pattern__goto_3141_11 = namelen__goto_3133_10)
                                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                    if (if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0 or (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR24)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (ptr = ptr + 1)
                                62 =>
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2147614720)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    (ptr = ptr + 1)
                                61 =>
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150039552)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150301696)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150105088)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator__goto_3248_12 = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern__goto_3141_11 = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    (offset__goto_3252_14 = (((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]()) - 2)) as c_ulong))
                                    0
                                    ptr = ptr + 2
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if prev_expect_cond_assert__goto_3244_7 > 0: 1 else: 0) != 0:
                                        if (if top_nest__goto_3169_12 == (null as *mut nest_save): 1 else: 0) != 0:
                                            (top_nest__goto_3169_12 = ((cb.start_workspace) as *mut nest_save))
                                        else:
                                            if (if (top_nest__goto_3169_12 = top_nest__goto_3169_12 + 1) >= end_nests__goto_3169_23: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR84)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.nest_depth = nest_depth__goto_3147_10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                42 =>
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150301696)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150105088)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator__goto_3248_12 = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern__goto_3141_11 = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    (offset__goto_3252_14 = (((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]()) - 2)) as c_ulong))
                                    0
                                    ptr = ptr + 2
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if prev_expect_cond_assert__goto_3244_7 > 0: 1 else: 0) != 0:
                                        if (if top_nest__goto_3169_12 == (null as *mut nest_save): 1 else: 0) != 0:
                                            (top_nest__goto_3169_12 = ((cb.start_workspace) as *mut nest_save))
                                        else:
                                            if (if (top_nest__goto_3169_12 = top_nest__goto_3169_12 + 1) >= end_nests__goto_3169_23: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR84)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.nest_depth = nest_depth__goto_3147_10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                33 =>
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2150105088)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (ptr = ptr + 1)
                                    __pc = 15
                                    __goto_pending = 1
                                    if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator__goto_3248_12 = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern__goto_3141_11 = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    (offset__goto_3252_14 = (((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]()) - 2)) as c_ulong))
                                    0
                                    ptr = ptr + 2
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if prev_expect_cond_assert__goto_3244_7 > 0: 1 else: 0) != 0:
                                        if (if top_nest__goto_3169_12 == (null as *mut nest_save): 1 else: 0) != 0:
                                            (top_nest__goto_3169_12 = ((cb.start_workspace) as *mut nest_save))
                                        else:
                                            if (if (top_nest__goto_3169_12 = top_nest__goto_3169_12 + 1) >= end_nests__goto_3169_23: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR84)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.nest_depth = nest_depth__goto_3147_10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                60 =>
                                    if (if (if ((ptrend__goto_3165_12 as usize -% ptr as usize) / sizeof[u8]()) <= 1: 1 else: 0) != 0 or ((if (if (if ptr[1] != 61: 1 else: 0) != 0 and (if ptr[1] != 33: 1 else: 0) != 0: 1 else: 0) != 0 and (if ptr[1] != 42: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                        (terminator__goto_3248_12 = 62)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 16
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (unsafe: *parsed_pattern__goto_3141_11 = (if ((if ptr[1] == 61: 1 else: 0)) != 0: 2150170624 else: (if ((if ptr[1] == 33: 1 else: 0)) != 0: 2150236160 else: 2150367232)))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    ((unsafe: *has_lookbehind) = 1)
                                    (offset__goto_3252_14 = (((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]()) - 2)) as c_ulong))
                                    0
                                    ptr = ptr + 2
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if prev_expect_cond_assert__goto_3244_7 > 0: 1 else: 0) != 0:
                                        if (if top_nest__goto_3169_12 == (null as *mut nest_save): 1 else: 0) != 0:
                                            (top_nest__goto_3169_12 = ((cb.start_workspace) as *mut nest_save))
                                        else:
                                            if (if (top_nest__goto_3169_12 = top_nest__goto_3169_12 + 1) >= end_nests__goto_3169_23: 1 else: 0) != 0:
                                                (errorcode__goto_3153_5 = ERR84)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                __pc = 19
                                                __goto_pending = 1
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.nest_depth = nest_depth__goto_3147_10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.flags = 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                39 =>
                                    (terminator__goto_3248_12 = 39)
                                    if (if read_name((&mut ptr as *mut *const u8), ptrend__goto_3165_12, utf__goto_3158_6, terminator__goto_3248_12, (&mut offset__goto_3252_14 as *mut c_ulong), (&mut name__goto_3164_12 as *mut *const u8), (&mut namelen__goto_3133_10 as *mut c_uint), (&mut errorcode__goto_3153_5 as *mut c_int), cb) != 0: 0 else: 1) != 0:
                                        __pc = 19
                                        __goto_pending = 1
                                    if (if cb.bracount >= 65535: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR97)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    (cb.bracount = cb.bracount + 1)
                                    (unsafe: *parsed_pattern__goto_3141_11 = ((2148007936 as c_uint) | cb.bracount))
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if cb.names_found >= 10000: 1 else: 0) != 0:
                                        (errorcode__goto_3153_5 = ERR49)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        __pc = 19
                                        __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if ((namelen__goto_3133_10 +% 2) +% 1) > cb.name_entry_size: 1 else: 0) != 0:
                                        (cb.name_entry_size = ((((namelen__goto_3133_10 +% 2) +% 1)) as c_ushort))
                                    (is_dupname__goto_3160_6 = 0)
                                    (hash__goto_3150_10 = _pcre2_compile_get_hash_from_name8(name__goto_3164_12, namelen__goto_3133_10))
                                    (ng__goto_3168_14 = cb.named_groups)
                                    if (if i__goto_3155_5 < cb.names_found: 1 else: 0) != 0:
                                        break
                                    if (if cb.names_found >= cb.named_group_list_size: 1 else: 0) != 0:
                                        newsize__goto_5787_18 = (cb.named_group_list_size *% 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        newspace__goto_5788_22 = (cb.cx.memctl.malloc((newsize__goto_5787_18 *% sizeof[named_group_8]()), cb.cx.memctl.memory_data) as *mut named_group_8)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if newspace__goto_5788_22 == (null as *mut named_group_8): 1 else: 0) != 0:
                                            (errorcode__goto_3153_5 = ERR21)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        with_memcpy((newspace__goto_5788_22 as *mut c_void) as *i8, (cb.named_groups as *const c_void) as *i8, (cb.named_group_list_size *% sizeof[named_group_8]()) as i64)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if cb.named_group_list_size > 20: 1 else: 0) != 0:
                                            cb.cx.memctl.free((cb.named_groups as *mut c_void), cb.cx.memctl.memory_data)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.named_groups = newspace__goto_5788_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.named_group_list_size = newsize__goto_5787_18)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if is_dupname__goto_3160_6 != 0:
                                        hash__goto_3150_10 = hash__goto_3150_10 | 32768
                                    (cb.named_groups[cb.names_found].name = name__goto_3164_12)
                                    (cb.named_groups[cb.names_found].length = (namelen__goto_3133_10 as c_ushort))
                                    (cb.named_groups[cb.names_found].number = cb.bracount)
                                    (cb.named_groups[cb.names_found].hash_dup = hash__goto_3150_10)
                                    (cb.names_found = cb.names_found + 1)
                                91 =>
                                    (class_mode_state__goto_3136_10 = 2)
                                    (c__goto_3131_10 = (unsafe: *(ptr = ptr + 1)))
                                    __pc = 3
                                    __goto_pending = 1
                                _ =>
                                    (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 + 1)
                                    if (if top_nest__goto_3169_12 == (null as *mut nest_save): 1 else: 0) != 0:
                                        (top_nest__goto_3169_12 = ((cb.start_workspace) as *mut nest_save))
                                    else:
                                        if (if (top_nest__goto_3169_12 = top_nest__goto_3169_12 + 1) >= end_nests__goto_3169_23: 1 else: 0) != 0:
                                            (errorcode__goto_3153_5 = ERR84)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            __pc = 19
                                            __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                    (top_nest__goto_3169_12.nest_depth = nest_depth__goto_3147_10)
                                    (top_nest__goto_3169_12.flags = 0)
                                    if (if (unsafe: *ptr) == 124: 1 else: 0) != 0:
                                        (top_nest__goto_3169_12.reset_group = (cb.bracount as c_ushort))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.max_group = (cb.bracount as c_ushort))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        top_nest__goto_3169_12.flags = top_nest__goto_3169_12.flags | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        cb.external_flags = cb.external_flags | 2097152
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *parsed_pattern__goto_3141_11 = 2149449728)
                                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (ptr = ptr + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        hyphenok__goto_5041_14 = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        oldoptions__goto_5042_18 = options
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        oldxoptions__goto_5043_18 = xoptions
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.reset_group = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (top_nest__goto_3169_12.max_group = 0)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unset__goto_3246_17 = 0)
                                        (set__goto_3246_12 = unset__goto_3246_17)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (optset__goto_3246_25 = (&mut set__goto_3246_12 as *mut c_uint))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (xunset__goto_3247_18 = 0)
                                        (xset__goto_3247_12 = xunset__goto_3247_18)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (xoptset__goto_3247_27 = (&mut xset__goto_3247_12 as *mut c_uint))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 94: 1 else: 0) != 0: 1 else: 0) != 0:
                                            options = options & (0 - ((((((8 | 1024) | 8192) | 32) | 128) | 16777216)) - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            xoptions = xoptions & (0 - (128) - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (hyphenok__goto_5041_14 = 0)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (ptr = ptr + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        while (if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) != 41: 1 else: 0) != 0: 1 else: 0) != 0 and (if (unsafe: *ptr) != 58: 1 else: 0) != 0: 1 else: 0) != 0:
                                            match (unsafe: *(ptr = ptr + 1))
                                                45 =>
                                                    if (if hyphenok__goto_5041_14 != 0: 0 else: 1) != 0:
                                                        (errorcode__goto_3153_5 = ERR94)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        __pc = 19
                                                        __goto_pending = 1
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                    (optset__goto_3246_25 = (&mut unset__goto_3246_17 as *mut c_uint))
                                                    (xoptset__goto_3247_27 = (&mut xunset__goto_3247_18 as *mut c_uint))
                                                    (hyphenok__goto_5041_14 = 0)
                                                97 =>
                                                    if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0:
                                                        if (if (unsafe: *ptr) == 68: 1 else: 0) != 0:
                                                            (unsafe: *xoptset__goto_3247_27) = (unsafe: *xoptset__goto_3247_27) | 256
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
                                                            (unsafe: *xoptset__goto_3247_27) = (unsafe: *xoptset__goto_3247_27) | ((2048 | 4096))
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
                                                            (unsafe: *xoptset__goto_3247_27) = (unsafe: *xoptset__goto_3247_27) | 512
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
                                                            (unsafe: *xoptset__goto_3247_27) = (unsafe: *xoptset__goto_3247_27) | 4096
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
                                                            (unsafe: *xoptset__goto_3247_27) = (unsafe: *xoptset__goto_3247_27) | 1024
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
                                                    (unsafe: *xoptset__goto_3247_27) = (unsafe: *xoptset__goto_3247_27) | ((((256 | 512) | 1024) | 4096) | 2048)
                                                74 =>
                                                    (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 64
                                                    cb.external_flags = cb.external_flags | 1024
                                                105 =>
                                                    (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 8
                                                109 =>
                                                    (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 1024
                                                110 =>
                                                    (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 8192
                                                114 =>
                                                    (unsafe: *xoptset__goto_3247_27) = (unsafe: *xoptset__goto_3247_27) | 128
                                                115 =>
                                                    (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 32
                                                85 =>
                                                    (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 262144
                                                120 =>
                                                    (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 128
                                                    if (if (if ptr < ptrend__goto_3165_12: 1 else: 0) != 0 and (if (unsafe: *ptr) == 120: 1 else: 0) != 0: 1 else: 0) != 0:
                                                        (unsafe: *optset__goto_3246_25) = (unsafe: *optset__goto_3246_25) | 16777216
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                        (ptr = ptr + 1)
                                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                                            break
                                                _ =>
                                                    (errorcode__goto_3153_5 = ERR11)
                                                    __pc = 19
                                                    __goto_pending = 1
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if ((set__goto_3246_12 & ((128 | 16777216)))) == 128: 1 else: 0) != 0 or (if ((unset__goto_3246_17 & 128)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                            unset__goto_3246_17 = unset__goto_3246_17 | 16777216
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (options = (((options | set__goto_3246_12)) & ((0 - unset__goto_3246_17 - 1))))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (xoptions = (((xoptions | xset__goto_3247_12)) & ((0 - xunset__goto_3247_18 - 1))))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0:
                                            __pc = 18
                                            __goto_pending = 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (unsafe: *(ptr = ptr + 1)) == 41: 1 else: 0) != 0:
                                            (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 - 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if (if top_nest__goto_3169_12 > ((cb.start_workspace) as *mut nest_save): 1 else: 0) != 0 and (if ((top_nest__goto_3169_12 - (1 as isize as usize))).nest_depth == nest_depth__goto_3147_10: 1 else: 0) != 0: 1 else: 0) != 0:
                                                (top_nest__goto_3169_12 = top_nest__goto_3169_12 - 1)
                                            else:
                                                (top_nest__goto_3169_12.nest_depth = nest_depth__goto_3147_10)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        else:
                                            (unsafe: *parsed_pattern__goto_3141_11 = 2149449728)
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if (if options != oldoptions__goto_5042_18: 1 else: 0) != 0 or (if xoptions != oldxoptions__goto_5043_18: 1 else: 0) != 0: 1 else: 0) != 0:
                                            (unsafe: *parsed_pattern__goto_3141_11 = 2149515264)
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern__goto_3141_11 = options)
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *parsed_pattern__goto_3141_11 = xoptions)
                                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                        124 =>
                            if (if (if (if top_nest__goto_3169_12 != (null as *mut nest_save): 1 else: 0) != 0 and (if top_nest__goto_3169_12.nest_depth == nest_depth__goto_3147_10: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((top_nest__goto_3169_12.flags & 1)) != 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if cb.bracount > top_nest__goto_3169_12.max_group: 1 else: 0) != 0:
                                    (top_nest__goto_3169_12.max_group = (cb.bracount as c_ushort))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.bracount = top_nest__goto_3169_12.reset_group)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *parsed_pattern__goto_3141_11 = 2147549184)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        41 =>
                            (okquantifier__goto_3162_6 = 1)
                            if (if (if top_nest__goto_3169_12 != (null as *mut nest_save): 1 else: 0) != 0 and (if top_nest__goto_3169_12.nest_depth == nest_depth__goto_3147_10: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if (if ((top_nest__goto_3169_12.flags & 1)) != 0: 1 else: 0) != 0 and (if top_nest__goto_3169_12.max_group > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (cb.bracount = top_nest__goto_3169_12.max_group)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((top_nest__goto_3169_12.flags & 2)) != 0: 1 else: 0) != 0:
                                    (okquantifier__goto_3162_6 = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((top_nest__goto_3169_12.flags & 4)) != 0: 1 else: 0) != 0:
                                    (unsafe: *parsed_pattern__goto_3141_11 = 2149384192)
                                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if top_nest__goto_3169_12 == ((cb.start_workspace) as *mut nest_save): 1 else: 0) != 0:
                                    (top_nest__goto_3169_12 = (null as *mut nest_save))
                                else:
                                    (top_nest__goto_3169_12 = top_nest__goto_3169_12 - 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if nest_depth__goto_3147_10 == 0: 1 else: 0) != 0:
                                (errorcode__goto_3153_5 = ERR22)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 19
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (nest_depth__goto_3147_10 = nest_depth__goto_3147_10 - 1)
                            (unsafe: *parsed_pattern__goto_3141_11 = 2149384192)
                            (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        _ =>
                            0
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if inverbname__goto_3157_6 != 0 and (if ptr >= ptrend__goto_3165_12: 1 else: 0) != 0: 1 else: 0) != 0:
                    (errorcode__goto_3153_5 = ERR60)
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
                (parsed_pattern__goto_3141_11 = manage_callouts(ptr, (&mut previous_callout__goto_3140_11 as *mut *mut c_uint), auto_callout__goto_3159_6, parsed_pattern__goto_3141_11, cb))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if ((xoptions & 8)) != 0: 1 else: 0) != 0:
                    (unsafe: *parsed_pattern__goto_3141_11 = 2149384192)
                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (unsafe: *parsed_pattern__goto_3141_11 = 2149187584)
                    (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                else:
                    if (if ((xoptions & 4)) != 0: 1 else: 0) != 0:
                        (unsafe: *parsed_pattern__goto_3141_11 = 2149384192)
                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        (unsafe: *parsed_pattern__goto_3141_11 = ((2149318656 as c_uint) +% 5))
                        (parsed_pattern__goto_3141_11 = parsed_pattern__goto_3141_11 + 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if parsed_pattern__goto_3141_11 >= parsed_pattern_end__goto_3142_11: 1 else: 0) != 0:
                    (errorcode__goto_3153_5 = ERR63)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    __pc = 19
                    __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *parsed_pattern__goto_3141_11) = (2147483648 as c_uint))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                if (if nest_depth__goto_3147_10 == 0: 1 else: 0) != 0:
                    return 0
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 18
                continue
            18 =>  // UNCLOSED_PARENTHESIS
                (__goto_pending = 0)
                (errorcode__goto_3153_5 = ERR14)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 19
                continue
            19 =>  // FAILED
                (__goto_pending = 0)
                (cb.erroroffset = ((((ptr as usize -% cb.start_pattern as usize) / sizeof[u8]())) as c_ulong))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return errorcode__goto_3153_5
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
    var bravalue__goto_6090_5: c_int = 0
    var okreturn__goto_6091_5: c_int = 0
    var group_return__goto_6092_5: c_int = 0
    var repeat_min__goto_6093_10: c_uint = 0
    var repeat_max__goto_6093_26: c_uint = 0
    var greedy_default__goto_6094_10: c_uint = 0
    var greedy_non_default__goto_6094_26: c_uint = 0
    var repeat_type__goto_6095_10: c_uint = 0
    var op_type__goto_6095_23: c_uint = 0
    var options__goto_6096_10: c_uint = 0
    var xoptions__goto_6097_10: c_uint = 0
    var firstcu__goto_6098_10: c_uint = 0
    var reqcu__goto_6098_19: c_uint = 0
    var zeroreqcu__goto_6099_10: c_uint = 0
    var zerofirstcu__goto_6099_21: c_uint = 0
    var pptr__goto_6100_11: *mut c_uint = null
    var meta__goto_6101_10: c_uint = 0
    var meta_arg__goto_6101_16: c_uint = 0
    var firstcuflags__goto_6102_10: c_uint = 0
    var reqcuflags__goto_6102_24: c_uint = 0
    var zeroreqcuflags__goto_6103_10: c_uint = 0
    var zerofirstcuflags__goto_6103_26: c_uint = 0
    var req_caseopt__goto_6104_10: c_uint = 0
    var reqvary__goto_6104_23: c_uint = 0
    var tempreqvary__goto_6104_32: c_uint = 0
    var offset__goto_6107_12: c_ulong = 0
    var length_prevgroup__goto_6108_12: c_ulong = 0
    var code__goto_6109_14: *mut u8 = null
    var last_code__goto_6110_14: *mut u8 = null
    var orig_code__goto_6111_14: *mut u8 = null
    var tempcode__goto_6112_14: *mut u8 = null
    var previous__goto_6113_14: *mut u8 = null
    var op_previous__goto_6114_13: u8 = 0
    var groupsetfirstcu__goto_6115_6: c_int = 0
    var had_accept__goto_6116_6: c_int = 0
    var matched_char__goto_6117_6: c_int = 0
    var previous_matched_char__goto_6118_6: c_int = 0
    var reset_caseful__goto_6119_6: c_int = 0
    var utf__goto_6129_6: c_int = 0
    var possessive_quantifier__goto_6161_8: c_int = 0
    var note_group_empty__goto_6162_8: c_int = 0
    var mclength__goto_6163_12: c_uint = 0
    var skipunits__goto_6164_12: c_uint = 0
    var subreqcu__goto_6165_12: c_uint = 0
    var subfirstcu__goto_6165_22: c_uint = 0
    var groupnumber__goto_6166_12: c_uint = 0
    var verbarglen__goto_6167_12: c_uint = 0
    var verbculen__goto_6167_24: c_uint = 0
    var subreqcuflags__goto_6168_12: c_uint = 0
    var subfirstcuflags__goto_6168_27: c_uint = 0
    var oc__goto_6169_17: *mut open_capitem = null
    var mcbuffer__goto_6170_15: [8]u8 = [0 as u8; 8]
    var c__goto_6366_16: c_uint = 0
    var c__goto_6435_16: c_uint = 0
    var d__goto_6446_18: c_uint = 0
    var i__goto_6561_14: c_int = 0
    var count__goto_6613_11: c_int = 0
    var index__goto_6613_18: c_int = 0
    var ng__goto_6614_20: *mut named_group_8 = null
    var i__goto_6676_16: c_uint = 0
    var name__goto_6677_18: *const u8 = null
    var ng__goto_6678_20: *mut named_group_8 = null
    var start_pptr__goto_6679_17: *mut c_uint = null
    var length__goto_6680_16: c_uint = 0
    var count__goto_6763_11: c_int = 0
    var index__goto_6763_18: c_int = 0
    var ng__goto_6764_20: *mut named_group_8 = null
    var tc__goto_6989_20: *mut u8 = null
    var condcount__goto_6990_11: c_int = 0
    var count__goto_7141_11: c_int = 0
    var index__goto_7141_18: c_int = 0
    var name__goto_7142_18: *const u8 = null
    var ng__goto_7143_20: *mut named_group_8 = null
    var length__goto_7144_16: c_uint = 0
    var pp__goto_7248_18: *const u8 = null
    var delimiter__goto_7249_16: c_uint = 0
    var length__goto_7250_16: c_uint = 0
    var callout_string__goto_7251_20: *mut u8 = null
    var replicate__goto_7482_13: c_int = 0
    var delta__goto_7492_22: c_ulong = 0
    var i__goto_7501_23: c_int = 0
    var length__goto_7518_20: c_ulong = 0
    var len__goto_7553_13: c_int = 0
    var bralink__goto_7554_22: *mut u8 = null
    var brazeroptr__goto_7555_22: *mut u8 = null
    var linkoffset__goto_7631_17: c_int = 0
    var delta__goto_7662_26: c_ulong = 0
    var i__goto_7684_29: c_uint = 0
    var delta__goto_7712_24: c_ulong = 0
    var i__goto_7726_30: c_uint = 0
    var linkoffset__goto_7735_19: c_int = 0
    var oldlinkoffset__goto_7751_17: c_int = 0
    var linkoffset__goto_7752_17: c_int = 0
    var bra__goto_7753_26: *mut u8 = null
    var ketcode__goto_7790_24: *mut u8 = null
    var bracode__goto_7791_24: *mut u8 = null
    var nlen__goto_7830_21: c_int = 0
    var prop_type__goto_7882_13: c_int = 0
    var prop_value__goto_7882_24: c_int = 0
    var oldcode__goto_7883_22: *mut u8 = null
    var len__goto_8038_11: c_int = 0
    var repcode__goto_8103_22: c_uint = 0
    var args__goto_8218_26: *mut recurse_arguments = null
    var current__goto_8232_19: *mut c_ushort = null
    var end__goto_8232_29: *mut c_ushort = null
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                bravalue__goto_6090_5 = 0
                okreturn__goto_6091_5 = -1
                group_return__goto_6092_5 = 0
                repeat_min__goto_6093_10 = 0
                repeat_max__goto_6093_26 = 0
                options__goto_6096_10 = (unsafe: *optionsptr)
                xoptions__goto_6097_10 = (unsafe: *xoptionsptr)
                pptr__goto_6100_11 = (unsafe: *pptrptr)
                offset__goto_6107_12 = 0
                length_prevgroup__goto_6108_12 = 0
                code__goto_6109_14 = (unsafe: *codeptr)
                last_code__goto_6110_14 = code__goto_6109_14
                orig_code__goto_6111_14 = code__goto_6109_14
                previous__goto_6113_14 = (null as *mut u8)
                groupsetfirstcu__goto_6115_6 = 0
                had_accept__goto_6116_6 = 0
                matched_char__goto_6117_6 = 0
                previous_matched_char__goto_6118_6 = 0
                reset_caseful__goto_6119_6 = 0
                utf__goto_6129_6 = 0
                (greedy_default__goto_6094_10 = ((if ((options__goto_6096_10 & 262144)) != 0: 1 else: 0)))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (greedy_non_default__goto_6094_26 = (greedy_default__goto_6094_10 ^ 1))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (zeroreqcu__goto_6099_10 = 0)
                (zerofirstcu__goto_6099_21 = zeroreqcu__goto_6099_10)
                (reqcu__goto_6098_19 = zerofirstcu__goto_6099_21)
                (firstcu__goto_6098_10 = reqcu__goto_6098_19)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (zeroreqcuflags__goto_6103_10 = (4294967295 as c_uint))
                (zerofirstcuflags__goto_6103_26 = zeroreqcuflags__goto_6103_10)
                (reqcuflags__goto_6102_24 = zerofirstcuflags__goto_6103_26)
                (firstcuflags__goto_6102_10 = reqcuflags__goto_6102_24)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                (req_caseopt__goto_6104_10 = (if ((if ((options__goto_6096_10 & 8)) != 0: 1 else: 0)) != 0: 1 else: 0))
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while (pptr__goto_6100_11 = pptr__goto_6100_11 + 1) != null:
                    if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                        if (if code__goto_6109_14 >= (cb.start_workspace + cb.workspace_size): 1 else: 0) != 0:
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
                        if (if code__goto_6109_14 > ((cb.start_workspace + cb.workspace_size) - ((100) as isize as usize)): 1 else: 0) != 0:
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
                        if (if code__goto_6109_14 < last_code__goto_6110_14: 1 else: 0) != 0:
                            (code__goto_6109_14 = last_code__goto_6110_14)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if (if meta__goto_6101_10 < 2151153664: 1 else: 0) != 0 or (if meta__goto_6101_10 > 2151874560: 1 else: 0) != 0: 1 else: 0) != 0:
                            if (if (2147483627 -% (unsafe: *lengthptr)) < ((((code__goto_6109_14 as usize -% orig_code__goto_6111_14 as usize) / sizeof[u8]())) as c_ulong): 1 else: 0) != 0:
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
                            (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((((code__goto_6109_14 as usize -% orig_code__goto_6111_14 as usize) / sizeof[u8]())) as c_ulong)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
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
                            (code__goto_6109_14 = orig_code__goto_6111_14)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        (last_code__goto_6110_14 = code__goto_6109_14)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if (if meta__goto_6101_10 < 2151153664: 1 else: 0) != 0 or (if meta__goto_6101_10 > 2151874560: 1 else: 0) != 0: 1 else: 0) != 0:
                        (previous__goto_6113_14 = code__goto_6109_14)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                        if (if matched_char__goto_6117_6 != 0 and (if had_accept__goto_6116_6 != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                            (okreturn__goto_6091_5 = 1)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            break
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (previous_matched_char__goto_6118_6 = matched_char__goto_6117_6)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (matched_char__goto_6117_6 = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (note_group_empty__goto_6162_8 = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    (skipunits__goto_6164_12 = 0)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    match meta__goto_6101_10
                        2147483648 =>
                            ((unsafe: *firstcuflagsptr) = firstcuflags__goto_6102_10)
                            ((unsafe: *reqcuptr) = reqcu__goto_6098_19)
                            ((unsafe: *reqcuflagsptr) = reqcuflags__goto_6102_24)
                            ((unsafe: *codeptr) = code__goto_6109_14)
                            ((unsafe: *pptrptr) = pptr__goto_6100_11)
                            return okreturn__goto_6091_5
                        2148073472 =>
                            if (if ((options__goto_6096_10 & 1024)) != 0: 1 else: 0) != 0:
                                if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                    (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = 28)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (unsafe: *code__goto_6109_14 = 27)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2149187584 =>
                            (unsafe: *code__goto_6109_14 = (if ((if ((options__goto_6096_10 & 1024)) != 0: 1 else: 0)) != 0: OP_DOLLM else: OP_DOLL))
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2149253120 =>
                            (matched_char__goto_6117_6 = 1)
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            (unsafe: *code__goto_6109_14 = (if ((if ((options__goto_6096_10 & 32)) != 0: 1 else: 0)) != 0: OP_ALLANY else: OP_ANY))
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2148204544 =>
                            if (if meta__goto_6101_10 == 2148270080: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 13)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                            else:
                                (unsafe: *code__goto_6109_14 = 110)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                with_memset((code__goto_6109_14 as *mut c_void) as *i8, 0, 32 as i64)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                code__goto_6109_14 = code__goto_6109_14 + (32 / sizeof[u8]())
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                        2148401152 =>
                            if (if (((unsafe: *pptr__goto_6100_11) & 1)) != 0: 1 else: 0) != 0:
                                if (if _pcre2_compile_class_nested_8(options__goto_6096_10, xoptions__goto_6097_10, (&mut pptr__goto_6100_11 as *mut *mut c_uint), (&mut code__goto_6109_14 as *mut *mut u8), errorcodeptr, cb, lengthptr) != 0: 0 else: 1) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                __pc = 1
                                __goto_pending = 1
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (if pptr__goto_6100_11[1] < 2147483648: 1 else: 0) != 0 and (if pptr__goto_6100_11[2] == 2148335616: 1 else: 0) != 0: 1 else: 0) != 0:
                                c__goto_6366_16 = pptr__goto_6100_11[1]
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta__goto_6101_10 == 2148139008: 1 else: 0) != 0:
                                    (meta__goto_6101_10 = c__goto_6366_16)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 11
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = (if ((if ((options__goto_6096_10 & 8)) != 0: 1 else: 0)) != 0: OP_NOTI else: OP_NOT))
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if (if (if (if meta__goto_6101_10 == 2148139008: 1 else: 0) != 0 and (if pptr__goto_6100_11[1] < 2147483648: 1 else: 0) != 0: 1 else: 0) != 0 and (if pptr__goto_6100_11[2] < 2147483648: 1 else: 0) != 0: 1 else: 0) != 0 and (if pptr__goto_6100_11[3] == 2148335616: 1 else: 0) != 0: 1 else: 0) != 0:
                                c__goto_6435_16 = pptr__goto_6100_11[1]
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (d__goto_6446_18 = ((cb.fcc)[c__goto_6435_16]))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if c__goto_6435_16 != d__goto_6446_18: 1 else: 0) != 0 and (if pptr__goto_6100_11[2] == d__goto_6446_18: 1 else: 0) != 0: 1 else: 0) != 0:
                                    pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (meta__goto_6101_10 = c__goto_6435_16)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if ((options__goto_6096_10 & 8)) == 0: 1 else: 0) != 0:
                                        (reset_caseful__goto_6119_6 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        options__goto_6096_10 = options__goto_6096_10 | 8
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (req_caseopt__goto_6104_10 = 1)
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
                            (pptr__goto_6100_11 = _pcre2_compile_class_not_nested_8(options__goto_6096_10, xoptions__goto_6097_10, (pptr__goto_6100_11 + (1 as isize as usize)), (&mut code__goto_6109_14 as *mut *mut u8), (if meta__goto_6101_10 == 2148401152: 1 else: 0), (null as *mut c_int), errorcodeptr, cb, lengthptr))
                            if (if pptr__goto_6100_11 == (null as *mut c_uint): 1 else: 0) != 0:
                                return 0
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                        2150498304 =>
                            (had_accept__goto_6116_6 = 1)
                            (cb.had_accept = had_accept__goto_6116_6)
                            (oc__goto_6169_17 = open_caps)
                            while (if (if oc__goto_6169_17 != (null as *mut open_capitem): 1 else: 0) != 0 and (if oc__goto_6169_17.assert_depth >= cb.assert_depth: 1 else: 0) != 0: 1 else: 0) != 0:
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + 3
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    (unsafe: *code__goto_6109_14 = 168)
                                    (code__goto_6109_14 = code__goto_6109_14 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (oc__goto_6169_17 = oc__goto_6169_17.next)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (unsafe: *code__goto_6109_14 = (if ((if cb.assert_depth > 0: 1 else: 0)) != 0: OP_ASSERT_ACCEPT else: OP_ACCEPT))
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                        2150760448 => 0
                        2150629376 => 0
                        2151022592 =>
                            cb.external_flags = cb.external_flags | 4096
                            (unsafe: *code__goto_6109_14 = 161)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2151088128 =>
                            cb.external_flags = cb.external_flags | 4096
                            __pc = 2
                            __goto_pending = 1
                            (verbarglen__goto_6167_12 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            (verbculen__goto_6167_24 = 0)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                            i__goto_6561_14 = 0
                            while (if i__goto_6561_14 < (verbarglen__goto_6167_12 as c_int): 1 else: 0) != 0:
                                (meta__goto_6101_10 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (mclength__goto_6163_12 = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = meta__goto_6101_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + mclength__goto_6163_12
                                else:
                                    code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    verbculen__goto_6167_24 = verbculen__goto_6167_24 + mclength__goto_6163_12
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i__goto_6561_14 = i__goto_6561_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *tempcode__goto_6112_14) = verbculen__goto_6167_24)
                            (unsafe: *code__goto_6109_14 = 0)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2150825984 =>
                            (verbarglen__goto_6167_12 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            (verbculen__goto_6167_24 = 0)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                            i__goto_6561_14 = 0
                            while (if i__goto_6561_14 < (verbarglen__goto_6167_12 as c_int): 1 else: 0) != 0:
                                (meta__goto_6101_10 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (mclength__goto_6163_12 = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = meta__goto_6101_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + mclength__goto_6163_12
                                else:
                                    code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    verbculen__goto_6167_24 = verbculen__goto_6167_24 + mclength__goto_6163_12
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i__goto_6561_14 = i__goto_6561_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *tempcode__goto_6112_14) = verbculen__goto_6167_24)
                            (unsafe: *code__goto_6109_14 = 0)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2150432768 =>
                            (verbarglen__goto_6167_12 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            (verbculen__goto_6167_24 = 0)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                            i__goto_6561_14 = 0
                            while (if i__goto_6561_14 < (verbarglen__goto_6167_12 as c_int): 1 else: 0) != 0:
                                (meta__goto_6101_10 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (mclength__goto_6163_12 = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = meta__goto_6101_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                    (unsafe: *lengthptr) = (unsafe: *lengthptr) + mclength__goto_6163_12
                                else:
                                    code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    verbculen__goto_6167_24 = verbculen__goto_6167_24 + mclength__goto_6163_12
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (i__goto_6561_14 = i__goto_6561_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *tempcode__goto_6112_14) = verbculen__goto_6167_24)
                            (unsafe: *code__goto_6109_14 = 0)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2149515264 =>
                            (options__goto_6096_10 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            ((unsafe: *optionsptr) = options__goto_6096_10)
                            (xoptions__goto_6097_10 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            ((unsafe: *xoptionsptr) = xoptions__goto_6097_10)
                            (greedy_default__goto_6094_10 = ((if ((options__goto_6096_10 & 262144)) != 0: 1 else: 0)))
                            (greedy_non_default__goto_6094_26 = (greedy_default__goto_6094_10 ^ 1))
                            (req_caseopt__goto_6104_10 = (if ((if ((options__goto_6096_10 & 8)) != 0: 1 else: 0)) != 0: 1 else: 0))
                        2148925440 =>
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                (pptr__goto_6100_11 = _pcre2_compile_parse_scan_substr_args8(pptr__goto_6100_11, errorcodeptr, cb, lengthptr))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if pptr__goto_6100_11 == (null as *mut c_uint): 1 else: 0) != 0:
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
                            (pptr__goto_6100_11 = pptr__goto_6100_11 - 1)
                        2148990976 =>
                            (bravalue__goto_6090_5 = OP_ASSERT_SCS)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                start_pptr__goto_6679_17 = pptr__goto_6100_11
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                length__goto_6680_16 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (name__goto_6677_18 = (cb.start_pattern + offset__goto_6107_12))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ng__goto_6678_20 == (null as *mut named_group_8): 1 else: 0) != 0:
                                    (groupnumber__goto_6166_12 = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if meta__goto_6101_10 == 2148794368: 1 else: 0) != 0:
                                        (i__goto_6676_16 = 1)
                                        while (if i__goto_6676_16 < length__goto_6680_16: 1 else: 0) != 0:
                                            (groupnumber__goto_6166_12 = ((groupnumber__goto_6166_12 *% 10) +% ((name__goto_6677_18[i__goto_6676_16] - 48))))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if groupnumber__goto_6166_12 > 65535: 1 else: 0) != 0:
                                                ((unsafe: *errorcodeptr) = ERR61)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (cb.erroroffset = (offset__goto_6107_12 +% i__goto_6676_16))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                return 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i__goto_6676_16 = i__goto_6676_16 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if meta__goto_6101_10 != 2148794368: 1 else: 0) != 0 or (if groupnumber__goto_6166_12 > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR15)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.erroroffset = offset__goto_6107_12)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if groupnumber__goto_6166_12 == 0: 1 else: 0) != 0:
                                        (groupnumber__goto_6166_12 = 65535)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr__goto_6679_17[1] = groupnumber__goto_6166_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta__goto_6101_10 == 2148794368: 1 else: 0) != 0:
                                    (meta__goto_6101_10 = (2148597760 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((ng__goto_6678_20.hash_dup & 32768)) == 0: 1 else: 0) != 0:
                                    if (if ng__goto_6678_20.number > cb.top_backref: 1 else: 0) != 0:
                                        (cb.top_backref = ng__goto_6678_20.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr__goto_6679_17[0] = meta__goto_6101_10)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr__goto_6679_17[1] = ng__goto_6678_20.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (start_pptr__goto_6679_17[0] = (meta__goto_6101_10 | 1))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (start_pptr__goto_6679_17[1] = ((((ng__goto_6678_20 as usize -% cb.named_groups as usize) / sizeof[named_group_8]())) as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits__goto_6164_12 = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if meta__goto_6101_10 == 2148794368: 1 else: 0) != 0:
                                    (code__goto_6109_14[(1 + 2)] = 149)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr__goto_6100_11 = pptr__goto_6100_11 + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta_arg__goto_6101_16 == 0: 1 else: 0) != 0:
                                    (code__goto_6109_14[(1 + 2)] = (if ((if meta__goto_6101_10 == 2148728832: 1 else: 0)) != 0: OP_RREF else: OP_CREF))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr__goto_6100_11 = pptr__goto_6100_11 + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ng__goto_6764_20 = (cb.named_groups + pptr__goto_6100_11[1]))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (count__goto_6763_11 = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (index__goto_6763_18 = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if _pcre2_compile_find_dupname_details8(ng__goto_6764_20.name, ng__goto_6764_20.length, (&mut index__goto_6763_18 as *mut c_int), (&mut count__goto_6763_11 as *mut c_int), errorcodeptr, cb) != 0: 0 else: 1) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14[(1 + 2)] = (if ((if meta__goto_6101_10 == 2148728832: 1 else: 0)) != 0: OP_DNRREF else: OP_DNCREF))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits__goto_6164_12 = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (code__goto_6109_14[(1 + 2)] = 170)
                            (skipunits__goto_6164_12 = 1)
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber__goto_6166_12 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            if (if groupnumber__goto_6166_12 > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset__goto_6107_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber__goto_6166_12 > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber__goto_6166_12)
                            offset__goto_6107_12 = offset__goto_6107_12 - 2
                            (code__goto_6109_14[(1 + 2)] = 147)
                            (skipunits__goto_6164_12 = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            if (if pptr__goto_6100_11[1] > 0: 1 else: 0) != 0:
                                (code__goto_6109_14[(1 + 2)] = (if ((if ((if 10 > pptr__goto_6100_11[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 >= pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code__goto_6109_14[(1 + 2)] = (if ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 == pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits__goto_6164_12 = 1)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                                start_pptr__goto_6679_17 = pptr__goto_6100_11
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                length__goto_6680_16 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (name__goto_6677_18 = (cb.start_pattern + offset__goto_6107_12))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ng__goto_6678_20 == (null as *mut named_group_8): 1 else: 0) != 0:
                                    (groupnumber__goto_6166_12 = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if meta__goto_6101_10 == 2148794368: 1 else: 0) != 0:
                                        (i__goto_6676_16 = 1)
                                        while (if i__goto_6676_16 < length__goto_6680_16: 1 else: 0) != 0:
                                            (groupnumber__goto_6166_12 = ((groupnumber__goto_6166_12 *% 10) +% ((name__goto_6677_18[i__goto_6676_16] - 48))))
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            if (if groupnumber__goto_6166_12 > 65535: 1 else: 0) != 0:
                                                ((unsafe: *errorcodeptr) = ERR61)
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                (cb.erroroffset = (offset__goto_6107_12 +% i__goto_6676_16))
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                                return 0
                                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                                    break
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (i__goto_6676_16 = i__goto_6676_16 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if meta__goto_6101_10 != 2148794368: 1 else: 0) != 0 or (if groupnumber__goto_6166_12 > cb.bracount: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR15)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (cb.erroroffset = offset__goto_6107_12)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if groupnumber__goto_6166_12 == 0: 1 else: 0) != 0:
                                        (groupnumber__goto_6166_12 = 65535)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr__goto_6679_17[1] = groupnumber__goto_6166_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta__goto_6101_10 == 2148794368: 1 else: 0) != 0:
                                    (meta__goto_6101_10 = (2148597760 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if ((ng__goto_6678_20.hash_dup & 32768)) == 0: 1 else: 0) != 0:
                                    if (if ng__goto_6678_20.number > cb.top_backref: 1 else: 0) != 0:
                                        (cb.top_backref = ng__goto_6678_20.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr__goto_6679_17[0] = meta__goto_6101_10)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (start_pptr__goto_6679_17[1] = ng__goto_6678_20.number)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (start_pptr__goto_6679_17[0] = (meta__goto_6101_10 | 1))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (start_pptr__goto_6679_17[1] = ((((ng__goto_6678_20 as usize -% cb.named_groups as usize) / sizeof[named_group_8]())) as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits__goto_6164_12 = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if meta__goto_6101_10 == 2148794368: 1 else: 0) != 0:
                                    (code__goto_6109_14[(1 + 2)] = 149)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr__goto_6100_11 = pptr__goto_6100_11 + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if meta_arg__goto_6101_16 == 0: 1 else: 0) != 0:
                                    (code__goto_6109_14[(1 + 2)] = (if ((if meta__goto_6101_10 == 2148728832: 1 else: 0)) != 0: OP_RREF else: OP_CREF))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (skipunits__goto_6164_12 = 3)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    pptr__goto_6100_11 = pptr__goto_6100_11 + (1 + 2)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 3
                                    __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (ng__goto_6764_20 = (cb.named_groups + pptr__goto_6100_11[1]))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (count__goto_6763_11 = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (index__goto_6763_18 = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if _pcre2_compile_find_dupname_details8(ng__goto_6764_20.name, ng__goto_6764_20.length, (&mut index__goto_6763_18 as *mut c_int), (&mut count__goto_6763_11 as *mut c_int), errorcodeptr, cb) != 0: 0 else: 1) != 0:
                                    return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14[(1 + 2)] = (if ((if meta__goto_6101_10 == 2148728832: 1 else: 0)) != 0: OP_DNRREF else: OP_DNCREF))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (skipunits__goto_6164_12 = 5)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + (1 + 2)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (code__goto_6109_14[(1 + 2)] = 170)
                            (skipunits__goto_6164_12 = 1)
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber__goto_6166_12 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            if (if groupnumber__goto_6166_12 > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset__goto_6107_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber__goto_6166_12 > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber__goto_6166_12)
                            offset__goto_6107_12 = offset__goto_6107_12 - 2
                            (code__goto_6109_14[(1 + 2)] = 147)
                            (skipunits__goto_6164_12 = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            if (if pptr__goto_6100_11[1] > 0: 1 else: 0) != 0:
                                (code__goto_6109_14[(1 + 2)] = (if ((if ((if 10 > pptr__goto_6100_11[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 >= pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code__goto_6109_14[(1 + 2)] = (if ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 == pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits__goto_6164_12 = 1)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            (bravalue__goto_6090_5 = OP_COND)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (code__goto_6109_14[(1 + 2)] = 170)
                            (skipunits__goto_6164_12 = 1)
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber__goto_6166_12 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            if (if groupnumber__goto_6166_12 > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset__goto_6107_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber__goto_6166_12 > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber__goto_6166_12)
                            offset__goto_6107_12 = offset__goto_6107_12 - 2
                            (code__goto_6109_14[(1 + 2)] = 147)
                            (skipunits__goto_6164_12 = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            if (if pptr__goto_6100_11[1] > 0: 1 else: 0) != 0:
                                (code__goto_6109_14[(1 + 2)] = (if ((if ((if 10 > pptr__goto_6100_11[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 >= pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code__goto_6109_14[(1 + 2)] = (if ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 == pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits__goto_6164_12 = 1)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            (bravalue__goto_6090_5 = OP_COND)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            (groupnumber__goto_6166_12 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            if (if groupnumber__goto_6166_12 > cb.bracount: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (cb.erroroffset = offset__goto_6107_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if groupnumber__goto_6166_12 > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = groupnumber__goto_6166_12)
                            offset__goto_6107_12 = offset__goto_6107_12 - 2
                            (code__goto_6109_14[(1 + 2)] = 147)
                            (skipunits__goto_6164_12 = 3)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            if (if pptr__goto_6100_11[1] > 0: 1 else: 0) != 0:
                                (code__goto_6109_14[(1 + 2)] = (if ((if ((if 10 > pptr__goto_6100_11[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 >= pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code__goto_6109_14[(1 + 2)] = (if ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 == pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits__goto_6164_12 = 1)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            (bravalue__goto_6090_5 = OP_COND)
                            if (if pptr__goto_6100_11[1] > 0: 1 else: 0) != 0:
                                (code__goto_6109_14[(1 + 2)] = (if ((if ((if 10 > pptr__goto_6100_11[2]: 1 else: 0)) != 0 or ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 >= pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            else:
                                (code__goto_6109_14[(1 + 2)] = (if ((if (if 10 == pptr__goto_6100_11[2]: 1 else: 0) != 0 and (if 48 == pptr__goto_6100_11[3]: 1 else: 0) != 0: 1 else: 0)) != 0: OP_TRUE else: OP_FALSE))
                            (skipunits__goto_6164_12 = 1)
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            (bravalue__goto_6090_5 = OP_COND)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            (bravalue__goto_6090_5 = OP_ASSERT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            (bravalue__goto_6090_5 = OP_ASSERT_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            if (if (if pptr__goto_6100_11[1] == 2149384192: 1 else: 0) != 0 and ((if (if pptr__goto_6100_11[2] < 2151153664: 1 else: 0) != 0 or (if pptr__goto_6100_11[2] > 2151874560: 1 else: 0) != 0: 1 else: 0)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = 165)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (bravalue__goto_6090_5 = OP_ASSERT_NOT)
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
                            (bravalue__goto_6090_5 = OP_ASSERTBACK)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERTBACK_NOT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_BRA)
                            (note_group_empty__goto_6162_8 = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code__goto_6109_14) = bravalue__goto_6090_5)
                            (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (tempreqvary__goto_6104_32 = cb.req_varyopt)
                            (length_prevgroup__goto_6108_12 = 0)
                            if (if ((group_return__goto_6092_5 = compile_regex(options__goto_6096_10, xoptions__goto_6097_10, (&mut tempcode__goto_6112_14 as *mut *mut u8), (&mut pptr__goto_6100_11 as *mut *mut c_uint), errorcodeptr, skipunits__goto_6164_12, (&mut subfirstcu__goto_6165_22 as *mut c_uint), (&mut subfirstcuflags__goto_6168_27 as *mut c_uint), (&mut subreqcu__goto_6165_12 as *mut c_uint), (&mut subreqcuflags__goto_6168_12 as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup__goto_6108_12 as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty__goto_6162_8 != 0 and (if bravalue__goto_6090_5 != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return__goto_6092_5 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            if (if (if bravalue__goto_6090_5 >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue__goto_6090_5 <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue__goto_6090_5 == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc__goto_6989_20 = code__goto_6109_14
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount__goto_6990_11 = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount__goto_6990_11 = condcount__goto_6990_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc__goto_6989_20) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code__goto_6109_14[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount__goto_6990_11 > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    (code__goto_6109_14[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue__goto_6090_5 = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount__goto_6990_11 > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    if (if condcount__goto_6990_11 == 1: 1 else: 0) != 0:
                                        (subreqcuflags__goto_6168_12 = (4294967294 as c_uint))
                                        (subfirstcuflags__goto_6168_27 = subreqcuflags__goto_6168_12)
                                    else:
                                        if (if group_return__goto_6092_5 > 0: 1 else: 0) != 0:
                                            (matched_char__goto_6117_6 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup__goto_6108_12 -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup__goto_6108_12 -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = 122)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code__goto_6109_14 = tempcode__goto_6112_14)
                            if (if bravalue__goto_6090_5 == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (groupsetfirstcu__goto_6115_6 = 0)
                            if (if bravalue__goto_6090_5 >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0:
                                        (firstcu__goto_6098_10 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags__goto_6102_10 = subfirstcuflags__goto_6168_27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu__goto_6115_6 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags__goto_6103_26 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0 and (if subreqcuflags__goto_6168_12 >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu__goto_6165_12 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags__goto_6168_12 = (subfirstcuflags__goto_6168_27 | tempreqvary__goto_6104_32))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue__goto_6090_5 == OP_ASSERT: 1 else: 0) != 0 or (if bravalue__goto_6090_5 == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2150236160 =>
                            (bravalue__goto_6090_5 = OP_ASSERTBACK_NOT)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_BRA)
                            (note_group_empty__goto_6162_8 = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code__goto_6109_14) = bravalue__goto_6090_5)
                            (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (tempreqvary__goto_6104_32 = cb.req_varyopt)
                            (length_prevgroup__goto_6108_12 = 0)
                            if (if ((group_return__goto_6092_5 = compile_regex(options__goto_6096_10, xoptions__goto_6097_10, (&mut tempcode__goto_6112_14 as *mut *mut u8), (&mut pptr__goto_6100_11 as *mut *mut c_uint), errorcodeptr, skipunits__goto_6164_12, (&mut subfirstcu__goto_6165_22 as *mut c_uint), (&mut subfirstcuflags__goto_6168_27 as *mut c_uint), (&mut subreqcu__goto_6165_12 as *mut c_uint), (&mut subreqcuflags__goto_6168_12 as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup__goto_6108_12 as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty__goto_6162_8 != 0 and (if bravalue__goto_6090_5 != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return__goto_6092_5 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            if (if (if bravalue__goto_6090_5 >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue__goto_6090_5 <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue__goto_6090_5 == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc__goto_6989_20 = code__goto_6109_14
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount__goto_6990_11 = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount__goto_6990_11 = condcount__goto_6990_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc__goto_6989_20) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code__goto_6109_14[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount__goto_6990_11 > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    (code__goto_6109_14[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue__goto_6090_5 = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount__goto_6990_11 > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    if (if condcount__goto_6990_11 == 1: 1 else: 0) != 0:
                                        (subreqcuflags__goto_6168_12 = (4294967294 as c_uint))
                                        (subfirstcuflags__goto_6168_27 = subreqcuflags__goto_6168_12)
                                    else:
                                        if (if group_return__goto_6092_5 > 0: 1 else: 0) != 0:
                                            (matched_char__goto_6117_6 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup__goto_6108_12 -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup__goto_6108_12 -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = 122)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code__goto_6109_14 = tempcode__goto_6112_14)
                            if (if bravalue__goto_6090_5 == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (groupsetfirstcu__goto_6115_6 = 0)
                            if (if bravalue__goto_6090_5 >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0:
                                        (firstcu__goto_6098_10 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags__goto_6102_10 = subfirstcuflags__goto_6168_27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu__goto_6115_6 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags__goto_6103_26 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0 and (if subreqcuflags__goto_6168_12 >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu__goto_6165_12 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags__goto_6168_12 = (subfirstcuflags__goto_6168_27 | tempreqvary__goto_6104_32))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue__goto_6090_5 == OP_ASSERT: 1 else: 0) != 0 or (if bravalue__goto_6090_5 == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2150367232 =>
                            (bravalue__goto_6090_5 = OP_ASSERTBACK_NA)
                            cb.assert_depth = cb.assert_depth + 1
                            __pc = 4
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_BRA)
                            (note_group_empty__goto_6162_8 = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code__goto_6109_14) = bravalue__goto_6090_5)
                            (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (tempreqvary__goto_6104_32 = cb.req_varyopt)
                            (length_prevgroup__goto_6108_12 = 0)
                            if (if ((group_return__goto_6092_5 = compile_regex(options__goto_6096_10, xoptions__goto_6097_10, (&mut tempcode__goto_6112_14 as *mut *mut u8), (&mut pptr__goto_6100_11 as *mut *mut c_uint), errorcodeptr, skipunits__goto_6164_12, (&mut subfirstcu__goto_6165_22 as *mut c_uint), (&mut subfirstcuflags__goto_6168_27 as *mut c_uint), (&mut subreqcu__goto_6165_12 as *mut c_uint), (&mut subreqcuflags__goto_6168_12 as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup__goto_6108_12 as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty__goto_6162_8 != 0 and (if bravalue__goto_6090_5 != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return__goto_6092_5 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            if (if (if bravalue__goto_6090_5 >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue__goto_6090_5 <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue__goto_6090_5 == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc__goto_6989_20 = code__goto_6109_14
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount__goto_6990_11 = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount__goto_6990_11 = condcount__goto_6990_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc__goto_6989_20) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code__goto_6109_14[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount__goto_6990_11 > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    (code__goto_6109_14[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue__goto_6090_5 = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount__goto_6990_11 > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    if (if condcount__goto_6990_11 == 1: 1 else: 0) != 0:
                                        (subreqcuflags__goto_6168_12 = (4294967294 as c_uint))
                                        (subfirstcuflags__goto_6168_27 = subreqcuflags__goto_6168_12)
                                    else:
                                        if (if group_return__goto_6092_5 > 0: 1 else: 0) != 0:
                                            (matched_char__goto_6117_6 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup__goto_6108_12 -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup__goto_6108_12 -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = 122)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code__goto_6109_14 = tempcode__goto_6112_14)
                            if (if bravalue__goto_6090_5 == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (groupsetfirstcu__goto_6115_6 = 0)
                            if (if bravalue__goto_6090_5 >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0:
                                        (firstcu__goto_6098_10 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags__goto_6102_10 = subfirstcuflags__goto_6168_27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu__goto_6115_6 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags__goto_6103_26 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0 and (if subreqcuflags__goto_6168_12 >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu__goto_6165_12 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags__goto_6168_12 = (subfirstcuflags__goto_6168_27 | tempreqvary__goto_6104_32))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue__goto_6090_5 == OP_ASSERT: 1 else: 0) != 0 or (if bravalue__goto_6090_5 == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2147614720 =>
                            (bravalue__goto_6090_5 = OP_ONCE)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_BRA)
                            (note_group_empty__goto_6162_8 = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code__goto_6109_14) = bravalue__goto_6090_5)
                            (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (tempreqvary__goto_6104_32 = cb.req_varyopt)
                            (length_prevgroup__goto_6108_12 = 0)
                            if (if ((group_return__goto_6092_5 = compile_regex(options__goto_6096_10, xoptions__goto_6097_10, (&mut tempcode__goto_6112_14 as *mut *mut u8), (&mut pptr__goto_6100_11 as *mut *mut c_uint), errorcodeptr, skipunits__goto_6164_12, (&mut subfirstcu__goto_6165_22 as *mut c_uint), (&mut subfirstcuflags__goto_6168_27 as *mut c_uint), (&mut subreqcu__goto_6165_12 as *mut c_uint), (&mut subreqcuflags__goto_6168_12 as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup__goto_6108_12 as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty__goto_6162_8 != 0 and (if bravalue__goto_6090_5 != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return__goto_6092_5 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            if (if (if bravalue__goto_6090_5 >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue__goto_6090_5 <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue__goto_6090_5 == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc__goto_6989_20 = code__goto_6109_14
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount__goto_6990_11 = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount__goto_6990_11 = condcount__goto_6990_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc__goto_6989_20) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code__goto_6109_14[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount__goto_6990_11 > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    (code__goto_6109_14[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue__goto_6090_5 = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount__goto_6990_11 > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    if (if condcount__goto_6990_11 == 1: 1 else: 0) != 0:
                                        (subreqcuflags__goto_6168_12 = (4294967294 as c_uint))
                                        (subfirstcuflags__goto_6168_27 = subreqcuflags__goto_6168_12)
                                    else:
                                        if (if group_return__goto_6092_5 > 0: 1 else: 0) != 0:
                                            (matched_char__goto_6117_6 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup__goto_6108_12 -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup__goto_6108_12 -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = 122)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code__goto_6109_14 = tempcode__goto_6112_14)
                            if (if bravalue__goto_6090_5 == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (groupsetfirstcu__goto_6115_6 = 0)
                            if (if bravalue__goto_6090_5 >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0:
                                        (firstcu__goto_6098_10 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags__goto_6102_10 = subfirstcuflags__goto_6168_27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu__goto_6115_6 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags__goto_6103_26 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0 and (if subreqcuflags__goto_6168_12 >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu__goto_6165_12 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags__goto_6168_12 = (subfirstcuflags__goto_6168_27 | tempreqvary__goto_6104_32))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue__goto_6090_5 == OP_ASSERT: 1 else: 0) != 0 or (if bravalue__goto_6090_5 == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2149974016 =>
                            (bravalue__goto_6090_5 = OP_SCRIPT_RUN)
                            __pc = 3
                            __goto_pending = 1
                            (bravalue__goto_6090_5 = OP_BRA)
                            (note_group_empty__goto_6162_8 = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code__goto_6109_14) = bravalue__goto_6090_5)
                            (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (tempreqvary__goto_6104_32 = cb.req_varyopt)
                            (length_prevgroup__goto_6108_12 = 0)
                            if (if ((group_return__goto_6092_5 = compile_regex(options__goto_6096_10, xoptions__goto_6097_10, (&mut tempcode__goto_6112_14 as *mut *mut u8), (&mut pptr__goto_6100_11 as *mut *mut c_uint), errorcodeptr, skipunits__goto_6164_12, (&mut subfirstcu__goto_6165_22 as *mut c_uint), (&mut subfirstcuflags__goto_6168_27 as *mut c_uint), (&mut subreqcu__goto_6165_12 as *mut c_uint), (&mut subreqcuflags__goto_6168_12 as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup__goto_6108_12 as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty__goto_6162_8 != 0 and (if bravalue__goto_6090_5 != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return__goto_6092_5 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            if (if (if bravalue__goto_6090_5 >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue__goto_6090_5 <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue__goto_6090_5 == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc__goto_6989_20 = code__goto_6109_14
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount__goto_6990_11 = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount__goto_6990_11 = condcount__goto_6990_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc__goto_6989_20) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code__goto_6109_14[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount__goto_6990_11 > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    (code__goto_6109_14[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue__goto_6090_5 = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount__goto_6990_11 > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    if (if condcount__goto_6990_11 == 1: 1 else: 0) != 0:
                                        (subreqcuflags__goto_6168_12 = (4294967294 as c_uint))
                                        (subfirstcuflags__goto_6168_27 = subreqcuflags__goto_6168_12)
                                    else:
                                        if (if group_return__goto_6092_5 > 0: 1 else: 0) != 0:
                                            (matched_char__goto_6117_6 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup__goto_6108_12 -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup__goto_6108_12 -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = 122)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code__goto_6109_14 = tempcode__goto_6112_14)
                            if (if bravalue__goto_6090_5 == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (groupsetfirstcu__goto_6115_6 = 0)
                            if (if bravalue__goto_6090_5 >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0:
                                        (firstcu__goto_6098_10 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags__goto_6102_10 = subfirstcuflags__goto_6168_27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu__goto_6115_6 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags__goto_6103_26 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0 and (if subreqcuflags__goto_6168_12 >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu__goto_6165_12 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags__goto_6168_12 = (subfirstcuflags__goto_6168_27 | tempreqvary__goto_6104_32))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue__goto_6090_5 == OP_ASSERT: 1 else: 0) != 0 or (if bravalue__goto_6090_5 == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2149449728 =>
                            (bravalue__goto_6090_5 = OP_BRA)
                            (note_group_empty__goto_6162_8 = 1)
                            cb.parens_depth = cb.parens_depth + 1
                            ((unsafe: *code__goto_6109_14) = bravalue__goto_6090_5)
                            (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                            (tempcode__goto_6112_14 = code__goto_6109_14)
                            (tempreqvary__goto_6104_32 = cb.req_varyopt)
                            (length_prevgroup__goto_6108_12 = 0)
                            if (if ((group_return__goto_6092_5 = compile_regex(options__goto_6096_10, xoptions__goto_6097_10, (&mut tempcode__goto_6112_14 as *mut *mut u8), (&mut pptr__goto_6100_11 as *mut *mut c_uint), errorcodeptr, skipunits__goto_6164_12, (&mut subfirstcu__goto_6165_22 as *mut c_uint), (&mut subfirstcuflags__goto_6168_27 as *mut c_uint), (&mut subreqcu__goto_6165_12 as *mut c_uint), (&mut subreqcuflags__goto_6168_12 as *mut c_uint), bcptr, open_caps, cb, (if ((if lengthptr == (null as *mut c_ulong): 1 else: 0)) != 0: (null as *mut c_ulong) else: (&mut length_prevgroup__goto_6108_12 as *mut c_ulong))))) == 0: 1 else: 0) != 0:
                                return 0
                            cb.parens_depth = cb.parens_depth - 1
                            if (if (if note_group_empty__goto_6162_8 != 0 and (if bravalue__goto_6090_5 != OP_COND: 1 else: 0) != 0: 1 else: 0) != 0 and (if group_return__goto_6092_5 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            if (if (if bravalue__goto_6090_5 >= OP_ASSERT: 1 else: 0) != 0 and (if bravalue__goto_6090_5 <= OP_ASSERT_SCS: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.assert_depth = cb.assert_depth - 1
                            if (if (if bravalue__goto_6090_5 == OP_COND: 1 else: 0) != 0 and (if lengthptr == (null as *mut c_ulong): 1 else: 0) != 0: 1 else: 0) != 0:
                                tc__goto_6989_20 = code__goto_6109_14
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                condcount__goto_6990_11 = 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while true:
                                    (condcount__goto_6990_11 = condcount__goto_6990_11 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if not ((if (unsafe: *tc__goto_6989_20) != OP_KET: 1 else: 0) != 0):
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if code__goto_6109_14[(2 + 1)] == OP_DEFINE: 1 else: 0) != 0:
                                    if (if condcount__goto_6990_11 > 1: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    (code__goto_6109_14[(2 + 1)] = 151)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (bravalue__goto_6090_5 = OP_DEFINE)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if condcount__goto_6990_11 > 2: 1 else: 0) != 0:
                                        (cb.erroroffset = offset__goto_6107_12)
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
                                    if (if condcount__goto_6990_11 == 1: 1 else: 0) != 0:
                                        (subreqcuflags__goto_6168_12 = (4294967294 as c_uint))
                                        (subfirstcuflags__goto_6168_27 = subreqcuflags__goto_6168_12)
                                    else:
                                        if (if group_return__goto_6092_5 > 0: 1 else: 0) != 0:
                                            (matched_char__goto_6117_6 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                if (if (2147483627 -% (unsafe: *lengthptr)) < ((length_prevgroup__goto_6108_12 -% 2) -% 4): 1 else: 0) != 0:
                                    ((unsafe: *errorcodeptr) = ERR20)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    return 0
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + ((length_prevgroup__goto_6108_12 -% 2) -% 4)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *code__goto_6109_14 = 122)
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (code__goto_6109_14 = tempcode__goto_6112_14)
                            if (if bravalue__goto_6090_5 == OP_DEFINE: 1 else: 0) != 0:
                                break
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (groupsetfirstcu__goto_6115_6 = 0)
                            if (if bravalue__goto_6090_5 >= OP_ONCE: 1 else: 0) != 0:
                                if (if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 != 4294967295: 1 else: 0) != 0: 1 else: 0) != 0:
                                    if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0:
                                        (firstcu__goto_6098_10 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (firstcuflags__goto_6102_10 = subfirstcuflags__goto_6168_27)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (groupsetfirstcu__goto_6115_6 = 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (zerofirstcuflags__goto_6103_26 = (4294967294 as c_uint))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    if (if (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0 and (if subreqcuflags__goto_6168_12 >= 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (subreqcu__goto_6165_12 = subfirstcu__goto_6165_22)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (subreqcuflags__goto_6168_12 = (subfirstcuflags__goto_6168_27 | tempreqvary__goto_6104_32))
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                if (if (if ((if (if bravalue__goto_6090_5 == OP_ASSERT: 1 else: 0) != 0 or (if bravalue__goto_6090_5 == OP_ASSERT_NA: 1 else: 0) != 0: 1 else: 0)) != 0 and (if subreqcuflags__goto_6168_12 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0 and (if subfirstcuflags__goto_6168_27 < 4294967294: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = subreqcu__goto_6165_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = subreqcuflags__goto_6168_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                        2147745792 => 0
                        2147876864 =>
                            (code__goto_6109_14[0] = 119)
                            (code__goto_6109_14[(1 + (2 * 2))] = pptr__goto_6100_11[3])
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                            code__goto_6109_14 = code__goto_6109_14 + _pcre2_OP_lengths_8[OP_CALLOUT]
                        2147942400 =>
                            if (if lengthptr != (null as *mut c_ulong): 1 else: 0) != 0:
                                (unsafe: *lengthptr) = (unsafe: *lengthptr) + (pptr__goto_6100_11[3] +% 9)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                length__goto_7250_16 = pptr__goto_6100_11[3]
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                callout_string__goto_7251_20 = (code__goto_6109_14 + (((1 + (4 * 2))) as isize as usize))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14[0] = 120)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 3
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (pp__goto_7248_18 = (cb.start_pattern + offset__goto_6107_12))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *callout_string__goto_7251_20 = (unsafe: *(pp__goto_7248_18 = pp__goto_7248_18 + 1)))
                                (callout_string__goto_7251_20 = callout_string__goto_7251_20 + 1)
                                (delimiter__goto_7249_16 = (unsafe: *(callout_string__goto_7251_20 = callout_string__goto_7251_20 + 1)))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if delimiter__goto_7249_16 == 123: 1 else: 0) != 0:
                                    (delimiter__goto_7249_16 = 125)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                while (if (length__goto_7250_16 = length__goto_7250_16 - 1) > 1: 1 else: 0) != 0:
                                    if (if (if (unsafe: *pp__goto_7248_18) == delimiter__goto_7249_16: 1 else: 0) != 0 and (if pp__goto_7248_18[1] == delimiter__goto_7249_16: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (unsafe: *callout_string__goto_7251_20 = delimiter__goto_7249_16)
                                        (callout_string__goto_7251_20 = callout_string__goto_7251_20 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        pp__goto_7248_18 = pp__goto_7248_18 + 2
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (length__goto_7250_16 = length__goto_7250_16 - 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *callout_string__goto_7251_20 = (unsafe: *(pp__goto_7248_18 = pp__goto_7248_18 + 1)))
                                        (callout_string__goto_7251_20 = callout_string__goto_7251_20 + 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (unsafe: *callout_string__goto_7251_20 = 0)
                                (callout_string__goto_7251_20 = callout_string__goto_7251_20 + 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (code__goto_6109_14 = callout_string__goto_7251_20)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                        2151809024 =>
                            (repeat_max__goto_6093_26 = (unsafe: *((pptr__goto_6100_11 = pptr__goto_6100_11 + 1))))
                            __pc = 5
                            __goto_pending = 1
                            __pc = 5
                            __goto_pending = 1
                            __pc = 5
                            __goto_pending = 1
                            (repeat_max__goto_6093_26 = 1)
                            if (if previous_matched_char__goto_6118_6 != 0 and (if repeat_min__goto_6093_10 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            (reqvary__goto_6104_23 = (if ((if repeat_min__goto_6093_10 == repeat_max__goto_6093_26: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min__goto_6093_10 == 0: 1 else: 0) != 0:
                                (firstcu__goto_6098_10 = zerofirstcu__goto_6099_21)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags__goto_6102_10 = zerofirstcuflags__goto_6103_26)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu__goto_6098_19 = zeroreqcu__goto_6099_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags__goto_6102_24 = zeroreqcuflags__goto_6103_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta__goto_6101_10
                                2151809024 =>
                                    (possessive_quantifier__goto_6161_8 = 1)
                                2151874560 =>
                                    (possessive_quantifier__goto_6161_8 = 0)
                                _ =>
                                    (repeat_type__goto_6095_10 = greedy_default__goto_6094_10)
                                    (possessive_quantifier__goto_6161_8 = 0)
                            (tempcode__goto_6112_14 = previous__goto_6113_14)
                            (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                            match op_previous__goto_6114_13
                                OP_CHAR =>
                                    (op_type__goto_6095_23 = (&chartypeoffset[0] as *mut c_uint)[(op_previous__goto_6114_13 - OP_CHAR)])
                                    ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = code__goto_6109_14[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu__goto_6098_19 = (&mcbuffer__goto_6170_15[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags__goto_6102_24 = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous__goto_6114_13 == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags__goto_6102_24 = reqcuflags__goto_6102_24 | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier__goto_6161_8 != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length__goto_7518_20 = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup__goto_6108_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous__goto_6113_14) = 137)
                                    (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous__goto_6113_14[(3 +% length__goto_7518_20)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code__goto_6109_14 = code__goto_6109_14 + (2 + (2 * 2))
                                    length_prevgroup__goto_6108_12 = length_prevgroup__goto_6108_12 + 6
                                    (group_return__goto_6092_5 = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous__goto_6114_13 >= OP_EODN: 1 else: 0) != 0 or (if op_previous__goto_6114_13 <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type__goto_6095_23 = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 == OP_PROP: 1 else: 0) != 0 or (if op_previous__goto_6114_13 == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type__goto_7882_13 = previous__goto_6113_14[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value__goto_7882_24 = previous__goto_6113_14[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value__goto_7882_24 = -1)
                                        (prop_type__goto_7882_13 = prop_value__goto_7882_24)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode__goto_7883_22 = code__goto_6109_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code__goto_6109_14 = previous__goto_6113_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max__goto_6093_26 == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type__goto_6095_10 = repeat_type__goto_6095_10 + op_type__goto_6095_23
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength__goto_6163_12 > 0: 1 else: 0) != 0:
                                        code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code__goto_6109_14 = op_previous__goto_6114_13)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type__goto_7882_13 >= 0: 1 else: 0) != 0:
                                            (unsafe: *code__goto_6109_14 = prop_type__goto_7882_13)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code__goto_6109_14 = prop_value__goto_7882_24)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier__goto_6161_8 != 0:
                                match (unsafe: *tempcode__goto_6112_14)
                                    OP_TYPEEXACT =>
                                        tempcode__goto_6112_14 = tempcode__goto_6112_14 + (_pcre2_OP_lengths_8[(unsafe: *tempcode__goto_6112_14)] + ((if ((if (if tempcode__goto_6112_14[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode__goto_6112_14[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len__goto_8038_11 = ((((code__goto_6109_14 as usize -% tempcode__goto_6112_14 as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len__goto_8038_11 > 0: 1 else: 0) != 0:
                                    repcode__goto_8103_22 = (unsafe: *tempcode__goto_6112_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode__goto_8103_22 < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode__goto_6112_14) = (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22])
                                    else:
                                        code__goto_6109_14 = code__goto_6109_14 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len__goto_8038_11 = len__goto_8038_11 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode__goto_6112_14[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code__goto_6109_14 = 122)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary__goto_6104_23
                        2151153664 =>
                            __pc = 5
                            __goto_pending = 1
                            __pc = 5
                            __goto_pending = 1
                            (repeat_max__goto_6093_26 = 1)
                            if (if previous_matched_char__goto_6118_6 != 0 and (if repeat_min__goto_6093_10 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            (reqvary__goto_6104_23 = (if ((if repeat_min__goto_6093_10 == repeat_max__goto_6093_26: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min__goto_6093_10 == 0: 1 else: 0) != 0:
                                (firstcu__goto_6098_10 = zerofirstcu__goto_6099_21)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags__goto_6102_10 = zerofirstcuflags__goto_6103_26)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu__goto_6098_19 = zeroreqcu__goto_6099_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags__goto_6102_24 = zeroreqcuflags__goto_6103_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta__goto_6101_10
                                2151809024 =>
                                    (possessive_quantifier__goto_6161_8 = 1)
                                2151874560 =>
                                    (possessive_quantifier__goto_6161_8 = 0)
                                _ =>
                                    (repeat_type__goto_6095_10 = greedy_default__goto_6094_10)
                                    (possessive_quantifier__goto_6161_8 = 0)
                            (tempcode__goto_6112_14 = previous__goto_6113_14)
                            (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                            match op_previous__goto_6114_13
                                OP_CHAR =>
                                    (op_type__goto_6095_23 = (&chartypeoffset[0] as *mut c_uint)[(op_previous__goto_6114_13 - OP_CHAR)])
                                    ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = code__goto_6109_14[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu__goto_6098_19 = (&mcbuffer__goto_6170_15[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags__goto_6102_24 = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous__goto_6114_13 == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags__goto_6102_24 = reqcuflags__goto_6102_24 | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier__goto_6161_8 != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length__goto_7518_20 = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup__goto_6108_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous__goto_6113_14) = 137)
                                    (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous__goto_6113_14[(3 +% length__goto_7518_20)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code__goto_6109_14 = code__goto_6109_14 + (2 + (2 * 2))
                                    length_prevgroup__goto_6108_12 = length_prevgroup__goto_6108_12 + 6
                                    (group_return__goto_6092_5 = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous__goto_6114_13 >= OP_EODN: 1 else: 0) != 0 or (if op_previous__goto_6114_13 <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type__goto_6095_23 = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 == OP_PROP: 1 else: 0) != 0 or (if op_previous__goto_6114_13 == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type__goto_7882_13 = previous__goto_6113_14[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value__goto_7882_24 = previous__goto_6113_14[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value__goto_7882_24 = -1)
                                        (prop_type__goto_7882_13 = prop_value__goto_7882_24)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode__goto_7883_22 = code__goto_6109_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code__goto_6109_14 = previous__goto_6113_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max__goto_6093_26 == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type__goto_6095_10 = repeat_type__goto_6095_10 + op_type__goto_6095_23
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength__goto_6163_12 > 0: 1 else: 0) != 0:
                                        code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code__goto_6109_14 = op_previous__goto_6114_13)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type__goto_7882_13 >= 0: 1 else: 0) != 0:
                                            (unsafe: *code__goto_6109_14 = prop_type__goto_7882_13)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code__goto_6109_14 = prop_value__goto_7882_24)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier__goto_6161_8 != 0:
                                match (unsafe: *tempcode__goto_6112_14)
                                    OP_TYPEEXACT =>
                                        tempcode__goto_6112_14 = tempcode__goto_6112_14 + (_pcre2_OP_lengths_8[(unsafe: *tempcode__goto_6112_14)] + ((if ((if (if tempcode__goto_6112_14[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode__goto_6112_14[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len__goto_8038_11 = ((((code__goto_6109_14 as usize -% tempcode__goto_6112_14 as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len__goto_8038_11 > 0: 1 else: 0) != 0:
                                    repcode__goto_8103_22 = (unsafe: *tempcode__goto_6112_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode__goto_8103_22 < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode__goto_6112_14) = (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22])
                                    else:
                                        code__goto_6109_14 = code__goto_6109_14 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len__goto_8038_11 = len__goto_8038_11 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode__goto_6112_14[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code__goto_6109_14 = 122)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary__goto_6104_23
                        2151350272 =>
                            __pc = 5
                            __goto_pending = 1
                            (repeat_max__goto_6093_26 = 1)
                            if (if previous_matched_char__goto_6118_6 != 0 and (if repeat_min__goto_6093_10 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            (reqvary__goto_6104_23 = (if ((if repeat_min__goto_6093_10 == repeat_max__goto_6093_26: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min__goto_6093_10 == 0: 1 else: 0) != 0:
                                (firstcu__goto_6098_10 = zerofirstcu__goto_6099_21)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags__goto_6102_10 = zerofirstcuflags__goto_6103_26)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu__goto_6098_19 = zeroreqcu__goto_6099_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags__goto_6102_24 = zeroreqcuflags__goto_6103_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta__goto_6101_10
                                2151809024 =>
                                    (possessive_quantifier__goto_6161_8 = 1)
                                2151874560 =>
                                    (possessive_quantifier__goto_6161_8 = 0)
                                _ =>
                                    (repeat_type__goto_6095_10 = greedy_default__goto_6094_10)
                                    (possessive_quantifier__goto_6161_8 = 0)
                            (tempcode__goto_6112_14 = previous__goto_6113_14)
                            (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                            match op_previous__goto_6114_13
                                OP_CHAR =>
                                    (op_type__goto_6095_23 = (&chartypeoffset[0] as *mut c_uint)[(op_previous__goto_6114_13 - OP_CHAR)])
                                    ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = code__goto_6109_14[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu__goto_6098_19 = (&mcbuffer__goto_6170_15[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags__goto_6102_24 = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous__goto_6114_13 == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags__goto_6102_24 = reqcuflags__goto_6102_24 | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier__goto_6161_8 != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length__goto_7518_20 = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup__goto_6108_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous__goto_6113_14) = 137)
                                    (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous__goto_6113_14[(3 +% length__goto_7518_20)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code__goto_6109_14 = code__goto_6109_14 + (2 + (2 * 2))
                                    length_prevgroup__goto_6108_12 = length_prevgroup__goto_6108_12 + 6
                                    (group_return__goto_6092_5 = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous__goto_6114_13 >= OP_EODN: 1 else: 0) != 0 or (if op_previous__goto_6114_13 <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type__goto_6095_23 = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 == OP_PROP: 1 else: 0) != 0 or (if op_previous__goto_6114_13 == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type__goto_7882_13 = previous__goto_6113_14[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value__goto_7882_24 = previous__goto_6113_14[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value__goto_7882_24 = -1)
                                        (prop_type__goto_7882_13 = prop_value__goto_7882_24)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode__goto_7883_22 = code__goto_6109_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code__goto_6109_14 = previous__goto_6113_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max__goto_6093_26 == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type__goto_6095_10 = repeat_type__goto_6095_10 + op_type__goto_6095_23
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength__goto_6163_12 > 0: 1 else: 0) != 0:
                                        code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code__goto_6109_14 = op_previous__goto_6114_13)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type__goto_7882_13 >= 0: 1 else: 0) != 0:
                                            (unsafe: *code__goto_6109_14 = prop_type__goto_7882_13)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code__goto_6109_14 = prop_value__goto_7882_24)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier__goto_6161_8 != 0:
                                match (unsafe: *tempcode__goto_6112_14)
                                    OP_TYPEEXACT =>
                                        tempcode__goto_6112_14 = tempcode__goto_6112_14 + (_pcre2_OP_lengths_8[(unsafe: *tempcode__goto_6112_14)] + ((if ((if (if tempcode__goto_6112_14[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode__goto_6112_14[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len__goto_8038_11 = ((((code__goto_6109_14 as usize -% tempcode__goto_6112_14 as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len__goto_8038_11 > 0: 1 else: 0) != 0:
                                    repcode__goto_8103_22 = (unsafe: *tempcode__goto_6112_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode__goto_8103_22 < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode__goto_6112_14) = (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22])
                                    else:
                                        code__goto_6109_14 = code__goto_6109_14 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len__goto_8038_11 = len__goto_8038_11 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode__goto_6112_14[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code__goto_6109_14 = 122)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary__goto_6104_23
                        2151546880 =>
                            (repeat_max__goto_6093_26 = 1)
                            if (if previous_matched_char__goto_6118_6 != 0 and (if repeat_min__goto_6093_10 > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                            (reqvary__goto_6104_23 = (if ((if repeat_min__goto_6093_10 == repeat_max__goto_6093_26: 1 else: 0)) != 0: 0 else: 2))
                            if (if repeat_min__goto_6093_10 == 0: 1 else: 0) != 0:
                                (firstcu__goto_6098_10 = zerofirstcu__goto_6099_21)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (firstcuflags__goto_6102_10 = zerofirstcuflags__goto_6103_26)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcu__goto_6098_19 = zeroreqcu__goto_6099_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reqcuflags__goto_6102_24 = zeroreqcuflags__goto_6103_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta__goto_6101_10
                                2151809024 =>
                                    (possessive_quantifier__goto_6161_8 = 1)
                                2151874560 =>
                                    (possessive_quantifier__goto_6161_8 = 0)
                                _ =>
                                    (repeat_type__goto_6095_10 = greedy_default__goto_6094_10)
                                    (possessive_quantifier__goto_6161_8 = 0)
                            (tempcode__goto_6112_14 = previous__goto_6113_14)
                            (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                            match op_previous__goto_6114_13
                                OP_CHAR =>
                                    (op_type__goto_6095_23 = (&chartypeoffset[0] as *mut c_uint)[(op_previous__goto_6114_13 - OP_CHAR)])
                                    ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = code__goto_6109_14[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 1)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 <= OP_CHARI: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 > 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (reqcu__goto_6098_19 = (&mcbuffer__goto_6170_15[0] as *mut u8)[0])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags__goto_6102_24 = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if op_previous__goto_6114_13 == OP_CHARI: 1 else: 0) != 0:
                                            reqcuflags__goto_6102_24 = reqcuflags__goto_6102_24 | 1
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    __pc = 6
                                    __goto_pending = 1
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_CLASS =>
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                OP_RECURSE =>
                                    if (if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0 and (if possessive_quantifier__goto_6161_8 != 0: 0 else: 1) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    length__goto_7518_20 = (if ((if lengthptr != (null as *mut c_ulong): 1 else: 0)) != 0: 3 else: length_prevgroup__goto_6108_12)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    ((unsafe: *previous__goto_6113_14) = 137)
                                    (op_previous__goto_6114_13 = (unsafe: *previous__goto_6113_14))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (previous__goto_6113_14[(3 +% length__goto_7518_20)] = 122)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    code__goto_6109_14 = code__goto_6109_14 + (2 + (2 * 2))
                                    length_prevgroup__goto_6108_12 = length_prevgroup__goto_6108_12 + 6
                                    (group_return__goto_6092_5 = -1)
                                OP_ASSERT => 0
                                _ =>
                                    if (if (if op_previous__goto_6114_13 >= OP_EODN: 1 else: 0) != 0 or (if op_previous__goto_6114_13 <= OP_WORD_BOUNDARY: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *errorcodeptr) = ERR10)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        return 0
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if (if repeat_max__goto_6093_26 == 1: 1 else: 0) != 0 and (if repeat_min__goto_6093_10 == 1: 1 else: 0) != 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (op_type__goto_6095_23 = 52)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (mclength__goto_6163_12 = 0)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if op_previous__goto_6114_13 == OP_PROP: 1 else: 0) != 0 or (if op_previous__goto_6114_13 == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0) != 0:
                                        (prop_type__goto_7882_13 = previous__goto_6113_14[1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (prop_value__goto_7882_24 = previous__goto_6113_14[2])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (prop_value__goto_7882_24 = -1)
                                        (prop_type__goto_7882_13 = prop_value__goto_7882_24)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (oldcode__goto_7883_22 = code__goto_6109_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (code__goto_6109_14 = previous__goto_6113_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if repeat_max__goto_6093_26 == 0: 1 else: 0) != 0:
                                        __pc = 7
                                        __goto_pending = 1
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    repeat_type__goto_6095_10 = repeat_type__goto_6095_10 + op_type__goto_6095_23
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength__goto_6163_12 > 0: 1 else: 0) != 0:
                                        code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    else:
                                        (unsafe: *code__goto_6109_14 = op_previous__goto_6114_13)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        if (if prop_type__goto_7882_13 >= 0: 1 else: 0) != 0:
                                            (unsafe: *code__goto_6109_14 = prop_type__goto_7882_13)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                            (unsafe: *code__goto_6109_14 = prop_value__goto_7882_24)
                                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                                break
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                            if possessive_quantifier__goto_6161_8 != 0:
                                match (unsafe: *tempcode__goto_6112_14)
                                    OP_TYPEEXACT =>
                                        tempcode__goto_6112_14 = tempcode__goto_6112_14 + (_pcre2_OP_lengths_8[(unsafe: *tempcode__goto_6112_14)] + ((if ((if (if tempcode__goto_6112_14[(1 + 2)] == OP_PROP: 1 else: 0) != 0 or (if tempcode__goto_6112_14[(1 + 2)] == OP_NOTPROP: 1 else: 0) != 0: 1 else: 0)) != 0: 2 else: 0)))
                                    OP_CHAR => 0
                                    OP_CLASS => 0
                                    OP_REF => 0
                                    _ => 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (len__goto_8038_11 = ((((code__goto_6109_14 as usize -% tempcode__goto_6112_14 as usize) / sizeof[u8]())) as c_int))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if len__goto_8038_11 > 0: 1 else: 0) != 0:
                                    repcode__goto_8103_22 = (unsafe: *tempcode__goto_6112_14)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if (if repcode__goto_8103_22 < 119: 1 else: 0) != 0 and (if (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22] > 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                        ((unsafe: *tempcode__goto_6112_14) = (&opcode_possessify[0] as *mut u8)[repcode__goto_8103_22])
                                    else:
                                        code__goto_6109_14 = code__goto_6109_14 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        len__goto_8038_11 = len__goto_8038_11 + (1 + 2)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (tempcode__goto_6112_14[0] = 135)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (unsafe: *code__goto_6109_14 = 122)
                                        (code__goto_6109_14 = code__goto_6109_14 + 1)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            cb.req_varyopt = cb.req_varyopt | reqvary__goto_6104_23
                        2147811328 =>
                            (pptr__goto_6100_11 = pptr__goto_6100_11 + 1)
                            __pc = 10
                            __goto_pending = 1
                            if (if meta_arg__goto_6101_16 < 10: 1 else: 0) != 0:
                                (offset__goto_6107_12 = (&cb.small_ref_offset[0] as *mut c_ulong)[meta_arg__goto_6101_16])
                            else:
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            0
                            if (if meta_arg__goto_6101_16 > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset__goto_6107_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (unsafe: *code__goto_6109_14 = (if ((if ((options__goto_6096_10 & 8)) != 0: 1 else: 0)) != 0: OP_REFI else: OP_REF))
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                            if (if ((options__goto_6096_10 & 8)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = (((if ((if ((xoptions__goto_6097_10 & 128)) != 0: 1 else: 0)) != 0: 1 else: 0)) | ((if ((if ((xoptions__goto_6097_10 & 65536)) != 0: 1 else: 0)) != 0: 2 else: 0))))
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                            cb.backref_map = cb.backref_map | (if ((if meta_arg__goto_6101_16 < 32: 1 else: 0)) != 0: ((1 << meta_arg__goto_6101_16)) else: 1)
                            if (if meta_arg__goto_6101_16 > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = meta_arg__goto_6101_16)
                        2147680256 =>
                            if (if meta_arg__goto_6101_16 < 10: 1 else: 0) != 0:
                                (offset__goto_6107_12 = (&cb.small_ref_offset[0] as *mut c_ulong)[meta_arg__goto_6101_16])
                            else:
                                pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            0
                            if (if meta_arg__goto_6101_16 > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset__goto_6107_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (unsafe: *code__goto_6109_14 = (if ((if ((options__goto_6096_10 & 8)) != 0: 1 else: 0)) != 0: OP_REFI else: OP_REF))
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                            if (if ((options__goto_6096_10 & 8)) != 0: 1 else: 0) != 0:
                                (unsafe: *code__goto_6109_14 = (((if ((if ((xoptions__goto_6097_10 & 128)) != 0: 1 else: 0)) != 0: 1 else: 0)) | ((if ((if ((xoptions__goto_6097_10 & 65536)) != 0: 1 else: 0)) != 0: 2 else: 0))))
                                (code__goto_6109_14 = code__goto_6109_14 + 1)
                            cb.backref_map = cb.backref_map | (if ((if meta_arg__goto_6101_16 < 32: 1 else: 0)) != 0: ((1 << meta_arg__goto_6101_16)) else: 1)
                            if (if meta_arg__goto_6101_16 > cb.top_backref: 1 else: 0) != 0:
                                (cb.top_backref = meta_arg__goto_6101_16)
                        2149842944 =>
                            pptr__goto_6100_11 = pptr__goto_6100_11 + 2
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            0
                            if (if meta_arg__goto_6101_16 > cb.bracount: 1 else: 0) != 0:
                                (cb.erroroffset = offset__goto_6107_12)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                ((unsafe: *errorcodeptr) = ERR15)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            ((unsafe: *code__goto_6109_14) = 118)
                            code__goto_6109_14 = code__goto_6109_14 + (1 + 2)
                            (length_prevgroup__goto_6108_12 = 3)
                            (groupsetfirstcu__goto_6115_6 = 0)
                            (cb.had_recurse = 1)
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                        2148007936 =>
                            (bravalue__goto_6090_5 = OP_CBRA)
                            (skipunits__goto_6164_12 = 2)
                            (cb.lastcapture = meta_arg__goto_6101_16)
                            __pc = 3
                            __goto_pending = 1
                            if (if (if meta_arg__goto_6101_16 > 5: 1 else: 0) != 0 and (if meta_arg__goto_6101_16 < 23: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            if (if (if (if cb.assert_depth > 0: 1 else: 0) != 0 and (if meta_arg__goto_6101_16 == 3: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((xoptions__goto_6097_10 & 64)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR99)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta_arg__goto_6101_16
                                14 =>
                                    cb.external_flags = cb.external_flags | 4194304
                                    if (if utf__goto_6129_6 != 0: 0 else: 1) != 0:
                                        (meta_arg__goto_6101_16 = 13)
                                4 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                1 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                3 =>
                                    cb.external_flags = cb.external_flags | 16777216
                                _ => 0
                            (unsafe: *code__goto_6109_14 = meta_arg__goto_6101_16)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        2149318656 =>
                            if (if (if meta_arg__goto_6101_16 > 5: 1 else: 0) != 0 and (if meta_arg__goto_6101_16 < 23: 1 else: 0) != 0: 1 else: 0) != 0:
                                (matched_char__goto_6117_6 = 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                    (firstcuflags__goto_6102_10 = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                            (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                            (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                            (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                            if (if (if (if cb.assert_depth > 0: 1 else: 0) != 0 and (if meta_arg__goto_6101_16 == 3: 1 else: 0) != 0: 1 else: 0) != 0 and (if ((xoptions__goto_6097_10 & 64)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR99)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            match meta_arg__goto_6101_16
                                14 =>
                                    cb.external_flags = cb.external_flags | 4194304
                                    if (if utf__goto_6129_6 != 0: 0 else: 1) != 0:
                                        (meta_arg__goto_6101_16 = 13)
                                4 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                1 =>
                                    if (if cb.max_lookbehind == 0: 1 else: 0) != 0:
                                        (cb.max_lookbehind = 1)
                                3 =>
                                    cb.external_flags = cb.external_flags | 16777216
                                _ => 0
                            (unsafe: *code__goto_6109_14 = meta_arg__goto_6101_16)
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                        _ =>
                            if (if meta__goto_6101_10 >= 2147483648: 1 else: 0) != 0:
                                ((unsafe: *errorcodeptr) = ERR89)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                return 0
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            (meta__goto_6101_10 = (unsafe: *pptr__goto_6100_11))
                            (matched_char__goto_6117_6 = 1)
                            (mclength__goto_6163_12 = 1)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            ((&mcbuffer__goto_6170_15[0] as *mut u8)[0] = meta__goto_6101_10)
                            if (if __goto_pending != 0: 1 else: 0) != 0:
                                break
                            (unsafe: *code__goto_6109_14 = (if ((if ((options__goto_6096_10 & 8)) != 0: 1 else: 0)) != 0: OP_CHARI else: OP_CHAR))
                            (code__goto_6109_14 = code__goto_6109_14 + 1)
                            code__goto_6109_14 = code__goto_6109_14 + mclength__goto_6163_12
                            if (if (if (&mcbuffer__goto_6170_15[0] as *mut u8)[0] == 13: 1 else: 0) != 0 or (if (&mcbuffer__goto_6170_15[0] as *mut u8)[0] == 10: 1 else: 0) != 0: 1 else: 0) != 0:
                                cb.external_flags = cb.external_flags | 2048
                            if (if firstcuflags__goto_6102_10 == 4294967295: 1 else: 0) != 0:
                                (zerofirstcuflags__goto_6103_26 = (4294967294 as c_uint))
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if mclength__goto_6163_12 == 1: 1 else: 0) != 0 or (if req_caseopt__goto_6104_10 == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (firstcu__goto_6098_10 = (&mcbuffer__goto_6170_15[0] as *mut u8)[0])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (firstcuflags__goto_6102_10 = req_caseopt__goto_6104_10)
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    if (if mclength__goto_6163_12 != 1: 1 else: 0) != 0:
                                        (reqcu__goto_6098_19 = code__goto_6109_14[-1])
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                        (reqcuflags__goto_6102_24 = cb.req_varyopt)
                                        if (if __goto_pending != 0: 1 else: 0) != 0:
                                            break
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                else:
                                    (reqcuflags__goto_6102_24 = (4294967294 as c_uint))
                                    (firstcuflags__goto_6102_10 = reqcuflags__goto_6102_24)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            else:
                                (zerofirstcu__goto_6099_21 = firstcu__goto_6098_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zerofirstcuflags__goto_6103_26 = firstcuflags__goto_6102_10)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcu__goto_6099_10 = reqcu__goto_6098_19)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (zeroreqcuflags__goto_6103_10 = reqcuflags__goto_6102_24)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                if (if (if mclength__goto_6163_12 == 1: 1 else: 0) != 0 or (if req_caseopt__goto_6104_10 == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                                    (reqcu__goto_6098_19 = code__goto_6109_14[-1])
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                    (reqcuflags__goto_6102_24 = (req_caseopt__goto_6104_10 | cb.req_varyopt))
                                    if (if __goto_pending != 0: 1 else: 0) != 0:
                                        break
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                            if reset_caseful__goto_6119_6 != 0:
                                options__goto_6096_10 = options__goto_6096_10 & (0 - 8 - 1)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (req_caseopt__goto_6104_10 = 0)
                                if (if __goto_pending != 0: 1 else: 0) != 0:
                                    break
                                (reset_caseful__goto_6119_6 = 0)
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
    var gi__goto_9529_11: *mut c_uint = null
    var branchlength__goto_9530_5: c_int = 0
    var branchminlength__goto_9530_19: c_int = 0
    var grouplength__goto_9531_5: c_int = 0
    var groupminlength__goto_9532_5: c_int = 0
    var groupinfo__goto_9541_12: c_uint = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true:
        match __pc
            0 =>
                (__goto_pending = 0)
                gi__goto_9529_11 = (cb.groupinfo + ((2 * group) as isize as usize))
                grouplength__goto_9531_5 = -1
                groupminlength__goto_9532_5 = 2147483647
                if (if (if group > 0: 1 else: 0) != 0 and (if ((cb.external_flags & 2097152)) == 0: 1 else: 0) != 0: 1 else: 0) != 0:
                    groupinfo__goto_9541_12 = gi__goto_9529_11[0]
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if ((groupinfo__goto_9541_12 & 1073741824)) != 0: 1 else: 0) != 0:
                        return -1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    if (if ((groupinfo__goto_9541_12 & (2147483648 as c_uint))) != 0: 1 else: 0) != 0:
                        if isinline != 0:
                            ((unsafe: *pptrptr) = parsed_skip((unsafe: *pptrptr), 2))
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        ((unsafe: *minptr) = gi__goto_9529_11[1])
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                        return (groupinfo__goto_9541_12 & 65535)
                        if (if __goto_pending != 0: 1 else: 0) != 0:
                            continue
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                while true:
                    (branchlength__goto_9530_5 = get_branchlength(pptrptr, (&mut branchminlength__goto_9530_19 as *mut c_int), errcodeptr, lcptr, recurses, cb))
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if branchlength__goto_9530_5 < 0: 1 else: 0) != 0:
                        __pc = 1
                        __goto_pending = 1
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if branchlength__goto_9530_5 > grouplength__goto_9531_5: 1 else: 0) != 0:
                        (grouplength__goto_9531_5 = branchlength__goto_9530_5)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        break
                    if (if branchminlength__goto_9530_19 < groupminlength__goto_9532_5: 1 else: 0) != 0:
                        (groupminlength__goto_9532_5 = branchminlength__goto_9530_19)
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
                    gi__goto_9529_11[0] = gi__goto_9529_11[0] | ((((2147483648 as c_uint) | grouplength__goto_9531_5)) as c_uint)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                    (gi__goto_9529_11[1] = groupminlength__goto_9532_5)
                    if (if __goto_pending != 0: 1 else: 0) != 0:
                        continue
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                ((unsafe: *minptr) = groupminlength__goto_9532_5)
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                return grouplength__goto_9531_5
                if (if __goto_pending != 0: 1 else: 0) != 0:
                    continue
                __pc = 1
                continue
            1 =>  // ISNOTFIXED
                (__goto_pending = 0)
                if (if group > 0: 1 else: 0) != 0:
                    gi__goto_9529_11[0] = gi__goto_9529_11[0] | 1073741824
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
    (((ch as u32) == 0x69) or ((ch as u32) == 0x0130))
fn UCD_FOLD_I_TURKISH[T](ch: T) -> T:
    (if ((ch as u32) == 0x0130): 0x69 else: (if ((ch as u32) == 0x49): 0x0131 else: (ch as u32)))
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
