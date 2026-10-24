// Migrated from C
use std.engines.stc_testing.defs
use std.engines.stc_testing.harness
use std.engines.stc_testing.cspan
use std.libc
use std.option
use std.collections

unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: i64) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as u64) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

unsafe fn c_basehash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_len = __param_len
    var __local_msg: *const u8 = ((__param_key as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    var __local_block: u64 = ((0 as u64))


    while ((if __local_len >= ((sizeof[u64]() as i64)): 1 else: 0) != 0) {
        with_memcpy((((&raw mut __local_block as *mut u64) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[u64]() as u64) as i64))

        (__local_h = (__local_h as u64) ^ (__local_block as u64))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[u64]() as i64) as usize))

        (__local_len = __local_len - (sizeof[u64]() as i64))

    }

    while true {
        var __ci_expr_old_0: i64 = __local_len

        (__local_len = __local_len - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_1) as u64))

        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_n(__param_key: *const c_void, __param_len: i64) -> u64 {
    var __local_b8: u64

    var __local_b4: u32

    match __param_len {
        8 => {
            with_memcpy((((&raw mut __local_b8 as *mut u64) as *mut c_void) as *mut u8), (__param_key as *const u8), ((8 as u64) as i64))

            return ((__local_b8 as u64) *% (((0 as u64) -% 4132994306676758115) as u64))

        },
        4 => {
            with_memcpy((((&raw mut __local_b4 as *mut u32) as *mut c_void) as *mut u8), (__param_key as *const u8), ((4 as u64) as i64))

            return ((__local_b4 as u64) *% (((0 as u64) -% 3750763034362895579) as u64))

        },
        _ => {
            return c_basehash_n(__param_key, __param_len)
        },
    }

}

unsafe fn c_hash_str(__param_str: *const c_char) -> u64 {
    var __local_msg: *const u8 = ((__param_str as *const u8))

    var __local_h: u64 = ((((0 as u64) -% 3750763034362895579) as u64))

    while ((*__local_msg) != 0) {
        var __ci_expr_old_0: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as u64) ^ ((*__ci_expr_old_0) as u64))


        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_mix_n(__param_h: *mut u64, __param_n: i64) -> u64 {
    var __local_i: i64 = ((1 as i64))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        ((__param_h[0]) = ((__param_h[0]) +% (((__param_h[0]) as u64) ^ ((__param_h[__local_i]) as u64))))

        (__local_i = __local_i + 1)

    }


    return (__param_h[0])

}

fn c_next_pow2(__param_n: i64) -> i64 {
    var __local_n = __param_n
    (__local_n = __local_n - 1)

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (1 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (2 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (4 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (8 as u32)) as i64))


    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (16 as u32)) as i64))

    (__local_n = (__local_n as i64) | (((__local_n as i64) >> (32 as u32)) as i64))

    return (__local_n + 1)

}

unsafe fn c_strnstrn(__param_str: *const c_char, __param_slen: i64, __param_needle: *const c_char, __param_nlen: i64) -> *mut c_char {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return ((__local_str as *mut c_char))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut c_char))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: i32 = 0

        if ((if (*__local_str) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as i64)) as u64) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return ((__local_str as *mut c_char))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: i64 = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut c_char))

}

