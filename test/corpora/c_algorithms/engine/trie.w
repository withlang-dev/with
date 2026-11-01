// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.engines.c_algorithms_testing.alloc_testing

pub fn trie_new() -> *mut _Trie writes allocation_limit {
    var __local_new_trie: *mut _Trie

    (__local_new_trie = ((alloc_test_malloc((sizeof[_Trie]() as u64)) as *mut _Trie)))

    if (__local_new_trie == null) {
        return ((null as *mut _Trie))

    }

    ((unsafe *__local_new_trie).root_node = ((null as *mut _TrieNode)))

    return __local_new_trie

}

// contract: unproved:0:NULL is an accepted argument
pub unsafe fn trie_free(__param_trie: *mut _Trie) {
    free_node_recursive((*__param_trie).root_node)

    alloc_test_free((__param_trie as *mut c_void))

}

// contract: receiver:_Trie,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn trie_insert(__param_trie: *mut _Trie, __param_key: *mut c_char, __param_value: *mut c_void) -> i32 writes allocation_limit {
    var __local_rover: *mut *mut _TrieNode

    var __local_node: *mut _TrieNode

    var __local_p: *mut c_char

    var __local_c: i32

    if trie_value_is_null((&raw mut __param_value as *mut *mut c_void)) {
        return 0

    }

    (__local_node = trie_find_end(__param_trie, __param_key))

    var __ci_expr_logic_0: i32 = 0

    if (__local_node != null) {
        (__ci_expr_logic_0 = (if not trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)): 1 else: 0))
    }

    if __ci_expr_logic_0 {
        ((*__local_node).data = __param_value)

        return 1

    }


    (__local_rover = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = __param_key)

    while true {
        (__local_node = (*__local_rover))

        if (__local_node == null) {
            (__local_node = ((alloc_test_calloc((1 as u64), (sizeof[_TrieNode]() as u64)) as *mut _TrieNode)))

            if (__local_node == null) {
                trie_insert_rollback(__param_trie, (__param_key as *mut u8))

                return 0

            }

            ((*__local_node).data = trie_null_value)

            ((*__local_rover) = __local_node)

        }

        ((*__local_node).use_count = ((*__local_node).use_count +% 1))

        (__local_c = ((((*__local_p) as u8) as i32)))

        if (__local_c == 0) {
            ((*__local_node).data = __param_value)

            break

        }

        (__local_rover = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        (__local_p = __local_p + 1)

    }

    return 1

}

// contract: receiver:_Trie,stored-unknown:1,stored-unknown:3 — stores an argument; ownership not modeled
pub unsafe fn trie_insert_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: i32, __param_value: *mut c_void) -> i32 writes allocation_limit {
    var __local_rover: *mut *mut _TrieNode

    var __local_node: *mut _TrieNode

    var __local_p: i32

    var __local_c: i32


    if trie_value_is_null((&raw mut __param_value as *mut *mut c_void)) {
        return 0

    }

    (__local_node = trie_find_end_binary(__param_trie, __param_key, __param_key_length))

    var __ci_expr_logic_0: i32 = 0

    if (__local_node != null) {
        (__ci_expr_logic_0 = (if not trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)): 1 else: 0))
    }

    if __ci_expr_logic_0 {
        ((*__local_node).data = __param_value)

        return 1

    }


    (__local_rover = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = ((0 as i32)))

    while true {
        (__local_node = (*__local_rover))

        if (__local_node == null) {
            (__local_node = ((alloc_test_calloc((1 as u64), (sizeof[_TrieNode]() as u64)) as *mut _TrieNode)))

            if (__local_node == null) {
                trie_insert_rollback(__param_trie, __param_key)

                return 0

            }

            ((*__local_node).data = trie_null_value)

            ((*__local_rover) = __local_node)

        }

        ((*__local_node).use_count = ((*__local_node).use_count +% 1))

        (__local_c = (((__param_key[__local_p]) as i32)))

        if (__local_p == __param_key_length) {
            ((*__local_node).data = __param_value)

            break

        }

        (__local_rover = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        (__local_p = __local_p + 1)

    }

    return 1

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn trie_lookup(__param_trie: *mut _Trie, __param_key: *mut c_char) -> *mut c_void {
    var __local_node: *mut _TrieNode

    (__local_node = trie_find_end(__param_trie, __param_key))

    if (__local_node != null) {
        return (*__local_node).data

    }
    return trie_null_value


}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:1:read only
pub unsafe fn trie_lookup_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: i32) -> *mut c_void {
    var __local_node: *mut _TrieNode

    (__local_node = trie_find_end_binary(__param_trie, __param_key, __param_key_length))

    if (__local_node != null) {
        return (*__local_node).data

    }
    return trie_null_value


}

// contract: receiver:_Trie,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn trie_remove(__param_trie: *mut _Trie, __param_key: *mut c_char) -> i32 {
    var __local_node: *mut _TrieNode

    var __local_next: *mut _TrieNode

    var __local_last_next_ptr: *mut *mut _TrieNode

    var __local_p: *mut c_char

    var __local_c: i32

    (__local_node = trie_find_end(__param_trie, __param_key))

    var __ci_expr_logic_0: i32 = 0

    if (__local_node != null) {
        (__ci_expr_logic_0 = (if not trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)): 1 else: 0))
    }

    if __ci_expr_logic_0 {
        ((*__local_node).data = trie_null_value)

    } else {
        return 0

    }


    (__local_node = (*__param_trie).root_node)

    (__local_last_next_ptr = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = __param_key)

    while true {
        (__local_c = ((((*__local_p) as u8) as i32)))

        (__local_next = (*__local_node).next[__local_c])

        ((*__local_node).use_count = ((*__local_node).use_count -% 1))

        if ((*__local_node).use_count <= 0) {
            alloc_test_free((__local_node as *mut c_void))

            if (__local_last_next_ptr != null) {
                ((*__local_last_next_ptr) = ((null as *mut _TrieNode)))

                (__local_last_next_ptr = ((null as *mut *mut _TrieNode)))

            }

        }

        if (__local_c == 0) {
            break

        }
        (__local_p = __local_p + 1)


        if (__local_last_next_ptr != null) {
            (__local_last_next_ptr = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        }

        (__local_node = __local_next)

    }

    return 1

}

