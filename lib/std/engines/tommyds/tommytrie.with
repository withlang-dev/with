// Migrated from C
use std.engines.tommyds.defs
use std.engines.tommyds.tommyalloc
use std.engines.tommyds.tommylist
use std.libc
use std.collections

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

// contract: receiver-mut:tommy_trie_struct,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn tommy_trie_init(__param_trie: *mut tommy_trie_struct, __param_alloc: *mut tommy_allocator_struct) {
    var __local_i: u32

    (__local_i = ((0 as u32)))

    while (__local_i < 32) {
        ((*__param_trie).bucket[__local_i] = null)

        (__local_i = (__local_i +% 1))

    }


    ((*__param_trie).count = ((0 as u64)))

    ((*__param_trie).node_count = ((0 as u64)))

    ((*__param_trie).alloc = __param_alloc)

}

// contract: receiver-mut:tommy_trie_struct,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn tommy_trie_insert(__param_trie: *mut tommy_trie_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void, __param_key: u64) {
    var __local_let_ptr: *mut *mut tommy_node_struct

    if ((if not (((__param_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32)) < 32): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_trie_insert".ptr, c"tommytrie.c".ptr, (158 as i32), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
    } else {
        0
    }

    ((*__param_node).data = __param_data)

    ((*__param_node).index = __param_key)

    (__local_let_ptr = (((&raw const (*__param_trie).bucket[((__param_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))

    trie_bucket_insert(__param_trie, (27 as u32), __local_let_ptr, __param_node, __param_key)

    ((*__param_trie).count = ((*__param_trie).count +% 1))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn tommy_trie_bucket(__param_trie: *mut tommy_trie_struct, __param_key: u64) -> *mut tommy_node_struct {
    var __local_node__goto_298_19: *mut tommy_node_struct = null

    var __local_ptr__goto_299_8: *mut c_void = null

    var __local_type___goto_300_15: u32 = 0

    var __local_shift__goto_301_15: u32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        if ((if not (((__param_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32)) < 32): 1 else: 0) as i64) {
            __assert_rtn(c"tommy_trie_bucket".ptr, c"tommytrie.c".ptr, (304 as i32), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
        } else {
            0
        }
        (__local_ptr__goto_299_8 = (((*__param_trie).bucket[((__param_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32))] as *mut c_void)))
        (__local_shift__goto_301_15 = ((27 as u32)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        if (not (__local_ptr__goto_299_8 != null)) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_3 {
        (__local_type___goto_300_15 = ((((__local_ptr__goto_299_8 as u64) & (1 as u64)) as u32)))
        goto '__ci_bb_4
    }

    '__ci_bb_4 {
        if (__local_type___goto_300_15 == 0) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_10
        }
    }

    '__ci_bb_6 {
        (__local_node__goto_298_19 = ((__local_ptr__goto_299_8 as *mut tommy_node_struct)))
        if ((*__local_node__goto_298_19).index != __param_key) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_7 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_8 {
        return __local_node__goto_298_19
    }

    '__ci_bb_9 {
        (__local_ptr__goto_299_8 = (((*(((__local_ptr__goto_299_8 as u64) -% (1 as u64)) as *mut tommy_trie_tree_struct)).map[((((__param_key as u64) >> (__local_shift__goto_301_15 as u32)) as u64) & (7 as u64))] as *mut c_void)))
        (__local_shift__goto_301_15 = (__local_shift__goto_301_15 -% 3))
        goto '__ci_bb_1
    }

    '__ci_bb_10 {
        if (__local_type___goto_300_15 == 1) {
            goto '__ci_bb_9
        } else {
            goto '__ci_bb_9
        }
    }

    __ci_unreachable()

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn tommy_trie_search(__param_trie: *mut tommy_trie_struct, __param_key: u64) -> *mut c_void {
    var __local_i: *mut tommy_node_struct = tommy_trie_bucket(__param_trie, __param_key)

    if (not (__local_i != null)) {
        return ((0 as *mut c_void))
    }

    return (*__local_i).data

}

// contract: receiver-mut:tommy_trie_struct,unproved:1:out-parameter read before the write
pub unsafe fn tommy_trie_remove_existing(__param_trie: *mut tommy_trie_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_ret: *mut tommy_node_struct

    var __local_key: u64 = (*__param_node).index

    var __local_let_ptr: *mut *mut tommy_node_struct

    if ((if not (((__local_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32)) < 32): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_trie_remove_existing".ptr, c"tommytrie.c".ptr, (282 as i32), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
    } else {
        0
    }

    (__local_let_ptr = (((&raw const (*__param_trie).bucket[((__local_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))

    (__local_ret = trie_bucket_remove_existing(__param_trie, (27 as u32), __local_let_ptr, __param_node, __local_key))

    if ((if not (__local_ret == __param_node): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_trie_remove_existing".ptr, c"tommytrie.c".ptr, (289 as i32), c"ret == node".ptr)
    } else {
        0
    }

    ((*__param_trie).count = ((*__param_trie).count -% 1))

    return (*__local_ret).data

}

// contract: receiver-mut:tommy_trie_struct,unproved:2:out-parameter read before the write,stored-unknown:3 — stores an argument; ownership not modeled
unsafe fn trie_bucket_insert(__param_trie: *mut tommy_trie_struct, __param_shift: u32, __param_let_ptr: *mut *mut tommy_node_struct, __param_insert: *mut tommy_node_struct, __param_key: u64) -> Unit {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_tree__goto_92_19: *mut tommy_trie_tree_struct = null

    var __local_node__goto_93_19: *mut tommy_node_struct = null

    var __local_ptr__goto_94_8: *mut c_void = null

    var __local_i__goto_95_15: u32 = 0

    var __local_j__goto_96_15: u32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local_ptr__goto_94_8 = (((*__local_let_ptr) as *mut c_void)))
        if (not (__local_ptr__goto_94_8 != null)) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        tommy_list_insert_first(__local_let_ptr, __param_insert)
        return
    }

    '__ci_bb_3 {
        if (((__local_ptr__goto_94_8 as u64) & (1 as u64)) == 1) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__local_let_ptr = (((&raw const (*(((__local_ptr__goto_94_8 as u64) -% (1 as u64)) as *mut tommy_trie_tree_struct)).map[((((__param_key as u64) >> (__local_shift as u32)) as u64) & (7 as u64))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))
        (__local_shift = (__local_shift -% 3))
        goto '__ci_bb_1
    }

    '__ci_bb_5 {
        (__local_node__goto_93_19 = ((__local_ptr__goto_94_8 as *mut tommy_node_struct)))
        if ((*__local_node__goto_93_19).index == __param_key) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_6 {
        tommy_list_insert_tail_not_empty(__local_node__goto_93_19, __param_insert)
        return
    }

    '__ci_bb_7 {
        goto '__ci_bb_8
    }

    '__ci_bb_8 {
        (__local_tree__goto_92_19 = (((*((*__param_trie).alloc)).tommy_allocator_alloc() as *mut tommy_trie_tree_struct)))
        ((*__param_trie).node_count = ((*__param_trie).node_count +% 1))
        ((*__local_let_ptr) = (((((__local_tree__goto_92_19 as u64) +% (1 as u64)) as *mut c_void) as *mut tommy_node_struct)))
        (__local_i__goto_95_15 = ((0 as u32)))
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        if (__local_i__goto_95_15 < ((64 as u64) / (8 as u64))) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_12
        }
    }

    '__ci_bb_10 {
        ((*__local_tree__goto_92_19).map[__local_i__goto_95_15] = null)
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        (__local_i__goto_95_15 = (__local_i__goto_95_15 +% 1))
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        (__local_i__goto_95_15 = (((((((*__local_node__goto_93_19).index as u64) >> (__local_shift as u32)) as u64) & (7 as u64)) as u32)))
        (__local_j__goto_96_15 = ((((((__param_key as u64) >> (__local_shift as u32)) as u64) & (7 as u64)) as u32)))
        if (__local_i__goto_95_15 != __local_j__goto_96_15) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_14
        }
    }

    '__ci_bb_13 {
        ((*__local_tree__goto_92_19).map[__local_i__goto_95_15] = __local_node__goto_93_19)
        tommy_list_insert_first(((&raw const (*__local_tree__goto_92_19).map[__local_j__goto_96_15] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct), __param_insert)
        return
    }

    '__ci_bb_14 {
        (__local_let_ptr = (((&raw const (*__local_tree__goto_92_19).map[__local_i__goto_95_15] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))
        (__local_shift = (__local_shift -% 3))
        goto '__ci_bb_8
    }

    __ci_unreachable()

}

// contract: receiver-mut:tommy_trie_struct,stored-unknown:2,unproved:3:returns a pointer loaded from the parameter — stores an argument; ownership not modeled
unsafe fn trie_bucket_remove_existing(__param_trie: *mut tommy_trie_struct, __param_shift: u32, __param_let_ptr: *mut *mut tommy_node_struct, __param_remove: *mut tommy_node_struct, __param_key: u64) -> *mut tommy_node_struct {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_remove = __param_remove
    var __local_node__goto_172_19: *mut tommy_node_struct = null

    var __local_tree__goto_173_19: *mut tommy_trie_tree_struct = null

    var __local_ptr__goto_174_8: *mut c_void = null

    var __local_let_back__goto_175_20: List[*mut *mut tommy_node_struct] = [null; 10]

    var __local_level__goto_176_15: u32 = 0

    var __local_i__goto_177_15: u32 = 0

    var __local_count__goto_178_15: u32 = 0

    var __local_last__goto_179_15: u32 = 0

    var __ci_expr_old_0: u32 = 0

    var __ci_expr_logic_1: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        (__local_level__goto_176_15 = ((0 as u32)))
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        (__local_ptr__goto_174_8 = (((*__local_let_ptr) as *mut c_void)))
        if (not (__local_ptr__goto_174_8 != null)) {
            goto '__ci_bb_2
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_2 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_3 {
        if (((__local_ptr__goto_174_8 as u64) & (1 as u64)) == 1) {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_5
        }
    }

    '__ci_bb_4 {
        (__local_tree__goto_173_19 = ((((__local_ptr__goto_174_8 as u64) -% (1 as u64)) as *mut tommy_trie_tree_struct)))
        (__ci_expr_old_0 = __local_level__goto_176_15)
        (__local_level__goto_176_15 = (__local_level__goto_176_15 +% 1))
        (__local_let_back__goto_175_20[__ci_expr_old_0] = __local_let_ptr)
        (__local_let_ptr = (((&raw const (*__local_tree__goto_173_19).map[((((__param_key as u64) >> (__local_shift as u32)) as u64) & (7 as u64))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))
        (__local_shift = (__local_shift -% 3))
        goto '__ci_bb_1
    }

    '__ci_bb_5 {
        (__local_node__goto_172_19 = ((__local_ptr__goto_174_8 as *mut tommy_node_struct)))
        if (not (__local_remove != null)) {
            goto '__ci_bb_6
        } else {
            goto '__ci_bb_7
        }
    }

    '__ci_bb_6 {
        (__local_remove = __local_node__goto_172_19)
        if ((*__local_remove).index != __param_key) {
            goto '__ci_bb_8
        } else {
            goto '__ci_bb_9
        }
    }

    '__ci_bb_7 {
        tommy_list_remove_existing(__local_let_ptr, __local_remove)
        if ((*__local_let_ptr) != null) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if not __local_level__goto_176_15: 1 else: 0))
        }
        if __ci_expr_logic_1 {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        return ((0 as *mut tommy_node_struct))
    }

    '__ci_bb_9 {
        goto '__ci_bb_7
    }

    '__ci_bb_10 {
        return __local_remove
    }

    '__ci_bb_11 {
        goto '__ci_bb_12
    }

    '__ci_bb_12 {
        (__local_level__goto_176_15 = (__local_level__goto_176_15 -% 1))
        (__local_let_ptr = __local_let_back__goto_175_20[__local_level__goto_176_15])
        (__local_tree__goto_173_19 = (((((*__local_let_ptr) as u64) -% (1 as u64)) as *mut tommy_trie_tree_struct)))
        (__local_count__goto_178_15 = ((0 as u32)))
        (__local_last__goto_179_15 = ((0 as u32)))
        (__local_i__goto_177_15 = ((0 as u32)))
        goto '__ci_bb_13
    }

    '__ci_bb_13 {
        if (__local_i__goto_177_15 < ((64 as u64) / (8 as u64))) {
            goto '__ci_bb_14
        } else {
            goto '__ci_bb_16
        }
    }

    '__ci_bb_14 {
        if ((*__local_tree__goto_173_19).map[__local_i__goto_177_15] != null) {
            goto '__ci_bb_17
        } else {
            goto '__ci_bb_18
        }
    }

    '__ci_bb_15 {
        (__local_i__goto_177_15 = (__local_i__goto_177_15 +% 1))
        goto '__ci_bb_13
    }

    '__ci_bb_16 {
        if ((if not (__local_count__goto_178_15 == 1): 1 else: 0) as i64) {
            __assert_rtn(c"trie_bucket_remove_existing".ptr, c"tommytrie.c".ptr, (241 as i32), c"count == 1".ptr)
        } else {
            0
        }
        ((*__local_let_ptr) = (*__local_tree__goto_173_19).map[__local_last__goto_179_15])
        tommy_allocator_free((*__param_trie).alloc, (__local_tree__goto_173_19 as *mut c_void))
        ((*__param_trie).node_count = ((*__param_trie).node_count -% 1))
        if __local_level__goto_176_15 {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_24
        }
    }

    '__ci_bb_17 {
        if ((((*__local_tree__goto_173_19).map[__local_i__goto_177_15] as u64) & (1 as u64)) != 0) {
            goto '__ci_bb_19
        } else {
            goto '__ci_bb_20
        }
    }

    '__ci_bb_18 {
        goto '__ci_bb_15
    }

    '__ci_bb_19 {
        return __local_remove
    }

    '__ci_bb_20 {
        (__local_count__goto_178_15 = (__local_count__goto_178_15 +% 1))
        if (__local_count__goto_178_15 > 1) {
            goto '__ci_bb_21
        } else {
            goto '__ci_bb_22
        }
    }

    '__ci_bb_21 {
        return __local_remove
    }

    '__ci_bb_22 {
        (__local_last__goto_179_15 = __local_i__goto_177_15)
        goto '__ci_bb_18
    }

    '__ci_bb_23 {
        goto '__ci_bb_12
    }

    '__ci_bb_24 {
        return __local_remove
    }

    __ci_unreachable()

}