extern fn assert_str(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_char, __param_real: *const c_char, __param_caller: *const c_char, __param_line: i32)
extern fn assert_wstr(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const i32, __param_real: *const i32, __param_caller: *const c_char, __param_line: i32)
extern fn assert_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_interval(__param_diag: i32, __param_low: i64, __param_high: i64, __param_real: i64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_pointers(__param_diag: i32, __param_cmp: *const c_char, __param_exp: *const c_void, __param_real: *const c_void, __param_caller: *const c_char, __param_line: i32)
extern fn assert_bool(__param_diag: i32, __param_exp: bool, __param_real: bool, __param_caller: *const c_char, __param_line: i32)
extern fn assert_dbl_compare(__param_diag: i32, __param_cmp: *const c_char, __param_exp: f64, __param_real: f64, __param_tol: f64, __param_caller: *const c_char, __param_line: i32)
extern fn assert_fail(__param_caller: *const c_char, __param_line: i32)
unsafe fn Span_slice_(__param_d: *mut i32, __param_shape: *mut i32, __param_stri: *mut i32, __param_args: *mut [i64; 3], __param_rank: i32) -> Span {
    var __local_s: Span

    var __local_outrank: i32

    (__local_s.data = __param_d + ((_cspan_slice((&(*(&raw const __local_s as *const Span)).shape[0] as *mut i32), (&(*(&raw const __local_s.stride as *const cspan_tuple1)).d[0] as *mut i32), (&raw mut __local_outrank as *mut i32), (&(__param_shape[0]) as *mut i32), (&(__param_stri[0]) as *mut i32), (&(__param_args[0]) as *mut [i64; 3]), __param_rank) as i64) as usize))

    if (((if not ((if __local_outrank == 1: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Span_slice_".ptr, c"cspan_test.c".ptr, (5 as i32), c"outrank == 1".ptr)
    } else {
        0
    }

    return __local_s

}

unsafe fn Span_begin(__param_self_: *const Span) -> Span_iter {
    var __ci_expr_ternary_1: *mut i32 = null

    var __ci_expr_logic_0: i32 = 0

    if ((if 1 == 1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_self_).shape[0] == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = ((null as *mut i32)))
    } else {
        (__ci_expr_ternary_1 = (*__param_self_).data)
    }

    return ((Span_iter { ref: __ci_expr_ternary_1, _s: __param_self_ } as Span_iter))


}

unsafe fn Span_end(__param_self_: *const Span) -> Span_iter {

    return ((Span_iter.zeroed() as Span_iter))

}

unsafe fn Span_next(__param_it_: *mut Span_iter) -> Unit {
    var __local_off: i64 = (((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple1)).d[(1 - 1)] as i64))

    var __local_done: bool = with 0 as __ci_expr_seq_6 {
        ((*__param_it_).pos[0] = (*__param_it_).pos[0] + 1)
        (((*__param_it_).pos[0] == (*(*__param_it_)._s).shape[0]))
    }

    if __local_done {
        ((*__param_it_).ref = ((null as *mut i32)))
    } else {
        ((*__param_it_).ref = (*__param_it_).ref + ((__local_off as i64) as usize))
    }

}

unsafe fn Span_size(__param_self_: *const Span) -> i64 {
    return _cspan_size((&(*__param_self_).shape[0] as *mut i32), (1 as i32))

}

fn Span_transposed(__param_sp: Span) -> Span {
    unsafe { _cspan_transpose((&(*(&raw const __param_sp as *const Span)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple1)).d[0] as *mut i32), (1 as i32)) }

    return __param_sp

}

fn Span_swapped_axes(__param_sp: Span, __param_ax1: i32, __param_ax2: i32) -> Span {
    unsafe { _cspan_swap_axes((&(*(&raw const __param_sp as *const Span)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple1)).d[0] as *mut i32), (1 as i32), __param_ax1, __param_ax2) }

    return __param_sp

}

unsafe fn Span_eq(__param_x: *const Span, __param_y: *const Span) -> bool {
    if ((if with_memcmp(((&(*__param_x).shape[0] as *mut i32) as *const u8), ((&(*__param_y).shape[0] as *mut i32) as *const u8), (((1 * (sizeof[i32]() as usize)) as u64) as i64)) != 0: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local__i: Span_iter = Span_begin(__param_x)

    var __local__j: Span_iter = Span_begin(__param_y)


    while ((if (*(&raw const __local__i as *const Span_iter)).ref != null: 1 else: 0) != 0) {
        if ((if not ((if (*((*(&raw const __local__i as *const Span_iter)).ref)) == (*((*(&raw const __local__j as *const Span_iter)).ref)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return ((false as bool))
        }


        Span_next((&raw mut __local__i as *mut Span_iter))

        Span_next((&raw mut __local__j as *mut Span_iter))


    }


    return ((true as bool))

}

fn Span_equals(__param_sp1: Span, __param_sp2: Span) -> bool {
    return unsafe { Span_eq(((&raw mut __param_sp1 as *mut Span) as *const Span), ((&raw mut __param_sp2 as *mut Span) as *const Span)) }

}

unsafe fn Span_from_n(__param_dataptr: *mut i32, __param_n: i64) -> Span {
    return ((Span { data: __param_dataptr, shape: [((__param_n) as i32)], stride: cspan_tuple1 { d: [1] } } as Span))

}

unsafe fn Span2_slice_(__param_d: *mut i32, __param_shape: *mut i32, __param_stri: *mut i32, __param_args: *mut [i64; 3], __param_rank: i32) -> Span2 {
    var __local_s: Span2

    var __local_outrank: i32

    (__local_s.data = __param_d + ((_cspan_slice((&(*(&raw const __local_s as *const Span2)).shape[0] as *mut i32), (&(*(&raw const __local_s.stride as *const cspan_tuple2)).d[0] as *mut i32), (&raw mut __local_outrank as *mut i32), (&(__param_shape[0]) as *mut i32), (&(__param_stri[0]) as *mut i32), (&(__param_args[0]) as *mut [i64; 3]), __param_rank) as i64) as usize))

    if (((if not ((if __local_outrank == 2: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Span2_slice_".ptr, c"cspan_test.c".ptr, (5 as i32), c"outrank == 2".ptr)
    } else {
        0
    }

    return __local_s

}

unsafe fn Span2_begin(__param_self_: *const Span2) -> Span2_iter {
    var __ci_expr_ternary_1: *mut i32 = null

    var __ci_expr_logic_0: i32 = 0

    if ((if 2 == 1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_self_).shape[0] == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = ((null as *mut i32)))
    } else {
        (__ci_expr_ternary_1 = (*__param_self_).data)
    }

    return ((Span2_iter { ref: __ci_expr_ternary_1, _s: __param_self_ } as Span2_iter))


}

unsafe fn Span2_end(__param_self_: *const Span2) -> Span2_iter {

    return ((Span2_iter.zeroed() as Span2_iter))

}

unsafe fn Span2_next(__param_it_: *mut Span2_iter) -> Unit {
    var __local_off: i64 = (((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple2)).d[(2 - 1)] as i64))

    var __local_done: bool = with 0 as __ci_expr_seq_17 {
        var __ci_expr_logic_0: i32 = 0
        ((*__param_it_).pos[1] = (*__param_it_).pos[1] + 1)
        if ((if (*__param_it_).pos[1] == (*(*__param_it_)._s).shape[1]: 1 else: 0) != 0) {
            ((*__param_it_).pos[1] = ((0 as i32)))
            ((*(&raw mut __local_off as *mut i64)) = (*(&raw mut __local_off as *mut i64)) + ((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple2)).d[0] - (((*(*__param_it_)._s).shape[1] as i64) * (*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple2)).d[1])))
            ((*__param_it_).pos[0] = (*__param_it_).pos[0] + 1)
            (__ci_expr_logic_0 = (if (if (*__param_it_).pos[0] == (*(*__param_it_)._s).shape[0]: 1 else: 0) != 0: 1 else: 0))
        }
        (__ci_expr_logic_0 != 0)
    }

    if __local_done {
        ((*__param_it_).ref = ((null as *mut i32)))
    } else {
        ((*__param_it_).ref = (*__param_it_).ref + ((__local_off as i64) as usize))
    }

}

unsafe fn Span2_size(__param_self_: *const Span2) -> i64 {
    return _cspan_size((&(*__param_self_).shape[0] as *mut i32), (2 as i32))

}

fn Span2_transposed(__param_sp: Span2) -> Span2 {
    unsafe { _cspan_transpose((&(*(&raw const __param_sp as *const Span2)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple2)).d[0] as *mut i32), (2 as i32)) }

    return __param_sp

}

fn Span2_swapped_axes(__param_sp: Span2, __param_ax1: i32, __param_ax2: i32) -> Span2 {
    unsafe { _cspan_swap_axes((&(*(&raw const __param_sp as *const Span2)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple2)).d[0] as *mut i32), (2 as i32), __param_ax1, __param_ax2) }

    return __param_sp

}

unsafe fn Span2_eq(__param_x: *const Span2, __param_y: *const Span2) -> bool {
    if ((if with_memcmp(((&(*__param_x).shape[0] as *mut i32) as *const u8), ((&(*__param_y).shape[0] as *mut i32) as *const u8), (((2 * (sizeof[i32]() as usize)) as u64) as i64)) != 0: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local__i: Span2_iter = Span2_begin(__param_x)

    var __local__j: Span2_iter = Span2_begin(__param_y)


    while ((if (*(&raw const __local__i as *const Span2_iter)).ref != null: 1 else: 0) != 0) {
        if ((if not ((if (*((*(&raw const __local__i as *const Span2_iter)).ref)) == (*((*(&raw const __local__j as *const Span2_iter)).ref)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return ((false as bool))
        }


        Span2_next((&raw mut __local__i as *mut Span2_iter))

        Span2_next((&raw mut __local__j as *mut Span2_iter))


    }


    return ((true as bool))

}

fn Span2_equals(__param_sp1: Span2, __param_sp2: Span2) -> bool {
    return unsafe { Span2_eq(((&raw mut __param_sp1 as *mut Span2) as *const Span2), ((&raw mut __param_sp2 as *mut Span2) as *const Span2)) }

}

unsafe fn Span3_slice_(__param_d: *mut i32, __param_shape: *mut i32, __param_stri: *mut i32, __param_args: *mut [i64; 3], __param_rank: i32) -> Span3 {
    var __local_s: Span3

    var __local_outrank: i32

    (__local_s.data = __param_d + ((_cspan_slice((&(*(&raw const __local_s as *const Span3)).shape[0] as *mut i32), (&(*(&raw const __local_s.stride as *const cspan_tuple3)).d[0] as *mut i32), (&raw mut __local_outrank as *mut i32), (&(__param_shape[0]) as *mut i32), (&(__param_stri[0]) as *mut i32), (&(__param_args[0]) as *mut [i64; 3]), __param_rank) as i64) as usize))

    if (((if not ((if __local_outrank == 3: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Span3_slice_".ptr, c"cspan_test.c".ptr, (5 as i32), c"outrank == 3".ptr)
    } else {
        0
    }

    return __local_s

}

unsafe fn Span3_begin(__param_self_: *const Span3) -> Span3_iter {
    var __ci_expr_ternary_1: *mut i32 = null

    var __ci_expr_logic_0: i32 = 0

    if ((if 3 == 1: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*__param_self_).shape[0] == 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__ci_expr_ternary_1 = ((null as *mut i32)))
    } else {
        (__ci_expr_ternary_1 = (*__param_self_).data)
    }

    return ((Span3_iter { ref: __ci_expr_ternary_1, _s: __param_self_ } as Span3_iter))


}

unsafe fn Span3_end(__param_self_: *const Span3) -> Span3_iter {

    return ((Span3_iter.zeroed() as Span3_iter))

}

unsafe fn Span3_next(__param_it_: *mut Span3_iter) -> Unit {
    var __local_off: i64 = (((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple3)).d[(3 - 1)] as i64))

    var __local_done: bool = with 0 as __ci_expr_seq_28 {
        var __ci_expr_logic_1: i32 = 0
        var __ci_expr_logic_0: i32 = 0
        ((*__param_it_).pos[2] = (*__param_it_).pos[2] + 1)
        if ((if (*__param_it_).pos[2] == (*(*__param_it_)._s).shape[2]: 1 else: 0) != 0) {
            ((*__param_it_).pos[2] = ((0 as i32)))
            ((*(&raw mut __local_off as *mut i64)) = (*(&raw mut __local_off as *mut i64)) + ((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple3)).d[1] - (((*(*__param_it_)._s).shape[2] as i64) * (*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple3)).d[2])))
            ((*__param_it_).pos[1] = (*__param_it_).pos[1] + 1)
            (__ci_expr_logic_0 = (if (if (*__param_it_).pos[1] == (*(*__param_it_)._s).shape[1]: 1 else: 0) != 0: 1 else: 0))
        }
        if (__ci_expr_logic_0 != 0) {
            ((*__param_it_).pos[1] = ((0 as i32)))
            ((*(&raw mut __local_off as *mut i64)) = (*(&raw mut __local_off as *mut i64)) + ((*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple3)).d[0] - (((*(*__param_it_)._s).shape[1] as i64) * (*(&raw const (*(*__param_it_)._s).stride as *const cspan_tuple3)).d[1])))
            ((*__param_it_).pos[0] = (*__param_it_).pos[0] + 1)
            (__ci_expr_logic_1 = (if (if (*__param_it_).pos[0] == (*(*__param_it_)._s).shape[0]: 1 else: 0) != 0: 1 else: 0))
        }
        (__ci_expr_logic_1 != 0)
    }

    if __local_done {
        ((*__param_it_).ref = ((null as *mut i32)))
    } else {
        ((*__param_it_).ref = (*__param_it_).ref + ((__local_off as i64) as usize))
    }

}

unsafe fn Span3_size(__param_self_: *const Span3) -> i64 {
    return _cspan_size((&(*__param_self_).shape[0] as *mut i32), (3 as i32))

}

fn Span3_transposed(__param_sp: Span3) -> Span3 {
    unsafe { _cspan_transpose((&(*(&raw const __param_sp as *const Span3)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple3)).d[0] as *mut i32), (3 as i32)) }

    return __param_sp

}

fn Span3_swapped_axes(__param_sp: Span3, __param_ax1: i32, __param_ax2: i32) -> Span3 {
    unsafe { _cspan_swap_axes((&(*(&raw const __param_sp as *const Span3)).shape[0] as *mut i32), (&(*(&raw const __param_sp.stride as *const cspan_tuple3)).d[0] as *mut i32), (3 as i32), __param_ax1, __param_ax2) }

    return __param_sp

}

unsafe fn Span3_eq(__param_x: *const Span3, __param_y: *const Span3) -> bool {
    if ((if with_memcmp(((&(*__param_x).shape[0] as *mut i32) as *const u8), ((&(*__param_y).shape[0] as *mut i32) as *const u8), (((3 * (sizeof[i32]() as usize)) as u64) as i64)) != 0: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local__i: Span3_iter = Span3_begin(__param_x)

    var __local__j: Span3_iter = Span3_begin(__param_y)


    while ((if (*(&raw const __local__i as *const Span3_iter)).ref != null: 1 else: 0) != 0) {
        if ((if not ((if (*((*(&raw const __local__i as *const Span3_iter)).ref)) == (*((*(&raw const __local__j as *const Span3_iter)).ref)): 1 else: 0) != 0): 1 else: 0) != 0) {
            return ((false as bool))
        }


        Span3_next((&raw mut __local__i as *mut Span3_iter))

        Span3_next((&raw mut __local__j as *mut Span3_iter))


    }


    return ((true as bool))

}

fn Span3_equals(__param_sp1: Span3, __param_sp2: Span3) -> bool {
    return unsafe { Span3_eq(((&raw mut __param_sp1 as *mut Span3) as *const Span3), ((&raw mut __param_sp2 as *mut Span3) as *const Span3)) }

}

fn ctest_cspan_subdim_run() {
    var __local_array: List[i32] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

    var __local_m: Span3 = with 0 as __ci_expr_seq_8 {
        var __ci_expr_lit_0: [i32; 3] = [2, 2, 3]
        var __ci_expr_init_1: cspan_tuple3 = (unsafe *(unsafe { _cspan_shape2stride((0 as i32), (&__ci_expr_lit_0[0] as *mut i32), (3 as i32)) } as *mut cspan_tuple3))
        Span3 { data: (&raw const __local_array[0] as *mut i32), shape: [2, 2, 3], stride: __ci_expr_init_1 }
    }

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (((unsafe *(&raw const __local_m as *const Span3)).shape[0] as i64))


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        var __local_sub_i: Span2 = with 0 as __ci_expr_seq_108 {
            var __ci_expr_logic_3: i32 = 0
            var __ci_expr_logic_2: i32 = 0
            if ((if __local_i < (unsafe *(&raw mut __local_m as *mut Span3)).shape[0]: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if 0 < (unsafe *(&raw mut __local_m as *mut Span3)).shape[1]: 1 else: 0) != 0: 1 else: 0))
            }
            if (__ci_expr_logic_2 != 0) {
                (__ci_expr_logic_3 = (if (if 0 < (unsafe *(&raw mut __local_m as *mut Span3)).shape[2]: 1 else: 0) != 0: 1 else: 0))
            }
            if (((if not (__ci_expr_logic_3 != 0): 1 else: 0) as i64) != 0) {
                __assert_rtn(c"ctest_cspan_subdim_run".ptr, c"cspan_test.c".ptr, (12 as i32), c"(i) < (&m)->shape[0] && (0) < (&m)->shape[1] && (0) < (&m)->shape[2]".ptr)
            } else {
                0
            }
            var __ci_expr_init_4: *mut i32 = ((unsafe *(&raw mut __local_m as *mut Span3)).data + (((((__local_i * (unsafe *(&raw const (*(&raw mut __local_m as *mut Span3)).stride as *const cspan_tuple3)).d[0]) + (0 * (unsafe *(&raw const (*(&raw mut __local_m as *mut Span3)).stride as *const cspan_tuple3)).d[1])) + (0 * (unsafe *(&raw const (*(&raw mut __local_m as *mut Span3)).stride as *const cspan_tuple3)).d[2])) as i64) as usize))
            Span2 { data: (__ci_expr_init_4), shape: [((unsafe (&raw const ((&raw mut __local_m as *mut Span3)).shape[0] as *mut i32)[1]) as i32), ((unsafe (&raw const ((&raw mut __local_m as *mut Span3)).shape[0] as *mut i32)[2]) as i32)], stride: cspan_tuple2 { d: [((unsafe (&raw const ((&raw mut __local_m as *mut Span3)).stride.d[0] as *mut i32)[1]) as i32), ((unsafe (&raw const ((&raw mut __local_m as *mut Span3)).stride.d[0] as *mut i32)[2]) as i32)] } }
        }

        var __local_j: i64 = ((0 as i64))

        var __local__c_end_j: i64 = (((unsafe *(&raw const __local_m as *const Span3)).shape[1] as i64))


        while ((if __local_j < __local__c_end_j: 1 else: 0) != 0) {
            var __local_sub_i_j: Span = with 0 as __ci_expr_seq_95 {
                var __ci_expr_logic_5: i32 = 0
                if ((if __local_j < (unsafe *(&raw mut __local_sub_i as *mut Span2)).shape[0]: 1 else: 0) != 0) {
                    (__ci_expr_logic_5 = (if (if 0 < (unsafe *(&raw mut __local_sub_i as *mut Span2)).shape[1]: 1 else: 0) != 0: 1 else: 0))
                }
                if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as i64) != 0) {
                    __assert_rtn(c"ctest_cspan_subdim_run".ptr, c"cspan_test.c".ptr, (14 as i32), c"(j) < (&sub_i)->shape[0] && (0) < (&sub_i)->shape[1]".ptr)
                } else {
                    0
                }
                var __ci_expr_init_6: *mut i32 = ((unsafe *(&raw mut __local_sub_i as *mut Span2)).data + ((((__local_j * (unsafe *(&raw const (*(&raw mut __local_sub_i as *mut Span2)).stride as *const cspan_tuple2)).d[0]) + (0 * (unsafe *(&raw const (*(&raw mut __local_sub_i as *mut Span2)).stride as *const cspan_tuple2)).d[1])) as i64) as usize))
                Span { data: (__ci_expr_init_6), shape: [((unsafe (&raw const ((&raw mut __local_sub_i as *mut Span2)).shape[0] as *mut i32)[1]) as i32)], stride: cspan_tuple1 { d: [((unsafe (&raw const ((&raw mut __local_sub_i as *mut Span2)).stride.d[0] as *mut i32)[1]) as i32)] } }
            }

            var __local_k: i64 = ((0 as i64))

            var __local__c_end_k: i64 = (((unsafe *(&raw const __local_m as *const Span3)).shape[2] as i64))


            while ((if __local_k < __local__c_end_k: 1 else: 0) != 0) {
                if (((if not ((if __local_k < (unsafe *(&raw mut __local_sub_i_j as *mut Span)).shape[0]: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                    __assert_rtn(c"ctest_cspan_subdim_run".ptr, c"cspan_test.c".ptr, (16 as i32), c"(k) < (&sub_i_j)->shape[0]".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_8: i32 = 0

                var __ci_expr_logic_7: i32 = 0

                if ((if __local_i < (unsafe *(&raw mut __local_m as *mut Span3)).shape[0]: 1 else: 0) != 0) {
                    (__ci_expr_logic_7 = (if (if __local_j < (unsafe *(&raw mut __local_m as *mut Span3)).shape[1]: 1 else: 0) != 0: 1 else: 0))
                }

                if (__ci_expr_logic_7 != 0) {
                    (__ci_expr_logic_8 = (if (if __local_k < (unsafe *(&raw mut __local_m as *mut Span3)).shape[2]: 1 else: 0) != 0: 1 else: 0))
                }

                if (((if not (__ci_expr_logic_8 != 0): 1 else: 0) as i64) != 0) {
                    __assert_rtn(c"ctest_cspan_subdim_run".ptr, c"cspan_test.c".ptr, (16 as i32), c"(i) < (&m)->shape[0] && (j) < (&m)->shape[1] && (k) < (&m)->shape[2]".ptr)
                } else {
                    0
                }

                assert_compare((1 as i32), c"==".ptr, ((unsafe *((*(&raw mut __local_sub_i_j as *mut Span)).data + (((__local_k * (*(&raw const (*(&raw mut __local_sub_i_j as *mut Span)).stride as *const cspan_tuple1)).d[0]) as i64) as usize))) as i64), ((unsafe *((*(&raw mut __local_m as *mut Span3)).data + (((((__local_i * (*(&raw const (*(&raw mut __local_m as *mut Span3)).stride as *const cspan_tuple3)).d[0]) + (__local_j * (*(&raw const (*(&raw mut __local_m as *mut Span3)).stride as *const cspan_tuple3)).d[1])) + (__local_k * (*(&raw const (*(&raw mut __local_m as *mut Span3)).stride as *const cspan_tuple3)).d[2])) as i64) as usize))) as i64), c"cspan_test.c".ptr, (16 as i32))



                (__local_k = __local_k + 1)

            }



            (__local_j = __local_j + 1)

        }



        (__local_i = __local_i + 1)

    }


}

fn ctest_cspan_slice_run() {
    var __local_array: List[i32] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

    var __local_m1: Span2 = with 0 as __ci_expr_seq_8 {
        var __ci_expr_lit_0: [i32; 2] = [3, 4]
        var __ci_expr_init_1: cspan_tuple2 = (unsafe *(unsafe { _cspan_shape2stride((0 as i32), (&__ci_expr_lit_0[0] as *mut i32), (2 as i32)) } as *mut cspan_tuple2))
        Span2 { data: (&raw const __local_array[0] as *mut i32), shape: [3, 4], stride: __ci_expr_init_1 }
    }

    var __local_sum1: i32 = ((0 as i32))

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (((unsafe *(&raw const __local_m1 as *const Span2)).shape[0] as i64))


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        var __local_j: i64 = ((0 as i64))

        var __local__c_end_j: i64 = (((unsafe *(&raw const __local_m1 as *const Span2)).shape[1] as i64))


        while ((if __local_j < __local__c_end_j: 1 else: 0) != 0) {
            var __ci_expr_logic_2: i32 = 0

            if ((if __local_i < (unsafe *(&raw mut __local_m1 as *mut Span2)).shape[0]: 1 else: 0) != 0) {
                (__ci_expr_logic_2 = (if (if __local_j < (unsafe *(&raw mut __local_m1 as *mut Span2)).shape[1]: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_2 != 0): 1 else: 0) as i64) != 0) {
                __assert_rtn(c"ctest_cspan_slice_run".ptr, c"cspan_test.c".ptr, (30 as i32), c"(i) < (&m1)->shape[0] && (j) < (&m1)->shape[1]".ptr)
            } else {
                0
            }

            (__local_sum1 = __local_sum1 + (unsafe *((*(&raw mut __local_m1 as *mut Span2)).data + ((((__local_i * (*(&raw const (*(&raw mut __local_m1 as *mut Span2)).stride as *const cspan_tuple2)).d[0]) + (__local_j * (*(&raw const (*(&raw mut __local_m1 as *mut Span2)).stride as *const cspan_tuple2)).d[1])) as i64) as usize))))



            (__local_j = __local_j + 1)

        }



        (__local_i = __local_i + 1)

    }


    var __local_m2: Span2 = with 0 as __ci_expr_seq_51 {
        var __ci_expr_lit_3: [i64; 2, 3] = [[0, 2147483647, 0 as i64], [2, 4, 0 as i64]]
        unsafe { Span2_slice_((*(&raw mut __local_m1 as *mut Span2)).data, (&(*(&raw mut __local_m1 as *mut Span2)).shape[0] as *mut i32), (&(*(&raw const (*(&raw mut __local_m1 as *mut Span2)).stride as *const cspan_tuple2)).d[0] as *mut i32), (&__ci_expr_lit_3[0] as *mut [i64; 3]), (((((&raw mut __local_m1 as *mut Span2)).shape.len() as u64) as i64) as i32)) }
    }

    var __local_sum2: i32 = ((0 as i32))

    var __local_i_1: i64 = ((0 as i64))

    var __local__c_end_i_1: i64 = (((unsafe *(&raw const __local_m2 as *const Span2)).shape[0] as i64))


    while ((if __local_i_1 < __local__c_end_i_1: 1 else: 0) != 0) {
        var __local_j_1: i64 = ((0 as i64))

        var __local__c_end_j_1: i64 = (((unsafe *(&raw const __local_m2 as *const Span2)).shape[1] as i64))


        while ((if __local_j_1 < __local__c_end_j_1: 1 else: 0) != 0) {
            var __ci_expr_logic_4: i32 = 0

            if ((if __local_i_1 < (unsafe *(&raw mut __local_m2 as *mut Span2)).shape[0]: 1 else: 0) != 0) {
                (__ci_expr_logic_4 = (if (if __local_j_1 < (unsafe *(&raw mut __local_m2 as *mut Span2)).shape[1]: 1 else: 0) != 0: 1 else: 0))
            }

            if (((if not (__ci_expr_logic_4 != 0): 1 else: 0) as i64) != 0) {
                __assert_rtn(c"ctest_cspan_slice_run".ptr, c"cspan_test.c".ptr, (39 as i32), c"(i) < (&m2)->shape[0] && (j) < (&m2)->shape[1]".ptr)
            } else {
                0
            }

            (__local_sum2 = __local_sum2 + (unsafe *((*(&raw mut __local_m2 as *mut Span2)).data + ((((__local_i_1 * (*(&raw const (*(&raw mut __local_m2 as *mut Span2)).stride as *const cspan_tuple2)).d[0]) + (__local_j_1 * (*(&raw const (*(&raw mut __local_m2 as *mut Span2)).stride as *const cspan_tuple2)).d[1])) as i64) as usize))))



            (__local_j_1 = __local_j_1 + 1)

        }



        (__local_i_1 = __local_i_1 + 1)

    }


    assert_compare((1 as i32), c"==".ptr, (78 as i64), (__local_sum1 as i64), c"cspan_test.c".ptr, (42 as i32))

    assert_compare((1 as i32), c"==".ptr, (45 as i64), (__local_sum2 as i64), c"cspan_test.c".ptr, (43 as i32))

}

pub unsafe fn Stack_move(__param_self_: *mut Stack) -> Stack {
    var __local_m: Stack = (*__param_self_)

    ((*__param_self_).size = ((0 as i64)))

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).data = ((null as *mut i32)))

    return __local_m

}

pub unsafe fn Stack_capacity(__param_self_: *const Stack) -> i64 {
    return (*__param_self_).capacity

}

pub unsafe fn Stack_reserve(__param_self_: *mut Stack, __param_cap: i64) -> bool {
    var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (*__param_self_).size else: __param_cap) as i64))

    if ((((if __param_cap > (*__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as i32)) != 0) {
        var __local_d: *mut i32 = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[i32]() as i64)) as i64) else: (((*__param_self_).capacity * (sizeof[i32]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((((*__param_self_).data != null)) as bool))

}

pub unsafe fn Stack_clear(__param_self_: *mut Stack) {
    var __local_i: i64 = (*__param_self_).size

    while true {
        var __ci_expr_old_0: i64 = __local_i

        (__local_i = __local_i - 1)

        if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
            break
        }

    }

    ((*__param_self_).size = ((0 as i64)))

}

pub unsafe fn Stack_drop(__param_cself: *const Stack) {
    var __local_self_: *mut Stack = ((__param_cself as *mut Stack))

    Stack_clear(__local_self_)

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

pub unsafe fn Stack_take(__param_self_: *mut Stack, __param_unowned: Stack) -> Unit {
    Stack_drop((__param_self_ as *const Stack))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Stack]())

}

pub unsafe fn Stack_size(__param_self_: *const Stack) -> i64 {
    return (*__param_self_).size

}

pub unsafe fn Stack_is_empty(__param_self_: *const Stack) -> bool {
    return ((((not ((*__param_self_).size != 0))) as bool))

}

pub unsafe fn Stack_value_drop(__param_self_: *const Stack, __param_val: *mut i32) {
    return
}

pub unsafe fn Stack_append_uninit(__param_self_: *mut Stack, __param_n: i64) -> *mut i32 {
    var __local_len: i64 = (*__param_self_).size

    if ((if (__local_len + __param_n) >= Stack_capacity((__param_self_ as *const Stack)): 1 else: 0) != 0) {
        if ((if not Stack_reserve(__param_self_, ((((__local_len * 3) / 2) + __param_n) as i64)): 1 else: 0) != 0) {
            return ((null as *mut i32))
        }
    }

    ((*__param_self_).size = (*__param_self_).size + __param_n)

    return ((((*__param_self_).data + ((__local_len as i64) as usize)) as *mut i32))

}

pub unsafe fn Stack_shrink_to_fit(__param_self_: *mut Stack) -> Unit {
    Stack_reserve(__param_self_, (9223372036854775807 as i64))

}

pub unsafe fn Stack_front(__param_self_: *const Stack) -> *const i32 {
    return ((((&raw const ((*__param_self_).data[0]) as *const i32) as *mut i32) as *const i32))

}

pub unsafe fn Stack_front_mut(__param_self_: *mut Stack) -> *mut i32 {
    return (((&raw const ((*__param_self_).data[0]) as *const i32) as *mut i32))

}

pub unsafe fn Stack_back(__param_self_: *const Stack) -> *const i32 {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const i32) as *mut i32) as *const i32))

}

pub unsafe fn Stack_back_mut(__param_self_: *mut Stack) -> *mut i32 {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const i32) as *mut i32))

}

