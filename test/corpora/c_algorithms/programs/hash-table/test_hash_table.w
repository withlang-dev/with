// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.compare_int
use std.calg_testing.compare_string
use std.calg_testing.framework
use std.calg_testing.hash_int
use std.calg_testing.hash_string
use std.calg_testing.hash_table
use std.libc

pub fn generate_hash_table() -> *mut _HashTable {
    var __local_hash_table: *mut _HashTable

    var __local_buf: [10]c_char

    var __local_value: *mut c_char

    var __local_i: c_int

    (__local_hash_table = hash_table_new(string_hash, string_equal))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        (__local_value = ((unsafe { alloc_test_strdup((&__local_buf[0] as *mut c_char)) } as *mut c_char)))

        unsafe { hash_table_insert(__local_hash_table, (__local_value as *mut c_void), (__local_value as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    unsafe { hash_table_register_free_functions(__local_hash_table, null, alloc_test_free) }

    return __local_hash_table

}

pub fn test_hash_table_new_free() -> Unit {
    var __local_hash_table: *mut _HashTable

    (__local_hash_table = hash_table_new(int_hash, int_equal))

    if ((((if not ((if __local_hash_table != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (77 as c_int), c"hash_table != NULL".ptr)
    } else {
        0
    }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value1 as *mut c_int) as *mut c_void), ((&raw mut value1 as *mut c_int) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value2 as *mut c_int) as *mut c_void), ((&raw mut value2 as *mut c_int) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value3 as *mut c_int) as *mut c_void), ((&raw mut value3 as *mut c_int) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value4 as *mut c_int) as *mut c_void), ((&raw mut value4 as *mut c_int) as *mut c_void)) }

    unsafe { hash_table_free(__local_hash_table) }

    alloc_test_set_limit((0 as c_int))

    (__local_hash_table = hash_table_new(int_hash, int_equal))

    if ((((if not ((if __local_hash_table == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (91 as c_int), c"hash_table == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (92 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_hash_table = hash_table_new(int_hash, int_equal))

    if ((((if not ((if __local_hash_table == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (96 as c_int), c"hash_table == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_new_free".ptr, c"test-hash-table.c".ptr, (97 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

}

pub fn test_hash_table_insert_lookup() -> Unit {
    var __local_hash_table: *mut _HashTable

    var __local_buf: [10]c_char

    var __local_value: *mut c_char

    var __local_i: c_int

    (__local_hash_table = generate_hash_table())

    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (111 as c_int), c"hash_table_num_entries(hash_table) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        (__local_value = ((unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } as *mut c_char)))

        if ((((if not ((if strcmp((__local_value as *const i8), (&__local_buf[0] as *mut c_char)) == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (118 as c_int), c"strcmp(value, buf) == 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, -1)

    if ((((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (123 as c_int), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, 10000)

    if ((((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (125 as c_int), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, 12345)

    unsafe { hash_table_insert(__local_hash_table, (&__local_buf[0] as *mut c_char), (unsafe { alloc_test_strdup(c"hello world".ptr) } as *mut c_void)) }

    (__local_value = ((unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } as *mut c_char)))

    if ((((if not ((if strcmp((__local_value as *const i8), c"hello world".ptr) == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_insert_lookup".ptr, c"test-hash-table.c".ptr, (131 as c_int), c"strcmp(value, \"hello world\") == 0".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_table_remove() -> Unit {
    var __local_hash_table: *mut _HashTable

    var __local_buf: [10]c_char

    (__local_hash_table = generate_hash_table())

    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (143 as c_int), c"hash_table_num_entries(hash_table) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, 5000)

    if ((((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (145 as c_int), c"hash_table_lookup(hash_table, buf) != NULL".ptr)
    } else {
        0
    }

    unsafe { hash_table_remove(__local_hash_table, (&__local_buf[0] as *mut c_char)) }

    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 9999: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (151 as c_int), c"hash_table_num_entries(hash_table) == 9999".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (154 as c_int), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
    } else {
        0
    }

    sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, -1)

    unsafe { hash_table_remove(__local_hash_table, (&__local_buf[0] as *mut c_char)) }

    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 9999: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_remove".ptr, c"test-hash-table.c".ptr, (160 as c_int), c"hash_table_num_entries(hash_table) == 9999".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_table_iterating() -> Unit {
    var __local_hash_table: *mut _HashTable

    var __local_iterator: _HashTableIterator

    var __local_pair: _HashTablePair

    var __local_count: c_int

    (__local_hash_table = generate_hash_table())

    (__local_count = ((0 as c_int)))

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    while (unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } != 0) {
        unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) }

        (__local_count = __local_count + 1)

    }

    if ((((if not ((if __local_count == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_iterating".ptr, c"test-hash-table.c".ptr, (185 as c_int), c"count == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    unsafe { with_memcpy((&raw mut __local_pair as *mut u8), (&raw const unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) } as *const u8), sizeof[_HashTablePair]()) }

    if ((((if not ((if (unsafe *(&raw const __local_pair as *const _HashTablePair)).value == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_iterating".ptr, c"test-hash-table.c".ptr, (189 as c_int), c"pair.value == HASH_TABLE_NULL".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

    (__local_hash_table = hash_table_new(int_hash, int_equal))

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    if ((((if not ((if unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_iterating".ptr, c"test-hash-table.c".ptr, (198 as c_int), c"hash_table_iter_has_more(&iterator) == 0".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_table_iterating_remove() -> Unit {
    var __local_hash_table: *mut _HashTable

    var __local_iterator: _HashTableIterator

    var __local_buf: [10]c_char

    var __local_val: *mut c_char

    var __local_pair: _HashTablePair

    var __local_count: c_int

    var __local_removed: c_uint

    var __local_i: c_int

    (__local_hash_table = generate_hash_table())

    (__local_count = ((0 as c_int)))

    (__local_removed = ((0 as c_uint)))

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    while (unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } != 0) {
        unsafe { with_memcpy((&raw mut __local_pair as *mut u8), (&raw const unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) } as *const u8), sizeof[_HashTablePair]()) }

        (__local_val = (((unsafe *(&raw const __local_pair as *const _HashTablePair)).value as *mut c_char)))

        if ((if (atoi((__local_val as *const i8)) % 100) == 0: 1 else: 0) != 0) {
            unsafe { hash_table_remove(__local_hash_table, (__local_val as *mut c_void)) }

            (__local_removed = (__local_removed +% 1))

        }

        (__local_count = __local_count + 1)

    }

    if ((((if not ((if __local_removed == 100: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (241 as c_int), c"removed == 100".ptr)
    } else {
        0
    }

    if ((((if not ((if __local_count == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (242 as c_int), c"count == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == ((10000 as c_uint) -% (__local_removed as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (244 as c_int), c"hash_table_num_entries(hash_table) == NUM_TEST_VALUES - removed".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if ((if (__local_i % 100) == 0: 1 else: 0) != 0) {
            if ((((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (251 as c_int), c"hash_table_lookup(hash_table, buf) == NULL".ptr)
            } else {
                0
            }

        } else {
            if ((((if not ((if unsafe { hash_table_lookup(__local_hash_table, (&__local_buf[0] as *mut c_char)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                __assert_rtn(c"test_hash_table_iterating_remove".ptr, c"test-hash-table.c".ptr, (253 as c_int), c"hash_table_lookup(hash_table, buf) != NULL".ptr)
            } else {
                0
            }

        }


        (__local_i = __local_i + 1)

    }


    unsafe { hash_table_free(__local_hash_table) }

}

pub fn new_key(__param_value: c_int) -> *mut c_int {
    var __local_result: *mut c_int

    (__local_result = ((alloc_test_malloc((sizeof[c_int]() as c_ulong)) as *mut c_int)))

    ((unsafe *__local_result) = __param_value)

    (allocated_keys = allocated_keys + 1)

    return __local_result

}

pub unsafe fn free_key(__param_key: *mut c_void) -> Unit {
    alloc_test_free(__param_key)

    (allocated_keys = allocated_keys - 1)

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

pub fn test_hash_table_free_functions() -> Unit {
    var __local_hash_table: *mut _HashTable

    var __local_key: *mut c_int

    var __local_value: *mut c_int

    var __local_i: c_int

    (__local_hash_table = hash_table_new(int_hash, int_equal))

    unsafe { hash_table_register_free_functions(__local_hash_table, free_key, free_value) }

    (allocated_values = ((0 as c_int)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (__local_key = new_key(__local_i))

        (__local_value = new_value((99 as c_int)))

        unsafe { hash_table_insert(__local_hash_table, (__local_key as *mut c_void), (__local_value as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if allocated_keys == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (324 as c_int), c"allocated_keys == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if ((((if not ((if allocated_values == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (325 as c_int), c"allocated_values == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    (__local_i = (((10000 / 2) as c_int)))

    unsafe { hash_table_remove(__local_hash_table, ((&raw mut __local_i as *mut c_int) as *mut c_void)) }

    if ((((if not ((if allocated_keys == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (331 as c_int), c"allocated_keys == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    if ((((if not ((if allocated_values == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (332 as c_int), c"allocated_values == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    (__local_key = new_key(((10000 / 3) as c_int)))

    (__local_value = new_value((999 as c_int)))

    if ((((if not ((if allocated_keys == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (338 as c_int), c"allocated_keys == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if ((((if not ((if allocated_values == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (339 as c_int), c"allocated_values == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    unsafe { hash_table_insert(__local_hash_table, (__local_key as *mut c_void), (__local_value as *mut c_void)) }

    if ((((if not ((if allocated_keys == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (343 as c_int), c"allocated_keys == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    if ((((if not ((if allocated_values == (10000 - 1): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (344 as c_int), c"allocated_values == NUM_TEST_VALUES - 1".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

    if ((((if not ((if allocated_keys == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (349 as c_int), c"allocated_keys == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if allocated_values == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_free_functions".ptr, c"test-hash-table.c".ptr, (350 as c_int), c"allocated_values == 0".ptr)
    } else {
        0
    }

}

pub fn test_hash_table_out_of_memory() -> Unit {
    var __local_hash_table: *mut _HashTable

    var __local_values: [66]c_int

    var __local_i: c_uint

    (__local_hash_table = hash_table_new(int_hash, int_equal))

    alloc_test_set_limit((0 as c_int))

    (__local_values[0] = ((0 as c_int)))

    if ((((if not ((if unsafe { hash_table_insert(__local_hash_table, (((&raw const __local_values[0] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const __local_values[0] as *const c_int) as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (365 as c_int), c"hash_table_insert(hash_table, &values[0], &values[0]) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (366 as c_int), c"hash_table_num_entries(hash_table) == 0".ptr)
    } else {
        0
    }

    alloc_test_set_limit((-1 as c_int))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 65: 1 else: 0) != 0) {
        (__local_values[__local_i] = ((__local_i as c_int)))

        if ((((if not ((if unsafe { hash_table_insert(__local_hash_table, (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const __local_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (379 as c_int), c"hash_table_insert(hash_table, &values[i], &values[i]) != 0".ptr)
        } else {
            0
        }

        if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == ((__local_i as c_uint) +% (1 as c_uint)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (380 as c_int), c"hash_table_num_entries(hash_table) == i + 1".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 65: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (383 as c_int), c"hash_table_num_entries(hash_table) == 65".ptr)
    } else {
        0
    }

    alloc_test_set_limit((0 as c_int))

    (__local_values[65] = ((65 as c_int)))

    if ((((if not ((if unsafe { hash_table_insert(__local_hash_table, (((&raw const __local_values[65] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const __local_values[65] as *const c_int) as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (390 as c_int), c"hash_table_insert(hash_table, &values[65], &values[65]) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { hash_table_num_entries(__local_hash_table) } == 65: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_table_out_of_memory".ptr, c"test-hash-table.c".ptr, (391 as c_int), c"hash_table_num_entries(hash_table) == 65".ptr)
    } else {
        0
    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub fn test_hash_iterator_key_pair(...) -> Unit {
    var __local_hash_table: *mut _HashTable

    var __local_iterator: _HashTableIterator

    var __local_pair: _HashTablePair

    var __local_key: *mut c_int

    var __local_val: *mut c_int


    (__local_hash_table = hash_table_new(int_hash, int_equal))

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value1 as *mut c_int) as *mut c_void), ((&raw mut value1 as *mut c_int) as *mut c_void)) }

    unsafe { hash_table_insert(__local_hash_table, ((&raw mut value2 as *mut c_int) as *mut c_void), ((&raw mut value2 as *mut c_int) as *mut c_void)) }

    unsafe { hash_table_iterate(__local_hash_table, (&raw mut __local_iterator as *mut _HashTableIterator)) }

    while (unsafe { hash_table_iter_has_more((&raw mut __local_iterator as *mut _HashTableIterator)) } != 0) {
        unsafe { with_memcpy((&raw mut __local_pair as *mut u8), (&raw const unsafe { hash_table_iter_next((&raw mut __local_iterator as *mut _HashTableIterator)) } as *const u8), sizeof[_HashTablePair]()) }

        (__local_key = (((unsafe *(&raw const __local_pair as *const _HashTablePair)).key as *mut c_int)))

        (__local_val = (((unsafe *(&raw const __local_pair as *const _HashTablePair)).value as *mut c_int)))

        if ((((if not ((if (unsafe *__local_key) == (unsafe *__local_val): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_hash_iterator_key_pair".ptr, c"test-hash-table.c".ptr, (419 as c_int), c"*key == *val".ptr)
        } else {
            0
        }

    }

    unsafe { hash_table_free(__local_hash_table) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [9]extern "C" fn() -> Unit = [test_hash_table_new_free, test_hash_table_insert_lookup, test_hash_table_remove, test_hash_table_iterating, test_hash_table_iterating_remove, test_hash_table_free_functions, test_hash_table_out_of_memory, test_hash_iterator_key_pair, null]
