// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.harness
use std.libc
use std.option

extern fn assert_str(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const i8, __param_real: *const i8, __param_caller: *const i8, __param_line: c_int)
extern fn assert_wstr(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_int, __param_real: *const c_int, __param_caller: *const i8, __param_line: c_int)
extern fn assert_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_interval(__param_diag: c_int, __param_low: c_long, __param_high: c_long, __param_real: c_long, __param_caller: *const i8, __param_line: c_int)
extern fn assert_pointers(__param_diag: c_int, __param_cmp: *const i8, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const i8, __param_line: c_int)
extern fn assert_bool(__param_diag: c_int, __param_exp: bool, __param_real: bool, __param_caller: *const i8, __param_line: c_int)
extern fn assert_dbl_compare(__param_diag: c_int, __param_cmp: *const i8, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const i8, __param_line: c_int)
extern fn assert_fail(__param_caller: *const i8, __param_line: c_int)
unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: c_long) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as c_ulong) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

unsafe fn c_basehash_n(__param_key: *const c_void, __param_len: c_long) -> c_ulong {
    var __local_len = __param_len
    var __local_msg: *const u8 = ((__param_key as *const u8))

    var __local_h: c_ulong = ((((0 as c_ulong) -% 3750763034362895579) as c_ulong))

    var __local_block: c_ulong = ((0 as c_ulong))


    while ((if __local_len >= ((sizeof[c_ulong]() as c_long)): 1 else: 0) != 0) {
        with_memcpy((((&raw mut __local_block as *mut c_ulong) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[c_ulong]() as c_ulong) as i64))

        (__local_h = (__local_h as c_ulong) ^ (__local_block as c_ulong))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[c_ulong]() as c_long) as usize))

        (__local_len = __local_len - (sizeof[c_ulong]() as c_long))

    }

    while true {
        var __ci_expr_old_0: c_long = __local_len

        (__local_len = __local_len - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as c_ulong) ^ ((*__ci_expr_old_1) as c_ulong))

        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_n(__param_key: *const c_void, __param_len: c_long) -> c_ulong {
    var __local_b8: c_ulonglong

    var __local_b4: c_uint

    match __param_len {
        8 => {
            with_memcpy((((&raw mut __local_b8 as *mut c_ulonglong) as *mut c_void) as *mut u8), (__param_key as *const u8), ((8 as c_ulong) as i64))

            return ((((__local_b8 as c_ulonglong) *% (((0 as c_ulonglong) -% 4132994306676758115) as c_ulonglong)) as c_ulong))

        },
        4 => {
            with_memcpy((((&raw mut __local_b4 as *mut c_uint) as *mut c_void) as *mut u8), (__param_key as *const u8), ((4 as c_ulong) as i64))

            return ((__local_b4 as c_ulong) *% (((0 as c_ulong) -% 3750763034362895579) as c_ulong))

        },
        _ => {
            return c_basehash_n(__param_key, __param_len)
        },
    }

}

unsafe fn c_hash_str(__param_str: *const i8) -> c_ulong {
    var __local_msg: *const u8 = ((__param_str as *const u8))

    var __local_h: c_ulong = ((((0 as c_ulong) -% 3750763034362895579) as c_ulong))

    while ((*__local_msg) != 0) {
        var __ci_expr_old_0: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as c_ulong) ^ ((*__ci_expr_old_0) as c_ulong))


        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_mix_n(__param_h: *mut c_ulong, __param_n: c_long) -> c_ulong {
    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        ((__param_h[0]) = ((__param_h[0]) +% (((__param_h[0]) as c_ulong) ^ ((__param_h[__local_i]) as c_ulong))))

        (__local_i = __local_i + 1)

    }


    return (__param_h[0])

}

fn c_next_pow2(__param_n: c_long) -> c_long {
    var __local_n = __param_n
    (__local_n = __local_n - 1)

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (1 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (2 as c_uint)) as c_long))


    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (4 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (8 as c_uint)) as c_long))


    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (16 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (32 as c_uint)) as c_long))

    return (__local_n + 1)

}

unsafe fn c_strnstrn(__param_str: *const i8, __param_slen: c_long, __param_needle: *const i8, __param_nlen: c_long) -> *mut i8 {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return (((__local_str as *mut c_char) as *mut i8))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut i8))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: c_int = 0

        if ((if (*__local_str) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return (((__local_str as *mut c_char) as *mut i8))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: c_long = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut i8))

}

unsafe fn IList_drop(__param_cself: *const IList) {
    var __local_self_: *mut IList = ((__param_cself as *mut IList))

    while ((*__local_self_).last != null) {
        IList_erase_after_node(__local_self_, (*__local_self_).last)
    }

}

unsafe fn IList_push_back(__param_self_: *mut IList, __param_value: c_int) -> *mut c_int {
    var __local_entry: *mut IList_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[IList_node]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut IList_node))

    ((*__local_entry).value = __param_value)

    if ((*__param_self_).last != null) {
        ((*__local_entry).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    ((*__param_self_).last = __local_entry)

    return (((&raw const (*__local_entry).value as *const c_int) as *mut c_int))

}

unsafe fn IList_push_front(__param_self_: *mut IList, __param_value: c_int) -> *mut c_int {
    var __local_entry: *mut IList_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[IList_node]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut IList_node))

    ((*__local_entry).value = __param_value)

    if ((*__param_self_).last != null) {
        ((*__local_entry).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = __local_entry)
    }

    return (((&raw const (*__local_entry).value as *const c_int) as *mut c_int))

}

