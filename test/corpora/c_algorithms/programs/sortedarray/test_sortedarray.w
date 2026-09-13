// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.calg_testing.sortedarray
use std.libc

pub unsafe fn check_sorted(__param_sa: *mut _SortedArray) -> Unit {
    var __local_i: c_uint

    (__local_i = ((1 as c_uint)))

    while ((if __local_i < sortedarray_length(__param_sa): 1 else: 0) != 0) {
        if ((((if not ((if int_compare(sortedarray_get(__param_sa, (((__local_i as c_uint) -% (1 as c_uint)) as c_uint)), sortedarray_get(__param_sa, __local_i)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"check_sorted".ptr, c"test-sortedarray.c".ptr, (68 as c_int), c"int_compare(sortedarray_get(sa, i - 1), sortedarray_get(sa, i)) <= 0".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


}

pub fn generate_sortedarray() -> *mut _SortedArray {
    var __local_sa: *mut _SortedArray

    var __local_i: c_uint

    (__local_sa = sortedarray_new((0 as c_uint), int_compare))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (((100 * sizeof[c_int]()) as c_ulong) / (sizeof[c_int]() as c_ulong)): 1 else: 0) != 0) {
        unsafe { sortedarray_insert(__local_sa, (((&raw const test_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    return __local_sa

}

pub fn test_sortedarray_new_free() -> Unit {
    var __local_sa: *mut _SortedArray

    if ((((if not ((if sortedarray_new((0 as c_uint), null) == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_new_free".ptr, c"test-sortedarray.c".ptr, (92 as c_int), c"sortedarray_new(0, NULL) == NULL".ptr)
    } else {
        0
    }

    (__local_sa = sortedarray_new((0 as c_uint), int_compare))

    if ((((if not ((if __local_sa != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_new_free".ptr, c"test-sortedarray.c".ptr, (96 as c_int), c"sa != NULL".ptr)
    } else {
        0
    }

    unsafe { sortedarray_free(__local_sa) }

    unsafe { sortedarray_free((null as *mut _SortedArray)) }

    alloc_test_set_limit((0 as c_int))

    (__local_sa = sortedarray_new((0 as c_uint), int_compare))

    if ((((if not ((if __local_sa == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_new_free".ptr, c"test-sortedarray.c".ptr, (105 as c_int), c"sa == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((-1 as c_int))

}

pub fn test_sortedarray_insert() -> Unit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    if ((((if not ((if unsafe { sortedarray_insert((null as *mut _SortedArray), null) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_insert".ptr, c"test-sortedarray.c".ptr, (114 as c_int), c"sortedarray_insert(NULL, NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { check_sorted(__local_sa) }

    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_get() -> Unit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    var __local_i: c_uint

    var __local_got: *mut c_int

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < unsafe { sortedarray_length(__local_sa) }: 1 else: 0) != 0) {
        (__local_got = ((unsafe { sortedarray_get(__local_sa, __local_i) } as *mut c_int)))

        if ((((if not ((if __local_got != null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (129 as c_int), c"got != NULL".ptr)
        } else {
            0
        }

        if ((((if not ((if (unsafe *__local_got) == sorted_test_values[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (130 as c_int), c"*got == sorted_test_values[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    if ((((if not ((if unsafe { sortedarray_get((null as *mut _SortedArray), (0 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (134 as c_int), c"sortedarray_get(NULL, 0) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_get(__local_sa, (unsafe { sortedarray_length(__local_sa) } as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (135 as c_int), c"sortedarray_get(sa, sortedarray_length(sa)) == NULL".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_get(__local_sa, (999999 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (136 as c_int), c"sortedarray_get(sa, 999999) == NULL".ptr)
    } else {
        0
    }

    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_remove() -> Unit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    var __local_i: c_uint

    var __local_check_idx: c_uint


    var __local_got: *mut c_int

    if ((((if not ((if unsafe { sortedarray_remove_range(__local_sa, (95 as c_uint), (10 as c_uint)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (155 as c_int), c"sortedarray_remove_range(sa, REMOVE_IDX_3, REMOVE_IDX_3_LEN) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_remove_range(__local_sa, (57 as c_uint), (7 as c_uint)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (157 as c_int), c"sortedarray_remove_range(sa, REMOVE_IDX_2, REMOVE_IDX_2_LEN) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_remove(__local_sa, (23 as c_uint)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (158 as c_int), c"sortedarray_remove(sa, REMOVE_IDX_1) != 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_remove((null as *mut _SortedArray), (0 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (161 as c_int), c"sortedarray_remove(NULL, 0) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_remove(__local_sa, (unsafe { sortedarray_length(__local_sa) } as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (162 as c_int), c"sortedarray_remove(sa, sortedarray_length(sa)) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_remove_range(__local_sa, (unsafe { sortedarray_length(__local_sa) } as c_uint), (3 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (163 as c_int), c"sortedarray_remove_range(sa, sortedarray_length(sa), 3) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_remove(__local_sa, (999999 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (164 as c_int), c"sortedarray_remove(sa, 999999) == 0".ptr)
    } else {
        0
    }

    if ((((if not ((if unsafe { sortedarray_remove_range(__local_sa, (999999 as c_uint), (44 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (165 as c_int), c"sortedarray_remove_range(sa, 999999, 44) == 0".ptr)
    } else {
        0
    }

    unsafe { check_sorted(__local_sa) }

    if ((((if not ((if unsafe { sortedarray_length(__local_sa) } == (((((((((100 * sizeof[c_int]()) as c_ulong) / (sizeof[c_int]() as c_ulong)) as c_ulong) -% (1 as c_ulong)) as c_ulong) -% (7 as c_ulong)) as c_ulong) -% (5 as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (169 as c_int), c"sortedarray_length(sa) == NUM_TEST_VALUES - 1 - REMOVE_IDX_2_LEN - REMOVE_IDX_3_REAL_LEN".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < unsafe { sortedarray_length(__local_sa) }: 1 else: 0) != 0) {
        (__local_check_idx = __local_i)

        if ((if __local_check_idx >= 23: 1 else: 0) != 0) {
            (__local_check_idx = (__local_check_idx +% 1))

        }

        if ((if __local_check_idx >= 57: 1 else: 0) != 0) {
            (__local_check_idx = (__local_check_idx +% 7))

        }

        (__local_got = ((unsafe { sortedarray_get(__local_sa, __local_i) } as *mut c_int)))

        if ((((if not ((if (unsafe *__local_got) == sorted_test_values[__local_check_idx]: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (180 as c_int), c"*got == sorted_test_values[check_idx]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_index_of() -> Unit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    var __local_i: c_uint

    var __local_got_idx: c_int

    var __local_test_index: c_int


    if ((((if not ((if unsafe { sortedarray_index_of((null as *mut _SortedArray), null) } == -1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_index_of".ptr, c"test-sortedarray.c".ptr, (192 as c_int), c"sortedarray_index_of(NULL, NULL) == -1".ptr)
    } else {
        0
    }

    (__local_test_index = ((999999 as c_int)))

    if ((((if not ((if unsafe { sortedarray_index_of(__local_sa, ((&raw mut __local_test_index as *mut c_int) as *mut c_void)) } == -1: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_index_of".ptr, c"test-sortedarray.c".ptr, (196 as c_int), c"sortedarray_index_of(sa, &test_index) == -1".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (((100 * sizeof[c_int]()) as c_ulong) / (sizeof[c_int]() as c_ulong)): 1 else: 0) != 0) {
        (__local_got_idx = ((unsafe { sortedarray_index_of(__local_sa, (((&raw const sorted_test_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } as c_int)))

        if ((((if not ((if sorted_test_values[__local_got_idx] == sorted_test_values[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_index_of".ptr, c"test-sortedarray.c".ptr, (201 as c_int), c"sorted_test_values[got_idx] == sorted_test_values[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_clear() -> Unit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    unsafe { sortedarray_clear(__local_sa) }

    if ((((if not ((if unsafe { sortedarray_length(__local_sa) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_clear".ptr, c"test-sortedarray.c".ptr, (212 as c_int), c"sortedarray_length(sa) == 0".ptr)
    } else {
        0
    }

    unsafe { sortedarray_free(__local_sa) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var test_values: [100]c_int = [(114812 as c_int), (292972 as c_int), (15252 as c_int), (317887 as c_int), (859422 as c_int), (943227 as c_int), (173673 as c_int), (444396 as c_int), (289730 as c_int), (60903 as c_int), (706503 as c_int), (412815 as c_int), (-13616 as c_int), (464193 as c_int), (921380 as c_int), (411002 as c_int), (118983 as c_int), (908936 as c_int), (854842 as c_int), (228639 as c_int), (175174 as c_int), (976812 as c_int), (963457 as c_int), (39332 as c_int), (774021 as c_int), (588784 as c_int), (23511 as c_int), (364428 as c_int), (816641 as c_int), (66433 as c_int), (911779 as c_int), (774060 as c_int), (4340 as c_int), (-46542 as c_int), (739951 as c_int), (388501 as c_int), (710893 as c_int), (817647 as c_int), (582295 as c_int), (994147 as c_int), (741106 as c_int), (813303 as c_int), (187471 as c_int), (147041 as c_int), (933029 as c_int), (933029 as c_int), (933029 as c_int), (753121 as c_int), (469556 as c_int), (882575 as c_int), (953070 as c_int), (166462 as c_int), (-25609 as c_int), (766862 as c_int), (199480 as c_int), (269323 as c_int), (636875 as c_int), (49809 as c_int), (633426 as c_int), (153528 as c_int), (325532 as c_int), (15949 as c_int), (418818 as c_int), (541376 as c_int), (950242 as c_int), (824802 as c_int), (67683 as c_int), (583518 as c_int), (91497 as c_int), (832324 as c_int), (591778 as c_int), (296072 as c_int), (96531 as c_int), (867789 as c_int), (126879 as c_int), (716791 as c_int), (685326 as c_int), (826331 as c_int), (677729 as c_int), (496589 as c_int), (-6777 as c_int), (667244 as c_int), (446665 as c_int), (560213 as c_int), (727965 as c_int), (678769 as c_int), (428202 as c_int), (761385 as c_int), (130289 as c_int), (724727 as c_int), (300728 as c_int), (734018 as c_int), (493283 as c_int), (770024 as c_int), (472722 as c_int), (123696 as c_int), (301295 as c_int), (511707 as c_int), (383382 as c_int), (151978 as c_int)]
var sorted_test_values: [100]c_int = [(-46542 as c_int), (-25609 as c_int), (-13616 as c_int), (-6777 as c_int), (4340 as c_int), (15252 as c_int), (15949 as c_int), (23511 as c_int), (39332 as c_int), (49809 as c_int), (60903 as c_int), (66433 as c_int), (67683 as c_int), (91497 as c_int), (96531 as c_int), (114812 as c_int), (118983 as c_int), (123696 as c_int), (126879 as c_int), (130289 as c_int), (147041 as c_int), (151978 as c_int), (153528 as c_int), (166462 as c_int), (173673 as c_int), (175174 as c_int), (187471 as c_int), (199480 as c_int), (228639 as c_int), (269323 as c_int), (289730 as c_int), (292972 as c_int), (296072 as c_int), (300728 as c_int), (301295 as c_int), (317887 as c_int), (325532 as c_int), (364428 as c_int), (383382 as c_int), (388501 as c_int), (411002 as c_int), (412815 as c_int), (418818 as c_int), (428202 as c_int), (444396 as c_int), (446665 as c_int), (464193 as c_int), (469556 as c_int), (472722 as c_int), (493283 as c_int), (496589 as c_int), (511707 as c_int), (541376 as c_int), (560213 as c_int), (582295 as c_int), (583518 as c_int), (588784 as c_int), (591778 as c_int), (633426 as c_int), (636875 as c_int), (667244 as c_int), (677729 as c_int), (678769 as c_int), (685326 as c_int), (706503 as c_int), (710893 as c_int), (716791 as c_int), (724727 as c_int), (727965 as c_int), (734018 as c_int), (739951 as c_int), (741106 as c_int), (753121 as c_int), (761385 as c_int), (766862 as c_int), (770024 as c_int), (774021 as c_int), (774060 as c_int), (813303 as c_int), (816641 as c_int), (817647 as c_int), (824802 as c_int), (826331 as c_int), (832324 as c_int), (854842 as c_int), (859422 as c_int), (867789 as c_int), (882575 as c_int), (908936 as c_int), (911779 as c_int), (921380 as c_int), (933029 as c_int), (933029 as c_int), (933029 as c_int), (943227 as c_int), (950242 as c_int), (953070 as c_int), (963457 as c_int), (976812 as c_int), (994147 as c_int)]
var tests: [7]extern "C" fn() -> Unit = [test_sortedarray_new_free, test_sortedarray_insert, test_sortedarray_get, test_sortedarray_remove, test_sortedarray_index_of, test_sortedarray_clear, null]
