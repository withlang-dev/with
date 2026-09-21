// Migrated from C
use std.calg_testing.defs
use std.calg_testing.alloc_testing

pub fn trie_new() -> *mut _Trie {
    var __local_new_trie: *mut _Trie

    (__local_new_trie = ((alloc_test_malloc((sizeof[_Trie]() as c_ulong)) as *mut _Trie)))

    if ((if __local_new_trie == null: 1 else: 0) != 0) {
        return ((null as *mut _Trie))

    }

    ((unsafe *__local_new_trie).root_node = ((null as *mut _TrieNode)))

    return __local_new_trie

}

pub unsafe fn trie_free(__param_trie: *mut _Trie) -> Unit {
    free_node_recursive((*__param_trie).root_node)

    alloc_test_free((__param_trie as *mut c_void))

}

pub unsafe fn trie_insert(__param_trie: *mut _Trie, __param_key: *mut i8, __param_value: *mut c_void) -> c_int {
    var __local_rover: *mut *mut _TrieNode

    var __local_node: *mut _TrieNode

    var __local_p: *mut c_char

    var __local_c: c_int

    if (trie_value_is_null((&raw mut __param_value as *mut *mut c_void)) != 0) {
        return 0

    }

    (__local_node = trie_find_end(__param_trie, __param_key))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_node != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__local_node).data = __param_value)

        return 1

    }


    (__local_rover = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = ((__param_key as *mut c_char)))

    while true {
        (__local_node = (*__local_rover))

        if ((if __local_node == null: 1 else: 0) != 0) {
            (__local_node = ((alloc_test_calloc((1 as c_ulong), (sizeof[_TrieNode]() as c_ulong)) as *mut _TrieNode)))

            if ((if __local_node == null: 1 else: 0) != 0) {
                trie_insert_rollback(__param_trie, (__param_key as *mut u8))

                return 0

            }

            ((*__local_node).data = trie_null_value)

            ((*__local_rover) = __local_node)

        }

        ((*__local_node).use_count = ((*__local_node).use_count +% 1))

        (__local_c = ((((*__local_p) as u8) as c_int)))

        if ((if __local_c == 0: 1 else: 0) != 0) {
            ((*__local_node).data = __param_value)

            break

        }

        (__local_rover = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        (__local_p = __local_p + 1)

    }

    return 1

}

pub unsafe fn trie_insert_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: c_int, __param_value: *mut c_void) -> c_int {
    var __local_rover: *mut *mut _TrieNode

    var __local_node: *mut _TrieNode

    var __local_p: c_int

    var __local_c: c_int


    if (trie_value_is_null((&raw mut __param_value as *mut *mut c_void)) != 0) {
        return 0

    }

    (__local_node = trie_find_end_binary(__param_trie, __param_key, __param_key_length))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_node != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__local_node).data = __param_value)

        return 1

    }


    (__local_rover = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = ((0 as c_int)))

    while true {
        (__local_node = (*__local_rover))

        if ((if __local_node == null: 1 else: 0) != 0) {
            (__local_node = ((alloc_test_calloc((1 as c_ulong), (sizeof[_TrieNode]() as c_ulong)) as *mut _TrieNode)))

            if ((if __local_node == null: 1 else: 0) != 0) {
                trie_insert_rollback(__param_trie, __param_key)

                return 0

            }

            ((*__local_node).data = trie_null_value)

            ((*__local_rover) = __local_node)

        }

        ((*__local_node).use_count = ((*__local_node).use_count +% 1))

        (__local_c = (((__param_key[__local_p]) as c_int)))

        if ((if __local_p == __param_key_length: 1 else: 0) != 0) {
            ((*__local_node).data = __param_value)

            break

        }

        (__local_rover = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        (__local_p = __local_p + 1)

    }

    return 1

}

