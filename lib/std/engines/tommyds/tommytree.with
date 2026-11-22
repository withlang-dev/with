// Migrated from C
use std.engines.tommyds.defs
use std.libc
use std.option

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

// contract: receiver-mut:tommy_tree_struct,stored-unknown:1,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn tommy_tree_insert(__param_tree: *mut tommy_tree_struct, __param_node: *mut tommy_node_struct, __param_data: *mut c_void) -> *mut c_void {
    var __local_insert: *mut tommy_node_struct = __param_node

    ((*__local_insert).data = __param_data)

    ((*__local_insert).prev = null)

    ((*__local_insert).next = null)

    ((*__local_insert).index = ((0 as u64)))

    ((*__param_tree).root = tommy_tree_insert_node((*__param_tree).cmp, (*__param_tree).root, (&raw mut __local_insert as *mut *mut tommy_node_struct)))

    if (__local_insert == __param_node) {
        ((*__param_tree).count = ((*__param_tree).count +% 1))
    }

    return (*__local_insert).data

}

// contract: receiver-mut:tommy_tree_struct,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn tommy_tree_remove(__param_tree: *mut tommy_tree_struct, __param_data: *mut c_void) -> *mut c_void {
    var __local_node: *mut tommy_node_struct = null

    ((*__param_tree).root = tommy_tree_remove_node((*__param_tree).cmp, (*__param_tree).root, __param_data, (&raw mut __local_node as *mut *mut tommy_node_struct)))

    if (not (__local_node != null)) {
        return ((0 as *mut c_void))
    }

    ((*__param_tree).count = ((*__param_tree).count -% 1))

    return (*__local_node).data

}

// contract: unproved:0:tommy_tree_search_node may write through it,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn tommy_tree_search(__param_tree: *mut tommy_tree_struct, __param_data: *mut c_void) -> *mut c_void {
    var __local_node: *mut tommy_node_struct = tommy_tree_search_node((*__param_tree).cmp, (*__param_tree).root, __param_data)

    if (not (__local_node != null)) {
        return ((0 as *mut c_void))
    }

    return (*__local_node).data

}

// contract: unproved:0:tommy_tree_search_node may write through it,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn tommy_tree_search_compare(__param_tree: *mut tommy_tree_struct, __param_cmp: unsafe extern "C" fn(*const c_void, *const c_void) -> i32, __param_cmp_arg: *mut c_void) -> *mut c_void {
    var __local_node: *mut tommy_node_struct = tommy_tree_search_node(Some(__param_cmp), (*__param_tree).root, __param_cmp_arg)

    if (not (__local_node != null)) {
        return ((0 as *mut c_void))
    }

    return (*__local_node).data

}

// contract: receiver-mut:tommy_tree_struct,unproved:1:read only
pub unsafe fn tommy_tree_remove_existing(__param_tree: *mut tommy_tree_struct, __param_node: *mut tommy_node_struct) -> *mut c_void {
    var __local_data: *mut c_void = tommy_tree_remove(__param_tree, (*__param_node).data)

    if ((if not (__local_data != 0): 1 else: 0) as i64) {
        __assert_rtn(c"tommy_tree_remove_existing".ptr, c"tommytree.c".ptr, (239 as i32), c"data != 0".ptr)
    } else {
        0
    }

    return __local_data

}

// contract: unproved:0:tommy_tree_foreach_node may write through it
pub unsafe fn tommy_tree_foreach(__param_tree: *mut tommy_tree_struct, __param_func: unsafe extern "C" fn(*mut c_void) -> Unit) {
    tommy_tree_foreach_node((*__param_tree).root, Some(__param_func))

}

// contract: unproved:0:tommy_tree_foreach_arg_node may write through it,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn tommy_tree_foreach_arg(__param_tree: *mut tommy_tree_struct, __param_func: unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit, __param_arg: *mut c_void) {
    tommy_tree_foreach_arg_node((*__param_tree).root, Some(__param_func), __param_arg)

}

