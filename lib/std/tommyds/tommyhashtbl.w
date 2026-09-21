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

pub unsafe fn tommy_hashtable_init(__param_hashtable: *mut tommy_hashtable_struct, __param_bucket_max: c_ulonglong) -> Unit {
    var __local_bucket_max = __param_bucket_max
    if ((if __local_bucket_max < 16: 1 else: 0) != 0) {
        (__local_bucket_max = ((16 as c_ulonglong)))
    } else {
        (__local_bucket_max = ((tommy_roundup_pow2_u64(__local_bucket_max) as c_ulonglong)))
    }

    ((*__param_hashtable).bucket_max = __local_bucket_max)

    ((*__param_hashtable).bucket_mask = (((((*__param_hashtable).bucket_max as c_ulonglong) -% (1 as c_ulonglong)) as c_ulonglong)))

    ((*__param_hashtable).bucket = (((with_alloc((((((*__param_hashtable).bucket_max as c_ulonglong) *% (8 as c_ulonglong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut tommy_node_struct)))

    with_memset((((*__param_hashtable).bucket as *mut c_void) as *mut u8), (0 as c_int), (((((*__param_hashtable).bucket_max as c_ulonglong) *% (8 as c_ulonglong)) as c_ulong) as i64))

    ((*__param_hashtable).count = ((0 as c_ulonglong)))

}

pub unsafe fn tommy_hashtable_done(__param_hashtable: *mut tommy_hashtable_struct) -> Unit {
    with_free((((*__param_hashtable).bucket as *mut c_void) as *mut u8))

}

pub unsafe fn tommy_hashtable_insert(__param_hashtable: *mut tommy_hashtable_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void, __param_hash: c_ulonglong) -> Unit {
    var __local_pos: c_ulonglong = ((((__param_hash as c_ulonglong) & ((*__param_hashtable).bucket_mask as c_ulonglong)) as c_ulonglong))

    tommy_list_insert_tail(((&raw const ((*__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node, __param_data)

    ((*__param_node).index = __param_hash)

    ((*__param_hashtable).count = ((*__param_hashtable).count +% 1))

}

pub unsafe fn tommy_hashtable_remove(__param_hashtable: *mut tommy_hashtable_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_cmp_arg: *const c_void, __param_hash: c_ulonglong) -> *mut c_void {
    var __local_pos: c_ulonglong = ((((__param_hash as c_ulonglong) & ((*__param_hashtable).bucket_mask as c_ulonglong)) as c_ulonglong))

    var __local_node: *mut tommy_node_struct = ((*__param_hashtable).bucket[__local_pos])

    while (__local_node != null) {
        var __ci_expr_logic_0: c_int = 0

        if ((if (*__local_node).index == __param_hash: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __param_cmp(__param_cmp_arg, ((*__local_node).data as *const c_void)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            tommy_list_remove_existing(((&raw const ((*__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __local_node)

            ((*__param_hashtable).count = ((*__param_hashtable).count -% 1))

            return (*__local_node).data

        }


        (__local_node = (*__local_node).next)

    }

    return ((0 as *mut c_void))

}

pub unsafe fn tommy_hashtable_bucket(__param_hashtable: *mut tommy_hashtable_struct, __param_hash: c_ulonglong) -> *mut tommy_node_struct {
    return ((((*__param_hashtable).bucket[((__param_hash as c_ulonglong) & ((*__param_hashtable).bucket_mask as c_ulonglong))]) as *mut tommy_node_struct))

}

pub unsafe fn tommy_hashtable_search(__param_hashtable: *mut tommy_hashtable_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_cmp_arg: *const c_void, __param_hash: c_ulonglong) -> *mut c_void {
    var __local_i: *mut tommy_node_struct = tommy_hashtable_bucket(__param_hashtable, __param_hash)

    while (__local_i != null) {
        var __ci_expr_logic_0: c_int = 0

        if ((if (*__local_i).index == __param_hash: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __param_cmp(__param_cmp_arg, ((*__local_i).data as *const c_void)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return (*__local_i).data
        }


        (__local_i = (*__local_i).next)

    }

    return ((0 as *mut c_void))

}

pub unsafe fn tommy_hashtable_remove_existing(__param_hashtable: *mut tommy_hashtable_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_pos: c_ulonglong = (((((*__param_node).index as c_ulonglong) & ((*__param_hashtable).bucket_mask as c_ulonglong)) as c_ulonglong))

    tommy_list_remove_existing(((&raw const ((*__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node)

    ((*__param_hashtable).count = ((*__param_hashtable).count -% 1))

    return (*__param_node).data

}

pub unsafe fn tommy_hashtable_foreach(__param_hashtable: *mut tommy_hashtable_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    var __local_bucket_max: c_ulonglong = (*__param_hashtable).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (*__param_hashtable).bucket

    var __local_pos: c_ulonglong

    (__local_pos = ((0 as c_ulonglong)))

    while ((if __local_pos < __local_bucket_max: 1 else: 0) != 0) {
        var __local_node: *mut tommy_node_struct = (__local_bucket[__local_pos])

        while (__local_node != null) {
            var __local_data: *mut c_void = (*__local_node).data

            (__local_node = (*__local_node).next)

            __param_func(__local_data)

        }


        (__local_pos = (__local_pos +% 1))

    }


}

pub unsafe fn tommy_hashtable_foreach_arg(__param_hashtable: *mut tommy_hashtable_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) -> Unit {
    var __local_bucket_max: c_ulonglong = (*__param_hashtable).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (*__param_hashtable).bucket

    var __local_pos: c_ulonglong

    (__local_pos = ((0 as c_ulonglong)))

    while ((if __local_pos < __local_bucket_max: 1 else: 0) != 0) {
        var __local_node: *mut tommy_node_struct = (__local_bucket[__local_pos])

        while (__local_node != null) {
            var __local_data: *mut c_void = (*__local_node).data

            (__local_node = (*__local_node).next)

            __param_func(__param_arg, __local_data)

        }


        (__local_pos = (__local_pos +% 1))

    }


}

pub unsafe fn tommy_hashtable_count(__param_hashtable: *mut tommy_hashtable_struct) -> c_ulonglong {
    return (*__param_hashtable).count

}

pub unsafe fn tommy_hashtable_memory_usage(__param_hashtable: *mut tommy_hashtable_struct) -> c_ulonglong {
    return (((((*__param_hashtable).bucket_max as c_ulonglong) *% ((sizeof[usize]() as c_ulonglong) as c_ulonglong)) as c_ulonglong) +% (((tommy_hashtable_count(__param_hashtable) as c_ulonglong) *% ((sizeof[tommy_node_struct]() as c_ulonglong) as c_ulonglong)) as c_ulonglong))

}
