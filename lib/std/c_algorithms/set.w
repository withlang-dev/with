// Migrated from C
use std.c_algorithms.defs

pub fn set_new(__param_hash_func: unsafe extern "C" fn(*mut c_void) -> c_uint, __param_equal_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _Set {
    var __local_new_set: *mut _Set

    (__local_new_set = (((unsafe { with_alloc(((sizeof[_Set]() as c_ulong) as i64)) } as *mut c_void) as *mut _Set)))

    if ((if __local_new_set == null: 1 else: 0) != 0) {
        return ((null as *mut _Set))

    }

    ((unsafe *__local_new_set).hash_func = __param_hash_func)

    ((unsafe *__local_new_set).equal_func = __param_equal_func)

    ((unsafe *__local_new_set).entries = ((0 as c_uint)))

    ((unsafe *__local_new_set).prime_index = ((0 as c_uint)))

    ((unsafe *__local_new_set).free_func = null)

    if ((if not (unsafe { set_allocate_table(__local_new_set) } != 0): 1 else: 0) != 0) {
        unsafe { with_free(((__local_new_set as *mut c_void) as *mut u8)) }

        return ((null as *mut _Set))

    }

    return __local_new_set

}

pub unsafe fn set_free(__param_set: *mut _Set) -> Unit {
    var __local_rover: *mut _SetEntry

    var __local_next: *mut _SetEntry

    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (*__param_set).table_size: 1 else: 0) != 0) {
        (__local_rover = ((*__param_set).table[__local_i]))

        while ((if __local_rover != null: 1 else: 0) != 0) {
            (__local_next = (*__local_rover).next)

            set_free_entry(__param_set, __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    with_free((((*__param_set).table as *mut c_void) as *mut u8))

    with_free(((__param_set as *mut c_void) as *mut u8))

}

pub unsafe fn set_register_free_function(__param_set: *mut _Set, __param_free_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    ((*__param_set).free_func = __param_free_func)

}

pub unsafe fn set_insert(__param_set: *mut _Set, __param_data: *mut c_void) -> c_int {
    var __local_newentry: *mut _SetEntry

    var __local_rover: *mut _SetEntry

    var __local_index: c_uint

    if ((if (((((*__param_set).entries as c_uint) *% (3 as c_uint)) as c_uint) / ((*__param_set).table_size as c_uint)) > 0: 1 else: 0) != 0) {
        if ((if not (set_enlarge(__param_set) != 0): 1 else: 0) != 0) {
            return 0

        }

    }

    (__local_index = (((((*__param_set).hash_func(__param_data) as c_uint) % ((*__param_set).table_size as c_uint)) as c_uint)))

    (__local_rover = ((*__param_set).table[__local_index]))

    while ((if __local_rover != null: 1 else: 0) != 0) {
        if ((if (*__param_set).equal_func(__param_data, (*__local_rover).data) != 0: 1 else: 0) != 0) {
            return 0

        }

        (__local_rover = (*__local_rover).next)

    }

    (__local_newentry = (((with_alloc(((sizeof[_SetEntry]() as c_ulong) as i64)) as *mut c_void) as *mut _SetEntry)))

    if ((if __local_newentry == null: 1 else: 0) != 0) {
        return 0

    }

    ((*__local_newentry).data = __param_data)

    ((*__local_newentry).next = ((*__param_set).table[__local_index]))

    (((*__param_set).table[__local_index]) = __local_newentry)

    ((*__param_set).entries = ((*__param_set).entries +% 1))

    return 1

}

pub unsafe fn set_remove(__param_set: *mut _Set, __param_data: *mut c_void) -> c_int {
    var __local_rover: *mut *mut _SetEntry

    var __local_entry: *mut _SetEntry

    var __local_index: c_uint

    (__local_index = (((((*__param_set).hash_func(__param_data) as c_uint) % ((*__param_set).table_size as c_uint)) as c_uint)))

    (__local_rover = (((&raw const ((*__param_set).table[__local_index]) as *const *mut _SetEntry) as *mut *mut _SetEntry)))

    while ((if (*__local_rover) != null: 1 else: 0) != 0) {
        if ((if (*__param_set).equal_func(__param_data, (*(*__local_rover)).data) != 0: 1 else: 0) != 0) {
            (__local_entry = (*__local_rover))

            ((*__local_rover) = (*__local_entry).next)

            ((*__param_set).entries = ((*__param_set).entries -% 1))

            set_free_entry(__param_set, __local_entry)

            return 1

        }

        (__local_rover = (((&raw const (*(*__local_rover)).next as *const *mut _SetEntry) as *mut *mut _SetEntry)))

    }

    return 0

}

pub unsafe fn set_query(__param_set: *mut _Set, __param_data: *mut c_void) -> c_int {
    var __local_rover: *mut _SetEntry

    var __local_index: c_uint

    (__local_index = (((((*__param_set).hash_func(__param_data) as c_uint) % ((*__param_set).table_size as c_uint)) as c_uint)))

    (__local_rover = ((*__param_set).table[__local_index]))

    while ((if __local_rover != null: 1 else: 0) != 0) {
        if ((if (*__param_set).equal_func(__param_data, (*__local_rover).data) != 0: 1 else: 0) != 0) {
            return 1

        }

        (__local_rover = (*__local_rover).next)

    }

    return 0

}

pub unsafe fn set_num_entries(__param_set: *mut _Set) -> c_uint {
    return (*__param_set).entries

}

pub unsafe fn set_to_array(__param_set: *mut _Set) -> *mut *mut c_void {
    var __local_array: *mut *mut c_void

    var __local_array_counter: c_int

    var __local_i: c_uint

    var __local_rover: *mut _SetEntry

    (__local_array = (((with_alloc(((((sizeof[usize]() as c_ulong) *% ((*__param_set).entries as c_ulong)) as c_ulong) as i64)) as *mut c_void) as *mut *mut c_void)))

    if ((if __local_array == null: 1 else: 0) != 0) {
        return ((null as *mut *mut c_void))

    }

    (__local_array_counter = ((0 as c_int)))

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (*__param_set).table_size: 1 else: 0) != 0) {
        (__local_rover = ((*__param_set).table[__local_i]))

        while ((if __local_rover != null: 1 else: 0) != 0) {
            ((__local_array[__local_array_counter]) = (*__local_rover).data)

            (__local_array_counter = __local_array_counter + 1)

            (__local_rover = (*__local_rover).next)

        }


        (__local_i = (__local_i +% 1))

    }


    return __local_array

}

