// Migrated from C
use std.c_algorithms.defs
use std.c_algorithms.arraylist
use std.c_algorithms.avl_tree
use std.c_algorithms.binary_heap
use std.c_algorithms.binomial_heap
use std.c_algorithms.bloom_filter
use std.c_algorithms.compare_int
use std.c_algorithms.compare_pointer
use std.c_algorithms.compare_string
use std.c_algorithms.framework
use std.c_algorithms.hash_int
use std.c_algorithms.hash_pointer
use std.c_algorithms.hash_string
use std.c_algorithms.hash_table
use std.c_algorithms.list
use std.c_algorithms.queue
use std.c_algorithms.set
use std.c_algorithms.slist
use std.c_algorithms.trie
use std.libc

fn test_compare_int() -> Unit {
    var __local_a: c_int

    var __local_b: c_int


    (__local_a = ((1 as c_int)))

    (__local_b = ((2 as c_int)))

    if ((((if not ((if not (unsafe { int_equal(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_b as *mut c_int) as *mut c_void)) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_compare_int".ptr, c"test-cpp.c".ptr, (53 as c_int), c"!int_equal(&a, &b)".ptr)
    } else {
        0
    }

    (__local_a = ((2 as c_int)))

    (__local_b = ((2 as c_int)))

    if ((((if not (unsafe { int_equal(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_b as *mut c_int) as *mut c_void)) } != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_compare_int".ptr, c"test-cpp.c".ptr, (55 as c_int), c"int_equal(&a, &b)".ptr)
    } else {
        0
    }

}

fn test_compare_pointer() -> Unit {
    var __local_a: c_int

    var __local_b: c_int


    var __local_p1: *mut c_void

    var __local_p2: *mut c_void


    (__local_p1 = (((&raw mut __local_a as *mut c_int) as *mut c_void)))

    (__local_p2 = (((&raw mut __local_b as *mut c_int) as *mut c_void)))

    if ((((if not ((if not (unsafe { pointer_equal(__local_p1, __local_p2) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_compare_pointer".ptr, c"test-cpp.c".ptr, (64 as c_int), c"!pointer_equal(p1, p2)".ptr)
    } else {
        0
    }

    (__local_p1 = (((&raw mut __local_a as *mut c_int) as *mut c_void)))

    (__local_p2 = (((&raw mut __local_a as *mut c_int) as *mut c_void)))

    if ((((if not (unsafe { pointer_equal(__local_p1, __local_p2) } != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_compare_pointer".ptr, c"test-cpp.c".ptr, (66 as c_int), c"pointer_equal(p1, p2)".ptr)
    } else {
        0
    }

}

fn test_compare_string() -> Unit {
    var __local_s1: [6]c_char = [(104 as c_char), (101 as c_char), (108 as c_char), (108 as c_char), (111 as c_char), (0 as c_char)]

    var __local_s2: [6]c_char = [(104 as c_char), (101 as c_char), (108 as c_char), (108 as c_char), (111 as c_char), (0 as c_char)]

    var __local_s3: [6]c_char = [(119 as c_char), (111 as c_char), (114 as c_char), (108 as c_char), (100 as c_char), (0 as c_char)]

    if ((((if not ((if not (unsafe { string_equal((&__local_s1[0] as *mut c_char), (&__local_s3[0] as *mut c_char)) } != 0): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_compare_string".ptr, c"test-cpp.c".ptr, (75 as c_int), c"!string_equal(s1, s3)".ptr)
    } else {
        0
    }

    if ((((if not (unsafe { string_equal((&__local_s1[0] as *mut c_char), (&__local_s2[0] as *mut c_char)) } != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_compare_string".ptr, c"test-cpp.c".ptr, (76 as c_int), c"string_equal(s1, s2)".ptr)
    } else {
        0
    }

}

fn test_hash_int() -> Unit {
    var __local_a: c_int

    var __local_b: c_int


    (__local_a = ((1 as c_int)))

    (__local_b = ((2 as c_int)))

    if ((((if not ((if unsafe { int_hash(((&raw mut __local_a as *mut c_int) as *mut c_void)) } != unsafe { int_hash(((&raw mut __local_b as *mut c_int) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_int".ptr, c"test-cpp.c".ptr, (84 as c_int), c"int_hash(&a) != int_hash(&b)".ptr)
    } else {
        0
    }

    (__local_a = ((2 as c_int)))

    (__local_b = ((2 as c_int)))

    if ((((if not ((if unsafe { int_hash(((&raw mut __local_a as *mut c_int) as *mut c_void)) } == unsafe { int_hash(((&raw mut __local_b as *mut c_int) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_int".ptr, c"test-cpp.c".ptr, (86 as c_int), c"int_hash(&a) == int_hash(&b)".ptr)
    } else {
        0
    }

}

fn test_hash_pointer() -> Unit {
    var __local_a: c_int

    var __local_b: c_int


    var __local_p1: *mut c_void

    var __local_p2: *mut c_void


    (__local_p1 = (((&raw mut __local_a as *mut c_int) as *mut c_void)))

    (__local_p2 = (((&raw mut __local_b as *mut c_int) as *mut c_void)))

    if ((((if not ((if unsafe { pointer_hash(__local_p1) } != unsafe { pointer_hash(__local_p2) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_pointer".ptr, c"test-cpp.c".ptr, (95 as c_int), c"pointer_hash(p1) != pointer_hash(p2)".ptr)
    } else {
        0
    }

    (__local_p1 = (((&raw mut __local_a as *mut c_int) as *mut c_void)))

    (__local_p2 = (((&raw mut __local_a as *mut c_int) as *mut c_void)))

    if ((((if not ((if unsafe { pointer_hash(__local_p1) } == unsafe { pointer_hash(__local_p2) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_pointer".ptr, c"test-cpp.c".ptr, (97 as c_int), c"pointer_hash(p1) == pointer_hash(p2)".ptr)
    } else {
        0
    }

}

fn test_hash_string() -> Unit {
    var __local_s1: [6]c_char = [(104 as c_char), (101 as c_char), (108 as c_char), (108 as c_char), (111 as c_char), (0 as c_char)]

    var __local_s2: [6]c_char = [(104 as c_char), (101 as c_char), (108 as c_char), (108 as c_char), (111 as c_char), (0 as c_char)]

    var __local_s3: [6]c_char = [(119 as c_char), (111 as c_char), (114 as c_char), (108 as c_char), (100 as c_char), (0 as c_char)]

    if ((((if not ((if unsafe { string_hash((&__local_s1[0] as *mut c_char)) } != unsafe { string_hash((&__local_s3[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_string".ptr, c"test-cpp.c".ptr, (106 as c_int), c"string_hash(s1) != string_hash(s3)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { string_hash((&__local_s1[0] as *mut c_char)) } == unsafe { string_hash((&__local_s2[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_hash_string".ptr, c"test-cpp.c".ptr, (107 as c_int), c"string_hash(s1) == string_hash(s2)".ptr)
    } else {
        0
    }

}

fn test_arraylist() -> Unit {
    var __local_arraylist: *mut _ArrayList

    (__local_arraylist = arraylist_new((0 as c_uint)))

    unsafe { arraylist_free(__local_arraylist) }

}

fn test_avl_tree() -> Unit {
    var __local_avl_tree: *mut _AVLTree

    (__local_avl_tree = avl_tree_new(string_compare))

    unsafe { avl_tree_free(__local_avl_tree) }

}

fn test_binary_heap() -> Unit {
    var __local_heap: *mut _BinaryHeap

    (__local_heap = binary_heap_new((1 as i32), string_compare))

    unsafe { binary_heap_free(__local_heap) }

}

fn test_binomial_heap() -> Unit {
    var __local_heap: *mut _BinomialHeap

    (__local_heap = binomial_heap_new((1 as i32), string_compare))

    unsafe { binomial_heap_free(__local_heap) }

}

fn test_bloom_filter() -> Unit {
    var __local_filter: *mut _BloomFilter

    (__local_filter = bloom_filter_new((16 as c_uint), string_hash, (10 as c_uint)))

    unsafe { bloom_filter_free(__local_filter) }

}

fn test_hash_table() -> Unit {
    var __local_hash_table: *mut _HashTable

    (__local_hash_table = hash_table_new(string_hash, string_equal))

    unsafe { hash_table_free(__local_hash_table) }

}

fn test_list() -> Unit {
    var __local_list: *mut _ListEntry = ((null as *mut _ListEntry))

    var __local_a: c_int

    var __local_b: c_int

    var __local_c: c_int


    unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut __local_a as *mut c_int) as *mut c_void)) }

    unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut __local_b as *mut c_int) as *mut c_void)) }

    unsafe { list_prepend((&raw mut __local_list as *mut *mut _ListEntry), ((&raw mut __local_c as *mut c_int) as *mut c_void)) }

    unsafe { list_free(__local_list) }

}

fn test_queue() -> Unit {
    var __local_queue: *mut _Queue

    (__local_queue = queue_new())

    unsafe { queue_free(__local_queue) }

}

fn test_set() -> Unit {
    var __local_set: *mut _Set

    (__local_set = set_new(string_hash, string_equal))

    unsafe { set_free(__local_set) }

}

fn test_slist() -> Unit {
    var __local_list: *mut _SListEntry = ((null as *mut _SListEntry))

    var __local_a: c_int

    var __local_b: c_int

    var __local_c: c_int


    unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut __local_a as *mut c_int) as *mut c_void)) }

    unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut __local_b as *mut c_int) as *mut c_void)) }

    unsafe { slist_prepend((&raw mut __local_list as *mut *mut _SListEntry), ((&raw mut __local_c as *mut c_int) as *mut c_void)) }

    unsafe { slist_free(__local_list) }

}

fn test_trie() -> Unit {
    var __local_trie: *mut _Trie

    (__local_trie = trie_new())

    unsafe { trie_free(__local_trie) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

}

var tests: [18]extern "C" fn() -> Unit = [test_compare_int, test_compare_pointer, test_compare_string, test_hash_int, test_hash_pointer, test_hash_string, test_arraylist, test_avl_tree, test_binary_heap, test_binomial_heap, test_bloom_filter, test_hash_table, test_list, test_queue, test_set, test_slist, test_trie, null]