pub unsafe fn Stack_top(__param_self_: *const Stack) -> *const i32 {
    return ((Stack_back(__param_self_) as *const i32))

}

pub unsafe fn Stack_top_mut(__param_self_: *mut Stack) -> *mut i32 {
    return ((Stack_back_mut(__param_self_) as *mut i32))

}

pub unsafe fn Stack_push(__param_self_: *mut Stack, __param_val: i32) -> *mut i32 {
    if ((if (*__param_self_).size == Stack_capacity((__param_self_ as *const Stack)): 1 else: 0) != 0) {
        if ((if not Stack_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 4) as i64)): 1 else: 0) != 0) {
            return ((null as *mut i32))
        }
    }

    var __local_vp: *mut i32 = with 0 as __ci_expr_seq_10 {
        var __ci_expr_old_0: i64 = (*__param_self_).size
        ((*__param_self_).size = (*__param_self_).size + 1)
        ((*__param_self_).data + ((__ci_expr_old_0 as i64) as usize))
    }

    ((*__local_vp) = __param_val)

    return __local_vp

}

pub unsafe fn Stack_pop(__param_self_: *mut Stack) {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Stack_pop".ptr, c"stack.h".ptr, (149 as i32), c"self->size".ptr)
    } else {
        0
    }

    var __local_p: *mut i32 = with 0 as __ci_expr_seq_8 {
        ((*__param_self_).size = (*__param_self_).size - 1)
        ((&raw const ((*__param_self_).data[(*__param_self_).size]) as *const i32) as *mut i32)
    }


}

