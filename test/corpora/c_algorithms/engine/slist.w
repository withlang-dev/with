// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing
use std.option

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn slist_free(__param_list: *mut _SListEntry) {
    var __local_entry: *mut _SListEntry

    (__local_entry = __param_list)

    while (__local_entry != null) {
        var __local_next: *mut _SListEntry

        (__local_next = (*__local_entry).next)

        alloc_test_free((__local_entry as *mut c_void))

        (__local_entry = __local_next)

    }

}

// contract: unproved:0:out-parameter a return before the write,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn slist_prepend(__param_list: *mut *mut _SListEntry, __param_data: *mut c_void) -> *mut _SListEntry writes allocation_limit {
    var __local_newentry: *mut _SListEntry

    (__local_newentry = ((alloc_test_malloc((sizeof[_SListEntry]() as u64)) as *mut _SListEntry)))

    if (__local_newentry == null) {
        return ((null as *mut _SListEntry))

    }

    ((*__local_newentry).data = __param_data)

    ((*__local_newentry).next = (*__param_list))

    ((*__param_list) = __local_newentry)

    return __local_newentry

}

// contract: unproved:0:out-parameter a return before the write,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn slist_append(__param_list: *mut *mut _SListEntry, __param_data: *mut c_void) -> *mut _SListEntry writes allocation_limit {
    var __local_rover: *mut _SListEntry

    var __local_newentry: *mut _SListEntry

    (__local_newentry = ((alloc_test_malloc((sizeof[_SListEntry]() as u64)) as *mut _SListEntry)))

    if (__local_newentry == null) {
        return ((null as *mut _SListEntry))

    }

    ((*__local_newentry).data = __param_data)

    ((*__local_newentry).next = ((null as *mut _SListEntry)))

    if ((*__param_list) == null) {
        ((*__param_list) = __local_newentry)

    } else {
        (__local_rover = (*__param_list))

        while ((*__local_rover).next != null) {

            (__local_rover = (*__local_rover).next)

        }


        ((*__local_rover).next = __local_newentry)

    }

    return __local_newentry

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn slist_next(__param_listentry: *mut _SListEntry) -> *mut _SListEntry {
    return (*__param_listentry).next

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn slist_data(__param_listentry: *mut _SListEntry) -> *mut c_void {
    return (*__param_listentry).data

}

// contract: unproved:0:NULL is an accepted argument,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn slist_set_data(__param_listentry: *mut _SListEntry, __param_data: *mut c_void) {
    if (__param_listentry != null) {
        ((*__param_listentry).data = __param_data)

    }

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn slist_nth_entry(__param_list: *mut _SListEntry, __param_n: u32) -> *mut _SListEntry {
    var __local_entry: *mut _SListEntry

    var __local_i: u32

    (__local_entry = __param_list)

    (__local_i = ((0 as u32)))

    while (__local_i < __param_n) {
        if (__local_entry == null) {
            return ((null as *mut _SListEntry))

        }

        (__local_entry = (*__local_entry).next)


        (__local_i = (__local_i +% 1))

    }


    return __local_entry

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn slist_nth_data(__param_list: *mut _SListEntry, __param_n: u32) -> *mut c_void {
    var __local_entry: *mut _SListEntry

    (__local_entry = slist_nth_entry(__param_list, __param_n))

    if (__local_entry == null) {
        return slist_null_value

    }
    return (*__local_entry).data


}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn slist_length(__param_list: *mut _SListEntry) -> u32 {
    var __local_entry: *mut _SListEntry

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
pub unsafe fn slist_to_array(__param_list: *mut _SListEntry) -> *mut *mut c_void writes allocation_limit {
    var __local_rover: *mut _SListEntry

    var __local_array: *mut *mut c_void

    var __local_length: u32

    var __local_i: u32

    (__local_length = ((slist_length(__param_list) as u32)))

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
pub unsafe fn slist_remove_entry(__param_list: *mut *mut _SListEntry, __param_entry: *mut _SListEntry) -> i32 {
    var __local_rover: *mut _SListEntry

    var __ci_expr_logic_0: i32

    if ((*__param_list) == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __param_entry == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        return 0

    }


    if ((*__param_list) == __param_entry) {
        ((*__param_list) = (*__param_entry).next)

    } else {
        (__local_rover = (*__param_list))

        while true {
            var __ci_expr_logic_1: i32 = 0

            if (__local_rover != null) {
                (__ci_expr_logic_1 = (if (*__local_rover).next != __param_entry: 1 else: 0))
            }

            if (not __ci_expr_logic_1) {
                break
            }

            (__local_rover = (*__local_rover).next)

        }

        if (__local_rover == null) {
            return 0

        }
        ((*__local_rover).next = (*__param_entry).next)


    }

    alloc_test_free((__param_entry as *mut c_void))

    return 1

}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn slist_remove_data(__param_list: *mut *mut _SListEntry, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32, __param_data: *mut c_void) -> u32 {
    var __local_rover: *mut *mut _SListEntry

    var __local_next: *mut _SListEntry

    var __local_entries_removed: u32

    (__local_entries_removed = ((0 as u32)))

    (__local_rover = __param_list)

    while ((*__local_rover) != null) {
        if (__param_callback((*(*__local_rover)).data, __param_data) != 0) {
            (__local_next = (*(*__local_rover)).next)

            alloc_test_free(((*__local_rover) as *mut c_void))

            ((*__local_rover) = __local_next)

            (__local_entries_removed = (__local_entries_removed +% 1))

        } else {
            (__local_rover = (((&raw const (*(*__local_rover)).next as *const *mut _SListEntry) as *mut *mut _SListEntry)))

        }

    }

    return __local_entries_removed

}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn slist_sort(__param_list: *mut *mut _SListEntry, __param_compare_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32) -> Unit {
    slist_sort_internal(__param_list, Some(__param_compare_func))

}

// contract: stored-unknown:0,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn slist_find_data(__param_list: *mut _SListEntry, __param_callback: unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32, __param_data: *mut c_void) -> *mut _SListEntry {
    var __local_rover: *mut _SListEntry

    (__local_rover = __param_list)

    while (__local_rover != null) {
        if (__param_callback((*__local_rover).data, __param_data) != 0) {
            return __local_rover

        }


        (__local_rover = (*__local_rover).next)

    }


    return ((null as *mut _SListEntry))

}

// contract: stored-unknown:0,unproved:1:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn slist_iterate(__param_list: *mut *mut _SListEntry, __param_iter: *mut _SListIterator) {
    ((*__param_iter).prev_next = __param_list)

    ((*__param_iter).current = ((null as *mut _SListEntry)))

}

// contract: unproved:0:out-parameter written conditionally
unsafe fn slist_sort_internal(__param_list: *mut *mut _SListEntry, __param_compare_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _SListEntry {
    var __local_pivot: *mut _SListEntry

    var __local_rover: *mut _SListEntry

    var __local_less_list: *mut _SListEntry

    var __local_more_list: *mut _SListEntry


    var __local_less_list_end: *mut _SListEntry

    var __local_more_list_end: *mut _SListEntry


    var __ci_expr_logic_0: i32

    if ((*__param_list) == null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (*(*__param_list)).next == null: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        return (*__param_list)

    }


    (__local_pivot = (*__param_list))

    (__local_less_list = ((null as *mut _SListEntry)))

    (__local_more_list = ((null as *mut _SListEntry)))

    (__local_rover = (*(*__param_list)).next)

    while (__local_rover != null) {
        var __local_next: *mut _SListEntry = (*__local_rover).next

        if (__param_compare_func.unwrap()((*__local_rover).data, (*__local_pivot).data) < 0) {
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

    if (__local_less_list == null) {
        ((*__param_list) = __local_pivot)

    } else {
        ((*__local_less_list_end).next = __local_pivot)

    }

    ((*__local_pivot).next = __local_more_list)

    if (__local_more_list == null) {
        return __local_pivot

    }
    return __local_more_list_end


}

impl _SListIterator {
    pub fn slist_iter_has_more() -> i32 {
        let __param_iter: *mut _SListIterator = (self as *const _SListIterator) as *mut _SListIterator
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

    pub mut fn slist_iter_next() -> *mut c_void {
        let __param_iter: *mut _SListIterator = self as *mut _SListIterator
        var __ci_expr_logic_0: i32

        if ((unsafe *__param_iter).current == null) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (unsafe *__param_iter).current != (unsafe *((*__param_iter).prev_next)): 1 else: 0))
        }

        if __ci_expr_logic_0 {
            ((unsafe *__param_iter).current = (unsafe *((*__param_iter).prev_next)))

        } else {
            ((unsafe *__param_iter).prev_next = (((&raw const (unsafe *(*__param_iter).current).next as *const *mut _SListEntry) as *mut *mut _SListEntry)))

            ((unsafe *__param_iter).current = (unsafe *(*__param_iter).current).next)

        }


        if ((unsafe *__param_iter).current == null) {
            return slist_null_value

        }
        return (unsafe *(*__param_iter).current).data


    }

    pub mut fn slist_iter_remove() {
        let __param_iter: *mut _SListIterator = self as *mut _SListIterator
        var __ci_expr_logic_0: i32

        if ((unsafe *__param_iter).current == null) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (unsafe *__param_iter).current != (unsafe *((*__param_iter).prev_next)): 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            ((unsafe *((*__param_iter).prev_next)) = (unsafe *(*__param_iter).current).next)

            unsafe { alloc_test_free(((*__param_iter).current as *mut c_void)) }

            ((unsafe *__param_iter).current = ((null as *mut _SListEntry)))

        }


    }

}

let slist_null_value: *mut c_void = null
