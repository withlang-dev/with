// Migrated from C
use std.c_algorithms.defs

pub unsafe fn slist_free(__param_list: *mut _SListEntry) -> Unit {
    var __local_entry: *mut _SListEntry

    (__local_entry = __param_list)

    while ((if __local_entry != null: 1 else: 0) != 0) {
        var __local_next: *mut _SListEntry

        (__local_next = (*__local_entry).next)

        with_free(((__local_entry as *mut c_void) as *mut u8))

        (__local_entry = __local_next)

    }

}

pub unsafe fn slist_prepend(__param_list: *mut *mut _SListEntry, __param_data: *mut c_void) -> *mut _SListEntry {
    var __local_newentry: *mut _SListEntry

    (__local_newentry = (((with_alloc(((sizeof[_SListEntry]() as c_ulong) as i64)) as *mut c_void) as *mut _SListEntry)))

    if ((if __local_newentry == null: 1 else: 0) != 0) {
        return ((null as *mut _SListEntry))

    }

    ((*__local_newentry).data = __param_data)

    ((*__local_newentry).next = (*__param_list))

    ((*__param_list) = __local_newentry)

    return __local_newentry

}

pub unsafe fn slist_append(__param_list: *mut *mut _SListEntry, __param_data: *mut c_void) -> *mut _SListEntry {
    var __local_rover: *mut _SListEntry

    var __local_newentry: *mut _SListEntry

    (__local_newentry = (((with_alloc(((sizeof[_SListEntry]() as c_ulong) as i64)) as *mut c_void) as *mut _SListEntry)))

    if ((if __local_newentry == null: 1 else: 0) != 0) {
        return ((null as *mut _SListEntry))

    }

    ((*__local_newentry).data = __param_data)

    ((*__local_newentry).next = ((null as *mut _SListEntry)))

    if ((if (*__param_list) == null: 1 else: 0) != 0) {
        ((*__param_list) = __local_newentry)

    } else {
        (__local_rover = (*__param_list))

        while ((if (*__local_rover).next != null: 1 else: 0) != 0) {

            (__local_rover = (*__local_rover).next)

        }


        ((*__local_rover).next = __local_newentry)

    }

    return __local_newentry

}

pub unsafe fn slist_next(__param_listentry: *mut _SListEntry) -> *mut _SListEntry {
    return (*__param_listentry).next

}

pub unsafe fn slist_data(__param_listentry: *mut _SListEntry) -> *mut c_void {
    return (*__param_listentry).data

}

pub unsafe fn slist_set_data(__param_listentry: *mut _SListEntry, __param_data: *mut c_void) -> Unit {
    if ((if __param_listentry != null: 1 else: 0) != 0) {
        ((*__param_listentry).data = __param_data)

    }

}

pub unsafe fn slist_nth_entry(__param_list: *mut _SListEntry, __param_n: c_uint) -> *mut _SListEntry {
    var __local_entry: *mut _SListEntry

    var __local_i: c_uint

    (__local_entry = __param_list)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        if ((if __local_entry == null: 1 else: 0) != 0) {
            return ((null as *mut _SListEntry))

        }

        (__local_entry = (*__local_entry).next)


        (__local_i = (__local_i +% 1))

    }


    return __local_entry

}

pub unsafe fn slist_nth_data(__param_list: *mut _SListEntry, __param_n: c_uint) -> *mut c_void {
    var __local_entry: *mut _SListEntry

    (__local_entry = slist_nth_entry(__param_list, __param_n))

    if ((if __local_entry == null: 1 else: 0) != 0) {
        return slist_null_value

    }
    return (*__local_entry).data


}

pub unsafe fn slist_length(__param_list: *mut _SListEntry) -> c_uint {
    var __local_entry: *mut _SListEntry

    var __local_length: c_uint

    (__local_length = ((0 as c_uint)))

    (__local_entry = __param_list)

    while ((if __local_entry != null: 1 else: 0) != 0) {
        (__local_length = (__local_length +% 1))

        (__local_entry = (*__local_entry).next)

    }

    return __local_length

}

