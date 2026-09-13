// Migrated from C
use std.c_algorithms.defs

pub unsafe fn list_free(__param_list: *mut _ListEntry) -> Unit {
    var __local_entry: *mut _ListEntry

    (__local_entry = __param_list)

    while ((if __local_entry != null: 1 else: 0) != 0) {
        var __local_next: *mut _ListEntry

        (__local_next = (unsafe *__local_entry).next)

        with_free(((__local_entry as *mut c_void) as *mut u8))

        (__local_entry = __local_next)

    }

}

pub unsafe fn list_prepend(__param_list: *mut *mut _ListEntry, __param_data: *mut c_void) -> *mut _ListEntry {
    var __local_newentry: *mut _ListEntry

    if ((if __param_list == null: 1 else: 0) != 0) {
        return ((null as *mut _ListEntry))

    }

    (__local_newentry = (((with_alloc(((sizeof[_ListEntry]() as c_ulong) as i64)) as *mut c_void) as *mut _ListEntry)))

    if ((if __local_newentry == null: 1 else: 0) != 0) {
        return ((null as *mut _ListEntry))

    }

    ((unsafe *__local_newentry).data = __param_data)

    if ((if (unsafe *__param_list) != null: 1 else: 0) != 0) {
        ((unsafe *(unsafe *__param_list)).prev = __local_newentry)

    }

    ((unsafe *__local_newentry).prev = ((null as *mut _ListEntry)))

    ((unsafe *__local_newentry).next = (unsafe *__param_list))

    ((unsafe *__param_list) = __local_newentry)

    return __local_newentry

}

pub unsafe fn list_append(__param_list: *mut *mut _ListEntry, __param_data: *mut c_void) -> *mut _ListEntry {
    var __local_rover: *mut _ListEntry

    var __local_newentry: *mut _ListEntry

    if ((if __param_list == null: 1 else: 0) != 0) {
        return ((null as *mut _ListEntry))

    }

    (__local_newentry = (((with_alloc(((sizeof[_ListEntry]() as c_ulong) as i64)) as *mut c_void) as *mut _ListEntry)))

    if ((if __local_newentry == null: 1 else: 0) != 0) {
        return ((null as *mut _ListEntry))

    }

    ((unsafe *__local_newentry).data = __param_data)

    ((unsafe *__local_newentry).next = ((null as *mut _ListEntry)))

    if ((if (unsafe *__param_list) == null: 1 else: 0) != 0) {
        ((unsafe *__param_list) = __local_newentry)

        ((unsafe *__local_newentry).prev = ((null as *mut _ListEntry)))

    } else {
        (__local_rover = (unsafe *__param_list))

        while ((if (unsafe *__local_rover).next != null: 1 else: 0) != 0) {

            (__local_rover = (unsafe *__local_rover).next)

        }


        ((unsafe *__local_newentry).prev = __local_rover)

        ((unsafe *__local_rover).next = __local_newentry)

    }

    return __local_newentry

}

pub unsafe fn list_prev(__param_listentry: *mut _ListEntry) -> *mut _ListEntry {
    if ((if __param_listentry == null: 1 else: 0) != 0) {
        return ((null as *mut _ListEntry))

    }

    return (unsafe *__param_listentry).prev

}

pub unsafe fn list_next(__param_listentry: *mut _ListEntry) -> *mut _ListEntry {
    if ((if __param_listentry == null: 1 else: 0) != 0) {
        return ((null as *mut _ListEntry))

    }

    return (unsafe *__param_listentry).next

}

pub unsafe fn list_data(__param_listentry: *mut _ListEntry) -> *mut c_void {
    if ((if __param_listentry == null: 1 else: 0) != 0) {
        return list_null_value

    }

    return (unsafe *__param_listentry).data

}

pub unsafe fn list_set_data(__param_listentry: *mut _ListEntry, __param_value: *mut c_void) -> Unit {
    if ((if __param_listentry != null: 1 else: 0) != 0) {
        ((unsafe *__param_listentry).data = __param_value)

    }

}

pub unsafe fn list_nth_entry(__param_list: *mut _ListEntry, __param_n: c_uint) -> *mut _ListEntry {
    var __local_entry: *mut _ListEntry

    var __local_i: c_uint

    (__local_entry = __param_list)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if __local_entry == null: 1 else: 0) != 0) {
            return ((null as *mut _ListEntry))

        }

        (__local_entry = (unsafe *__local_entry).next)


        (__local_i = (__local_i +% 1))

    }


    return __local_entry

}

pub unsafe fn list_nth_data(__param_list: *mut _ListEntry, __param_n: c_uint) -> *mut c_void {
    var __local_entry: *mut _ListEntry

    (__local_entry = list_nth_entry(__param_list, __param_n))

    if ((if __local_entry == null: 1 else: 0) != 0) {
        return list_null_value

    }
    return (unsafe *__local_entry).data


}

