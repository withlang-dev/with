// Migrated from PCRE2
use std.re.defs

@[c_export("_pcre2_compile_get_hash_from_name8")]
fn _pcre2_compile_get_hash_from_name8(__param_name: *const u8, __param_length: c_uint) -> c_ushort {
    var __local_hash: c_ushort

    do {
        0
    } while (0 != 0)

    (__local_hash = ((((((unsafe: __param_name[0]) as c_int) & 127) | (((((unsafe: __param_name[((__param_length as c_uint) -% (1 as c_uint))]) as c_int) & 255) as c_int) << (7 as c_uint))) as c_ushort)))

    do {
        0
    } while (0 != 0)

    return __local_hash

}

@[c_export("_pcre2_compile_find_named_group8")]
fn _pcre2_compile_find_named_group8(__param_name: *const u8, __param_length: c_uint, __param_cb: *mut compile_block_8) -> *mut named_group_8 {
    var __local_hash: c_ushort = _pcre2_compile_get_hash_from_name8(__param_name, __param_length)

    var __local_ng: *mut named_group_8

    var __local_end: *mut named_group_8 = (__param_cb.named_groups + ((__param_cb.names_found as c_uint) as usize))

    (__local_ng = __param_cb.named_groups)

    while ((if __local_ng < __local_end: 1 else: 0) != 0) {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_logic_0: c_int = 0

        if ((if __param_length == __local_ng.length: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_hash == ((__local_ng.hash_dup as c_int) & (32767 as c_int)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if _pcre2_strncmp_8(__param_name, __local_ng.name, __param_length) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return __local_ng
        }


        (__local_ng = __local_ng + 1)

    }


    return null

}

@[c_export("_pcre2_compile_add_name_to_table8")]
fn _pcre2_compile_add_name_to_table8(__param_cb: *mut compile_block_8, __param_ng: *mut named_group_8, __param_tablecount: c_uint) -> c_uint {
    var __local_ng = __param_ng
    var __local_tablecount = __param_tablecount
    var __local_i: c_uint

    var __local_name: *const u8 = __local_ng.name

    var __local_length: c_int = __local_ng.length

    var __local_duplicate_count: c_uint = 1

    var __local_slot: *mut u8 = __param_cb.name_table

    do {
        0
    } while (0 != 0)

    if ((if ((__local_ng.hash_dup as c_int) & (32768 as c_int)) != 0: 1 else: 0) != 0) {
        var __local_ng_it: *mut named_group_8

        var __local_end: *mut named_group_8 = (__param_cb.named_groups + ((__param_cb.names_found as c_uint) as usize))

        (__local_ng_it = __local_ng + ((1 as isize) as usize))

        while ((if __local_ng_it < __local_end: 1 else: 0) != 0) {
            if ((if __local_ng_it.name == __local_name: 1 else: 0) != 0) {
                (__local_duplicate_count = __local_duplicate_count + 1)
            }

            (__local_ng_it = __local_ng_it + 1)

        }


    }

    (__local_i = 0)

    while ((if __local_i < __local_tablecount: 1 else: 0) != 0) {
        var __local_crc: c_int = with_memcmp((__local_name as *i8), ((__local_slot + ((2 as isize) as usize)) as *i8), ((__local_length * (8 / 8)) as i64))

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_crc == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: __local_slot[(2 + __local_length)]) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_crc = -1)
        }


        if ((if __local_crc < 0: 1 else: 0) != 0) {
            with_memmove(((__local_slot + ((((__param_cb.name_entry_size as c_int) as c_uint) *% (__local_duplicate_count as c_uint)) as usize)) as *i8), (__local_slot as *i8), (((((((__local_tablecount as c_uint) -% (__local_i as c_uint)) as c_uint) *% ((__param_cb.name_entry_size as c_int) as c_uint)) as c_uint) *% (1 as c_uint)) as i64))

            break

        }

        (__local_slot = __local_slot + ((__param_cb.name_entry_size as c_uint) as usize))


        (__local_i = __local_i + 1)

    }


    (__local_tablecount = __local_tablecount + __local_duplicate_count)

    while (1 != 0) {
        ((unsafe: __local_slot[0]) = (__local_ng.number as c_uint) >> (8 as c_uint))

        ((unsafe: __local_slot[(0 + 1)]) = (__local_ng.number as c_uint) & (255 as c_uint))


        with_memcpy(((__local_slot + ((2 as isize) as usize)) as *i8), (__local_name as *i8), ((__local_length * (8 / 8)) as i64))

        with_memset((((__local_slot + ((2 as isize) as usize)) + ((__local_length as isize) as usize)) as *i8), 0, (((((__param_cb.name_entry_size as c_int) - __local_length) - 2) * (8 / 8)) as i64))

        (__local_duplicate_count = __local_duplicate_count - 1)

        if ((if __local_duplicate_count == 0: 1 else: 0) != 0) {
            break
        }


        while (1 != 0) {
            (__local_ng = __local_ng + 1)

            if ((if __local_ng.name == __local_name: 1 else: 0) != 0) {
                break
            }

        }

        (__local_slot = __local_slot + ((__param_cb.name_entry_size as c_uint) as usize))

    }

    return __local_tablecount

}