pub unsafe fn Stack_pull(__param_self_: *mut Stack) -> i32 {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Stack_pull".ptr, c"stack.h".ptr, (152 as i32), c"self->size".ptr)
    } else {
        0
    }

    ((*__param_self_).size = (*__param_self_).size - 1)

    return ((*__param_self_).data[(*__param_self_).size])


}

pub unsafe fn Stack_put_n(__param_self_: *mut Stack, __param_raw: *const i32, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        Stack_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn Stack_init() -> Stack {
    var __local_out: Stack = Stack.zeroed()

    return __local_out

}

pub fn Stack_with_capacity(__param_cap: i64) -> Stack {
    var __local_out: Stack = Stack { data: (((with_alloc((((if 1 != 0: ((__param_cap * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)), size: 0, capacity: __param_cap }

    return __local_out

}

pub fn Stack_with_size_uninit(__param_size: i64) -> Stack {
    var __local_out: Stack = Stack { data: (((with_alloc((((if 1 != 0: ((__param_size * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)), size: __param_size, capacity: __param_size }

    return __local_out

}

pub fn Stack_with_size(__param_size: i64, __param_default_raw: i32) -> Stack {
    var __local_size = __param_size
    var __local_out: Stack = Stack { data: (((with_alloc((((if 1 != 0: ((__local_size * (sizeof[i32]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i32)), size: __local_size, capacity: __local_size }

    while (__local_size != 0) {
        (__local_size = __local_size - 1)

        ((unsafe __local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

pub unsafe fn Stack_from_n(__param_raw: *const i32, __param_n: i64) -> Stack {
    var __local_out: Stack = Stack_with_capacity(__param_n)

    Stack_put_n((&raw mut __local_out as *mut Stack), __param_raw, __param_n)

    return __local_out

}

pub unsafe fn Stack_at(__param_self_: *const Stack, __param_idx: i64) -> *const i32 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Stack_at".ptr, c"stack.h".ptr, (189 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *const i32))

}

pub unsafe fn Stack_at_mut(__param_self_: *mut Stack, __param_idx: i64) -> *mut i32 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Stack_at_mut".ptr, c"stack.h".ptr, (192 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *mut i32))

}

pub fn Stack_clone(__param_stk: Stack) -> Stack {
    var __local_out: Stack = __param_stk

    var __local_self_: *mut Stack = ((&raw mut __local_out as *mut Stack))



    (__local_out.data = ((null as *mut i32)))

    (__local_out.capacity = ((0 as i64)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Stack)).capacity)


    unsafe { Stack_reserve((&raw mut __local_out as *mut Stack), (*(&raw const __param_stk as *const Stack)).size) }

    (__local_out.size = (unsafe *(&raw const __param_stk as *const Stack)).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (unsafe *(&raw const __param_stk as *const Stack)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (((unsafe (*(&raw const __param_stk as *const Stack)).data[__local_i]) as i32)))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

pub unsafe fn Stack_copy(__param_self_: *mut Stack, __param_other: *const Stack) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    Stack_clear(__param_self_)

    Stack_reserve(__param_self_, (*__param_other).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (*__param_self_).size

        ((*__param_self_).size = (*__param_self_).size + 1)

        (((*__param_self_).data[__ci_expr_old_0]) = ((((*__param_other).data[__local_i]) as i32)))


        (__local_i = __local_i + 1)

    }


}

pub unsafe fn Stack_value_clone(__param_self_: *const Stack, __param_val: i32) -> i32 {

    return __param_val

}

pub unsafe fn Stack_value_toraw(__param_val: *const i32) -> i32 {
    return (*__param_val)

}

pub unsafe fn Stack_begin(__param_self_: *const Stack) -> Stack_iter {
    var __local_it_: Stack_iter = Stack_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.end = (*(&raw const __local_it_ as *const Stack_iter)).end + (((*__param_self_).size as i64) as usize))
    } else {
        (__local_it_.ref = ((null as *mut i32)))
    }

    return __local_it_

}

pub unsafe fn Stack_rbegin(__param_self_: *const Stack) -> Stack_iter {
    var __local_it_: Stack_iter = Stack_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const Stack_iter)).ref + ((((*__param_self_).size - 1) as i64) as usize))

        (__local_it_.end = (*(&raw const __local_it_ as *const Stack_iter)).end - ((1 as i64) as usize))

    } else {
        (__local_it_.ref = ((null as *mut i32)))
    }

    return __local_it_

}

pub unsafe fn Stack_end(__param_self_: *const Stack) -> Stack_iter {

    var __local_it_: Stack_iter = Stack_iter.zeroed()

    return __local_it_

}

pub unsafe fn Stack_rend(__param_self_: *const Stack) -> Stack_iter {

    var __local_it_: Stack_iter = Stack_iter.zeroed()

    return __local_it_

}

pub unsafe fn Stack_next(__param_it_: *mut Stack_iter) {
    ((*__param_it_).ref = (*__param_it_).ref + 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut i32)))
    }


}

pub unsafe fn Stack_rnext(__param_it_: *mut Stack_iter) {
    ((*__param_it_).ref = (*__param_it_).ref - 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut i32)))
    }


}

pub fn Stack_advance(__param_it_: Stack_iter, __param_n: u64) -> Stack_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const Stack_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const Stack_iter)).ref >= (unsafe *(&raw const __param_it_ as *const Stack_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut i32)))
    }


    return __param_it_

}

pub unsafe fn Stack_index(__param_self_: *const Stack, __param_it_: Stack_iter) -> i64 {
    return (((((*(&raw const __param_it_ as *const Stack_iter)).ref as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[i32]() as i64))

}

pub unsafe fn Stack_adjust_end_(__param_self_: *mut Stack, __param_n: i64) {
    ((*__param_self_).size = (*__param_self_).size + __param_n)

}

fn ctest_cspan_slice2_run() {
    var __local__c_i4: i32 = ((0 as i32))

    while ((if __local__c_i4 == 0: 1 else: 0) != 0) {
        var __local_stack: Stack = Stack.zeroed()

        while true {
            var __ci_expr_old_0: i32 = __local__c_i4

            (__local__c_i4 = __local__c_i4 + 1)

            if (not ((if __ci_expr_old_0 == 0: 1 else: 0) != 0)) {
                break
            }

            var __local_i: i32 = ((0 as i32))

            var __local__c_end_i: i32 = ((((10 * 20) * 30) as i32))

            while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
                unsafe { Stack_push((&raw mut __local_stack as *mut Stack), __local_i) }

                (__local_i = __local_i + 1)

            }

            var __local_ms3: Span3

            var __ci_expr_lit_1: [i32; 3] = [10, 20, 30]

            var __ci_expr_init_2: cspan_tuple3 = (unsafe *(unsafe { _cspan_shape2stride((0 as i32), (&__ci_expr_lit_1[0] as *mut i32), (3 as i32)) } as *mut cspan_tuple3))

            __local_ms3 = Span3.zeroed()
            __local_ms3.data = (unsafe *(&raw const __local_stack as *const Stack)).data
            __local_ms3.shape = [10, 20, 30]
            __local_ms3.stride = __ci_expr_init_2

            var __ci_expr_lit_3: [i64; 3, 3] = [[1, 4, 0 as i64], [3, 7, 0 as i64], [20, 24, 0 as i64]]

            let __ci_copy_140: Span3 = unsafe { Span3_slice_((*(&raw mut __local_ms3 as *mut Span3)).data, (&(*(&raw mut __local_ms3 as *mut Span3)).shape[0] as *mut i32), (&(*(&raw const (*(&raw mut __local_ms3 as *mut Span3)).stride as *const cspan_tuple3)).d[0] as *mut i32), (&__ci_expr_lit_3[0] as *mut [i64; 3]), (((((&raw mut __local_ms3 as *mut Span3)).shape.len() as u64) as i64) as i32)) }
            with_memcpy((&raw mut __local_ms3 as *mut u8), (&raw const __ci_copy_140 as *const u8), sizeof[Span3]())

            var __local_sum: i32 = ((0 as i32))

            var __local_i_1: i64 = ((0 as i64))

            var __local__c_end_i_1: i64 = (((unsafe *(&raw const __local_ms3 as *const Span3)).shape[0] as i64))

            while ((if __local_i_1 < __local__c_end_i_1: 1 else: 0) != 0) {
                var __local_j: i64 = ((0 as i64))

                var __local__c_end_j: i64 = (((unsafe *(&raw const __local_ms3 as *const Span3)).shape[1] as i64))


                while ((if __local_j < __local__c_end_j: 1 else: 0) != 0) {
                    var __local_k: i64 = ((0 as i64))

                    var __local__c_end_k: i64 = (((unsafe *(&raw const __local_ms3 as *const Span3)).shape[2] as i64))


                    while ((if __local_k < __local__c_end_k: 1 else: 0) != 0) {
                        var __ci_expr_logic_5: i32 = 0

                        var __ci_expr_logic_4: i32 = 0

                        if ((if __local_i_1 < (unsafe *(&raw mut __local_ms3 as *mut Span3)).shape[0]: 1 else: 0) != 0) {
                            (__ci_expr_logic_4 = (if (if __local_j < (unsafe *(&raw mut __local_ms3 as *mut Span3)).shape[1]: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (__ci_expr_logic_4 != 0) {
                            (__ci_expr_logic_5 = (if (if __local_k < (unsafe *(&raw mut __local_ms3 as *mut Span3)).shape[2]: 1 else: 0) != 0: 1 else: 0))
                        }

                        if (((if not (__ci_expr_logic_5 != 0): 1 else: 0) as i64) != 0) {
                            __assert_rtn(c"ctest_cspan_slice2_run".ptr, c"cspan_test.c".ptr, (63 as i32), c"(i) < (&ms3)->shape[0] && (j) < (&ms3)->shape[1] && (k) < (&ms3)->shape[2]".ptr)
                        } else {
                            0
                        }

                        (__local_sum = __local_sum + (unsafe *((*(&raw mut __local_ms3 as *mut Span3)).data + (((((__local_i_1 * (*(&raw const (*(&raw mut __local_ms3 as *mut Span3)).stride as *const cspan_tuple3)).d[0]) + (__local_j * (*(&raw const (*(&raw mut __local_ms3 as *mut Span3)).stride as *const cspan_tuple3)).d[1])) + (__local_k * (*(&raw const (*(&raw mut __local_ms3 as *mut Span3)).stride as *const cspan_tuple3)).d[2])) as i64) as usize))))



                        (__local_k = __local_k + 1)

                    }



                    (__local_j = __local_j + 1)

                }



                (__local_i_1 = __local_i_1 + 1)

            }

            assert_compare((1 as i32), c"==".ptr, (65112 as i64), (__local_sum as i64), c"cspan_test.c".ptr, (67 as i32))

            (__local_sum = ((0 as i32)))

            var __local_i_2: Span3_iter = unsafe { Span3_begin(((&raw mut __local_ms3 as *mut Span3) as *const Span3)) }

            while ((unsafe *(&raw const __local_i_2 as *const Span3_iter)).ref != null) {
                (__local_sum = __local_sum + (unsafe *((*(&raw const __local_i_2 as *const Span3_iter)).ref)))

                unsafe { Span3_next((&raw mut __local_i_2 as *mut Span3_iter)) }

            }

            assert_compare((1 as i32), c"==".ptr, (65112 as i64), (__local_sum as i64), c"cspan_test.c".ptr, (72 as i32))

            unsafe { Stack_drop(((&raw mut __local_stack as *mut Stack) as *const Stack)) }

        }

    }


}

fn ctest_cspan_equality_run() {
    var __local_base: Span = with 0 as __ci_expr_seq_5 {
        var __ci_expr_lit_0: [i32; 30] = [3, 1, 2, 3, 1, 2, 4, 5, 6, 2, 1, 7, 8, 9, 3, 1, 3, 1, 2, 3, 2, 2, 4, 5, 6, 3, 1, 7, 8, 9]
        unsafe { Span_from_n((&__ci_expr_lit_0[0] as *mut i32), (30 as i64)) }
    }

    var __local_base2: Span2 = with 0 as __ci_expr_seq_12 {
        var __ci_expr_lit_1: [i32; 2] = [6, 5]
        var __ci_expr_init_2: cspan_tuple2 = (unsafe *(unsafe { _cspan_shape2stride((0 as i32), (&__ci_expr_lit_1[0] as *mut i32), (2 as i32)) } as *mut cspan_tuple2))
        Span2 { data: (unsafe *(&raw const __local_base as *const Span)).data, shape: [6, 5], stride: __ci_expr_init_2 }
    }

    var __local_test: Span = with 0 as __ci_expr_seq_17 {
        var __ci_expr_lit_3: [i32; 9] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        unsafe { Span_from_n((&__ci_expr_lit_3[0] as *mut i32), (9 as i64)) }
    }

    var __local_test2: Span2 = with 0 as __ci_expr_seq_24 {
        var __ci_expr_lit_4: [i32; 2] = [3, 3]
        var __ci_expr_init_5: cspan_tuple2 = (unsafe *(unsafe { _cspan_shape2stride((0 as i32), (&__ci_expr_lit_4[0] as *mut i32), (2 as i32)) } as *mut cspan_tuple2))
        Span2 { data: (unsafe *(&raw const __local_test as *const Span)).data, shape: [3, 3], stride: __ci_expr_init_5 }
    }

    var __local_y: i64 = ((0 as i64))

    var __local__c_end_y: i64 = (((((unsafe *(&raw const __local_base2 as *const Span2)).shape[0] - 3) + 1) as i64))


    while ((if __local_y < __local__c_end_y: 1 else: 0) != 0) {
        var __local_x: i64 = ((0 as i64))

        var __local__c_end_x: i64 = (((((unsafe *(&raw const __local_base2 as *const Span2)).shape[1] - 3) + 1) as i64))


        while ((if __local_x < __local__c_end_x: 1 else: 0) != 0) {
            var __local_expect_eq: bool = with 0 as __ci_expr_seq_60 {
                var __ci_expr_logic_8: i32
                var __ci_expr_logic_6: i32 = 0
                if ((if __local_y == 0: 1 else: 0) != 0) {
                    (__ci_expr_logic_6 = (if (if __local_x == 1: 1 else: 0) != 0: 1 else: 0))
                }
                if (__ci_expr_logic_6 != 0) {
                    (__ci_expr_logic_8 = (if true: 1 else: 0))
                } else {
                    var __ci_expr_logic_7: i32 = 0
                    if ((if __local_y == 3: 1 else: 0) != 0) {
                        (__ci_expr_logic_7 = (if (if __local_x == 2: 1 else: 0) != 0: 1 else: 0))
                    }
                    (__ci_expr_logic_8 = (if __ci_expr_logic_7 != 0: 1 else: 0))
                }
                (__ci_expr_logic_8 != 0)
            }

            var __ci_expr_lit_9: [i64; 2, 3] = [[__local_y, (__local_y + 3), 0 as i64], [__local_x, (__local_x + 3), 0 as i64]]

            assert_compare((1 as i32), c"==".ptr, (__local_expect_eq as i64), (Span2_equals(__local_test2, unsafe { Span2_slice_((*(&raw mut __local_base2 as *mut Span2)).data, (&(*(&raw mut __local_base2 as *mut Span2)).shape[0] as *mut i32), (&(*(&raw const (*(&raw mut __local_base2 as *mut Span2)).stride as *const cspan_tuple2)).d[0] as *mut i32), (&__ci_expr_lit_9[0] as *mut [i64; 3]), (((((&raw mut __local_base2 as *mut Span2)).shape.len() as u64) as i64) as i32)) }) as i64), c"cspan_test.c".ptr, (101 as i32))



            (__local_x = __local_x + 1)

        }



        (__local_y = __local_y + 1)

    }


    var __ci_expr_lit_10: [i64; 2, 3] = [[0, 3, 0 as i64], [0, 4, 0 as i64]]

    var __ci_expr_lit_11: [i64; 2, 3] = [[3, 6, 0 as i64], [1, 5, 0 as i64]]

    assert_bool((1 as i32), (true as bool), (Span2_equals(unsafe { Span2_slice_((*(&raw mut __local_base2 as *mut Span2)).data, (&(*(&raw mut __local_base2 as *mut Span2)).shape[0] as *mut i32), (&(*(&raw const (*(&raw mut __local_base2 as *mut Span2)).stride as *const cspan_tuple2)).d[0] as *mut i32), (&__ci_expr_lit_10[0] as *mut [i64; 3]), (((((&raw mut __local_base2 as *mut Span2)).shape.len() as u64) as i64) as i32)) }, unsafe { Span2_slice_((*(&raw mut __local_base2 as *mut Span2)).data, (&(*(&raw mut __local_base2 as *mut Span2)).shape[0] as *mut i32), (&(*(&raw const (*(&raw mut __local_base2 as *mut Span2)).stride as *const cspan_tuple2)).d[0] as *mut i32), (&__ci_expr_lit_11[0] as *mut [i64; 3]), (((((&raw mut __local_base2 as *mut Span2)).shape.len() as u64) as i64) as i32)) }) as bool), c"cspan_test.c".ptr, (107 as i32))


}

pub unsafe fn Tiles_move(__param_self_: *mut Tiles) -> Tiles {
    var __local_m: Tiles = (*__param_self_)

    ((*__param_self_).size = ((0 as i64)))

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).data = ((null as *mut Span3)))

    return __local_m

}

pub unsafe fn Tiles_capacity(__param_self_: *const Tiles) -> i64 {
    return (*__param_self_).capacity

}

pub unsafe fn Tiles_reserve(__param_self_: *mut Tiles, __param_cap: i64) -> bool {
    var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (*__param_self_).size else: __param_cap) as i64))

    if ((((if __param_cap > (*__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as i32)) != 0) {
        var __local_d: *mut Span3 = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[Span3]() as i64)) as i64) else: (((*__param_self_).capacity * (sizeof[Span3]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Span3))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((((*__param_self_).data != null)) as bool))

}

pub unsafe fn Tiles_clear(__param_self_: *mut Tiles) {
    var __local_i: i64 = (*__param_self_).size

    while true {
        var __ci_expr_old_0: i64 = __local_i

        (__local_i = __local_i - 1)

        if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
            break
        }

    }

    ((*__param_self_).size = ((0 as i64)))

}

pub unsafe fn Tiles_drop(__param_cself: *const Tiles) {
    var __local_self_: *mut Tiles = ((__param_cself as *mut Tiles))

    Tiles_clear(__local_self_)

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

pub unsafe fn Tiles_take(__param_self_: *mut Tiles, __param_unowned: Tiles) -> Unit {
    Tiles_drop((__param_self_ as *const Tiles))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[Tiles]())

}

pub unsafe fn Tiles_size(__param_self_: *const Tiles) -> i64 {
    return (*__param_self_).size

}

pub unsafe fn Tiles_is_empty(__param_self_: *const Tiles) -> bool {
    return ((((not ((*__param_self_).size != 0))) as bool))

}

pub unsafe fn Tiles_value_drop(__param_self_: *const Tiles, __param_val: *mut Span3) {
    return
}

pub unsafe fn Tiles_append_uninit(__param_self_: *mut Tiles, __param_n: i64) -> *mut Span3 {
    var __local_len: i64 = (*__param_self_).size

    if ((if (__local_len + __param_n) >= Tiles_capacity((__param_self_ as *const Tiles)): 1 else: 0) != 0) {
        if ((if not Tiles_reserve(__param_self_, ((((__local_len * 3) / 2) + __param_n) as i64)): 1 else: 0) != 0) {
            return ((null as *mut Span3))
        }
    }

    ((*__param_self_).size = (*__param_self_).size + __param_n)

    return ((((*__param_self_).data + ((__local_len as i64) as usize)) as *mut Span3))

}

pub unsafe fn Tiles_shrink_to_fit(__param_self_: *mut Tiles) -> Unit {
    Tiles_reserve(__param_self_, (9223372036854775807 as i64))

}

pub unsafe fn Tiles_front(__param_self_: *const Tiles) -> *const Span3 {
    return ((((&raw const ((*__param_self_).data[0]) as *const Span3) as *mut Span3) as *const Span3))

}

pub unsafe fn Tiles_front_mut(__param_self_: *mut Tiles) -> *mut Span3 {
    return (((&raw const ((*__param_self_).data[0]) as *const Span3) as *mut Span3))

}

pub unsafe fn Tiles_back(__param_self_: *const Tiles) -> *const Span3 {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const Span3) as *mut Span3) as *const Span3))

}

pub unsafe fn Tiles_back_mut(__param_self_: *mut Tiles) -> *mut Span3 {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const Span3) as *mut Span3))

}