impl tommy_trie_struct {
    pub mut fn tommy_trie_remove(__param_key: u64) -> *mut c_void {
        let __param_trie: *mut tommy_trie_struct = self as *mut tommy_trie_struct
        var __local_ret: *mut tommy_node_struct

        var __local_let_ptr: *mut *mut tommy_node_struct

        if ((if not (((__param_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32)) < 32): 1 else: 0) as i64) {
            __assert_rtn(c"tommy_trie_remove".ptr, c"tommytrie.c".ptr, (261 as i32), c"key >> TOMMY_TRIE_BUCKET_SHIFT < TOMMY_TRIE_BUCKET_MAX".ptr)
        } else {
            0
        }

        (__local_let_ptr = (((&raw const (unsafe *__param_trie).bucket[((__param_key as u64) >> ((32 - ((32 % (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32))) + (if ((64 as u64) / (sizeof[usize]() as u64)) == 256: (8 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 128: (7 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 64: (6 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 32: (5 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 16: (4 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 8: (3 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 4: (2 as i32) else: ((if ((64 as u64) / (sizeof[usize]() as u64)) == 2: (1 as i32) else: (0 as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)) as i32)))) as u32))] as *const *mut tommy_node_struct) as *mut *mut tommy_node_struct)))

        (__local_ret = unsafe { trie_bucket_remove_existing(__param_trie, (27 as u32), __local_let_ptr, null, __param_key) })

        if (not (__local_ret != null)) {
            return ((0 as *mut c_void))
        }

        ((unsafe *__param_trie).count = ((unsafe *__param_trie).count -% 1))

        return (unsafe *__local_ret).data

    }

    pub fn tommy_trie_count() -> u64 {
        let __param_trie: *mut tommy_trie_struct = (self as *const tommy_trie_struct) as *mut tommy_trie_struct
        return (unsafe *__param_trie).count

    }

    pub fn tommy_trie_memory_usage() -> u64 {
        let __param_trie: *mut tommy_trie_struct = (self as *const tommy_trie_struct) as *mut tommy_trie_struct
        return ((((unsafe { (*__param_trie).tommy_trie_count() } as u64) *% (sizeof[tommy_node_struct]() as u64)) as u64) +% ((((unsafe *__param_trie).node_count as u64) *% (((((64 as u64) / (8 as u64)) as u64) *% (8 as u64)) as u64)) as u64))

    }

}