pub unsafe fn set_union(__param_set1: *mut _Set, __param_set2: *mut _Set) -> *mut _Set {
    var __local_iterator: _SetIterator

    var __local_new_set: *mut _Set

    var __local_value: *mut c_void

    (__local_new_set = set_new((*__param_set1).hash_func, (*__param_set1).equal_func))

    if ((if __local_new_set == null: 1 else: 0) != 0) {
        return ((null as *mut _Set))

    }

    set_iterate(__param_set1, (&raw mut __local_iterator as *mut _SetIterator))

    while (set_iter_has_more((&raw mut __local_iterator as *mut _SetIterator)) != 0) {
        (__local_value = set_iter_next((&raw mut __local_iterator as *mut _SetIterator)))

        if ((if not (set_insert(__local_new_set, __local_value) != 0): 1 else: 0) != 0) {
            set_free(__local_new_set)

            return ((null as *mut _Set))

        }

    }

    set_iterate(__param_set2, (&raw mut __local_iterator as *mut _SetIterator))

    while (set_iter_has_more((&raw mut __local_iterator as *mut _SetIterator)) != 0) {
        (__local_value = set_iter_next((&raw mut __local_iterator as *mut _SetIterator)))

        if ((if set_query(__local_new_set, __local_value) == 0: 1 else: 0) != 0) {
            if ((if not (set_insert(__local_new_set, __local_value) != 0): 1 else: 0) != 0) {
                set_free(__local_new_set)

                return ((null as *mut _Set))

            }

        }

    }

    return __local_new_set

}

pub unsafe fn set_intersection(__param_set1: *mut _Set, __param_set2: *mut _Set) -> *mut _Set {
    var __local_new_set: *mut _Set

    var __local_iterator: _SetIterator

    var __local_value: *mut c_void

    (__local_new_set = set_new((*__param_set1).hash_func, (*__param_set2).equal_func))

    if ((if __local_new_set == null: 1 else: 0) != 0) {
        return ((null as *mut _Set))

    }

    set_iterate(__param_set1, (&raw mut __local_iterator as *mut _SetIterator))

    while (set_iter_has_more((&raw mut __local_iterator as *mut _SetIterator)) != 0) {
        (__local_value = set_iter_next((&raw mut __local_iterator as *mut _SetIterator)))

        if ((if set_query(__param_set2, __local_value) != 0: 1 else: 0) != 0) {
            if ((if not (set_insert(__local_new_set, __local_value) != 0): 1 else: 0) != 0) {
                set_free(__local_new_set)

                return ((null as *mut _Set))

            }

        }

    }

    return __local_new_set

}

pub unsafe fn set_iterate(__param_set: *mut _Set, __param_iter: *mut _SetIterator) -> Unit {
    var __local_chain: c_uint

    ((*__param_iter).set = __param_set)

    ((*__param_iter).next_entry = ((null as *mut _SetEntry)))

    (__local_chain = ((0 as c_uint)))

    while ((if __local_chain < (*__param_set).table_size: 1 else: 0) != 0) {
        if ((if ((*__param_set).table[__local_chain]) != null: 1 else: 0) != 0) {
            ((*__param_iter).next_entry = ((*__param_set).table[__local_chain]))

            break

        }


        (__local_chain = (__local_chain +% 1))

    }


    ((*__param_iter).next_chain = __local_chain)

}

