// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing

pub fn arraylist_new(__param_length: c_uint) -> *mut _ArrayList {
    var __local_length = __param_length
    var __local_new_arraylist: *mut _ArrayList

    if ((if __local_length <= 0: 1 else: 0) != 0) {
        (__local_length = ((16 as c_uint)))

    }

    (__local_new_arraylist = ((alloc_test_malloc((sizeof[_ArrayList]() as c_ulong)) as *mut _ArrayList)))

    if ((if __local_new_arraylist == null: 1 else: 0) != 0) {
        return ((null as *mut _ArrayList))

    }

    ((unsafe *__local_new_arraylist)._alloced = __local_length)

    ((unsafe *__local_new_arraylist).length = ((0 as c_uint)))

    ((unsafe *__local_new_arraylist).data = ((alloc_test_malloc((((__local_length as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong)) as *mut *mut c_void)))

    if ((if (unsafe *__local_new_arraylist).data == null: 1 else: 0) != 0) {
        unsafe { alloc_test_free((__local_new_arraylist as *mut c_void)) }

        return ((null as *mut _ArrayList))

    }

    return __local_new_arraylist

}

pub unsafe fn arraylist_free(__param_arraylist: *mut _ArrayList) -> Unit {
    if ((if __param_arraylist != null: 1 else: 0) != 0) {
        alloc_test_free(((unsafe *__param_arraylist).data as *mut c_void))

        alloc_test_free((__param_arraylist as *mut c_void))

    }

}

pub unsafe fn arraylist_append(__param_arraylist: *mut _ArrayList, __param_data: *mut c_void) -> c_int {
    return arraylist_insert(__param_arraylist, (unsafe *__param_arraylist).length, __param_data)

}

pub unsafe fn arraylist_prepend(__param_arraylist: *mut _ArrayList, __param_data: *mut c_void) -> c_int {
    return arraylist_insert(__param_arraylist, (0 as c_uint), __param_data)

}

pub unsafe fn arraylist_remove(__param_arraylist: *mut _ArrayList, __param_index: c_uint) -> Unit {
    arraylist_remove_range(__param_arraylist, __param_index, (1 as c_uint))

}

pub unsafe fn arraylist_remove_range(__param_arraylist: *mut _ArrayList, __param_index: c_uint, __param_length: c_uint) -> Unit {
    var __ci_expr_logic_0: c_int

    if ((if __param_index > (unsafe *__param_arraylist).length: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if ((__param_index as c_uint) +% (__param_length as c_uint)) > (unsafe *__param_arraylist).length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return

    }


    with_memmove(((((&raw const (unsafe (unsafe *__param_arraylist).data[__param_index]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe (unsafe *__param_arraylist).data[((__param_index as c_uint) +% (__param_length as c_uint))]) as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), (((((((unsafe *__param_arraylist).length as c_uint) -% (((__param_index as c_uint) +% (__param_length as c_uint)) as c_uint)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong) as i64))

    ((unsafe *__param_arraylist).length = ((unsafe *__param_arraylist).length -% __param_length))

}

pub unsafe fn arraylist_insert(__param_arraylist: *mut _ArrayList, __param_index: c_uint, __param_data: *mut c_void) -> c_int {
    if ((if __param_index > (unsafe *__param_arraylist).length: 1 else: 0) != 0) {
        return 0

    }

    if ((if (((unsafe *__param_arraylist).length as c_uint) +% (1 as c_uint)) > (unsafe *__param_arraylist)._alloced: 1 else: 0) != 0) {
        if ((if not (arraylist_enlarge(__param_arraylist) != 0): 1 else: 0) != 0) {
            return 0

        }

    }

    with_memmove(((((&raw const (unsafe (unsafe *__param_arraylist).data[((__param_index as c_uint) +% (1 as c_uint))]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe (unsafe *__param_arraylist).data[__param_index]) as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), (((((((unsafe *__param_arraylist).length as c_uint) -% (__param_index as c_uint)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong) as i64))

    ((unsafe (unsafe *__param_arraylist).data[__param_index]) = __param_data)

    ((unsafe *__param_arraylist).length = ((unsafe *__param_arraylist).length +% 1))

    return 1

}

pub unsafe fn arraylist_index_of(__param_arraylist: *mut _ArrayList, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, __param_data: *mut c_void) -> c_int {
    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (unsafe *__param_arraylist).length: 1 else: 0) != 0) {
        if ((if __param_callback((unsafe (unsafe *__param_arraylist).data[__local_i]), __param_data) != 0: 1 else: 0) != 0) {
            return ((__local_i as c_int))

        }


        (__local_i = (__local_i +% 1))

    }


    return -1

}

pub unsafe fn arraylist_clear(__param_arraylist: *mut _ArrayList) -> Unit {
    ((unsafe *__param_arraylist).length = ((0 as c_uint)))

}

pub unsafe fn arraylist_sort(__param_arraylist: *mut _ArrayList, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> Unit {
    arraylist_sort_internal((unsafe *__param_arraylist).data, (unsafe *__param_arraylist).length, __param_compare_func)

}

unsafe fn arraylist_enlarge(__param_arraylist: *mut _ArrayList) -> c_int {
    var __local_data: *mut *mut c_void

    var __local_newsize: c_uint

    (__local_newsize = (((((unsafe *__param_arraylist)._alloced as c_uint) *% (2 as c_uint)) as c_uint)))

    (__local_data = ((alloc_test_realloc(((unsafe *__param_arraylist).data as *mut c_void), (((sizeof[usize]() as c_ulong) *% (__local_newsize as c_ulong)) as c_ulong)) as *mut *mut c_void)))

    if ((if __local_data == null: 1 else: 0) != 0) {
        return 0

    }
    ((unsafe *__param_arraylist).data = __local_data)

    ((unsafe *__param_arraylist)._alloced = __local_newsize)

    return 1


}

unsafe fn arraylist_sort_internal(__param_list_data: *mut *mut c_void, __param_list_length: c_uint, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> Unit {
    var __local_pivot: *mut c_void

    var __local_tmp: *mut c_void

    var __local_i: c_uint

    var __local_list1_length: c_uint

    var __local_list2_length: c_uint

    if ((if __param_list_length <= 1: 1 else: 0) != 0) {
        return

    }

    (__local_pivot = (unsafe __param_list_data[((__param_list_length as c_uint) -% (1 as c_uint))]))

    (__local_list1_length = ((0 as c_uint)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < ((__param_list_length as c_uint) -% (1 as c_uint)): 1 else: 0) != 0) {
        if ((if __param_compare_func((unsafe __param_list_data[__local_i]), __local_pivot) < 0: 1 else: 0) != 0) {
            (__local_tmp = (unsafe __param_list_data[__local_i]))

            ((unsafe __param_list_data[__local_i]) = (unsafe __param_list_data[__local_list1_length]))

            ((unsafe __param_list_data[__local_list1_length]) = __local_tmp)

            (__local_list1_length = (__local_list1_length +% 1))

        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_list2_length = ((((((__param_list_length as c_uint) -% (__local_list1_length as c_uint)) as c_uint) -% (1 as c_uint)) as c_uint)))

    ((unsafe __param_list_data[((__param_list_length as c_uint) -% (1 as c_uint))]) = (unsafe __param_list_data[__local_list1_length]))

    ((unsafe __param_list_data[__local_list1_length]) = __local_pivot)

    arraylist_sort_internal(__param_list_data, __local_list1_length, __param_compare_func)

    arraylist_sort_internal(((&raw const (unsafe __param_list_data[((__local_list1_length as c_uint) +% (1 as c_uint))]) as *const *mut c_void) as *mut *mut c_void), __local_list2_length, __param_compare_func)

}
