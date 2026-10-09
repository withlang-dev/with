// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.option

pub fn bloom_filter_new(__param_table_size: c_uint, __param_hash_func: Option[unsafe extern "C" fn(*mut c_void) -> c_uint], __param_num_functions: c_uint) -> *mut _BloomFilter writes allocation_limit {
    var __local_filter: *mut _BloomFilter

    if ((if __param_num_functions > ((salts.len() as c_ulong)): 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    (__local_filter = ((alloc_test_malloc((sizeof[_BloomFilter]() as c_ulong)) as *mut _BloomFilter)))

    if ((if __local_filter == null: 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    ((unsafe *__local_filter).table = ((alloc_test_calloc((((((__param_table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_ulong), (1 as c_ulong)) as *mut u8)))

    if ((if (unsafe *__local_filter).table == null: 1 else: 0) != 0) {
        unsafe { alloc_test_free((__local_filter as *mut c_void)) }

        return ((null as *mut _BloomFilter))

    }

    ((unsafe *__local_filter).hash_func = __param_hash_func)

    ((unsafe *__local_filter).num_functions = __param_num_functions)

    ((unsafe *__local_filter).table_size = __param_table_size)

    return __local_filter

}

pub unsafe fn bloom_filter_free(__param_bloomfilter: *mut _BloomFilter) {
    alloc_test_free(((*__param_bloomfilter).table as *mut c_void))

    alloc_test_free((__param_bloomfilter as *mut c_void))

}

pub unsafe fn bloom_filter_insert(__param_bloomfilter: *mut _BloomFilter, __param_value: *mut c_void) {
    var __local_hash: c_uint

    var __local_subhash: c_uint

    var __local_index: c_uint

    var __local_i: c_uint

    var __local_b: u8

    (__local_hash = (((*__param_bloomfilter).hash_func.unwrap()(__param_value) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (*__param_bloomfilter).num_functions: 1 else: 0) != 0) {
        (__local_subhash = ((((__local_hash as c_uint) ^ (salts[__local_i] as c_uint)) as c_uint)))

        (__local_index = ((((__local_subhash as c_uint) % ((*__param_bloomfilter).table_size as c_uint)) as c_uint)))

        (__local_b = ((((1 as c_int) << (((__local_index as c_uint) % (8 as c_uint)) as c_uint)) as u8)))

        (((*__param_bloomfilter).table[((__local_index as c_uint) / (8 as c_uint))]) = (((*__param_bloomfilter).table[((__local_index as c_uint) / (8 as c_uint))]) as u8) | (__local_b as u8))


        (__local_i = (__local_i +% 1))

    }


}

pub unsafe fn bloom_filter_query(__param_bloomfilter: *mut _BloomFilter, __param_value: *mut c_void) -> c_int {
    var __local_hash: c_uint

    var __local_subhash: c_uint

    var __local_index: c_uint

    var __local_i: c_uint

    var __local_b: u8

    var __local_bit: c_int

    (__local_hash = (((*__param_bloomfilter).hash_func.unwrap()(__param_value) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (*__param_bloomfilter).num_functions: 1 else: 0) != 0) {
        (__local_subhash = ((((__local_hash as c_uint) ^ (salts[__local_i] as c_uint)) as c_uint)))

        (__local_index = ((((__local_subhash as c_uint) % ((*__param_bloomfilter).table_size as c_uint)) as c_uint)))

        (__local_b = ((((*__param_bloomfilter).table[((__local_index as c_uint) / (8 as c_uint))]) as u8)))

        (__local_bit = ((((1 as c_int) << (((__local_index as c_uint) % (8 as c_uint)) as c_uint)) as c_int)))

        if ((if ((__local_b as c_int) & (__local_bit as c_int)) == 0: 1 else: 0) != 0) {
            return 0

        }


        (__local_i = (__local_i +% 1))

    }


    return 1

}

pub unsafe fn bloom_filter_read(__param_bloomfilter: *mut _BloomFilter, __param_array: *mut u8) -> Unit {
    var __local_array_size: c_uint

    (__local_array_size = (((((((*__param_bloomfilter).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    with_memcpy(((__param_array as *mut c_void) as *mut u8), (((*__param_bloomfilter).table as *const c_void) as *const u8), ((__local_array_size as c_ulong) as i64))

}

pub unsafe fn bloom_filter_load(__param_bloomfilter: *mut _BloomFilter, __param_array: *mut u8) -> Unit {
    var __local_array_size: c_uint

    (__local_array_size = (((((((*__param_bloomfilter).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    with_memcpy((((*__param_bloomfilter).table as *mut c_void) as *mut u8), ((__param_array as *const c_void) as *const u8), ((__local_array_size as c_ulong) as i64))

}

pub unsafe fn bloom_filter_union(__param_filter1: *mut _BloomFilter, __param_filter2: *mut _BloomFilter) -> *mut _BloomFilter writes allocation_limit {
    var __local_result: *mut _BloomFilter

    var __local_i: c_uint

    var __local_array_size: c_uint

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if (*__param_filter1).table_size != (*__param_filter2).table_size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*__param_filter1).num_functions != (*__param_filter2).num_functions: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__param_filter1).hash_func != (*__param_filter2).hash_func: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return ((null as *mut _BloomFilter))

    }


    (__local_result = bloom_filter_new((*__param_filter1).table_size, (*__param_filter1).hash_func, (*__param_filter1).num_functions))

    if ((if __local_result == null: 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    (__local_array_size = (((((((*__param_filter1).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_array_size: 1 else: 0) != 0) {
        (((*__local_result).table[__local_i]) = ((((((*__param_filter1).table[__local_i]) as c_int) | (((*__param_filter2).table[__local_i]) as c_int)) as u8)))


        (__local_i = (__local_i +% 1))

    }


    return __local_result

}

pub unsafe fn bloom_filter_intersection(__param_filter1: *mut _BloomFilter, __param_filter2: *mut _BloomFilter) -> *mut _BloomFilter writes allocation_limit {
    var __local_result: *mut _BloomFilter

    var __local_i: c_uint

    var __local_array_size: c_uint

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if (*__param_filter1).table_size != (*__param_filter2).table_size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*__param_filter1).num_functions != (*__param_filter2).num_functions: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (*__param_filter1).hash_func != (*__param_filter2).hash_func: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return ((null as *mut _BloomFilter))

    }


    (__local_result = bloom_filter_new((*__param_filter1).table_size, (*__param_filter1).hash_func, (*__param_filter1).num_functions))

    if ((if __local_result == null: 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    (__local_array_size = (((((((*__param_filter1).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_array_size: 1 else: 0) != 0) {
        (((*__local_result).table[__local_i]) = ((((((*__param_filter1).table[__local_i]) as c_int) & (((*__param_filter2).table[__local_i]) as c_int)) as u8)))


        (__local_i = (__local_i +% 1))

    }


    return __local_result

}

let salts: [c_uint; 64] = [424919842, 1485623063, 1690263564, 2797485885, 874119914, 363868695, 990259288, 1498873094, 414540367, 3820882758, 553635164, 2740845867, 532982207, 1472486748, 2825264202, 1327199442, 1517149715, 991484614, 94941119, 3151638498, 2723286392, 3885189193, 3577855093, 161831767, 2603899618, 4230817455, 946314479, 2176654861, 1699119534, 1262323629, 3590263035, 598945639, 2949112678, 3717553837, 3888335644, 4272742566, 3944149149, 1012377389, 746755269, 3130156586, 3445304596, 1949906632, 613007103, 3334827520, 1956967942, 2990844234, 1591723043, 4052752692, 615478929, 4140403493, 3928338246, 1993732838, 1580453362, 1147056983, 2287299538, 1892801146, 1413780328, 940581052, 470098111, 4158933314, 2726177368, 1720086469, 307338471, 1132102742]