pub unsafe fn Tiles_top(__param_self_: *const Tiles) -> *const Span3 {
    return ((Tiles_back(__param_self_) as *const Span3))

}

pub unsafe fn Tiles_top_mut(__param_self_: *mut Tiles) -> *mut Span3 {
    return ((Tiles_back_mut(__param_self_) as *mut Span3))

}

pub unsafe fn Tiles_push(__param_self_: *mut Tiles, __param_val: Span3) -> *mut Span3 {
    if ((if (*__param_self_).size == Tiles_capacity((__param_self_ as *const Tiles)): 1 else: 0) != 0) {
        if ((if not Tiles_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 4) as i64)): 1 else: 0) != 0) {
            return ((null as *mut Span3))
        }
    }

    var __local_vp: *mut Span3 = with 0 as __ci_expr_seq_10 {
        var __ci_expr_old_0: i64 = (*__param_self_).size
        ((*__param_self_).size = (*__param_self_).size + 1)
        ((*__param_self_).data + ((__ci_expr_old_0 as i64) as usize))
    }

    with_memcpy((&raw mut (*__local_vp) as *mut u8), (&raw const __param_val as *const u8), sizeof[Span3]())

    return __local_vp

}

pub unsafe fn Tiles_pop(__param_self_: *mut Tiles) {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Tiles_pop".ptr, c"stack.h".ptr, (149 as i32), c"self->size".ptr)
    } else {
        0
    }

    var __local_p: *mut Span3 = with 0 as __ci_expr_seq_8 {
        ((*__param_self_).size = (*__param_self_).size - 1)
        ((&raw const ((*__param_self_).data[(*__param_self_).size]) as *const Span3) as *mut Span3)
    }


}

