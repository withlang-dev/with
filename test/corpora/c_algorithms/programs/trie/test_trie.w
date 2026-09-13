// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.framework
use std.calg_testing.trie
use std.libc

pub fn generate_trie() -> *mut _Trie {
    var __local_trie: *mut _Trie

    var __local_i: c_int

    var __local_entries: c_uint

    (__local_trie = trie_new())

    (__local_entries = ((0 as c_uint)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        (test_array[__local_i] = __local_i)

        sprintf((&test_strings[__local_i][0] as *mut c_char), c"%i".ptr, __local_i)

        if ((((if not ((if unsafe { trie_insert(__local_trie, (&test_strings[__local_i][0] as *mut c_char), (((&raw const test_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"generate_trie".ptr, c"test-trie.c".ptr, (57 as c_int), c"trie_insert(trie, test_strings[i], &test_array[i]) != 0".ptr)
        } else {
            0
        }

        (__local_entries = (__local_entries +% 1))

        if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"generate_trie".ptr, c"test-trie.c".ptr, (61 as c_int), c"trie_num_entries(trie) == entries".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    return __local_trie

}

pub fn test_trie_new_free() -> Unit {
    var __local_trie: *mut _Trie

    (__local_trie = trie_new())

    if ((((if not ((if __local_trie != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (74 as c_int), c"trie != NULL".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

    (__local_trie = trie_new())

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("hello" as *mut i8), ("there" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (81 as c_int), c"trie_insert(trie, \"hello\", \"there\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("hell" as *mut i8), ("testing" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (82 as c_int), c"trie_insert(trie, \"hell\", \"testing\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("testing" as *mut i8), ("testing" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (83 as c_int), c"trie_insert(trie, \"testing\", \"testing\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("" as *mut i8), ("asfasf" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (84 as c_int), c"trie_insert(trie, \"\", \"asfasf\") != 0".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

    (__local_trie = trie_new())

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("hello" as *mut i8), ("there" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (91 as c_int), c"trie_insert(trie, \"hello\", \"there\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove(__local_trie, ("hello" as *mut i8)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (92 as c_int), c"trie_remove(trie, \"hello\") != 0".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

    alloc_test_set_limit((0 as c_int))

    (__local_trie = trie_new())

    if ((((if not ((if __local_trie == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_new_free".ptr, c"test-trie.c".ptr, (99 as c_int), c"trie == NULL".ptr)
    } else {
        0
    }

}

pub fn test_trie_insert() -> Unit {
    var __local_trie: *mut _Trie

    var __local_entries: c_uint

    var __local_allocated: c_ulong

    (__local_trie = generate_trie())

    (__local_entries = ((unsafe { trie_num_entries(__local_trie) } as c_uint)))

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("hello world" as *mut i8), null) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (112 as c_int), c"trie_insert(trie, \"hello world\", NULL) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (113 as c_int), c"trie_num_entries(trie) == entries".ptr)
    } else {
        0
    }

    (__local_allocated = ((alloc_test_get_allocated() as c_ulong)))

    alloc_test_set_limit((0 as c_int))

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("a" as *mut i8), ("test value" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (118 as c_int), c"trie_insert(trie, \"a\", \"test value\") == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (119 as c_int), c"trie_num_entries(trie) == entries".ptr)
    } else {
        0
    }

    alloc_test_set_limit((5 as c_int))

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("hello world" as *mut i8), ("test value" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (123 as c_int), c"trie_insert(trie, \"hello world\", \"test value\") == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if alloc_test_get_allocated() == __local_allocated: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (124 as c_int), c"alloc_test_get_allocated() == allocated".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert".ptr, c"test-trie.c".ptr, (125 as c_int), c"trie_num_entries(trie) == entries".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_lookup() -> Unit {
    var __local_trie: *mut _Trie

    var __local_buf: [10]c_char

    var __local_val: *mut c_int

    var __local_i: c_int

    (__local_trie = generate_trie())

    if ((((if not ((if unsafe { trie_lookup(__local_trie, ("000000000000000" as *mut i8)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_lookup".ptr, c"test-trie.c".ptr, (140 as c_int), c"trie_lookup(trie, \"000000000000000\") == TRIE_NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup(__local_trie, ("" as *mut i8)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_lookup".ptr, c"test-trie.c".ptr, (141 as c_int), c"trie_lookup(trie, \"\") == TRIE_NULL".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        (__local_val = ((unsafe { trie_lookup(__local_trie, (&__local_buf[0] as *mut c_char)) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_val) == __local_i: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_trie_lookup".ptr, c"test-trie.c".ptr, (150 as c_int), c"*val == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_remove() -> Unit {
    var __local_trie: *mut _Trie

    var __local_buf: [10]c_char

    var __local_i: c_int

    var __local_entries: c_uint

    (__local_trie = generate_trie())

    if ((((if not ((if unsafe { trie_remove(__local_trie, ("000000000000000" as *mut i8)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (166 as c_int), c"trie_remove(trie, \"000000000000000\") == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove(__local_trie, ("" as *mut i8)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (167 as c_int), c"trie_remove(trie, \"\") == 0".ptr)
    } else {
        0
    }

    (__local_entries = ((unsafe { trie_num_entries(__local_trie) } as c_uint)))

    if ((((if not ((if __local_entries == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (171 as c_int), c"entries == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        sprintf((&__local_buf[0] as *mut c_char), c"%i".ptr, __local_i)

        if ((((if not ((if unsafe { trie_remove(__local_trie, (&__local_buf[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (179 as c_int), c"trie_remove(trie, buf) != 0".ptr)
        } else {
            0
        }

        (__local_entries = (__local_entries -% 1))

        if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == __local_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_trie_remove".ptr, c"test-trie.c".ptr, (181 as c_int), c"trie_num_entries(trie) == entries".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_replace() -> Unit {
    var __local_trie: *mut _Trie

    var __local_val: *mut c_int

    (__local_trie = generate_trie())

    (__local_val = ((alloc_test_malloc((sizeof[c_int]() as c_ulong)) as *mut c_int)))

    ((unsafe *__local_val) = ((999 as c_int)))

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("999" as *mut i8), (__local_val as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_replace".ptr, c"test-trie.c".ptr, (197 as c_int), c"trie_insert(trie, \"999\", val) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == 10000: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_replace".ptr, c"test-trie.c".ptr, (198 as c_int), c"trie_num_entries(trie) == NUM_TEST_VALUES".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup(__local_trie, ("999" as *mut i8)) } == __local_val: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_replace".ptr, c"test-trie.c".ptr, (200 as c_int), c"trie_lookup(trie, \"999\") == val".ptr)
    } else {
        0
    }

    unsafe { alloc_test_free((__local_val as *mut c_void)) }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_insert_empty() -> Unit {
    var __local_trie: *mut _Trie

    var __local_buf: [10]c_char

    (__local_trie = trie_new())

    if ((((if not ((if unsafe { trie_insert(__local_trie, ("" as *mut i8), (&__local_buf[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (213 as c_int), c"trie_insert(trie, \"\", buf) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_num_entries(__local_trie) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (214 as c_int), c"trie_num_entries(trie) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup(__local_trie, ("" as *mut i8)) } == (&__local_buf[0] as *mut c_char): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (215 as c_int), c"trie_lookup(trie, \"\") == buf".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove(__local_trie, ("" as *mut i8)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (216 as c_int), c"trie_remove(trie, \"\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_empty".ptr, c"test-trie.c".ptr, (218 as c_int), c"trie_num_entries(trie) == 0".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

fn test_trie_free_long() -> Unit {
    var __local_long_string: *mut c_char

    var __local_trie: *mut _Trie

    (__local_long_string = ((alloc_test_malloc((4096 as c_ulong)) as *mut c_char)))

    unsafe { with_memset(((__local_long_string as *mut c_void) as *mut u8), (65 as c_int), ((4096 as c_ulong) as i64)) }

    ((unsafe __local_long_string[(4096 - 1)]) = ((0 as c_char)))

    (__local_trie = trie_new())

    unsafe { trie_insert(__local_trie, __local_long_string, (__local_long_string as *mut c_void)) }

    unsafe { trie_free(__local_trie) }

    unsafe { alloc_test_free((__local_long_string as *mut c_void)) }

}

fn test_trie_negative_keys() -> Unit {
    var __local_my_key: [6]c_char = [(97 as c_char), (98 as c_char), (99 as c_char), (-50 as c_char), (-20 as c_char), (0 as c_char)]

    var __local_trie: *mut _Trie

    var __local_value: *mut c_void

    (__local_trie = trie_new())

    if ((((if not ((if unsafe { trie_insert(__local_trie, (&__local_my_key[0] as *mut c_char), ("hello world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (253 as c_int), c"trie_insert(trie, my_key, \"hello world\") != 0".ptr)
    } else {
        0
    }

    (__local_value = unsafe { trie_lookup(__local_trie, (&__local_my_key[0] as *mut c_char)) })

    if ((((if not ((if not (strcmp((__local_value as *const i8), c"hello world".ptr) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (257 as c_int), c"!strcmp(value, \"hello world\")".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove(__local_trie, (&__local_my_key[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (259 as c_int), c"trie_remove(trie, my_key) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove(__local_trie, (&__local_my_key[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (260 as c_int), c"trie_remove(trie, my_key) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup(__local_trie, (&__local_my_key[0] as *mut c_char)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_negative_keys".ptr, c"test-trie.c".ptr, (261 as c_int), c"trie_lookup(trie, my_key) == NULL".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn generate_binary_trie() -> *mut _Trie {
    var __local_trie: *mut _Trie

    (__local_trie = trie_new())

    if ((((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as c_int), ("goodbye world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_binary_trie".ptr, c"test-trie.c".ptr, (274 as c_int), c"trie_insert_binary(trie, bin_key2, sizeof(bin_key2), \"goodbye world\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as c_int), ("hello world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"generate_binary_trie".ptr, c"test-trie.c".ptr, (276 as c_int), c"trie_insert_binary(trie, bin_key, sizeof(bin_key), \"hello world\") != 0".ptr)
    } else {
        0
    }

    return __local_trie

}

pub fn test_trie_insert_binary() -> Unit {
    var __local_trie: *mut _Trie

    var __local_value: *mut c_char

    (__local_trie = generate_binary_trie())

    if ((((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as c_int), ("hi world" as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (290 as c_int), c"trie_insert_binary(trie, bin_key, sizeof(bin_key), \"hi world\") != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key3[0] as *mut u8), (3 as c_int), null) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (293 as c_int), c"trie_insert_binary(trie, bin_key3, sizeof(bin_key3), NULL) == 0".ptr)
    } else {
        0
    }

    (__local_value = ((unsafe { trie_lookup_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as c_int)) } as *mut c_char)))

    if ((((if not ((if not (strcmp((__local_value as *const i8), c"hi world".ptr) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (297 as c_int), c"!strcmp(value, \"hi world\")".ptr)
    } else {
        0
    }

    (__local_value = ((unsafe { trie_lookup_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as c_int)) } as *mut c_char)))

    if ((((if not ((if not (strcmp((__local_value as *const i8), c"goodbye world".ptr) != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_binary".ptr, c"test-trie.c".ptr, (300 as c_int), c"!strcmp(value, \"goodbye world\")".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_insert_out_of_memory() -> Unit {
    var __local_trie: *mut _Trie

    (__local_trie = generate_binary_trie())

    alloc_test_set_limit((3 as c_int))

    if ((((if not ((if unsafe { trie_insert_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as c_int), ("test value" as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_out_of_memory".ptr, c"test-trie.c".ptr, (314 as c_int), c"trie_insert_binary(trie, bin_key4, sizeof(bin_key4), \"test value\") == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as c_int)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_out_of_memory".ptr, c"test-trie.c".ptr, (316 as c_int), c"trie_lookup_binary(trie, bin_key4, sizeof(bin_key4)) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_num_entries(__local_trie) } == 2: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_insert_out_of_memory".ptr, c"test-trie.c".ptr, (317 as c_int), c"trie_num_entries(trie) == 2".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub fn test_trie_remove_binary() -> Unit {
    var __local_trie: *mut _Trie

    var __local_value: *mut c_void

    (__local_trie = generate_binary_trie())

    (__local_value = unsafe { trie_lookup_binary(__local_trie, (&bin_key3[0] as *mut u8), (3 as c_int)) })

    if ((((if not ((if __local_value == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (331 as c_int), c"value == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key3[0] as *mut u8), (3 as c_int)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (333 as c_int), c"trie_remove_binary(trie, bin_key3, sizeof(bin_key3)) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as c_int)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (335 as c_int), c"trie_lookup_binary(trie, bin_key4, sizeof(bin_key4)) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key4[0] as *mut u8), (4 as c_int)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (336 as c_int), c"trie_remove_binary(trie, bin_key4, sizeof(bin_key4)) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as c_int)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (339 as c_int), c"trie_remove_binary(trie, bin_key2, sizeof(bin_key2)) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key2[0] as *mut u8), (8 as c_int)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (340 as c_int), c"trie_lookup_binary(trie, bin_key2, sizeof(bin_key2)) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as c_int)) } != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (341 as c_int), c"trie_lookup_binary(trie, bin_key, sizeof(bin_key)) != NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_remove_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as c_int)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (343 as c_int), c"trie_remove_binary(trie, bin_key, sizeof(bin_key)) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { trie_lookup_binary(__local_trie, (&bin_key[0] as *mut u8), (7 as c_int)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_trie_remove_binary".ptr, c"test-trie.c".ptr, (344 as c_int), c"trie_lookup_binary(trie, bin_key, sizeof(bin_key)) == NULL".ptr)
    } else {
        0
    }

    unsafe { trie_free(__local_trie) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [12]extern "C" fn() -> Unit = [test_trie_new_free, test_trie_insert, test_trie_lookup, test_trie_remove, test_trie_replace, test_trie_insert_empty, test_trie_free_long, test_trie_negative_keys, test_trie_insert_binary, test_trie_insert_out_of_memory, test_trie_remove_binary, null]
