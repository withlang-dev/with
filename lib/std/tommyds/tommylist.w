// Migrated from C
use std.tommyds.defs

fn tommy_ilog2_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).clz() as c_int) ^ (31 as c_int))

}

fn tommy_ilog2_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).clz() as c_int) ^ (63 as c_int))

}

fn tommy_ctz_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).ctz() as c_uint))

}

fn tommy_ctz_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).ctz() as c_uint))

}

fn tommy_roundup_pow2_u32(__param_value: c_uint) -> c_uint {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (1 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (2 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (4 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (8 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (16 as c_uint)) as c_uint))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: c_ulonglong) -> c_ulonglong {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (1 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (2 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (4 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (8 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (16 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (32 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: c_uint) -> c_int {
    return (if ((((((__param_value as c_uint) -% (16843009 as c_uint)) as c_uint) & ((~__param_value) as c_uint)) as c_uint) & ((2155905152 as c_uint) as c_uint)) != 0: 1 else: 0)

}

unsafe fn tommy_list_init(__param_list: *mut *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_list) = null)

}

unsafe fn tommy_list_head(__param_list: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    return (unsafe *__param_list)

}

unsafe fn tommy_list_tail(__param_list: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if ((if not (__local_head != null): 1 else: 0) != 0) {
        return ((0 as *mut tommy_node_struct))
    }

    return (unsafe *__local_head).prev

}

unsafe fn tommy_list_insert_first(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_node).prev = __param_node)

    ((unsafe *__param_node).next = null)

    ((unsafe *__param_list) = __param_node)

}

unsafe fn tommy_list_insert_head_not_empty(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> Unit {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    ((unsafe *__param_node).prev = (unsafe *__local_head).prev)

    ((unsafe *__local_head).prev = __param_node)

    ((unsafe *__param_node).next = __local_head)

    ((unsafe *__param_list) = __param_node)

}

unsafe fn tommy_list_insert_tail_not_empty(__param_head: *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_node).prev = (unsafe *__param_head).prev)

    ((unsafe *__param_head).prev = __param_node)

    ((unsafe *__param_node).next = null)

    ((unsafe *(unsafe *__param_node).prev).next = __param_node)

}

unsafe fn tommy_list_insert_head(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void) -> Unit {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if (__local_head != null) {
        tommy_list_insert_head_not_empty(__param_list, __param_node)
    } else {
        tommy_list_insert_first(__param_list, __param_node)
    }

    ((unsafe *__param_node).data = __param_data)

}

unsafe fn tommy_list_insert_tail(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void) -> Unit {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if (__local_head != null) {
        tommy_list_insert_tail_not_empty(__local_head, __param_node)
    } else {
        tommy_list_insert_first(__param_list, __param_node)
    }

    ((unsafe *__param_node).data = __param_data)

}

unsafe fn tommy_list_remove_existing(__param_list: *mut *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_head: *mut tommy_node_struct = tommy_list_head(__param_list)

    if ((unsafe *__param_node).next != null) {
        ((unsafe *(unsafe *__param_node).next).prev = (unsafe *__param_node).prev)
    } else {
        ((unsafe *__local_head).prev = (unsafe *__param_node).prev)
    }

    if ((if __local_head == __param_node: 1 else: 0) != 0) {
        ((unsafe *__param_list) = (unsafe *__param_node).next)
    } else {
        ((unsafe *(unsafe *__param_node).prev).next = (unsafe *__param_node).next)
    }

    return (unsafe *__param_node).data

}

unsafe fn tommy_list_concat(__param_first: *mut *mut tommy_node_struct, __param_second: *mut *mut tommy_node_struct) -> Unit {
    var __local_first_head: *mut tommy_node_struct

    var __local_first_tail: *mut tommy_node_struct

    var __local_second_head: *mut tommy_node_struct

    (__local_second_head = tommy_list_head(__param_second))

    if ((if __local_second_head == 0: 1 else: 0) != 0) {
        return
    }

    (__local_first_head = tommy_list_head(__param_first))

    if ((if __local_first_head == 0: 1 else: 0) != 0) {
        ((unsafe *__param_first) = (unsafe *__param_second))

        return

    }

    (__local_first_tail = (unsafe *__local_first_head).prev)

    ((unsafe *__local_first_head).prev = (unsafe *__local_second_head).prev)

    ((unsafe *__local_second_head).prev = __local_first_tail)

    ((unsafe *__local_first_tail).next = __local_second_head)

}

pub unsafe fn tommy_list_sort(__param_list: *mut *mut tommy_node_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int) -> Unit {
    var __local_chain: tommy_chain_struct

    var __local_head: *mut tommy_node_struct

    if (tommy_list_empty(__param_list) != 0) {
        return
    }

    (__local_head = tommy_list_head(__param_list))

    (__local_chain.head = __local_head)

    (__local_chain.tail = (unsafe *__local_head).prev)

    tommy_chain_mergesort((&raw mut __local_chain as *mut tommy_chain_struct), __param_cmp)

    tommy_list_set(__param_list, (unsafe *(&raw const __local_chain as *const tommy_chain_struct)).head, (unsafe *(&raw const __local_chain as *const tommy_chain_struct)).tail)

}

unsafe fn tommy_list_empty(__param_list: *mut *mut tommy_node_struct) -> c_int {
    return (if tommy_list_head(__param_list) == 0: 1 else: 0)

}

unsafe fn tommy_list_count(__param_list: *mut *mut tommy_node_struct) -> c_ulonglong {
    var __local_count: c_ulonglong = ((0 as c_ulonglong))

    var __local_i: *mut tommy_node_struct = tommy_list_head(__param_list)

    while (__local_i != null) {
        (__local_count = (__local_count +% 1))

        (__local_i = (unsafe *__local_i).next)

    }

    return __local_count

}

unsafe fn tommy_list_foreach(__param_list: *mut *mut tommy_node_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    var __local_node: *mut tommy_node_struct = tommy_list_head(__param_list)

    while (__local_node != null) {
        var __local_data: *mut c_void = (unsafe *__local_node).data

        (__local_node = (unsafe *__local_node).next)

        __param_func(__local_data)

    }

}

unsafe fn tommy_list_foreach_arg(__param_list: *mut *mut tommy_node_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) -> Unit {
    var __local_node: *mut tommy_node_struct = tommy_list_head(__param_list)

    while (__local_node != null) {
        var __local_data: *mut c_void = (unsafe *__local_node).data

        (__local_node = (unsafe *__local_node).next)

        __param_func(__param_arg, __local_data)

    }

}

unsafe fn tommy_chain_splice(__param_first_before: *mut tommy_node_struct, __param_first_after: *mut tommy_node_struct, __param_second_head: *mut tommy_node_struct, __param_second_tail: *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_first_after).prev = __param_second_tail)

    ((unsafe *__param_second_head).prev = __param_first_before)

    ((unsafe *__param_first_before).next = __param_second_head)

    ((unsafe *__param_second_tail).next = __param_first_after)

}

