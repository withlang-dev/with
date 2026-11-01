// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.harness
use std.libc
use std.option

extern fn assert_str(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_char, __param_real: *const c_char, __param_caller: *const c_char, __param_line: i32)
extern fn assert_wstr(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const i32, __param_real: *const i32, __param_caller: *const c_char, __param_line: i32)
extern fn assert_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_interval(__param_diag: i32, __param_low: i64, __param_high: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_pointers(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const c_char, __param_line: i32)
extern fn assert_bool(__param_diag: i32, __param_exp: bool, __param_real: bool, __param_caller: *const c_char, __param_line: i32)
extern fn assert_dbl_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_fail(__param_caller: *const c_char, __param_line: i32)
// contract: unproved:0:read only,unproved:1:read only
unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: i64) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as u64) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

// contract: unproved:0:read only
unsafe fn c_basehash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_len = __param_len
    var __local_msg: *const u8 = ((__param_key as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    var __local_block: u64 = ((0 as u64))


    while (__local_len >= ((sizeof[u64]() as i64))) {
        with_memcpy((((&raw mut __local_block as *mut u64) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[u64]() as u64) as i64))

        (__local_h = (__local_h as u64) ^ (__local_block as u64))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[u64]() as i64) as usize))

        (__local_len = __local_len - (sizeof[u64]() as i64))

    }

    while true {
        var __ci_expr_old_0: i64 = __local_len

        (__local_len = __local_len - 1)

        if (not __ci_expr_old_0) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_1) as u64))

        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

// contract: unproved:0:read only
unsafe fn c_hash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_b8: u64

    var __local_b4: u32

    match __param_len {
        8 => {
            with_memcpy((((&raw mut __local_b8 as *mut u64) as *mut c_void) as *mut u8), (__param_key as *const u8), ((8 as u64) as i64))

            return ((__local_b8 as u64) *% (((0 as u64) -% 4132994306676758115) as u64))

        },
        4 => {
            with_memcpy((((&raw mut __local_b4 as *mut u32) as *mut c_void) as *mut u8), (__param_key as *const u8), ((4 as u64) as i64))

            return ((__local_b4 as u64) *% (((0 as u64) -% 3750763034362895579) as u64))

        },
        _ => {
            return c_basehash_n(__param_key, __param_len)
        },
    }

}

// contract: unproved:0:read only
unsafe fn c_hash_str(__param_str: *const c_char) -> u64 {
    var __local_msg: *const u8 = ((__param_str as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    while (*__local_msg) {
        var __ci_expr_old_0: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_0) as u64))


        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

// contract: unproved:0:out-parameter read before the write
unsafe fn c_hash_mix_n(__param_h: *mut u64, __param_n: i64) -> u64 {
    var __local_i: i64 = ((1 as i64))

    while (__local_i < __param_n) {
        ((__param_h[0]) = ((__param_h[0]) +% (((__param_h[0]) as u64) ^ ((__param_h[__local_i]) as u64))))

        (__local_i = __local_i + 1)

    }


    return (__param_h[0])

}

fn c_next_pow2(__param_n: i64) -> i64 {
    var __local_n = __param_n
    (__local_n = __local_n - 1)

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (1 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (2 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (4 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (8 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (16 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (32 as u32)) as i64))

    return (__local_n + 1)

}

// contract: unproved:0:read only,unproved:2:read only
unsafe fn c_strnstrn(__param_str: *const c_char, __param_slen: i64, __param_needle: *const c_char, __param_nlen: i64) -> *mut c_char {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if (__param_nlen == 0) {
        return ((__local_str as *mut c_char))
    }

    if (__param_nlen > __local_slen) {
        return ((null as *mut c_char))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: i32 = 0

        if ((*__local_str) == (*__param_needle)) {
            (__ci_expr_logic_1 = (if not with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if true: __param_nlen else: (-1 as i64)) as u64) as i64)): 1 else: 0))
        }

        if __ci_expr_logic_1 {
            return ((__local_str as *mut c_char))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: i64 = __local_slen

        (__local_slen = __local_slen - 1)

        if not (__ci_expr_old_0) {
            break
        }
    }

    return ((null as *mut c_char))

}

// contract: unproved:0:casts away const
unsafe fn IList_drop(__param_cself: *const IList) {
    var __local_self_: *mut IList = ((__param_cself as *mut IList))

    while ((*__local_self_).last != null) {
        IList_erase_after_node(__local_self_, (*__local_self_).last)
    }

}