unsafe fn IList_insert_at(__param_self_: *mut IList, __param_it_: IList_iter, __param_value: c_int) -> IList_iter {
    var __local_node: *mut IList_node = (if (*(&raw const __param_it_ as *const IList_iter)).ref != null: (*(&raw const __param_it_ as *const IList_iter)).prev else: (*__param_self_).last)

    var __local_entry: *mut IList_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[IList_node]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut IList_node))

    ((*__local_entry).value = __param_value)

    if (__local_node != null) {
        ((*__local_entry).next = (*__local_node).next)

        ((*__local_node).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    var __ci_expr_logic_0: c_int

    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*(&raw const __param_it_ as *const IList_iter)).ref == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__param_it_.prev = (if (*__param_self_).last != null: (*__param_self_).last else: __local_entry))

        ((*__param_self_).last = __local_entry)

    }


    (__param_it_.ref = (((&raw const (*__local_entry).value as *const c_int) as *mut c_int)))

    return __param_it_

}

unsafe fn IList_erase_at(__param_self_: *mut IList, __param_it_: IList_iter) -> IList_iter {
    var __local_node: *mut IList_node = (((if 1 != 0: (*(&raw const __param_it_ as *const IList_iter)).ref else: (null as *mut c_int)) as *mut IList_node))

    (__param_it_.ref = (if (if __local_node == (*__param_self_).last: 1 else: 0) != 0: (null as *mut c_int) else: ((&raw const (*(*__local_node).next).value as *const c_int) as *mut c_int)))

    IList_erase_after_node(__param_self_, (*(&raw const __param_it_ as *const IList_iter)).prev)

    return __param_it_

}

unsafe fn IList_erase_range(__param_self_: *mut IList, __param_it1: IList_iter, __param_it2: IList_iter) -> IList_iter {
    var __local_end: *mut IList_node = (if (*(&raw const __param_it2 as *const IList_iter)).ref != null: ((if 1 != 0: (*(&raw const __param_it2 as *const IList_iter)).ref else: (null as *mut c_int)) as *mut IList_node) else: (*(*__param_self_).last).next)

    if ((if (*(&raw const __param_it1 as *const IList_iter)).ref != (*(&raw const __param_it2 as *const IList_iter)).ref: 1 else: 0) != 0) {
        loop {
            IList_erase_after_node(__param_self_, (*(&raw const __param_it1 as *const IList_iter)).prev)

            if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
                break
            }

            if not (((if (*(*(&raw const __param_it1 as *const IList_iter)).prev).next != __local_end: 1 else: 0) != 0)) {
                break
            }
        }
    }

    return __param_it2

}

unsafe fn IList_find_in(__param_self_: *const IList, __param_it1: IList_iter, __param_it2: IList_iter, __param_val: c_int) -> IList_iter {

    var __local_it_: IList_iter = __param_it1

    var __local__endref_it: *mut IList_iter = (((if 1 != 0: (*(&raw const __param_it2 as *const IList_iter)).ref else: (null as *mut c_int)) as *mut IList_iter))


    while ((if (*(&raw const __local_it_ as *const IList_iter)).ref != ((__local__endref_it as *mut c_int)): 1 else: 0) != 0) {
        var __local_r: c_int = (*((*(&raw const __local_it_ as *const IList_iter)).ref))

        if ((if (*(&raw mut __local_r as *mut c_int)) == (*(&raw mut __param_val as *mut c_int)): 1 else: 0) != 0) {
            return __local_it_
        }


        IList_next((&raw mut __local_it_ as *mut IList_iter))

    }


    (__param_it2.ref = ((null as *mut c_int)))

    return __param_it2

}

unsafe fn IList_remove(__param_self_: *mut IList, __param_val: c_int) -> c_long {
    var __local_n: c_long = ((0 as c_long))

    var __local_prev: *mut IList_node = (*__param_self_).last

    var __local_node: *mut IList_node


    if (__local_prev != null) {
        loop {
            (__local_node = (*__local_prev).next)

            var __local_r: c_int = (*((&raw const (*__local_node).value as *const c_int) as *mut c_int))

            if ((if (*(&raw mut __local_r as *mut c_int)) == (*(&raw mut __param_val as *mut c_int)): 1 else: 0) != 0) {
                IList_erase_after_node(__param_self_, __local_prev)

                (__local_n = __local_n + 1)


                if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
                    break
                }

            } else {
                (__local_prev = __local_node)
            }

            if not (((if __local_node != (*__param_self_).last: 1 else: 0) != 0)) {
                break
            }
        }
    }

    return __local_n

}

