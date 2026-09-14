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

pub unsafe fn tommy_hashdyn_init(__param_hashdyn: *mut tommy_hashdyn_struct) -> Unit {
    ((unsafe *__param_hashdyn).bucket_bit = ((4 as c_uint)))

    ((unsafe *__param_hashdyn).bucket_max = (((((1 as c_ulonglong) as c_ulonglong) << ((unsafe *__param_hashdyn).bucket_bit as c_uint)) as c_ulonglong)))

    ((unsafe *__param_hashdyn).bucket_mask = (((((unsafe *__param_hashdyn).bucket_max as c_ulonglong) -% (1 as c_ulonglong)) as c_ulonglong)))

    ((unsafe *__param_hashdyn).bucket = (((with_alloc_zeroed((((unsafe *__param_hashdyn).bucket_max as c_ulong) as i64), ((sizeof[usize]() as c_ulong) as i64)) as *mut c_void) as *mut *mut tommy_node_struct)))

    ((unsafe *__param_hashdyn).count = ((0 as c_ulonglong)))

}

pub unsafe fn tommy_hashdyn_done(__param_hashdyn: *mut tommy_hashdyn_struct) -> Unit {
    with_free((((unsafe *__param_hashdyn).bucket as *mut c_void) as *mut u8))

}

pub unsafe fn tommy_hashdyn_insert(__param_hashdyn: *mut tommy_hashdyn_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void, __param_hash: c_ulonglong) -> Unit {
    var __local_pos: c_ulonglong = ((((__param_hash as c_ulonglong) & ((unsafe *__param_hashdyn).bucket_mask as c_ulonglong)) as c_ulonglong))

    tommy_list_insert_tail(((&raw const (unsafe (unsafe *__param_hashdyn).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node, __param_data)

    ((unsafe *__param_node).index = __param_hash)

    ((unsafe *__param_hashdyn).count = ((unsafe *__param_hashdyn).count +% 1))

    hashdyn_grow_step(__param_hashdyn)

}

pub unsafe fn tommy_hashdyn_remove(__param_hashdyn: *mut tommy_hashdyn_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_cmp_arg: *const c_void, __param_hash: c_ulonglong) -> *mut c_void {
    var __local_pos: c_ulonglong = ((((__param_hash as c_ulonglong) & ((unsafe *__param_hashdyn).bucket_mask as c_ulonglong)) as c_ulonglong))

    var __local_node: *mut tommy_node_struct = (unsafe (unsafe *__param_hashdyn).bucket[__local_pos])

    while (__local_node != null) {
        var __ci_expr_logic_0: c_int = 0

        if ((if (unsafe *__local_node).index == __param_hash: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __param_cmp(__param_cmp_arg, ((unsafe *__local_node).data as *const c_void)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            tommy_list_remove_existing(((&raw const (unsafe (unsafe *__param_hashdyn).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __local_node)

            ((unsafe *__param_hashdyn).count = ((unsafe *__param_hashdyn).count -% 1))

            hashdyn_shrink_step(__param_hashdyn)

            return (unsafe *__local_node).data

        }


        (__local_node = (unsafe *__local_node).next)

    }

    return ((0 as *mut c_void))

}

pub unsafe fn tommy_hashdyn_bucket(__param_hashdyn: *mut tommy_hashdyn_struct, __param_hash: c_ulonglong) -> *mut tommy_node_struct {
    return (((unsafe (unsafe *__param_hashdyn).bucket[((__param_hash as c_ulonglong) & ((unsafe *__param_hashdyn).bucket_mask as c_ulonglong))]) as *mut tommy_node_struct))

}

pub unsafe fn tommy_hashdyn_search(__param_hashdyn: *mut tommy_hashdyn_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_cmp_arg: *const c_void, __param_hash: c_ulonglong) -> *mut c_void {
    var __local_i: *mut tommy_node_struct = tommy_hashdyn_bucket(__param_hashdyn, __param_hash)

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

pub unsafe fn tommy_hashdyn_remove_existing(__param_hashdyn: *mut tommy_hashdyn_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_pos: c_ulonglong = (((((unsafe *__param_node).index as c_ulonglong) & ((unsafe *__param_hashdyn).bucket_mask as c_ulonglong)) as c_ulonglong))

    tommy_list_remove_existing(((&raw const (unsafe (unsafe *__param_hashdyn).bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_node)

    ((unsafe *__param_hashdyn).count = ((unsafe *__param_hashdyn).count -% 1))

    hashdyn_shrink_step(__param_hashdyn)

    return (unsafe *__param_node).data

}

pub unsafe fn tommy_hashdyn_foreach(__param_hashdyn: *mut tommy_hashdyn_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    var __local_bucket_max: c_ulonglong = (unsafe *__param_hashdyn).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (unsafe *__param_hashdyn).bucket

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

pub unsafe fn tommy_hashdyn_foreach_arg(__param_hashdyn: *mut tommy_hashdyn_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) -> Unit {
    var __local_bucket_max: c_ulonglong = (unsafe *__param_hashdyn).bucket_max

    var __local_bucket: *mut *mut tommy_node_struct = (unsafe *__param_hashdyn).bucket

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

pub unsafe fn tommy_hashdyn_count(__param_hashdyn: *mut tommy_hashdyn_struct) -> c_ulonglong {
    return (unsafe *__param_hashdyn).count

}

pub unsafe fn tommy_hashdyn_memory_usage(__param_hashdyn: *mut tommy_hashdyn_struct) -> c_ulonglong {
    return (((((unsafe *__param_hashdyn).bucket_max as c_ulonglong) *% ((sizeof[usize]() as c_ulonglong) as c_ulonglong)) as c_ulonglong) +% (((tommy_hashdyn_count(__param_hashdyn) as c_ulonglong) *% ((sizeof[tommy_node_struct]() as c_ulonglong) as c_ulonglong)) as c_ulonglong))

}

unsafe fn tommy_hashdyn_resize(__param_hashdyn: *mut tommy_hashdyn_struct, __param_new_bucket_bit: c_uint) -> Unit {
    var __local_bucket_bit: c_ulonglong

    var __local_bucket_max: c_ulonglong

    var __local_new_bucket_max: c_ulonglong

    var __local_new_bucket_mask: c_ulonglong

    var __local_new_bucket: *mut *mut tommy_node_struct

    (__local_bucket_bit = (((unsafe *__param_hashdyn).bucket_bit as c_ulonglong)))

    (__local_bucket_max = (unsafe *__param_hashdyn).bucket_max)

    (__local_new_bucket_max = (((((1 as c_ulonglong) as c_ulonglong) << (__param_new_bucket_bit as c_uint)) as c_ulonglong)))

    (__local_new_bucket_mask = ((((__local_new_bucket_max as c_ulonglong) -% (1 as c_ulonglong)) as c_ulonglong)))

    (__local_new_bucket = (((with_alloc(((((__local_new_bucket_max as c_ulonglong) *% (8 as c_ulonglong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut tommy_node_struct)))

    if ((if __param_new_bucket_bit > __local_bucket_bit: 1 else: 0) != 0) {
        var __local_i: c_ulonglong

        (__local_i = ((0 as c_ulonglong)))

        while ((if __local_i < __local_bucket_max: 1 else: 0) != 0) {
            var __local_j: *mut tommy_node_struct

            ((unsafe __local_new_bucket[__local_i]) = null)

            ((unsafe __local_new_bucket[((__local_i as c_ulonglong) +% (__local_bucket_max as c_ulonglong))]) = null)

            (__local_j = (unsafe (unsafe *__param_hashdyn).bucket[__local_i]))

            while (__local_j != null) {
                var __local_j_next: *mut tommy_node_struct = (unsafe *__local_j).next

                var __local_pos: c_ulonglong = (((((unsafe *__local_j).index as c_ulonglong) & (__local_new_bucket_mask as c_ulonglong)) as c_ulonglong))

                if ((unsafe __local_new_bucket[__local_pos]) != null) {
                    tommy_list_insert_tail_not_empty((unsafe __local_new_bucket[__local_pos]), __local_j)
                } else {
                    tommy_list_insert_first(((&raw const (unsafe __local_new_bucket[__local_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __local_j)
                }

                (__local_j = __local_j_next)

            }


            (__local_i = (__local_i +% 1))

        }


    } else {
        var __local_i_1: c_ulonglong

        (__local_i_1 = ((0 as c_ulonglong)))

        while ((if __local_i_1 < __local_new_bucket_max: 1 else: 0) != 0) {
            ((unsafe __local_new_bucket[__local_i_1]) = (unsafe (unsafe *__param_hashdyn).bucket[__local_i_1]))

            tommy_list_concat(((&raw const (unsafe __local_new_bucket[__local_i_1]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), ((&raw const (unsafe (unsafe *__param_hashdyn).bucket[((__local_i_1 as c_ulonglong) +% (__local_new_bucket_max as c_ulonglong))]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct))


            (__local_i_1 = (__local_i_1 +% 1))

        }


    }

    with_free((((unsafe *__param_hashdyn).bucket as *mut c_void) as *mut u8))

    ((unsafe *__param_hashdyn).bucket_bit = __param_new_bucket_bit)

    ((unsafe *__param_hashdyn).bucket_max = __local_new_bucket_max)

    ((unsafe *__param_hashdyn).bucket_mask = __local_new_bucket_mask)

    ((unsafe *__param_hashdyn).bucket = __local_new_bucket)

}

unsafe fn hashdyn_grow_step(__param_hashdyn: *mut tommy_hashdyn_struct) -> Unit {
    if ((if (unsafe *__param_hashdyn).count >= (((unsafe *__param_hashdyn).bucket_max as c_ulonglong) / (2 as c_ulonglong)): 1 else: 0) != 0) {
        tommy_hashdyn_resize(__param_hashdyn, ((((unsafe *__param_hashdyn).bucket_bit as c_uint) +% (1 as c_uint)) as c_uint))
    }

}

unsafe fn hashdyn_shrink_step(__param_hashdyn: *mut tommy_hashdyn_struct) -> Unit {
    var __ci_expr_logic_0: c_int = 0

    if ((if (unsafe *__param_hashdyn).count <= (((unsafe *__param_hashdyn).bucket_max as c_ulonglong) / (8 as c_ulonglong)): 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_hashdyn).bucket_bit > 4: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        tommy_hashdyn_resize(__param_hashdyn, ((((unsafe *__param_hashdyn).bucket_bit as c_uint) -% (1 as c_uint)) as c_uint))
    }


}