pub unsafe fn Tiles_pull(__param_self_: *mut Tiles) -> Span3 {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Tiles_pull".ptr, c"stack.h".ptr, (152 as i32), c"self->size".ptr)
    } else {
        0
    }

    ((*__param_self_).size = (*__param_self_).size - 1)

    return ((*__param_self_).data[(*__param_self_).size])


}

pub unsafe fn Tiles_put_n(__param_self_: *mut Tiles, __param_raw: *const Span3, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        Tiles_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn Tiles_init() -> Tiles {
    var __local_out: Tiles = Tiles.zeroed()

    return __local_out

}

pub fn Tiles_with_capacity(__param_cap: i64) -> Tiles {
    var __local_out: Tiles = Tiles { data: (((with_alloc((((if 1 != 0: ((__param_cap * (sizeof[Span3]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Span3)), size: 0, capacity: __param_cap }

    return __local_out

}

pub fn Tiles_with_size_uninit(__param_size: i64) -> Tiles {
    var __local_out: Tiles = Tiles { data: (((with_alloc((((if 1 != 0: ((__param_size * (sizeof[Span3]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Span3)), size: __param_size, capacity: __param_size }

    return __local_out

}

pub fn Tiles_with_size(__param_size: i64, __param_default_raw: Span3) -> Tiles {
    var __local_size = __param_size
    var __local_out: Tiles = Tiles { data: (((with_alloc((((if 1 != 0: ((__local_size * (sizeof[Span3]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut Span3)), size: __local_size, capacity: __local_size }

    while (__local_size != 0) {
        (__local_size = __local_size - 1)

        ((unsafe __local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

pub unsafe fn Tiles_from_n(__param_raw: *const Span3, __param_n: i64) -> Tiles {
    var __local_out: Tiles = Tiles_with_capacity(__param_n)

    Tiles_put_n((&raw mut __local_out as *mut Tiles), __param_raw, __param_n)

    return __local_out

}

pub unsafe fn Tiles_at(__param_self_: *const Tiles, __param_idx: i64) -> *const Span3 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Tiles_at".ptr, c"stack.h".ptr, (189 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *const Span3))

}

pub unsafe fn Tiles_at_mut(__param_self_: *mut Tiles, __param_idx: i64) -> *mut Span3 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"Tiles_at_mut".ptr, c"stack.h".ptr, (192 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *mut Span3))

}

pub fn Tiles_clone(__param_stk: Tiles) -> Tiles {
    var __local_out: Tiles = __param_stk

    var __local_self_: *mut Tiles = ((&raw mut __local_out as *mut Tiles))



    (__local_out.data = ((null as *mut Span3)))

    (__local_out.capacity = ((0 as i64)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const Tiles)).capacity)


    unsafe { Tiles_reserve((&raw mut __local_out as *mut Tiles), (*(&raw const __param_stk as *const Tiles)).size) }

    (__local_out.size = (unsafe *(&raw const __param_stk as *const Tiles)).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (unsafe *(&raw const __param_stk as *const Tiles)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (unsafe (*(&raw const __param_stk as *const Tiles)).data[__local_i]))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

pub unsafe fn Tiles_copy(__param_self_: *mut Tiles, __param_other: *const Tiles) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    Tiles_clear(__param_self_)

    Tiles_reserve(__param_self_, (*__param_other).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (*__param_self_).size

        ((*__param_self_).size = (*__param_self_).size + 1)

        (((*__param_self_).data[__ci_expr_old_0]) = ((*__param_other).data[__local_i]))


        (__local_i = __local_i + 1)

    }


}

pub unsafe fn Tiles_value_clone(__param_self_: *const Tiles, __param_val: Span3) -> Span3 {

    return __param_val

}

pub unsafe fn Tiles_value_toraw(__param_val: *const Span3) -> Span3 {
    return (*__param_val)

}

pub unsafe fn Tiles_begin(__param_self_: *const Tiles) -> Tiles_iter {
    var __local_it_: Tiles_iter = Tiles_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.end = (*(&raw const __local_it_ as *const Tiles_iter)).end + (((*__param_self_).size as i64) as usize))
    } else {
        (__local_it_.ref = ((null as *mut Span3)))
    }

    return __local_it_

}

pub unsafe fn Tiles_rbegin(__param_self_: *const Tiles) -> Tiles_iter {
    var __local_it_: Tiles_iter = Tiles_iter { ref: (*__param_self_).data, end: (*__param_self_).data }

    if ((*__param_self_).size != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const Tiles_iter)).ref + ((((*__param_self_).size - 1) as i64) as usize))

        (__local_it_.end = (*(&raw const __local_it_ as *const Tiles_iter)).end - ((1 as i64) as usize))

    } else {
        (__local_it_.ref = ((null as *mut Span3)))
    }

    return __local_it_

}

pub unsafe fn Tiles_end(__param_self_: *const Tiles) -> Tiles_iter {

    var __local_it_: Tiles_iter = Tiles_iter.zeroed()

    return __local_it_

}

pub unsafe fn Tiles_rend(__param_self_: *const Tiles) -> Tiles_iter {

    var __local_it_: Tiles_iter = Tiles_iter.zeroed()

    return __local_it_

}

pub unsafe fn Tiles_next(__param_it_: *mut Tiles_iter) {
    ((*__param_it_).ref = (*__param_it_).ref + 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut Span3)))
    }


}

pub unsafe fn Tiles_rnext(__param_it_: *mut Tiles_iter) {
    ((*__param_it_).ref = (*__param_it_).ref - 1)

    if ((if (*__param_it_).ref == (*__param_it_).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut Span3)))
    }


}

pub fn Tiles_advance(__param_it_: Tiles_iter, __param_n: u64) -> Tiles_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const Tiles_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const Tiles_iter)).ref >= (unsafe *(&raw const __param_it_ as *const Tiles_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut Span3)))
    }


    return __param_it_

}

pub unsafe fn Tiles_index(__param_self_: *const Tiles, __param_it_: Tiles_iter) -> i64 {
    return (((((*(&raw const __param_it_ as *const Tiles_iter)).ref as usize) -% ((*__param_self_).data as usize)) as i64) / (sizeof[Span3]() as i64))

}

pub unsafe fn Tiles_adjust_end_(__param_self_: *mut Tiles, __param_n: i64) {
    ((*__param_self_).size = (*__param_self_).size + __param_n)

}

unsafe fn ctest_cspan_cube_setup(__param_fixt: *mut ctest_cspan_cube_data) {
    let TSIZE: i32 = 4

    let CUBE: i32 = 64

    let N: i32 = 262144


    let __ci_copy_7: Stack = Stack_init()
    with_memcpy((&raw mut (*__param_fixt).stack as *mut u8), (&raw const __ci_copy_7 as *const u8), sizeof[Stack]())

    let __ci_copy_11: Tiles = Tiles_init()
    with_memcpy((&raw mut (*__param_fixt).tiles as *mut u8), (&raw const __ci_copy_11 as *const u8), sizeof[Tiles]())

    Stack_reserve(((&raw const (*__param_fixt).stack as *const Stack) as *mut Stack), (262144 as i64))

    var __local_i: i32 = ((0 as i32))

    var __local__c_end_i: i32 = N


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        Stack_push(((&raw const (*__param_fixt).stack as *const Stack) as *mut Stack), ((__local_i + 1) as i32))

        (__local_i = __local_i + 1)

    }


    var __local_ms3: Span3 = with 0 as __ci_expr_seq_22 {
        var __ci_expr_lit_0: [i32; 3] = [CUBE, CUBE, CUBE]
        var __ci_expr_init_1: cspan_tuple3 = (*(_cspan_shape2stride((0 as i32), (&__ci_expr_lit_0[0] as *mut i32), (3 as i32)) as *mut cspan_tuple3))
        Span3 { data: (*(&raw const (*__param_fixt).stack as *const Stack)).data, shape: [CUBE, CUBE, CUBE], stride: __ci_expr_init_1 }
    }

    var __local_i_1: i64 = ((0 as i64))

    var __local__c_inc_i: i64 = ((4 as i64))

    var __local__c_end_i_1: i64 = ((((*(&raw const __local_ms3 as *const Span3)).shape[0] - (if __local__c_inc_i > 0: 1 else: 0)) as i64))


    while ((if (if __local__c_inc_i > 0: 1 else: 0) == (if __local_i_1 <= __local__c_end_i_1: 1 else: 0): 1 else: 0) != 0) {
        var __local_j: i64 = ((0 as i64))

        var __local__c_inc_j: i64 = ((4 as i64))

        var __local__c_end_j: i64 = ((((*(&raw const __local_ms3 as *const Span3)).shape[1] - (if __local__c_inc_j > 0: 1 else: 0)) as i64))


        while ((if (if __local__c_inc_j > 0: 1 else: 0) == (if __local_j <= __local__c_end_j: 1 else: 0): 1 else: 0) != 0) {
            var __local_k: i64 = ((0 as i64))

            var __local__c_inc_k: i64 = ((4 as i64))

            var __local__c_end_k: i64 = ((((*(&raw const __local_ms3 as *const Span3)).shape[2] - (if __local__c_inc_k > 0: 1 else: 0)) as i64))


            while ((if (if __local__c_inc_k > 0: 1 else: 0) == (if __local_k <= __local__c_end_k: 1 else: 0): 1 else: 0) != 0) {
                var __local_tile: Span3 = with 0 as __ci_expr_seq_44 {
                    var __ci_expr_lit_2: [i64; 3, 3] = [[__local_i_1, (__local_i_1 + 4), 0 as i64], [__local_j, (__local_j + 4), 0 as i64], [__local_k, (__local_k + 4), 0 as i64]]
                    Span3_slice_((*(&raw mut __local_ms3 as *mut Span3)).data, (&(*(&raw mut __local_ms3 as *mut Span3)).shape[0] as *mut i32), (&(*(&raw const (*(&raw mut __local_ms3 as *mut Span3)).stride as *const cspan_tuple3)).d[0] as *mut i32), (&__ci_expr_lit_2[0] as *mut [i64; 3]), (((((&raw mut __local_ms3 as *mut Span3)).shape.len() as u64) as i64) as i32))
                }

                Tiles_push(((&raw const (*__param_fixt).tiles as *const Tiles) as *mut Tiles), __local_tile)


                (__local_k = __local_k + __local__c_inc_k)

            }



            (__local_j = __local_j + __local__c_inc_j)

        }



        (__local_i_1 = __local_i_1 + __local__c_inc_i)

    }


}

unsafe fn ctest_cspan_cube_teardown(__param_fixt: *mut ctest_cspan_cube_data) {
    Stack_drop((((&raw const (*__param_fixt).stack as *const Stack) as *mut Stack) as *const Stack))

    Tiles_drop((((&raw const (*__param_fixt).tiles as *const Tiles) as *mut Tiles) as *const Tiles))

}

unsafe fn ctest_cspan_cube_slice3_run(__param_fixt: *mut ctest_cspan_cube_data) {
    var __local_n: i64 = ((Stack_size((((&raw const (*__param_fixt).stack as *const Stack) as *mut Stack) as *const Stack)) as i64))

    var __local_sum: i64 = ((0 as i64))

    var __local_tile: Tiles_iter = Tiles_begin((((&raw const (*__param_fixt).tiles as *const Tiles) as *mut Tiles) as *const Tiles))

    while ((*(&raw const __local_tile as *const Tiles_iter)).ref != null) {
        var __local_i: Span3_iter = Span3_begin((((&raw const (*((*(&raw const __local_tile as *const Tiles_iter)).ref)) as *const Span3) as *mut Span3) as *const Span3))

        while ((*(&raw const __local_i as *const Span3_iter)).ref != null) {
            (__local_sum = __local_sum + (*((*(&raw const __local_i as *const Span3_iter)).ref)))

            Span3_next((&raw mut __local_i as *mut Span3_iter))

        }


        Tiles_next((&raw mut __local_tile as *mut Tiles_iter))

    }


    assert_compare((1 as i32), c"==".ptr, __local_sum, (((__local_n * (__local_n + 1)) / 2) as i64), c"cspan_test.c".ptr, (157 as i32))

}

var ctest_cspan_subdim: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("cspan" as *mut c_char) as *const c_char), ttname: (("subdim" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_cspan_subdim_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_cspan_slice: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("cspan" as *mut c_char) as *const c_char), ttname: (("slice" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_cspan_slice_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_cspan_slice2: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("cspan" as *mut c_char) as *const c_char), ttname: (("slice2" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_cspan_slice2_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_cspan_equality: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("cspan" as *mut c_char) as *const c_char), ttname: (("equality" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some(ctest_cspan_equality_run) }, data: (null), setup: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: ((null) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }
var ctest_cspan_cube_setup_ptr: Option[unsafe extern "C" fn(*mut ctest_cspan_cube_data) -> Unit] = Some(ctest_cspan_cube_setup)
var ctest_cspan_cube_teardown_ptr: Option[unsafe extern "C" fn(*mut ctest_cspan_cube_data) -> Unit] = Some(ctest_cspan_cube_teardown)
var ctest_cspan_cube_slice3_data: ctest_cspan_cube_data
var ctest_cspan_cube_slice3: ctest = ctest { magic0: 3135025120, padding: 0, ssname: (("cspan_cube" as *mut c_char) as *const c_char), ttname: (("slice3" as *mut c_char) as *const c_char), run: ctest_run_func_union { nullary: Some((ctest_cspan_cube_slice3_run as extern "C" fn() -> Unit)) }, data: ((&raw mut ctest_cspan_cube_slice3_data as *mut ctest_cspan_cube_data) as *mut c_void), setup: (((&raw const ctest_cspan_cube_setup_ptr as *const unsafe extern "C" fn(*mut ctest_cspan_cube_data) -> Unit) as *mut unsafe extern "C" fn(*mut ctest_cspan_cube_data) -> Unit) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), teardown: (((&raw const ctest_cspan_cube_teardown_ptr as *const unsafe extern "C" fn(*mut ctest_cspan_cube_data) -> Unit) as *mut unsafe extern "C" fn(*mut ctest_cspan_cube_data) -> Unit) as *mut unsafe extern "C" fn(*mut c_void) -> Unit), skip: 0, magic1: 3135025121 }

// The runner (build/stc.w): every registered test, in order.
pub fn main() -> c_int:
    ctest_cspan_subdim_run()
    print("ran cspan.subdim")
    ctest_cspan_slice_run()
    print("ran cspan.slice")
    ctest_cspan_slice2_run()
    print("ran cspan.slice2")
    ctest_cspan_equality_run()
    print("ran cspan.equality")
    unsafe { ctest_cspan_cube_setup((&raw mut ctest_cspan_cube_slice3_data as *mut ctest_cspan_cube_data)) }
    unsafe { ctest_cspan_cube_slice3_run((&raw mut ctest_cspan_cube_slice3_data as *mut ctest_cspan_cube_data)) }
    unsafe { ctest_cspan_cube_teardown((&raw mut ctest_cspan_cube_slice3_data as *mut ctest_cspan_cube_data)) }
    print("ran cspan_cube.slice3")
    return ctest_failure_count()
