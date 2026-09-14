// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.arraylist
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.libc

pub fn generate_arraylist() -> *mut _ArrayList {
    var __local_arraylist: *mut _ArrayList

    var __local_i: c_int

    (__local_arraylist = arraylist_new((0 as c_uint)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 4: 1 else: 0) != 0) {
        unsafe { arraylist_append(__local_arraylist, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

        unsafe { arraylist_append(__local_arraylist, ((&raw mut variable2 as *mut c_int) as *mut c_void)) }

        unsafe { arraylist_append(__local_arraylist, ((&raw mut variable3 as *mut c_int) as *mut c_void)) }

        unsafe { arraylist_append(__local_arraylist, ((&raw mut variable4 as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    return __local_arraylist

}

pub fn test_arraylist_new_free() -> Unit {
    var __local_arraylist: *mut _ArrayList

    (__local_arraylist = arraylist_new((0 as c_uint)))

    if ((((if not ((if __local_arraylist != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_new_free".ptr, c"test-arraylist.c".ptr, (58 as c_int), c"arraylist != NULL".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

    (__local_arraylist = arraylist_new((10 as c_uint)))

    if ((((if not ((if __local_arraylist != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_new_free".ptr, c"test-arraylist.c".ptr, (63 as c_int), c"arraylist != NULL".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

    unsafe { arraylist_free((null as *mut _ArrayList)) }

    alloc_test_set_limit((0 as c_int))

    (__local_arraylist = arraylist_new((0 as c_uint)))

    if ((((if not ((if __local_arraylist == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_new_free".ptr, c"test-arraylist.c".ptr, (72 as c_int), c"arraylist == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((1 as c_int))

    (__local_arraylist = arraylist_new((100 as c_uint)))

    if ((((if not ((if __local_arraylist == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_new_free".ptr, c"test-arraylist.c".ptr, (76 as c_int), c"arraylist == NULL".ptr)
    } else {
        0
    }

}

pub fn test_arraylist_append() -> Unit {
    var __local_arraylist: *mut _ArrayList

    var __local_i: c_int

    (__local_arraylist = arraylist_new((0 as c_uint)))

    if ((((if not ((if (unsafe *__local_arraylist).length == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (86 as c_int), c"arraylist->length == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_append(__local_arraylist, ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (89 as c_int), c"arraylist_append(arraylist, &variable1) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (90 as c_int), c"arraylist->length == 1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_append(__local_arraylist, ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (92 as c_int), c"arraylist_append(arraylist, &variable2) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 2: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (93 as c_int), c"arraylist->length == 2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_append(__local_arraylist, ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (95 as c_int), c"arraylist_append(arraylist, &variable3) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 3: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (96 as c_int), c"arraylist->length == 3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_append(__local_arraylist, ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (98 as c_int), c"arraylist_append(arraylist, &variable4) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (99 as c_int), c"arraylist->length == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[0]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (101 as c_int), c"arraylist->data[0] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[1]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (102 as c_int), c"arraylist->data[1] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[2]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (103 as c_int), c"arraylist->data[2] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[3]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (104 as c_int), c"arraylist->data[3] == &variable4".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { arraylist_append(__local_arraylist, null) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (108 as c_int), c"arraylist_append(arraylist, NULL) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { arraylist_free(__local_arraylist) }

    (__local_arraylist = arraylist_new((100 as c_uint)))

    alloc_test_set_limit((0 as c_int))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 100: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { arraylist_append(__local_arraylist, null) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (119 as c_int), c"arraylist_append(arraylist, NULL) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if (unsafe *__local_arraylist).length == 100: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (122 as c_int), c"arraylist->length == 100".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_append(__local_arraylist, null) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (123 as c_int), c"arraylist_append(arraylist, NULL) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 100: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_append".ptr, c"test-arraylist.c".ptr, (124 as c_int), c"arraylist->length == 100".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

}

pub fn test_arraylist_prepend() -> Unit {
    var __local_arraylist: *mut _ArrayList

    var __local_i: c_int

    (__local_arraylist = arraylist_new((0 as c_uint)))

    if ((((if not ((if (unsafe *__local_arraylist).length == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (136 as c_int), c"arraylist->length == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_prepend(__local_arraylist, ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (139 as c_int), c"arraylist_prepend(arraylist, &variable1) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (140 as c_int), c"arraylist->length == 1".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_prepend(__local_arraylist, ((&raw mut variable2 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (142 as c_int), c"arraylist_prepend(arraylist, &variable2) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 2: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (143 as c_int), c"arraylist->length == 2".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_prepend(__local_arraylist, ((&raw mut variable3 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (145 as c_int), c"arraylist_prepend(arraylist, &variable3) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 3: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (146 as c_int), c"arraylist->length == 3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_prepend(__local_arraylist, ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (148 as c_int), c"arraylist_prepend(arraylist, &variable4) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 4: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (149 as c_int), c"arraylist->length == 4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[0]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (151 as c_int), c"arraylist->data[0] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[1]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (152 as c_int), c"arraylist->data[1] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[2]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (153 as c_int), c"arraylist->data[2] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[3]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (154 as c_int), c"arraylist->data[3] == &variable1".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { arraylist_prepend(__local_arraylist, null) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (158 as c_int), c"arraylist_prepend(arraylist, NULL) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    unsafe { arraylist_free(__local_arraylist) }

    (__local_arraylist = arraylist_new((100 as c_uint)))

    alloc_test_set_limit((0 as c_int))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 100: 1 else: 0) != 0) {
        if ((((if not ((if unsafe { arraylist_prepend(__local_arraylist, null) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (169 as c_int), c"arraylist_prepend(arraylist, NULL) != 0".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    if ((((if not ((if (unsafe *__local_arraylist).length == 100: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (172 as c_int), c"arraylist->length == 100".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_prepend(__local_arraylist, null) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (173 as c_int), c"arraylist_prepend(arraylist, NULL) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 100: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_prepend".ptr, c"test-arraylist.c".ptr, (174 as c_int), c"arraylist->length == 100".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

}

pub fn test_arraylist_insert() -> Unit {
    var __local_arraylist: *mut _ArrayList

    var __local_i: c_int

    (__local_arraylist = generate_arraylist())

    if ((((if not ((if (unsafe *__local_arraylist).length == 16: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (187 as c_int), c"arraylist->length == 16".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_insert(__local_arraylist, (17 as c_uint), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (188 as c_int), c"arraylist_insert(arraylist, 17, &variable1) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 16: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (189 as c_int), c"arraylist->length == 16".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 16: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (192 as c_int), c"arraylist->length == 16".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[4]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (193 as c_int), c"arraylist->data[4] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[5]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (194 as c_int), c"arraylist->data[5] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[6]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (195 as c_int), c"arraylist->data[6] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_insert(__local_arraylist, (5 as c_uint), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (197 as c_int), c"arraylist_insert(arraylist, 5, &variable4) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 17: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (199 as c_int), c"arraylist->length == 17".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[4]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (200 as c_int), c"arraylist->data[4] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[5]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (201 as c_int), c"arraylist->data[5] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[6]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (202 as c_int), c"arraylist->data[6] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[7]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (203 as c_int), c"arraylist->data[7] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[0]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (206 as c_int), c"arraylist->data[0] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[1]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (207 as c_int), c"arraylist->data[1] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[2]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (208 as c_int), c"arraylist->data[2] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_insert(__local_arraylist, (0 as c_uint), ((&raw mut variable4 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (210 as c_int), c"arraylist_insert(arraylist, 0, &variable4) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 18: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (212 as c_int), c"arraylist->length == 18".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[0]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (213 as c_int), c"arraylist->data[0] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[1]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (214 as c_int), c"arraylist->data[1] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[2]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (215 as c_int), c"arraylist->data[2] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[3]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (216 as c_int), c"arraylist->data[3] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[15]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (219 as c_int), c"arraylist->data[15] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[16]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (220 as c_int), c"arraylist->data[16] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[17]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (221 as c_int), c"arraylist->data[17] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { arraylist_insert(__local_arraylist, (18 as c_uint), ((&raw mut variable1 as *mut c_int) as *mut c_void)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (223 as c_int), c"arraylist_insert(arraylist, 18, &variable1) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe *__local_arraylist).length == 19: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (225 as c_int), c"arraylist->length == 19".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[15]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (226 as c_int), c"arraylist->data[15] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[16]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (227 as c_int), c"arraylist->data[16] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[17]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (228 as c_int), c"arraylist->data[17] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[18]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_insert".ptr, c"test-arraylist.c".ptr, (229 as c_int), c"arraylist->data[18] == &variable1".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 10000: 1 else: 0) != 0) {
        unsafe { arraylist_insert(__local_arraylist, (10 as c_uint), ((&raw mut variable1 as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    unsafe { arraylist_free(__local_arraylist) }

}

pub fn test_arraylist_remove_range() -> Unit {
    var __local_arraylist: *mut _ArrayList

    (__local_arraylist = generate_arraylist())

    if ((((if not ((if (unsafe *__local_arraylist).length == 16: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (245 as c_int), c"arraylist->length == 16".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[3]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (246 as c_int), c"arraylist->data[3] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[4]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (247 as c_int), c"arraylist->data[4] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[5]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (248 as c_int), c"arraylist->data[5] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[6]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (249 as c_int), c"arraylist->data[6] == &variable3".ptr)
    } else {
        0
    }

    unsafe { arraylist_remove_range(__local_arraylist, (4 as c_uint), (3 as c_uint)) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 13: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (253 as c_int), c"arraylist->length == 13".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[3]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (254 as c_int), c"arraylist->data[3] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[4]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (255 as c_int), c"arraylist->data[4] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[5]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (256 as c_int), c"arraylist->data[5] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[6]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (257 as c_int), c"arraylist->data[6] == &variable2".ptr)
    } else {
        0
    }

    unsafe { arraylist_remove_range(__local_arraylist, (10 as c_uint), (10 as c_uint)) }

    unsafe { arraylist_remove_range(__local_arraylist, (0 as c_uint), (16 as c_uint)) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 13: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove_range".ptr, c"test-arraylist.c".ptr, (263 as c_int), c"arraylist->length == 13".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

}

pub fn test_arraylist_remove() -> Unit {
    var __local_arraylist: *mut _ArrayList

    (__local_arraylist = generate_arraylist())

    if ((((if not ((if (unsafe *__local_arraylist).length == 16: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (274 as c_int), c"arraylist->length == 16".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[3]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (275 as c_int), c"arraylist->data[3] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[4]) == ((&raw mut variable1 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (276 as c_int), c"arraylist->data[4] == &variable1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[5]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (277 as c_int), c"arraylist->data[5] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[6]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (278 as c_int), c"arraylist->data[6] == &variable3".ptr)
    } else {
        0
    }

    unsafe { arraylist_remove(__local_arraylist, (4 as c_uint)) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 15: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (282 as c_int), c"arraylist->length == 15".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[3]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (283 as c_int), c"arraylist->data[3] == &variable4".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[4]) == ((&raw mut variable2 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (284 as c_int), c"arraylist->data[4] == &variable2".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[5]) == ((&raw mut variable3 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (285 as c_int), c"arraylist->data[5] == &variable3".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[6]) == ((&raw mut variable4 as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (286 as c_int), c"arraylist->data[6] == &variable4".ptr)
    } else {
        0
    }

    unsafe { arraylist_remove(__local_arraylist, (15 as c_uint)) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 15: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_remove".ptr, c"test-arraylist.c".ptr, (291 as c_int), c"arraylist->length == 15".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

}

pub fn test_arraylist_index_of() -> Unit {
    var __local_entries: [10]c_int = [(89 as c_int), (4 as c_int), (23 as c_int), (42 as c_int), (16 as c_int), (15 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int)]

    var __local_num_entries: c_int

    var __local_arraylist: *mut _ArrayList

    var __local_i: c_int

    var __local_index: c_int

    var __local_val: c_int

    (__local_num_entries = ((10 as c_int)))

    (__local_arraylist = arraylist_new((0 as c_uint)))

    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        unsafe { arraylist_append(__local_arraylist, (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = __local_i + 1)

    }


    (__local_i = ((0 as c_int)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        (__local_val = ((__local_entries[__local_i] as c_int)))

        (__local_index = ((unsafe { arraylist_index_of(__local_arraylist, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } as c_int)))

        if ((((if not ((if __local_index == __local_i: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_arraylist_index_of".ptr, c"test-arraylist.c".ptr, (320 as c_int), c"index == i".ptr)
        } else {
            0
        }


        (__local_i = __local_i + 1)

    }


    (__local_val = ((0 as c_int)))

    if ((((if not ((if unsafe { arraylist_index_of(__local_arraylist, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_index_of".ptr, c"test-arraylist.c".ptr, (325 as c_int), c"arraylist_index_of(arraylist, int_equal, &val) < 0".ptr)
    } else {
        0
    }

    (__local_val = ((57 as c_int)))

    if ((((if not ((if unsafe { arraylist_index_of(__local_arraylist, int_equal, ((&raw mut __local_val as *mut c_int) as *mut c_void)) } < 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_index_of".ptr, c"test-arraylist.c".ptr, (327 as c_int), c"arraylist_index_of(arraylist, int_equal, &val) < 0".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

}

pub fn test_arraylist_clear() -> Unit {
    var __local_arraylist: *mut _ArrayList

    (__local_arraylist = arraylist_new((0 as c_uint)))

    unsafe { arraylist_clear(__local_arraylist) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_clear".ptr, c"test-arraylist.c".ptr, (340 as c_int), c"arraylist->length == 0".ptr)
    } else {
        0
    }

    unsafe { arraylist_append(__local_arraylist, ((&raw mut variable1 as *mut c_int) as *mut c_void)) }

    unsafe { arraylist_append(__local_arraylist, ((&raw mut variable2 as *mut c_int) as *mut c_void)) }

    unsafe { arraylist_append(__local_arraylist, ((&raw mut variable3 as *mut c_int) as *mut c_void)) }

    unsafe { arraylist_append(__local_arraylist, ((&raw mut variable4 as *mut c_int) as *mut c_void)) }

    unsafe { arraylist_clear(__local_arraylist) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_clear".ptr, c"test-arraylist.c".ptr, (350 as c_int), c"arraylist->length == 0".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

}

pub fn test_arraylist_sort() -> Unit {
    var __local_arraylist: *mut _ArrayList

    var __local_entries: [13]c_int = [(89 as c_int), (4 as c_int), (23 as c_int), (42 as c_int), (4 as c_int), (16 as c_int), (15 as c_int), (4 as c_int), (8 as c_int), (99 as c_int), (50 as c_int), (30 as c_int), (4 as c_int)]

    var __local_sorted: [13]c_int = [(4 as c_int), (4 as c_int), (4 as c_int), (4 as c_int), (8 as c_int), (15 as c_int), (16 as c_int), (23 as c_int), (30 as c_int), (42 as c_int), (50 as c_int), (89 as c_int), (99 as c_int)]

    var __local_num_entries: c_uint = ((13 as c_uint))

    var __local_i: c_uint

    (__local_arraylist = arraylist_new((10 as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        unsafe { arraylist_prepend(__local_arraylist, (((&raw const __local_entries[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    unsafe { arraylist_sort(__local_arraylist, int_compare) }

    if ((((if not ((if (unsafe *__local_arraylist).length == __local_num_entries: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_sort".ptr, c"test-arraylist.c".ptr, (372 as c_int), c"arraylist->length == num_entries".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_num_entries: 1 else: 0) != 0) {
        var __local_value: *mut c_int

        (__local_value = (((unsafe (unsafe *__local_arraylist).data[__local_i]) as *mut c_int)))

        if ((((if not ((if (unsafe *__local_value) == __local_sorted[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_arraylist_sort".ptr, c"test-arraylist.c".ptr, (379 as c_int), c"*value == sorted[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { arraylist_free(__local_arraylist) }

    (__local_arraylist = arraylist_new((5 as c_uint)))

    unsafe { arraylist_sort(__local_arraylist, int_compare) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_sort".ptr, c"test-arraylist.c".ptr, (389 as c_int), c"arraylist->length == 0".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

    (__local_arraylist = arraylist_new((5 as c_uint)))

    unsafe { arraylist_prepend(__local_arraylist, (((&raw const __local_entries[0] as *const c_int) as *mut c_int) as *mut c_void)) }

    unsafe { arraylist_sort(__local_arraylist, int_compare) }

    if ((((if not ((if (unsafe *__local_arraylist).length == 1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_sort".ptr, c"test-arraylist.c".ptr, (399 as c_int), c"arraylist->length == 1".ptr)
    } else {
        0
    }

    if ((((if not ((if (unsafe (unsafe *__local_arraylist).data[0]) == (((&raw const __local_entries[0] as *const c_int) as *mut c_int)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_arraylist_sort".ptr, c"test-arraylist.c".ptr, (400 as c_int), c"arraylist->data[0] == &entries[0]".ptr)
    } else {
        0
    }

    unsafe { arraylist_free(__local_arraylist) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var tests: [10]extern "C" fn() -> Unit = [test_arraylist_new_free, test_arraylist_append, test_arraylist_prepend, test_arraylist_insert, test_arraylist_remove, test_arraylist_remove_range, test_arraylist_index_of, test_arraylist_clear, test_arraylist_sort, null]
