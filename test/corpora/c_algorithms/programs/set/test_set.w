// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.compare_int
use std.calg_testing.compare_pointer
use std.calg_testing.compare_string
use std.calg_testing.framework
use std.calg_testing.hash_int
use std.calg_testing.hash_pointer
use std.calg_testing.hash_string
use std.calg_testing.set
use std.libc

pub fn generate_set() -> *mut _Set {
    var __local_set: *mut _Set

    var __local_buf: [10]c_char

    var __local_i: c_uint

    var __local_value: *mut c_char

    (__local_set = set_new(string_hash, string_equal))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        (__local_value = ((unsafe { alloc_test_strdup((&__local_buf[0] as *mut c_char)) } as *mut c_char)))

        unsafe { set_insert(__local_set, (__local_value as *mut c_void)) }

        if ((((if not ((if unsafe { set_num_entries(__local_set) } == ((__local_i as c_uint) +% (1 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"generate_set".ptr, c"test-set.c".ptr, (56 as c_int), c"set_num_entries(set) == i + 1".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { set_register_free_function(__local_set, alloc_test_free) }

    return __local_set

}

pub fn test_set_new_free() -> Unit {
    var __local_set: *mut _Set

    var __local_i: c_int

    var __local_value: *mut c_int

    (__local_set = set_new(int_hash, int_equal))

    unsafe { set_register_free_function(__local_set, alloc_test_free) }

    if ((((if not ((if __local_set != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_new_free".ptr, c"test-set.c".ptr, (74 as c_int), c"set != NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (__local_value = ((alloc_test_malloc((sizeof[c_int]() as c_ulong)) as *mut c_int)))

        ((unsafe *__local_value) = __local_i)

        unsafe { set_insert(__local_set, (__local_value as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    unsafe { set_free(__local_set) }

    alloc_test_set_limit((0 as c_int))

    (__local_set = set_new(int_hash, int_equal))

    if ((((if not ((if __local_set == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_new_free".ptr, c"test-set.c".ptr, (91 as c_int), c"set == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_set = set_new(int_hash, int_equal))

    if ((((if not ((if __local_set == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_new_free".ptr, c"test-set.c".ptr, (95 as c_int), c"set == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_new_free".ptr, c"test-set.c".ptr, (96 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

}

pub fn test_set_insert() -> Unit {
    var __local_set: *mut _Set

    var __local_numbers1: [6]c_int = [(1 as c_int), (2 as c_int), (3 as c_int), (4 as c_int), (5 as c_int), (6 as c_int)]

    var __local_numbers2: [6]c_int = [(5 as c_int), (6 as c_int), (7 as c_int), (8 as c_int), (9 as c_int), (10 as c_int)]

    var __local_i: c_int

    (__local_set = set_new(int_hash, int_equal))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        unsafe { set_insert(__local_set, (((&raw const __local_numbers1[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < 6: 1 else: 0) != 0) {
        unsafe { set_insert(__local_set, (((&raw const __local_numbers2[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if unsafe { set_num_entries(__local_set) } == 10: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_insert".ptr, c"test-set.c".ptr, (117 as c_int), c"set_num_entries(set) == 10".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set) }

}

pub fn test_set_query() -> Unit {
    var __local_set: *mut _Set

    var __local_buf: [10]c_char

    var __local_i: c_int

    (__local_set = generate_set())

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if ((((if not ((if unsafe { set_query(__local_set, (&__local_buf[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_query".ptr, c"test-set.c".ptr, (133 as c_int), c"set_query(set, buf) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if unsafe { set_query(__local_set, ("-1" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_query".ptr, c"test-set.c".ptr, (137 as c_int), c"set_query(set, \"-1\") == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { set_query(__local_set, ("100001" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_query".ptr, c"test-set.c".ptr, (138 as c_int), c"set_query(set, \"100001\") == 0".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set) }

}

pub fn test_set_remove() -> Unit {
    var __local_set: *mut _Set

    var __local_buf: [10]c_char

    var __local_i: c_int

    var __local_num_entries: c_uint

    (__local_set = generate_set())

    (__local_num_entries = ((unsafe { set_num_entries(__local_set) } as c_uint)))

    if ((((if not ((if __local_num_entries == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (153 as c_int), c"num_entries == 10000".ptr)
    } else {
        0
    }

    (__local_i = ((4000 as c_int)))

    while ((if __local_i < 6000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if ((((if not ((if unsafe { set_query(__local_set, (&__local_buf[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (161 as c_int), c"set_query(set, buf) != 0".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { set_remove(__local_set, (&__local_buf[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (164 as c_int), c"set_remove(set, buf) != 0".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { set_num_entries(__local_set) } == ((__local_num_entries as c_uint) -% (1 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (167 as c_int), c"set_num_entries(set) == num_entries - 1".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { set_query(__local_set, (&__local_buf[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (170 as c_int), c"set_query(set, buf) == 0".ptr)
        } else {
            0
        }

        (__local_num_entries = (__local_num_entries -% 1))


        (__local_i = __local_i + 1)

    }


    (__local_i = ((-1000 as c_int)))

    while ((if __local_i < -500: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if ((((if not ((if unsafe { set_remove(__local_set, (&__local_buf[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (179 as c_int), c"set_remove(set, buf) == 0".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { set_num_entries(__local_set) } == __local_num_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (180 as c_int), c"set_num_entries(set) == num_entries".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((50000 as c_int)))

    while ((if __local_i < 51000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if ((((if not ((if unsafe { set_remove(__local_set, (&__local_buf[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (186 as c_int), c"set_remove(set, buf) == 0".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { set_num_entries(__local_set) } == __local_num_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_remove".ptr, c"test-set.c".ptr, (187 as c_int), c"set_num_entries(set) == num_entries".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { set_free(__local_set) }

}

pub fn test_set_union() -> Unit {
    var __local_numbers1: [7]c_int = [(1 as c_int), (2 as c_int), (3 as c_int), (4 as c_int), (5 as c_int), (6 as c_int), (7 as c_int)]

    var __local_numbers2: [7]c_int = [(5 as c_int), (6 as c_int), (7 as c_int), (8 as c_int), (9 as c_int), (10 as c_int), (11 as c_int)]

    var __local_result: [11]c_int = [(1 as c_int), (2 as c_int), (3 as c_int), (4 as c_int), (5 as c_int), (6 as c_int), (7 as c_int), (8 as c_int), (9 as c_int), (10 as c_int), (11 as c_int)]

    var __local_i: c_int

    var __local_set1: *mut _Set

    var __local_set2: *mut _Set

    var __local_result_set: *mut _Set

    var __local_allocated: c_ulong

    (__local_set1 = set_new(int_hash, int_equal))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 7: 1 else: 0) != 0) {
        unsafe { set_insert(__local_set1, (((&raw const __local_numbers1[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_set2 = set_new(int_hash, int_equal))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 7: 1 else: 0) != 0) {
        unsafe { set_insert(__local_set2, (((&raw const __local_numbers2[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_result_set = unsafe { set_union(__local_set1, __local_set2) })

    if ((((if not ((if unsafe { set_num_entries(__local_result_set) } == 11: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_union".ptr, c"test-set.c".ptr, (221 as c_int), c"set_num_entries(result_set) == 11".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 11: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { set_query(__local_result_set, (((&raw const __local_result[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_union".ptr, c"test-set.c".ptr, (224 as c_int), c"set_query(result_set, &result[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { set_free(__local_result_set) }

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { set_union(__local_set1, __local_set2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_union".ptr, c"test-set.c".ptr, (231 as c_int), c"set_union(set1, set2) == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit(((2 + 2) as c_int))

    (__local_allocated = ((alloc_test_get_allocated() as c_ulong)))

    if ((((if not ((if unsafe { set_union(__local_set1, __local_set2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_union".ptr, c"test-set.c".ptr, (236 as c_int), c"set_union(set1, set2) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == __local_allocated: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_union".ptr, c"test-set.c".ptr, (237 as c_int), c"alloc_test_get_allocated() == allocated".ptr)
    } else {
        0
    }

    alloc_test_set_limit((((2 + 7) + 2) as c_int))

    (__local_allocated = ((alloc_test_get_allocated() as c_ulong)))

    if ((((if not ((if unsafe { set_union(__local_set1, __local_set2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_union".ptr, c"test-set.c".ptr, (243 as c_int), c"set_union(set1, set2) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == __local_allocated: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_union".ptr, c"test-set.c".ptr, (244 as c_int), c"alloc_test_get_allocated() == allocated".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set1) }

    unsafe { set_free(__local_set2) }

}

pub fn test_set_intersection() -> Unit {
    var __local_numbers1: [7]c_int = [(1 as c_int), (2 as c_int), (3 as c_int), (4 as c_int), (5 as c_int), (6 as c_int), (7 as c_int)]

    var __local_numbers2: [7]c_int = [(5 as c_int), (6 as c_int), (7 as c_int), (8 as c_int), (9 as c_int), (10 as c_int), (11 as c_int)]

    var __local_result: [3]c_int = [(5 as c_int), (6 as c_int), (7 as c_int)]

    var __local_i: c_int

    var __local_set1: *mut _Set

    var __local_set2: *mut _Set

    var __local_result_set: *mut _Set

    var __local_allocated: c_ulong

    (__local_set1 = set_new(int_hash, int_equal))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 7: 1 else: 0) != 0) {
        unsafe { set_insert(__local_set1, (((&raw const __local_numbers1[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_set2 = set_new(int_hash, int_equal))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 7: 1 else: 0) != 0) {
        unsafe { set_insert(__local_set2, (((&raw const __local_numbers2[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_result_set = unsafe { set_intersection(__local_set1, __local_set2) })

    if ((((if not ((if unsafe { set_num_entries(__local_result_set) } == 3: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_intersection".ptr, c"test-set.c".ptr, (278 as c_int), c"set_num_entries(result_set) == 3".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 3: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { set_query(__local_result_set, (((&raw const __local_result[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_intersection".ptr, c"test-set.c".ptr, (281 as c_int), c"set_query(result_set, &result[i]) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { set_intersection(__local_set1, __local_set2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_intersection".ptr, c"test-set.c".ptr, (286 as c_int), c"set_intersection(set1, set2) == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit(((2 + 2) as c_int))

    (__local_allocated = ((alloc_test_get_allocated() as c_ulong)))

    if ((((if not ((if unsafe { set_intersection(__local_set1, __local_set2) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_intersection".ptr, c"test-set.c".ptr, (291 as c_int), c"set_intersection(set1, set2) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == __local_allocated: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_intersection".ptr, c"test-set.c".ptr, (292 as c_int), c"alloc_test_get_allocated() == allocated".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set1) }

    unsafe { set_free(__local_set2) }

    unsafe { set_free(__local_result_set) }

}

pub fn test_set_to_array() -> Unit {
    var __local_set: *mut _Set

    var __local_values: [100]c_int

    var __local_array: *mut *mut c_int

    var __local_i: c_int

    (__local_set = set_new(pointer_hash, pointer_equal))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 100: 1 else: 0) != 0) {
        (__local_values[__local_i] = ((1 as c_int)))

        unsafe { set_insert(__local_set, (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_array = ((unsafe { set_to_array(__local_set) } as *mut *mut c_int)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 100: 1 else: 0) != 0) {
        if ((((if not ((if (unsafe *((unsafe __local_array[__local_i]) as *mut c_int)) == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_to_array".ptr, c"test-set.c".ptr, (319 as c_int), c"*array[i] == 1".ptr)
        } else {
            0
        }

        ((unsafe *((unsafe __local_array[__local_i]) as *mut c_int)) = ((0 as c_int)))


        (__local_i = __local_i + 1)

    }


    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { set_to_array(__local_set) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_to_array".ptr, c"test-set.c".ptr, (325 as c_int), c"set_to_array(set) == NULL".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_array as *mut c_void)) }

    unsafe { set_free(__local_set) }

}

pub fn test_set_iterating() -> Unit {
    var __local_set: *mut _Set

    var __local_iterator: _SetIterator

    var __local_count: c_int

    (__local_set = generate_set())

    (__local_count = ((0 as c_int)))

    unsafe { set_iterate(__local_set, (&raw mut __local_iterator as *mut _SetIterator)) }

    while (unsafe { set_iter_has_more((&raw mut __local_iterator as *mut _SetIterator)) } != 0) {
        unsafe { set_iter_next((&raw mut __local_iterator as *mut _SetIterator)) }

        (__local_count = __local_count + 1)

    }

    if ((((if not ((if unsafe { set_iter_next((&raw mut __local_iterator as *mut _SetIterator)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_iterating".ptr, c"test-set.c".ptr, (351 as c_int), c"set_iter_next(&iterator) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if __local_count == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_iterating".ptr, c"test-set.c".ptr, (354 as c_int), c"count == 10000".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set) }

    (__local_set = set_new(int_hash, int_equal))

    unsafe { set_iterate(__local_set, (&raw mut __local_iterator as *mut _SetIterator)) }

    if ((((if not ((if unsafe { set_iter_has_more((&raw mut __local_iterator as *mut _SetIterator)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_iterating".ptr, c"test-set.c".ptr, (363 as c_int), c"set_iter_has_more(&iterator) == 0".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set) }

}

pub fn test_set_iterating_remove() -> Unit {
    var __local_set: *mut _Set

    var __local_iterator: _SetIterator

    var __local_count: c_int

    var __local_removed: c_uint

    var __local_value: *mut c_char

    (__local_set = generate_set())

    (__local_count = ((0 as c_int)))

    (__local_removed = ((0 as c_uint)))

    unsafe { set_iterate(__local_set, (&raw mut __local_iterator as *mut _SetIterator)) }

    while (unsafe { set_iter_has_more((&raw mut __local_iterator as *mut _SetIterator)) } != 0) {
        (__local_value = ((unsafe { set_iter_next((&raw mut __local_iterator as *mut _SetIterator)) } as *mut c_char)))

        if ((if (atoi((__local_value as *const i8)) % 100) == 0: 1 else: 0) != 0) {
            unsafe { set_remove(__local_set, (__local_value as *mut c_void)) }

            (__local_removed = (__local_removed +% 1))

        }

        (__local_count = __local_count + 1)

    }

    if ((((if not ((if __local_count == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_iterating_remove".ptr, c"test-set.c".ptr, (403 as c_int), c"count == 10000".ptr)
    } else {
        0
    }

    if ((((if not ((if __local_removed == 100: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_iterating_remove".ptr, c"test-set.c".ptr, (404 as c_int), c"removed == 100".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { set_num_entries(__local_set) } == ((10000 as c_uint) -% (__local_removed as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_iterating_remove".ptr, c"test-set.c".ptr, (405 as c_int), c"set_num_entries(set) == 10000 - removed".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set) }

}

pub fn new_value(__param_value: c_int) -> *mut c_int {
    var __local_result: *mut c_int

    (__local_result = ((alloc_test_malloc((sizeof[c_int]() as c_ulong)) as *mut c_int)))

    ((unsafe *__local_result) = __param_value)

    (allocated_values = allocated_values + 1)

    return __local_result

}

pub unsafe fn free_value(__param_value: *mut c_void) -> Unit {
    alloc_test_free(__param_value)

    (allocated_values = allocated_values - 1)

}

pub fn test_set_free_function() -> Unit {
    var __local_set: *mut _Set

    var __local_i: c_int

    var __local_value: *mut c_int

    (__local_set = set_new(int_hash, int_equal))

    unsafe { set_register_free_function(__local_set, free_value) }

    (allocated_values = ((0 as c_int)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 1000: 1 else: 0) != 0) {
        (__local_value = new_value(__local_i))

        unsafe { set_insert(__local_set, (__local_value as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if allocated_values == 1000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_free_function".ptr, c"test-set.c".ptr, (448 as c_int), c"allocated_values == 1000".ptr)
    } else {
        0
    }

    (__local_i = ((500 as c_int)))

    unsafe { set_remove(__local_set, ((&raw mut __local_i as *mut c_int) as *mut c_void)) }

    if ((((if not ((if allocated_values == 999: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_free_function".ptr, c"test-set.c".ptr, (454 as c_int), c"allocated_values == 999".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set) }

    if ((((if not ((if allocated_values == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_free_function".ptr, c"test-set.c".ptr, (459 as c_int), c"allocated_values == 0".ptr)
    } else {
        0
    }

}

pub fn test_set_out_of_memory() -> Unit {
    var __local_set: *mut _Set

    var __local_values: [66]c_int

    var __local_i: c_uint

    (__local_set = set_new(int_hash, int_equal))

    alloc_test_set_limit((0 as c_int))

    (__local_values[0] = ((0 as c_int)))

    if ((((if not ((if unsafe { set_insert(__local_set, (((&raw const __local_values[0] as *const c_int) as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_out_of_memory".ptr, c"test-set.c".ptr, (474 as c_int), c"set_insert(set, &values[0]) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { set_num_entries(__local_set) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_out_of_memory".ptr, c"test-set.c".ptr, (475 as c_int), c"set_num_entries(set) == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((-1 as c_int))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 65: 1 else: 0) != 0) {
        (__local_values[__local_i] = ((__local_i as c_int)))

        if ((((if not ((if unsafe { set_insert(__local_set, (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_out_of_memory".ptr, c"test-set.c".ptr, (486 as c_int), c"set_insert(set, &values[i]) != 0".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { set_num_entries(__local_set) } == ((__local_i as c_uint) +% (1 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_set_out_of_memory".ptr, c"test-set.c".ptr, (487 as c_int), c"set_num_entries(set) == i + 1".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    if ((((if not ((if unsafe { set_num_entries(__local_set) } == 65: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_out_of_memory".ptr, c"test-set.c".ptr, (490 as c_int), c"set_num_entries(set) == 65".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    (__local_values[65] = ((65 as c_int)))

    if ((((if not ((if unsafe { set_insert(__local_set, (((&raw const __local_values[65] as *const c_int) as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_out_of_memory".ptr, c"test-set.c".ptr, (497 as c_int), c"set_insert(set, &values[65]) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { set_num_entries(__local_set) } == 65: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_set_out_of_memory".ptr, c"test-set.c".ptr, (498 as c_int), c"set_num_entries(set) == 65".ptr)
    } else {
        0
    }

    unsafe { set_free(__local_set) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [12]extern "C" fn() -> Unit = [test_set_new_free, test_set_insert, test_set_query, test_set_remove, test_set_intersection, test_set_union, test_set_iterating, test_set_iterating_remove, test_set_to_array, test_set_free_function, test_set_out_of_memory, null]
