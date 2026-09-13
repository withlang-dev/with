// Migrated from C
use std.c_algorithms.defs

pub fn bloom_filter_new(__param_table_size: c_uint, __param_hash_func: unsafe extern "C" fn(*mut c_void) -> c_uint, __param_num_functions: c_uint) -> *mut _BloomFilter {
    var __local_filter: *mut _BloomFilter

    if ((if __param_num_functions > (((64 * sizeof[c_uint]()) as c_ulong) / (sizeof[c_uint]() as c_ulong)): 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    (__local_filter = (((unsafe { with_alloc(((sizeof[_BloomFilter]() as c_ulong) as i64)) } as *mut c_void) as *mut _BloomFilter)))

    if ((if __local_filter == null: 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    ((unsafe *__local_filter).table = (((unsafe { with_alloc_zeroed(((((((__param_table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_ulong) as i64), ((1 as c_ulong) as i64)) } as *mut c_void) as *mut u8)))

    if ((if (unsafe *__local_filter).table == null: 1 else: 0) != 0) {
        unsafe { with_free(((__local_filter as *mut c_void) as *mut u8)) }

        return ((null as *mut _BloomFilter))

    }

    ((unsafe *__local_filter).hash_func = __param_hash_func)

    ((unsafe *__local_filter).num_functions = __param_num_functions)

    ((unsafe *__local_filter).table_size = __param_table_size)

    return __local_filter

}

pub unsafe fn bloom_filter_free(__param_bloomfilter: *mut _BloomFilter) -> Unit {
    with_free((((unsafe *__param_bloomfilter).table as *mut c_void) as *mut u8))

    with_free(((__param_bloomfilter as *mut c_void) as *mut u8))

}

pub unsafe fn bloom_filter_insert(__param_bloomfilter: *mut _BloomFilter, __param_value: *mut c_void) -> Unit {
    var __local_hash: c_uint

    var __local_subhash: c_uint

    var __local_index: c_uint

    var __local_i: c_uint

    var __local_b: u8

    (__local_hash = (((unsafe *__param_bloomfilter).hash_func(__param_value) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (unsafe *__param_bloomfilter).num_functions: 1 else: 0) != 0) {
        (__local_subhash = ((((__local_hash as c_uint) ^ (salts[__local_i] as c_uint)) as c_uint)))

        (__local_index = ((((__local_subhash as c_uint) % ((unsafe *__param_bloomfilter).table_size as c_uint)) as c_uint)))

        (__local_b = ((((1 as c_int) << (((__local_index as c_uint) % (8 as c_uint)) as c_uint)) as u8)))

        ((unsafe (unsafe *__param_bloomfilter).table[((__local_index as c_uint) / (8 as c_uint))]) = ((unsafe (unsafe *__param_bloomfilter).table[((__local_index as c_uint) / (8 as c_uint))]) as u8) | (__local_b as u8))


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

    (__local_hash = (((unsafe *__param_bloomfilter).hash_func(__param_value) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (unsafe *__param_bloomfilter).num_functions: 1 else: 0) != 0) {
        (__local_subhash = ((((__local_hash as c_uint) ^ (salts[__local_i] as c_uint)) as c_uint)))

        (__local_index = ((((__local_subhash as c_uint) % ((unsafe *__param_bloomfilter).table_size as c_uint)) as c_uint)))

        (__local_b = (((unsafe (unsafe *__param_bloomfilter).table[((__local_index as c_uint) / (8 as c_uint))]) as u8)))

        (__local_bit = ((((1 as c_int) << (((__local_index as c_uint) % (8 as c_uint)) as c_uint)) as c_int)))

        if ((if (((__local_b as c_int) as c_int) & (__local_bit as c_int)) == 0: 1 else: 0) != 0) {
            return 0

        }


        (__local_i = (__local_i +% 1))

    }


    return 1

}

pub unsafe fn bloom_filter_read(__param_bloomfilter: *mut _BloomFilter, __param_array: *mut u8) -> Unit {
    var __local_array_size: c_uint

    (__local_array_size = (((((((unsafe *__param_bloomfilter).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    with_memcpy(((__param_array as *mut c_void) as *mut u8), (((unsafe *__param_bloomfilter).table as *const c_void) as *const u8), ((__local_array_size as c_ulong) as i64))

}

pub unsafe fn bloom_filter_load(__param_bloomfilter: *mut _BloomFilter, __param_array: *mut u8) -> Unit {
    var __local_array_size: c_uint

    (__local_array_size = (((((((unsafe *__param_bloomfilter).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    with_memcpy((((unsafe *__param_bloomfilter).table as *mut c_void) as *mut u8), ((__param_array as *const c_void) as *const u8), ((__local_array_size as c_ulong) as i64))

}

pub unsafe fn bloom_filter_union(__param_filter1: *mut _BloomFilter, __param_filter2: *mut _BloomFilter) -> *mut _BloomFilter {
    var __local_result: *mut _BloomFilter

    var __local_i: c_uint

    var __local_array_size: c_uint

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if (unsafe *__param_filter1).table_size != (unsafe *__param_filter2).table_size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_filter1).num_functions != (unsafe *__param_filter2).num_functions: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *__param_filter1).hash_func != (unsafe *__param_filter2).hash_func: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return ((null as *mut _BloomFilter))

    }


    (__local_result = bloom_filter_new((unsafe *__param_filter1).table_size, (unsafe *__param_filter1).hash_func, (unsafe *__param_filter1).num_functions))

    if ((if __local_result == null: 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    (__local_array_size = (((((((unsafe *__param_filter1).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_array_size: 1 else: 0) != 0) {
        ((unsafe (unsafe *__local_result).table[__local_i]) = ((((((unsafe (unsafe *__param_filter1).table[__local_i]) as c_int) as c_int) | (((unsafe (unsafe *__param_filter2).table[__local_i]) as c_int) as c_int)) as u8)))


        (__local_i = (__local_i +% 1))

    }


    return __local_result

}

pub unsafe fn bloom_filter_intersection(__param_filter1: *mut _BloomFilter, __param_filter2: *mut _BloomFilter) -> *mut _BloomFilter {
    var __local_result: *mut _BloomFilter

    var __local_i: c_uint

    var __local_array_size: c_uint

    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if (unsafe *__param_filter1).table_size != (unsafe *__param_filter2).table_size: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_filter1).num_functions != (unsafe *__param_filter2).num_functions: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *__param_filter1).hash_func != (unsafe *__param_filter2).hash_func: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return ((null as *mut _BloomFilter))

    }


    (__local_result = bloom_filter_new((unsafe *__param_filter1).table_size, (unsafe *__param_filter1).hash_func, (unsafe *__param_filter1).num_functions))

    if ((if __local_result == null: 1 else: 0) != 0) {
        return ((null as *mut _BloomFilter))

    }

    (__local_array_size = (((((((unsafe *__param_filter1).table_size as c_uint) +% (7 as c_uint)) as c_uint) / (8 as c_uint)) as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_array_size: 1 else: 0) != 0) {
        ((unsafe (unsafe *__local_result).table[__local_i]) = ((((((unsafe (unsafe *__param_filter1).table[__local_i]) as c_int) as c_int) & (((unsafe (unsafe *__param_filter2).table[__local_i]) as c_int) as c_int)) as u8)))


        (__local_i = (__local_i +% 1))

    }


    return __local_result

}

let salts: [64]c_uint = [(424919842 as c_uint), (1485623063 as c_uint), (1690263564 as c_uint), (2797485885 as c_uint), (874119914 as c_uint), (363868695 as c_uint), (990259288 as c_uint), (1498873094 as c_uint), (414540367 as c_uint), (3820882758 as c_uint), (553635164 as c_uint), (2740845867 as c_uint), (532982207 as c_uint), (1472486748 as c_uint), (2825264202 as c_uint), (1327199442 as c_uint), (1517149715 as c_uint), (991484614 as c_uint), (94941119 as c_uint), (3151638498 as c_uint), (2723286392 as c_uint), (3885189193 as c_uint), (3577855093 as c_uint), (161831767 as c_uint), (2603899618 as c_uint), (4230817455 as c_uint), (946314479 as c_uint), (2176654861 as c_uint), (1699119534 as c_uint), (1262323629 as c_uint), (3590263035 as c_uint), (598945639 as c_uint), (2949112678 as c_uint), (3717553837 as c_uint), (3888335644 as c_uint), (4272742566 as c_uint), (3944149149 as c_uint), (1012377389 as c_uint), (746755269 as c_uint), (3130156586 as c_uint), (3445304596 as c_uint), (1949906632 as c_uint), (613007103 as c_uint), (3334827520 as c_uint), (1956967942 as c_uint), (2990844234 as c_uint), (1591723043 as c_uint), (4052752692 as c_uint), (615478929 as c_uint), (4140403493 as c_uint), (3928338246 as c_uint), (1993732838 as c_uint), (1580453362 as c_uint), (1147056983 as c_uint), (2287299538 as c_uint), (1892801146 as c_uint), (1413780328 as c_uint), (940581052 as c_uint), (470098111 as c_uint), (4158933314 as c_uint), (2726177368 as c_uint), (1720086469 as c_uint), (307338471 as c_uint), (1132102742 as c_uint)]
