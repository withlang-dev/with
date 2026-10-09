// Migrated from C
use std.tommyds.defs
use std.libc

fn tommy_ilog2_u32(__param_value: c_uint) -> c_uint {
    return (((((__param_value as u32).clz() as c_int) ^ (31 as c_int)) as c_uint))

}

fn tommy_ilog2_u64(__param_value: c_ulonglong) -> c_uint {
    return (((((__param_value as u64).clz() as c_int) ^ (63 as c_int)) as c_uint))

}

fn tommy_ctz_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).ctz() as c_uint))

}

fn tommy_ctz_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).ctz() as c_uint))

}

fn tommy_roundup_pow2_u32(__param_value: c_uint) -> c_uint {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (1 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (2 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (4 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (8 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (16 as c_uint)) as c_uint))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: c_ulonglong) -> c_ulonglong {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (1 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (2 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (4 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (8 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (16 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (32 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: c_uint) -> c_int {
    return (if ((((((__param_value as c_uint) -% (16843009 as c_uint)) as c_uint) & ((~__param_value) as c_uint)) as c_uint) & (2155905152 as c_uint)) != 0: 1 else: 0)

}

pub unsafe fn tommy_trie_inplace_init(__param_trie_inplace: *mut tommy_trie_inplace_struct) {
    var __local_i: c_uint

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 64: 1 else: 0) != 0) {
        ((*__param_trie_inplace).bucket[__local_i] = null)

        (__local_i = (__local_i +% 1))

    }


    ((*__param_trie_inplace).count = ((0 as c_ulonglong)))

}

pub unsafe fn tommy_trie_inplace_insert(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_node: *mut tommy_trie_inplace_node_struct, __param_data: *mut c_void, __param_key: c_ulonglong) {
    var __local_let_ptr: *mut *mut tommy_trie_inplace_node_struct

    var __local_i: c_uint

    if (((if not ((if ((__param_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint)) < 64: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_inplace_insert".ptr, c"tommytrieinp.c".ptr, (133 as c_int), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
    } else {
        0
    }

    ((*__param_node).data = __param_data)

    ((*__param_node).key = __param_key)

    (__local_i = ((0 as c_uint)))

    while ((if __local_i < 4: 1 else: 0) != 0) {
        ((*__param_node).map[__local_i] = null)

        (__local_i = (__local_i +% 1))

    }


    (__local_let_ptr = (((&raw const (*__param_trie_inplace).bucket[((__param_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

    trie_inplace_bucket_insert((26 as c_uint), __local_let_ptr, __param_node, __param_key)

    ((*__param_trie_inplace).count = ((*__param_trie_inplace).count +% 1))

}

pub unsafe fn tommy_trie_inplace_remove(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_key: c_ulonglong) -> *mut c_void {
    var __local_ret: *mut tommy_trie_inplace_node_struct

    var __local_let_ptr: *mut *mut tommy_trie_inplace_node_struct

    if (((if not ((if ((__param_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint)) < 64: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_inplace_remove".ptr, c"tommytrieinp.c".ptr, (224 as c_int), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
    } else {
        0
    }

    (__local_let_ptr = (((&raw const (*__param_trie_inplace).bucket[((__param_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

    (__local_ret = trie_inplace_bucket_remove((26 as c_uint), __local_let_ptr, null, __param_key))

    if ((if not (__local_ret != null): 1 else: 0) != 0) {
        return ((0 as *mut c_void))
    }

    ((*__param_trie_inplace).count = ((*__param_trie_inplace).count -% 1))

    return (*__local_ret).data

}

pub unsafe fn tommy_trie_inplace_bucket(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_key: c_ulonglong) -> *mut tommy_trie_inplace_node_struct {
    var __local_node: *mut tommy_trie_inplace_node_struct

    var __local_shift: c_uint

    if (((if not ((if ((__param_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint)) < 64: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_inplace_bucket".ptr, c"tommytrieinp.c".ptr, (265 as c_int), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
    } else {
        0
    }

    (__local_node = (*__param_trie_inplace).bucket[((__param_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint))])

    (__local_shift = ((26 as c_uint)))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if (__local_node != null) {
            (__ci_expr_logic_0 = (if (if (*__local_node).key != __param_key: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_node = (*__local_node).map[((((__param_key as c_ulonglong) >> (__local_shift as c_uint)) as c_ulonglong) & (3 as c_ulonglong))])

        (__local_shift = (__local_shift -% 2))

    }

    return __local_node

}

pub unsafe fn tommy_trie_inplace_search(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_key: c_ulonglong) -> *mut c_void {
    var __local_i: *mut tommy_trie_inplace_node_struct = tommy_trie_inplace_bucket(__param_trie_inplace, __param_key)

    if ((if not (__local_i != null): 1 else: 0) != 0) {
        return ((0 as *mut c_void))
    }

    return (*__local_i).data

}

pub unsafe fn tommy_trie_inplace_remove_existing(__param_trie_inplace: *mut tommy_trie_inplace_struct, __param_node: *mut tommy_trie_inplace_node_struct) -> *mut c_void {
    var __local_ret: *mut tommy_trie_inplace_node_struct

    var __local_key: c_ulonglong = (*__param_node).key

    var __local_let_ptr: *mut *mut tommy_trie_inplace_node_struct

    if (((if not ((if ((__local_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint)) < 64: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_inplace_remove_existing".ptr, c"tommytrieinp.c".ptr, (245 as c_int), c"key >> TOMMY_TRIE_INPLACE_BUCKET_SHIFT < TOMMY_TRIE_INPLACE_BUCKET_MAX".ptr)
    } else {
        0
    }

    (__local_let_ptr = (((&raw const (*__param_trie_inplace).bucket[((__local_key as c_ulonglong) >> ((32 - ((32 % (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))) + (3 * (if (if 4 == 256: 1 else: 0) != 0: (8 as c_int) else: ((if (if 4 == 128: 1 else: 0) != 0: (7 as c_int) else: ((if (if 4 == 64: 1 else: 0) != 0: (6 as c_int) else: ((if (if 4 == 32: 1 else: 0) != 0: (5 as c_int) else: ((if (if 4 == 16: 1 else: 0) != 0: (4 as c_int) else: ((if (if 4 == 8: 1 else: 0) != 0: (3 as c_int) else: ((if (if 4 == 4: 1 else: 0) != 0: (2 as c_int) else: ((if (if 4 == 2: 1 else: 0) != 0: (1 as c_int) else: (0 as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int)) as c_int))))) as c_uint))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

    (__local_ret = trie_inplace_bucket_remove((26 as c_uint), __local_let_ptr, __param_node, __local_key))

    if (((if not ((if __local_ret == __param_node: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"tommy_trie_inplace_remove_existing".ptr, c"tommytrieinp.c".ptr, (252 as c_int), c"ret == node".ptr)
    } else {
        0
    }

    ((*__param_trie_inplace).count = ((*__param_trie_inplace).count -% 1))

    return (*__local_ret).data

}

pub unsafe fn tommy_trie_inplace_count(__param_trie_inplace: *mut tommy_trie_inplace_struct) -> c_ulonglong {
    return (*__param_trie_inplace).count

}

pub unsafe fn tommy_trie_inplace_memory_usage(__param_trie_inplace: *mut tommy_trie_inplace_struct) -> c_ulonglong {
    return ((tommy_trie_inplace_count(__param_trie_inplace) as c_ulonglong) *% (sizeof[tommy_trie_inplace_node_struct]() as c_ulonglong))

}

unsafe fn tommy_trie_inplace_list_insert_first(__param_node: *mut tommy_trie_inplace_node_struct) -> *mut tommy_trie_inplace_node_struct {
    ((*__param_node).prev = __param_node)

    ((*__param_node).next = null)

    return __param_node

}

unsafe fn tommy_trie_inplace_list_insert_tail_not_empty(__param_head: *mut tommy_trie_inplace_node_struct, __param_node: *mut tommy_trie_inplace_node_struct) {
    ((*__param_node).prev = (*__param_head).prev)

    ((*__param_head).prev = __param_node)

    ((*__param_node).next = null)

    ((*(*__param_node).prev).next = __param_node)

}

unsafe fn tommy_trie_inplace_list_remove(__param_let_ptr: *mut *mut tommy_trie_inplace_node_struct, __param_node: *mut tommy_trie_inplace_node_struct) -> Unit {
    var __local_head: *mut tommy_trie_inplace_node_struct = (*__param_let_ptr)

    if ((*__param_node).next != null) {
        ((*(*__param_node).next).prev = (*__param_node).prev)
    } else {
        ((*__local_head).prev = (*__param_node).prev)
    }

    if ((if __local_head == __param_node: 1 else: 0) != 0) {
        ((*__param_let_ptr) = (*__param_node).next)
    } else {
        ((*(*__param_node).prev).next = (*__param_node).next)
    }

}

unsafe fn trie_inplace_bucket_insert(__param_shift: c_uint, __param_let_ptr: *mut *mut tommy_trie_inplace_node_struct, __param_insert: *mut tommy_trie_inplace_node_struct, __param_key: c_ulonglong) -> Unit {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_node: *mut tommy_trie_inplace_node_struct

    (__local_node = (*__local_let_ptr))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if (__local_node != null) {
            (__ci_expr_logic_0 = (if (if (*__local_node).key != __param_key: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_let_ptr = (((&raw const (*__local_node).map[((((__param_key as c_ulonglong) >> (__local_shift as c_uint)) as c_ulonglong) & (3 as c_ulonglong))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

        (__local_node = (*__local_let_ptr))

        (__local_shift = (__local_shift -% 2))

    }

    if ((if not (__local_node != null): 1 else: 0) != 0) {
        ((*__local_let_ptr) = tommy_trie_inplace_list_insert_first(__param_insert))

    } else {
        tommy_trie_inplace_list_insert_tail_not_empty(__local_node, __param_insert)

    }

}

unsafe fn trie_inplace_bucket_remove(__param_shift: c_uint, __param_let_ptr: *mut *mut tommy_trie_inplace_node_struct, __param_remove: *mut tommy_trie_inplace_node_struct, __param_key: c_ulonglong) -> *mut tommy_trie_inplace_node_struct {
    var __local_shift = __param_shift
    var __local_let_ptr = __param_let_ptr
    var __local_remove = __param_remove
    var __local_node: *mut tommy_trie_inplace_node_struct

    var __local_i: c_int

    var __local_leaf_let_ptr: *mut *mut tommy_trie_inplace_node_struct

    var __local_leaf: *mut tommy_trie_inplace_node_struct

    (__local_node = (*__local_let_ptr))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if (__local_node != null) {
            (__ci_expr_logic_0 = (if (if (*__local_node).key != __param_key: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_let_ptr = (((&raw const (*__local_node).map[((((__param_key as c_ulonglong) >> (__local_shift as c_uint)) as c_ulonglong) & (3 as c_ulonglong))] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

        (__local_node = (*__local_let_ptr))

        (__local_shift = (__local_shift -% 2))

    }

    if ((if not (__local_node != null): 1 else: 0) != 0) {
        return ((0 as *mut tommy_trie_inplace_node_struct))
    }

    if ((if not (__local_remove != null): 1 else: 0) != 0) {
        (__local_remove = __local_node)
    }

    tommy_trie_inplace_list_remove(__local_let_ptr, __local_remove)

    if ((if (*__local_let_ptr) == __local_node: 1 else: 0) != 0) {
        return __local_remove
    }

    if ((if (*__local_let_ptr) != 0: 1 else: 0) != 0) {
        (__local_node = (*__local_let_ptr))

        (__local_i = ((0 as c_int)))

        while ((if __local_i < 4: 1 else: 0) != 0) {
            ((*__local_node).map[__local_i] = (*__local_remove).map[__local_i])

            (__local_i = __local_i + 1)

        }


        return __local_remove

    }

    (__local_leaf_let_ptr = null)

    (__local_leaf = __local_remove)

    (__local_i = (((4 - 1) as c_int)))

    while ((if __local_i >= 0: 1 else: 0) != 0) {
        if ((*__local_leaf).map[__local_i] != null) {
            (__local_leaf_let_ptr = (((&raw const (*__local_leaf).map[__local_i] as *const *mut tommy_trie_inplace_node_struct) as *mut *mut tommy_trie_inplace_node_struct)))

            (__local_leaf = (*__local_leaf_let_ptr))

            (__local_i = (((4 - 1) as c_int)))

            continue

        }

        (__local_i = __local_i - 1)

    }

    if ((if not (__local_leaf_let_ptr != null): 1 else: 0) != 0) {
        return __local_remove
    }

    ((*__local_leaf_let_ptr) = null)

    (__local_i = ((0 as c_int)))

    while ((if __local_i < 4: 1 else: 0) != 0) {
        ((*__local_leaf).map[__local_i] = (*__local_remove).map[__local_i])

        (__local_i = __local_i + 1)

    }


    ((*__local_let_ptr) = __local_leaf)

    return __local_remove

}
