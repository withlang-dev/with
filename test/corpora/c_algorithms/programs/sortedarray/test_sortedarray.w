// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing
use std.calg_testing.compare_int
use std.calg_testing.framework
use std.calg_testing.sortedarray
use std.libc
use std.option

pub unsafe fn check_sorted(__param_sa: *mut _SortedArray) {
    var __local_i: c_uint

    (__local_i = ((1 as c_uint)))

    while ((if __local_i < sortedarray_length(__param_sa): 1 else: 0) != 0) {
        if (((if not ((if int_compare(sortedarray_get(__param_sa, (((__local_i as c_uint) -% (1 as c_uint)) as c_uint)), sortedarray_get(__param_sa, __local_i)) <= 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"check_sorted".ptr, c"test-sortedarray.c".ptr, (68 as c_int), c"int_compare(sortedarray_get(sa, i - 1), sortedarray_get(sa, i)) <= 0".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


}

pub fn generate_sortedarray() -> *mut _SortedArray writes allocation_limit {
    var __local_sa: *mut _SortedArray

    var __local_i: c_uint

    (__local_sa = sortedarray_new((0 as c_uint), Some(int_compare)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((test_values.len() as c_ulong)): 1 else: 0) != 0) {
        unsafe { sortedarray_insert(__local_sa, (((&raw const test_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) }


        (__local_i = (__local_i +% 1))

    }


    return __local_sa

}

pub fn test_sortedarray_new_free() writes allocation_limit {
    var __local_sa: *mut _SortedArray

    if (((if not ((if sortedarray_new((0 as c_uint), null) == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_new_free".ptr, c"test-sortedarray.c".ptr, (92 as c_int), c"sortedarray_new(0, NULL) == NULL".ptr)
    } else {
        0
    }

    (__local_sa = sortedarray_new((0 as c_uint), Some(int_compare)))

    if (((if not ((if __local_sa != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_new_free".ptr, c"test-sortedarray.c".ptr, (96 as c_int), c"sa != NULL".ptr)
    } else {
        0
    }

    unsafe { sortedarray_free(__local_sa) }

    unsafe { sortedarray_free((null as *mut _SortedArray)) }

    alloc_test_set_limit((0 as c_int))

    (__local_sa = sortedarray_new((0 as c_uint), Some(int_compare)))

    if (((if not ((if __local_sa == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_new_free".ptr, c"test-sortedarray.c".ptr, (105 as c_int), c"sa == NULL".ptr)
    } else {
        0
    }

    alloc_test_set_limit((-1 as c_int))

}

pub fn test_sortedarray_insert() writes allocation_limit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    if (((if not ((if unsafe { sortedarray_insert((null as *mut _SortedArray), null) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_insert".ptr, c"test-sortedarray.c".ptr, (114 as c_int), c"sortedarray_insert(NULL, NULL) == 0".ptr)
    } else {
        0
    }

    unsafe { check_sorted(__local_sa) }

    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_get() writes allocation_limit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    var __local_i: c_uint

    var __local_got: *mut c_int

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < unsafe { sortedarray_length(__local_sa) }: 1 else: 0) != 0) {
        (__local_got = ((unsafe { sortedarray_get(__local_sa, __local_i) } as *mut c_int)))

        if (((if not ((if __local_got != null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (129 as c_int), c"got != NULL".ptr)
        } else {
            0
        }

        if (((if not ((if (unsafe *__local_got) == sorted_test_values[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (130 as c_int), c"*got == sorted_test_values[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    if (((if not ((if unsafe { sortedarray_get((null as *mut _SortedArray), (0 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (134 as c_int), c"sortedarray_get(NULL, 0) == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_get(__local_sa, (unsafe { sortedarray_length(__local_sa) } as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (135 as c_int), c"sortedarray_get(sa, sortedarray_length(sa)) == NULL".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_get(__local_sa, (999999 as c_uint)) } == null: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_get".ptr, c"test-sortedarray.c".ptr, (136 as c_int), c"sortedarray_get(sa, 999999) == NULL".ptr)
    } else {
        0
    }

    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_remove() writes allocation_limit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    var __local_i: c_uint

    var __local_check_idx: c_uint


    var __local_got: *mut c_int

    if (((if not ((if unsafe { sortedarray_remove_range(__local_sa, (95 as c_uint), (10 as c_uint)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (155 as c_int), c"sortedarray_remove_range(sa, REMOVE_IDX_3, REMOVE_IDX_3_LEN) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_remove_range(__local_sa, (57 as c_uint), (7 as c_uint)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (157 as c_int), c"sortedarray_remove_range(sa, REMOVE_IDX_2, REMOVE_IDX_2_LEN) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_remove(__local_sa, (23 as c_uint)) } != 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (158 as c_int), c"sortedarray_remove(sa, REMOVE_IDX_1) != 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_remove((null as *mut _SortedArray), (0 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (161 as c_int), c"sortedarray_remove(NULL, 0) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_remove(__local_sa, (unsafe { sortedarray_length(__local_sa) } as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (162 as c_int), c"sortedarray_remove(sa, sortedarray_length(sa)) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_remove_range(__local_sa, (unsafe { sortedarray_length(__local_sa) } as c_uint), (3 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (163 as c_int), c"sortedarray_remove_range(sa, sortedarray_length(sa), 3) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_remove(__local_sa, (999999 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (164 as c_int), c"sortedarray_remove(sa, 999999) == 0".ptr)
    } else {
        0
    }

    if (((if not ((if unsafe { sortedarray_remove_range(__local_sa, (999999 as c_uint), (44 as c_uint)) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (165 as c_int), c"sortedarray_remove_range(sa, 999999, 44) == 0".ptr)
    } else {
        0
    }

    unsafe { check_sorted(__local_sa) }

    if (((if not ((if unsafe { sortedarray_length(__local_sa) } == ((((((test_values.len() as c_ulong) -% (1 as c_ulong)) as c_ulong) -% (7 as c_ulong)) as c_ulong) -% (5 as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
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

        if (((if not ((if (unsafe *__local_got) == sorted_test_values[__local_check_idx]: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_remove".ptr, c"test-sortedarray.c".ptr, (180 as c_int), c"*got == sorted_test_values[check_idx]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_index_of() writes allocation_limit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    var __local_i: c_uint

    var __local_got_idx: c_int

    var __local_test_index: c_int


    if (((if not ((if unsafe { sortedarray_index_of((null as *mut _SortedArray), null) } == -1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_index_of".ptr, c"test-sortedarray.c".ptr, (192 as c_int), c"sortedarray_index_of(NULL, NULL) == -1".ptr)
    } else {
        0
    }

    (__local_test_index = ((999999 as c_int)))

    if (((if not ((if unsafe { sortedarray_index_of(__local_sa, ((&raw mut __local_test_index as *mut c_int) as *mut c_void)) } == -1: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_index_of".ptr, c"test-sortedarray.c".ptr, (196 as c_int), c"sortedarray_index_of(sa, &test_index) == -1".ptr)
    } else {
        0
    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((test_values.len() as c_ulong)): 1 else: 0) != 0) {
        (__local_got_idx = ((unsafe { sortedarray_index_of(__local_sa, (((&raw const sorted_test_values[__local_i] as *const c_int) as *mut c_int) as *mut c_void)) } as c_int)))

        if (((if not ((if sorted_test_values[__local_got_idx] == sorted_test_values[__local_i]: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"test_sortedarray_index_of".ptr, c"test-sortedarray.c".ptr, (201 as c_int), c"sorted_test_values[got_idx] == sorted_test_values[i]".ptr)
        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    unsafe { sortedarray_free(__local_sa) }

}

pub fn test_sortedarray_clear() writes allocation_limit {
    var __local_sa: *mut _SortedArray = generate_sortedarray()

    unsafe { sortedarray_clear(__local_sa) }

    if (((if not ((if unsafe { sortedarray_length(__local_sa) } == 0: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"test_sortedarray_clear".ptr, c"test-sortedarray.c".ptr, (212 as c_int), c"sortedarray_length(sa) == 0".ptr)
    } else {
        0
    }

    unsafe { sortedarray_free(__local_sa) }

}

pub unsafe fn main(__param_argc: c_int, __param_argv: *mut *mut i8) -> c_int writes allocation_limit {
    run_tests((&tests[0] as *mut extern "C" fn() -> Unit))

    return 0

}

var test_values: [c_int; 100] = [114812, 292972, 15252, 317887, 859422, 943227, 173673, 444396, 289730, 60903, 706503, 412815, (-13616 as c_int), 464193, 921380, 411002, 118983, 908936, 854842, 228639, 175174, 976812, 963457, 39332, 774021, 588784, 23511, 364428, 816641, 66433, 911779, 774060, 4340, (-46542 as c_int), 739951, 388501, 710893, 817647, 582295, 994147, 741106, 813303, 187471, 147041, 933029, 933029, 933029, 753121, 469556, 882575, 953070, 166462, (-25609 as c_int), 766862, 199480, 269323, 636875, 49809, 633426, 153528, 325532, 15949, 418818, 541376, 950242, 824802, 67683, 583518, 91497, 832324, 591778, 296072, 96531, 867789, 126879, 716791, 685326, 826331, 677729, 496589, (-6777 as c_int), 667244, 446665, 560213, 727965, 678769, 428202, 761385, 130289, 724727, 300728, 734018, 493283, 770024, 472722, 123696, 301295, 511707, 383382, 151978]
var sorted_test_values: [c_int; 100] = [(-46542 as c_int), (-25609 as c_int), (-13616 as c_int), (-6777 as c_int), 4340, 15252, 15949, 23511, 39332, 49809, 60903, 66433, 67683, 91497, 96531, 114812, 118983, 123696, 126879, 130289, 147041, 151978, 153528, 166462, 173673, 175174, 187471, 199480, 228639, 269323, 289730, 292972, 296072, 300728, 301295, 317887, 325532, 364428, 383382, 388501, 411002, 412815, 418818, 428202, 444396, 446665, 464193, 469556, 472722, 493283, 496589, 511707, 541376, 560213, 582295, 583518, 588784, 591778, 633426, 636875, 667244, 677729, 678769, 685326, 706503, 710893, 716791, 724727, 727965, 734018, 739951, 741106, 753121, 761385, 766862, 770024, 774021, 774060, 813303, 816641, 817647, 824802, 826331, 832324, 854842, 859422, 867789, 882575, 908936, 911779, 921380, 933029, 933029, 933029, 943227, 950242, 953070, 963457, 976812, 994147]
var tests: [Option[extern "C" fn() -> Unit]; 7] = [Some(test_sortedarray_new_free), Some(test_sortedarray_insert), Some(test_sortedarray_get), Some(test_sortedarray_remove), Some(test_sortedarray_index_of), Some(test_sortedarray_clear), null]
