// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.compare_int
use std.engines.c_algorithms_testing.compare_string
use std.engines.c_algorithms_testing.framework
use std.engines.c_algorithms_testing.hash_int
use std.engines.c_algorithms_testing.hash_string
use std.engines.c_algorithms_testing.hash_table
use std.libc
use std.option
use std.collections

pub fn generate_hash_table() -> *mut _HashTable writes allocation_limit {
    var __local_hash_table: *mut _HashTable

    var __local_buf: List[c_char] = [0; 10]

    var __local_value: *mut c_char

    var __local_i: i32

    (__local_hash_table = hash_table_new(Some(string_hash), Some(string_equal)))

    (__local_i = ((0 as i32)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        (__local_value = unsafe { alloc_test_strdup((&__local_buf[0] as *mut c_char)) })

        unsafe { hash_table_insert(__local_hash_table, (__local_value as *mut c_void), (__local_value as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    unsafe { hash_table_register_free_functions(__local_hash_table, null, Some(alloc_test_free)) }

    return __local_hash_table

}

pub fn test_hash_table_new_free() -> Unit writes allocation_limit, value1, value2, value3, value4 {
    var __local_hash_table: *mut _HashTable

    (__local_hash_table = hash_table_new(Some(int_hash), Some(int_equal)))

    if (((if not ((if __local_hash_table != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (77 as i32), c"hash_table != NULL".ptr)
    } else {
        0
    }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value1 as *mut i32) as *mut c_void), ((&raw mut value1 as *mut i32) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value2 as *mut i32) as *mut c_void), ((&raw mut value2 as *mut i32) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value3 as *mut i32) as *mut c_void), ((&raw mut value3 as *mut i32) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value4 as *mut i32) as *mut c_void), ((&raw mut value4 as *mut i32) as *mut c_void)) }

    unsafe { hash_table_free(__local_hash_table) }

    alloc_test_set_limit((0 as i32))

    (__local_hash_table = hash_table_new(Some(int_hash), Some(int_equal)))

    if (((if not ((if __local_hash_table == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (91 as i32), c"hash_table == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (92 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as i32))

    (__local_hash_table = hash_table_new(Some(int_hash), Some(int_equal)))

    if (((if not ((if __local_hash_table == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (96 as i32), c"hash_table == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (97 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

}

pub fn test_hash_table_insert_lookup() writes allocation_limit {
    var __local_hash_table: *mut _HashTable

    var __local_buf: List[c_char] = [0; 10]

    var __local_value: *mut c_char

    var __local_i: i32

    (__local_hash_table = generate_hash_table())

    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (111 as i32), c"hash_table_num_entries(hash_table) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        (__local_value = ((unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } as *mut c_char)))

        if (((if not ((if strcmp((__local_value as *const c_char), (&__local_buf[0] as *mut c_char)) == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (118 as i32), c"strcmp(value, buf) == 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, -1)

    if (((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (123 as i32), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, 10000)

    if (((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (125 as i32), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, 12345)

    unsafe { hash_table_insert(__local_hash_table, (&__local_buf[0] as *mut c_char), (unsafe { alloc_test_strdup(c"hello world".ptr) } as *mut c_void)) }

    (__local_value = ((unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } as *mut c_char)))

    if (((if not ((if strcmp((__local_value as *const c_char), c"hello world".ptr) == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (131 as i32), c"strcmp(value, \"hello world\") == 0".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_table_remove() writes allocation_limit {
    var __local_hash_table: *mut _HashTable

    var __local_buf: List[c_char] = [0; 10]

    (__local_hash_table = generate_hash_table())

    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (143 as i32), c"hash_table_num_entries(hash_table) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, 5000)

    if (((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (145 as i32), c"hash_table_lookup(hash_table, buf) != NULL".ptr)
    } else {
        0
    }

    unsafe { hash_table_remove(__local_hash_table, (&__local_buf[0] as *mut c_char)) }

    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 9999: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (151 as i32), c"hash_table_num_entries(hash_table) == 9999".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (154 as i32), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, -1)

    unsafe { hash_table_remove(__local_hash_table, (&__local_buf[0] as *mut c_char)) }

    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 9999: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (160 as i32), c"hash_table_num_entries(hash_table) == 9999".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_table_iterating() writes allocation_limit {
    var __local_hash_table: *mut _HashTable

    var __local_iterator: _HashTableIterator

    var __local_pair: _HashTablePair

    var __local_count: i32

    (__local_hash_table = generate_hash_table())

    (__local_count = ((0 as i32)))

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    while (unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } != 0) {
        unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) }

        (__local_count = __local_count + 1)

    }

    if (((if not ((if __local_count == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_iterating".ptr, c"test-hash-table.c".ptr, (185 as i32), c"count == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    let __ci_copy_69: _HashTablePair = unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) }
    with_memcpy((&raw mut __local_pair as *mut u8), (&raw const __ci_copy_69 as *const u8), sizeof[_HashTablePair]())

    if (((if not ((if (unsafe *(&raw const __local_pair as *const _HashTablePair)).value == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_iterating".ptr, c"test-hash-table.c".ptr, (189 as i32), c"pair.value == HASH_TABLE_NULL".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

    (__local_hash_table = hash_table_new(Some(int_hash), Some(int_equal)))

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    if (((if not ((if unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_iterating".ptr, c"test-hash-table.c".ptr, (198 as i32), c"hash_table_iter_has_more(&iterator) == 0".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_table_iterating_remove() writes allocation_limit {
    var __local_hash_table: *mut _HashTable

    var __local_iterator: _HashTableIterator

    var __local_buf: List[c_char] = [0; 10]

    var __local_val: *mut c_char

    var __local_pair: _HashTablePair

    var __local_count: i32

    var __local_removed: u32

    var __local_i: i32

    (__local_hash_table = generate_hash_table())

    (__local_count = ((0 as i32)))

    (__local_removed = ((0 as u32)))

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    while (unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } != 0) {
        let __ci_copy_32: _HashTablePair = unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) }
        with_memcpy((&raw mut __local_pair as *mut u8), (&raw const __ci_copy_32 as *const u8), sizeof[_HashTablePair]())

        (__local_val = (((unsafe *(&raw const __local_pair as *const _HashTablePair)).value as *mut c_char)))

        if ((if (atoi((__local_val as *const c_char)) % 100) == 0: 1 else: 0) != 0) {
            unsafe { hash_table_remove(__local_hash_table, (__local_val as *mut c_void)) }

            (__local_removed = (__local_removed +% 1))

        }

        (__local_count = __local_count + 1)

    }

    if (((if not ((if __local_removed == 100: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (241 as i32), c"removed == 100".ptr)
    } else {
        0
    }

    if (((if not ((if __local_count == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (242 as i32), c"count == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == ((10000 as u32) -% (__local_removed as u32)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (244 as i32), c"hash_table_num_entries(hash_table) == NUM_TEST_VALUES - removed".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if ((if (__local_i % 100) == 0: 1 else: 0) != 0) {
            if (((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (251 as i32), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
            } else {
                0
            }

        } else {
            if (((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (253 as i32), c"hash_table_lookup(hash_table, buf) != NULL".ptr)
            } else {
                0
            }

        }


        (__local_i = __local_i + 1)

    }


    unsafe { hash_table_free(__local_hash_table) }

}

pub fn new_key(__param_value: i32) -> *mut i32 writes allocated_keys, allocation_limit {
    var __local_result: *mut i32

    (__local_result = ((alloc_test_malloc((sizeof[i32]() as u64)) as *mut i32)))

    ((unsafe *__local_result) = __param_value)

    (allocated_keys = allocated_keys + 1)

    return __local_result

}

pub unsafe fn free_key(__param_key: *mut c_void) writes allocated_keys {
    alloc_test_free(__param_key)

    (allocated_keys = allocated_keys - 1)

}

pub fn new_value(__param_value: i32) -> *mut i32 writes allocated_values, allocation_limit {
    var __local_result: *mut i32

    (__local_result = ((alloc_test_malloc((sizeof[i32]() as u64)) as *mut i32)))

    ((unsafe *__local_result) = __param_value)

    (allocated_values = allocated_values + 1)

    return __local_result

}

pub unsafe fn free_value(__param_value: *mut c_void) writes allocated_values {
    alloc_test_free(__param_value)

    (allocated_values = allocated_values - 1)

}

pub fn test_hash_table_free_functions() -> Unit writes allocated_keys, allocated_values, allocation_limit {
    var __local_hash_table: *mut _HashTable

    var __local_key: *mut i32

    var __local_value: *mut i32

    var __local_i: i32

    (__local_hash_table = hash_table_new(Some(int_hash), Some(int_equal)))

    unsafe { hash_table_register_free_functions(__local_hash_table, Some(free_key), Some(free_value)) }

    (allocated_values = ((0 as i32)))

    (__local_i = ((0 as i32)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (__local_key = new_key(__local_i))

        (__local_value = new_value((99 as i32)))

        unsafe { hash_table_insert(__local_hash_table, (__local_key as *mut c_void), (__local_value as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    if (((if not ((if allocated_keys == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (324 as i32), c"allocated_keys == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if (((if not ((if allocated_values == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (325 as i32), c"allocated_values == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    (__local_i = (((10000 / 2) as i32)))

    unsafe { hash_table_remove(__local_hash_table, ((&raw mut __local_i as *mut i32) as *mut c_void)) }

    if (((if not ((if allocated_keys == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (331 as i32), c"allocated_keys == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    if (((if not ((if allocated_values == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (332 as i32), c"allocated_values == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    (__local_key = new_key(((10000 / 3) as i32)))

    (__local_value = new_value((999 as i32)))

    if (((if not ((if allocated_keys == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (338 as i32), c"allocated_keys == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if (((if not ((if allocated_values == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (339 as i32), c"allocated_values == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    unsafe { hash_table_insert(__local_hash_table, (__local_key as *mut c_void), (__local_value as *mut c_void)) }

    if (((if not ((if allocated_keys == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (343 as i32), c"allocated_keys == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    if (((if not ((if allocated_values == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (344 as i32), c"allocated_values == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

    if (((if not ((if allocated_keys == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (349 as i32), c"allocated_keys == 0".ptr)
    } else {
        0
    }

    if (((if not ((if allocated_values == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (350 as i32), c"allocated_values == 0".ptr)
    } else {
        0
    }

}

pub fn test_hash_table_out_of_memory() writes allocation_limit {
    var __local_hash_table: *mut _HashTable

    var __local_values: List[i32] = [0; 66]

    var __local_i: u32

    (__local_hash_table = hash_table_new(Some(int_hash), Some(int_equal)))

    alloc_test_set_limit((0 as i32))

    (__local_values[0] = ((0 as i32)))

    if (((if not ((if unsafe { hash_table_insert(__local_hash_table, (((&raw const __local_values[0] as *const i32) as *mut i32) as *mut c_void), (((&raw const __local_values[0] as *const i32) as *mut i32) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (365 as i32), c"hash_table_insert(hash_table, &values[0], &values[0]) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (366 as i32), c"hash_table_num_entries(hash_table) == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((-1 as i32))

    (__local_i = ((0 as u32)))

    while ((if __local_i < 65: 1 else: 0) != 0) {
        (__local_values[__local_i] = ((__local_i as i32)))

        if (((if not ((if unsafe { hash_table_insert(__local_hash_table, (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void), (((&raw const __local_values[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (379 as i32), c"hash_table_insert(hash_table, &values[i], &values[i]) != 0".ptr)
        } else {
            0
        }

        if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == ((__local_i as u32) +% (1 as u32)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (380 as i32), c"hash_table_num_entries(hash_table) == i + 1".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 65: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (383 as i32), c"hash_table_num_entries(hash_table) == 65".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as i32))

    (__local_values[65] = ((65 as i32)))

    if (((if not ((if unsafe { hash_table_insert(__local_hash_table, (((&raw const __local_values[65] as *const i32) as *mut i32) as *mut c_void), (((&raw const __local_values[65] as *const i32) as *mut i32) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (390 as i32), c"hash_table_insert(hash_table, &values[65], &values[65]) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 65: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (391 as i32), c"hash_table_num_entries(hash_table) == 65".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_iterator_key_pair() writes allocation_limit, value1, value2 {
    var __local_hash_table: *mut _HashTable

    var __local_iterator: _HashTableIterator

    var __local_pair: _HashTablePair

    var __local_key: *mut i32

    var __local_val: *mut i32


    (__local_hash_table = hash_table_new(Some(int_hash), Some(int_equal)))

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value1 as *mut i32) as *mut c_void), ((&raw mut value1 as *mut i32) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value2 as *mut i32) as *mut c_void), ((&raw mut value2 as *mut i32) as *mut c_void)) }

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    while (unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } != 0) {
        let __ci_copy_55: _HashTablePair = unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) }
        with_memcpy((&raw mut __local_pair as *mut u8), (&raw const __ci_copy_55 as *const u8), sizeof[_HashTablePair]())

        (__local_key = (((unsafe *(&raw const __local_pair as *const _HashTablePair)).key as *mut i32)))

        (__local_val = (((unsafe *(&raw const __local_pair as *const _HashTablePair)).value as *mut i32)))

        if (((if not ((if (unsafe *__local_key) == (unsafe *__local_val): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_hash_iterator_key_pair".ptr, c"test-hash-table.c".ptr, (419 as i32), c"*key == *val".ptr)
        } else {
            0
        }

    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_hash_table_new_free), Some(test_hash_table_insert_lookup), Some(test_hash_table_remove), Some(test_hash_table_iterating), Some(test_hash_table_iterating_remove), Some(test_hash_table_free_functions), Some(test_hash_table_out_of_memory), Some(test_hash_iterator_key_pair), null]
