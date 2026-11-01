// Migrated from C
use std.engines.c_algorithms.defs
use std.option
use std.collections

pub fn hash_table_new(__param_hash_func: Option[unsafe extern "C" fn(*mut c_void) -> u32], __param_equal_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> i32]) -> *mut _HashTable {
    var __local_hash_table: *mut _HashTable

    (__local_hash_table = (((with_alloc(((sizeof[_HashTable]() as u64) as i64)) as *mut c_void) as *mut _HashTable)))

    if (__local_hash_table == null) {
        return ((null as *mut _HashTable))

    }

    ((unsafe *__local_hash_table).hash_func = __param_hash_func)

    ((unsafe *__local_hash_table).equal_func = __param_equal_func)

    ((unsafe *__local_hash_table).key_free_func = null)

    ((unsafe *__local_hash_table).value_free_func = null)

    ((unsafe *__local_hash_table).entries = ((0 as u32)))

    ((unsafe *__local_hash_table).prime_index = ((0 as u32)))

    if (not unsafe { hash_table_allocate_table(__local_hash_table) }) {
        with_free(((__local_hash_table as *mut c_void) as *mut u8))

        return ((null as *mut _HashTable))

    }

    return __local_hash_table

}

// contract: unproved:0:frees a part of it
pub unsafe fn hash_table_free(__param_hash_table: *mut _HashTable) {
    var __local_rover: *mut _HashTableEntry

    var __local_next: *mut _HashTableEntry

    var __local_i: u32

    (__local_i = ((0 as u32)))

    while (__local_i < (*__param_hash_table).table_size) {
        (__local_rover = ((*__param_hash_table).table[__local_i]))

        while (__local_rover != null) {
            (__local_next = (*__local_rover).next)

            hash_table_free_entry(__param_hash_table, __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    with_free((((*__param_hash_table).table as *mut c_void) as *mut u8))

    with_free(((__param_hash_table as *mut c_void) as *mut u8))

}

// contract: receiver-mut:_HashTable,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn hash_table_insert(__param_hash_table: *mut _HashTable, __param_key: *mut c_void, __param_value: *mut c_void) -> i32 {
    var __local_rover: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_newentry: *mut _HashTableEntry

    var __local_index: u32

    if ((((((*__param_hash_table).entries as u32) *% (3 as u32)) as u32) / ((*__param_hash_table).table_size as u32)) > 0) {
        if (not hash_table_enlarge(__param_hash_table)) {
            return 0

        }

    }

    (__local_index = (((((*__param_hash_table).hash_func.unwrap()(__param_key) as u32) % ((*__param_hash_table).table_size as u32)) as u32)))

    (__local_rover = ((*__param_hash_table).table[__local_index]))

    while (__local_rover != null) {
        (__local_pair = (((&raw const (*__local_rover).pair as *const _HashTablePair) as *mut _HashTablePair)))

        if ((*__param_hash_table).equal_func.unwrap()((*__local_pair).key, __param_key) != 0) {
            if ((*__param_hash_table).value_free_func != null) {
                (*__param_hash_table).value_free_func.unwrap()((*__local_pair).value)

            }

            if ((*__param_hash_table).key_free_func != null) {
                (*__param_hash_table).key_free_func.unwrap()((*__local_pair).key)

            }

            ((*__local_pair).key = __param_key)

            ((*__local_pair).value = __param_value)

            return 1

        }

        (__local_rover = (*__local_rover).next)

    }

    (__local_newentry = (((with_alloc(((sizeof[_HashTableEntry]() as u64) as i64)) as *mut c_void) as *mut _HashTableEntry)))

    if (__local_newentry == null) {
        return 0

    }

    ((*__local_newentry).pair.key = __param_key)

    ((*__local_newentry).pair.value = __param_value)

    ((*__local_newentry).next = ((*__param_hash_table).table[__local_index]))

    (((*__param_hash_table).table[__local_index]) = __local_newentry)

    ((*__param_hash_table).entries = ((*__param_hash_table).entries +% 1))

    return 1

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn hash_table_lookup(__param_hash_table: *mut _HashTable, __param_key: *mut c_void) -> *mut c_void {
    var __local_rover: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_index: u32

    (__local_index = (((((*__param_hash_table).hash_func.unwrap()(__param_key) as u32) % ((*__param_hash_table).table_size as u32)) as u32)))

    (__local_rover = ((*__param_hash_table).table[__local_index]))

    while (__local_rover != null) {
        (__local_pair = (((&raw const (*__local_rover).pair as *const _HashTablePair) as *mut _HashTablePair)))

        if ((*__param_hash_table).equal_func.unwrap()(__param_key, (*__local_pair).key) != 0) {
            return (*__local_pair).value

        }

        (__local_rover = (*__local_rover).next)

    }

    return hash_table_null_value

}

// contract: receiver-mut:_HashTable,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn hash_table_remove(__param_hash_table: *mut _HashTable, __param_key: *mut c_void) -> i32 {
    var __local_rover: *mut *mut _HashTableEntry

    var __local_entry: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_index: u32

    var __local_result: i32

    (__local_index = (((((*__param_hash_table).hash_func.unwrap()(__param_key) as u32) % ((*__param_hash_table).table_size as u32)) as u32)))

    (__local_result = ((0 as i32)))

    (__local_rover = (((&raw const ((*__param_hash_table).table[__local_index]) as *const *mut _HashTableEntry) as *mut *mut _HashTableEntry)))

    while ((*__local_rover) != null) {
        (__local_pair = (((&raw const (*(*__local_rover)).pair as *const _HashTablePair) as *mut _HashTablePair)))

        if ((*__param_hash_table).equal_func.unwrap()(__param_key, (*__local_pair).key) != 0) {
            (__local_entry = (*__local_rover))

            ((*__local_rover) = (*__local_entry).next)

            hash_table_free_entry(__param_hash_table, __local_entry)

            ((*__param_hash_table).entries = ((*__param_hash_table).entries -% 1))

            (__local_result = ((1 as i32)))

            break

        }

        (__local_rover = (((&raw const (*(*__local_rover)).next as *const *mut _HashTableEntry) as *mut *mut _HashTableEntry)))

    }

    return __local_result

}

// contract: stored-unknown:0,unproved:1:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn hash_table_iterate(__param_hash_table: *mut _HashTable, __param_iterator: *mut _HashTableIterator) {
    var __local_chain: u32

    ((*__param_iterator).hash_table = __param_hash_table)

    ((*__param_iterator).next_entry = ((null as *mut _HashTableEntry)))

    (__local_chain = ((0 as u32)))

    while (__local_chain < (*__param_hash_table).table_size) {
        if (((*__param_hash_table).table[__local_chain]) != null) {
            ((*__param_iterator).next_entry = ((*__param_hash_table).table[__local_chain]))

            ((*__param_iterator).next_chain = __local_chain)

            break

        }


        (__local_chain = (__local_chain +% 1))

    }


}

unsafe fn hash_table_allocate_table(__param_hash_table: *mut _HashTable) -> i32 {
    var __local_new_table_size: u32

    if ((*__param_hash_table).prime_index < 24) {
        (__local_new_table_size = ((hash_table_primes[(*__param_hash_table).prime_index] as u32)))

    } else {
        (__local_new_table_size = (((((*__param_hash_table).entries as u32) *% (10 as u32)) as u32)))

    }

    ((*__param_hash_table).table_size = __local_new_table_size)

    ((*__param_hash_table).table = (((with_alloc_zeroed((((*__param_hash_table).table_size as u64) as i64), ((sizeof[usize]() as u64) as i64)) as *mut c_void) as *mut *mut _HashTableEntry)))

    return (if (*__param_hash_table).table != null: 1 else: 0)

}

// contract: receiver:_HashTable,unproved:1:read only
unsafe fn hash_table_free_entry(__param_hash_table: *mut _HashTable, __param_entry: *mut _HashTableEntry) {
    var __local_pair: *mut _HashTablePair

    (__local_pair = (((&raw const (*__param_entry).pair as *const _HashTablePair) as *mut _HashTablePair)))

    if ((*__param_hash_table).key_free_func != null) {
        (*__param_hash_table).key_free_func.unwrap()((*__local_pair).key)

    }

    if ((*__param_hash_table).value_free_func != null) {
        (*__param_hash_table).value_free_func.unwrap()((*__local_pair).value)

    }

    with_free(((__param_entry as *mut c_void) as *mut u8))

}

unsafe fn hash_table_enlarge(__param_hash_table: *mut _HashTable) -> i32 {
    var __local_old_table: *mut *mut _HashTableEntry

    var __local_old_table_size: u32

    var __local_old_prime_index: u32

    var __local_rover: *mut _HashTableEntry

    var __local_pair: *mut _HashTablePair

    var __local_next: *mut _HashTableEntry

    var __local_index: u32

    var __local_i: u32

    (__local_old_table = (*__param_hash_table).table)

    (__local_old_table_size = (*__param_hash_table).table_size)

    (__local_old_prime_index = (*__param_hash_table).prime_index)

    ((*__param_hash_table).prime_index = ((*__param_hash_table).prime_index +% 1))

    if (not hash_table_allocate_table(__param_hash_table)) {
        ((*__param_hash_table).table = __local_old_table)

        ((*__param_hash_table).table_size = __local_old_table_size)

        ((*__param_hash_table).prime_index = __local_old_prime_index)

        return 0

    }

    (__local_i = ((0 as u32)))

    while (__local_i < __local_old_table_size) {
        (__local_rover = (__local_old_table[__local_i]))

        while (__local_rover != null) {
            (__local_next = (*__local_rover).next)

            (__local_pair = (((&raw const (*__local_rover).pair as *const _HashTablePair) as *mut _HashTablePair)))

            (__local_index = (((((*__param_hash_table).hash_func.unwrap()((*__local_pair).key) as u32) % ((*__param_hash_table).table_size as u32)) as u32)))

            ((*__local_rover).next = ((*__param_hash_table).table[__local_index]))

            (((*__param_hash_table).table[__local_index]) = __local_rover)

            (__local_rover = __local_next)

        }


        (__local_i = (__local_i +% 1))

    }


    with_free(((__local_old_table as *mut c_void) as *mut u8))

    return 1

}

impl _HashTable {
    pub mut fn hash_table_register_free_functions(__param_key_free_func: Option[unsafe extern "C" fn(*mut c_void) -> Unit], __param_value_free_func: Option[unsafe extern "C" fn(*mut c_void) -> Unit]) {
        let __param_hash_table: *mut _HashTable = self as *mut _HashTable
        ((unsafe *__param_hash_table).key_free_func = __param_key_free_func)

        ((unsafe *__param_hash_table).value_free_func = __param_value_free_func)

    }

    pub fn hash_table_num_entries() -> u32 {
        let __param_hash_table: *mut _HashTable = (self as *const _HashTable) as *mut _HashTable
        return (unsafe *__param_hash_table).entries

    }

}

impl _HashTableIterator {
    pub fn hash_table_iter_has_more() -> i32 {
        let __param_iterator: *mut _HashTableIterator = (self as *const _HashTableIterator) as *mut _HashTableIterator
        return (if (unsafe *__param_iterator).next_entry != null: 1 else: 0)

    }

    pub mut fn hash_table_iter_next() -> _HashTablePair {
        let __param_iterator: *mut _HashTableIterator = self as *mut _HashTableIterator
        var __local_current_entry: *mut _HashTableEntry

        var __local_hash_table: *mut _HashTable

        var __local_pair: _HashTablePair = _HashTablePair { key: (null), value: (null) }

        var __local_chain: u32

        (__local_hash_table = (unsafe *__param_iterator).hash_table)

        if ((unsafe *__param_iterator).next_entry == null) {
            return __local_pair

        }

        (__local_current_entry = (unsafe *__param_iterator).next_entry)

        with_memcpy((&raw mut __local_pair as *mut u8), (&raw const (unsafe *__local_current_entry).pair as *const u8), sizeof[_HashTablePair]())

        if ((unsafe *__local_current_entry).next != null) {
            ((unsafe *__param_iterator).next_entry = (unsafe *__local_current_entry).next)

        } else {
            (__local_chain = (((((unsafe *__param_iterator).next_chain as u32) +% (1 as u32)) as u32)))

            ((unsafe *__param_iterator).next_entry = ((null as *mut _HashTableEntry)))

            while (__local_chain < (unsafe *__local_hash_table).table_size) {
                if ((unsafe (*__local_hash_table).table[__local_chain]) != null) {
                    ((unsafe *__param_iterator).next_entry = (unsafe (*__local_hash_table).table[__local_chain]))

                    break

                }

                (__local_chain = (__local_chain +% 1))

            }

            ((unsafe *__param_iterator).next_chain = __local_chain)

        }

        return __local_pair

    }

}

let hash_table_primes: List[u32] = [193, 389, 769, 1543, 3079, 6151, 12289, 24593, 49157, 98317, 196613, 393241, 786433, 1572869, 3145739, 6291469, 12582917, 25165843, 50331653, 100663319, 201326611, 402653189, 805306457, 1610612741]
let hash_table_num_primes: u32 = ((((24 * (sizeof[u32]() as usize)) as u64) / (sizeof[i32]() as u64)) as u32)
let hash_table_null_value: *mut c_void = null
