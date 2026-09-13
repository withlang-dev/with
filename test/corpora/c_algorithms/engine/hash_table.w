// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing

pub fn hash_table_new(__param_hash_func: unsafe extern "C" fn(*mut c_void) -> c_uint, __param_equal_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> c_int) -> *mut _HashTable {
    var __local_hash_table: *mut _HashTable

    (__local_hash_table = ((alloc_test_malloc((sizeof[_HashTable]() as c_ulong)) as *mut _HashTable)))

    if ((if __local_hash_table == null: 1 else: 0) != 0) {
        return ((null as *mut _HashTable))

    }

    ((unsafe *__local_hash_table).hash_func = __param_hash_func)

    ((unsafe *__local_hash_table).equal_func = __param_equal_func)

    ((unsafe *__local_hash_table).key_free_func = null)

    ((unsafe *__local_hash_table).value_free_func = null)

    ((unsafe *__local_hash_table).entries = ((0 as c_uint)))

    ((unsafe *__local_hash_table).prime_index = ((0 as c_uint)))

    if ((if not (unsafe { hash_table_allocate_table(__local_hash_table) } != 0): 1 else: 0) != 0) {
        unsafe { alloc_test_free((__local_hash_table as *mut c_void)) }

        return ((null as *mut _HashTable))

    }

    return __local_hash_table

}

