// Migrated from C
use std.engines.c_algorithms.defs
use std.option
use std.collections

pub fn set_new(__param_hash_func: Option[unsafe extern "C" fn(*mut c_void) -> u32], __param_equal_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _Set {
    var __local_new_set: *mut _Set

    (__local_new_set = (((with_alloc(((sizeof[_Set]() as u64) as i64)) as *mut c_void) as *mut _Set)))

    if (__local_new_set == null) {
        return ((null as *mut _Set))

    }

    ((unsafe *__local_new_set).hash_func = __param_hash_func)

    ((unsafe *__local_new_set).equal_func = __param_equal_func)

    ((unsafe *__local_new_set).entries = ((0 as u32)))

    ((unsafe *__local_new_set).prime_index = ((0 as u32)))

    ((unsafe *__local_new_set).free_func = null)

    if (not unsafe { set_allocate_table(__local_new_set) }) {
        with_free(((__local_new_set as *mut c_void) as *mut u8))

        return ((null as *mut _Set))

    }

    return __local_new_set

}

// contract: unproved:0:frees a part of it
pub unsafe fn set_free(__param_set: *mut _Set) {
    var __local_rover: *mut _SetEntry

    var __local_next: *mut _SetEntry

    var __local_i: u32

    (__local_i = ((0 as u32)))

    while (__local_i < (*__param_set).table_size) {
        (__local_rover = ((*__param_set).table[__local_i]))

        while (__local_rover != null) {
            (__local_next = (*__local_rover).next)

            set_free_entry(__param_set, __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    with_free((((*__param_set).table as *mut c_void) as *mut u8))

    with_free(((__param_set as *mut c_void) as *mut u8))

}

// contract: receiver-mut:_Set,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn set_insert(__param_set: *mut _Set, __param_data: *mut c_void) -> i32 {
    var __local_newentry: *mut _SetEntry

    var __local_rover: *mut _SetEntry

    var __local_index: u32

    if ((((((*__param_set).entries as u32) *% (3 as u32)) as u32) / ((*__param_set).table_size as u32)) > 0) {
        if (not set_enlarge(__param_set)) {
            return 0

        }

    }

    (__local_index = (((((*__param_set).hash_func.unwrap()(__param_data) as u32) % ((*__param_set).table_size as u32)) as u32)))

    (__local_rover = ((*__param_set).table[__local_index]))

    while (__local_rover != null) {
        if ((*__param_set).equal_func.unwrap()(__param_data, (*__local_rover).data) != 0) {
            return 0

        }

        (__local_rover = (*__local_rover).next)

    }

    (__local_newentry = (((with_alloc(((sizeof[_SetEntry]() as u64) as i64)) as *mut c_void) as *mut _SetEntry)))

    if (__local_newentry == null) {
        return 0

    }

    ((*__local_newentry).data = __param_data)

    ((*__local_newentry).next = ((*__param_set).table[__local_index]))

    (((*__param_set).table[__local_index]) = __local_newentry)

    ((*__param_set).entries = ((*__param_set).entries +% 1))

    return 1

}

// contract: receiver-mut:_Set,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn set_remove(__param_set: *mut _Set, __param_data: *mut c_void) -> i32 {
    var __local_rover: *mut *mut _SetEntry

    var __local_entry: *mut _SetEntry

    var __local_index: u32

    (__local_index = (((((*__param_set).hash_func.unwrap()(__param_data) as u32) % ((*__param_set).table_size as u32)) as u32)))

    (__local_rover = (((&raw const ((*__param_set).table[__local_index]) as *const *mut _SetEntry) as *mut *mut _SetEntry)))

    while ((*__local_rover) != null) {
        if ((*__param_set).equal_func.unwrap()(__param_data, (*(*__local_rover)).data) != 0) {
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

// contract: receiver:_Set,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn set_query(__param_set: *mut _Set, __param_data: *mut c_void) -> i32 {
    var __local_rover: *mut _SetEntry

    var __local_index: u32

    (__local_index = (((((*__param_set).hash_func.unwrap()(__param_data) as u32) % ((*__param_set).table_size as u32)) as u32)))

    (__local_rover = ((*__param_set).table[__local_index]))

    while (__local_rover != null) {
        if ((*__param_set).equal_func.unwrap()(__param_data, (*__local_rover).data) != 0) {
            return 1

        }

        (__local_rover = (*__local_rover).next)

    }

    return 0

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn set_to_array(__param_set: *mut _Set) -> *mut *mut c_void {
    var __local_array: *mut *mut c_void

    var __local_array_counter: i32

    var __local_i: u32

    var __local_rover: *mut _SetEntry

    (__local_array = (((with_alloc(((((sizeof[usize]() as u64) *% ((*__param_set).entries as u64)) as u64) as i64)) as *mut c_void) as *mut *mut c_void)))

    if (__local_array == null) {
        return ((null as *mut *mut c_void))

    }

    (__local_array_counter = ((0 as i32)))

    (__local_i = ((0 as u32)))

    while (__local_i < (*__param_set).table_size) {
        (__local_rover = ((*__param_set).table[__local_i]))

        while (__local_rover != null) {
            ((__local_array[__local_array_counter]) = (*__local_rover).data)

            (__local_array_counter = __local_array_counter + 1)

            (__local_rover = (*__local_rover).next)

        }


        (__local_i = (__local_i +% 1))

    }


    return __local_array

}

// contract: stored-unknown:0,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn set_union(__param_set1: *mut _Set, __param_set2: *mut _Set) -> *mut _Set {
    var __local_iterator: _SetIterator

    var __local_new_set: *mut _Set

    var __local_value: *mut c_void

    (__local_new_set = set_new((*__param_set1).hash_func, (*__param_set1).equal_func))

    if (__local_new_set == null) {
        return ((null as *mut _Set))

    }

    set_iterate(__param_set1, (&raw mut __local_iterator as *mut _SetIterator))

    while (*(&raw mut __local_iterator as *mut _SetIterator)).set_iter_has_more() {
        (__local_value = (*(&raw mut __local_iterator as *mut _SetIterator)).set_iter_next())

        if (not set_insert(__local_new_set, __local_value)) {
            set_free(__local_new_set)

            return ((null as *mut _Set))

        }

    }

    set_iterate(__param_set2, (&raw mut __local_iterator as *mut _SetIterator))

    while (*(&raw mut __local_iterator as *mut _SetIterator)).set_iter_has_more() {
        (__local_value = (*(&raw mut __local_iterator as *mut _SetIterator)).set_iter_next())

        if (set_query(__local_new_set, __local_value) == 0) {
            if (not set_insert(__local_new_set, __local_value)) {
                set_free(__local_new_set)

                return ((null as *mut _Set))

            }

        }

    }

    return __local_new_set

}

// contract: stored-unknown:0,unproved:1:read only — stores an argument; ownership not modeled
pub unsafe fn set_intersection(__param_set1: *mut _Set, __param_set2: *mut _Set) -> *mut _Set {
    var __local_new_set: *mut _Set

    var __local_iterator: _SetIterator

    var __local_value: *mut c_void

    (__local_new_set = set_new((*__param_set1).hash_func, (*__param_set2).equal_func))

    if (__local_new_set == null) {
        return ((null as *mut _Set))

    }

    set_iterate(__param_set1, (&raw mut __local_iterator as *mut _SetIterator))

    while (*(&raw mut __local_iterator as *mut _SetIterator)).set_iter_has_more() {
        (__local_value = (*(&raw mut __local_iterator as *mut _SetIterator)).set_iter_next())

        if (set_query(__param_set2, __local_value) != 0) {
            if (not set_insert(__local_new_set, __local_value)) {
                set_free(__local_new_set)

                return ((null as *mut _Set))

            }

        }

    }

    return __local_new_set

}

// contract: stored-unknown:0,unproved:1:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn set_iterate(__param_set: *mut _Set, __param_iter: *mut _SetIterator) {
    var __local_chain: u32

    ((*__param_iter).set = __param_set)

    ((*__param_iter).next_entry = ((null as *mut _SetEntry)))

    (__local_chain = ((0 as u32)))

    while (__local_chain < (*__param_set).table_size) {
        if (((*__param_set).table[__local_chain]) != null) {
            ((*__param_iter).next_entry = ((*__param_set).table[__local_chain]))

            break

        }


        (__local_chain = (__local_chain +% 1))

    }


    ((*__param_iter).next_chain = __local_chain)

}

unsafe fn set_allocate_table(__param_set: *mut _Set) -> i32 {
    if ((*__param_set).prime_index < 24) {
        ((*__param_set).table_size = ((set_primes[(*__param_set).prime_index] as u32)))

    } else {
        ((*__param_set).table_size = (((((*__param_set).entries as u32) *% (10 as u32)) as u32)))

    }

    ((*__param_set).table = (((with_alloc_zeroed((((*__param_set).table_size as u64) as i64), ((sizeof[usize]() as u64) as i64)) as *mut c_void) as *mut *mut _SetEntry)))

    return (if (*__param_set).table != null: 1 else: 0)

}

// contract: receiver:_Set,unproved:1:read only
unsafe fn set_free_entry(__param_set: *mut _Set, __param_entry: *mut _SetEntry) {
    if ((*__param_set).free_func != null) {
        (*__param_set).free_func.unwrap()((*__param_entry).data)

    }

    with_free(((__param_entry as *mut c_void) as *mut u8))

}

unsafe fn set_enlarge(__param_set: *mut _Set) -> i32 {
    var __local_rover: *mut _SetEntry

    var __local_next: *mut _SetEntry

    var __local_old_table: *mut *mut _SetEntry

    var __local_old_table_size: u32

    var __local_old_prime_index: u32

    var __local_index: u32

    var __local_i: u32

    (__local_old_table = (*__param_set).table)

    (__local_old_table_size = (*__param_set).table_size)

    (__local_old_prime_index = (*__param_set).prime_index)

    ((*__param_set).prime_index = ((*__param_set).prime_index +% 1))

    if (not set_allocate_table(__param_set)) {
        ((*__param_set).table = __local_old_table)

        ((*__param_set).table_size = __local_old_table_size)

        ((*__param_set).prime_index = __local_old_prime_index)

        return 0

    }

    (__local_i = ((0 as u32)))

    while (__local_i < __local_old_table_size) {
        (__local_rover = (__local_old_table[__local_i]))

        while (__local_rover != null) {
            (__local_next = (*__local_rover).next)

            (__local_index = (((((*__param_set).hash_func.unwrap()((*__local_rover).data) as u32) % ((*__param_set).table_size as u32)) as u32)))

            ((*__local_rover).next = ((*__param_set).table[__local_index]))

            (((*__param_set).table[__local_index]) = __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    with_free(((__local_old_table as *mut c_void) as *mut u8))

    return 1

}

impl _Set {
    pub mut fn set_register_free_function(__param_free_func: Option[unsafe extern "C" fn(*mut c_void) -> Unit]) {
        let __param_set: *mut _Set = self as *mut _Set
        ((unsafe *__param_set).free_func = __param_free_func)

    }

    pub fn set_num_entries() -> u32 {
        let __param_set: *mut _Set = (self as *const _Set) as *mut _Set
        return (unsafe *__param_set).entries

    }

}

impl _SetIterator {
    pub fn set_iter_has_more() -> i32 {
        let __param_iterator: *mut _SetIterator = (self as *const _SetIterator) as *mut _SetIterator
        return (if (unsafe *__param_iterator).next_entry != null: 1 else: 0)

    }

    pub mut fn set_iter_next() -> *mut c_void {
        let __param_iterator: *mut _SetIterator = self as *mut _SetIterator
        var __local_set: *mut _Set

        var __local_result: *mut c_void

        var __local_current_entry: *mut _SetEntry

        var __local_chain: u32

        (__local_set = (unsafe *__param_iterator).set)

        if ((unsafe *__param_iterator).next_entry == null) {
            return set_null_value

        }

        (__local_current_entry = (unsafe *__param_iterator).next_entry)

        (__local_result = (unsafe *__local_current_entry).data)

        if ((unsafe *__local_current_entry).next != null) {
            ((unsafe *__param_iterator).next_entry = (unsafe *__local_current_entry).next)

        } else {
            ((unsafe *__param_iterator).next_entry = ((null as *mut _SetEntry)))

            (__local_chain = (((((unsafe *__param_iterator).next_chain as u32) +% (1 as u32)) as u32)))

            while (__local_chain < (unsafe *__local_set).table_size) {
                if ((unsafe (*__local_set).table[__local_chain]) != null) {
                    ((unsafe *__param_iterator).next_entry = (unsafe (*__local_set).table[__local_chain]))

                    break

                }

                (__local_chain = (__local_chain +% 1))

            }

            ((unsafe *__param_iterator).next_chain = __local_chain)

        }

        return __local_result

    }

}

let set_primes: List[u32] = [193, 389, 769, 1543, 3079, 6151, 12289, 24593, 49157, 98317, 196613, 393241, 786433, 1572869, 3145739, 6291469, 12582917, 25165843, 50331653, 100663319, 201326611, 402653189, 805306457, 1610612741]
let set_num_primes: u32 = ((((24 * (sizeof[u32]() as usize)) as u64) / (sizeof[i32]() as u64)) as u32)
let set_null_value: *mut c_void = null
