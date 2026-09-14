// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.framework
use std.calg_testing.hash_int
use std.calg_testing.hash_pointer
use std.calg_testing.hash_string
use std.libc

pub fn test_pointer_hash() -> Unit {
    var __local_array: [200]c_int

    var __local_i: c_int

    var __local_j: c_int


    (__local_i = ((0 as c_int)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_array[__local_i] = ((0 as c_int)))


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_j = (((__local_i + 1) as c_int)))

        while ((if __local_j < 200: 1 else: 0) != 0) {
            if ((((if not ((if unsafe { pointer_hash((((&raw const __local_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != unsafe { pointer_hash((((&raw const __local_array[__local_j] as *const c_int) as *mut c_int) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                __assert_rtn(c"test_pointer_hash".ptr, c"test-hash-functions.c".ptr, (48 as c_int), c"pointer_hash(&array[i]) != pointer_hash(&array[j])".ptr)
            } else {
                0
            }


            (__local_j = __local_j + 1)

        }



        (__local_i = __local_i + 1)

    }


}

pub fn test_int_hash() -> Unit {
    var __local_array: [200]c_int

    var __local_i: c_int

    var __local_j: c_int


    (__local_i = ((0 as c_int)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_array[__local_i] = __local_i)


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < 200: 1 else: 0) != 0) {
        (__local_j = (((__local_i + 1) as c_int)))

        while ((if __local_j < 200: 1 else: 0) != 0) {
            if ((((if not ((if unsafe { int_hash((((&raw const __local_array[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } != unsafe { int_hash((((&raw const __local_array[__local_j] as *const c_int) as *mut c_int) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
                __assert_rtn(c"test_int_hash".ptr, c"test-hash-functions.c".ptr, (66 as c_int), c"int_hash(&array[i]) != int_hash(&array[j])".ptr)
            } else {
                0
            }


            (__local_j = __local_j + 1)

        }



        (__local_i = __local_i + 1)

    }


    (__local_i = ((5000 as c_int)))

    (__local_j = ((5000 as c_int)))

    if ((((if not ((if unsafe { int_hash(((&raw mut __local_i as *mut c_int) as *mut c_void)) } == unsafe { int_hash(((&raw mut __local_j as *mut c_int) as *mut c_void)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_int_hash".ptr, c"test-hash-functions.c".ptr, (74 as c_int), c"int_hash(&i) == int_hash(&j)".ptr)
    } else {
        0
    }

}

pub fn test_string_hash() -> Unit {
    var __local_test1: [15]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (0 as c_char)]

    var __local_test2: [15]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (117 as c_char), (0 as c_char)]

    var __local_test3: [16]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (32 as c_char), (0 as c_char)]

    var __local_test4: [15]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (0 as c_char)]

    var __local_test5: [15]c_char = [(84 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (0 as c_char)]

    if ((((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_hash((&__local_test2[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (86 as c_int), c"string_hash(test1) != string_hash(test2)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_hash((&__local_test3[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (89 as c_int), c"string_hash(test1) != string_hash(test3)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_hash((&__local_test5[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (92 as c_int), c"string_hash(test1) != string_hash(test5)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { string_hash((&__local_test1[0] as *mut c_char)) } == unsafe { string_hash((&__local_test4[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_hash".ptr, c"test-hash-functions.c".ptr, (95 as c_int), c"string_hash(test1) == string_hash(test4)".ptr)
    } else {
        0
    }

}

pub fn test_string_nocase_hash() -> Unit {
    var __local_test1: [15]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (0 as c_char)]

    var __local_test2: [15]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (117 as c_char), (0 as c_char)]

    var __local_test3: [16]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (32 as c_char), (0 as c_char)]

    var __local_test4: [15]c_char = [(116 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (0 as c_char)]

    var __local_test5: [15]c_char = [(84 as c_char), (104 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (105 as c_char), (115 as c_char), (32 as c_char), (97 as c_char), (32 as c_char), (116 as c_char), (101 as c_char), (115 as c_char), (116 as c_char), (0 as c_char)]

    if ((((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_nocase_hash((&__local_test2[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (107 as c_int), c"string_nocase_hash(test1) != string_nocase_hash(test2)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } != unsafe { string_nocase_hash((&__local_test3[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (110 as c_int), c"string_nocase_hash(test1) != string_nocase_hash(test3)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } == unsafe { string_nocase_hash((&__local_test5[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (113 as c_int), c"string_nocase_hash(test1) == string_nocase_hash(test5)".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { string_nocase_hash((&__local_test1[0] as *mut c_char)) } == unsafe { string_nocase_hash((&__local_test4[0] as *mut c_char)) }: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_hash".ptr, c"test-hash-functions.c".ptr, (116 as c_int), c"string_nocase_hash(test1) == string_nocase_hash(test4)".ptr)
    } else {
        0
    }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [5]extern "C" fn() -> Unit = [test_pointer_hash, test_int_hash, test_string_hash, test_string_nocase_hash, null]