unsafe fn tommy_chain_concat(__param_first_tail: *mut tommy_node_struct, __param_second_head: *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_second_head).prev = __param_first_tail)

    ((unsafe *__param_first_tail).next = __param_second_head)

}

unsafe fn tommy_chain_merge(__param_first: *mut tommy_chain_struct, __param_second: *mut tommy_chain_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int) -> Unit {
    var __local_first_i: *mut tommy_node_struct = (unsafe *__param_first).head

    var __local_second_i: *mut tommy_node_struct = (unsafe *__param_second).head

    while (1 != 0) {
        if ((if __param_cmp(((unsafe *__local_first_i).data as *const c_void), ((unsafe *__local_second_i).data as *const c_void)) > 0: 1 else: 0) != 0) {
            var __local_next: *mut tommy_node_struct = (unsafe *__local_second_i).next

            if ((if __local_first_i == (unsafe *__param_first).head: 1 else: 0) != 0) {
                tommy_chain_concat(__local_second_i, __local_first_i)

                ((unsafe *__param_first).head = __local_second_i)

            } else {
                tommy_chain_splice((unsafe *__local_first_i).prev, __local_first_i, __local_second_i, __local_second_i)

            }

            if ((if __local_second_i == (unsafe *__param_second).tail: 1 else: 0) != 0) {
                break
            }

            (__local_second_i = __local_next)

        } else {
            if ((if __local_first_i == (unsafe *__param_first).tail: 1 else: 0) != 0) {
                tommy_chain_concat(__local_first_i, __local_second_i)

                ((unsafe *__param_first).tail = (unsafe *__param_second).tail)

                break

            }

            (__local_first_i = (unsafe *__local_first_i).next)

        }

    }

}

