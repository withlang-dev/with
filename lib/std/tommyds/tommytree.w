// Migrated from C
use std.tommyds.defs
use std.libc

fn tommy_ilog2_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).clz() as c_int) ^ (31 as c_int))

}

fn tommy_ilog2_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).clz() as c_int) ^ (63 as c_int))

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
    return (if ((((((__param_value as c_uint) -% (16843009 as c_uint)) as c_uint) & ((~__param_value) as c_uint)) as c_uint) & ((2155905152 as c_uint) as c_uint)) != 0: 1 else: 0)

}

pub unsafe fn tommy_tree_init(__param_tree: *mut tommy_tree_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int) -> Unit {
    ((unsafe *__param_tree).root = null)

    ((unsafe *__param_tree).count = ((0 as c_ulonglong)))

    ((unsafe *__param_tree).cmp = __param_cmp)

}

pub unsafe fn tommy_tree_insert(__param_tree: *mut tommy_tree_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void) -> *mut c_void {
    var __local_insert: *mut tommy_node_struct = __param_node

    ((unsafe *__local_insert).data = __param_data)

    ((unsafe *__local_insert).prev = null)

    ((unsafe *__local_insert).next = null)

    ((unsafe *__local_insert).index = ((0 as c_ulonglong)))

    ((unsafe *__param_tree).root = tommy_tree_insert_node((unsafe *__param_tree).cmp, (unsafe *__param_tree).root, (&raw mut __local_insert as *mut *mut tommy_node_struct)))

    if ((if __local_insert == __param_node: 1 else: 0) != 0) {
        ((unsafe *__param_tree).count = ((unsafe *__param_tree).count +% 1))
    }

    return (unsafe *__local_insert).data

}

pub unsafe fn tommy_tree_remove(__param_tree: *mut tommy_tree_struct, __param_data: *mut c_void) -> *mut c_void {
    var __local_node: *mut tommy_node_struct = null

    ((unsafe *__param_tree).root = tommy_tree_remove_node((unsafe *__param_tree).cmp, (unsafe *__param_tree).root, __param_data, (&raw mut __local_node as *mut *mut tommy_node_struct)))

    if ((if not (__local_node != null): 1 else: 0) != 0) {
        return ((0 as *mut c_void))
    }

    ((unsafe *__param_tree).count = ((unsafe *__param_tree).count -% 1))

    return (unsafe *__local_node).data

}

pub unsafe fn tommy_tree_search(__param_tree: *mut tommy_tree_struct, __param_data: *mut c_void) -> *mut c_void {
    var __local_node: *mut tommy_node_struct = tommy_tree_search_node((unsafe *__param_tree).cmp, (unsafe *__param_tree).root, __param_data)

    if ((if not (__local_node != null): 1 else: 0) != 0) {
        return ((0 as *mut c_void))
    }

    return (unsafe *__local_node).data

}

pub unsafe fn tommy_tree_search_compare(__param_tree: *mut tommy_tree_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_cmp_arg: *mut c_void) -> *mut c_void {
    var __local_node: *mut tommy_node_struct = tommy_tree_search_node(__param_cmp, (unsafe *__param_tree).root, __param_cmp_arg)

    if ((if not (__local_node != null): 1 else: 0) != 0) {
        return ((0 as *mut c_void))
    }

    return (unsafe *__local_node).data

}

