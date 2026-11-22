// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.option

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn list_free(__param_list: *mut _ListEntry) {
    var __local_entry: *mut _ListEntry

    (__local_entry = __param_list)

    while (__local_entry != null) {
        var __local_next: *mut _ListEntry

        (__local_next = (*__local_entry).next)

        alloc_test_free((__local_entry as *mut c_void))

        (__local_entry = __local_next)

    }

}

// contract: unproved:0:out-parameter written conditionally,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn list_prepend(__param_list: *mut *mut _ListEntry, __param_data: *mut c_void) -> *mut _ListEntry writes allocation_limit {
    var __local_newentry: *mut _ListEntry

    if (__param_list == null) {
        return ((null as *mut _ListEntry))

    }

    (__local_newentry = ((alloc_test_malloc((sizeof[_ListEntry]() as u64)) as *mut _ListEntry)))

    if (__local_newentry == null) {
        return ((null as *mut _ListEntry))

    }

    ((*__local_newentry).data = __param_data)

    if ((*__param_list) != null) {
        ((*(*__param_list)).prev = __local_newentry)

    }

    ((*__local_newentry).prev = ((null as *mut _ListEntry)))

    ((*__local_newentry).next = (*__param_list))

    ((*__param_list) = __local_newentry)

    return __local_newentry

}

// contract: unproved:0:out-parameter written conditionally,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn list_append(__param_list: *mut *mut _ListEntry, __param_data: *mut c_void) -> *mut _ListEntry writes allocation_limit {
    var __local_rover: *mut _ListEntry

    var __local_newentry: *mut _ListEntry

    if (__param_list == null) {
        return ((null as *mut _ListEntry))

    }

    (__local_newentry = ((alloc_test_malloc((sizeof[_ListEntry]() as u64)) as *mut _ListEntry)))

    if (__local_newentry == null) {
        return ((null as *mut _ListEntry))

    }

    ((*__local_newentry).data = __param_data)

    ((*__local_newentry).next = ((null as *mut _ListEntry)))

    if ((*__param_list) == null) {
        ((*__param_list) = __local_newentry)

        ((*__local_newentry).prev = ((null as *mut _ListEntry)))

    } else {
        (__local_rover = (*__param_list))

        while ((*__local_rover).next != null) {

            (__local_rover = (*__local_rover).next)

        }


        ((*__local_newentry).prev = __local_rover)

        ((*__local_rover).next = __local_newentry)

    }

    return __local_newentry

}

// contract: unproved:0:NULL is an accepted argument
pub unsafe fn list_prev(__param_listentry: *mut _ListEntry) -> *mut _ListEntry {
    if (__param_listentry == null) {
        return ((null as *mut _ListEntry))

    }

    return (*__param_listentry).prev

}

// contract: unproved:0:NULL is an accepted argument
pub unsafe fn list_next(__param_listentry: *mut _ListEntry) -> *mut _ListEntry {
    if (__param_listentry == null) {
        return ((null as *mut _ListEntry))

    }

    return (*__param_listentry).next

}

// contract: unproved:0:NULL is an accepted argument
pub unsafe fn list_data(__param_listentry: *mut _ListEntry) -> *mut c_void {
    if (__param_listentry == null) {
        return list_null_value

    }

    return (*__param_listentry).data

}

