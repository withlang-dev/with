// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.framework
use std.engines.c_algorithms_testing.trie
use std.libc
use std.option
use std.collections

pub fn generate_trie() -> *mut _Trie writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_i: i32

    var __local_entries: u32

    (__local_trie = trie_new())

    (__local_entries = ((0 as u32)))

    (__local_i = ((0 as i32)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        sprintf((&test_strings[__local_i][0] as *mut c_char), c"%i".ptr, __local_i)

        if (((if not ((if unsafe { trie_insert(__local_trie, (&test_strings[__local_i][0] as *mut c_char), (((&raw const test_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"generate_trie".ptr, c"test-trie.c".ptr, (57 as i32), c"trie_insert(trie, test_strings[i], &test_array[i]) != 0".ptr)
        } else {
            0
        }

        (__local_entries = (__local_entries +% 1))

        if (((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"generate_trie".ptr, c"test-trie.c".ptr, (61 as i32), c"trie_num_entries(trie) == entries".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    return __local_trie

}

pub fn test_trie_new_free() -> Unit writes allocation_limit {
    var __local_trie: *mut _Trie

    (__local_trie = trie_new())

    if (((if not ((if __local_trie != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (74 as i32), c"trie != NULL".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

    (__local_trie = trie_new())

    if (((if not ((if unsafe { trie_insert(__local_trie, ("hello" as *mut c_char), ("there" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (81 as i32), c"trie_insert(trie, \"hello\", \"there\") != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_insert(__local_trie, ("hell" as *mut c_char), ("testing" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (82 as i32), c"trie_insert(trie, \"hell\", \"testing\") != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_insert(__local_trie, ("testing" as *mut c_char), ("testing" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (83 as i32), c"trie_insert(trie, \"testing\", \"testing\") != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_insert(__local_trie, ("" as *mut c_char), ("asfasf" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (84 as i32), c"trie_insert(trie, \"\", \"asfasf\") != 0".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

    (__local_trie = trie_new())

    if (((if not ((if unsafe { trie_insert(__local_trie, ("hello" as *mut c_char), ("there" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (91 as i32), c"trie_insert(trie, \"hello\", \"there\") != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove(__local_trie, ("hello" as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (92 as i32), c"trie_remove(trie, \"hello\") != 0".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

    alloc_test_set_limit((0 as i32))

    (__local_trie = trie_new())

    if (((if not ((if __local_trie == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (99 as i32), c"trie == NULL".ptr)
    } else {
        0
    }

}

pub fn test_trie_insert() writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_entries: u32

    var __local_allocated: u64

    (__local_trie = generate_trie())

    (__local_entries = ((unsafe { trie_num_entries(__local_trie) } as u32)))

    if (((if not ((if unsafe { trie_insert(__local_trie, ("hello world" as *mut c_char), null) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (112 as i32), c"trie_insert(trie, \"hello world\", NULL) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (113 as i32), c"trie_num_entries(trie) == entries".ptr)
    } else {
        0
    }

    (__local_allocated = ((alloc_test_get_allocated() as u64)))

    alloc_test_set_limit((0 as i32))

    if (((if not ((if unsafe { trie_insert(__local_trie, ("a" as *mut c_char), ("test value" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (118 as i32), c"trie_insert(trie, \"a\", \"test value\") == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (119 as i32), c"trie_num_entries(trie) == entries".ptr)
    } else {
        0
    }

    alloc_test_set_limit((5 as i32))

    if (((if not ((if unsafe { trie_insert(__local_trie, ("hello world" as *mut c_char), ("test value" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (123 as i32), c"trie_insert(trie, \"hello world\", \"test value\") == 0".ptr)
    } else {
        0
    }

    if (((if not ((if alloc_test_get_allocated() == __local_allocated: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (124 as i32), c"alloc_test_get_allocated() == allocated".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (125 as i32), c"trie_num_entries(trie) == entries".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_lookup() writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_buf: List[c_char] = [0; 10]

    var __local_val: *mut i32

    var __local_i: i32

    (__local_trie = generate_trie())

    if (((if not ((if unsafe { trie_lookup(__local_trie, ("000000000000000" as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_lookup".ptr, c"test-trie.c".ptr, (140 as i32), c"trie_lookup(trie, \"000000000000000\") == TRIE_NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup(__local_trie, ("" as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_lookup".ptr, c"test-trie.c".ptr, (141 as i32), c"trie_lookup(trie, \"\") == TRIE_NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        (__local_val = ((unsafe { trie_lookup(__local_trie, (&__local_buf[0] as *mut c_char)) } as *mut i32)))

        if (((if not ((if (unsafe *__local_val) == __local_i: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_trie_lookup".ptr, c"test-trie.c".ptr, (150 as i32), c"*val == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_remove() writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_buf: List[c_char] = [0; 10]

    var __local_i: i32

    var __local_entries: u32

    (__local_trie = generate_trie())

    if (((if not ((if unsafe { trie_remove(__local_trie, ("000000000000000" as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (166 as i32), c"trie_remove(trie, \"000000000000000\") == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove(__local_trie, ("" as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (167 as i32), c"trie_remove(trie, \"\") == 0".ptr)
    } else {
        0
    }

    (__local_entries = ((unsafe { trie_num_entries(__local_trie) } as u32)))

    if (((if not ((if __local_entries == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (171 as i32), c"entries == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if (((if not ((if unsafe { trie_remove(__local_trie, (&__local_buf[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (179 as i32), c"trie_remove(trie, buf) != 0".ptr)
        } else {
            0
        }

        (__local_entries = (__local_entries -% 1))

        if (((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (181 as i32), c"trie_num_entries(trie) == entries".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_replace() writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_val: *mut i32

    (__local_trie = generate_trie())

    (__local_val = ((alloc_test_malloc((sizeof[i32]() as u64)) as *mut i32)))

    ((unsafe *__local_val) = ((999 as i32)))

    if (((if not ((if unsafe { trie_insert(__local_trie, ("999" as *mut c_char), (__local_val as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_replace".ptr, c"test-trie.c".ptr, (197 as i32), c"trie_insert(trie, \"999\", val) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_num_entries(__local_trie) } == 10000: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_replace".ptr, c"test-trie.c".ptr, (198 as i32), c"trie_num_entries(trie) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup(__local_trie, ("999" as *mut c_char)) } == __local_val: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_replace".ptr, c"test-trie.c".ptr, (200 as i32), c"trie_lookup(trie, \"999\") == val".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_val as *mut c_void)) }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_insert_empty() writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_buf: List[c_char] = [0; 10]

    (__local_trie = trie_new())

    if (((if not ((if unsafe { trie_insert(__local_trie, ("" as *mut c_char), (&__local_buf[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (213 as i32), c"trie_insert(trie, \"\", buf) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_num_entries(__local_trie) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (214 as i32), c"trie_num_entries(trie) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup(__local_trie, ("" as *mut c_char)) } == (&__local_buf[0] as *mut c_void): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (215 as i32), c"trie_lookup(trie, \"\") == buf".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove(__local_trie, ("" as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (216 as i32), c"trie_remove(trie, \"\") != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_num_entries(__local_trie) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (218 as i32), c"trie_num_entries(trie) == 0".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

fn test_trie_free_long() {
    var __local_long_string: *mut c_char

    var __local_trie: *mut _Trie

    (__local_long_string = ((alloc_test_malloc((4096 as u64)) as *mut c_char)))

    with_memset(((__local_long_string as *mut c_void) as *mut u8), (65 as i32), ((4096 as u64) as i64))

    ((unsafe __local_long_string[(4096 - 1)]) = ((0 as c_char)))

    (__local_trie = trie_new())

    unsafe { trie_insert(__local_trie, __local_long_string, (__local_long_string as *mut c_void)) }

    unsafe { trie_free(__local_trie) }

    unsafe { alloc_test_free((__local_long_string as *mut c_void)) }

}

fn test_trie_negative_keys() {
    var __local_my_key: List[c_char] = [97, 98, 99, (-50 as c_char), (-20 as c_char), 0]

    var __local_trie: *mut _Trie

    var __local_value: *mut c_void

    (__local_trie = trie_new())

    if (((if not ((if unsafe { trie_insert(__local_trie, (&__local_my_key[0] as *mut c_char), ("hello world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (253 as i32), c"trie_insert(trie, my_key, \"hello world\") != 0".ptr)
    } else {
        0
    }

    (__local_value = unsafe { trie_lookup(__local_trie, (&__local_my_key[0] as *mut c_char)) })

    if (((if not ((if not (strcmp((__local_value as *const c_char), c"hello world".ptr) != 0): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (257 as i32), c"!strcmp(value, \"hello world\")".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove(__local_trie, (&__local_my_key[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (259 as i32), c"trie_remove(trie, my_key) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove(__local_trie, (&__local_my_key[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (260 as i32), c"trie_remove(trie, my_key) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup(__local_trie, (&__local_my_key[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (261 as i32), c"trie_lookup(trie, my_key) == NULL".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn generate_binary_trie() -> *mut _Trie writes allocation_limit {
    var __local_trie: *mut _Trie

    (__local_trie = trie_new())

    if (((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as i32), ("goodbye world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"generate_binary_trie".ptr, c"test-trie.c".ptr, (274 as i32), c"trie_insert_binary(trie, bin_key2, sizeof(bin_key2), \"goodbye world\") != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as i32), ("hello world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"generate_binary_trie".ptr, c"test-trie.c".ptr, (276 as i32), c"trie_insert_binary(trie, bin_key, sizeof(bin_key), \"hello world\") != 0".ptr)
    } else {
        0
    }

    return __local_trie

}

pub fn test_trie_insert_binary() writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_value: *mut c_char

    (__local_trie = generate_binary_trie())

    if (((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as i32), ("hi world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (290 as i32), c"trie_insert_binary(trie, bin_key, sizeof(bin_key), \"hi world\") != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key3[0] as *mut u8), (3 as i32), null) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (293 as i32), c"trie_insert_binary(trie, bin_key3, sizeof(bin_key3), NULL) == 0".ptr)
    } else {
        0
    }

    (__local_value = ((unsafe { trie_lookup_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as i32)) } as *mut c_char)))

    if (((if not ((if not (strcmp((__local_value as *const c_char), c"hi world".ptr) != 0): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (297 as i32), c"!strcmp(value, \"hi world\")".ptr)
    } else {
        0
    }

    (__local_value = ((unsafe { trie_lookup_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as i32)) } as *mut c_char)))

    if (((if not ((if not (strcmp((__local_value as *const c_char), c"goodbye world".ptr) != 0): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (300 as i32), c"!strcmp(value, \"goodbye world\")".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_insert_out_of_memory() writes allocation_limit {
    var __local_trie: *mut _Trie

    (__local_trie = generate_binary_trie())

    alloc_test_set_limit((3 as i32))

    if (((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as i32), ("test value" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_out_of_memory".ptr, c"test-trie.c".ptr, (314 as i32), c"trie_insert_binary(trie, bin_key4, sizeof(bin_key4), \"test value\") == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as i32)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_out_of_memory".ptr, c"test-trie.c".ptr, (316 as i32), c"trie_lookup_binary(trie, bin_key4, sizeof(bin_key4)) == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_num_entries(__local_trie) } == 2: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_insert_out_of_memory".ptr, c"test-trie.c".ptr, (317 as i32), c"trie_num_entries(trie) == 2".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_remove_binary() writes allocation_limit {
    var __local_trie: *mut _Trie

    var __local_value: *mut c_void

    (__local_trie = generate_binary_trie())

    (__local_value = unsafe { trie_lookup_binary(__local_trie, (&bin_key3[0] as *mut u8), (3 as i32)) })

    if (((if not ((if __local_value == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (331 as i32), c"value == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key3[0] as *mut u8), (3 as i32)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (333 as i32), c"trie_remove_binary(trie, bin_key3, sizeof(bin_key3)) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as i32)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (335 as i32), c"trie_lookup_binary(trie, bin_key4, sizeof(bin_key4)) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as i32)) } == 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (336 as i32), c"trie_remove_binary(trie, bin_key4, sizeof(bin_key4)) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as i32)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (339 as i32), c"trie_remove_binary(trie, bin_key2, sizeof(bin_key2)) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as i32)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (340 as i32), c"trie_lookup_binary(trie, bin_key2, sizeof(bin_key2)) == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as i32)) } != null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (341 as i32), c"trie_lookup_binary(trie, bin_key, sizeof(bin_key)) != NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as i32)) } != 0: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (343 as i32), c"trie_remove_binary(trie, bin_key, sizeof(bin_key)) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as i32)) } == null: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (344 as i32), c"trie_lookup_binary(trie, bin_key, sizeof(bin_key)) == NULL".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_trie_new_free), Some(test_trie_insert), Some(test_trie_lookup), Some(test_trie_remove), Some(test_trie_replace), Some(test_trie_insert_empty), Some(test_trie_free_long), Some(test_trie_negative_keys), Some(test_trie_insert_binary), Some(test_trie_insert_out_of_memory), Some(test_trie_remove_binary), null]
