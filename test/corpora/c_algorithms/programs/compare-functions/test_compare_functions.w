// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.compare_int
use std.calg_testing.compare_pointer
use std.calg_testing.compare_string
use std.calg_testing.framework
use std.libc
use std.option

pub fn test_int_compare() -> Unit {
    var __local_a: c_int = ((4 as c_int))

    var __local_b: c_int = ((8 as c_int))

    var __local_c: c_int = ((4 as c_int))

    if (((if not ((if unsafe { int_compare(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_b as *mut c_int) as *mut c_void)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_int_compare".ptr, c"test-compare-functions.c".ptr, (41 as c_int), c"int_compare(&a, &b) < 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { int_compare(((&raw mut __local_b as *mut c_int) as *mut c_void), ((&raw mut __local_a as *mut c_int) as *mut c_void)) } > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_int_compare".ptr, c"test-compare-functions.c".ptr, (44 as c_int), c"int_compare(&b, &a) > 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { int_compare(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_c as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_int_compare".ptr, c"test-compare-functions.c".ptr, (47 as c_int), c"int_compare(&a, &c) == 0".ptr)
    } else {
        0
    }

}

pub fn test_int_equal() -> Unit {
    var __local_a: c_int = ((4 as c_int))

    var __local_b: c_int = ((8 as c_int))

    var __local_c: c_int = ((4 as c_int))

    if (((if not ((if unsafe { int_equal(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_c as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_int_equal".ptr, c"test-compare-functions.c".ptr, (57 as c_int), c"int_equal(&a, &c) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { int_equal(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_b as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_int_equal".ptr, c"test-compare-functions.c".ptr, (60 as c_int), c"int_equal(&a, &b) == 0".ptr)
    } else {
        0
    }

}

pub fn test_pointer_compare() -> Unit {
    var __local_array: [c_int; 5]

    if (((if not ((if unsafe { pointer_compare((((&raw const __local_array[0] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const __local_array[4] as *const c_int) as *mut c_int) as *mut c_void)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_pointer_compare".ptr, c"test-compare-functions.c".ptr, (69 as c_int), c"pointer_compare(&array[0], &array[4]) < 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { pointer_compare((((&raw const __local_array[3] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const __local_array[2] as *const c_int) as *mut c_int) as *mut c_void)) } > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_pointer_compare".ptr, c"test-compare-functions.c".ptr, (73 as c_int), c"pointer_compare(&array[3], &array[2]) > 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { pointer_compare((((&raw const __local_array[4] as *const c_int) as *mut c_int) as *mut c_void), (((&raw const __local_array[4] as *const c_int) as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_pointer_compare".ptr, c"test-compare-functions.c".ptr, (76 as c_int), c"pointer_compare(&array[4], &array[4]) == 0".ptr)
    } else {
        0
    }

}

pub fn test_pointer_equal() -> Unit {
    var __local_a: c_int

    var __local_b: c_int


    if (((if not ((if unsafe { pointer_equal(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_a as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_pointer_equal".ptr, c"test-compare-functions.c".ptr, (84 as c_int), c"pointer_equal(&a, &a) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { pointer_equal(((&raw mut __local_a as *mut c_int) as *mut c_void), ((&raw mut __local_b as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_pointer_equal".ptr, c"test-compare-functions.c".ptr, (87 as c_int), c"pointer_equal(&a, &b) == 0".ptr)
    } else {
        0
    }

}

pub fn test_string_compare() -> Unit {
    var __local_test1: [c_char; 6] = [65, 112, 112, 108, 101, 0]

    var __local_test2: [c_char; 7] = [79, 114, 97, 110, 103, 101, 0]

    var __local_test3: [c_char; 6] = [65, 112, 112, 108, 101, 0]

    if (((if not ((if unsafe { string_compare((&__local_test1[0] as *mut c_char), (&__local_test2[0] as *mut c_char)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_compare".ptr, c"test-compare-functions.c".ptr, (97 as c_int), c"string_compare(test1, test2) < 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_compare((&__local_test2[0] as *mut c_char), (&__local_test1[0] as *mut c_char)) } > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_compare".ptr, c"test-compare-functions.c".ptr, (100 as c_int), c"string_compare(test2, test1) > 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_compare((&__local_test1[0] as *mut c_char), (&__local_test3[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_compare".ptr, c"test-compare-functions.c".ptr, (103 as c_int), c"string_compare(test1, test3) == 0".ptr)
    } else {
        0
    }

}

pub fn test_string_equal() -> Unit {
    var __local_test1: [c_char; 22] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 0]

    var __local_test2: [c_char; 23] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 32, 0]

    var __local_test3: [c_char; 21] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 0]

    var __local_test4: [c_char; 22] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 71, 0]

    var __local_test5: [c_char; 22] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 0]

    if (((if not ((if unsafe { string_equal((&__local_test1[0] as *mut c_char), (&__local_test5[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_equal".ptr, c"test-compare-functions.c".ptr, (115 as c_int), c"string_equal(test1, test5) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_equal((&__local_test1[0] as *mut c_char), (&__local_test2[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_equal".ptr, c"test-compare-functions.c".ptr, (119 as c_int), c"string_equal(test1, test2) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_equal((&__local_test1[0] as *mut c_char), (&__local_test3[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_equal".ptr, c"test-compare-functions.c".ptr, (120 as c_int), c"string_equal(test1, test3) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_equal((&__local_test1[0] as *mut c_char), (&__local_test4[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_equal".ptr, c"test-compare-functions.c".ptr, (123 as c_int), c"string_equal(test1, test4) == 0".ptr)
    } else {
        0
    }

}

pub fn test_string_nocase_compare() -> Unit {
    var __local_test1: [c_char; 6] = [65, 112, 112, 108, 101, 0]

    var __local_test2: [c_char; 7] = [79, 114, 97, 110, 103, 101, 0]

    var __local_test3: [c_char; 6] = [65, 112, 112, 108, 101, 0]

    var __local_test4: [c_char; 6] = [65, 108, 112, 104, 97, 0]

    var __local_test5: [c_char; 6] = [98, 114, 97, 118, 111, 0]

    var __local_test6: [c_char; 8] = [67, 104, 97, 114, 108, 105, 101, 0]

    if (((if not ((if unsafe { string_nocase_compare((&__local_test1[0] as *mut c_char), (&__local_test2[0] as *mut c_char)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_compare".ptr, c"test-compare-functions.c".ptr, (136 as c_int), c"string_nocase_compare(test1, test2) < 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_compare((&__local_test2[0] as *mut c_char), (&__local_test1[0] as *mut c_char)) } > 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_compare".ptr, c"test-compare-functions.c".ptr, (139 as c_int), c"string_nocase_compare(test2, test1) > 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_compare((&__local_test1[0] as *mut c_char), (&__local_test3[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_compare".ptr, c"test-compare-functions.c".ptr, (142 as c_int), c"string_nocase_compare(test1, test3) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_compare((&__local_test4[0] as *mut c_char), (&__local_test5[0] as *mut c_char)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_compare".ptr, c"test-compare-functions.c".ptr, (145 as c_int), c"string_nocase_compare(test4, test5) < 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_compare((&__local_test5[0] as *mut c_char), (&__local_test6[0] as *mut c_char)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_compare".ptr, c"test-compare-functions.c".ptr, (146 as c_int), c"string_nocase_compare(test5, test6) < 0".ptr)
    } else {
        0
    }

}

pub fn test_string_nocase_equal() -> Unit {
    var __local_test1: [c_char; 22] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 0]

    var __local_test2: [c_char; 23] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 32, 0]

    var __local_test3: [c_char; 21] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 0]

    var __local_test4: [c_char; 22] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 71, 0]

    var __local_test5: [c_char; 22] = [116, 104, 105, 115, 32, 105, 115, 32, 97, 32, 116, 101, 115, 116, 32, 115, 116, 114, 105, 110, 103, 0]

    if (((if not ((if unsafe { string_nocase_equal((&__local_test1[0] as *mut c_char), (&__local_test5[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_equal".ptr, c"test-compare-functions.c".ptr, (158 as c_int), c"string_nocase_equal(test1, test5) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_equal((&__local_test1[0] as *mut c_char), (&__local_test2[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_equal".ptr, c"test-compare-functions.c".ptr, (162 as c_int), c"string_nocase_equal(test1, test2) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_equal((&__local_test1[0] as *mut c_char), (&__local_test3[0] as *mut c_char)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_equal".ptr, c"test-compare-functions.c".ptr, (163 as c_int), c"string_nocase_equal(test1, test3) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { string_nocase_equal((&__local_test1[0] as *mut c_char), (&__local_test4[0] as *mut c_char)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_string_nocase_equal".ptr, c"test-compare-functions.c".ptr, (166 as c_int), c"string_nocase_equal(test1, test4) != 0".ptr)
    } else {
        0
    }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [Option[extern "C" fn() -> Unit]; 9] = [Some(test_int_compare), Some(test_int_equal), Some(test_pointer_compare), Some(test_pointer_equal), Some(test_string_compare), Some(test_string_equal), Some(test_string_nocase_compare), Some(test_string_nocase_equal), null]