unsafe fn IList_sort(__param_self_: *mut IList) -> bool {
    var __local_len__goto_410_13: c_long = 0

    var __local_cap__goto_410_22: c_long = 0

    var __local_arr__goto_411_15: *mut c_int = null

    var __local_p__goto_411_28: *mut c_int = null

    var __local_keep__goto_412_14: *mut IList_node = null

    var __local_i__goto_413_10: IList_iter = IList_iter.zeroed()

    var __local_cap_n__goto_415_21: c_long = 0

    var __local_i__goto_426_10: IList_iter = IList_iter.zeroed()

    var __ci_expr_old_0: c_long = 0

    var __ci_expr_old_1: *mut c_int = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_len__goto_410_13 = ((0 as c_long)))
        (__local_cap__goto_410_22 = ((0 as c_long)))
        (__local_arr__goto_411_15 = ((null as *mut c_int)))
        (__local_p__goto_411_28 = ((null as *mut c_int)))
        (__local_i__goto_413_10 = IList_begin((((&raw const (*__param_self_) as *const IList) as *mut IList) as *const IList)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if ((*(&raw const __local_i__goto_413_10 as *const IList_iter)).ref != null) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_4
        }
    }

    '__ci_bb_2 {
        if ((if __local_len__goto_410_13 == __local_cap__goto_410_22: 1 else: 0) != 0) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_3 {
        IList_next((&raw mut __local_i__goto_413_10 as *mut IList_iter))
        goto '__ci_bb_1
    }

    '__ci_bb_4 {
        (__local_keep__goto_412_14 = (*__param_self_).last)
        ((*__param_self_).last = ((__local_arr__goto_411_15 as *mut IList_node)))
        IList_sort_lowhigh(__param_self_, (0 as c_long), ((__local_len__goto_410_13 - 1) as c_long))
        ((*__param_self_).last = __local_keep__goto_412_14)
        (__local_i__goto_426_10 = IList_begin((((&raw const (*__param_self_) as *const IList) as *mut IList) as *const IList)))
        goto '__ci_bb_10
    }

    '__ci_bb_5 {
        (__local_cap_n__goto_415_21 = ((((__local_cap__goto_410_22 + (__local_cap__goto_410_22 / 2)) + 8) as c_long)))
        (__local_p__goto_411_28 = (((with_realloc(((__local_arr__goto_411_15 as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_cap_n__goto_415_21 * (sizeof[c_int]() as c_long)) as c_long) else: ((__local_cap__goto_410_22 * (sizeof[c_int]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_int)))
        if ((if __local_p__goto_411_28 == null: 1 else: 0) != 0) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_6 {
        (__ci_expr_old_0 = __local_len__goto_410_13)
        (__local_len__goto_410_13 = __local_len__goto_410_13 + 1)
        ((__local_arr__goto_411_15[__ci_expr_old_0]) = (*((*(&raw const __local_i__goto_413_10 as *const IList_iter)).ref)))
        goto '__ci_bb_3
    }

    '__ci_bb_7 {
        goto '__ci_bb_9
    }

    '__ci_bb_8 {
        (__local_arr__goto_411_15 = __local_p__goto_411_28)
        (__local_cap__goto_410_22 = __local_cap_n__goto_415_21)
        goto '__ci_bb_6
    }

    '__ci_bb_9 {
        (sizeof[c_int]() as usize)
        with_free(((__local_arr__goto_411_15 as *mut c_void) as *mut u8))
        return ((__local_p__goto_411_28 != null))
    }

    '__ci_bb_10 {
        if ((*(&raw const __local_i__goto_426_10 as *const IList_iter)).ref != null) {
            goto '__ci_bb_11
        } else {
            goto '__ci_bb_13
        }
    }

    '__ci_bb_11 {
        (__ci_expr_old_1 = __local_p__goto_411_28)
        (__local_p__goto_411_28 = __local_p__goto_411_28 + 1)
        ((*((*(&raw const __local_i__goto_426_10 as *const IList_iter)).ref)) = (*__ci_expr_old_1))
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        IList_next((&raw mut __local_i__goto_426_10 as *mut IList_iter))
        goto '__ci_bb_10
    }

    '__ci_bb_13 {
        goto '__ci_bb_9
    }

    __ci_unreachable()

}

unsafe fn IList_reverse(__param_self_: *mut IList) -> Unit {
    var __local_rev: IList = (*__param_self_)

    (__local_rev.last = ((null as *mut IList_node)))

    while ((*__param_self_).last != null) {
        var __local_node: *mut IList_node = IList_unlink_after_node(__param_self_, (*__param_self_).last)

        IList_insert_after_node((&raw mut __local_rev as *mut IList), (*(&raw const __local_rev as *const IList)).last, __local_node)

    }

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __local_rev as *const u8), sizeof[IList]())

}

unsafe fn IList_splice(__param_self_: *mut IList, __param_it_: IList_iter, __param_other: *mut IList) -> IList_iter {
    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = (*__param_other).last)
    } else {
        if ((*__param_other).last != null) {
            var __local_p: *mut IList_node = (if (*(&raw const __param_it_ as *const IList_iter)).ref != null: (*(&raw const __param_it_ as *const IList_iter)).prev else: (*__param_self_).last)

            var __local_next: *mut IList_node = (*__local_p).next


            (__param_it_.prev = (*__param_other).last)

            ((*__local_p).next = (*(*(&raw const __param_it_ as *const IList_iter)).prev).next)

            ((*(*(&raw const __param_it_ as *const IList_iter)).prev).next = __local_next)

            if ((if (*(&raw const __param_it_ as *const IList_iter)).ref == null: 1 else: 0) != 0) {
                ((*__param_self_).last = (*(&raw const __param_it_ as *const IList_iter)).prev)
            }

        }
    }

    ((*__param_other).last = ((null as *mut IList_node)))

    return __param_it_

}

