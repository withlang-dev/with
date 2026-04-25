// Migrated from PCRE2
use std.re.defs

fn _pcre2_compile_get_hash_from_name8(name: *const u8, length: c_uint) -> c_ushort {
    var hash: c_ushort

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (hash = (((((unsafe: name[0]) & 127) | ((((unsafe: name[(length -% 1)]) & 255) as c_int) << (7 as c_uint))) as c_ushort)))

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    return hash

}

fn _pcre2_compile_find_named_group8(name: *const u8, length: c_uint, cb: *mut compile_block_8) -> *mut named_group_8 {
    var hash: c_ushort = _pcre2_compile_get_hash_from_name8(name, length)

    var ng: *mut named_group_8

    var end: *mut named_group_8 = (cb.named_groups + ((cb.names_found as isize) as usize))

    (ng = cb.named_groups)

    while ((if ng < end: 1 else: 0) != 0) {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_logic_0: c_int = 0

        if ((if length == ng.length: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if hash == (ng.hash_dup & 32767): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__ci_expr_logic_1 = (if (if _pcre2_strncmp_8(name, ng.name, length) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return ng
        }


        (ng = ng + 1)

    }


    return null

}

fn _pcre2_compile_add_name_to_table8(cb: *mut compile_block_8, __param_ng: *mut named_group_8, __param_tablecount: c_uint) -> c_uint {
    var ng = __param_ng
    var tablecount = __param_tablecount
    var i: c_uint

    var name: *const u8 = ng.name

    var length: c_int = ng.length

    var duplicate_count: c_uint = 1

    var slot: *mut u8 = cb.name_table

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    if ((if (ng.hash_dup & 32768) != 0: 1 else: 0) != 0) {
        var ng_it: *mut named_group_8

        var end: *mut named_group_8 = (cb.named_groups + ((cb.names_found as isize) as usize))

        (ng_it = ng + ((1 as isize) as usize))

        while ((if ng_it < end: 1 else: 0) != 0) {
            if ((if ng_it.name == name: 1 else: 0) != 0) {
                (duplicate_count = duplicate_count + 1)
            }

            (ng_it = ng_it + 1)

        }


    }

    (i = 0)

    while ((if i < tablecount: 1 else: 0) != 0) {
        var crc: c_int = with_memcmp((name as *i8), ((slot + ((2 as isize) as usize)) as *i8), ((length * (8 / 8)) as i64))

        var __ci_expr_logic_0: c_int = 0

        if ((if crc == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: slot[(2 + length)]) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (crc = -1)
        }


        if ((if crc < 0: 1 else: 0) != 0) {
            with_memmove(((slot + (cb.name_entry_size *% duplicate_count)) as *i8), (slot as *i8), ((((tablecount -% i) *% cb.name_entry_size) *% 1) as i64))

            break

        }

        (slot = slot + cb.name_entry_size)


        (i = i + 1)

    }


    (tablecount = tablecount + duplicate_count)

    while (1 != 0) {
        ((unsafe: slot[0]) = (ng.number as c_uint) >> (8 as c_uint))

        ((unsafe: slot[(0 + 1)]) = ng.number & 255)


        with_memcpy(((slot + ((2 as isize) as usize)) as *i8), (name as *i8), ((length * (8 / 8)) as i64))

        with_memset((((slot + ((2 as isize) as usize)) + ((length as isize) as usize)) as *i8), 0, ((((cb.name_entry_size - length) - 2) * (8 / 8)) as i64))

        (duplicate_count = duplicate_count - 1)

        if ((if duplicate_count == 0: 1 else: 0) != 0) {
            break
        }


        while (1 != 0) {
            (ng = ng + 1)

            if ((if ng.name == name: 1 else: 0) != 0) {
                break
            }

        }

        (slot = slot + cb.name_entry_size)

    }

    return tablecount

}

fn _pcre2_compile_find_dupname_details8(name: *const u8, length: c_uint, indexptr: *mut c_int, countptr: *mut c_int, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int {
    var i: c_uint

    var groupnumber: c_uint


    var count: c_int

    var slot: *mut u8 = cb.name_table

    (i = 0)

    while ((if i < cb.names_found: 1 else: 0) != 0) {
        var __ci_expr_logic_0: c_int = 0

        if ((if _pcre2_strncmp_8(name, (slot + ((2 as isize) as usize)), length) == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: slot[(2 +% length)]) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            break
        }


        (slot = slot + cb.name_entry_size)


        (i = i + 1)

    }


    if ((if i >= cb.names_found: 1 else: 0) != 0) {
        while true {
            if (not (0 != 0)) {
                break
            }
        }

        ((unsafe: *errorcodeptr) = ERR53)

        (cb.erroroffset = ((name as usize) -% (cb.start_pattern as usize)) / sizeof[u8]())

        return 0

    }

    ((unsafe: *indexptr) = i)

    (count = 0)

    while true {
        (count = count + 1)

        (groupnumber = ((((((unsafe: slot[0]) as c_int) << (8 as c_uint)) | (unsafe: slot[(0 + 1)])) as c_uint)))

        var __ci_expr_ternary_1: c_uint = 0

        if ((if groupnumber < 32: 1 else: 0) != 0) {
            (__ci_expr_ternary_1 = (1 as c_uint) << (groupnumber as c_uint))
        } else {
            (__ci_expr_ternary_1 = 1)
        }

        (cb.backref_map = cb.backref_map | __ci_expr_ternary_1)


        if ((if groupnumber > cb.top_backref: 1 else: 0) != 0) {
            (cb.top_backref = groupnumber)
        }

        (i = i + 1)

        if ((if i >= cb.names_found: 1 else: 0) != 0) {
            break
        }


        (slot = slot + cb.name_entry_size)

        var __ci_expr_logic_2: c_int

        if ((if _pcre2_strncmp_8(name, (slot + ((2 as isize) as usize)), length) != 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if (unsafe: (slot + ((2 as isize) as usize))[length]) != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_2 != 0) {
            break
        }


    }

    ((unsafe: *countptr) = count)

    return 1

}

fn _pcre2_compile_parse_scan_substr_args8(__param_pptr: *mut c_uint, errorcodeptr: *mut c_int, cb: *mut compile_block_8, lengthptr: *mut c_ulong) -> *mut c_uint {
    var pptr = __param_pptr
    var captures: *mut u8

    var capture_ptr: *mut u8

    var bit: u8

    var name: *const u8

    var ng: *mut named_group_8

    var end: *mut named_group_8 = (cb.named_groups + ((cb.names_found as isize) as usize))

    var all_found: c_int

    var size: c_ulong

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    if ((if _pcre2_compile_process_capture_list((pptr - ((1 as isize) as usize)), 0, errorcodeptr, cb) == 0: 1 else: 0) != 0) {
        return null
    }

    (size = (((cb.bracount +% 1) +% 7) as c_uint) >> (3 as c_uint))

    (captures = ((cb.cx.memctl.malloc(size, cb.cx.memctl.memory_data) as *mut u8)))

    if ((if captures == null: 1 else: 0) != 0) {
        ((unsafe: *errorcodeptr) = ERR21)

        (cb.erroroffset = ((((unsafe: pptr[1]) as c_ulong) as c_ulong) << (32 as c_uint)) | ((unsafe: pptr[2]) as c_ulong))


        return null

    }

    with_memset((captures as *i8), 0, (size as i64))

    while (1 != 0) {
        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match ((unsafe: *pptr) & (4294901760 as c_uint)) {
                2148925440 => {
                    (pptr = pptr + 1)

                    (pptr = pptr + 2)

                    continue

                },
                2149056512 => {
                    (ng = cb.named_groups + (unsafe: pptr[1]))

                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    (pptr = pptr + 2)

                    (name = ng.name)

                    (all_found = 1)

                    while true {
                        if ((if ng.name != name: 1 else: 0) != 0) {
                            continue
                        }

                        (capture_ptr = captures + ((ng.number as c_uint) >> (3 as c_uint)))

                        while true {
                            if (not (0 != 0)) {
                                break
                            }
                        }

                        (bit = ((((1 as c_int) << ((ng.number & 7) as c_uint)) as u8)))

                        if ((if ((unsafe: *capture_ptr) & bit) == 0: 1 else: 0) != 0) {
                            ((unsafe: *capture_ptr) = (unsafe: *capture_ptr) | bit)

                            (all_found = 0)

                        }

                        (ng = ng + 1)

                        if (not ((if ng < end: 1 else: 0) != 0)) {
                            break
                        }

                    }

                    if ((if not (all_found != 0): 1 else: 0) != 0) {
                        ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 5)

                        continue

                    }

                    ((unsafe: pptr[-2]) = 2149122048)

                    ((unsafe: pptr[-1]) = 0)

                    continue

                },
                2149122048 => {
                    (pptr = pptr + 2)

                    (capture_ptr = captures + (((unsafe: pptr[-1]) as c_uint) >> (3 as c_uint)))

                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    (bit = ((((1 as c_int) << (((unsafe: pptr[-1]) & 7) as c_uint)) as u8)))

                    if ((if ((unsafe: *capture_ptr) & bit) != 0: 1 else: 0) != 0) {
                        ((unsafe: pptr[-1]) = 0)

                        continue

                    }

                    ((unsafe: *capture_ptr) = (unsafe: *capture_ptr) | bit)

                    ((unsafe: *lengthptr) = (unsafe: *lengthptr) + 3)

                    continue

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

    cb.cx.memctl.free(captures, cb.cx.memctl.memory_data)

    return (pptr - ((1 as isize) as usize))

}

fn _pcre2_compile_parse_recurse_args8(pptr_start: *mut c_uint, offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_int {
    var pptr: *mut c_uint = pptr_start

    var i: c_ulong

    var size: c_ulong


    var name: *const u8

    var ng: *mut named_group_8

    var end: *mut named_group_8 = (cb.named_groups + ((cb.names_found as isize) as usize))

    var args: *mut recurse_arguments

    var captures: *mut c_ushort

    var current: *mut c_ushort

    var captures_end: *mut c_ushort

    var tmp: c_ushort

    (size = _pcre2_compile_process_capture_list(pptr, offset, errorcodeptr, cb))

    if ((if size == 0: 1 else: 0) != 0) {
        return 0
    }

    (args = ((cb.cx.memctl.malloc((sizeof[recurse_arguments]() +% (size *% sizeof[c_ushort]())), cb.cx.memctl.memory_data) as *mut recurse_arguments)))

    if ((if args == null: 1 else: 0) != 0) {
        ((unsafe: *errorcodeptr) = ERR21)

        (cb.erroroffset = offset)

        return 0

    }

    (args.header.next = ((null as *mut compile_data)))

    (args.size = size)

    if ((if cb.last_data != null: 1 else: 0) != 0) {
        (cb.last_data.next = (((&args.header as *const compile_data) as *mut compile_data)))
    } else {
        (cb.first_data = (((&args.header as *const compile_data) as *mut compile_data)))
    }

    (cb.last_data = (((&args.header as *const compile_data) as *mut compile_data)))

    (captures = (((args + ((1 as isize) as usize)) as *mut c_ushort)))

    while (1 != 0) {
        (pptr = pptr + 1)

        var __ci_expr_switch_continue_3: i32 = 0

        while true {
            match ((unsafe: *pptr) & (4294901760 as c_uint)) {
                2148925440 => {
                    (pptr = pptr + 2)

                    continue

                },
                2149056512 => {
                    (pptr = pptr + 1)

                    (ng = cb.named_groups + (unsafe: *pptr))


                    while true {
                        if (not (0 != 0)) {
                            break
                        }
                    }

                    var __ci_expr_old_0: *mut c_ushort = captures

                    (captures = captures + 1)

                    ((unsafe: *__ci_expr_old_0) = ((ng.number as c_ushort)))


                    (name = ng.name)

                    while true {
                        (ng = ng + 1)

                        if (not ((if ng < end: 1 else: 0) != 0)) {
                            break
                        }

                        if ((if ng.name == name: 1 else: 0) != 0) {
                            var __ci_expr_old_1: *mut c_ushort = captures

                            (captures = captures + 1)

                            ((unsafe: *__ci_expr_old_1) = ((ng.number as c_ushort)))

                        }

                    }

                    continue

                },
                2149122048 => {
                    var __ci_expr_old_2: *mut c_ushort = captures

                    (captures = captures + 1)

                    (pptr = pptr + 1)

                    ((unsafe: *__ci_expr_old_2) = (unsafe: *pptr))


                    continue

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

    while true {
        if (not (0 != 0)) {
            break
        }
    }

    (args.skip_size = (((((pptr as usize) -% (pptr_start as usize)) / sizeof[c_uint]()) as c_ulong) -% 1))

    if ((if size == 1: 1 else: 0) != 0) {
        return 1
    }

    (captures = (((args + ((1 as isize) as usize)) as *mut c_ushort)))

    (i = (((size as c_ulong) >> (1 as c_uint)) -% 1))

    while (1 != 0) {
        do_heapify_u16(captures, size, i)

        if ((if i == 0: 1 else: 0) != 0) {
            break
        }

        (i = i - 1)

    }

    (i = (size -% 1))

    while ((if i > 0: 1 else: 0) != 0) {
        (tmp = (unsafe: captures[0]))

        ((unsafe: captures[0]) = (unsafe: captures[i]))

        ((unsafe: captures[i]) = tmp)

        do_heapify_u16(captures, i, 0)


        (i = i - 1)

    }


    (captures_end = captures + size)

    var __ci_expr_old_4: *mut c_ushort = captures

    (captures = captures + 1)

    (tmp = (unsafe: *__ci_expr_old_4))


    (current = captures)

    while ((if current < captures_end: 1 else: 0) != 0) {
        if ((if (unsafe: *current) != tmp: 1 else: 0) != 0) {
            (tmp = (unsafe: *current))

            var __ci_expr_old_5: *mut c_ushort = captures

            (captures = captures + 1)

            ((unsafe: *__ci_expr_old_5) = tmp)


        }

        (current = current + 1)

    }

    (args.size = (((((captures as usize) -% (((args + ((1 as isize) as usize)) as *mut c_ushort) as usize)) / sizeof[c_ushort]()) as c_ulong)))

    return 1

}

fn _pcre2_compile_process_capture_list(__param_pptr: *mut c_uint, __param_offset: c_ulong, errorcodeptr: *mut c_int, cb: *mut compile_block_8) -> c_ulong {
    var pptr = __param_pptr
    var offset = __param_offset
    var i: c_ulong

    var size: c_ulong = 0


    var ng: *mut named_group_8

    var name: *const u8

    var length: c_uint

    var end: *mut named_group_8 = (cb.named_groups + ((cb.names_found as isize) as usize))

    while (1 != 0) {
        (pptr = pptr + 1)

        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match ((unsafe: *pptr) & (4294901760 as c_uint)) {
                2148925440 => {
                    (offset = ((((unsafe: pptr[1]) as c_ulong) as c_ulong) << (32 as c_uint)) | ((unsafe: pptr[2]) as c_ulong))

                    (pptr = pptr + 2)


                    continue

                },
                2149056512 => {
                    (offset = offset + ((unsafe: *pptr) & 65535))

                    (pptr = pptr + 1)

                    (length = (unsafe: *pptr))


                    (name = cb.start_pattern + offset)

                    (ng = _pcre2_compile_find_named_group8(name, length, cb))

                    if ((if ng == null: 1 else: 0) != 0) {
                        ((unsafe: *errorcodeptr) = ERR15)

                        (cb.erroroffset = offset)

                        return 0

                    }

                    if ((if (ng.hash_dup & 32768) == 0: 1 else: 0) != 0) {
                        ((unsafe: pptr[-1]) = 2149122048)

                        ((unsafe: pptr[0]) = ng.number)

                        (size = size + 1)

                        continue

                    }

                    ((unsafe: pptr[-1]) = 2149056512)

                    ((unsafe: pptr[0]) = (((((ng as usize) -% (cb.named_groups as usize)) / sizeof[named_group_8]()) as c_uint)))

                    (size = size + 1)

                    (name = ng.name)

                    while true {
                        (ng = ng + 1)

                        if (not ((if ng < end: 1 else: 0) != 0)) {
                            break
                        }

                        if ((if ng.name == name: 1 else: 0) != 0) {
                            (size = size + 1)
                        }

                    }

                    continue

                },
                2149122048 => {
                    (offset = offset + ((unsafe: *pptr) & 65535))

                    (pptr = pptr + 1)

                    (i = (unsafe: *pptr))


                    if ((if i > cb.bracount: 1 else: 0) != 0) {
                        ((unsafe: *errorcodeptr) = ERR15)

                        (cb.erroroffset = offset)

                        return 0

                    }

                    if ((if i > cb.top_backref: 1 else: 0) != 0) {
                        (cb.top_backref = ((i as c_ushort)))
                    }

                    (size = size + 1)

                    continue

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


        while true {
            if (not (0 != 0)) {
                break
            }
        }

        return size

    }

}

fn do_heapify_u16(captures: *mut c_ushort, size: c_ulong, __param_i: c_ulong) {
    var i = __param_i
    var max: c_ulong

    var left: c_ulong

    var right: c_ulong

    var tmp: c_ushort

    while (1 != 0) {
        (max = i)

        (left = (((i as c_ulong) << (1 as c_uint)) +% 1))

        (right = (left +% 1))

        var __ci_expr_logic_0: c_int = 0

        if ((if left < size: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe: captures[left]) > (unsafe: captures[max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (max = left)
        }


        var __ci_expr_logic_1: c_int = 0

        if ((if right < size: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if (unsafe: captures[right]) > (unsafe: captures[max]): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (max = right)
        }


        if ((if i == max: 1 else: 0) != 0) {
            return
        }

        (tmp = (unsafe: captures[i]))

        ((unsafe: captures[i]) = (unsafe: captures[max]))

        ((unsafe: captures[max]) = tmp)

        (i = max)

    }

}
