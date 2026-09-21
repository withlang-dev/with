// Migrated from C
use std.c_algorithms.defs

pub unsafe fn sortedarray_get(__param_array: *mut _SortedArray, __param_i: c_uint) -> *mut c_void {
    var __ci_expr_logic_0: c_int

    if ((if __param_array == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_i >= (*__param_array).length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return sortedarray_null_value

    }


    return ((((*__param_array).data[__param_i]) as *mut c_void))

}

pub unsafe fn sortedarray_length(__param_array: *mut _SortedArray) -> c_uint {
    return (*__param_array).length

}

pub fn sortedarray_new(__param_length: c_uint, __param_cmp_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _SortedArray {
    var __local_length = __param_length
    var __local_array: *mut *mut c_void

    var __local_sortedarray: *mut _SortedArray

    if ((if __param_cmp_func == null: 1 else: 0) != 0) {
        return ((null as *mut _SortedArray))

    }

    if ((if __local_length == 0: 1 else: 0) != 0) {
        (__local_length = ((16 as c_uint)))

    }

    (__local_array = (((unsafe { with_alloc(((((sizeof[usize]() as c_ulong) *% (__local_length as c_ulong)) as c_ulong) as i64)) } as *mut c_void) as *mut *mut c_void)))

    if ((if __local_array == null: 1 else: 0) != 0) {
        return ((null as *mut _SortedArray))

    }

    (__local_sortedarray = (((unsafe { with_alloc(((sizeof[_SortedArray]() as c_ulong) as i64)) } as *mut c_void) as *mut _SortedArray)))

    if ((if __local_sortedarray == null: 1 else: 0) != 0) {
        unsafe { with_free(((__local_array as *mut c_void) as *mut u8)) }

        return ((null as *mut _SortedArray))

    }

    ((unsafe *__local_sortedarray).data = __local_array)

    ((unsafe *__local_sortedarray).length = ((0 as c_uint)))

    ((unsafe *__local_sortedarray)._alloced = __local_length)

    ((unsafe *__local_sortedarray).cmp_func = __param_cmp_func)

    return __local_sortedarray

}

pub unsafe fn sortedarray_free(__param_sortedarray: *mut _SortedArray) -> Unit {
    if ((if __param_sortedarray != null: 1 else: 0) != 0) {
        with_free((((*__param_sortedarray).data as *mut c_void) as *mut u8))

        with_free(((__param_sortedarray as *mut c_void) as *mut u8))

    }

}

pub unsafe fn sortedarray_remove(__param_sortedarray: *mut _SortedArray, __param_index: c_uint) -> c_int {
    return sortedarray_remove_range(__param_sortedarray, __param_index, (1 as c_uint))

}

pub unsafe fn sortedarray_remove_range(__param_sortedarray: *mut _SortedArray, __param_index: c_uint, __param_length: c_uint) -> c_int {
    var __local_length = __param_length
    var __ci_expr_logic_0: c_int

    if ((if __param_sortedarray == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_index >= (*__param_sortedarray).length: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 0

    }


    if ((if ((__param_index as c_uint) +% (__local_length as c_uint)) > (*__param_sortedarray).length: 1 else: 0) != 0) {
        (__local_length = (((((*__param_sortedarray).length as c_uint) -% (__param_index as c_uint)) as c_uint)))

    }

    with_memmove(((((&raw const ((*__param_sortedarray).data[__param_index]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const ((*__param_sortedarray).data[((__param_index as c_uint) +% (__local_length as c_uint))]) as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), (((((((*__param_sortedarray).length as c_uint) -% (((__param_index as c_uint) +% (__local_length as c_uint)) as c_uint)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong) as i64))

    ((*__param_sortedarray).length = ((*__param_sortedarray).length -% __local_length))

    return 1

}

pub unsafe fn sortedarray_insert(__param_sortedarray: *mut _SortedArray, __param_data: *mut c_void) -> c_int {
    var __local_data = __param_data
    var __local_left: c_uint

    var __local_right: c_uint

    var __local_index: c_uint


    var __local_order: c_int

    if ((if __param_sortedarray == null: 1 else: 0) != 0) {
        return 0

    }

    (__local_left = ((0 as c_uint)))

    (__local_right = (*__param_sortedarray).length)

    (__local_index = ((0 as c_uint)))

    var __ci_expr_ternary_0: c_uint = 0

    if ((if __local_right > 1: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = __local_right)
    } else {
        (__ci_expr_ternary_0 = ((0 as c_uint)))
    }

    (__local_right = __ci_expr_ternary_0)


    while ((if __local_left != __local_right: 1 else: 0) != 0) {
        (__local_index = ((((((__local_left as c_uint) +% (__local_right as c_uint)) as c_uint) / (2 as c_uint)) as c_uint)))

        (__local_order = (((*__param_sortedarray).cmp_func(__local_data, ((*__param_sortedarray).data[__local_index])) as c_int)))

        if ((if __local_order < 0: 1 else: 0) != 0) {
            (__local_right = __local_index)

        } else {
            if ((if __local_order > 0: 1 else: 0) != 0) {
                (__local_left = ((((__local_index as c_uint) +% (1 as c_uint)) as c_uint)))

            } else {
                break

            }
        }

    }

    var __ci_expr_logic_1: c_int = 0

    if ((if (*__param_sortedarray).length > 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if (*__param_sortedarray).cmp_func(__local_data, ((*__param_sortedarray).data[__local_index])) > 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__local_index = (__local_index +% 1))

    }


    if ((if (((*__param_sortedarray).length as c_uint) +% (1 as c_uint)) > (*__param_sortedarray)._alloced: 1 else: 0) != 0) {
        var __local_newsize: c_uint

        var __local_data_1: *mut *mut c_void

        (__local_newsize = (((((*__param_sortedarray)._alloced as c_uint) *% (2 as c_uint)) as c_uint)))

        (__local_data_1 = (((with_realloc((((*__param_sortedarray).data as *mut c_void) as *mut u8), (0 as i64), ((((sizeof[usize]() as c_ulong) *% (__local_newsize as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

        if ((if __local_data_1 == null: 1 else: 0) != 0) {
            return 0

        }
        ((*__param_sortedarray).data = __local_data_1)

        ((*__param_sortedarray)._alloced = __local_newsize)


    }

    with_memmove(((((&raw const ((*__param_sortedarray).data[((__local_index as c_uint) +% (1 as c_uint))]) as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const ((*__param_sortedarray).data[__local_index]) as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), (((((((*__param_sortedarray).length as c_uint) -% (__local_index as c_uint)) as c_ulong) *% (sizeof[usize]() as c_ulong)) as c_ulong) as i64))

    (((*__param_sortedarray).data[__local_index]) = __local_data)

    ((*__param_sortedarray).length = ((*__param_sortedarray).length +% 1))

    return 1

}

pub unsafe fn sortedarray_index_of(__param_sortedarray: *mut _SortedArray, __param_data: *mut c_void) -> c_int {
    var __local_left: c_uint

    var __local_right: c_uint

    var __local_index: c_uint


    var __local_order: c_int

    if ((if __param_sortedarray == null: 1 else: 0) != 0) {
        return -1

    }

    (__local_left = ((0 as c_uint)))

    (__local_right = (*__param_sortedarray).length)

    (__local_index = ((0 as c_uint)))

    var __ci_expr_ternary_0: c_uint = 0

    if ((if __local_right > 1: 1 else: 0) != 0) {
        (__ci_expr_ternary_0 = __local_right)
    } else {
        (__ci_expr_ternary_0 = ((0 as c_uint)))
    }

    (__local_right = __ci_expr_ternary_0)


    while ((if __local_left != __local_right: 1 else: 0) != 0) {
        (__local_index = ((((((__local_left as c_uint) +% (__local_right as c_uint)) as c_uint) / (2 as c_uint)) as c_uint)))

        (__local_order = (((*__param_sortedarray).cmp_func(__param_data, ((*__param_sortedarray).data[__local_index])) as c_int)))

        if ((if __local_order < 0: 1 else: 0) != 0) {
            (__local_right = __local_index)

        } else {
            if ((if __local_order > 0: 1 else: 0) != 0) {
                (__local_left = ((((__local_index as c_uint) +% (1 as c_uint)) as c_uint)))

            } else {
                return ((__local_index as c_int))

            }
        }

    }

    return -1

}

pub unsafe fn sortedarray_clear(__param_sortedarray: *mut _SortedArray) -> Unit {
    ((*__param_sortedarray).length = ((0 as c_uint)))

}

let sortedarray_null_value: *mut c_void = null