unsafe fn tommy_tree_delta(__param_root: *mut tommy_node_struct) -> i64 {
    var __local_left_height: i64 = (((if (*__param_root).prev != null: (*(*__param_root).prev).index else: (0 as u64)) as i64))

    var __local_right_height: i64 = (((if (*__param_root).next != null: (*(*__param_root).next).index else: (0 as u64)) as i64))

    return (__local_left_height - __local_right_height)

}

unsafe fn tommy_tree_balance(__param_root: *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_delta: i64 = ((tommy_tree_delta(__param_root) as i64))

    if (__local_delta < -1) {
        if (tommy_tree_delta((*__param_root).next) > 0) {
            ((*__param_root).next = tommy_tree_rotate_right((*__param_root).next))
        }

        return ((tommy_tree_rotate_left(__param_root) as *mut tommy_node_struct))

    }

    if (__local_delta > 1) {
        if (tommy_tree_delta((*__param_root).prev) < 0) {
            ((*__param_root).prev = tommy_tree_rotate_left((*__param_root).prev))
        }

        return ((tommy_tree_rotate_right(__param_root) as *mut tommy_node_struct))

    }

    ((*__param_root).index = ((0 as u64)))

    var __ci_expr_logic_0: i32 = 0

    if ((*__param_root).prev != null) {
        (__ci_expr_logic_0 = (if (*(*__param_root).prev).index > (*__param_root).index: 1 else: 0))
    }

    if __ci_expr_logic_0 {
        ((*__param_root).index = (*(*__param_root).prev).index)
    }


    var __ci_expr_logic_1: i32 = 0

    if ((*__param_root).next != null) {
        (__ci_expr_logic_1 = (if (*(*__param_root).next).index > (*__param_root).index: 1 else: 0))
    }

    if __ci_expr_logic_1 {
        ((*__param_root).index = (*(*__param_root).next).index)
    }


    ((*__param_root).index = ((*__param_root).index +% 1))

    return __param_root

}

unsafe fn tommy_tree_rotate_left(__param_root: *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_next: *mut tommy_node_struct = (*__param_root).next

    ((*__param_root).next = (*__local_next).prev)

    ((*__local_next).prev = tommy_tree_balance(__param_root))

    return ((tommy_tree_balance(__local_next) as *mut tommy_node_struct))

}

unsafe fn tommy_tree_rotate_right(__param_root: *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_prev: *mut tommy_node_struct = (*__param_root).prev

    ((*__param_root).prev = (*__local_prev).next)

    ((*__local_prev).next = tommy_tree_balance(__param_root))

    return ((tommy_tree_balance(__local_prev) as *mut tommy_node_struct))

}

// contract: unproved:0:NULL is an accepted argument,unproved:1:read only
unsafe fn tommy_tree_move_right(__param_root: *mut tommy_node_struct, __param_node: *mut tommy_node_struct) -> *mut tommy_node_struct {
    if (not (__param_root != null)) {
        return __param_node
    }

    ((*__param_root).next = tommy_tree_move_right((*__param_root).next, __param_node))

    return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

}