pub unsafe fn trie_lookup(__param_trie: *mut _Trie, __param_key: *mut i8) -> *mut c_void {
    var __local_node: *mut _TrieNode

    (__local_node = trie_find_end(__param_trie, __param_key))

    if ((if __local_node != null: 1 else: 0) != 0) {
        return (*__local_node).data

    }
    return trie_null_value


}

pub unsafe fn trie_lookup_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: c_int) -> *mut c_void {
    var __local_node: *mut _TrieNode

    (__local_node = trie_find_end_binary(__param_trie, __param_key, __param_key_length))

    if ((if __local_node != null: 1 else: 0) != 0) {
        return (*__local_node).data

    }
    return trie_null_value


}

pub unsafe fn trie_remove(__param_trie: *mut _Trie, __param_key: *mut i8) -> c_int {
    var __local_node: *mut _TrieNode

    var __local_next: *mut _TrieNode

    var __local_last_next_ptr: *mut *mut _TrieNode

    var __local_p: *mut c_char

    var __local_c: c_int

    (__local_node = trie_find_end(__param_trie, __param_key))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_node != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__local_node).data = trie_null_value)

    } else {
        return 0

    }


    (__local_node = (*__param_trie).root_node)

    (__local_last_next_ptr = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = ((__param_key as *mut c_char)))

    while true {
        (__local_c = ((((*__local_p) as u8) as c_int)))

        (__local_next = (*__local_node).next[__local_c])

        ((*__local_node).use_count = ((*__local_node).use_count -% 1))

        if ((if (*__local_node).use_count <= 0: 1 else: 0) != 0) {
            alloc_test_free((__local_node as *mut c_void))

            if ((if __local_last_next_ptr != null: 1 else: 0) != 0) {
                ((*__local_last_next_ptr) = ((null as *mut _TrieNode)))

                (__local_last_next_ptr = ((null as *mut *mut _TrieNode)))

            }

        }

        if ((if __local_c == 0: 1 else: 0) != 0) {
            break

        }
        (__local_p = __local_p + 1)


        if ((if __local_last_next_ptr != null: 1 else: 0) != 0) {
            (__local_last_next_ptr = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        }

        (__local_node = __local_next)

    }

    return 1

}