unsafe fn IList_push_back(__param_self_: *mut IList, __param_value: i32) -> *mut i32 {
    var __local_entry: *mut IList_node = (((with_alloc((((if true: ((1 * (sizeof[IList_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut IList_node))

    ((*__local_entry).value = __param_value)

    if ((*__param_self_).last != null) {
        ((*__local_entry).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    ((*__param_self_).last = __local_entry)

    return (((&raw const (*__local_entry).value as *const i32) as *mut i32))

}

unsafe fn IList_push_front(__param_self_: *mut IList, __param_value: i32) -> *mut i32 {
    var __local_entry: *mut IList_node = (((with_alloc((((if true: ((1 * (sizeof[IList_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut IList_node))

    ((*__local_entry).value = __param_value)

    if ((*__param_self_).last != null) {
        ((*__local_entry).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    if ((*__param_self_).last == null) {
        ((*__param_self_).last = __local_entry)
    }

    return (((&raw const (*__local_entry).value as *const i32) as *mut i32))

}

unsafe fn IList_insert_at(__param_self_: *mut IList, __param_it_: IList_iter, __param_value: i32) -> IList_iter {
    var __local_node: *mut IList_node = (if (*(&raw const __param_it_ as *const IList_iter)).ref != null: (*(&raw const __param_it_ as *const IList_iter)).prev else: (*__param_self_).last)

    var __local_entry: *mut IList_node = (((with_alloc((((if true: ((1 * (sizeof[IList_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut IList_node))

    ((*__local_entry).value = __param_value)

    if (__local_node != null) {
        ((*__local_entry).next = (*__local_node).next)

        ((*__local_node).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    var __ci_expr_logic_0: i32

    if ((*__param_self_).last == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (*(&raw const __param_it_ as *const IList_iter)).ref == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__param_it_.prev = (if (*__param_self_).last != null: (*__param_self_).last else: __local_entry))

        ((*__param_self_).last = __local_entry)

    }


    (__param_it_.ref = (((&raw const (*__local_entry).value as *const i32) as *mut i32)))

    return __param_it_

}

unsafe fn IList_erase_at(__param_self_: *mut IList, __param_it_: IList_iter) -> IList_iter {
    var __local_node: *mut IList_node = (((if true: (*(&raw const __param_it_ as *const IList_iter)).ref else: (null as *mut i32)) as *mut IList_node))

    (__param_it_.ref = (if __local_node == (*__param_self_).last: (null as *mut i32) else: ((&raw const (*(*__local_node).next).value as *const i32) as *mut i32)))

    IList_erase_after_node(__param_self_, (*(&raw const __param_it_ as *const IList_iter)).prev)

    return __param_it_

}

unsafe fn IList_erase_range(__param_self_: *mut IList, __param_it1: IList_iter, __param_it2: IList_iter) -> IList_iter {
    var __local_end: *mut IList_node = (if (*(&raw const __param_it2 as *const IList_iter)).ref != null: ((if true: (*(&raw const __param_it2 as *const IList_iter)).ref else: (null as *mut i32)) as *mut IList_node) else: (*(*__param_self_).last).next)

    if ((*(&raw const __param_it1 as *const IList_iter)).ref != (*(&raw const __param_it2 as *const IList_iter)).ref) {
        loop {
            IList_erase_after_node(__param_self_, (*(&raw const __param_it1 as *const IList_iter)).prev)

            if ((*__param_self_).last == null) {
                break
            }

            if not (((*(*(&raw const __param_it1 as *const IList_iter)).prev).next != __local_end)) {
                break
            }
        }
    }

    return __param_it2

}

unsafe fn IList_find_in(__param_self_: *const IList, __param_it1: IList_iter, __param_it2: IList_iter, __param_val: i32) -> IList_iter {

    var __local_it_: IList_iter = __param_it1

    var __local__endref_it: *mut IList_iter = (((if true: (*(&raw const __param_it2 as *const IList_iter)).ref else: (null as *mut i32)) as *mut IList_iter))


    while ((*(&raw const __local_it_ as *const IList_iter)).ref != ((__local__endref_it as *mut i32))) {
        var __local_r: i32 = (*((*(&raw const __local_it_ as *const IList_iter)).ref))

        if ((*(&raw mut __local_r as *mut i32)) == (*(&raw mut __param_val as *mut i32))) {
            return __local_it_
        }


        (*(&raw mut __local_it_ as *mut IList_iter)).next()

    }


    (__param_it2.ref = ((null as *mut i32)))

    return __param_it2

}

unsafe fn IList_remove(__param_self_: *mut IList, __param_val: i32) -> i64 {
    var __local_n: i64 = ((0 as i64))

    var __local_prev: *mut IList_node = (*__param_self_).last

    var __local_node: *mut IList_node


    if (__local_prev != null) {
        loop {
            (__local_node = (*__local_prev).next)

            var __local_r: i32 = (*((&raw const (*__local_node).value as *const i32) as *mut i32))

            if ((*(&raw mut __local_r as *mut i32)) == (*(&raw mut __param_val as *mut i32))) {
                IList_erase_after_node(__param_self_, __local_prev)

                (__local_n = __local_n + 1)


                if ((*__param_self_).last == null) {
                    break
                }

            } else {
                (__local_prev = __local_node)
            }

            if not ((__local_node != (*__param_self_).last)) {
                break
            }
        }
    }

    return __local_n

}

unsafe fn IList_sort(__param_self_: *mut IList) -> bool {
    var __local_len__goto_410_13: i64 = 0

    var __local_cap__goto_410_22: i64 = 0

    var __local_arr__goto_411_15: *mut i32 = null

    var __local_p__goto_411_28: *mut i32 = null

    var __local_keep__goto_412_14: *mut IList_node = null

    var __local_i__goto_413_10: IList_iter = IList_iter.zeroed()

    var __local_cap_n__goto_415_21: i64 = 0

    var __local_i__goto_426_10: IList_iter = IList_iter.zeroed()

    var __ci_expr_old_0: i64 = 0

    var __ci_expr_old_1: *mut i32 = null

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_len__goto_410_13 = ((0 as i64)))
        (__local_cap__goto_410_22 = ((0 as i64)))
        (__local_arr__goto_411_15 = ((null as *mut i32)))
        (__local_p__goto_411_28 = ((null as *mut i32)))
        (__local_i__goto_413_10 = (*(((&raw const (*__param_self_) as *const IList) as *mut IList) as *const IList)).begin())
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
        if (__local_len__goto_410_13 == __local_cap__goto_410_22) {
            goto '__ci_bb_5
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_3 {
        (*(&raw mut __local_i__goto_413_10 as *mut IList_iter)).next()
        goto '__ci_bb_1
    }

    '__ci_bb_4 {
        (__local_keep__goto_412_14 = (*__param_self_).last)
        ((*__param_self_).last = ((__local_arr__goto_411_15 as *mut IList_node)))
        IList_sort_lowhigh(__param_self_, (0 as i64), ((__local_len__goto_410_13 - 1) as i64))
        ((*__param_self_).last = __local_keep__goto_412_14)
        (__local_i__goto_426_10 = (*(((&raw const (*__param_self_) as *const IList) as *mut IList) as *const IList)).begin())
        goto '__ci_bb_10
    }

    '__ci_bb_5 {
        (__local_cap_n__goto_415_21 = ((((__local_cap__goto_410_22 + (__local_cap__goto_410_22 / 2)) + 8) as i64)))
        (__local_p__goto_411_28 = (((with_realloc(((__local_arr__goto_411_15 as *mut c_void) as *mut u8), (0 as i64), (((if true: ((if true: ((__local_cap_n__goto_415_21 * (sizeof[i32]() as i64)) as i64) else: ((__local_cap__goto_410_22 * (sizeof[i32]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)))
        if (__local_p__goto_411_28 == null) {
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
        (*(&raw mut __local_i__goto_426_10 as *mut IList_iter)).next()
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

// contract: receiver-mut:IList,unproved:2:out-parameter read before the write
unsafe fn IList_splice(__param_self_: *mut IList, __param_it_: IList_iter, __param_other: *mut IList) -> IList_iter {
    if ((*__param_self_).last == null) {
        ((*__param_self_).last = (*__param_other).last)
    } else {
        if ((*__param_other).last != null) {
            var __local_p: *mut IList_node = (if (*(&raw const __param_it_ as *const IList_iter)).ref != null: (*(&raw const __param_it_ as *const IList_iter)).prev else: (*__param_self_).last)

            var __local_next: *mut IList_node = (*__local_p).next


            (__param_it_.prev = (*__param_other).last)

            ((*__local_p).next = (*(*(&raw const __param_it_ as *const IList_iter)).prev).next)

            ((*(*(&raw const __param_it_ as *const IList_iter)).prev).next = __local_next)

            if ((*(&raw const __param_it_ as *const IList_iter)).ref == null) {
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

    if ((*(&raw const __param_it1 as *const IList_iter)).ref == (*(&raw const __param_it2 as *const IList_iter)).ref) {
        return __local_lst
    }

    var __local_p1: *mut IList_node = (*(&raw const __param_it1 as *const IList_iter)).prev

    var __local_p2: *mut IList_node = (if (*(&raw const __param_it2 as *const IList_iter)).ref != null: (*(&raw const __param_it2 as *const IList_iter)).prev else: (*__param_self_).last)


    ((*__local_p1).next = (*__local_p2).next)

    ((*__local_p2).next = (((if true: (*(&raw const __param_it1 as *const IList_iter)).ref else: (null as *mut i32)) as *mut IList_node)))

    if ((*__param_self_).last == __local_p2) {
        ((*__param_self_).last = (if __local_p1 == __local_p2: (null as *mut IList_node) else: __local_p1))
    }

    (__local_lst.last = __local_p2)

    return __local_lst

}

// contract: receiver-mut:IList,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn IList_push_back_node(__param_self_: *mut IList, __param_node: *mut IList_node) -> *mut i32 {
    if ((*__param_self_).last != null) {
        ((*__param_node).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    ((*__param_self_).last = __param_node)

    return (((&raw const (*__param_node).value as *const i32) as *mut i32))

}

// contract: receiver-mut:IList,unproved:1:out-parameter read before the write,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn IList_insert_after_node(__param_self_: *mut IList, __param_ref: *mut IList_node, __param_node: *mut IList_node) -> *mut i32 {
    if (__param_ref != null) {
        ((*__param_node).next = (*__param_ref).next)

        ((*__param_ref).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    if ((*__param_self_).last == null) {
        ((*__param_self_).last = __param_node)
    }

    return (((&raw const (*__param_node).value as *const i32) as *mut i32))

}

// contract: receiver-mut:IList,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn IList_unlink_after_node(__param_self_: *mut IList, __param_ref: *mut IList_node) -> *mut IList_node {
    var __local_node: *mut IList_node = (*__param_ref).next

    var __local_next: *mut IList_node = (*__local_node).next


    ((*__param_ref).next = __local_next)

    if (__local_node == __local_next) {
        ((*__param_self_).last = ((null as *mut IList_node)))
    } else {
        if (__local_node == (*__param_self_).last) {
            ((*__param_self_).last = __param_ref)
        }
    }

    return __local_node

}

// contract: receiver-mut:IList,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn IList_erase_after_node(__param_self_: *mut IList, __param_ref: *mut IList_node) {
    var __local_node: *mut IList_node = IList_unlink_after_node(__param_self_, __param_ref)


    with_free(((__local_node as *mut c_void) as *mut u8))

}

// contract: unproved:0:read only
pub unsafe fn IList_get_node(__param_pval: *mut i32) -> *mut IList_node {
    return (((if true: __param_pval else: (null as *mut i32)) as *mut IList_node))

}

fn IList_clone(__param_lst: IList) -> IList {
    var __local_out: IList = __param_lst

    var __local_self_: *mut IList = ((&raw mut __local_out as *mut IList))



    (__local_out.last = ((null as *mut IList_node)))

    var __local_it_: IList_iter = unsafe { (*((&raw mut __param_lst as *mut IList) as *const IList)).begin() }

    while ((unsafe *(&raw const __local_it_ as *const IList_iter)).ref != null) {
        unsafe { IList_push_back((&raw mut __local_out as *mut IList), (*((*(&raw const __local_it_ as *const IList_iter)).ref))) }

        unsafe { (*(&raw mut __local_it_ as *mut IList_iter)).next() }

    }


    return __local_out

}

// contract: receiver-mut:IList,unproved:1:read only
pub unsafe fn IList_copy(__param_self_: *mut IList, __param_other: *const IList) -> Unit {
    if ((*__param_self_).last == (*__param_other).last) {
        return
    }

    IList_drop((__param_self_ as *const IList))

    let __ci_copy_18: IList = IList_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[IList]())

}

// contract: receiver-mut:IList,unproved:1:read only
pub unsafe fn IList_put_n(__param_self_: *mut IList, __param_raw: *const i32, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not __ci_expr_old_0) {
            break
        }

        IList_push_back(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn IList_init() -> IList {
    return ((IList.zeroed() as IList))

}

// contract: unproved:0:read only
pub unsafe fn IList_from_n(__param_raw: *const i32, __param_n: i64) -> IList {
    var __local_cx: IList = IList.zeroed()

    IList_put_n((&raw mut __local_cx as *mut IList), __param_raw, __param_n)

    return __local_cx

}

// contract: unproved:0:indexed as an array
pub unsafe fn IList_reserve(__param_self_: *mut IList, __param_n: i64) -> bool {

    return ((true as bool))

}

// contract: unproved:0:IList_drop may write through it
pub unsafe fn IList_clear(__param_self_: *mut IList) {
    IList_drop((__param_self_ as *const IList))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IList_front(__param_self_: *const IList) -> *const i32 {
    return ((((&raw const (*(*(*__param_self_).last).next).value as *const i32) as *mut i32) as *const i32))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IList_front_mut(__param_self_: *mut IList) -> *mut i32 {
    return (((&raw const (*(*(*__param_self_).last).next).value as *const i32) as *mut i32))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IList_back(__param_self_: *const IList) -> *const i32 {
    return ((((&raw const (*(*__param_self_).last).value as *const i32) as *mut i32) as *const i32))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn IList_back_mut(__param_self_: *mut IList) -> *mut i32 {
    return (((&raw const (*(*__param_self_).last).value as *const i32) as *mut i32))

}

// contract: unproved:0:read only
pub unsafe fn IList_value_toraw(__param_pval: *const i32) -> i32 {
    return (*__param_pval)

}

// contract: receiver:IList,unproved:1:read only
pub unsafe fn IList_value_drop(__param_self_: *const IList, __param_pval: *mut i32) {
    return
}

pub fn IList_advance(__param_it_: IList_iter, __param_n: u64) -> IList_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if __ci_expr_old_0 {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const IList_iter)).ref != null: 1 else: 0))
        }

        if (not __ci_expr_logic_1) {
            break
        }

        unsafe { (*(&raw mut __param_it_ as *mut IList_iter)).next() }

    }

    return __param_it_

}

// contract: receiver-mut:IList,unproved:2:out-parameter read before the write
pub unsafe fn IList_splice_range(__param_self_: *mut IList, __param_it_: IList_iter, __param_other: *mut IList, __param_it1: IList_iter, __param_it2: IList_iter) -> IList_iter {
    var __local_tmp: IList = IList_split_off(__param_other, __param_it1, __param_it2)

    return IList_splice(__param_self_, __param_it_, (&raw mut __local_tmp as *mut IList))

}

// contract: receiver:IList,unproved:1:read only
pub unsafe fn IList_eq(__param_self_: *const IList, __param_other: *const IList) -> bool {
    var __local_i: IList_iter = (*__param_self_).begin()

    var __local_j: IList_iter = (*__param_other).begin()


    while true {
        var __ci_expr_logic_0: i32 = 0

        if ((*(&raw const __local_i as *const IList_iter)).ref != null) {
            (__ci_expr_logic_0 = (if (*(&raw const __local_j as *const IList_iter)).ref != null: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        var __local__rx: i32 = (*((*(&raw const __local_i as *const IList_iter)).ref))

        var __local__ry: i32 = (*((*(&raw const __local_j as *const IList_iter)).ref))

        if (not ((*(&raw const __local__rx as *const i32)) == (*(&raw const __local__ry as *const i32)))) {
            return ((false as bool))
        }

        (*(&raw mut __local_i as *mut IList_iter)).next()

        (*(&raw mut __local_j as *mut IList_iter)).next()

    }

    var __ci_expr_logic_1: i32

    if ((*(&raw const __local_i as *const IList_iter)).ref != null) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (*(&raw const __local_j as *const IList_iter)).ref != null: 1 else: 0))
    }

    return ((((not __ci_expr_logic_1)) as bool))


}

unsafe fn IList_sort_lowhigh(__param_self_: *mut IList, __param_lo: i64, __param_hi: i64) -> Unit {
    var __local_lo = __param_lo
    var __local_i: i64 = __local_lo

    var __local_j: i64


    while (__local_lo < __param_hi) {
        var __local_pivot: i32 = (*((&raw const (((*__param_self_).last as *mut i32)[(__local_lo + (((__param_hi - __local_lo) * 7) / 16))]) as *const i32) as *mut i32))

        var __local_rx: i32


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (((*__param_self_).last as *mut i32)[__local_i]) as *const i32) as *mut i32)))

                var __ci_expr_logic_0: i32 = 0

                if ((*(&raw mut __local_rx as *mut i32)) < (*(&raw mut __local_pivot as *mut i32))) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i: 1 else: 0))

                }

                if not (__ci_expr_logic_0) {
                    break
                }
            }

            loop {
                (__local_rx = (*((&raw const (((*__param_self_).last as *mut i32)[__local_j]) as *const i32) as *mut i32)))

                var __ci_expr_logic_1: i32 = 0

                if ((*(&raw mut __local_pivot as *mut i32)) < (*(&raw mut __local_rx as *mut i32))) {
                    (__local_j = __local_j - 1)

                    (__ci_expr_logic_1 = (if __local_j: 1 else: 0))

                }

                if not (__ci_expr_logic_1) {
                    break
                }
            }

            if (__local_i > __local_j) {
                break
            }

            loop {
                var __local__xp: *mut i32 = (((&raw const (((*__param_self_).last as *mut i32)[__local_i]) as *const i32) as *mut i32))

                var __local__yp: *mut i32 = (((&raw const (((*__param_self_).last as *mut i32)[__local_j]) as *const i32) as *mut i32))


                var __local__tv: i32 = (*__local__xp)

                ((*__local__xp) = (*__local__yp))

                ((*__local__yp) = __local__tv)

                if not (false) {
                    break
                }
            }

            (__local_i = __local_i + 1)

            (__local_j = __local_j - 1)

            if not ((__local_i <= __local_j)) {
                break
            }
        }

        if ((__local_j - __local_lo) > (__param_hi - __local_i)) {
            loop {
                var __local__xp_1: *mut i64 = ((&raw mut __local_lo as *mut i64))

                var __local__yp_1: *mut i64 = ((&raw mut __local_i as *mut i64))


                var __local__tv_1: i64 = (*__local__xp_1)

                ((*__local__xp_1) = (*__local__yp_1))

                ((*__local__yp_1) = __local__tv_1)

                if not (false) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut i64 = ((&raw mut __param_hi as *mut i64))

                var __local__yp_2: *mut i64 = ((&raw mut __local_j as *mut i64))


                var __local__tv_2: i64 = (*__local__xp_2)

                ((*__local__xp_2) = (*__local__yp_2))

                ((*__local__yp_2) = __local__tv_2)

                if not (false) {
                    break
                }
            }

        }

        if ((__local_j - __local_lo) > 64) {
            IList_sort_lowhigh(__param_self_, __local_lo, __local_j)
        } else {
            if (__local_j > __local_lo) {
                IList_insertsort_lowhigh(__param_self_, __local_lo, __local_j)
            }
        }

        (__local_lo = __local_i)

    }

}

unsafe fn IList_insertsort_lowhigh(__param_self_: *mut IList, __param_lo: i64, __param_hi: i64) {
    var __local_j: i64 = __param_lo

    var __local_i: i64 = (((__param_lo + 1) as i64))


    while (__local_i <= __param_hi) {
        var __local_x: i32 = (*((&raw const (((*__param_self_).last as *mut i32)[__local_i]) as *const i32) as *mut i32))

        var __local_rx: i32 = (*(&raw mut __local_x as *mut i32))

        while (__local_j >= 0) {
            var __local_ry: i32 = (*((&raw const (((*__param_self_).last as *mut i32)[__local_j]) as *const i32) as *mut i32))

            if (not ((*(&raw mut __local_rx as *mut i32)) < (*(&raw mut __local_ry as *mut i32)))) {
                break
            }

            ((*((&raw const (((*__param_self_).last as *mut i32)[(__local_j + 1)]) as *const i32) as *mut i32)) = (*((&raw const (((*__param_self_).last as *mut i32)[__local_j]) as *const i32) as *mut i32)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (((*__param_self_).last as *mut i32)[(__local_j + 1)]) as *const i32) as *mut i32)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

@[repr(C)]
pub type ctest_list_splice_run__c_i2_anon { _ref: *const *mut IList = null, ref: *mut *mut IList = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_list_splice_run__c_i2_anon
fn ctest_list_splice_run() {
    var __local_list1: IList = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [i32; 5] = [1, 2, 3, 4, 5]
        unsafe { IList_from_n((&__ci_expr_lit_0[0] as *mut i32), (([1, 2, 3, 4, 5].len() as u64) as i64)) }
    }

    var __local_list2: IList = with 0 as __ci_expr_seq_10 {
        var __ci_expr_lit_1: [i32; 5] = [10, 20, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_1[0] as *mut i32), (([10, 20, 30, 40, 50].len() as u64) as i64)) }
    }

    var __local_pos: IList_iter = IList_advance(unsafe { (*((&raw mut __local_list1 as *mut IList) as *const IList)).begin() }, (2 as u64))

    let __ci_copy_98: IList_iter = unsafe { IList_splice((&raw mut __local_list1 as *mut IList), __local_pos, (&raw mut __local_list2 as *mut IList)) }
    with_memcpy((&raw mut __local_pos as *mut u8), (&raw const __ci_copy_98 as *const u8), sizeof[IList_iter]())

    var __local_res1: IList = with 0 as __ci_expr_seq_17 {
        var __ci_expr_lit_2: [i32; 10] = [1, 2, 10, 20, 30, 40, 50, 3, 4, 5]
        unsafe { IList_from_n((&__ci_expr_lit_2[0] as *mut i32), (([1, 2, 10, 20, 30, 40, 50, 3, 4, 5].len() as u64) as i64)) }
    }

    assert_compare((1 as i32), c"==".ptr, ((unsafe *((*(&raw const __local_pos as *const IList_iter)).ref)) as i64), (3 as i64), c"list_test.c".ptr, (18 as i32))

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res1 as *mut IList) as *const IList), ((&raw mut __local_list1 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (19 as i32))

    assert_bool((1 as i32), (true as bool), (unsafe { (*((&raw mut __local_list2 as *mut IList) as *const IList)).is_empty() } as bool), c"list_test.c".ptr, (20 as i32))

    unsafe { IList_splice_range((&raw mut __local_list2 as *mut IList), unsafe { (*((&raw mut __local_list2 as *mut IList) as *const IList)).begin() }, (&raw mut __local_list1 as *mut IList), __local_pos, unsafe { (*((&raw mut __local_list1 as *mut IList) as *const IList)).end() }) }

    var __local_res2: IList = with 0 as __ci_expr_seq_26 {
        var __ci_expr_lit_3: [i32; 7] = [1, 2, 10, 20, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_3[0] as *mut i32), (([1, 2, 10, 20, 30, 40, 50].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res2 as *mut IList) as *const IList), ((&raw mut __local_list1 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (26 as i32))

    var __local_res3: IList = with 0 as __ci_expr_seq_32 {
        var __ci_expr_lit_4: [i32; 3] = [3, 4, 5]
        unsafe { IList_from_n((&__ci_expr_lit_4[0] as *mut i32), (([3, 4, 5].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res3 as *mut IList) as *const IList), ((&raw mut __local_list2 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (29 as i32))

    assert_bool((1 as i32), (false as bool), (unsafe { IList_eq(((&raw mut __local_list1 as *mut IList) as *const IList), ((&raw mut __local_list2 as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (30 as i32))

    loop {
        var __local__c_i2: ctest_list_splice_run__c_i2_anon = ctest_list_splice_run__c_i2_anon.zeroed()

        var __ci_expr_lit_5: [*mut IList; 5] = [(&raw mut __local_list1 as *mut IList), (&raw mut __local_list2 as *mut IList), (&raw mut __local_res1 as *mut IList), (&raw mut __local_res2 as *mut IList), (&raw mut __local_res3 as *mut IList)]

        __local__c_i2 = ctest_list_splice_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_5)[0] as *mut *mut IList) as *const *mut IList)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon))._ref as *mut *mut IList)
        __local__c_i2.size = (((((5 * (sizeof[usize]() as usize)) as u64) / (sizeof[IList]() as u64))) as i32)


        while ((unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).size) {
            unsafe { IList_drop(((*((*(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).ref)) as *const IList)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_list_splice_run__c_i2_anon)).index + 1)


        }


        if not (false) {
            break
        }
    }

}

@[repr(C)]
pub type ctest_list_erase_run__c_i2_anon { _ref: *const *mut IList = null, ref: *mut *mut IList = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_list_erase_run__c_i2_anon
fn ctest_list_erase_run() {
    var __local_L: IList = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [i32; 5] = [10, 20, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_0[0] as *mut i32), (([10, 20, 30, 40, 50].len() as u64) as i64)) }
    }

    var __local_it_: IList_iter = unsafe { (*((&raw mut __local_L as *mut IList) as *const IList)).begin() }

    unsafe { (*(&raw mut __local_it_ as *mut IList_iter)).next() }

    let __ci_copy_62: IList_iter = unsafe { IList_erase_at((&raw mut __local_L as *mut IList), __local_it_) }
    with_memcpy((&raw mut __local_it_ as *mut u8), (&raw const __ci_copy_62 as *const u8), sizeof[IList_iter]())

    var __local_res1: IList = with 0 as __ci_expr_seq_13 {
        var __ci_expr_lit_1: [i32; 4] = [10, 30, 40, 50]
        unsafe { IList_from_n((&__ci_expr_lit_1[0] as *mut i32), (([10, 30, 40, 50].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res1 as *mut IList) as *const IList), ((&raw mut __local_L as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (44 as i32))

    unsafe { (*(&raw mut __local_it_ as *mut IList_iter)).next() }

    let __ci_copy_142: IList_iter = unsafe { IList_erase_range((&raw mut __local_L as *mut IList), __local_it_, unsafe { (*((&raw mut __local_L as *mut IList) as *const IList)).end() }) }
    with_memcpy((&raw mut __local_it_ as *mut u8), (&raw const __ci_copy_142 as *const u8), sizeof[IList_iter]())

    var __local_res2: IList = with 0 as __ci_expr_seq_21 {
        var __ci_expr_lit_2: [i32; 2] = [10, 30]
        unsafe { IList_from_n((&__ci_expr_lit_2[0] as *mut i32), (([10, 30].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res2 as *mut IList) as *const IList), ((&raw mut __local_L as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (50 as i32))

    loop {
        var __local__c_i2: ctest_list_erase_run__c_i2_anon = ctest_list_erase_run__c_i2_anon.zeroed()

        var __ci_expr_lit_3: [*mut IList; 3] = [(&raw mut __local_L as *mut IList), (&raw mut __local_res1 as *mut IList), (&raw mut __local_res2 as *mut IList)]

        __local__c_i2 = ctest_list_erase_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_3)[0] as *mut *mut IList) as *const *mut IList)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon))._ref as *mut *mut IList)
        __local__c_i2.size = (((((3 * (sizeof[usize]() as usize)) as u64) / (sizeof[IList]() as u64))) as i32)


        while ((unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).size) {
            unsafe { IList_drop(((*((*(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).ref)) as *const IList)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_list_erase_run__c_i2_anon)).index + 1)


        }


        if not (false) {
            break
        }
    }

}

@[repr(C)]
pub type ctest_list_misc_run__c_i2_anon { _ref: *const *mut IList = null, ref: *mut *mut IList = null, size: i32 = 0, index: i32 = 0 }
impl Copy for ctest_list_misc_run__c_i2_anon
fn ctest_list_misc_run() {
    var __local_nums: IList = IList.zeroed()

    var __local_nums2: IList = IList.zeroed()


    unsafe { IList_clear((&raw mut __local_nums as *mut IList)) }

    var __local_i: i32 = ((0 as i32))

    while (__local_i < 10) {
        unsafe { IList_push_back((&raw mut __local_nums as *mut IList), __local_i) }

        (__local_i = __local_i + 1)

    }


    var __local_i_1: i32 = ((100 as i32))

    while (__local_i_1 < 110) {
        unsafe { IList_push_back((&raw mut __local_nums2 as *mut IList), __local_i_1) }

        (__local_i_1 = __local_i_1 + 1)

    }


    unsafe { IList_splice((&raw mut __local_nums as *mut IList), unsafe { (*((&raw mut __local_nums as *mut IList) as *const IList)).begin() }, (&raw mut __local_nums2 as *mut IList)) }

    var __local_res1: IList = with 0 as __ci_expr_seq_22 {
        var __ci_expr_lit_0: [i32; 20] = [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        unsafe { IList_from_n((&__ci_expr_lit_0[0] as *mut i32), (([100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res1 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (70 as i32))

    ((unsafe *(unsafe { (*((&raw mut __local_nums as *mut IList) as *const IList)).find((104 as i32)) }.ref)) = (unsafe *(unsafe { (*((&raw mut __local_nums as *mut IList) as *const IList)).find((104 as i32)) }.ref)) + 50)

    unsafe { IList_remove((&raw mut __local_nums as *mut IList), (103 as i32)) }

    var __local_res2: IList = with 0 as __ci_expr_seq_30 {
        var __ci_expr_lit_1: [i32; 19] = [100, 101, 102, 154, 105, 106, 107, 108, 109, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        unsafe { IList_from_n((&__ci_expr_lit_1[0] as *mut i32), (([100, 101, 102, 154, 105, 106, 107, 108, 109, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res2 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (75 as i32))

    var __local_it_: IList_iter = unsafe { (*((&raw mut __local_nums as *mut IList) as *const IList)).begin() }

    unsafe { IList_erase_range((&raw mut __local_nums as *mut IList), IList_advance(__local_it_, (5 as u64)), IList_advance(__local_it_, (15 as u64))) }

    var __local_res3: IList = with 0 as __ci_expr_seq_38 {
        var __ci_expr_lit_2: [i32; 9] = [100, 101, 102, 154, 105, 6, 7, 8, 9]
        unsafe { IList_from_n((&__ci_expr_lit_2[0] as *mut i32), (([100, 101, 102, 154, 105, 6, 7, 8, 9].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res3 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (80 as i32))

    unsafe { (*(&raw mut __local_nums as *mut IList)).pop_front() }

    unsafe { IList_push_back((&raw mut __local_nums as *mut IList), (-99 as i32)) }

    unsafe { IList_sort((&raw mut __local_nums as *mut IList)) }

    var __local_res4: IList = with 0 as __ci_expr_seq_47 {
        var __ci_expr_lit_3: [i32; 9] = [(-99 as i32), 6, 7, 8, 9, 101, 102, 105, 154]
        unsafe { IList_from_n((&__ci_expr_lit_3[0] as *mut i32), (([(-99 as i32), 6, 7, 8, 9, 101, 102, 105, 154].len() as u64) as i64)) }
    }

    assert_bool((1 as i32), (true as bool), (unsafe { IList_eq(((&raw mut __local_res4 as *mut IList) as *const IList), ((&raw mut __local_nums as *mut IList) as *const IList)) } as bool), c"list_test.c".ptr, (86 as i32))

    loop {
        var __local__c_i2: ctest_list_misc_run__c_i2_anon = ctest_list_misc_run__c_i2_anon.zeroed()

        var __ci_expr_lit_4: [*mut IList; 6] = [(&raw mut __local_nums as *mut IList), (&raw mut __local_nums2 as *mut IList), (&raw mut __local_res1 as *mut IList), (&raw mut __local_res2 as *mut IList), (&raw mut __local_res3 as *mut IList), (&raw mut __local_res4 as *mut IList)]

        __local__c_i2 = ctest_list_misc_run__c_i2_anon.zeroed()
        __local__c_i2._ref = ((&raw const (__ci_expr_lit_4)[0] as *mut *mut IList) as *const *mut IList)
        __local__c_i2.ref = ((unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon))._ref as *mut *mut IList)
        __local__c_i2.size = (((((6 * (sizeof[usize]() as usize)) as u64) / (sizeof[IList]() as u64))) as i32)


        while ((unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).index < (unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).size) {
            unsafe { IList_drop(((*((*(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).ref)) as *const IList)) }

            (__local__c_i2.ref = (unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).ref + 1)

            (__local__c_i2.index = (unsafe *(&raw const __local__c_i2 as *const ctest_list_misc_run__c_i2_anon)).index + 1)


        }


        if not (false) {
            break
        }
    }

}

impl IList {
    pub mut fn unlink_front_node() -> *mut IList_node {
        let __param_self_: *mut IList = self as *mut IList
        return ((unsafe { IList_unlink_after_node(__param_self_, (*__param_self_).last) } as *mut IList_node))

    }

    pub fn value_clone(__param_val: i32) -> i32 {
        let __param_self_: *const IList = self as *const IList

        return __param_val

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const IList = self as *const IList
        return (((((unsafe *__param_self_).last == null)) as bool))

    }

    pub mut fn push(__param_value: i32) -> *mut i32 {
        let __param_self_: *mut IList = self as *mut IList
        return ((unsafe { IList_push_back(__param_self_, __param_value) } as *mut i32))

    }

    pub mut fn pop_front() {
        let __param_self_: *mut IList = self as *mut IList
        if ((if not (not unsafe { (*(__param_self_ as *const IList)).is_empty() }): 1 else: 0) as i64) {
            __assert_rtn(c"IList_pop_front".ptr, c"list.h".ptr, (162 as i32), c"!IList_is_empty(self)".ptr)
        } else {
            0
        }

        unsafe { IList_erase_after_node(__param_self_, (*__param_self_).last) }

    }

    pub mut fn move_() -> IList {
        let __param_self_: *mut IList = self as *mut IList
        var __local_m: IList = (unsafe *__param_self_)

        ((unsafe *__param_self_).last = ((null as *mut IList_node)))

        return __local_m

    }

    pub mut fn take(__param_unowned: IList) -> Unit {
        let __param_self_: *mut IList = self as *mut IList
        unsafe { IList_drop((__param_self_ as *const IList)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[IList]())

    }

    pub fn count() -> i64 {
        let __param_self_: *const IList = self as *const IList
        var __local_n: i64 = ((1 as i64))

        var __local_node: *const IList_node = (((unsafe *__param_self_).last as *const IList_node))

        if (__local_node == null) {
            return ((0 as i64))
        }

        while true {
            (__local_node = (((unsafe *__local_node).next as *const IList_node)))

            if (not (__local_node != (unsafe *__param_self_).last)) {
                break
            }

            (__local_n = __local_n + 1)

        }

        return __local_n

    }

    pub fn begin() -> IList_iter {
        let __param_self_: *const IList = self as *const IList
        var __local_head: *mut i32 = (if (unsafe *__param_self_).last != null: ((&raw const (unsafe *(*(*__param_self_).last).next).value as *const i32) as *mut i32) else: (null as *mut i32))

        return ((IList_iter { ref: __local_head, _last: (&raw const (unsafe *__param_self_).last as *const *mut IList_node), prev: (unsafe *__param_self_).last } as IList_iter))

    }

    pub fn end() -> IList_iter {
        let __param_self_: *const IList = self as *const IList

        return ((IList_iter.zeroed() as IList_iter))

    }

    pub fn find(__param_val: i32) -> IList_iter {
        let __param_self_: *const IList = self as *const IList
        return unsafe { IList_find_in(__param_self_, unsafe { (*__param_self_).begin() }, unsafe { (*__param_self_).end() }, __param_val) }

    }

}

impl IList_iter {
    pub mut fn next() {
        let __param_it_: *mut IList_iter = self as *mut IList_iter
        var __local_node: *mut IList_node = with 0 as __ci_expr_seq_5 {
            ((unsafe *__param_it_).prev = (((if true: (unsafe *__param_it_).ref else: (null as *mut i32)) as *mut IList_node)))
            (unsafe *__param_it_).prev
        }

        ((unsafe *__param_it_).ref = (if __local_node == (unsafe *((*__param_it_)._last)): (null as *mut i32) else: ((&raw const (unsafe *(*__local_node).next).value as *const i32) as *mut i32)))

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