// contract: stored-unknown:1,unproved:2:out-parameter written conditionally — stores an argument; ownership not modeled
unsafe fn tommy_tree_insert_node(__param_cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> i32], __param_root: *mut tommy_node_struct, __param_let_: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_c: i32

    if (not (__param_root != null)) {
        return (*__param_let_)
    }

    (__local_c = ((__param_cmp.unwrap()(((*(*__param_let_)).data as *const c_void), ((*__param_root).data as *const c_void)) as i32)))

    if (__local_c < 0) {
        ((*__param_root).prev = tommy_tree_insert_node(__param_cmp, (*__param_root).prev, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    if (__local_c > 0) {
        ((*__param_root).next = tommy_tree_insert_node(__param_cmp, (*__param_root).next, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    ((*__param_let_) = __param_root)

    return __param_root

}

// contract: stored-unknown:1,stored-unknown:2,unproved:3:out-parameter a return before the write — stores an argument; ownership not modeled
unsafe fn tommy_tree_remove_node(__param_cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> i32], __param_root: *mut tommy_node_struct, __param_data: *mut c_void, __param_let_: *mut *mut tommy_node_struct) -> *mut tommy_node_struct {
    var __local_c: i32

    if (not (__param_root != null)) {
        return ((0 as *mut tommy_node_struct))
    }

    (__local_c = ((__param_cmp.unwrap()((__param_data as *const c_void), ((*__param_root).data as *const c_void)) as i32)))

    if (__local_c < 0) {
        ((*__param_root).prev = tommy_tree_remove_node(__param_cmp, (*__param_root).prev, __param_data, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    if (__local_c > 0) {
        ((*__param_root).next = tommy_tree_remove_node(__param_cmp, (*__param_root).next, __param_data, __param_let_))

        return ((tommy_tree_balance(__param_root) as *mut tommy_node_struct))

    }

    ((*__param_let_) = __param_root)

    return ((tommy_tree_move_right((*__param_root).prev, (*__param_root).next) as *mut tommy_node_struct))

}

// contract: unproved:1:read only,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn tommy_tree_search_node(__param_cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> i32], __param_root: *mut tommy_node_struct, __param_data: *mut c_void) -> *mut tommy_node_struct {
    var __local_c: i32

    if (not (__param_root != null)) {
        return ((0 as *mut tommy_node_struct))
    }

    (__local_c = ((__param_cmp.unwrap()((__param_data as *const c_void), ((*__param_root).data as *const c_void)) as i32)))

    if (__local_c < 0) {
        return ((tommy_tree_search_node(__param_cmp, (*__param_root).prev, __param_data) as *mut tommy_node_struct))
    }

    if (__local_c > 0) {
        return ((tommy_tree_search_node(__param_cmp, (*__param_root).next, __param_data) as *mut tommy_node_struct))
    }

    return __param_root

}

// contract: unproved:0:tommy_tree_foreach_node may write through it
unsafe fn tommy_tree_foreach_node(__param_root: *mut tommy_node_struct, __param_func: Option[unsafe extern "C" fn(*mut c_void) -> Unit]) -> Unit {
    var __local_next: *mut tommy_node_struct

    if (not (__param_root != null)) {
        return
    }

    tommy_tree_foreach_node((*__param_root).prev, __param_func)

    (__local_next = (*__param_root).next)

    __param_func.unwrap()((*__param_root).data)

    tommy_tree_foreach_node(__local_next, __param_func)

}

// contract: unproved:0:tommy_tree_foreach_arg_node may write through it,stored-unknown:2 — stores an argument; ownership not modeled
unsafe fn tommy_tree_foreach_arg_node(__param_root: *mut tommy_node_struct, __param_func: Option[unsafe extern "C" fn(*mut c_void, *mut c_void) -> Unit], __param_arg: *mut c_void) -> Unit {
    var __local_next: *mut tommy_node_struct

    if (not (__param_root != null)) {
        return
    }

    tommy_tree_foreach_arg_node((*__param_root).prev, __param_func, __param_arg)

    (__local_next = (*__param_root).next)

    __param_func.unwrap()(__param_arg, (*__param_root).data)

    tommy_tree_foreach_arg_node(__local_next, __param_func, __param_arg)

}

impl tommy_tree_struct {
    pub mut fn tommy_tree_init(__param_cmp: Option[unsafe extern "C" fn(*const c_void, *const c_void) -> i32]) {
        let __param_tree: *mut tommy_tree_struct = self as *mut tommy_tree_struct
        ((unsafe *__param_tree).root = null)

        ((unsafe *__param_tree).count = ((0 as u64)))

        ((unsafe *__param_tree).cmp = __param_cmp)

    }

    pub fn tommy_tree_count() -> u64 {
        let __param_tree: *mut tommy_tree_struct = (self as *const tommy_tree_struct) as *mut tommy_tree_struct
        return (unsafe *__param_tree).count

    }

    pub fn tommy_tree_memory_usage() -> u64 {
        let __param_tree: *mut tommy_tree_struct = (self as *const tommy_tree_struct) as *mut tommy_tree_struct
        return ((unsafe { (*__param_tree).tommy_tree_count() } as u64) *% (32 as u64))

    }

}
