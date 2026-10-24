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
use std.engines.pcre2.pcre2_substring
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
use std.engines.pcre2.pcre2_compile_class

pub unsafe fn _pcre2_compile_get_hash_from_name8(__param_name: *const u8, __param_length: u32) -> u16 {
    var __local_hash: u16

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    (__local_hash = (((((((__param_name[0]) as i32) & (127 as i32)) as i32) | ((((((__param_name[((__param_length as u32) -% (1 as u32))]) as i32) & (255 as i32)) as i32) << (7 as u32)) as i32)) as u16)))

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    return __local_hash

}

pub unsafe fn _pcre2_compile_find_named_group8(__param_name: *const u8, __param_length: u32, __param_cb: *mut compile_block_8) -> *mut named_group_8 {
    var __local_hash: u16 = ((_pcre2_compile_get_hash_from_name8(__param_name, __param_length) as u16))

    var __local_ng: *mut named_group_8

    var __local_end: *mut named_group_8 = ((*__param_cb).named_groups + (((*__param_cb).names_found as u32) as usize))

    (__local_ng = (*__param_cb).named_groups)

    while ((if __local_ng < __local_end: 1 else: 0) != 0) {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_logic_0: i32 = 0

        if ((if __param_length == (*__local_ng).length: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_hash == (((*__local_ng).hash_dup as i32) & (32767 as i32)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if _pcre2_strncmp_8(__param_name, (*__local_ng).name, (__param_length as u64)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return __local_ng
        }


        (__local_ng = __local_ng + 1)

    }


    return ((null as *mut named_group_8))

}

pub unsafe fn _pcre2_compile_add_name_to_table8(__param_cb: *mut compile_block_8, __param_ng: *mut named_group_8, __param_tablecount: u32) -> u32 {
    var __local_ng = __param_ng
    var __local_tablecount = __param_tablecount
    var __local_i: u32

    var __local_name: *const u8 = (*__local_ng).name

    var __local_length: i32 = (((*__local_ng).length as i32))

    var __local_duplicate_count: u32 = ((1 as u32))

    var __local_slot: *mut u8 = (*__param_cb).name_table

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    if ((if (((*__local_ng).hash_dup as i32) & (32768 as i32)) != 0: 1 else: 0) != 0) {
        var __local_ng_it: *mut named_group_8

        var __local_end: *mut named_group_8 = ((*__param_cb).named_groups + (((*__param_cb).names_found as u32) as usize))

        (__local_ng_it = __local_ng + ((1 as isize) as usize))

        while ((if __local_ng_it < __local_end: 1 else: 0) != 0) {
            if ((if (*__local_ng_it).name == __local_name: 1 else: 0) != 0) {
                (__local_duplicate_count = (__local_duplicate_count +% 1))
            }

            (__local_ng_it = __local_ng_it + 1)

        }


    }

    (__local_i = ((0 as u32)))

    while ((if __local_i < __local_tablecount: 1 else: 0) != 0) {
        var __local_crc: i32 = ((with_memcmp(((__local_name as *const c_void) as *const u8), (((__local_slot + ((2 as isize) as usize)) as *const c_void) as *const u8), (((__local_length * (8 / 8)) as u64) as i64)) as i32))

        var __ci_expr_logic_0: i32 = 0

        if ((if __local_crc == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (__local_slot[(2 + __local_length)]) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_crc = ((-1 as i32)))
        }


        if ((if __local_crc < 0: 1 else: 0) != 0) {
            with_memmove((((__local_slot + (((((*__param_cb).name_entry_size as i32) as u32) *% (__local_duplicate_count as u32)) as usize)) as *mut c_void) as *mut u8), ((__local_slot as *const c_void) as *const u8), ((((((((__local_tablecount as u32) -% (__local_i as u32)) as u32) *% (((*__param_cb).name_entry_size as i32) as u32)) as u32) *% (1 as u32)) as u64) as i64))

            break

        }

        (__local_slot = __local_slot + ((((*__param_cb).name_entry_size as u32) as usize) as i32))


        (__local_i = (__local_i +% 1))

    }


    (__local_tablecount = (__local_tablecount +% __local_duplicate_count))

    while (1 != 0) {
        ((__local_slot[0]) = (((((*__local_ng).number as u32) >> (8 as u32)) as u8)))

        ((__local_slot[(0 + 1)]) = (((((*__local_ng).number as u32) & (255 as u32)) as u8)))


        with_memcpy((((__local_slot + ((2 as isize) as usize)) as *mut c_void) as *mut u8), ((__local_name as *const c_void) as *const u8), (((__local_length * (8 / 8)) as u64) as i64))

        with_memset(((((__local_slot + ((2 as isize) as usize)) + ((__local_length as isize) as usize)) as *mut c_void) as *mut u8), (0 as i32), (((((((*__param_cb).name_entry_size as i32) - __local_length) - 2) * (8 / 8)) as u64) as i64))

        (__local_duplicate_count = (__local_duplicate_count -% 1))

        if ((if __local_duplicate_count == 0: 1 else: 0) != 0) {
            break
        }


        while (1 != 0) {
            (__local_ng = __local_ng + 1)

            if ((if (*__local_ng).name == __local_name: 1 else: 0) != 0) {
                break
            }

        }

        (__local_slot = __local_slot + ((((*__param_cb).name_entry_size as u32) as usize) as i32))

    }

    return __local_tablecount

}

pub unsafe fn _pcre2_compile_find_dupname_details8(__param_name: *const u8, __param_length: u32, __param_indexptr: *mut i32, __param_countptr: *mut i32, __param_errorcodeptr: *mut i32, __param_cb: *mut compile_block_8) -> i32 {
    var __local_i: u32

    var __local_groupnumber: u32


    var __local_count: i32

    var __local_slot: *mut u8 = (*__param_cb).name_table

    (__local_i = ((0 as u32)))

    while ((if __local_i < (*__param_cb).names_found: 1 else: 0) != 0) {
        var __ci_expr_logic_0: i32 = 0

        if ((if _pcre2_strncmp_8(__param_name, ((__local_slot + ((2 as isize) as usize)) as *const u8), (__param_length as u64)) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (__local_slot[((2 as u32) +% (__param_length as u32))]) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            break
        }


        (__local_slot = __local_slot + ((((*__param_cb).name_entry_size as u32) as usize) as i32))


        (__local_i = (__local_i +% 1))

    }


    if ((if __local_i >= (*__param_cb).names_found: 1 else: 0) != 0) {
        loop {
            0
            if not ((0 != 0)) {
                break
            }
        }

        ((*__param_errorcodeptr) = ERR53)

        ((*__param_cb).erroroffset = ((((((__param_name as usize) -% ((*__param_cb).start_pattern as usize)) as i64) / (sizeof[u8]() as i64)) as u64)))

        return 0

    }

    ((*__param_indexptr) = ((__local_i as i32)))

    (__local_count = ((0 as i32)))

    while true {
        (__local_count = __local_count + 1)

        (__local_groupnumber = (((((((__local_slot[0]) as i32) << (8 as u32)) as i32) | ((__local_slot[(0 + 1)]) as i32)) as u32)))

        ((*__param_cb).backref_map = ((*__param_cb).backref_map as u32) | ((if (if __local_groupnumber < 32: 1 else: 0) != 0: (((1 as u32) << (__local_groupnumber as u32)) as u32) else: (1 as u32)) as u32))

        if ((if __local_groupnumber > (*__param_cb).top_backref: 1 else: 0) != 0) {
            ((*__param_cb).top_backref = __local_groupnumber)
        }

        (__local_i = (__local_i +% 1))

        if ((if __local_i >= (*__param_cb).names_found: 1 else: 0) != 0) {
            break
        }


        (__local_slot = __local_slot + ((((*__param_cb).name_entry_size as u32) as usize) as i32))

        var __ci_expr_logic_1: i32

        if ((if _pcre2_strncmp_8(__param_name, ((__local_slot + ((2 as isize) as usize)) as *const u8), (__param_length as u64)) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if ((__local_slot + ((2 as isize) as usize))[__param_length]) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            break
        }


    }

    ((*__param_countptr) = __local_count)

    return 1

}

pub unsafe fn _pcre2_compile_parse_scan_substr_args8(__param_pptr: *mut u32, __param_errorcodeptr: *mut i32, __param_cb: *mut compile_block_8, __param_lengthptr: *mut u64) -> *mut u32 {
    var __local_pptr = __param_pptr
    var __local_captures: *mut u8

    var __local_capture_ptr: *mut u8

    var __local_bit: u8

    var __local_name: *const u8

    var __local_ng: *mut named_group_8

    var __local_end: *mut named_group_8 = ((*__param_cb).named_groups + (((*__param_cb).names_found as u32) as usize))

    var __local_all_found: i32

    var __local_size: u64

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    if ((if _pcre2_compile_process_capture_list((__local_pptr - ((1 as isize) as usize)), (0 as u64), __param_errorcodeptr, __param_cb) == 0: 1 else: 0) != 0) {
        return ((null as *mut u32))
    }

    (__local_size = (((((((((*__param_cb).bracount as u32) +% (1 as u32)) as u32) +% (7 as u32)) as u32) >> (3 as u32)) as u64)))

    (__local_captures = (((*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).malloc.unwrap()(__local_size, (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).memory_data) as *mut u8)))

    if ((if __local_captures == null: 1 else: 0) != 0) {
        ((*__param_errorcodeptr) = ERR21)

        ((*__param_cb).erroroffset = (((((((__local_pptr[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr[2]) as u64)) as u64)))



        return ((null as *mut u32))

    }

    with_memset(((__local_captures as *mut c_void) as *mut u8), (0 as i32), (__local_size as i64))

    while (1 != 0) {
        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match (((*__local_pptr) as u32) & (4294901760 as u32)) {
                2148925440 => {
                    (__local_pptr = __local_pptr + 1)

                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149056512 => {
                    (__local_ng = (*__param_cb).named_groups + ((__local_pptr[1]) as usize))

                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__local_name = (*__local_ng).name)

                    (__local_all_found = ((1 as i32)))

                    loop {
                        if ((if (*__local_ng).name != __local_name: 1 else: 0) != 0) {
                            (__local_ng = __local_ng + 1)

                            if ((if __local_ng < __local_end: 1 else: 0) != 0) {
                                continue
                            }
                            break

                        }

                        (__local_capture_ptr = __local_captures + ((((*__local_ng).number as u32) >> (3 as u32)) as usize))

                        loop {
                            0
                            if not ((0 != 0)) {
                                break
                            }
                        }

                        (__local_bit = ((((1 as i32) << ((((*__local_ng).number as u32) & (7 as u32)) as u32)) as u8)))

                        if ((if (((*__local_capture_ptr) as i32) & (__local_bit as i32)) == 0: 1 else: 0) != 0) {
                            ((*__local_capture_ptr) = ((*__local_capture_ptr) as u8) | (__local_bit as u8))

                            (__local_all_found = ((0 as i32)))

                        }

                        (__local_ng = __local_ng + 1)
                        if not (((if __local_ng < __local_end: 1 else: 0) != 0)) {
                            break
                        }
                    }

                    if ((if not (__local_all_found != 0): 1 else: 0) != 0) {
                        ((*__param_lengthptr) = ((*__param_lengthptr) +% 5))

                        (__ci_expr_switch_continue_0 = 1)

                        break


                    }

                    ((__local_pptr[-2]) = ((2149122048 as u32)))

                    ((__local_pptr[-1]) = ((0 as u32)))

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149122048 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__local_capture_ptr = __local_captures + ((((__local_pptr[-1]) as u32) >> (3 as u32)) as usize))

                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    (__local_bit = ((((1 as i32) << ((((__local_pptr[-1]) as u32) & (7 as u32)) as u32)) as u8)))

                    if ((if (((*__local_capture_ptr) as i32) & (__local_bit as i32)) != 0: 1 else: 0) != 0) {
                        ((__local_pptr[-1]) = ((0 as u32)))

                        (__ci_expr_switch_continue_0 = 1)

                        break


                    }

                    ((*__local_capture_ptr) = ((*__local_capture_ptr) as u8) | (__local_bit as u8))

                    ((*__param_lengthptr) = ((*__param_lengthptr) +% 3))

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                _ => {
                    0
                },
            }

            break

        }

        if (__ci_expr_switch_continue_0 != 0) {
            continue
        }


        break

    }

    (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).free.unwrap()((__local_captures as *mut c_void), (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).memory_data)

    return (((__local_pptr - ((1 as isize) as usize)) as *mut u32))

}

pub unsafe fn _pcre2_compile_parse_recurse_args8(__param_pptr_start: *mut u32, __param_offset: u64, __param_errorcodeptr: *mut i32, __param_cb: *mut compile_block_8) -> i32 {
    var __local_pptr: *mut u32 = __param_pptr_start

    var __local_i: u64

    var __local_size: u64


    var __local_name: *const u8

    var __local_ng: *mut named_group_8

    var __local_end: *mut named_group_8 = ((*__param_cb).named_groups + (((*__param_cb).names_found as u32) as usize))

    var __local_args: *mut recurse_arguments

    var __local_captures: *mut u16

    var __local_current: *mut u16

    var __local_captures_end: *mut u16

    var __local_tmp: u16

    (__local_size = ((_pcre2_compile_process_capture_list(__local_pptr, __param_offset, __param_errorcodeptr, __param_cb) as u64)))

    if ((if __local_size == 0: 1 else: 0) != 0) {
        return 0
    }

    (__local_args = (((*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).malloc.unwrap()((((sizeof[recurse_arguments]() as u64) +% (((__local_size as u64) *% (sizeof[u16]() as u64)) as u64)) as u64), (*(&raw const (*(*__param_cb).cx).memctl as *const pcre2_memctl)).memory_data) as *mut recurse_arguments)))

    if ((if __local_args == null: 1 else: 0) != 0) {
        ((*__param_errorcodeptr) = ERR21)

        ((*__param_cb).erroroffset = __param_offset)

        return 0

    }

    ((*__local_args).header.next = ((null as *mut compile_data)))

    ((*__local_args).size = __local_size)

    if ((if (*__param_cb).last_data != null: 1 else: 0) != 0) {
        ((*(*__param_cb).last_data).next = (((&raw const (*__local_args).header as *const compile_data) as *mut compile_data)))
    } else {
        ((*__param_cb).first_data = (((&raw const (*__local_args).header as *const compile_data) as *mut compile_data)))
    }

    ((*__param_cb).last_data = (((&raw const (*__local_args).header as *const compile_data) as *mut compile_data)))

    (__local_captures = (((__local_args + ((1 as isize) as usize)) as *mut u16)))

    while (1 != 0) {
        (__local_pptr = __local_pptr + 1)

        var __ci_expr_switch_continue_3: i32 = 0

        while true {
            match (((*__local_pptr) as u32) & (4294901760 as u32)) {
                2148925440 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__ci_expr_switch_continue_3 = 1)

                    break


                },
                2149056512 => {
                    (__local_pptr = __local_pptr + 1)

                    (__local_ng = (*__param_cb).named_groups + ((*__local_pptr) as usize))


                    loop {
                        0
                        if not ((0 != 0)) {
                            break
                        }
                    }

                    var __ci_expr_old_0: *mut u16 = __local_captures

                    (__local_captures = __local_captures + 1)

                    ((*__ci_expr_old_0) = (((*__local_ng).number as u16)))


                    (__local_name = (*__local_ng).name)

                    while true {
                        (__local_ng = __local_ng + 1)

                        if (not ((if __local_ng < __local_end: 1 else: 0) != 0)) {
                            break
                        }

                        if ((if (*__local_ng).name == __local_name: 1 else: 0) != 0) {
                            var __ci_expr_old_1: *mut u16 = __local_captures

                            (__local_captures = __local_captures + 1)

                            ((*__ci_expr_old_1) = (((*__local_ng).number as u16)))

                        }

                    }

                    (__ci_expr_switch_continue_3 = 1)

                    break


                },
                2149122048 => {
                    var __ci_expr_old_2: *mut u16 = __local_captures

                    (__local_captures = __local_captures + 1)

                    (__local_pptr = __local_pptr + 1)

                    ((*__ci_expr_old_2) = (((*__local_pptr) as u16)))


                    (__ci_expr_switch_continue_3 = 1)

                    break


                },
                _ => {
                    0
                },
            }

            break

        }

        if (__ci_expr_switch_continue_3 != 0) {
            continue
        }


        break

    }

    loop {
        0
        if not ((0 != 0)) {
            break
        }
    }

    ((*__local_args).skip_size = ((((((((__local_pptr as usize) -% (__param_pptr_start as usize)) as i64) / (sizeof[u32]() as i64)) as u64) -% (1 as u64)) as u64)))

    if ((if __local_size == 1: 1 else: 0) != 0) {
        return 1
    }

    (__local_captures = (((__local_args + ((1 as isize) as usize)) as *mut u16)))

    (__local_i = ((((((__local_size as u64) >> (1 as u32)) as u64) -% (1 as u64)) as u64)))

    while (1 != 0) {
        do_heapify_u16(__local_captures, __local_size, __local_i)

        if ((if __local_i == 0: 1 else: 0) != 0) {
            break
        }

        (__local_i = (__local_i -% 1))

    }

    (__local_i = ((((__local_size as u64) -% (1 as u64)) as u64)))

    while ((if __local_i > 0: 1 else: 0) != 0) {
        (__local_tmp = (((__local_captures[0]) as u16)))

        ((__local_captures[0]) = (((__local_captures[__local_i]) as u16)))

        ((__local_captures[__local_i]) = __local_tmp)

        do_heapify_u16(__local_captures, __local_i, (0 as u64))


        (__local_i = (__local_i -% 1))

    }


    (__local_captures_end = __local_captures + (__local_size as usize))

    var __ci_expr_old_4: *mut u16 = __local_captures

    (__local_captures = __local_captures + 1)

    (__local_tmp = (*__ci_expr_old_4))


    (__local_current = __local_captures)

    while ((if __local_current < __local_captures_end: 1 else: 0) != 0) {
        if ((if (*__local_current) != __local_tmp: 1 else: 0) != 0) {
            (__local_tmp = (*__local_current))

            var __ci_expr_old_5: *mut u16 = __local_captures

            (__local_captures = __local_captures + 1)

            ((*__ci_expr_old_5) = __local_tmp)


        }

        (__local_current = __local_current + 1)

    }

    ((*__local_args).size = ((((((__local_captures as usize) -% (((__local_args + ((1 as isize) as usize)) as *mut u16) as usize)) as i64) / (sizeof[u16]() as i64)) as u64)))

    return 1

}

unsafe fn _pcre2_compile_process_capture_list(__param_pptr: *mut u32, __param_offset: u64, __param_errorcodeptr: *mut i32, __param_cb: *mut compile_block_8) -> u64 {
    var __local_pptr = __param_pptr
    var __local_offset = __param_offset
    var __local_i: u64

    var __local_size: u64 = ((0 as u64))


    var __local_ng: *mut named_group_8

    var __local_name: *const u8

    var __local_length: u32

    var __local_end: *mut named_group_8 = ((*__param_cb).named_groups + (((*__param_cb).names_found as u32) as usize))

    while (1 != 0) {
        (__local_pptr = __local_pptr + 1)

        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match (((*__local_pptr) as u32) & (4294901760 as u32)) {
                2148925440 => {
                    (__local_offset = (((((((__local_pptr[1]) as u64) << (32 as u32)) as u64) | ((__local_pptr[2]) as u64)) as u64)))

                    (__local_pptr = __local_pptr + ((2 as isize) as usize))


                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149056512 => {
                    (__local_offset = (__local_offset +% (((*__local_pptr) as u32) & (65535 as u32))))

                    (__local_pptr = __local_pptr + 1)

                    (__local_length = (*__local_pptr))


                    (__local_name = (*__param_cb).start_pattern + (__local_offset as usize))

                    (__local_ng = _pcre2_compile_find_named_group8(__local_name, __local_length, __param_cb))

                    if ((if __local_ng == null: 1 else: 0) != 0) {
                        ((*__param_errorcodeptr) = ERR15)

                        ((*__param_cb).erroroffset = __local_offset)

                        return ((0 as u64))

                    }

                    if ((if (((*__local_ng).hash_dup as i32) & (32768 as i32)) == 0: 1 else: 0) != 0) {
                        ((__local_pptr[-1]) = ((2149122048 as u32)))

                        ((__local_pptr[0]) = (*__local_ng).number)

                        (__local_size = (__local_size +% 1))

                        (__ci_expr_switch_continue_0 = 1)

                        break


                    }

                    ((__local_pptr[-1]) = ((2149056512 as u32)))

                    ((__local_pptr[0]) = ((((((__local_ng as usize) -% ((*__param_cb).named_groups as usize)) as i64) / (sizeof[named_group_8]() as i64)) as u32)))

                    (__local_size = (__local_size +% 1))

                    (__local_name = (*__local_ng).name)

                    while true {
                        (__local_ng = __local_ng + 1)

                        if (not ((if __local_ng < __local_end: 1 else: 0) != 0)) {
                            break
                        }

                        if ((if (*__local_ng).name == __local_name: 1 else: 0) != 0) {
                            (__local_size = (__local_size +% 1))
                        }

                    }

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149122048 => {
                    (__local_offset = (__local_offset +% (((*__local_pptr) as u32) & (65535 as u32))))

                    (__local_pptr = __local_pptr + 1)

                    (__local_i = (((*__local_pptr) as u64)))


                    if ((if __local_i > (*__param_cb).bracount: 1 else: 0) != 0) {
                        ((*__param_errorcodeptr) = ERR15)

                        ((*__param_cb).erroroffset = __local_offset)

                        return ((0 as u64))

                    }

                    if ((if __local_i > (*__param_cb).top_backref: 1 else: 0) != 0) {
                        ((*__param_cb).top_backref = (((__local_i as u16) as u32)))
                    }

                    (__local_size = (__local_size +% 1))

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                _ => {
                    0
                },
            }

            break

        }

        if (__ci_expr_switch_continue_0 != 0) {
            continue
        }


        loop {
            0
            if not ((0 != 0)) {
                break
            }
        }

        return __local_size

    }

}

unsafe fn do_heapify_u16(__param_captures: *mut u16, __param_size: u64, __param_i: u64) {
    var __local_i = __param_i
    var __local_max: u64

    var __local_left: u64

    var __local_right: u64

    var __local_tmp: u16

    while (1 != 0) {
        (__local_max = __local_i)

        (__local_left = ((((((__local_i as u64) << (1 as u32)) as u64) +% (1 as u64)) as u64)))

        (__local_right = ((((__local_left as u64) +% (1 as u64)) as u64)))

        var __ci_expr_logic_0: i32 = 0

        if ((if __local_left < __param_size: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (__param_captures[__local_left]) > (__param_captures[__local_max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_max = __local_left)
        }


        var __ci_expr_logic_1: i32 = 0

        if ((if __local_right < __param_size: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (__param_captures[__local_right]) > (__param_captures[__local_max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_max = __local_right)
        }


        if ((if __local_i == __local_max: 1 else: 0) != 0) {
            return
        }

        (__local_tmp = (((__param_captures[__local_i]) as u16)))

        ((__param_captures[__local_i]) = (((__param_captures[__local_max]) as u16)))

        ((__param_captures[__local_max]) = __local_tmp)

        (__local_i = __local_max)

    }

}