// contract: unproved:0:NULL is an accepted argument,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn list_set_data(__param_listentry: *mut _ListEntry, __param_value: *mut c_void) {
    if (__param_listentry != null) {
        ((*__param_listentry).data = __param_value)

    }

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn list_nth_entry(__param_list: *mut _ListEntry, __param_n: u32) -> *mut _ListEntry {
    var __local_entry: *mut _ListEntry

    var __local_i: u32

    (__local_entry = __param_list)

    (__local_i = ((0 as u32)))

    while (__local_i < __param_n) {
        if (__local_entry == null) {
            return ((null as *mut _ListEntry))

        }

        (__local_entry = (*__local_entry).next)


        (__local_i = (__local_i +% 1))

    }


    return __local_entry

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn list_nth_data(__param_list: *mut _ListEntry, __param_n: u32) -> *mut c_void {
    var __local_entry: *mut _ListEntry

    (__local_entry = list_nth_entry(__param_list, __param_n))

    if (__local_entry == null) {
        return list_null_value

    }
    return (*__local_entry).data


}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn list_length(__param_list: *mut _ListEntry) -> u32 {
    var __local_entry: *mut _ListEntry

    var __local_length: u32

    (__local_length = ((0 as u32)))

    (__local_entry = __param_list)

    while (__local_entry != null) {
        (__local_length = (__local_length +% 1))

        (__local_entry = (*__local_entry).next)

    }

    return __local_length

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn list_to_array(__param_list: *mut _ListEntry) -> *mut *mut c_void writes allocation_limit {
    var __local_rover: *mut _ListEntry

    var __local_array: *mut *mut c_void

    var __local_length: u32

    var __local_i: u32

    (__local_length = ((list_length(__param_list) as u32)))

    (__local_array = ((alloc_test_malloc((((sizeof[usize]() as u64) *% (__local_length as u64)) as u64)) as *mut *mut c_void)))

    if (__local_array == null) {
        return ((null as *mut *mut c_void))

    }

    (__local_rover = __param_list)

    (__local_i = ((0 as u32)))

    while (__local_i < __local_length) {
        ((__local_array[__local_i]) = (*__local_rover).data)

        (__local_rover = (*__local_rover).next)


        (__local_i = (__local_i +% 1))

    }


    return __local_array

}

// contract: unproved:0:out-parameter written conditionally,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn list_remove_entry(__param_list: *mut *mut _ListEntry, __param_entry: *mut _ListEntry) -> i32 {
    var __ci_expr_logic_1: i32

    var __ci_expr_logic_0: i32

    if (__param_list == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (*__param_list) == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if __param_entry == null: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        return 0

    }


    if ((*__param_entry).prev == null) {
        ((*__param_list) = (*__param_entry).next)

        if ((*__param_entry).next != null) {
            ((*(*__param_entry).next).prev = ((null as *mut _ListEntry)))

        }

    } else {
        ((*(*__param_entry).prev).next = (*__param_entry).next)

        if ((*__param_entry).next != null) {
            ((*(*__param_entry).next).prev = (*__param_entry).prev)

        }

    }

    alloc_test_free((__param_entry as *mut c_void))

    return 1

}

// contract: unproved:0:out-parameter written conditionally,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn list_remove_data(__param_list: *mut *mut _ListEntry, __param_callback: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32], __param_data: *mut c_void) -> u32 {
    var __local_entries_removed: u32

    var __local_rover: *mut _ListEntry

    var __local_next: *mut _ListEntry

    var __ci_expr_logic_0: i32

    if (__param_list == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __param_callback == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        return ((0 as u32))

    }


    (__local_entries_removed = ((0 as u32)))

    (__local_rover = (*__param_list))

    while (__local_rover != null) {
        (__local_next = (*__local_rover).next)

        if __param_callback.unwrap()((*__local_rover).data, __param_data) {
            if ((*__local_rover).prev == null) {
                ((*__param_list) = (*__local_rover).next)

            } else {
                ((*(*__local_rover).prev).next = (*__local_rover).next)

            }

            if ((*__local_rover).next != null) {
                ((*(*__local_rover).next).prev = (*__local_rover).prev)

            }

            alloc_test_free((__local_rover as *mut c_void))

            (__local_entries_removed = (__local_entries_removed +% 1))

        }

        (__local_rover = __local_next)

    }

    return __local_entries_removed

}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn list_sort(__param_list: *mut *mut _ListEntry, __param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> Unit {
    list_sort_internal(__param_list, __param_compare_func)

}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn list_find_data(__param_list: *mut _ListEntry, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32, __param_data: *mut c_void) -> *mut _ListEntry {
    var __local_rover: *mut _ListEntry

    (__local_rover = __param_list)

    while (__local_rover != null) {
        if (__param_callback((*__local_rover).data, __param_data) != 0) {
            return __local_rover

        }


        (__local_rover = (*__local_rover).next)

    }


    return ((null as *mut _ListEntry))

}

// contract: stored-unknown:0,unproved:1:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn list_iterate(__param_list: *mut *mut _ListEntry, __param_iter: *mut _ListIterator) {
    ((*__param_iter).prev_next = __param_list)

    ((*__param_iter).current = ((null as *mut _ListEntry)))

}