pub unsafe fn hash_table_free(__param_hash_table: *mut _HashTable) -> Unit {
    var __local_rover: *mut _HashTableEntry

    var __local_next: *mut _HashTableEntry

    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < (unsafe *__param_hash_table).table_size: 1 else: 0) != 0) {
        (__local_rover = (unsafe (unsafe *__param_hash_table).table[__local_i]))

        while ((if __local_rover != null: 1 else: 0) != 0) {
            (__local_next = (unsafe *__local_rover).next)

            hash_table_free_entry(__param_hash_table, __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    alloc_test_free(((unsafe *__param_hash_table).table as *mut c_void))

    alloc_test_free((__param_hash_table as *mut c_void))

}

pub unsafe fn hash_table_register_free_functions(__param_hash_table: *mut _HashTable, __param_key_free_func: unsafe extern "C" fn(*mut c_void) -> Unit, __param_value_free_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    ((unsafe *__param_hash_table).key_free_func = __param_key_free_func)

    ((unsafe *__param_hash_table).value_free_func = __param_value_free_func)

}

pub unsafe fn hash_table_insert(__param_hash_table: *mut _HashTable, __param_key: *mut c_void, __param_value: *mut c_void) -> c_int {
    var __local_rover: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_newentry: *mut _HashTableEntry

    var __local_index: c_uint

    if ((if (((((unsafe *__param_hash_table).entries as c_uint) *% (3 as c_uint)) as c_uint) / ((unsafe *__param_hash_table).table_size as c_uint)) > 0: 1 else: 0) != 0) {
        if ((if not (hash_table_enlarge(__param_hash_table) != 0): 1 else: 0) != 0) {
            return 0

        }

    }

    (__local_index = (((((unsafe *__param_hash_table).hash_func(__param_key) as c_uint) % ((unsafe *__param_hash_table).table_size as c_uint)) as c_uint)))

    (__local_rover = (unsafe (unsafe *__param_hash_table).table[__local_index]))

    while ((if __local_rover != null: 1 else: 0) != 0) {
        (__local_pair = (((&raw const (unsafe *__local_rover).pair as *const _HashTablePair) as *mut _HashTablePair)))

        if ((if (unsafe *__param_hash_table).equal_func((unsafe *__local_pair).key, __param_key) != 0: 1 else: 0) != 0) {
            if ((if (unsafe *__param_hash_table).value_free_func != null: 1 else: 0) != 0) {
                (unsafe *__param_hash_table).value_free_func((unsafe *__local_pair).value)

            }

            if ((if (unsafe *__param_hash_table).key_free_func != null: 1 else: 0) != 0) {
                (unsafe *__param_hash_table).key_free_func((unsafe *__local_pair).key)

            }

            ((unsafe *__local_pair).key = __param_key)

            ((unsafe *__local_pair).value = __param_value)

            return 1

        }

        (__local_rover = (unsafe *__local_rover).next)

    }

    (__local_newentry = ((alloc_test_malloc((sizeof[_HashTableEntry]() as c_ulong)) as *mut _HashTableEntry)))

    if ((if __local_newentry == null: 1 else: 0) != 0) {
        return 0

    }

    ((unsafe *__local_newentry).pair.key = __param_key)

    ((unsafe *__local_newentry).pair.value = __param_value)

    ((unsafe *__local_newentry).next = (unsafe (unsafe *__param_hash_table).table[__local_index]))

    ((unsafe (unsafe *__param_hash_table).table[__local_index]) = __local_newentry)

    ((unsafe *__param_hash_table).entries = ((unsafe *__param_hash_table).entries +% 1))

    return 1

}

pub unsafe fn hash_table_lookup(__param_hash_table: *mut _HashTable, __param_key: *mut c_void) -> *mut c_void {
    var __local_rover: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_index: c_uint

    (__local_index = (((((unsafe *__param_hash_table).hash_func(__param_key) as c_uint) % ((unsafe *__param_hash_table).table_size as c_uint)) as c_uint)))

    (__local_rover = (unsafe (unsafe *__param_hash_table).table[__local_index]))

    while ((if __local_rover != null: 1 else: 0) != 0) {
        (__local_pair = (((&raw const (unsafe *__local_rover).pair as *const _HashTablePair) as *mut _HashTablePair)))

        if ((if (unsafe *__param_hash_table).equal_func(__param_key, (unsafe *__local_pair).key) != 0: 1 else: 0) != 0) {
            return (unsafe *__local_pair).value

        }

        (__local_rover = (unsafe *__local_rover).next)

    }

    return hash_table_null_value

}

pub unsafe fn hash_table_remove(__param_hash_table: *mut _HashTable, __param_key: *mut c_void) -> c_int {
    var __local_rover: *mut *mut _HashTableEntry

    var __local_entry: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_index: c_uint

    var __local_result: c_int

    (__local_index = (((((unsafe *__param_hash_table).hash_func(__param_key) as c_uint) % ((unsafe *__param_hash_table).table_size as c_uint)) as c_uint)))

    (__local_result = ((0 as c_int)))

    (__local_rover = (((&raw const (unsafe (unsafe *__param_hash_table).table[__local_index]) as *const *mut _HashTableEntry) as *mut *mut _HashTableEntry)))

    while ((if (unsafe *__local_rover) != null: 1 else: 0) != 0) {
        (__local_pair = (((&raw const (unsafe *(unsafe *__local_rover)).pair as *const _HashTablePair) as *mut _HashTablePair)))

        if ((if (unsafe *__param_hash_table).equal_func(__param_key, (unsafe *__local_pair).key) != 0: 1 else: 0) != 0) {
            (__local_entry = (unsafe *__local_rover))

            ((unsafe *__local_rover) = (unsafe *__local_entry).next)

            hash_table_free_entry(__param_hash_table, __local_entry)

            ((unsafe *__param_hash_table).entries = ((unsafe *__param_hash_table).entries -% 1))

            (__local_result = ((1 as c_int)))

            break

        }

        (__local_rover = (((&raw const (unsafe *(unsafe *__local_rover)).next as *const *mut _HashTableEntry) as *mut *mut _HashTableEntry)))

    }

    return __local_result

}

pub unsafe fn hash_table_num_entries(__param_hash_table: *mut _HashTable) -> c_uint {
    return (unsafe *__param_hash_table).entries

}

pub unsafe fn hash_table_iterate(__param_hash_table: *mut _HashTable, __param_iterator: *mut _HashTableIterator) -> Unit {
    var __local_chain: c_uint

    ((unsafe *__param_iterator).hash_table = __param_hash_table)

    ((unsafe *__param_iterator).next_entry = ((null as *mut _HashTableEntry)))

    (__local_chain = ((0 as c_uint)))

    while ((if __local_chain < (unsafe *__param_hash_table).table_size: 1 else: 0) != 0) {
        if ((if (unsafe (unsafe *__param_hash_table).table[__local_chain]) != null: 1 else: 0) != 0) {
            ((unsafe *__param_iterator).next_entry = (unsafe (unsafe *__param_hash_table).table[__local_chain]))

            ((unsafe *__param_iterator).next_chain = __local_chain)

            break

        }


        (__local_chain = (__local_chain +% 1))

    }


}

pub unsafe fn hash_table_iter_has_more(__param_iterator: *mut _HashTableIterator) -> c_int {
    return (if (unsafe *__param_iterator).next_entry != null: 1 else: 0)

}

pub unsafe fn hash_table_iter_next(__param_iterator: *mut _HashTableIterator) -> _HashTablePair {
    var __local_current_entry: *mut _HashTableEntry

    var __local_hash_table: *mut _HashTable

    var __local_pair: _HashTablePair = _HashTablePair { key: (null), value: (null) }

    var __local_chain: c_uint

    (__local_hash_table = (unsafe *__param_iterator).hash_table)

    if ((if (unsafe *__param_iterator).next_entry == null: 1 else: 0) != 0) {
        return __local_pair

    }

    (__local_current_entry = (unsafe *__param_iterator).next_entry)

    with_memcpy((&raw mut __local_pair as *mut u8), (&raw const (unsafe *__local_current_entry).pair as *const u8), sizeof[_HashTablePair]())

    if ((if (unsafe *__local_current_entry).next != null: 1 else: 0) != 0) {
        ((unsafe *__param_iterator).next_entry = (unsafe *__local_current_entry).next)

    } else {
        (__local_chain = (((((unsafe *__param_iterator).next_chain as c_uint) +% (1 as c_uint)) as c_uint)))

        ((unsafe *__param_iterator).next_entry = ((null as *mut _HashTableEntry)))

        while ((if __local_chain < (unsafe *__local_hash_table).table_size: 1 else: 0) != 0) {
            if ((if (unsafe (unsafe *__local_hash_table).table[__local_chain]) != null: 1 else: 0) != 0) {
                ((unsafe *__param_iterator).next_entry = (unsafe (unsafe *__local_hash_table).table[__local_chain]))

                break

            }

            (__local_chain = (__local_chain +% 1))

        }

        ((unsafe *__param_iterator).next_chain = __local_chain)

    }

    return __local_pair

}

unsafe fn hash_table_allocate_table(__param_hash_table: *mut _HashTable) -> c_int {
    var __local_new_table_size: c_uint

    if ((if (unsafe *__param_hash_table).prime_index < 24: 1 else: 0) != 0) {
        (__local_new_table_size = ((hash_table_primes[(unsafe *__param_hash_table).prime_index] as c_uint)))

    } else {
        (__local_new_table_size = (((((unsafe *__param_hash_table).entries as c_uint) *% (10 as c_uint)) as c_uint)))

    }

    ((unsafe *__param_hash_table).table_size = __local_new_table_size)

    ((unsafe *__param_hash_table).table = ((alloc_test_calloc(((unsafe *__param_hash_table).table_size as c_ulong), (sizeof[usize]() as c_ulong)) as *mut *mut _HashTableEntry)))

    return (if (unsafe *__param_hash_table).table != null: 1 else: 0)

}

unsafe fn hash_table_free_entry(__param_hash_table: *mut _HashTable, __param_entry: *mut _HashTableEntry) -> Unit {
    var __local_pair: *mut _HashTablePair

    (__local_pair = (((&raw const (unsafe *__param_entry).pair as *const _HashTablePair) as *mut _HashTablePair)))

    if ((if (unsafe *__param_hash_table).key_free_func != null: 1 else: 0) != 0) {
        (unsafe *__param_hash_table).key_free_func((unsafe *__local_pair).key)

    }

    if ((if (unsafe *__param_hash_table).value_free_func != null: 1 else: 0) != 0) {
        (unsafe *__param_hash_table).value_free_func((unsafe *__local_pair).value)

    }

    alloc_test_free((__param_entry as *mut c_void))

}

unsafe fn hash_table_enlarge(__param_hash_table: *mut _HashTable) -> c_int {
    var __local_old_table: *mut *mut _HashTableEntry

    var __local_old_table_size: c_uint

    var __local_old_prime_index: c_uint

    var __local_rover: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_next: *mut _HashTableEntry

    var __local_index: c_uint

    var __local_i: c_uint

    (__local_old_table = (unsafe *__param_hash_table).table)

    (__local_old_table_size = (unsafe *__param_hash_table).table_size)

    (__local_old_prime_index = (unsafe *__param_hash_table).prime_index)

    ((unsafe *__param_hash_table).prime_index = ((unsafe *__param_hash_table).prime_index +% 1))

    if ((if not (hash_table_allocate_table(__param_hash_table) != 0): 1 else: 0) != 0) {
        ((unsafe *__param_hash_table).table = __local_old_table)

        ((unsafe *__param_hash_table).table_size = __local_old_table_size)

        ((unsafe *__param_hash_table).prime_index = __local_old_prime_index)

        return 0

    }

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < __local_old_table_size: 1 else: 0) != 0) {
        (__local_rover = (unsafe __local_old_table[__local_i]))

        while ((if __local_rover != null: 1 else: 0) != 0) {
            (__local_next = (unsafe *__local_rover).next)

            (__local_pair = (((&raw const (unsafe *__local_rover).pair as *const _HashTablePair) as *mut _HashTablePair)))

            (__local_index = (((((unsafe *__param_hash_table).hash_func((unsafe *__local_pair).key) as c_uint) % ((unsafe *__param_hash_table).table_size as c_uint)) as c_uint)))

            ((unsafe *__local_rover).next = (unsafe (unsafe *__param_hash_table).table[__local_index]))

            ((unsafe (unsafe *__param_hash_table).table[__local_index]) = __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    alloc_test_free((__local_old_table as *mut c_void))

    return 1

}

let hash_table_primes: [24]c_uint = [(193 as c_uint), (389 as c_uint), (769 as c_uint), (1543 as c_uint), (3079 as c_uint), (6151 as c_uint), (12289 as c_uint), (24593 as c_uint), (49157 as c_uint), (98317 as c_uint), (196613 as c_uint), (393241 as c_uint), (786433 as c_uint), (1572869 as c_uint), (3145739 as c_uint), (6291469 as c_uint), (12582917 as c_uint), (25165843 as c_uint), (50331653 as c_uint), (100663319 as c_uint), (201326611 as c_uint), (402653189 as c_uint), (805306457 as c_uint), (1610612741 as c_uint)]
let hash_table_num_primes: c_uint = 24
let hash_table_null_value: *mut c_void = null