pub unsafe fn set_iter_has_more(__param_iterator: *mut _SetIterator) -> c_int {
    return (if (*__param_iterator).next_entry != null: 1 else: 0)

}

pub unsafe fn set_iter_next(__param_iterator: *mut _SetIterator) -> *mut c_void {
    var __local_set: *mut _Set

    var __local_result: *mut c_void

    var __local_current_entry: *mut _SetEntry

    var __local_chain: c_uint

    (__local_set = (*__param_iterator).set)

    if ((if (*__param_iterator).next_entry == null: 1 else: 0) != 0) {
        return set_null_value

    }

    (__local_current_entry = (*__param_iterator).next_entry)

    (__local_result = (*__local_current_entry).data)

    if ((if (*__local_current_entry).next != null: 1 else: 0) != 0) {
        ((*__param_iterator).next_entry = (*__local_current_entry).next)

    } else {
        ((*__param_iterator).next_entry = ((null as *mut _SetEntry)))

        (__local_chain = (((((*__param_iterator).next_chain as c_uint) +% (1 as c_uint)) as c_uint)))

        while ((if __local_chain < (*__local_set).table_size: 1 else: 0) != 0) {
            if ((if ((*__local_set).table[__local_chain]) != null: 1 else: 0) != 0) {
                ((*__param_iterator).next_entry = ((*__local_set).table[__local_chain]))

                break

            }

            (__local_chain = (__local_chain +% 1))

        }

        ((*__param_iterator).next_chain = __local_chain)

    }

    return __local_result

}

unsafe fn set_allocate_table(__param_set: *mut _Set) -> c_int {
    if ((if (*__param_set).prime_index < 24: 1 else: 0) != 0) {
        ((*__param_set).table_size = ((set_primes[(*__param_set).prime_index] as c_uint)))

    } else {
        ((*__param_set).table_size = (((((*__param_set).entries as c_uint) *% (10 as c_uint)) as c_uint)))

    }

    ((*__param_set).table = (((with_alloc_zeroed((((*__param_set).table_size as c_ulong) as i64), ((sizeof[usize]() as c_ulong) as i64)) as *mut c_void) as *mut *mut _SetEntry)))

    return (if (*__param_set).table != null: 1 else: 0)

}

unsafe fn set_free_entry(__param_set: *mut _Set, __param_entry: *mut _SetEntry) -> Unit {
    if ((if (*__param_set).free_func != null: 1 else: 0) != 0) {
        (*__param_set).free_func((*__param_entry).data)

    }

    with_free(((__param_entry as *mut c_void) as *mut u8))

}

unsafe fn set_enlarge(__param_set: *mut _Set) -> c_int {
    var __local_rover: *mut _SetEntry

    var __local_next: *mut _SetEntry

    var __local_old_table: *mut *mut _SetEntry

    var __local_old_table_size: c_uint

    var __local_old_prime_index: c_uint

    var __local_index: c_uint

    var __local_i: c_uint

    (__local_old_table = (*__param_set).table)

    (__local_old_table_size = (*__param_set).table_size)

    (__local_old_prime_index = (*__param_set).prime_index)

    ((*__param_set).prime_index = ((*__param_set).prime_index +% 1))

    if ((if not (set_allocate_table(__param_set) != 0): 1 else: 0) != 0) {
        ((*__param_set).table = __local_old_table)

        ((*__param_set).table_size = __local_old_table_size)

        ((*__param_set).prime_index = __local_old_prime_index)

        return 0

    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_old_table_size: 1 else: 0) != 0) {
        (__local_rover = (__local_old_table[__local_i]))

        while ((if __local_rover != null: 1 else: 0) != 0) {
            (__local_next = (*__local_rover).next)

            (__local_index = (((((*__param_set).hash_func((*__local_rover).data) as c_uint) % ((*__param_set).table_size as c_uint)) as c_uint)))

            ((*__local_rover).next = ((*__param_set).table[__local_index]))

            (((*__param_set).table[__local_index]) = __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    with_free(((__local_old_table as *mut c_void) as *mut u8))

    return 1

}

let set_primes: [24]c_uint = [(193 as c_uint), (389 as c_uint), (769 as c_uint), (1543 as c_uint), (3079 as c_uint), (6151 as c_uint), (12289 as c_uint), (24593 as c_uint), (49157 as c_uint), (98317 as c_uint), (196613 as c_uint), (393241 as c_uint), (786433 as c_uint), (1572869 as c_uint), (3145739 as c_uint), (6291469 as c_uint), (12582917 as c_uint), (25165843 as c_uint), (50331653 as c_uint), (100663319 as c_uint), (201326611 as c_uint), (402653189 as c_uint), (805306457 as c_uint), (1610612741 as c_uint)]
let set_num_primes: c_uint = 24
let set_null_value: *mut c_void = null