unsafe fn tommy_chain_merge_degenerated(__param_first: *mut tommy_chain_struct, __param_second: *mut tommy_chain_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int) -> Unit {
    if ((if __param_cmp(((unsafe *(unsafe *__param_first).tail).data as *const c_void), ((unsafe *(unsafe *__param_second).head).data as *const c_void)) <= 0: 1 else: 0) != 0) {
        tommy_chain_concat((unsafe *__param_first).tail, (unsafe *__param_second).head)

        ((unsafe *__param_first).tail = (unsafe *__param_second).tail)

        return

    }

    if ((if __param_cmp(((unsafe *(unsafe *__param_second).tail).data as *const c_void), ((unsafe *(unsafe *__param_first).head).data as *const c_void)) < 0: 1 else: 0) != 0) {
        tommy_chain_concat((unsafe *__param_second).tail, (unsafe *__param_first).head)

        ((unsafe *__param_first).head = (unsafe *__param_second).head)

        return

    }

    tommy_chain_merge(__param_first, __param_second, __param_cmp)

}

unsafe fn tommy_chain_mergesort(__param_chain: *mut tommy_chain_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int) -> Unit {
    var __local_bit: [65]tommy_chain_struct

    var __local_counter: c_ulonglong

    var __local_node: *mut tommy_node_struct = (unsafe *__param_chain).head

    var __local_tail: *mut tommy_node_struct = (unsafe *__param_chain).tail

    var __local_mask: c_ulonglong

    var __local_i: c_ulonglong

    (__local_counter = ((0 as c_ulonglong)))

    while (1 != 0) {
        var __local_next: *mut tommy_node_struct

        var __local_last: *mut tommy_chain_struct

        (__local_last = (((&raw const __local_bit[64] as *const tommy_chain_struct) as *mut tommy_chain_struct)))

        (__local_bit[64].head = __local_node)

        (__local_bit[64].tail = __local_node)

        (__local_next = (unsafe *__local_node).next)

        (__local_i = ((0 as c_ulonglong)))

        (__local_mask = __local_counter)

        while ((if ((__local_mask as c_ulonglong) & (1 as c_ulonglong)) != 0: 1 else: 0) != 0) {
            tommy_chain_merge_degenerated(((&raw const __local_bit[__local_i] as *const tommy_chain_struct) as *mut tommy_chain_struct), __local_last, __param_cmp)

            (__local_mask = __local_mask >> (1 as c_uint))

            (__local_last = (((&raw const __local_bit[__local_i] as *const tommy_chain_struct) as *mut tommy_chain_struct)))

            (__local_i = (__local_i +% 1))

        }

        (__local_bit[__local_i] = (unsafe *__local_last))

        (__local_counter = (__local_counter +% 1))

        if ((if __local_node == __local_tail: 1 else: 0) != 0) {
            break
        }

        (__local_node = __local_next)

    }

    (__local_i = ((tommy_ctz_u64(__local_counter) as c_ulonglong)))

    (__local_mask = ((((__local_counter as c_ulonglong) >> (__local_i as c_uint)) as c_ulonglong)))

    while ((if __local_mask != 1: 1 else: 0) != 0) {
        (__local_mask = __local_mask >> (1 as c_uint))

        if (((__local_mask as c_ulonglong) & (1 as c_ulonglong)) != 0) {
            tommy_chain_merge_degenerated(((&raw const __local_bit[((__local_i as c_ulonglong) +% (1 as c_ulonglong))] as *const tommy_chain_struct) as *mut tommy_chain_struct), ((&raw const __local_bit[__local_i] as *const tommy_chain_struct) as *mut tommy_chain_struct), __param_cmp)
        } else {
            (__local_bit[((__local_i as c_ulonglong) +% (1 as c_ulonglong))] = __local_bit[__local_i])
        }

        (__local_i = (__local_i +% 1))

    }

    with_memcpy((&raw mut (unsafe *__param_chain) as *mut u8), (&raw const __local_bit[__local_i] as *const u8), sizeof[tommy_chain_struct]())

}

unsafe fn tommy_list_set(__param_list: *mut *mut tommy_node_struct, __param_head: *mut tommy_node_struct, __param_tail: *mut tommy_node_struct) -> Unit {
    ((unsafe *__param_head).prev = __param_tail)

    ((unsafe *__param_tail).next = null)

    ((unsafe *__param_list) = __param_head)

}
