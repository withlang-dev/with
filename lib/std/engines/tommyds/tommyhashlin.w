// Migrated from C
use std.engines.tommyds.defs
use std.engines.tommyds.tommyhash
use std.engines.tommyds.tommylist
use std.collections

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

pub unsafe fn tommy_hashlin_init(__param_hashlin: *mut tommy_hashlin_struct) {
    var __local_i: u32

    ((*__param_hashlin).bucket_bit = ((6 as u32)))

    ((*__param_hashlin).bucket_max = ((((1 as u64) << ((*__param_hashlin).bucket_bit as u32)) as u64)))

    ((*__param_hashlin).bucket_mask = (((((*__param_hashlin).bucket_max as u64) -% (1 as u64)) as u64)))

    ((*__param_hashlin).bucket[0] = (((with_alloc_zeroed(((*__param_hashlin).bucket_max as i64), ((sizeof[usize]() as u64) as i64)) as *mut c_void) as *mut *mut tommy_node_struct)))

    (__local_i = ((1 as u32)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        ((*__param_hashlin).bucket[__local_i] = (*__param_hashlin).bucket[0])

        (__local_i = (__local_i +% 1))

    }


    tommy_hashlin_stable(__param_hashlin)

    ((*__param_hashlin).count = ((0 as u64)))

}

pub unsafe fn tommy_hashlin_done(__param_hashlin: *mut tommy_hashlin_struct) {
    var __local_i: u32

    with_free((((*__param_hashlin).bucket[0] as *mut c_void) as *mut u8))

    (__local_i = ((6 as u32)))

    while ((if __local_i < (*__param_hashlin).bucket_bit: 1 else: 0) != 0) {
        var __local_segment: *mut *mut tommy_node_struct = (*__param_hashlin).bucket[__local_i]

        with_free(((((&raw const (__local_segment[((1 as i64) << (__local_i as u32))]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct) as *mut c_void) as *mut u8))


        (__local_i = (__local_i +% 1))

    }


}

pub unsafe fn tommy_hashlin_insert(__param_hashlin: *mut tommy_hashlin_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void, __param_hash: u64) {
    tommy_list_insert_tail(tommy_hashlin_bucket_ref(__param_hashlin, __param_hash), __param_node, __param_data)

    ((*__param_node).index = __param_hash)

    ((*__param_hashlin).count = ((*__param_hashlin).count +% 1))

    hashlin_grow_step(__param_hashlin)

}

pub unsafe fn tommy_hashlin_remove(__param_hashlin: *mut tommy_hashlin_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> i32, __param_cmp_arg: *const c_void, __param_hash: u64) -> *mut c_void {
    var __local_let_ptr: *mut *mut tommy_node_struct = tommy_hashlin_bucket_ref(__param_hashlin, __param_hash)

    var __local_node: *mut tommy_node_struct = (*__local_let_ptr)

    while (__local_node != null) {
        var __ci_expr_logic_0: i32 = 0

        if ((if (*__local_node).index == __param_hash: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __param_cmp(__param_cmp_arg, ((*__local_node).data as *const c_void)) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            tommy_list_remove_existing(__local_let_ptr, __local_node)

            ((*__param_hashlin).count = ((*__param_hashlin).count -% 1))

            hashlin_shrink_step(__param_hashlin)

            return (*__local_node).data

        }


        (__local_node = (*__local_node).next)

    }

    return ((0 as *mut c_void))

}

pub unsafe fn tommy_hashlin_pos(__param_hashlin: *mut tommy_hashlin_struct, __param_pos: u64) -> *mut *mut tommy_node_struct {
    var __local_bsr: u32

    (__local_bsr = ((tommy_ilog2_u64((((__param_pos as u64) | (1 as u64)) as u64)) as u32)))

    return (((&raw const ((*__param_hashlin).bucket[__local_bsr][__param_pos]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct))

}

pub unsafe fn tommy_hashlin_bucket_ref(__param_hashlin: *mut tommy_hashlin_struct, __param_hash: u64) -> *mut *mut tommy_node_struct {
    var __local_pos: u64

    var __local_high_pos: u64

    (__local_pos = ((((__param_hash as u64) & ((*__param_hashlin).low_mask as u64)) as u64)))

    (__local_high_pos = ((((__param_hash as u64) & ((*__param_hashlin).bucket_mask as u64)) as u64)))

    if ((if __local_pos < (*__param_hashlin).split: 1 else: 0) != 0) {
        (__local_pos = __local_high_pos)

    }

    return ((tommy_hashlin_pos(__param_hashlin, __local_pos) as *mut *mut tommy_node_struct))

}

pub unsafe fn tommy_hashlin_bucket(__param_hashlin: *mut tommy_hashlin_struct, __param_hash: u64) -> *mut tommy_node_struct {
    return (*(tommy_hashlin_bucket_ref(__param_hashlin, __param_hash)))

}

pub unsafe fn tommy_hashlin_search(__param_hashlin: *mut tommy_hashlin_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> i32, __param_cmp_arg: *const c_void, __param_hash: u64) -> *mut c_void {
    var __local_i: *mut tommy_node_struct = tommy_hashlin_bucket(__param_hashlin, __param_hash)

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

pub unsafe fn tommy_hashlin_remove_existing(__param_hashlin: *mut tommy_hashlin_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    tommy_list_remove_existing(tommy_hashlin_bucket_ref(__param_hashlin, (*__param_node).index), __param_node)

    ((*__param_hashlin).count = ((*__param_hashlin).count -% 1))

    hashlin_shrink_step(__param_hashlin)

    return (*__param_node).data

}

pub unsafe fn tommy_hashlin_foreach(__param_hashlin: *mut tommy_hashlin_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) {
    var __local_bucket_max: u64

    var __local_pos: u64

    (__local_bucket_max = (((((*__param_hashlin).low_max as u64) +% ((*__param_hashlin).split as u64)) as u64)))

    (__local_pos = ((0 as u64)))

    while ((if __local_pos < __local_bucket_max: 1 else: 0) != 0) {
        var __local_node: *mut tommy_node_struct = (*(tommy_hashlin_pos(__param_hashlin, __local_pos)))

        while (__local_node != null) {
            var __local_data: *mut c_void = (*__local_node).data

            (__local_node = (*__local_node).next)

            __param_func(__local_data)

        }


        (__local_pos = (__local_pos +% 1))

    }


}

pub unsafe fn tommy_hashlin_foreach_arg(__param_hashlin: *mut tommy_hashlin_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) {
    var __local_bucket_max: u64

    var __local_pos: u64

    (__local_bucket_max = (((((*__param_hashlin).low_max as u64) +% ((*__param_hashlin).split as u64)) as u64)))

    (__local_pos = ((0 as u64)))

    while ((if __local_pos < __local_bucket_max: 1 else: 0) != 0) {
        var __local_node: *mut tommy_node_struct = (*(tommy_hashlin_pos(__param_hashlin, __local_pos)))

        while (__local_node != null) {
            var __local_data: *mut c_void = (*__local_node).data

            (__local_node = (*__local_node).next)

            __param_func(__param_arg, __local_data)

        }


        (__local_pos = (__local_pos +% 1))

    }


}

pub unsafe fn tommy_hashlin_count(__param_hashlin: *mut tommy_hashlin_struct) -> u64 {
    return (*__param_hashlin).count

}

pub unsafe fn tommy_hashlin_memory_usage(__param_hashlin: *mut tommy_hashlin_struct) -> u64 {
    return (((((*__param_hashlin).bucket_max as u64) *% (sizeof[usize]() as u64)) as u64) +% ((((*__param_hashlin).count as u64) *% (sizeof[tommy_node_struct]() as u64)) as u64))

}

unsafe fn tommy_hashlin_stable(__param_hashlin: *mut tommy_hashlin_struct) {
    ((*__param_hashlin).state = ((0 as u32)))

    ((*__param_hashlin).low_max = (*__param_hashlin).bucket_max)

    ((*__param_hashlin).low_mask = (*__param_hashlin).bucket_mask)

    ((*__param_hashlin).split = ((0 as u64)))

}

unsafe fn hashlin_grow_step(__param_hashlin: *mut tommy_hashlin_struct) {
    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_hashlin).state != 1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_hashlin).count > (((*__param_hashlin).bucket_max as u64) / (2 as u64)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        if ((if (*__param_hashlin).state == 0: 1 else: 0) != 0) {
            var __local_segment: *mut *mut tommy_node_struct

            ((*__param_hashlin).low_max = (*__param_hashlin).bucket_max)

            ((*__param_hashlin).low_mask = (*__param_hashlin).bucket_mask)

            (__local_segment = (((with_alloc((((((*__param_hashlin).low_max as u64) *% (8 as u64)) as u64) as i64)) as *mut c_void) as *mut *mut tommy_node_struct)))

            ((*__param_hashlin).bucket[(*__param_hashlin).bucket_bit] = (((&raw const (__local_segment[(0 - ((*__param_hashlin).low_max as i64))]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))

            ((*__param_hashlin).bucket_bit = ((*__param_hashlin).bucket_bit +% 1))

            ((*__param_hashlin).bucket_max = ((((1 as u64) << ((*__param_hashlin).bucket_bit as u32)) as u64)))

            ((*__param_hashlin).bucket_mask = (((((*__param_hashlin).bucket_max as u64) -% (1 as u64)) as u64)))

            ((*__param_hashlin).split = ((0 as u64)))

        }

        ((*__param_hashlin).state = ((1 as u32)))

    }


    if ((if (*__param_hashlin).state == 1: 1 else: 0) != 0) {
        var __local_split_target: u64 = ((((2 as u64) *% ((*__param_hashlin).count as u64)) as u64))

        while ((if (((*__param_hashlin).split as u64) +% ((*__param_hashlin).low_max as u64)) < __local_split_target: 1 else: 0) != 0) {
            var __local_split: List[*mut *mut tommy_node_struct] = [null; 2]

            var __local_j: *mut tommy_node_struct

            var __local_mask: u64

            (__local_split[0] = tommy_hashlin_pos(__param_hashlin, (*__param_hashlin).split))

            (__local_split[1] = tommy_hashlin_pos(__param_hashlin, ((((*__param_hashlin).split as u64) +% ((*__param_hashlin).low_max as u64)) as u64)))

            (__local_j = (*(__local_split[0] as *mut *mut tommy_node_struct)))

            ((*(__local_split[0] as *mut *mut tommy_node_struct)) = null)

            ((*(__local_split[1] as *mut *mut tommy_node_struct)) = null)

            (__local_mask = (*__param_hashlin).low_max)

            while (__local_j != null) {
                var __local_j_next: *mut tommy_node_struct = (*__local_j).next

                var __local_pos: u64 = (((if (((*__local_j).index as u64) & (__local_mask as u64)) != 0: 1 else: 0) as u64))

                if ((*(__local_split[__local_pos] as *mut *mut tommy_node_struct)) != null) {
                    tommy_list_insert_tail_not_empty((*(__local_split[__local_pos] as *mut *mut tommy_node_struct)), __local_j)
                } else {
                    tommy_list_insert_first(__local_split[__local_pos], __local_j)
                }

                (__local_j = __local_j_next)

            }

            ((*__param_hashlin).split = ((*__param_hashlin).split +% 1))

            if ((if (*__param_hashlin).split == (*__param_hashlin).low_max: 1 else: 0) != 0) {
                tommy_hashlin_stable(__param_hashlin)

                break

            }

        }

    }

}

unsafe fn hashlin_shrink_step(__param_hashlin: *mut tommy_hashlin_struct) {
    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_hashlin).state != 2: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_hashlin).count < (((*__param_hashlin).bucket_max as u64) / (8 as u64)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        if ((if (*__param_hashlin).bucket_bit > 6: 1 else: 0) != 0) {
            if ((if (*__param_hashlin).state == 0: 1 else: 0) != 0) {
                ((*__param_hashlin).low_max = (((((*__param_hashlin).bucket_max as u64) / (2 as u64)) as u64)))

                ((*__param_hashlin).low_mask = (((((*__param_hashlin).bucket_mask as u64) / (2 as u64)) as u64)))

                ((*__param_hashlin).split = (*__param_hashlin).low_max)

            }

            ((*__param_hashlin).state = ((2 as u32)))

        }

    }


    if ((if (*__param_hashlin).state == 2: 1 else: 0) != 0) {
        var __local_split_target: u64 = ((((8 as u64) *% ((*__param_hashlin).count as u64)) as u64))

        while ((if (((*__param_hashlin).split as u64) +% ((*__param_hashlin).low_max as u64)) > __local_split_target: 1 else: 0) != 0) {
            var __local_split: List[*mut *mut tommy_node_struct] = [null; 2]

            ((*__param_hashlin).split = ((*__param_hashlin).split -% 1))

            (__local_split[0] = tommy_hashlin_pos(__param_hashlin, (*__param_hashlin).split))

            (__local_split[1] = tommy_hashlin_pos(__param_hashlin, ((((*__param_hashlin).split as u64) +% ((*__param_hashlin).low_max as u64)) as u64)))

            tommy_list_concat(__local_split[0], __local_split[1])

            if ((if (*__param_hashlin).split == 0: 1 else: 0) != 0) {
                var __local_segment: *mut *mut tommy_node_struct

                ((*__param_hashlin).bucket_bit = ((*__param_hashlin).bucket_bit -% 1))

                ((*__param_hashlin).bucket_max = ((((1 as u64) << ((*__param_hashlin).bucket_bit as u32)) as u64)))

                ((*__param_hashlin).bucket_mask = (((((*__param_hashlin).bucket_max as u64) -% (1 as u64)) as u64)))

                (__local_segment = (*__param_hashlin).bucket[(*__param_hashlin).bucket_bit])

                with_free(((((&raw const (__local_segment[((1 as i64) << ((*__param_hashlin).bucket_bit as u32))]) as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct) as *mut c_void) as *mut u8))

                tommy_hashlin_stable(__param_hashlin)

                break

            }

        }

    }

}