pub unsafe fn list_length(__param_list: *mut _ListEntry) -> c_uint {
    var __local_entry: *mut _ListEntry

    var __local_length: c_uint

    (__local_length = ((0 as c_uint)))

    (__local_entry = __param_list)

    while ((if __local_entry != null: 1 else: 0) != 0) {
        (__local_length = (__local_length +% 1))

        (__local_entry = (unsafe *__local_entry).next)

    }

    return __local_length

}

pub unsafe fn list_to_array(__param_list: *mut _ListEntry) -> *mut *mut c_void {
    var __local_rover: *mut _ListEntry

    var __local_array: *mut *mut c_void

    var __local_length: c_uint

    var __local_i: c_uint

    (__local_length = ((list_length(__param_list) as c_uint)))

    (__local_array = (((with_alloc(((((sizeof[usize]() as c_ulong) *% (__local_length as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

    if ((if __local_array == null: 1 else: 0) != 0) {
        return ((null as *mut *mut c_void))

    }

    (__local_rover = __param_list)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_length: 1 else: 0) != 0) {
        ((unsafe __local_array[__local_i]) = (unsafe *__local_rover).data)

        (__local_rover = (unsafe *__local_rover).next)


        (__local_i = (__local_i +% 1))

    }


    return __local_array

}

pub unsafe fn list_remove_entry(__param_list: *mut *mut _ListEntry, __param_entry: *mut _ListEntry) -> c_int {
    var __ci_expr_logic_1: c_int

    var __ci_expr_logic_0: c_int

    if ((if __param_list == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_list) == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if __param_entry == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return 0

    }


    if ((if (unsafe *__param_entry).prev == null: 1 else: 0) != 0) {
        ((unsafe *__param_list) = (unsafe *__param_entry).next)

        if ((if (unsafe *__param_entry).next != null: 1 else: 0) != 0) {
            ((unsafe *(unsafe *__param_entry).next).prev = ((null as *mut _ListEntry)))

        }

    } else {
        ((unsafe *(unsafe *__param_entry).prev).next = (unsafe *__param_entry).next)

        if ((if (unsafe *__param_entry).next != null: 1 else: 0) != 0) {
            ((unsafe *(unsafe *__param_entry).next).prev = (unsafe *__param_entry).prev)

        }

    }

    with_free(((__param_entry as *mut c_void) as *mut u8))

    return 1

}

pub unsafe fn list_remove_data(__param_list: *mut *mut _ListEntry, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, __param_data: *mut c_void) -> c_uint {
    var __local_entries_removed: c_uint

    var __local_rover: *mut _ListEntry

    var __local_next: *mut _ListEntry

    var __ci_expr_logic_0: c_int

    if ((if __param_list == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_callback == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 0

    }


    (__local_entries_removed = ((0 as c_uint)))

    (__local_rover = (unsafe *__param_list))

    while ((if __local_rover != null: 1 else: 0) != 0) {
        (__local_next = (unsafe *__local_rover).next)

        if (__param_callback((unsafe *__local_rover).data, __param_data) != 0) {
            if ((if (unsafe *__local_rover).prev == null: 1 else: 0) != 0) {
                ((unsafe *__param_list) = (unsafe *__local_rover).next)

            } else {
                ((unsafe *(unsafe *__local_rover).prev).next = (unsafe *__local_rover).next)

            }

            if ((if (unsafe *__local_rover).next != null: 1 else: 0) != 0) {
                ((unsafe *(unsafe *__local_rover).next).prev = (unsafe *__local_rover).prev)

            }

            with_free(((__local_rover as *mut c_void) as *mut u8))

            (__local_entries_removed = (__local_entries_removed +% 1))

        }

        (__local_rover = __local_next)

    }

    return __local_entries_removed

}

pub unsafe fn list_sort(__param_list: *mut *mut _ListEntry, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> Unit {
    list_sort_internal(__param_list, __param_compare_func)

}

pub unsafe fn list_find_data(__param_list: *mut _ListEntry, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, __param_data: *mut c_void) -> *mut _ListEntry {
    var __local_rover: *mut _ListEntry

    (__local_rover = __param_list)

    while ((if __local_rover != null: 1 else: 0) != 0) {
        if ((if __param_callback((unsafe *__local_rover).data, __param_data) != 0: 1 else: 0) != 0) {
            return __local_rover

        }


        (__local_rover = (unsafe *__local_rover).next)

    }


    return ((null as *mut _ListEntry))

}

pub unsafe fn list_iterate(__param_list: *mut *mut _ListEntry, __param_iter: *mut _ListIterator) -> Unit {
    ((unsafe *__param_iter).prev_next = __param_list)

    ((unsafe *__param_iter).current = ((null as *mut _ListEntry)))

}

pub unsafe fn list_iter_has_more(__param_iter: *mut _ListIterator) -> c_int {
    var __ci_expr_logic_0: c_int

    if ((if (unsafe *__param_iter).current == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_iter).current != (unsafe *((unsafe *__param_iter).prev_next)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return (if (unsafe *((unsafe *__param_iter).prev_next)) != null: 1 else: 0)

    }
    return (if (unsafe *(unsafe *__param_iter).current).next != null: 1 else: 0)



}

pub unsafe fn list_iter_next(__param_iter: *mut _ListIterator) -> *mut c_void {
    var __ci_expr_logic_0: c_int

    if ((if (unsafe *__param_iter).current == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_iter).current != (unsafe *((unsafe *__param_iter).prev_next)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((unsafe *__param_iter).current = (unsafe *((unsafe *__param_iter).prev_next)))

    } else {
        ((unsafe *__param_iter).prev_next = (((&raw const (unsafe *(unsafe *__param_iter).current).next as *const *mut _ListEntry) as *mut *mut _ListEntry)))

        ((unsafe *__param_iter).current = (unsafe *(unsafe *__param_iter).current).next)

    }


    if ((if (unsafe *__param_iter).current == null: 1 else: 0) != 0) {
        return list_null_value

    }
    return (unsafe *(unsafe *__param_iter).current).data


}

pub unsafe fn list_iter_remove(__param_iter: *mut _ListIterator) -> Unit {
    var __ci_expr_logic_0: c_int

    if ((if (unsafe *__param_iter).current == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (unsafe *__param_iter).current != (unsafe *((unsafe *__param_iter).prev_next)): 1 else: 0) != 0: 1 else: 0))
    }

    if (not (__ci_expr_logic_0 != 0)) {
        ((unsafe *((unsafe *__param_iter).prev_next)) = (unsafe *(unsafe *__param_iter).current).next)

        if ((if (unsafe *(unsafe *__param_iter).current).next != null: 1 else: 0) != 0) {
            ((unsafe *(unsafe *(unsafe *__param_iter).current).next).prev = (unsafe *(unsafe *__param_iter).current).prev)

        }

        with_free((((unsafe *__param_iter).current as *mut c_void) as *mut u8))

        ((unsafe *__param_iter).current = ((null as *mut _ListEntry)))

    }


}

unsafe fn list_sort_internal(__param_list: *mut *mut _ListEntry, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _ListEntry {
    var __local_pivot: *mut _ListEntry

    var __local_rover: *mut _ListEntry

    var __local_less_list: *mut _ListEntry

    var __local_more_list: *mut _ListEntry


    var __local_less_list_end: *mut _ListEntry

    var __local_more_list_end: *mut _ListEntry


    var __ci_expr_logic_0: c_int

    if ((if __param_list == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_compare_func == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((null as *mut _ListEntry))

    }


    var __ci_expr_logic_1: c_int

    if ((if (unsafe *__param_list) == null: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *(unsafe *__param_list)).next == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        return (unsafe *__param_list)

    }


    (__local_pivot = (unsafe *__param_list))

    (__local_less_list = ((null as *mut _ListEntry)))

    (__local_more_list = ((null as *mut _ListEntry)))

    (__local_rover = (unsafe *(unsafe *__param_list)).next)

    while ((if __local_rover != null: 1 else: 0) != 0) {
        var __local_next: *mut _ListEntry = (unsafe *__local_rover).next

        if ((if __param_compare_func((unsafe *__local_rover).data, (unsafe *__local_pivot).data) < 0: 1 else: 0) != 0) {
            ((unsafe *__local_rover).prev = ((null as *mut _ListEntry)))

            ((unsafe *__local_rover).next = __local_less_list)

            if ((if __local_less_list != null: 1 else: 0) != 0) {
                ((unsafe *__local_less_list).prev = __local_rover)

            }

            (__local_less_list = __local_rover)

        } else {
            ((unsafe *__local_rover).prev = ((null as *mut _ListEntry)))

            ((unsafe *__local_rover).next = __local_more_list)

            if ((if __local_more_list != null: 1 else: 0) != 0) {
                ((unsafe *__local_more_list).prev = __local_rover)

            }

            (__local_more_list = __local_rover)

        }

        (__local_rover = __local_next)

    }

    (__local_less_list_end = list_sort_internal((&raw mut __local_less_list as *mut *mut _ListEntry), __param_compare_func))

    (__local_more_list_end = list_sort_internal((&raw mut __local_more_list as *mut *mut _ListEntry), __param_compare_func))

    ((unsafe *__param_list) = __local_less_list)

    if ((if __local_less_list == null: 1 else: 0) != 0) {
        ((unsafe *__local_pivot).prev = ((null as *mut _ListEntry)))

        ((unsafe *__param_list) = __local_pivot)

    } else {
        ((unsafe *__local_pivot).prev = __local_less_list_end)

        ((unsafe *__local_less_list_end).next = __local_pivot)

    }

    ((unsafe *__local_pivot).next = __local_more_list)

    if ((if __local_more_list != null: 1 else: 0) != 0) {
        ((unsafe *__local_more_list).prev = __local_pivot)

    }

    if ((if __local_more_list == null: 1 else: 0) != 0) {
        return __local_pivot

    }
    return __local_more_list_end


}

let list_null_value: *mut c_void = null