unsafe fn IList_split_off(__param_self_: *mut IList, __param_it1: IList_iter, __param_it2: IList_iter) -> IList {
    var __local_lst: IList = (*__param_self_)

    (__local_lst.last = ((null as *mut IList_node)))

    if ((if (*(&raw const __param_it1 as *const IList_iter)).ref == (*(&raw const __param_it2 as *const IList_iter)).ref: 1 else: 0) != 0) {
        return __local_lst
    }

    var __local_p1: *mut IList_node = (*(&raw const __param_it1 as *const IList_iter)).prev

    var __local_p2: *mut IList_node = (if (*(&raw const __param_it2 as *const IList_iter)).ref != null: (*(&raw const __param_it2 as *const IList_iter)).prev else: (*__param_self_).last)


    ((*__local_p1).next = (*__local_p2).next)

    ((*__local_p2).next = (((if 1 != 0: (*(&raw const __param_it1 as *const IList_iter)).ref else: (null as *mut c_int)) as *mut IList_node)))

    if ((if (*__param_self_).last == __local_p2: 1 else: 0) != 0) {
        ((*__param_self_).last = (if (if __local_p1 == __local_p2: 1 else: 0) != 0: (null as *mut IList_node) else: __local_p1))
    }

    (__local_lst.last = __local_p2)

    return __local_lst

}

unsafe fn IList_push_back_node(__param_self_: *mut IList, __param_node: *mut IList_node) -> *mut c_int {
    if ((*__param_self_).last != null) {
        ((*__param_node).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    ((*__param_self_).last = __param_node)

    return (((&raw const (*__param_node).value as *const c_int) as *mut c_int))

}

unsafe fn IList_insert_after_node(__param_self_: *mut IList, __param_ref: *mut IList_node, __param_node: *mut IList_node) -> *mut c_int {
    if (__param_ref != null) {
        ((*__param_node).next = (*__param_ref).next)

        ((*__param_ref).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = __param_node)
    }

    return (((&raw const (*__param_node).value as *const c_int) as *mut c_int))

}

unsafe fn IList_unlink_after_node(__param_self_: *mut IList, __param_ref: *mut IList_node) -> *mut IList_node {
    var __local_node: *mut IList_node = (*__param_ref).next

    var __local_next: *mut IList_node = (*__local_node).next


    ((*__param_ref).next = __local_next)

    if ((if __local_node == __local_next: 1 else: 0) != 0) {
        ((*__param_self_).last = ((null as *mut IList_node)))
    } else {
        if ((if __local_node == (*__param_self_).last: 1 else: 0) != 0) {
            ((*__param_self_).last = __param_ref)
        }
    }

    return __local_node

}

unsafe fn IList_erase_after_node(__param_self_: *mut IList, __param_ref: *mut IList_node) {
    var __local_node: *mut IList_node = IList_unlink_after_node(__param_self_, __param_ref)


    (sizeof[IList_node]() as usize)

    with_free(((__local_node as *mut c_void) as *mut u8))


}

pub unsafe fn IList_get_node(__param_pval: *mut c_int) -> *mut IList_node {
    return (((if 1 != 0: __param_pval else: (null as *mut c_int)) as *mut IList_node))

}

pub unsafe fn IList_unlink_front_node(__param_self_: *mut IList) -> *mut IList_node {
    return ((IList_unlink_after_node(__param_self_, (*__param_self_).last) as *mut IList_node))

}

fn IList_clone(__param_lst: IList) -> IList {
    var __local_out: IList = __param_lst

    var __local_self_: *mut IList = ((&raw mut __local_out as *mut IList))



    (__local_out.last = ((null as *mut IList_node)))

    var __local_it_: IList_iter = unsafe { IList_begin(((&raw mut __param_lst as *mut IList) as *const IList)) }

    while ((unsafe *(&raw const __local_it_ as *const IList_iter)).ref != null) {
        unsafe { IList_push_back((&raw mut __local_out as *mut IList), (*((*(&raw const __local_it_ as *const IList_iter)).ref))) }

        unsafe { IList_next((&raw mut __local_it_ as *mut IList_iter)) }

    }


    return __local_out

}

pub unsafe fn IList_value_clone(__param_self_: *const IList, __param_val: c_int) -> c_int {

    return __param_val

}

pub unsafe fn IList_copy(__param_self_: *mut IList, __param_other: *const IList) -> Unit {
    if ((if (*__param_self_).last == (*__param_other).last: 1 else: 0) != 0) {
        return
    }

    IList_drop((__param_self_ as *const IList))

    let __ci_copy_20: IList = IList_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_20 as *const u8), sizeof[IList]())

}