// contract: unproved:0:out-parameter written conditionally
unsafe fn list_sort_internal(__param_list: *mut *mut _ListEntry, __param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _ListEntry {
    var __local_pivot: *mut _ListEntry

    var __local_rover: *mut _ListEntry

    var __local_less_list: *mut _ListEntry

    var __local_more_list: *mut _ListEntry


    var __local_less_list_end: *mut _ListEntry

    var __local_more_list_end: *mut _ListEntry


    var __ci_expr_logic_0: i32

    if (__param_list == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __param_compare_func == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        return ((null as *mut _ListEntry))

    }


    var __ci_expr_logic_1: i32

    if ((*__param_list) == null) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (*(*__param_list)).next == null: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        return (*__param_list)

    }


    (__local_pivot = (*__param_list))

    (__local_less_list = ((null as *mut _ListEntry)))

    (__local_more_list = ((null as *mut _ListEntry)))

    (__local_rover = (*(*__param_list)).next)

    while (__local_rover != null) {
        var __local_next: *mut _ListEntry = (*__local_rover).next

        if (__param_compare_func.unwrap()((*__local_rover).data, (*__local_pivot).data) < 0) {
            ((*__local_rover).prev = ((null as *mut _ListEntry)))

            ((*__local_rover).next = __local_less_list)

            if (__local_less_list != null) {
                ((*__local_less_list).prev = __local_rover)

            }

            (__local_less_list = __local_rover)

        } else {
            ((*__local_rover).prev = ((null as *mut _ListEntry)))

            ((*__local_rover).next = __local_more_list)

            if (__local_more_list != null) {
                ((*__local_more_list).prev = __local_rover)

            }

            (__local_more_list = __local_rover)

        }

        (__local_rover = __local_next)

    }

    (__local_less_list_end = list_sort_internal((&raw mut __local_less_list as *mut *mut _ListEntry), __param_compare_func))

    (__local_more_list_end = list_sort_internal((&raw mut __local_more_list as *mut *mut _ListEntry), __param_compare_func))

    ((*__param_list) = __local_less_list)

    if (__local_less_list == null) {
        ((*__local_pivot).prev = ((null as *mut _ListEntry)))

        ((*__param_list) = __local_pivot)

    } else {
        ((*__local_pivot).prev = __local_less_list_end)

        ((*__local_less_list_end).next = __local_pivot)

    }

    ((*__local_pivot).next = __local_more_list)

    if (__local_more_list != null) {
        ((*__local_more_list).prev = __local_pivot)

    }

    if (__local_more_list == null) {
        return __local_pivot

    }
    return __local_more_list_end


}

impl _ListIterator {
    pub fn list_iter_has_more() -> i32 {
        let __param_iter: *mut _ListIterator = (self as *const _ListIterator) as *mut _ListIterator
        var __ci_expr_logic_0: i32

        if ((unsafe *__param_iter).current == null) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (unsafe *__param_iter).current != (unsafe *((*__param_iter).prev_next)): 1 else: 0))
        }

        if __ci_expr_logic_0 {
            return (if (unsafe *((*__param_iter).prev_next)) != null: 1 else: 0)

        }
        return (if (unsafe *(*__param_iter).current).next != null: 1 else: 0)



    }

    pub mut fn list_iter_next() -> *mut c_void {
        let __param_iter: *mut _ListIterator = self as *mut _ListIterator
        var __ci_expr_logic_0: i32

        if ((unsafe *__param_iter).current == null) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (unsafe *__param_iter).current != (unsafe *((*__param_iter).prev_next)): 1 else: 0))
        }

        if __ci_expr_logic_0 {
            ((unsafe *__param_iter).current = (unsafe *((*__param_iter).prev_next)))

        } else {
            ((unsafe *__param_iter).prev_next = (((&raw const (unsafe *(*__param_iter).current).next as *const *mut _ListEntry) as *mut *mut _ListEntry)))

            ((unsafe *__param_iter).current = (unsafe *(*__param_iter).current).next)

        }


        if ((unsafe *__param_iter).current == null) {
            return list_null_value

        }
        return (unsafe *(*__param_iter).current).data


    }

    pub mut fn list_iter_remove() {
        let __param_iter: *mut _ListIterator = self as *mut _ListIterator
        var __ci_expr_logic_0: i32

        if ((unsafe *__param_iter).current == null) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (unsafe *__param_iter).current != (unsafe *((*__param_iter).prev_next)): 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            ((unsafe *((*__param_iter).prev_next)) = (unsafe *(*__param_iter).current).next)

            if ((unsafe *(*__param_iter).current).next != null) {
                ((unsafe *(*(*__param_iter).current).next).prev = (unsafe *(*__param_iter).current).prev)

            }

            unsafe { alloc_test_free(((*__param_iter).current as *mut c_void)) }

            ((unsafe *__param_iter).current = ((null as *mut _ListEntry)))

        }


    }

}

let list_null_value: *mut c_void = null