pub unsafe fn tommy_tree_remove_existing(__param_tree: *mut tommy_tree_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_data: *mut c_void = tommy_tree_remove(__param_tree, (unsafe *__param_node).data)

    if ((((if not ((if __local_data != 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"tommy_tree_remove_existing".ptr, c"tommytree.c".ptr, (239 as c_int), c"data != 0".ptr)
    } else {
        0
    }

    return __local_data

}

pub unsafe fn tommy_tree_foreach(__param_tree: *mut tommy_tree_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    tommy_tree_foreach_node((unsafe *__param_tree).root, __param_func)

}

pub unsafe fn tommy_tree_foreach_arg(__param_tree: *mut tommy_tree_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) -> Unit {
    tommy_tree_foreach_arg_node((unsafe *__param_tree).root, __param_func, __param_arg)

}

pub unsafe fn tommy_tree_count(__param_tree: *mut tommy_tree_struct) -> c_ulonglong {
    return (unsafe *__param_tree).count

}

pub unsafe fn tommy_tree_memory_usage(__param_tree: *mut tommy_tree_struct) -> c_ulonglong {
    return ((tommy_tree_count(__param_tree) as c_ulonglong) *% (32 as c_ulonglong))

}

unsafe fn tommy_tree_delta(__param_root: *mut tommy_node_struct) -> c_longlong {
    var __local_left_height: c_longlong = with 0 as __ci_expr_seq_9 {
        var __ci_expr_ternary_0: c_ulonglong = 0
        if ((unsafe *__param_root).prev != null) {
            (__ci_expr_ternary_0 = (unsafe *(unsafe *__param_root).prev).index)
        } else {
            (__ci_expr_ternary_0 = ((0 as c_ulonglong)))
        }
        (__ci_expr_ternary_0 as c_longlong)
    }

    var __local_right_height: c_longlong = with 0 as __ci_expr_seq_18 {
        var __ci_expr_ternary_1: c_ulonglong = 0
        if ((unsafe *__param_root).next != null) {
            (__ci_expr_ternary_1 = (unsafe *(unsafe *__param_root).next).index)
        } else {
            (__ci_expr_ternary_1 = ((0 as c_ulonglong)))
        }
        (__ci_expr_ternary_1 as c_longlong)
    }

    return (__local_left_height - __local_right_height)

}

unsafe fn tommy_tree_balance(__param_root: *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_delta: c_longlong = ((tommy_tree_delta(__param_root) as c_longlong))

    if ((if __local_delta < -1: 1 else: 0) != 0) {
        if ((if tommy_tree_delta((unsafe *__param_root).next) > 0: 1 else: 0) != 0) {
            ((unsafe *__param_root).next = tommy_tree_rotate_right((unsafe *__param_root).next))
        }

        return ((tommy_tree_rotate_left(__param_root) as *mut tommy_node_struct))

    }

    if ((if __local_delta > 1: 1 else: 0) != 0) {
        if ((if tommy_tree_delta((unsafe *__param_root).prev) < 0: 1 else: 0) != 0) {
            ((unsafe *__param_root).prev = tommy_tree_rotate_left((unsafe *__param_root).prev))
        }

        return ((tommy_tree_rotate_right(__param_root) as *mut tommy_node_struct))

    }

    ((unsafe *__param_root).index = ((0 as c_ulonglong)))

    var __ci_expr_logic_0: c_int = 0

    if ((unsafe *__param_root).prev != null) {
        (__ci_expr_logic_0 = (if (if (unsafe *(unsafe *__param_root).prev).index > (unsafe *__param_root).index: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        ((unsafe *__param_root).index = (unsafe *(unsafe *__param_root).prev).index)
    }


    var __ci_expr_logic_1: c_int = 0

    if ((unsafe *__param_root).next != null) {
        (__ci_expr_logic_1 = (if (if (unsafe *(unsafe *__param_root).next).index > (unsafe *__param_root).index: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        ((unsafe *__param_root).index = (unsafe *(unsafe *__param_root).next).index)
    }


    ((unsafe *__param_root).index = ((unsafe *__param_root).index +% 1))

    return __param_root

}

unsafe fn tommy_tree_rotate_left(__param_root: *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_next: *mut tommy_node_struct = (unsafe *__param_root).next

    ((unsafe *__param_root).next = (unsafe *__local_next).prev)

    ((unsafe *__local_next).prev = tommy_tree_balance(__param_root))

    return ((tommy_tree_balance(__local_next) as *mut tommy_node_struct))

}

unsafe fn tommy_tree_rotate_right(__param_root: *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_prev: *mut tommy_node_struct = (unsafe *__param_root).prev

    ((unsafe *__param_root).prev = (unsafe *__local_prev).next)

    ((unsafe *__local_prev).next = tommy_tree_balance(__param_root))

    return ((tommy_tree_balance(__local_prev) as *mut tommy_node_struct))

}

unsafe fn tommy_tree_move_right(__param_root: *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> *mut tommy_node_struct {
    if ((if not (__param_root != null): 1 else: 0) != 0) {
        return __param_node
    }

    ((unsafe *__param_root).next = tommy_tree_move_right((unsafe *__param_root).next, __param_node))

    return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

}

unsafe fn tommy_tree_insert_node(__param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_root: *mut tommy_node_struct, __param_let_: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_c: c_int

    if ((if not (__param_root != null): 1 else: 0) != 0) {
        return (unsafe *__param_let_)
    }

    (__local_c = ((__param_cmp(((unsafe *(unsafe *__param_let_)).data as *const c_void), ((unsafe *__param_root).data as *const c_void)) as c_int)))

    if ((if __local_c < 0: 1 else: 0) != 0) {
        ((unsafe *__param_root).prev = tommy_tree_insert_node(__param_cmp, (unsafe *__param_root).prev, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    if ((if __local_c > 0: 1 else: 0) != 0) {
        ((unsafe *__param_root).next = tommy_tree_insert_node(__param_cmp, (unsafe *__param_root).next, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    ((unsafe *__param_let_) = __param_root)

    return __param_root

}

unsafe fn tommy_tree_remove_node(__param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_root: *mut tommy_node_struct, __param_data: *mut c_void, __param_let_: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_c: c_int

    if ((if not (__param_root != null): 1 else: 0) != 0) {
        return ((0 as *mut tommy_node_struct))
    }

    (__local_c = ((__param_cmp((__param_data as *const c_void), ((unsafe *__param_root).data as *const c_void)) as c_int)))

    if ((if __local_c < 0: 1 else: 0) != 0) {
        ((unsafe *__param_root).prev = tommy_tree_remove_node(__param_cmp, (unsafe *__param_root).prev, __param_data, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    if ((if __local_c > 0: 1 else: 0) != 0) {
        ((unsafe *__param_root).next = tommy_tree_remove_node(__param_cmp, (unsafe *__param_root).next, __param_data, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    ((unsafe *__param_let_) = __param_root)

    return ((tommy_tree_move_right((unsafe *__param_root).prev, (unsafe *__param_root).next) as *mut tommy_node_struct))

}

unsafe fn tommy_tree_search_node(__param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> c_int, __param_root: *mut tommy_node_struct, __param_data: *mut c_void) -> *mut tommy_node_struct {
    var __local_c: c_int

    if ((if not (__param_root != null): 1 else: 0) != 0) {
        return ((0 as *mut tommy_node_struct))
    }

    (__local_c = ((__param_cmp((__param_data as *const c_void), ((unsafe *__param_root).data as *const c_void)) as c_int)))

    if ((if __local_c < 0: 1 else: 0) != 0) {
        return ((tommy_tree_search_node(__param_cmp, (unsafe *__param_root).prev, __param_data) as *mut tommy_node_struct))
    }

    if ((if __local_c > 0: 1 else: 0) != 0) {
        return ((tommy_tree_search_node(__param_cmp, (unsafe *__param_root).next, __param_data) as *mut tommy_node_struct))
    }

    return __param_root

}

unsafe fn tommy_tree_foreach_node(__param_root: *mut tommy_node_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) -> Unit {
    var __local_next: *mut tommy_node_struct

    if ((if not (__param_root != null): 1 else: 0) != 0) {
        return
    }

    tommy_tree_foreach_node((unsafe *__param_root).prev, __param_func)

    (__local_next = (unsafe *__param_root).next)

    __param_func((unsafe *__param_root).data)

    tommy_tree_foreach_node(__local_next, __param_func)

}

unsafe fn tommy_tree_foreach_arg_node(__param_root: *mut tommy_node_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) -> Unit {
    var __local_next: *mut tommy_node_struct

    if ((if not (__param_root != null): 1 else: 0) != 0) {
        return
    }

    tommy_tree_foreach_arg_node((unsafe *__param_root).prev, __param_func, __param_arg)

    (__local_next = (unsafe *__param_root).next)

    __param_func(__param_arg, (unsafe *__param_root).data)

    tommy_tree_foreach_arg_node(__local_next, __param_func, __param_arg)

}
