// Migrated from C
use std.engines.tommyds.defs
use std.engines.tommyds.tommyhash
use std.engines.tommyds.tommylist

fn tommy_ilog2_u32(__param_value: u32) -> u32 {
    return (((((__param_value as u32).clz() as i32) ^ (31 as i32)) as u32))

}

fn tommy_ilog2_u64(__param_value: u64) -> u32 {
    return (((((__param_value as u64).clz() as i32) ^ (63 as i32)) as u32))

}

fn tommy_ctz_u32(__param_value: u32) -> u32 {
    return (((__param_value as u32).ctz() as u32))

}

fn tommy_ctz_u64(__param_value: u64) -> u32 {
    return (((__param_value as u64).ctz() as u32))

}

fn tommy_roundup_pow2_u32(__param_value: u32) -> u32 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (1 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (2 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (4 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (8 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (16 as u32)) as u32))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: u64) -> u64 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (1 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (2 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (4 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (8 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (16 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (32 as u32)) as u64))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: u32) -> i32 {
    return (if ((((((__param_value as u32) -% (16843009 as u32)) as u32) & ((~__param_value) as u32)) as u32) & (2155905152 as u32)) != 0: 1 else: 0)

}

pub unsafe fn tommy_hashtable_init(__param_hashtable: *mut tommy_hashtable_struct, __param_bucket_max: u64) {
    var __local_bucket_max = __param_bucket_max
    if ((if __local_bucket_max < 16: 1 else: 0) != 0) {
        (__local_bucket_max = ((16 as u64)))
    } else {
        (__local_bucket_max = ((tommy_roundup_pow2_u64(__local_bucket_max) as u64)))
    }

    ((*__param_hashtable).bucket_max = __local_bucket_max)

    ((*__param_hashtable).bucket_mask = (((((*__param_hashtable).bucket_max as u64) -% (1 as u64)) as u64)))

    ((*__param_hashtable).bucket = (((with_alloc((((((*__param_hashtable).bucket_max as u64) *% (8 as u64)) as u64) as i64)) as *mut c_void) as *mut *mut tommy_node_struct)))

    with_memset((((*__param_hashtable).bucket as *mut c_void) as *mut u8), (0 as i32), (((((*__param_hashtable).bucket_max as u64) *% (8 as u64)) as u64) as i64))

    ((*__param_hashtable).count = ((0 as u64)))

}

pub unsafe fn tommy_hashtable_done(__param_hashtable: *mut tommy_hashtable_struct) {
    with_free((((*__param_hashtable).bucket as *mut c_void) as *mut u8))

}

pub unsafe fn tommy_hashtable_insert(__param_hashtable: *mut tommy_hashtable_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void, __param_hash: u64) {
    var __local_pos: u64 = ((((__param_hash as u64) & ((*__param_hashtable).bucket_mask as u64)) as u64))

    tommy_list_insert_tail(((&raw const ((*__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node, __param_data)

    ((*__param_node).index = __param_hash)

    ((*__param_hashtable).count = ((*__param_hashtable).count +% 1))

}

pub unsafe fn tommy_hashtable_remove(__param_hashtable: *mut tommy_hashtable_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> i32, __param_cmp_arg: *const c_void, __param_hash: u64) -> *mut c_void {
    var __local_pos: u64 = ((((__param_hash as u64) & ((*__param_hashtable).bucket_mask as u64)) as u64))

    var __local_node: *mut tommy_node_struct = ((*__param_hashtable).bucket[__local_pos])

    while (__local_node != null) {
        var __ci_expr_logic_0: i32 = 0

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

pub unsafe fn tommy_hashtable_bucket(__param_hashtable: *mut tommy_hashtable_struct, __param_hash: u64) -> *mut tommy_node_struct {
    return ((((*__param_hashtable).bucket[((__param_hash as u64) & ((*__param_hashtable).bucket_mask as u64))]) as *mut tommy_node_struct))

}

pub unsafe fn tommy_hashtable_search(__param_hashtable: *mut tommy_hashtable_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> i32, __param_cmp_arg: *const c_void, __param_hash: u64) -> *mut c_void {
    var __local_i: *mut tommy_node_struct = tommy_hashtable_bucket(__param_hashtable, __param_hash)

    while (__local_i != null) {
        var __ci_expr_logic_0: i32 = 0

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
    var __local_pos: u64 = (((((*__param_node).index as u64) & ((*__param_hashtable).bucket_mask as u64)) as u64))

    tommy_list_remove_existing(((&raw const ((*__param_hashtable).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node)

    ((*__param_hashtable).count = ((*__param_hashtable).count -% 1))

    return (*__param_node).data

}

pub unsafe fn tommy_hashtable_foreach(__param_hashtable: *mut tommy_hashtable_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) {
    var __local_bucket_max: u64 = (*__param_hashtable).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (*__param_hashtable).bucket

    var __local_pos: u64

    (__local_pos = ((0 as u64)))

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

pub unsafe fn tommy_hashtable_foreach_arg(__param_hashtable: *mut tommy_hashtable_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) {
    var __local_bucket_max: u64 = (*__param_hashtable).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (*__param_hashtable).bucket

    var __local_pos: u64

    (__local_pos = ((0 as u64)))

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

pub unsafe fn tommy_hashtable_count(__param_hashtable: *mut tommy_hashtable_struct) -> u64 {
    return (*__param_hashtable).count

}

pub unsafe fn tommy_hashtable_memory_usage(__param_hashtable: *mut tommy_hashtable_struct) -> u64 {
    return (((((*__param_hashtable).bucket_max as u64) *% (sizeof[usize]() as u64)) as u64) +% (((tommy_hashtable_count(__param_hashtable) as u64) *% (sizeof[tommy_node_struct]() as u64)) as u64))

}
