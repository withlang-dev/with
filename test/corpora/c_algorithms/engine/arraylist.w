// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.option

pub fn arraylist_new(__param_length: u32) -> *mut _ArrayList writes allocation_limit {
    var __local_length = __param_length
    var __local_new_arraylist: *mut _ArrayList

    if ((if __local_length <= 0: 1 else: 0) != 0) {
        (__local_length = ((16 as u32)))

    }

    (__local_new_arraylist = ((alloc_test_malloc((sizeof[_ArrayList]() as u64)) as *mut _ArrayList)))

    if ((if __local_new_arraylist == null: 1 else: 0) != 0) {
        return ((null as *mut _ArrayList))

    }

    ((unsafe *__local_new_arraylist)._alloced = __local_length)

    ((unsafe *__local_new_arraylist).length = ((0 as u32)))

    ((unsafe *__local_new_arraylist).data = ((alloc_test_malloc((((__local_length as u64) *% (sizeof[usize]() as u64)) as u64)) as *mut *mut c_void)))

    if ((if (unsafe *__local_new_arraylist).data == null: 1 else: 0) != 0) {
        unsafe { alloc_test_free((__local_new_arraylist as *mut c_void)) }

        return ((null as *mut _ArrayList))

    }

    return __local_new_arraylist

}

pub unsafe fn arraylist_free(__param_arraylist: *mut _ArrayList) {
    if ((if __param_arraylist != null: 1 else: 0) != 0) {
        alloc_test_free(((*__param_arraylist).data as *mut c_void))

        alloc_test_free((__param_arraylist as *mut c_void))

    }

}

pub unsafe fn arraylist_append(__param_arraylist: *mut _ArrayList, __param_data: *mut c_void) -> i32 writes allocation_limit {
    return arraylist_insert(__param_arraylist, (*__param_arraylist).length, __param_data)

}

pub unsafe fn arraylist_prepend(__param_arraylist: *mut _ArrayList, __param_data: *mut c_void) -> i32 writes allocation_limit {
    return arraylist_insert(__param_arraylist, (0 as u32), __param_data)

}

pub unsafe fn arraylist_remove(__param_arraylist: *mut _ArrayList, __param_index: u32) {
    arraylist_remove_range(__param_arraylist, __param_index, (1 as u32))

}

pub unsafe fn arraylist_remove_range(__param_arraylist: *mut _ArrayList, __param_index: u32, __param_length: u32) {
    var __ci_expr_logic_0: i32

    if ((if __param_index > (*__param_arraylist).length: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if ((__param_index as u32) +% (__param_length as u32)) > (*__param_arraylist).length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return

    }


    with_memmove(((((&raw const ((*__param_arraylist).data[__param_index]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const ((*__param_arraylist).data[((__param_index as u32) +% (__param_length as u32))]) as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), (((((((*__param_arraylist).length as u32) -% (((__param_index as u32) +% (__param_length as u32)) as u32)) as u64) *% (sizeof[usize]() as u64)) as u64) as i64))

    ((*__param_arraylist).length = ((*__param_arraylist).length -% __param_length))

}

pub unsafe fn arraylist_insert(__param_arraylist: *mut _ArrayList, __param_index: u32, __param_data: *mut c_void) -> i32 writes allocation_limit {
    if ((if __param_index > (*__param_arraylist).length: 1 else: 0) != 0) {
        return 0

    }

    if ((if (((*__param_arraylist).length as u32) +% (1 as u32)) > (*__param_arraylist)._alloced: 1 else: 0) != 0) {
        if ((if not (arraylist_enlarge(__param_arraylist) != 0): 1 else: 0) != 0) {
            return 0

        }

    }

    with_memmove(((((&raw const ((*__param_arraylist).data[((__param_index as u32) +% (1 as u32))]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const ((*__param_arraylist).data[__param_index]) as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), (((((((*__param_arraylist).length as u32) -% (__param_index as u32)) as u64) *% (sizeof[usize]() as u64)) as u64) as i64))

    (((*__param_arraylist).data[__param_index]) = __param_data)

    ((*__param_arraylist).length = ((*__param_arraylist).length +% 1))

    return 1

}

pub unsafe fn arraylist_index_of(__param_arraylist: *mut _ArrayList, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32, __param_data: *mut c_void) -> i32 {
    var __local_i: u32

    (__local_i = ((0 as u32)))

    while ((if __local_i < (*__param_arraylist).length: 1 else: 0) != 0) {
        if ((if __param_callback(((*__param_arraylist).data[__local_i]), __param_data) != 0: 1 else: 0) != 0) {
            return ((__local_i as i32))

        }


        (__local_i = (__local_i +% 1))

    }


    return -1

}

pub unsafe fn arraylist_clear(__param_arraylist: *mut _ArrayList) {
    ((*__param_arraylist).length = ((0 as u32)))

}

pub unsafe fn arraylist_sort(__param_arraylist: *mut _ArrayList, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32) {
    arraylist_sort_internal((*__param_arraylist).data, (*__param_arraylist).length, Some(__param_compare_func))

}

unsafe fn arraylist_enlarge(__param_arraylist: *mut _ArrayList) -> i32 {
    var __local_data: *mut *mut c_void

    var __local_newsize: u32

    (__local_newsize = (((((*__param_arraylist)._alloced as u32) *% (2 as u32)) as u32)))

    (__local_data = ((alloc_test_realloc(((*__param_arraylist).data as *mut c_void), (((sizeof[usize]() as u64) *% (__local_newsize as u64)) as u64)) as *mut *mut c_void)))

    if ((if __local_data == null: 1 else: 0) != 0) {
        return 0

    }
    ((*__param_arraylist).data = __local_data)

    ((*__param_arraylist)._alloced = __local_newsize)

    return 1


}

unsafe fn arraylist_sort_internal(__param_list_data: *mut *mut c_void, __param_list_length: u32, __param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> Unit {
    var __local_pivot: *mut c_void

    var __local_tmp: *mut c_void

    var __local_i: u32

    var __local_list1_length: u32

    var __local_list2_length: u32

    if ((if __param_list_length <= 1: 1 else: 0) != 0) {
        return

    }

    (__local_pivot = (__param_list_data[((__param_list_length as u32) -% (1 as u32))]))

    (__local_list1_length = ((0 as u32)))

    (__local_i = ((0 as u32)))

    while ((if __local_i < ((__param_list_length as u32) -% (1 as u32)): 1 else: 0) != 0) {
        if ((if __param_compare_func.unwrap()((__param_list_data[__local_i]), __local_pivot) < 0: 1 else: 0) != 0) {
            (__local_tmp = (__param_list_data[__local_i]))

            ((__param_list_data[__local_i]) = (__param_list_data[__local_list1_length]))

            ((__param_list_data[__local_list1_length]) = __local_tmp)

            (__local_list1_length = (__local_list1_length +% 1))

        } else {
            0
        }


        (__local_i = (__local_i +% 1))

    }


    (__local_list2_length = ((((((__param_list_length as u32) -% (__local_list1_length as u32)) as u32) -% (1 as u32)) as u32)))

    ((__param_list_data[((__param_list_length as u32) -% (1 as u32))]) = (__param_list_data[__local_list1_length]))

    ((__param_list_data[__local_list1_length]) = __local_pivot)

    arraylist_sort_internal(__param_list_data, __local_list1_length, __param_compare_func)

    arraylist_sort_internal(((&raw const (__param_list_data[((__local_list1_length as u32) +% (1 as u32))]) as *const *mut c_void) as *mut *mut c_void), __local_list2_length, __param_compare_func)

}