pub unsafe fn slist_to_array(__param_list: *mut _SListEntry) -> *mut *mut c_void {
    var __local_rover: *mut _SListEntry

    var __local_array: *mut *mut c_void

    var __local_length: c_uint

    var __local_i: c_uint

    (__local_length = ((slist_length(__param_list) as c_uint)))

    (__local_array = (((with_alloc(((((sizeof[usize]() as c_ulong) *% (__local_length as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

    if ((if __local_array == null: 1 else: 0) != 0) {
        return ((null as *mut *mut c_void))

    }

    (__local_rover = __param_list)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_length: 1 else: 0) != 0) {
        ((__local_array[__local_i]) = (*__local_rover).data)

        (__local_rover = (*__local_rover).next)


        (__local_i = (__local_i +% 1))

    }


    return __local_array

}

pub unsafe fn slist_remove_entry(__param_list: *mut *mut _SListEntry, __param_entry: *mut _SListEntry) -> c_int {
    var __local_rover: *mut _SListEntry

    var __ci_expr_logic_0: c_int

    if ((if (*__param_list) == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param_entry == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return 0

    }


    if ((if (*__param_list) == __param_entry: 1 else: 0) != 0) {
        ((*__param_list) = (*__param_entry).next)

    } else {
        (__local_rover = (*__param_list))

        while true {
            var __ci_expr_logic_1: c_int = 0

            if ((if __local_rover != null: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if (if (*__local_rover).next != __param_entry: 1 else: 0) != 0: 1 else: 0))
            }

            if (not (__ci_expr_logic_1 != 0)) {
                break
            }

            (__local_rover = (*__local_rover).next)

        }

        if ((if __local_rover == null: 1 else: 0) != 0) {
            return 0

        }
        ((*__local_rover).next = (*__param_entry).next)


    }

    with_free(((__param_entry as *mut c_void) as *mut u8))

    return 1

}

pub unsafe fn slist_remove_data(__param_list: *mut *mut _SListEntry, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, __param_data: *mut c_void) -> c_uint {
    var __local_rover: *mut *mut _SListEntry

    var __local_next: *mut _SListEntry

    var __local_entries_removed: c_uint

    (__local_entries_removed = ((0 as c_uint)))

    (__local_rover = __param_list)

    while ((if (*__local_rover) != null: 1 else: 0) != 0) {
        if ((if __param_callback((*(*__local_rover)).data, __param_data) != 0: 1 else: 0) != 0) {
            (__local_next = (*(*__local_rover)).next)

            with_free((((*__local_rover) as *mut c_void) as *mut u8))

            ((*__local_rover) = __local_next)

            (__local_entries_removed = (__local_entries_removed +% 1))

        } else {
            (__local_rover = (((&raw const (*(*__local_rover)).next as *const *mut _SListEntry) as *mut *mut _SListEntry)))

        }

    }

    return __local_entries_removed

}

pub unsafe fn slist_sort(__param_list: *mut *mut _SListEntry, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> Unit {
    slist_sort_internal(__param_list, __param_compare_func)

}

pub unsafe fn slist_find_data(__param_list: *mut _SListEntry, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int, __param_data: *mut c_void) -> *mut _SListEntry {
    var __local_rover: *mut _SListEntry

    (__local_rover = __param_list)

    while ((if __local_rover != null: 1 else: 0) != 0) {
        if ((if __param_callback((*__local_rover).data, __param_data) != 0: 1 else: 0) != 0) {
            return __local_rover

        }


        (__local_rover = (*__local_rover).next)

    }


    return ((null as *mut _SListEntry))

}

pub unsafe fn slist_iterate(__param_list: *mut *mut _SListEntry, __param_iter: *mut _SListIterator) -> Unit {
    ((*__param_iter).prev_next = __param_list)

    ((*__param_iter).current = ((null as *mut _SListEntry)))

}

pub unsafe fn slist_iter_has_more(__param_iter: *mut _SListIterator) -> c_int {
    var __ci_expr_logic_0: c_int

    if ((if (*__param_iter).current == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*__param_iter).current != (*((*__param_iter).prev_next)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return (if (*((*__param_iter).prev_next)) != null: 1 else: 0)

    }
    return (if (*(*__param_iter).current).next != null: 1 else: 0)



}

pub unsafe fn slist_iter_next(__param_iter: *mut _SListIterator) -> *mut c_void {
    var __ci_expr_logic_0: c_int

    if ((if (*__param_iter).current == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*__param_iter).current != (*((*__param_iter).prev_next)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__param_iter).current = (*((*__param_iter).prev_next)))

    } else {
        ((*__param_iter).prev_next = (((&raw const (*(*__param_iter).current).next as *const *mut _SListEntry) as *mut *mut _SListEntry)))

        ((*__param_iter).current = (*(*__param_iter).current).next)

    }


    if ((if (*__param_iter).current == null: 1 else: 0) != 0) {
        return slist_null_value

    }
    return (*(*__param_iter).current).data


}

pub unsafe fn slist_iter_remove(__param_iter: *mut _SListIterator) -> Unit {
    var __ci_expr_logic_0: c_int

    if ((if (*__param_iter).current == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*__param_iter).current != (*((*__param_iter).prev_next)): 1 else: 0) != 0: 1 else: 0))
    }

    if (not (__ci_expr_logic_0 != 0)) {
        ((*((*__param_iter).prev_next)) = (*(*__param_iter).current).next)

        with_free((((*__param_iter).current as *mut c_void) as *mut u8))

        ((*__param_iter).current = ((null as *mut _SListEntry)))

    }


}

unsafe fn slist_sort_internal(__param_list: *mut *mut _SListEntry, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _SListEntry {
    var __local_pivot: *mut _SListEntry

    var __local_rover: *mut _SListEntry

    var __local_less_list: *mut _SListEntry

    var __local_more_list: *mut _SListEntry


    var __local_less_list_end: *mut _SListEntry

    var __local_more_list_end: *mut _SListEntry


    var __ci_expr_logic_0: c_int

    if ((if (*__param_list) == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*(*__param_list)).next == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return (*__param_list)

    }


    (__local_pivot = (*__param_list))

    (__local_less_list = ((null as *mut _SListEntry)))

    (__local_more_list = ((null as *mut _SListEntry)))

    (__local_rover = (*(*__param_list)).next)

    while ((if __local_rover != null: 1 else: 0) != 0) {
        var __local_next: *mut _SListEntry = (*__local_rover).next

        if ((if __param_compare_func((*__local_rover).data, (*__local_pivot).data) < 0: 1 else: 0) != 0) {
            ((*__local_rover).next = __local_less_list)

            (__local_less_list = __local_rover)

        } else {
            ((*__local_rover).next = __local_more_list)

            (__local_more_list = __local_rover)

        }

        (__local_rover = __local_next)

    }

    (__local_less_list_end = slist_sort_internal((&raw mut __local_less_list as *mut *mut _SListEntry), __param_compare_func))

    (__local_more_list_end = slist_sort_internal((&raw mut __local_more_list as *mut *mut _SListEntry), __param_compare_func))

    ((*__param_list) = __local_less_list)

    if ((if __local_less_list == null: 1 else: 0) != 0) {
        ((*__param_list) = __local_pivot)

    } else {
        ((*__local_less_list_end).next = __local_pivot)

    }

    ((*__local_pivot).next = __local_more_list)

    if ((if __local_more_list == null: 1 else: 0) != 0) {
        return __local_pivot

    }
    return __local_more_list_end


}

let slist_null_value: *mut c_void = null
