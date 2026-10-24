// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.engines.c_algorithms_testing.framework
use std.engines.c_algorithms_testing.hash_int
use std.engines.c_algorithms_testing.hash_pointer
use std.engines.c_algorithms_testing.hash_string
use std.libc
use std.option
use std.collections

pub fn test_pointer_hash() {
    var __local_array: List[i32] = [0; 200]

    var __local_i: i32

    var __local_j: i32


    (__local_i = ((0 as i32)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_array[__local_i] = ((0 as i32)))


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as i32)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_j = (((__local_i + 1) as i32)))

        while ((if __local_j < 200: 1 else: 0) != 0) {
            if (((if not ((if unsafe { pointer_hash((((&raw const __local_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != unsafe { pointer_hash((((&raw const __local_array[__local_j] as *const i32) as *mut i32) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                __assert_rtn(c"test_pointer_hash".ptr, c"test-hash-functions.c".ptr, (48 as i32), c"pointer_hash(&array[i]) != pointer_hash(&array[j])".ptr)
            } else {
                0
            }


            (__local_j = __local_j + 1)

        }



        (__local_i = __local_i + 1)

    }


}

pub fn test_int_hash() -> Unit {
    var __local_array: List[i32] = [0; 200]

    var __local_i: i32

    var __local_j: i32


    (__local_i = ((0 as i32)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_array[__local_i] = __local_i)


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as i32)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_j = (((__local_i + 1) as i32)))

        while ((if __local_j < 200: 1 else: 0) != 0) {
            if (((if not ((if unsafe { int_hash((((&raw const __local_array[__local_i] as *const i32) as *mut i32) as *mut c_void)) } != unsafe { int_hash((((&raw const __local_array[__local_j] as *const i32) as *mut i32) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                __assert_rtn(c"test_int_hash".ptr, c"test-hash-functions.c".ptr, (66 as i32), c"int_hash(&array[i]) != int_hash(&array[j])".ptr)
            } else {
                0
            }


            (__local_j = __local_j + 1)

        }



        (__local_i = __local_i + 1)

    }


    (__local_i = ((5000 as i32)))

    (__local_j = ((5000 as i32)))

    if (((if not ((if unsafe { int_hash(((&raw mut __local_i as *mut i32) as *mut c_void)) } == unsafe { int_hash(((&raw mut __local_j as *mut i32) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_int_hash".ptr, c"test-hash-functions.c".ptr, (74 as i32), c"int_hash(&i) == int_hash(&j)".ptr)
    } else {
        0
    }

}

pub fn test_string_hash() -> Unit {
    var __local_test1: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 0]

    var __local_test2: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 117, 0]

    var __local_test3: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 0]

    var __local_test4: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 0]

    var __local_test5: List[c_char] = [84, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 0]

    if (((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_hash((&__local_test2[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (86 as i32), c"string_hash(test1) != string_hash(test2)".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_hash((&__local_test3[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (89 as i32), c"string_hash(test1) != string_hash(test3)".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_hash((&__local_test5[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (92 as i32), c"string_hash(test1) != string_hash(test5)".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } == unsafe { string_hash((&__local_test4[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (95 as i32), c"string_hash(test1) == string_hash(test4)".ptr)
    } else {
        0
    }

}

pub fn test_string_nocase_hash() -> Unit {
    var __local_test1: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 0]

    var __local_test2: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 117, 0]

    var __local_test3: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 0]

    var __local_test4: List[c_char] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 0]

    var __local_test5: List[c_char] = [84, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 0]

    if (((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_nocase_hash((&__local_test2[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (107 as i32), c"string_nocase_hash(test1) != string_nocase_hash(test2)".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_nocase_hash((&__local_test3[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (110 as i32), c"string_nocase_hash(test1) != string_nocase_hash(test3)".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } == unsafe { string_nocase_hash((&__local_test5[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (113 as i32), c"string_nocase_hash(test1) == string_nocase_hash(test5)".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } == unsafe { string_nocase_hash((&__local_test4[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (116 as i32), c"string_nocase_hash(test1) == string_nocase_hash(test4)".ptr)
    } else {
        0
    }

}

pub unsafe fn main(__param_argc: i32, __param_argv: *mut *mut c_char) -> i32 writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

let tests: List[Option[extern "C" fn() -> Unit]] = [Some(test_pointer_hash), Some(test_int_hash), Some(test_string_hash), Some(test_string_nocase_hash), null]