// contract: receiver:_Trie,unproved:1:read only
pub unsafe fn trie_remove_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: i32) -> i32 {
    var __local_node: *mut _TrieNode

    var __local_next: *mut _TrieNode

    var __local_last_next_ptr: *mut *mut _TrieNode

    var __local_p: i32

    var __local_c: i32


    (__local_node = trie_find_end_binary(__param_trie, __param_key, __param_key_length))

    var __ci_expr_logic_0: i32 = 0

    if (__local_node != null) {
        (__ci_expr_logic_0 = (if not trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)): 1 else: 0))
    }

    if __ci_expr_logic_0 {
        ((*__local_node).data = trie_null_value)

    } else {
        return 0

    }


    (__local_node = (*__param_trie).root_node)

    (__local_last_next_ptr = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = ((0 as i32)))

    while true {
        (__local_c = (((__param_key[__local_p]) as i32)))

        (__local_next = (*__local_node).next[__local_c])

        ((*__local_node).use_count = ((*__local_node).use_count -% 1))

        if ((*__local_node).use_count <= 0) {
            alloc_test_free((__local_node as *mut c_void))

            if (__local_last_next_ptr != null) {
                ((*__local_last_next_ptr) = ((null as *mut _TrieNode)))

                (__local_last_next_ptr = ((null as *mut *mut _TrieNode)))

            }

        }

        if (__local_p == __param_key_length) {
            break

        }
        (__local_p = __local_p + 1)


        if (__local_last_next_ptr != null) {
            (__local_last_next_ptr = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        }

        (__local_node = __local_next)

    }

    return 1

}

// contract: unproved:0:NULL is an accepted argument
unsafe fn free_node_recursive(__param_node: *mut _TrieNode) -> Unit {
    var __local_i: i32

    if (__param_node == null) {
        return

    }

    (__local_i = ((0 as i32)))

    while (__local_i < 256) {
        free_node_recursive((*__param_node).next[__local_i])


        (__local_i = __local_i + 1)

    }


    alloc_test_free((__param_node as *mut c_void))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn trie_find_end(__param_trie: *mut _Trie, __param_key: *mut c_char) -> *mut _TrieNode {
    var __local_node: *mut _TrieNode

    var __local_p: *mut c_char

    (__local_node = (*__param_trie).root_node)

    (__local_p = __param_key)

    while ((*__local_p) != 0) {
        if (__local_node == null) {
            return ((null as *mut _TrieNode))

        }

        (__local_node = (*__local_node).next[((*__local_p) as u8)])


        (__local_p = __local_p + 1)

    }


    return __local_node

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:1:read only
unsafe fn trie_find_end_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: i32) -> *mut _TrieNode {
    var __local_node: *mut _TrieNode

    var __local_j: i32

    var __local_c: i32

    (__local_node = (*__param_trie).root_node)

    (__local_j = ((0 as i32)))

    while (__local_j < __param_key_length) {
        if (__local_node == null) {
            return ((null as *mut _TrieNode))

        }

        (__local_c = (((__param_key[__local_j]) as i32)))

        (__local_node = (*__local_node).next[__local_c])


        (__local_j = __local_j + 1)

    }


    return __local_node

}

// contract: receiver:_Trie,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn trie_insert_rollback(__param_trie: *mut _Trie, __param_key: *mut u8) {
    var __local_node: *mut _TrieNode

    var __local_prev_ptr: *mut *mut _TrieNode

    var __local_next_node: *mut _TrieNode

    var __local_next_prev_ptr: *mut *mut _TrieNode

    var __local_p: *mut u8

    (__local_node = (*__param_trie).root_node)

    (__local_prev_ptr = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = __param_key)

    while (__local_node != null) {
        (__local_next_prev_ptr = (((&raw const (*__local_node).next[(*__local_p)] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        (__local_next_node = (*__local_next_prev_ptr))

        (__local_p = __local_p + 1)

        ((*__local_node).use_count = ((*__local_node).use_count -% 1))

        if ((*__local_node).use_count == 0) {
            alloc_test_free((__local_node as *mut c_void))

            if (__local_prev_ptr != null) {
                ((*__local_prev_ptr) = ((null as *mut _TrieNode)))

            }

            (__local_next_prev_ptr = ((null as *mut *mut _TrieNode)))

        }

        (__local_node = __local_next_node)

        (__local_prev_ptr = __local_next_prev_ptr)

    }

}

// contract: unproved:0:read only
unsafe fn trie_value_is_null(__param_v: *mut *mut c_void) -> i32 {
    return (if not with_memcmp(((__param_v as *const c_void) as *const u8), (((&raw const trie_null_value as *const *mut c_void) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64)): 1 else: 0)

}

impl _Trie {
    pub fn trie_num_entries() -> u32 {
        let __param_trie: *mut _Trie = (self as *const _Trie) as *mut _Trie
        if ((unsafe *__param_trie).root_node == null) {
            return ((0 as u32))

        }
        return (unsafe *(*__param_trie).root_node).use_count


    }

}

let trie_null_value: *mut c_void = null
