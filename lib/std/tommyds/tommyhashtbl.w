// Migrated from C
use std.tommyds.defs
use std.tommyds.tommyhash
use std.tommyds.tommylist

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

fn tommy_inthash_u32(__param_key: c_uint) -> c_uint {
    var __local_key = __param_key
    (__local_key = (__local_key -% ((__local_key as c_uint) << (6 as c_uint))))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) >> (17 as c_uint)) as c_uint))

    (__local_key = (__local_key -% ((__local_key as c_uint) << (9 as c_uint))))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) << (4 as c_uint)) as c_uint))

    (__local_key = (__local_key -% ((__local_key as c_uint) << (3 as c_uint))))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) << (10 as c_uint)) as c_uint))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) >> (15 as c_uint)) as c_uint))

    return __local_key

}

fn tommy_inthash_u64(__param_key: c_ulonglong) -> c_ulonglong {
    var __local_key = __param_key
    (__local_key = (((((~__local_key) as c_ulonglong) +% (((__local_key as c_ulonglong) << (21 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) ^ (((__local_key as c_ulonglong) >> (24 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((((__local_key as c_ulonglong) +% (((__local_key as c_ulonglong) << (3 as c_uint)) as c_ulonglong)) as c_ulonglong) +% (((__local_key as c_ulonglong) << (8 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) ^ (((__local_key as c_ulonglong) >> (14 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((((__local_key as c_ulonglong) +% (((__local_key as c_ulonglong) << (2 as c_uint)) as c_ulonglong)) as c_ulonglong) +% (((__local_key as c_ulonglong) << (4 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) ^ (((__local_key as c_ulonglong) >> (28 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) +% (((__local_key as c_ulonglong) << (31 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    return __local_key

}

pub unsafe fn tommy_hashtable_init(__param_hashtable: *mut tommy_hashtable_struct, __param_bucket_max: c_ulonglong) -> Unit {
    var __local_bucket_max = __param_bucket_max
    if ((if __local_bucket_max < 16: 1 else: 0) != 0) {
        (__local_bucket_max = ((16 as c_ulonglong)))
    } else {
        (__local_bucket_max = ((tommy_roundup_pow2_u64(__local_bucket_max) as c_ulonglong)))
    }

    ((unsafe *__param_hashtable).bucket_max = __local_bucket_max)

    ((unsafe *__param_hashtable).bucket_mask = (((((unsafe *__param_hashtable).bucket_max as c_ulonglong) -% (1 as c_ulonglong)) as c_ulonglong)))

    ((unsafe *__param_hashtable).bucket = (((with_alloc((((((unsafe *__param_hashtable).bucket_max as c_ulonglong) *% (8 as c_ulonglong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut tommy_node_struct)))

    with_memset((((unsafe *__param_hashtable).bucket as *mut c_void) as *mut u8), (0 as c_int), (((((unsafe *__param_hashtable).bucket_max as c_ulonglong) *% (8 as c_ulonglong)) as c_ulong) as i64))

    ((unsafe *__param_hashtable).count = ((0 as c_ulonglong)))

}

pub unsafe fn tommy_hashtable_done(__param_hashtable: *mut tommy_hashtable_struct) -> Unit {
    with_free((((unsafe *__param_hashtable).bucket as *mut c_void) as *mut u8))

}

pub unsafe fn tommy_hashtable_insert(__param_hashtable: *mut tommy_hashtable_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void, __param_hash: c_ulonglong) -> Unit {
    var __local_pos: c_ulonglong = ((((__param_hash as c_ulonglong) & ((unsafe *__param_hashtable).bucket_mask as c_ulonglong)) as c_ulonglong))

    tommy_list_insert_tail(((&raw const (unsafe (unsafe *__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node, __param_data)

    ((unsafe *__param_node).index = __param_hash)

    ((unsafe *__param_hashtable).count = ((unsafe *__param_hashtable).count +% 1))

}

pub unsafe fn tommy_hashtable_remove(__param_hashtable: *mut tommy_hashtable_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_cmp_arg: *const c_void, __param_hash: c_ulonglong) -> *mut c_void {
    var __local_pos: c_ulonglong = ((((__param_hash as c_ulonglong) & ((unsafe *__param_hashtable).bucket_mask as c_ulonglong)) as c_ulonglong))

    var __local_node: *mut tommy_node_struct = (unsafe (unsafe *__param_hashtable).bucket[__local_pos])

    while (__local_node != null) {
        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe *__local_node).index == __param_hash: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __param_cmp(__param_cmp_arg, ((unsafe *__local_node).data as *const c_void)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            tommy_list_remove_existing(((&raw const (unsafe (unsafe *__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __local_node)

            ((unsafe *__param_hashtable).count = ((unsafe *__param_hashtable).count -% 1))

            return (unsafe *__local_node).data

        }


        (__local_node = (unsafe *__local_node).next)

    }

    return ((0 as *mut c_void))

}

unsafe fn tommy_hashtable_bucket(__param_hashtable: *mut tommy_hashtable_struct, __param_hash: c_ulonglong) -> *mut tommy_node_struct {
    return (((unsafe (unsafe *__param_hashtable).bucket[((__param_hash as c_ulonglong) & ((unsafe *__param_hashtable).bucket_mask as c_ulonglong))]) as *mut tommy_node_struct))

}

unsafe fn tommy_hashtable_search(__param_hashtable: *mut tommy_hashtable_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_cmp_arg: *const c_void, __param_hash: c_ulonglong) -> *mut c_void {
    var __local_i: *mut tommy_node_struct = tommy_hashtable_bucket(__param_hashtable, __param_hash)

    while (__local_i != null) {
        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe *__local_i).index == __param_hash: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __param_cmp(__param_cmp_arg, ((unsafe *__local_i).data as *const c_void)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return (unsafe *__local_i).data
        }


        (__local_i = (unsafe *__local_i).next)

    }

    return ((0 as *mut c_void))

}

pub unsafe fn tommy_hashtable_remove_existing(__param_hashtable: *mut tommy_hashtable_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_pos: c_ulonglong = (((((unsafe *__param_node).index as c_ulonglong) & ((unsafe *__param_hashtable).bucket_mask as c_ulonglong)) as c_ulonglong))

    tommy_list_remove_existing(((&raw const (unsafe (unsafe *__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node)

    ((unsafe *__param_hashtable).count = ((unsafe *__param_hashtable).count -% 1))

    return (unsafe *__param_node).data

}

pub unsafe fn tommy_hashtable_foreach(__param_hashtable: *mut tommy_hashtable_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    var __local_bucket_max: c_ulonglong = (unsafe *__param_hashtable).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (unsafe *__param_hashtable).bucket

    var __local_pos: c_ulonglong

    (__local_pos = ((0 as c_ulonglong)))

    while ((if __local_pos < __local_bucket_max: 1 else: 0) != 0) {
        var __local_node: *mut tommy_node_struct = (unsafe __local_bucket[__local_pos])

        while (__local_node != null) {
            var __local_data: *mut c_void = (unsafe *__local_node).data

            (__local_node = (unsafe *__local_node).next)

            __param_func(__local_data)

        }


        (__local_pos = (__local_pos +% 1))

    }


}

pub unsafe fn tommy_hashtable_foreach_arg(__param_hashtable: *mut tommy_hashtable_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) -> Unit {
    var __local_bucket_max: c_ulonglong = (unsafe *__param_hashtable).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (unsafe *__param_hashtable).bucket

    var __local_pos: c_ulonglong

    (__local_pos = ((0 as c_ulonglong)))

    while ((if __local_pos < __local_bucket_max: 1 else: 0) != 0) {
        var __local_node: *mut tommy_node_struct = (unsafe __local_bucket[__local_pos])

        while (__local_node != null) {
            var __local_data: *mut c_void = (unsafe *__local_node).data

            (__local_node = (unsafe *__local_node).next)

            __param_func(__param_arg, __local_data)

        }


        (__local_pos = (__local_pos +% 1))

    }


}

unsafe fn tommy_hashtable_count(__param_hashtable: *mut tommy_hashtable_struct) -> c_ulonglong {
    return (unsafe *__param_hashtable).count

}

pub unsafe fn tommy_hashtable_memory_usage(__param_hashtable: *mut tommy_hashtable_struct) -> c_ulonglong {
    return (((((unsafe *__param_hashtable).bucket_max as c_ulonglong) *% ((sizeof[usize]() as c_ulonglong) as c_ulonglong)) as c_ulonglong) +% (((tommy_hashtable_count(__param_hashtable) as c_ulonglong) *% ((sizeof[tommy_node_struct]() as c_ulonglong) as c_ulonglong)) as c_ulonglong))

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