pub unsafe fn IList_put_n(__param_self_: *mut IList, __param_raw: *const c_int, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        IList_push_back(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn IList_init() -> IList {
    return ((IList.zeroed() as IList))

}

pub unsafe fn IList_from_n(__param_raw: *const c_int, __param_n: c_long) -> IList {
    var __local_cx: IList = IList.zeroed()

    IList_put_n((&raw mut __local_cx as *mut IList), __param_raw, __param_n)

    return __local_cx

}

pub unsafe fn IList_reserve(__param_self_: *mut IList, __param_n: c_long) -> bool {

    return true

}

pub unsafe fn IList_is_empty(__param_self_: *const IList) -> bool {
    return (((*__param_self_).last == null))

}

pub unsafe fn IList_clear(__param_self_: *mut IList) {
    IList_drop((__param_self_ as *const IList))

}

pub unsafe fn IList_push(__param_self_: *mut IList, __param_value: c_int) -> *mut c_int {
    return ((IList_push_back(__param_self_, __param_value) as *mut c_int))

}

pub unsafe fn IList_pop_front(__param_self_: *mut IList) {
    if (((if not ((if not IList_is_empty((__param_self_ as *const IList)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"IList_pop_front".ptr, c"list.h".ptr, (162 as c_int), c"!IList_is_empty(self)".ptr)
    } else {
        0
    }

    IList_erase_after_node(__param_self_, (*__param_self_).last)

}

pub unsafe fn IList_front(__param_self_: *const IList) -> *const c_int {
    return ((((&raw const (*(*(*__param_self_).last).next).value as *const c_int) as *mut c_int) as *const c_int))

}

pub unsafe fn IList_front_mut(__param_self_: *mut IList) -> *mut c_int {
    return (((&raw const (*(*(*__param_self_).last).next).value as *const c_int) as *mut c_int))

}

pub unsafe fn IList_back(__param_self_: *const IList) -> *const c_int {
    return ((((&raw const (*(*__param_self_).last).value as *const c_int) as *mut c_int) as *const c_int))

}

pub unsafe fn IList_back_mut(__param_self_: *mut IList) -> *mut c_int {
    return (((&raw const (*(*__param_self_).last).value as *const c_int) as *mut c_int))

}

pub unsafe fn IList_value_toraw(__param_pval: *const c_int) -> c_int {
    return (*__param_pval)

}

pub unsafe fn IList_value_drop(__param_self_: *const IList, __param_pval: *mut c_int) {
    return
}

pub unsafe fn IList_move(__param_self_: *mut IList) -> IList {
    var __local_m: IList = (*__param_self_)

    ((*__param_self_).last = ((null as *mut IList_node)))

    return __local_m

}

pub unsafe fn IList_take(__param_self_: *mut IList, __param_unowned: IList) -> Unit {
    IList_drop((__param_self_ as *const IList))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[IList]())

}

pub unsafe fn IList_count(__param_self_: *const IList) -> c_long {
    var __local_n: c_long = ((1 as c_long))

    var __local_node: *const IList_node = (((*__param_self_).last as *const IList_node))

    if ((if __local_node == null: 1 else: 0) != 0) {
        return 0
    }

    while true {
        (__local_node = (((*__local_node).next as *const IList_node)))

        if (not ((if __local_node != (*__param_self_).last: 1 else: 0) != 0)) {
            break
        }

        (__local_n = __local_n + 1)

    }

    return __local_n

}

pub unsafe fn IList_begin(__param_self_: *const IList) -> IList_iter {
    var __local_head: *mut c_int = (if (*__param_self_).last != null: ((&raw const (*(*(*__param_self_).last).next).value as *const c_int) as *mut c_int) else: (null as *mut c_int))

    return ((IList_iter { ref: __local_head, _last: (&raw const (*__param_self_).last as *const *mut IList_node), prev: (*__param_self_).last } as IList_iter))

}

pub unsafe fn IList_end(__param_self_: *const IList) -> IList_iter {

    return ((IList_iter.zeroed() as IList_iter))

}

pub unsafe fn IList_next(__param_it_: *mut IList_iter) {
    var __local_node: *mut IList_node = with 0 as __ci_expr_seq_5 {
        ((*__param_it_).prev = (((if 1 != 0: (*__param_it_).ref else: (null as *mut c_int)) as *mut IList_node)))
        (*__param_it_).prev
    }

    ((*__param_it_).ref = (if (if __local_node == (*((*__param_it_)._last)): 1 else: 0) != 0: (null as *mut c_int) else: ((&raw const (*(*__local_node).next).value as *const c_int) as *mut c_int)))

}

pub fn IList_advance(__param_it_: IList_iter, __param_n: c_ulong) -> IList_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_ulong = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const IList_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { IList_next((&raw mut __param_it_ as *mut IList_iter)) }

    }

    return __param_it_

}

pub unsafe fn IList_splice_range(__param_self_: *mut IList, __param_it_: IList_iter, __param_other: *mut IList, __param_it1: IList_iter, __param_it2: IList_iter) -> IList_iter {
    var __local_tmp: IList = IList_split_off(__param_other, __param_it1, __param_it2)

    return IList_splice(__param_self_, __param_it_, (&raw mut __local_tmp as *mut IList))

}

pub unsafe fn IList_find(__param_self_: *const IList, __param_val: c_int) -> IList_iter {
    return IList_find_in(__param_self_, IList_begin(__param_self_), IList_end(__param_self_), __param_val)

}

pub unsafe fn IList_eq(__param_self_: *const IList, __param_other: *const IList) -> bool {
    var __local_i: IList_iter = IList_begin(__param_self_)

    var __local_j: IList_iter = IList_begin(__param_other)


    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((*(&raw const __local_i as *const IList_iter)).ref != null) {
            (__ci_expr_logic_0 = (if (*(&raw const __local_j as *const IList_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        var __local__rx: c_int = (*((*(&raw const __local_i as *const IList_iter)).ref))

        var __local__ry: c_int = (*((*(&raw const __local_j as *const IList_iter)).ref))

        if ((if not ((if (*(&raw const __local__rx as *const c_int)) == (*(&raw const __local__ry as *const c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return false
        }

        IList_next((&raw mut __local_i as *mut IList_iter))

        IList_next((&raw mut __local_j as *mut IList_iter))

    }

    var __ci_expr_logic_1: c_int

    if ((*(&raw const __local_i as *const IList_iter)).ref != null) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (*(&raw const __local_j as *const IList_iter)).ref != null: 1 else: 0))
    }

    return ((not (__ci_expr_logic_1 != 0)))


}

unsafe fn IList_sort_lowhigh(__param_self_: *mut IList, __param_lo: c_long, __param_hi: c_long) -> Unit {
    var __local_lo = __param_lo
    var __local_i: c_long = __local_lo

    var __local_j: c_long


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: c_int = (*((&raw const (((*__param_self_).last as *mut c_int)[((__local_lo + (((__param_hi - __local_lo) * 7) / 16)) as c_long)]) as *const c_int) as *mut c_int))

        var __local_rx: c_int


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (((*__param_self_).last as *mut c_int)[__local_i]) as *const c_int) as *mut c_int)))

                var __ci_expr_logic_0: c_int = 0

                if ((if (*(&raw mut __local_rx as *mut c_int)) < (*(&raw mut __local_pivot as *mut c_int)): 1 else: 0) != 0) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_0 != 0)) {
                    break
                }
            }

            loop {
                (__local_rx = (*((&raw const (((*__param_self_).last as *mut c_int)[__local_j]) as *const c_int) as *mut c_int)))

                var __ci_expr_logic_1: c_int = 0

                if ((if (*(&raw mut __local_pivot as *mut c_int)) < (*(&raw mut __local_rx as *mut c_int)): 1 else: 0) != 0) {
                    (__local_j = __local_j - 1)

                    (__ci_expr_logic_1 = (if __local_j != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_1 != 0)) {
                    break
                }
            }

            if ((if __local_i > __local_j: 1 else: 0) != 0) {
                break
            }

            loop {
                var __local__xp: *mut c_int = (((&raw const (((*__param_self_).last as *mut c_int)[__local_i]) as *const c_int) as *mut c_int))

                var __local__yp: *mut c_int = (((&raw const (((*__param_self_).last as *mut c_int)[__local_j]) as *const c_int) as *mut c_int))


                var __local__tv: c_int = (((*__local__xp) as c_int))

                ((*__local__xp) = (((*__local__yp) as c_int)))

                ((*__local__yp) = __local__tv)

                if not ((0 != 0)) {
                    break
                }
            }

            (__local_i = __local_i + 1)

            (__local_j = __local_j - 1)

            if not (((if __local_i <= __local_j: 1 else: 0) != 0)) {
                break
            }
        }

        if ((if (__local_j - __local_lo) > (__param_hi - __local_i): 1 else: 0) != 0) {
            loop {
                var __local__xp_1: *mut c_long = ((&raw mut __local_lo as *mut c_long))

                var __local__yp_1: *mut c_long = ((&raw mut __local_i as *mut c_long))


                var __local__tv_1: c_long = (((*__local__xp_1) as c_long))

                ((*__local__xp_1) = (((*__local__yp_1) as c_long)))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut c_long = ((&raw mut __param_hi as *mut c_long))

                var __local__yp_2: *mut c_long = ((&raw mut __local_j as *mut c_long))


                var __local__tv_2: c_long = (((*__local__xp_2) as c_long))

                ((*__local__xp_2) = (((*__local__yp_2) as c_long)))

                ((*__local__yp_2) = __local__tv_2)

                if not ((0 != 0)) {
                    break
                }
            }

        }

        if ((if (__local_j - __local_lo) > 64: 1 else: 0) != 0) {
            IList_sort_lowhigh(__param_self_, __local_lo, __local_j)
        } else {
            if ((if __local_j > __local_lo: 1 else: 0) != 0) {
                IList_insertsort_lowhigh(__param_self_, __local_lo, __local_j)
            }
        }

        (__local_lo = __local_i)

    }

}

unsafe fn IList_insertsort_lowhigh(__param_self_: *mut IList, __param_lo: c_long, __param_hi: c_long) {
    var __local_j: c_long = __param_lo

    var __local_i: c_long = (((__param_lo + 1) as c_long))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: c_int = (*((&raw const (((*__param_self_).last as *mut c_int)[__local_i]) as *const c_int) as *mut c_int))

        var __local_rx: c_int = (*(&raw mut __local_x as *mut c_int))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: c_int = (*((&raw const (((*__param_self_).last as *mut c_int)[__local_j]) as *const c_int) as *mut c_int))

            if ((if not ((if (*(&raw mut __local_rx as *mut c_int)) < (*(&raw mut __local_ry as *mut c_int)): 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (((*__param_self_).last as *mut c_int)[(__local_j + 1)]) as *const c_int) as *mut c_int)) = (*((&raw const (((*__param_self_).last as *mut c_int)[__local_j]) as *const c_int) as *mut c_int)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (((*__param_self_).last as *mut c_int)[(__local_j + 1)]) as *const c_int) as *mut c_int)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

@[repr(C)]
pub type ctest_list_splice_run__c_i2_anon { _ref: *const *mut IList = null, ref: *mut *mut IList = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_list_splice_run__c_i2_anon
fn ctest_list_splice_run() {
    var __local_list1: IList = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [c_int; 5] = [1, 2, 3, 4, 5]
        unsafe { IList_from_n((&__ci_expr_lit_0[0] as *mut c_int), (5 as c_long)) }
    }

    var __local_list2: IList = with 0 as __ci_expr_seq_10 {
        var __ci_expr_lit_1: [c_int; 5] = [10, 20, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_1[0] as *mut c_int), (5 as c_long)) }
    }

    var __local_pos: IList_iter = IList_advance(unsafe { IList_begin(((&raw mut __local_list1 as *mut IList) as *const IList)) }, (2 as c_ulong))

    let __ci_copy_70: IList_iter = unsafe { IList_splice((&raw mut __local_list1 as *mut IList), __local_pos, (&raw mut __local_list2 as *mut IList)) }
    with_memcpy((&raw mut __local_pos as *mut u8), (&raw const __ci_copy_70 as *const u8), sizeof[IList_iter]())

    var __local_res1: IList = with 0 as __ci_expr_seq_17 {
        var __ci_expr_lit_2: [c_int; 10] = [1, 2, 10, 20, 30, 40, 50, 3, 4, 5]
        unsafe { IList_from_n((&__ci_expr_lit_2[0] as *mut c_int), (10 as c_long)) }
    }

    assert_compare((1 as c_int), c"==".ptr, ((unsafe *((*(&raw const __local_pos as *const IList_iter)).ref)) as c_long), (3 as c_long), c"list_test.c".ptr, (18 as c_int))

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res1 as *mut IList) as *const IList), ((&raw mut __local_list1 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (19 as c_int))

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_is_empty(((&raw mut __local_list2 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (20 as c_int))

    unsafe { IList_splice_range((&raw mut __local_list2 as *mut IList), unsafe { IList_begin(((&raw mut __local_list2 as *mut IList) as *const IList)) }, (&raw mut __local_list1 as *mut IList), __local_pos, unsafe { IList_end(((&raw mut __local_list1 as *mut IList) as *const IList)) }) }

    var __local_res2: IList = with 0 as __ci_expr_seq_26 {
        var __ci_expr_lit_3: [c_int; 7] = [1, 2, 10, 20, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_3[0] as *mut c_int), (7 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res2 as *mut IList) as *const IList), ((&raw mut __local_list1 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (26 as c_int))

    var __local_res3: IList = with 0 as __ci_expr_seq_32 {
        var __ci_expr_lit_4: [c_int; 3] = [3, 4, 5]
        unsafe { IList_from_n((&__ci_expr_lit_4[0] as *mut c_int), (3 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res3 as *mut IList) as *const IList), ((&raw mut __local_list2 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (29 as c_int))

    assert_bool((1 as c_int), (false as bool), (unsafe { IList_eq(((&raw mut __local_list1 as *mut IList) as *const IList), ((&raw mut __local_list2 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (30 as c_int))

    loop {
        var __local__c_i2: ctest_list_splice_run__c_i2_anon = ctest_list_splice_run__c_i2_anon.zeroed()

        var __ci_expr_lit_5: [*mut IList; 5] = [(&raw mut __local_list1 as *mut IList), (&raw mut __local_list2 as *mut IList), (&raw mut __local_res1 as *mut IList), (&raw mut __local_res2 as *mut IList), (&raw mut __local_res3 as *mut IList)]

        __local__c_i2 = ctest_list_splice_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_5)[0] as *mut *mut IList) as *const *mut IList)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon))._ref as *mut *mut IList)
        __local__c_i2.size = (((((5 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[IList]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { IList_drop(((*((*(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).ref)) as *const IList)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

@[repr(C)]
pub type ctest_list_erase_run__c_i2_anon { _ref: *const *mut IList = null, ref: *mut *mut IList = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_list_erase_run__c_i2_anon
fn ctest_list_erase_run() {
    var __local_L: IList = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [c_int; 5] = [10, 20, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_0[0] as *mut c_int), (5 as c_long)) }
    }

    var __local_it_: IList_iter = unsafe { IList_begin(((&raw mut __local_L as *mut IList) as *const IList)) }

    unsafe { IList_next((&raw mut __local_it_ as *mut IList_iter)) }

    let __ci_copy_45: IList_iter = unsafe { IList_erase_at((&raw mut __local_L as *mut IList), __local_it_) }
    with_memcpy((&raw mut __local_it_ as *mut u8), (&raw const __ci_copy_45 as *const u8), sizeof[IList_iter]())

    var __local_res1: IList = with 0 as __ci_expr_seq_13 {
        var __ci_expr_lit_1: [c_int; 4] = [10, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_1[0] as *mut c_int), (4 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res1 as *mut IList) as *const IList), ((&raw mut __local_L as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (44 as c_int))

    unsafe { IList_next((&raw mut __local_it_ as *mut IList_iter)) }

    let __ci_copy_110: IList_iter = unsafe { IList_erase_range((&raw mut __local_L as *mut IList), __local_it_, unsafe { IList_end(((&raw mut __local_L as *mut IList) as *const IList)) }) }
    with_memcpy((&raw mut __local_it_ as *mut u8), (&raw const __ci_copy_110 as *const u8), sizeof[IList_iter]())

    var __local_res2: IList = with 0 as __ci_expr_seq_21 {
        var __ci_expr_lit_2: [c_int; 2] = [10, 30]
        unsafe { IList_from_n((&__ci_expr_lit_2[0] as *mut c_int), (2 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res2 as *mut IList) as *const IList), ((&raw mut __local_L as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (50 as c_int))

    loop {
        var __local__c_i2: ctest_list_erase_run__c_i2_anon = ctest_list_erase_run__c_i2_anon.zeroed()

        var __ci_expr_lit_3: [*mut IList; 3] = [(&raw mut __local_L as *mut IList), (&raw mut __local_res1 as *mut IList), (&raw mut __local_res2 as *mut IList)]

        __local__c_i2 = ctest_list_erase_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_3)[0] as *mut *mut IList) as *const *mut IList)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon))._ref as *mut *mut IList)
        __local__c_i2.size = (((((3 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[IList]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { IList_drop(((*((*(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).ref)) as *const IList)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

@[repr(C)]
pub type ctest_list_misc_run__c_i2_anon { _ref: *const *mut IList = null, ref: *mut *mut IList = null, size: c_int = 0, index: c_int = 0 }
impl Copy for ctest_list_misc_run__c_i2_anon
fn ctest_list_misc_run() {
    var __local_nums: IList = IList.zeroed()

    var __local_nums2: IList = IList.zeroed()


    unsafe { IList_clear((&raw mut __local_nums as *mut IList)) }

    var __local_i: c_int = ((0 as c_int))

    while ((if __local_i < 10: 1 else: 0) != 0) {
        unsafe { IList_push_back((&raw mut __local_nums as *mut IList), __local_i) }

        (__local_i = __local_i + 1)

    }


    var __local_i_1: c_int = ((100 as c_int))

    while ((if __local_i_1 < 110: 1 else: 0) != 0) {
        unsafe { IList_push_back((&raw mut __local_nums2 as *mut IList), __local_i_1) }

        (__local_i_1 = __local_i_1 + 1)

    }


    unsafe { IList_splice((&raw mut __local_nums as *mut IList), unsafe { IList_begin(((&raw mut __local_nums as *mut IList) as *const IList)) }, (&raw mut __local_nums2 as *mut IList)) }

    var __local_res1: IList = with 0 as __ci_expr_seq_22 {
        var __ci_expr_lit_0: [c_int; 20] = [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        unsafe { IList_from_n((&__ci_expr_lit_0[0] as *mut c_int), (20 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res1 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (70 as c_int))

    ((unsafe *(unsafe { IList_find(((&raw mut __local_nums as *mut IList) as *const IList), (104 as c_int)) }.ref)) = (unsafe *(unsafe { IList_find(((&raw mut __local_nums as *mut IList) as *const IList), (104 as c_int)) }.ref)) + 50)

    unsafe { IList_remove((&raw mut __local_nums as *mut IList), (103 as c_int)) }

    var __local_res2: IList = with 0 as __ci_expr_seq_30 {
        var __ci_expr_lit_1: [c_int; 19] = [100, 101, 102, 154, 105, 106, 107, 108, 109, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        unsafe { IList_from_n((&__ci_expr_lit_1[0] as *mut c_int), (19 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res2 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (75 as c_int))

    var __local_it_: IList_iter = unsafe { IList_begin(((&raw mut __local_nums as *mut IList) as *const IList)) }

    unsafe { IList_erase_range((&raw mut __local_nums as *mut IList), IList_advance(__local_it_, (5 as c_ulong)), IList_advance(__local_it_, (15 as c_ulong))) }

    var __local_res3: IList = with 0 as __ci_expr_seq_38 {
        var __ci_expr_lit_2: [c_int; 9] = [100, 101, 102, 154, 105, 6, 7, 8, 9]
        unsafe { IList_from_n((&__ci_expr_lit_2[0] as *mut c_int), (9 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res3 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (80 as c_int))

    unsafe { IList_pop_front((&raw mut __local_nums as *mut IList)) }

    unsafe { IList_push_back((&raw mut __local_nums as *mut IList), (-99 as c_int)) }

    unsafe { IList_sort((&raw mut __local_nums as *mut IList)) }

    var __local_res4: IList = with 0 as __ci_expr_seq_47 {
        var __ci_expr_lit_3: [c_int; 9] = [(-99 as c_int), 6, 7, 8, 9, 101, 102, 105, 154]
        unsafe { IList_from_n((&__ci_expr_lit_3[0] as *mut c_int), (9 as c_long)) }
    }

    assert_bool((1 as c_int), (true as bool), (unsafe { IList_eq(((&raw mut __local_res4 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (86 as c_int))

    loop {
        var __local__c_i2: ctest_list_misc_run__c_i2_anon = ctest_list_misc_run__c_i2_anon.zeroed()

        var __ci_expr_lit_4: [*mut IList; 6] = [(&raw mut __local_nums as *mut IList), (&raw mut __local_nums2 as *mut IList), (&raw mut __local_res1 as *mut IList), (&raw mut __local_res2 as *mut IList), (&raw mut __local_res3 as *mut IList), (&raw mut __local_res4 as *mut IList)]

        __local__c_i2 = ctest_list_misc_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_4)[0] as *mut *mut IList) as *const *mut IList)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon))._ref as *mut *mut IList)
        __local__c_i2.size = (((((6 * (sizeof[usize]() as usize)) as c_ulong) / (sizeof[IList]() as c_ulong))) as c_int)


        while ((if (unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).size: 1 else: 0) != 0) {
            unsafe { IList_drop(((*((*(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).ref)) as *const IList)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).index + 1)


        }


        if not ((0 != 0)) {
            break
        }
    }

}

var ctest_list_splice: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("list" as *mut c_char) as *const c_char), ttname: (("splice" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_list_splice_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_list_erase: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("list" as *mut c_char) as *const c_char), ttname: (("erase" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_list_erase_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_list_misc: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("list" as *mut c_char) as *const c_char), ttname: (("misc" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_list_misc_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_list_splice_run()
    print("ran list.splice")
    ctest_list_erase_run()
    print("ran list.erase")
    ctest_list_misc_run()
    print("ran list.misc")
    return ctest_failure_count()