@[c_export("_pcre2_compile_find_dupname_details8")]
fn _pcre2_compile_find_dupname_details8(__param_name: *const u8, __param_length: c_uint, __param_indexptr: *mut c_int, __param_countptr: *mut c_int, __param_errorcodeptr: *mut c_int, __param_cb: *mut compile_block_8) -> c_int {
    var __local_i: c_uint

    var __local_groupnumber: c_uint


    var __local_count: c_int

    var __local_slot: *mut u8 = __param_cb.name_table

    (__local_i = 0)

    while ((if __local_i < __param_cb.names_found: 1 else: 0) != 0) {
        var __ci_expr_logic_0: c_int = 0

        if ((if _pcre2_strncmp_8(__param_name, (__local_slot + ((2 as isize) as usize)), __param_length) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: __local_slot[((2 as c_uint) +% (__param_length as c_uint))]) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            break
        }


        (__local_slot = __local_slot + ((__param_cb.name_entry_size as c_uint) as usize))


        (__local_i = __local_i + 1)

    }


    if ((if __local_i >= __param_cb.names_found: 1 else: 0) != 0) {
        do {
            0
        } while (0 != 0)

        ((unsafe: *__param_errorcodeptr) = ERR53)

        ((unsafe: *__param_cb).erroroffset = ((__param_name as usize) -% (__param_cb.start_pattern as usize)) / sizeof[u8]())

        return 0

    }

    ((unsafe: *__param_indexptr) = __local_i)

    (__local_count = 0)

    while true {
        (__local_count = __local_count + 1)

        (__local_groupnumber = ((((((unsafe: __local_slot[0]) as c_int) << (8 as c_uint)) | ((unsafe: __local_slot[(0 + 1)]) as c_int)) as c_uint)))

        var __ci_expr_ternary_1: c_uint = 0

        if ((if __local_groupnumber < 32: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = (1 as c_uint) << (__local_groupnumber as c_uint))
        } else {
            (__ci_expr_ternary_1 = 1)
        }

        ((unsafe: *__param_cb).backref_map = __param_cb.backref_map | __ci_expr_ternary_1)


        if ((if __local_groupnumber > __param_cb.top_backref: 1 else: 0) != 0) {
            ((unsafe: *__param_cb).top_backref = __local_groupnumber)
        }

        (__local_i = __local_i + 1)

        if ((if __local_i >= __param_cb.names_found: 1 else: 0) != 0) {
            break
        }


        (__local_slot = __local_slot + ((__param_cb.name_entry_size as c_uint) as usize))

        var __ci_expr_logic_2: c_int

        if ((if _pcre2_strncmp_8(__param_name, (__local_slot + ((2 as isize) as usize)), __param_length) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (unsafe: (__local_slot + ((2 as isize) as usize))[__param_length]) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            break
        }


    }

    ((unsafe: *__param_countptr) = __local_count)

    return 1

}

@[c_export("_pcre2_compile_parse_scan_substr_args8")]
fn _pcre2_compile_parse_scan_substr_args8(__param_pptr: *mut c_uint, __param_errorcodeptr: *mut c_int, __param_cb: *mut compile_block_8, __param_lengthptr: *mut c_ulong) -> *mut c_uint {
    var __local_pptr = __param_pptr
    var __local_captures: *mut u8

    var __local_capture_ptr: *mut u8

    var __local_bit: u8

    var __local_name: *const u8

    var __local_ng: *mut named_group_8

    var __local_end: *mut named_group_8 = (__param_cb.named_groups + ((__param_cb.names_found as c_uint) as usize))

    var __local_all_found: c_int

    var __local_size: c_ulong

    do {
        0
    } while (0 != 0)

    if ((if _pcre2_compile_process_capture_list((__local_pptr - ((1 as isize) as usize)), 0, __param_errorcodeptr, __param_cb) == 0: 1 else: 0) != 0) {
        return null
    }

    (__local_size = (((((__param_cb.bracount as c_uint) +% (1 as c_uint)) as c_uint) +% (7 as c_uint)) as c_uint) >> (3 as c_uint))

    (__local_captures = (((&raw const (unsafe: *__param_cb.cx).memctl as *const pcre2_memctl).malloc(__local_size, (&raw const (unsafe: *__param_cb.cx).memctl as *const pcre2_memctl).memory_data) as *mut u8)))

    if ((if __local_captures == null: 1 else: 0) != 0) {
        ((unsafe: *__param_errorcodeptr) = ERR21)

        ((unsafe: *__param_cb).erroroffset = (((((unsafe: __local_pptr[1]) as c_ulong) as c_ulong) << (32 as c_uint)) as c_ulong) | (((unsafe: __local_pptr[2]) as c_ulong) as c_ulong))


        return null

    }

    with_memset((__local_captures as *i8), 0, (__local_size as i64))

    while (1 != 0) {
        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match (((unsafe: *__local_pptr) as c_uint) & ((4294901760 as c_uint) as c_uint)) {
                2148925440 => {
                    (__local_pptr = __local_pptr + 1)

                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149056512 => {
                    (__local_ng = __param_cb.named_groups + ((unsafe: __local_pptr[1]) as usize))

                    do {
                        0
                    } while (0 != 0)

                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__local_name = __local_ng.name)

                    (__local_all_found = 1)

                    do {
                        if ((if __local_ng.name != __local_name: 1 else: 0) != 0) {
                            continue
                        }

                        (__local_capture_ptr = __local_captures + (((__local_ng.number as c_uint) >> (3 as c_uint)) as usize))

                        do {
                            0
                        } while (0 != 0)

                        (__local_bit = ((((1 as c_int) << (((__local_ng.number as c_uint) & (7 as c_uint)) as c_uint)) as u8)))

                        if ((if (((unsafe: *__local_capture_ptr) as c_int) & (__local_bit as c_int)) == 0: 1 else: 0) != 0) {
                            ((unsafe: *__local_capture_ptr) = (unsafe: *__local_capture_ptr) | __local_bit)

                            (__local_all_found = 0)

                        }

                    } while { (__local_ng = __local_ng + 1); ((if __local_ng < __local_end: 1 else: 0) != 0) }

                    if ((if not (__local_all_found != 0): 1 else: 0) != 0) {
                        ((unsafe: *__param_lengthptr) = (unsafe: *__param_lengthptr) + 5)

                        (__ci_expr_switch_continue_0 = 1)

                        break


                    }

                    ((unsafe: __local_pptr[-2]) = 2149122048)

                    ((unsafe: __local_pptr[-1]) = 0)

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149122048 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__local_capture_ptr = __local_captures + ((((unsafe: __local_pptr[-1]) as c_uint) >> (3 as c_uint)) as usize))

                    do {
                        0
                    } while (0 != 0)

                    (__local_bit = ((((1 as c_int) << ((((unsafe: __local_pptr[-1]) as c_uint) & (7 as c_uint)) as c_uint)) as u8)))

                    if ((if (((unsafe: *__local_capture_ptr) as c_int) & (__local_bit as c_int)) != 0: 1 else: 0) != 0) {
                        ((unsafe: __local_pptr[-1]) = 0)

                        (__ci_expr_switch_continue_0 = 1)

                        break


                    }

                    ((unsafe: *__local_capture_ptr) = (unsafe: *__local_capture_ptr) | __local_bit)

                    ((unsafe: *__param_lengthptr) = (unsafe: *__param_lengthptr) + 3)

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

    (&raw const (unsafe: *__param_cb.cx).memctl as *const pcre2_memctl).free(__local_captures, (&raw const (unsafe: *__param_cb.cx).memctl as *const pcre2_memctl).memory_data)

    return (__local_pptr - ((1 as isize) as usize))

}

@[c_export("_pcre2_compile_parse_recurse_args8")]
fn _pcre2_compile_parse_recurse_args8(__param_pptr_start: *mut c_uint, __param_offset: c_ulong, __param_errorcodeptr: *mut c_int, __param_cb: *mut compile_block_8) -> c_int {
    var __local_pptr: *mut c_uint = __param_pptr_start

    var __local_i: c_ulong

    var __local_size: c_ulong


    var __local_name: *const u8

    var __local_ng: *mut named_group_8

    var __local_end: *mut named_group_8 = (__param_cb.named_groups + ((__param_cb.names_found as c_uint) as usize))

    var __local_args: *mut recurse_arguments

    var __local_captures: *mut c_ushort

    var __local_current: *mut c_ushort

    var __local_captures_end: *mut c_ushort

    var __local_tmp: c_ushort

    (__local_size = _pcre2_compile_process_capture_list(__local_pptr, __param_offset, __param_errorcodeptr, __param_cb))

    if ((if __local_size == 0: 1 else: 0) != 0) {
        return 0
    }

    (__local_args = (((&raw const (unsafe: *__param_cb.cx).memctl as *const pcre2_memctl).malloc(((sizeof[recurse_arguments]() as c_ulong) +% (((__local_size as c_ulong) *% (sizeof[u16]() as c_ulong)) as c_ulong)), (&raw const (unsafe: *__param_cb.cx).memctl as *const pcre2_memctl).memory_data) as *mut recurse_arguments)))

    if ((if __local_args == null: 1 else: 0) != 0) {
        ((unsafe: *__param_errorcodeptr) = ERR21)

        ((unsafe: *__param_cb).erroroffset = __param_offset)

        return 0

    }

    ((unsafe: *__local_args).header.next = ((null as *mut compile_data)))

    ((unsafe: *__local_args).size = __local_size)

    if ((if __param_cb.last_data != null: 1 else: 0) != 0) {
        ((unsafe: *__param_cb.last_data).next = (((&raw const (unsafe: *__local_args).header as *const compile_data) as *mut compile_data)))
    } else {
        ((unsafe: *__param_cb).first_data = (((&raw const (unsafe: *__local_args).header as *const compile_data) as *mut compile_data)))
    }

    ((unsafe: *__param_cb).last_data = (((&raw const (unsafe: *__local_args).header as *const compile_data) as *mut compile_data)))

    (__local_captures = (((__local_args + ((1 as isize) as usize)) as *mut c_ushort)))

    while (1 != 0) {
        (__local_pptr = __local_pptr + 1)

        var __ci_expr_switch_continue_3: i32 = 0

        while true {
            match (((unsafe: *__local_pptr) as c_uint) & ((4294901760 as c_uint) as c_uint)) {
                2148925440 => {
                    (__local_pptr = __local_pptr + ((2 as isize) as usize))

                    (__ci_expr_switch_continue_3 = 1)

                    break


                },
                2149056512 => {
                    (__local_pptr = __local_pptr + 1)

                    (__local_ng = __param_cb.named_groups + ((unsafe: *__local_pptr) as usize))


                    do {
                        0
                    } while (0 != 0)

                    var __ci_expr_old_0: *mut c_ushort = __local_captures

                    (__local_captures = __local_captures + 1)

                    ((unsafe: *__ci_expr_old_0) = ((__local_ng.number as c_ushort)))


                    (__local_name = __local_ng.name)

                    while true {
                        (__local_ng = __local_ng + 1)

                        if (not ((if __local_ng < __local_end: 1 else: 0) != 0)) {
                            break
                        }

                        if ((if __local_ng.name == __local_name: 1 else: 0) != 0) {
                            var __ci_expr_old_1: *mut c_ushort = __local_captures

                            (__local_captures = __local_captures + 1)

                            ((unsafe: *__ci_expr_old_1) = ((__local_ng.number as c_ushort)))

                        }

                    }

                    (__ci_expr_switch_continue_3 = 1)

                    break


                },
                2149122048 => {
                    var __ci_expr_old_2: *mut c_ushort = __local_captures

                    (__local_captures = __local_captures + 1)

                    (__local_pptr = __local_pptr + 1)

                    ((unsafe: *__ci_expr_old_2) = (unsafe: *__local_pptr))


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

    do {
        0
    } while (0 != 0)

    ((unsafe: *__local_args).skip_size = ((((((__local_pptr as usize) -% (__param_pptr_start as usize)) / sizeof[c_uint]()) as c_ulong) as c_ulong) -% (1 as c_ulong)))

    if ((if __local_size == 1: 1 else: 0) != 0) {
        return 1
    }

    (__local_captures = (((__local_args + ((1 as isize) as usize)) as *mut c_ushort)))

    (__local_i = ((((__local_size as c_ulong) >> (1 as c_uint)) as c_ulong) -% (1 as c_ulong)))

    while (1 != 0) {
        do_heapify_u16(__local_captures, __local_size, __local_i)

        if ((if __local_i == 0: 1 else: 0) != 0) {
            break
        }

        (__local_i = __local_i - 1)

    }

    (__local_i = ((__local_size as c_ulong) -% (1 as c_ulong)))

    while ((if __local_i > 0: 1 else: 0) != 0) {
        (__local_tmp = (unsafe: __local_captures[0]))

        ((unsafe: __local_captures[0]) = (unsafe: __local_captures[__local_i]))

        ((unsafe: __local_captures[__local_i]) = __local_tmp)

        do_heapify_u16(__local_captures, __local_i, 0)


        (__local_i = __local_i - 1)

    }


    (__local_captures_end = __local_captures + (__local_size as usize))

    var __ci_expr_old_4: *mut c_ushort = __local_captures

    (__local_captures = __local_captures + 1)

    (__local_tmp = (unsafe: *__ci_expr_old_4))


    (__local_current = __local_captures)

    while ((if __local_current < __local_captures_end: 1 else: 0) != 0) {
        if ((if (unsafe: *__local_current) != __local_tmp: 1 else: 0) != 0) {
            (__local_tmp = (unsafe: *__local_current))

            var __ci_expr_old_5: *mut c_ushort = __local_captures

            (__local_captures = __local_captures + 1)

            ((unsafe: *__ci_expr_old_5) = __local_tmp)


        }

        (__local_current = __local_current + 1)

    }

    ((unsafe: *__local_args).size = (((((__local_captures as usize) -% (((__local_args + ((1 as isize) as usize)) as *mut c_ushort) as usize)) / sizeof[c_ushort]()) as c_ulong)))

    return 1

}

fn _pcre2_compile_process_capture_list(__param_pptr: *mut c_uint, __param_offset: c_ulong, __param_errorcodeptr: *mut c_int, __param_cb: *mut compile_block_8) -> c_ulong {
    var __local_pptr = __param_pptr
    var __local_offset = __param_offset
    var __local_i: c_ulong

    var __local_size: c_ulong = 0


    var __local_ng: *mut named_group_8

    var __local_name: *const u8

    var __local_length: c_uint

    var __local_end: *mut named_group_8 = (__param_cb.named_groups + ((__param_cb.names_found as c_uint) as usize))

    while (1 != 0) {
        (__local_pptr = __local_pptr + 1)

        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match (((unsafe: *__local_pptr) as c_uint) & ((4294901760 as c_uint) as c_uint)) {
                2148925440 => {
                    (__local_offset = (((((unsafe: __local_pptr[1]) as c_ulong) as c_ulong) << (32 as c_uint)) as c_ulong) | (((unsafe: __local_pptr[2]) as c_ulong) as c_ulong))

                    (__local_pptr = __local_pptr + ((2 as isize) as usize))


                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149056512 => {
                    (__local_offset = __local_offset + (((unsafe: *__local_pptr) as c_uint) & (65535 as c_uint)))

                    (__local_pptr = __local_pptr + 1)

                    (__local_length = (unsafe: *__local_pptr))


                    (__local_name = __param_cb.start_pattern + (__local_offset as usize))

                    (__local_ng = _pcre2_compile_find_named_group8(__local_name, __local_length, __param_cb))

                    if ((if __local_ng == null: 1 else: 0) != 0) {
                        ((unsafe: *__param_errorcodeptr) = ERR15)

                        ((unsafe: *__param_cb).erroroffset = __local_offset)

                        return 0

                    }

                    if ((if ((__local_ng.hash_dup as c_int) & (32768 as c_int)) == 0: 1 else: 0) != 0) {
                        ((unsafe: __local_pptr[-1]) = 2149122048)

                        ((unsafe: __local_pptr[0]) = __local_ng.number)

                        (__local_size = __local_size + 1)

                        (__ci_expr_switch_continue_0 = 1)

                        break


                    }

                    ((unsafe: __local_pptr[-1]) = 2149056512)

                    ((unsafe: __local_pptr[0]) = (((((__local_ng as usize) -% (__param_cb.named_groups as usize)) / sizeof[named_group_8]()) as c_uint)))

                    (__local_size = __local_size + 1)

                    (__local_name = __local_ng.name)

                    while true {
                        (__local_ng = __local_ng + 1)

                        if (not ((if __local_ng < __local_end: 1 else: 0) != 0)) {
                            break
                        }

                        if ((if __local_ng.name == __local_name: 1 else: 0) != 0) {
                            (__local_size = __local_size + 1)
                        }

                    }

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2149122048 => {
                    (__local_offset = __local_offset + (((unsafe: *__local_pptr) as c_uint) & (65535 as c_uint)))

                    (__local_pptr = __local_pptr + 1)

                    (__local_i = (unsafe: *__local_pptr))


                    if ((if __local_i > __param_cb.bracount: 1 else: 0) != 0) {
                        ((unsafe: *__param_errorcodeptr) = ERR15)

                        ((unsafe: *__param_cb).erroroffset = __local_offset)

                        return 0

                    }

                    if ((if __local_i > __param_cb.top_backref: 1 else: 0) != 0) {
                        ((unsafe: *__param_cb).top_backref = ((__local_i as c_ushort)))
                    }

                    (__local_size = __local_size + 1)

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


        do {
            0
        } while (0 != 0)

        return __local_size

    }

}

fn do_heapify_u16(__param_captures: *mut c_ushort, __param_size: c_ulong, __param_i: c_ulong) {
    var __local_i = __param_i
    var __local_max: c_ulong

    var __local_left: c_ulong

    var __local_right: c_ulong

    var __local_tmp: c_ushort

    while (1 != 0) {
        (__local_max = __local_i)

        (__local_left = ((((__local_i as c_ulong) << (1 as c_uint)) as c_ulong) +% (1 as c_ulong)))

        (__local_right = ((__local_left as c_ulong) +% (1 as c_ulong)))

        var __ci_expr_logic_0: c_int = 0

        if ((if __local_left < __param_size: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: __param_captures[__local_left]) > (unsafe: __param_captures[__local_max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_max = __local_left)
        }


        var __ci_expr_logic_1: c_int = 0

        if ((if __local_right < __param_size: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe: __param_captures[__local_right]) > (unsafe: __param_captures[__local_max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_max = __local_right)
        }


        if ((if __local_i == __local_max: 1 else: 0) != 0) {
            return
        }

        (__local_tmp = (unsafe: __param_captures[__local_i]))

        ((unsafe: __param_captures[__local_i]) = (unsafe: __param_captures[__local_max]))

        ((unsafe: __param_captures[__local_max]) = __local_tmp)

        (__local_i = __local_max)

    }

}
