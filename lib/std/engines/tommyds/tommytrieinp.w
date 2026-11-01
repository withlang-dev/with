// Migrated from C
use std.engines.tommyds.defs
use std.libc

fn tommy_ilog2_u32(__param_value: u32) -> u32 {
    return (((((__param_value as u32).clz() as i32) ^ (31 as i32)) as u32))

}

fn tommy_ilog2_u64(__param_value: u64) -> u32 {
    return (((((__param_value as u64).clz() as i32) ^ (63 as i32)) as u32))

}

fn tommy_ctz_u32(__param_value: u32) -> u32 {
    return (((__param_value as u32).ctz() as u32))

}

fn tommy_ctz_u64(__param_value: u64) -> u32 {
    return (((__param_value as u64).ctz() as u32))

}

fn tommy_roundup_pow2_u32(__param_value: u32) -> u32 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (1 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (2 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (4 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (8 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (16 as u32)) as u32))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: u64) -> u64 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (1 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (2 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (4 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (8 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (16 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (32 as u32)) as u64))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: u32) -> i32 {
    return (if ((((((__param_value as u32) -% (16843009 as u32)) as u32) & ((~__param_value) as u32)) as u32) & (2155905152 as u32)) != 0: 1 else: 0)

}

// contract: receiver-mut:tommy_trie_inplace_struct,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn tommy_trie_inplace_insert(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_node: *mut tommy_trie_inplace_node_struct, __param_data: *mut c_void, __param_key: u64) {
    var __local_let_ptr: *mut *mut tommy_trie_inplace_node_struct

    var __local_i: u32

    if ((if not (((__param_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32)) < 64): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_trie_inplace_insert".ptr, c"tommytrieinp.c".ptr, (133 as i32), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
    } else {
        0
    }

    ((*__param_node).data = __param_data)

    ((*__param_node).key = __param_key)

    (__local_i = ((0 as u32)))

    while (__local_i < 4) {
        ((*__param_node).map[__local_i] = null)

        (__local_i = (__local_i +% 1))

    }


    (__local_let_ptr = (((&raw const (*__param_trie_inplace).bucket[((__param_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

    trie_inplace_bucket_insert((26 as u32), __local_let_ptr, __param_node, __param_key)

    ((*__param_trie_inplace).count = ((*__param_trie_inplace).count +% 1))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn tommy_trie_inplace_bucket(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_key: u64) -> *mut tommy_trie_inplace_node_struct {
    var __local_node: *mut tommy_trie_inplace_node_struct

    var __local_shift: u32

    if ((if not (((__param_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32)) < 64): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_trie_inplace_bucket".ptr, c"tommytrieinp.c".ptr, (265 as i32), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
    } else {
        0
    }

    (__local_node = (*__param_trie_inplace).bucket[((__param_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32))])

    (__local_shift = ((26 as u32)))

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_node != null) {
            (__ci_expr_logic_0 = (if (*__local_node).key != __param_key: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        (__local_node = (*__local_node).map[((((__param_key as u64) >> (__local_shift as u32)) as u64) & (3 as u64))])

        (__local_shift = (__local_shift -% 2))

    }

    return __local_node

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn tommy_trie_inplace_search(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_key: u64) -> *mut c_void {
    var __local_i: *mut tommy_trie_inplace_node_struct = tommy_trie_inplace_bucket(__param_trie_inplace, __param_key)

    if (not (__local_i != null)) {
        return ((0 as *mut c_void))
    }

    return (*__local_i).data

}

// contract: receiver-mut:tommy_trie_inplace_struct,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn tommy_trie_inplace_remove_existing(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_node: *mut tommy_trie_inplace_node_struct) -> *mut c_void {
    var __local_ret: *mut tommy_trie_inplace_node_struct

    var __local_key: u64 = (*__param_node).key

    var __local_let_ptr: *mut *mut tommy_trie_inplace_node_struct

    if ((if not (((__local_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32)) < 64): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_trie_inplace_remove_existing".ptr, c"tommytrieinp.c".ptr, (245 as i32), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
    } else {
        0
    }

    (__local_let_ptr = (((&raw const (*__param_trie_inplace).bucket[((__local_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

    (__local_ret = trie_inplace_bucket_remove((26 as u32), __local_let_ptr, __param_node, __local_key))

    if ((if not (__local_ret == __param_node): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_trie_inplace_remove_existing".ptr, c"tommytrieinp.c".ptr, (252 as i32), c"ret == node".ptr)
    } else {
        0
    }

    ((*__param_trie_inplace).count = ((*__param_trie_inplace).count -% 1))

    return (*__local_ret).data

}

unsafe fn tommy_trie_inplace_list_insert_first(__param_node: *mut tommy_trie_inplace_node_struct) -> *mut tommy_trie_inplace_node_struct {
    ((*__param_node).prev = __param_node)

    ((*__param_node).next = null)

    return __param_node

}

// contract: receiver-mut:tommy_trie_inplace_node_struct,stored-unknown:1 — stores an argument; ownership not modeled
unsafe fn tommy_trie_inplace_list_insert_tail_not_empty(__param_head: *mut tommy_trie_inplace_node_struct, __param_node: *mut tommy_trie_inplace_node_struct) {
    ((*__param_node).prev = (*__param_head).prev)

    ((*__param_head).prev = __param_node)

    ((*__param_node).next = null)

    ((*(*__param_node).prev).next = __param_node)

}

// contract: unproved:0:out-parameter read before the write,unproved:1:out-parameter read before the write
unsafe fn tommy_trie_inplace_list_remove(__param_let_ptr: *mut *mut tommy_trie_inplace_node_struct, __param_node: *mut tommy_trie_inplace_node_struct) -> Unit {
    var __local_head: *mut tommy_trie_inplace_node_struct = (*__param_let_ptr)

    if ((*__param_node).next != null) {
        ((*(*__param_node).next).prev = (*__param_node).prev)
    } else {
        ((*__local_head).prev = (*__param_node).prev)
    }

    if (__local_head == __param_node) {
        ((*__param_let_ptr) = (*__param_node).next)
    } else {
        ((*(*__param_node).prev).next = (*__param_node).next)
    }

}

// contract: unproved:1:out-parameter read before the write,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn trie_inplace_bucket_insert(__param_shift: u32, __param_let_ptr: *mut *mut tommy_trie_inplace_node_struct, __param_insert: *mut tommy_trie_inplace_node_struct, __param_key: u64) -> Unit {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_node: *mut tommy_trie_inplace_node_struct

    (__local_node = (*__local_let_ptr))

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_node != null) {
            (__ci_expr_logic_0 = (if (*__local_node).key != __param_key: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        (__local_let_ptr = (((&raw const (*__local_node).map[((((__param_key as u64) >> (__local_shift as u32)) as u64) & (3 as u64))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

        (__local_node = (*__local_let_ptr))

        (__local_shift = (__local_shift -% 2))

    }

    if (not (__local_node != null)) {
        ((*__local_let_ptr) = tommy_trie_inplace_list_insert_first(__param_insert))

    } else {
        tommy_trie_inplace_list_insert_tail_not_empty(__local_node, __param_insert)

    }

}

// contract: unproved:1:out-parameter read before the write,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn trie_inplace_bucket_remove(__param_shift: u32, __param_let_ptr: *mut *mut tommy_trie_inplace_node_struct, __param_remove: *mut tommy_trie_inplace_node_struct, __param_key: u64) -> *mut tommy_trie_inplace_node_struct {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_remove = __param_remove
    var __local_node: *mut tommy_trie_inplace_node_struct

    var __local_i: i32

    var __local_leaf_let_ptr: *mut *mut tommy_trie_inplace_node_struct

    var __local_leaf: *mut tommy_trie_inplace_node_struct

    (__local_node = (*__local_let_ptr))

    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_node != null) {
            (__ci_expr_logic_0 = (if (*__local_node).key != __param_key: 1 else: 0))
        }

        if (not __ci_expr_logic_0) {
            break
        }

        (__local_let_ptr = (((&raw const (*__local_node).map[((((__param_key as u64) >> (__local_shift as u32)) as u64) & (3 as u64))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

        (__local_node = (*__local_let_ptr))

        (__local_shift = (__local_shift -% 2))

    }

    if (not (__local_node != null)) {
        return ((0 as *mut tommy_trie_inplace_node_struct))
    }

    if (not (__local_remove != null)) {
        (__local_remove = __local_node)
    }

    tommy_trie_inplace_list_remove(__local_let_ptr, __local_remove)

    if ((*__local_let_ptr) == __local_node) {
        return __local_remove
    }

    if ((*__local_let_ptr) != 0) {
        (__local_node = (*__local_let_ptr))

        (__local_i = ((0 as i32)))

        while (__local_i < 4) {
            ((*__local_node).map[__local_i] = (*__local_remove).map[__local_i])

            (__local_i = __local_i + 1)

        }


        return __local_remove

    }

    (__local_leaf_let_ptr = null)

    (__local_leaf = __local_remove)

    (__local_i = (((4 - 1) as i32)))

    while (__local_i >= 0) {
        if ((*__local_leaf).map[__local_i] != null) {
            (__local_leaf_let_ptr = (((&raw const (*__local_leaf).map[__local_i] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

            (__local_leaf = (*__local_leaf_let_ptr))

            (__local_i = (((4 - 1) as i32)))

            continue

        }

        (__local_i = __local_i - 1)

    }

    if (not (__local_leaf_let_ptr != null)) {
        return __local_remove
    }

    ((*__local_leaf_let_ptr) = null)

    (__local_i = ((0 as i32)))

    while (__local_i < 4) {
        ((*__local_leaf).map[__local_i] = (*__local_remove).map[__local_i])

        (__local_i = __local_i + 1)

    }


    ((*__local_let_ptr) = __local_leaf)

    return __local_remove

}

impl tommy_trie_inplace_struct {
    pub mut fn tommy_trie_inplace_init() {
        let __param_trie_inplace: *mut tommy_trie_inplace_struct = self as *mut tommy_trie_inplace_struct
        var __local_i: u32

        (__local_i = ((0 as u32)))

        while (__local_i < 64) {
            ((unsafe *__param_trie_inplace).bucket[__local_i] = null)

            (__local_i = (__local_i +% 1))

        }


        ((unsafe *__param_trie_inplace).count = ((0 as u64)))

    }

    pub mut fn tommy_trie_inplace_remove(__param_key: u64) -> *mut c_void {
        let __param_trie_inplace: *mut tommy_trie_inplace_struct = self as *mut tommy_trie_inplace_struct
        var __local_ret: *mut tommy_trie_inplace_node_struct

        var __local_let_ptr: *mut *mut tommy_trie_inplace_node_struct

        if ((if not (((__param_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32)) < 64): 1 else: 0) as i64) {
            __assert_rtn(c"tommy_trie_inplace_remove".ptr, c"tommytrieinp.c".ptr, (224 as i32), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
        } else {
            0
        }

        (__local_let_ptr = (((&raw const (unsafe *__param_trie_inplace).bucket[((__param_key as u64) >> ((32 - ((32 % (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (3 * (if 4 == 256: (8 as i32) else: ((if 4 == 128: (7 as i32) else: ((if 4 == 64: (6 as i32) else: ((if 4 == 32: (5 as i32) else: ((if 4 == 16: (4 as i32) else: ((if 4 == 8: (3 as i32) else: ((if 4 == 4: (2 as i32) else: ((if 4 == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))))) as u32))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

        (__local_ret = unsafe { trie_inplace_bucket_remove((26 as u32), __local_let_ptr, null, __param_key) })

        if (not (__local_ret != null)) {
            return ((0 as *mut c_void))
        }

        ((unsafe *__param_trie_inplace).count = ((unsafe *__param_trie_inplace).count -% 1))

        return (unsafe *__local_ret).data

    }

    pub fn tommy_trie_inplace_count() -> u64 {
        let __param_trie_inplace: *mut tommy_trie_inplace_struct = (self as *const tommy_trie_inplace_struct) as *mut tommy_trie_inplace_struct
        return (unsafe *__param_trie_inplace).count

    }

    pub fn tommy_trie_inplace_memory_usage() -> u64 {
        let __param_trie_inplace: *mut tommy_trie_inplace_struct = (self as *const tommy_trie_inplace_struct) as *mut tommy_trie_inplace_struct
        return ((unsafe { (*__param_trie_inplace).tommy_trie_inplace_count() } as u64) *% (sizeof[tommy_trie_inplace_node_struct]() as u64))

    }

}