pub unsafe fn trie_remove_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: c_int) -> c_int {
    var __local_node: *mut _TrieNode

    var __local_next: *mut _TrieNode

    var __local_last_next_ptr: *mut *mut _TrieNode

    var __local_p: c_int

    var __local_c: c_int


    (__local_node = trie_find_end_binary(__param_trie, __param_key, __param_key_length))

    var __ci_expr_logic_0: c_int = 0

    if ((if __local_node != null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if not (trie_value_is_null(((&raw const (*__local_node).data as *const *mut c_void) as *mut *mut c_void)) != 0): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((*__local_node).data = trie_null_value)

    } else {
        return 0

    }


    (__local_node = (*__param_trie).root_node)

    (__local_last_next_ptr = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = ((0 as c_int)))

    while true {
        (__local_c = (((__param_key[__local_p]) as c_int)))

        (__local_next = (*__local_node).next[__local_c])

        ((*__local_node).use_count = ((*__local_node).use_count -% 1))

        if ((if (*__local_node).use_count <= 0: 1 else: 0) != 0) {
            alloc_test_free((__local_node as *mut c_void))

            if ((if __local_last_next_ptr != null: 1 else: 0) != 0) {
                ((*__local_last_next_ptr) = ((null as *mut _TrieNode)))

                (__local_last_next_ptr = ((null as *mut *mut _TrieNode)))

            }

        }

        if ((if __local_p == __param_key_length: 1 else: 0) != 0) {
            break

        }
        (__local_p = __local_p + 1)


        if ((if __local_last_next_ptr != null: 1 else: 0) != 0) {
            (__local_last_next_ptr = (((&raw const (*__local_node).next[__local_c] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        }

        (__local_node = __local_next)

    }

    return 1

}

pub unsafe fn trie_num_entries(__param_trie: *mut _Trie) -> c_uint {
    if ((if (*__param_trie).root_node == null: 1 else: 0) != 0) {
        return 0

    }
    return (*(*__param_trie).root_node).use_count


}

unsafe fn free_node_recursive(__param_node: *mut _TrieNode) -> Unit {
    var __local_i: c_int

    if ((if __param_node == null: 1 else: 0) != 0) {
        return

    }

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 256: 1 else: 0) != 0) {
        free_node_recursive((*__param_node).next[__local_i])


        (__local_i = __local_i + 1)

    }


    alloc_test_free((__param_node as *mut c_void))

}

unsafe fn trie_find_end(__param_trie: *mut _Trie, __param_key: *mut i8) -> *mut _TrieNode {
    var __local_node: *mut _TrieNode

    var __local_p: *mut c_char

    (__local_node = (*__param_trie).root_node)

    (__local_p = ((__param_key as *mut c_char)))

    while ((if (*__local_p) != 0: 1 else: 0) != 0) {
        if ((if __local_node == null: 1 else: 0) != 0) {
            return ((null as *mut _TrieNode))

        }

        (__local_node = (*__local_node).next[((*__local_p) as u8)])


        (__local_p = __local_p + 1)

    }


    return __local_node

}

unsafe fn trie_find_end_binary(__param_trie: *mut _Trie, __param_key: *mut u8, __param_key_length: c_int) -> *mut _TrieNode {
    var __local_node: *mut _TrieNode

    var __local_j: c_int

    var __local_c: c_int

    (__local_node = (*__param_trie).root_node)

    (__local_j = ((0 as c_int)))

    while ((if __local_j < __param_key_length: 1 else: 0) != 0) {
        if ((if __local_node == null: 1 else: 0) != 0) {
            return ((null as *mut _TrieNode))

        }

        (__local_c = (((__param_key[__local_j]) as c_int)))

        (__local_node = (*__local_node).next[__local_c])


        (__local_j = __local_j + 1)

    }


    return __local_node

}

unsafe fn trie_insert_rollback(__param_trie: *mut _Trie, __param_key: *mut u8) -> Unit {
    var __local_node: *mut _TrieNode

    var __local_prev_ptr: *mut *mut _TrieNode

    var __local_next_node: *mut _TrieNode

    var __local_next_prev_ptr: *mut *mut _TrieNode

    var __local_p: *mut u8

    (__local_node = (*__param_trie).root_node)

    (__local_prev_ptr = (((&raw const (*__param_trie).root_node as *const *mut _TrieNode) as *mut *mut _TrieNode)))

    (__local_p = __param_key)

    while ((if __local_node != null: 1 else: 0) != 0) {
        (__local_next_prev_ptr = (((&raw const (*__local_node).next[(*__local_p)] as *const *mut _TrieNode) as *mut *mut _TrieNode)))

        (__local_next_node = (*__local_next_prev_ptr))

        (__local_p = __local_p + 1)

        ((*__local_node).use_count = ((*__local_node).use_count -% 1))

        if ((if (*__local_node).use_count == 0: 1 else: 0) != 0) {
            alloc_test_free((__local_node as *mut c_void))

            if ((if __local_prev_ptr != null: 1 else: 0) != 0) {
                ((*__local_prev_ptr) = ((null as *mut _TrieNode)))

            }

            (__local_next_prev_ptr = ((null as *mut *mut _TrieNode)))

        }

        (__local_node = __local_next_node)

        (__local_prev_ptr = __local_next_prev_ptr)

    }

}

unsafe fn trie_value_is_null(__param_v: *mut *mut c_void) -> c_int {
    return (if not (with_memcmp(((__param_v as *const c_void) as *const u8), (((&raw const trie_null_value as *const *mut c_void) as *const c_void) as *const u8), ((sizeof[usize]() as c_ulong) as i64)) != 0): 1 else: 0)

}

let trie_null_value: *mut c_void = null
