// Migrated from C
use std.stc.defs
use std.libc
use std.collections

unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: c_long) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as c_ulong) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

unsafe fn c_basehash_n(__param_key: *const c_void, __param_len: c_long) -> c_ulong {
    var __local_len = __param_len
    var __local_msg: *const u8 = ((__param_key as *const u8))

    var __local_h: c_ulong = ((((0 as c_ulong) -% 3750763034362895579) as c_ulong))

    var __local_block: c_ulong = ((0 as c_ulong))


    while ((if __local_len >= ((sizeof[c_ulong]() as c_long)): 1 else: 0) != 0) {
        with_memcpy((((&raw mut __local_block as *mut c_ulong) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[c_ulong]() as c_ulong) as i64))

        (__local_h = (__local_h as c_ulong) ^ (__local_block as c_ulong))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[c_ulong]() as c_long) as usize))

        (__local_len = __local_len - (sizeof[c_ulong]() as c_long))

    }

    while true {
        var __ci_expr_old_0: c_long = __local_len

        (__local_len = __local_len - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        var __ci_expr_old_1: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as c_ulong) ^ ((*__ci_expr_old_1) as c_ulong))

        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_n(__param_key: *const c_void, __param_len: c_long) -> c_ulong {
    var __local_b8: c_ulonglong

    var __local_b4: c_uint

    match __param_len {
        8 => {
            with_memcpy((((&raw mut __local_b8 as *mut c_ulonglong) as *mut c_void) as *mut u8), (__param_key as *const u8), ((8 as c_ulong) as i64))

            return ((((__local_b8 as c_ulonglong) *% (((0 as c_ulonglong) -% 4132994306676758115) as c_ulonglong)) as c_ulong))

        },
        4 => {
            with_memcpy((((&raw mut __local_b4 as *mut c_uint) as *mut c_void) as *mut u8), (__param_key as *const u8), ((4 as c_ulong) as i64))

            return ((__local_b4 as c_ulong) *% (((0 as c_ulong) -% 3750763034362895579) as c_ulong))

        },
        _ => {
            return c_basehash_n(__param_key, __param_len)
        },
    }

}

unsafe fn c_hash_str(__param_str_: *const i8) -> c_ulong {
    var __local_msg: *const u8 = ((__param_str_ as *const u8))

    var __local_h: c_ulong = ((((0 as c_ulong) -% 3750763034362895579) as c_ulong))

    while ((*__local_msg) != 0) {
        var __ci_expr_old_0: *const u8 = __local_msg

        (__local_msg = __local_msg + 1)

        (__local_h = (__local_h as c_ulong) ^ ((*__ci_expr_old_0) as c_ulong))


        (__local_h = (__local_h *% 1099511628211))

    }

    return __local_h

}

unsafe fn c_hash_mix_n(__param_h: *mut c_ulong, __param_n: c_long) -> c_ulong {
    var __local_i: c_long = ((1 as c_long))

    while ((if __local_i < __param_n: 1 else: 0) != 0) {
        ((__param_h[0]) = ((__param_h[0]) +% (((__param_h[0]) as c_ulong) ^ ((__param_h[__local_i]) as c_ulong))))

        (__local_i = __local_i + 1)

    }


    return (__param_h[0])

}

fn c_next_pow2(__param_n: c_long) -> c_long {
    var __local_n = __param_n
    (__local_n = __local_n - 1)

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (1 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (2 as c_uint)) as c_long))


    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (4 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (8 as c_uint)) as c_long))


    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (16 as c_uint)) as c_long))

    (__local_n = (__local_n as c_long) | (((__local_n as c_long) >> (32 as c_uint)) as c_long))

    return (__local_n + 1)

}

unsafe fn c_strnstrn(__param_str_: *const i8, __param_slen: c_long, __param_needle: *const i8, __param_nlen: c_long) -> *mut i8 {
    var __local_str_ = __param_str_
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return (((__local_str_ as *mut c_char) as *mut i8))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut i8))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: c_int = 0

        if ((if (*__local_str_) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str_ as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return (((__local_str_ as *mut c_char) as *mut i8))
        }


        (__local_str_ = __local_str_ + 1)

        var __ci_expr_old_0: c_long = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut i8))

}

pub unsafe fn _cspan_size(__param_shape: *mut c_int, __param_rank: c_int) -> c_long {
    var __local_rank = __param_rank
    var __local_size: c_long = (((__param_shape[0]) as c_long))

    while true {
        (__local_rank = __local_rank - 1)

        if (not (__local_rank != 0)) {
            break
        }

        (__local_size = __local_size * (__param_shape[__local_rank]))

    }

    return __local_size

}

pub unsafe fn _cspan_swap_axes(__param_shape: *mut c_int, __param_stride: *mut c_int, __param_rank: c_int, __param_ax1: c_int, __param_ax2: c_int) {

    if (((if not ((((if ((__param_ax1 as c_ulong)) < ((__param_rank as c_ulong)): 1 else: 0) as c_int) & ((if ((__param_ax2 as c_ulong)) < ((__param_rank as c_ulong)): 1 else: 0) as c_int)) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"_cspan_swap_axes".ptr, c"cspan.h".ptr, (347 as c_int), c"((size_t)(ax1) < (size_t)(rank)) & ((size_t)(ax2) < (size_t)(rank))".ptr)
    } else {
        0
    }

    loop {
        var __local__xp: *mut c_int = ((&(__param_shape[0]) as *mut c_int) + ((__param_ax1 as c_long) as usize))

        var __local__yp: *mut c_int = ((&(__param_shape[0]) as *mut c_int) + ((__param_ax2 as c_long) as usize))


        var __local__tv: c_int = (((*__local__xp) as c_int))

        ((*__local__xp) = (((*__local__yp) as c_int)))

        ((*__local__yp) = __local__tv)

        if not ((0 != 0)) {
            break
        }
    }

    loop {
        var __local__xp_1: *mut c_int = ((&(__param_stride[0]) as *mut c_int) + ((__param_ax1 as c_long) as usize))

        var __local__yp_1: *mut c_int = ((&(__param_stride[0]) as *mut c_int) + ((__param_ax2 as c_long) as usize))


        var __local__tv_1: c_int = (((*__local__xp_1) as c_int))

        ((*__local__xp_1) = (((*__local__yp_1) as c_int)))

        ((*__local__yp_1) = __local__tv_1)

        if not ((0 != 0)) {
            break
        }
    }

}

pub unsafe fn _cspan_transpose(__param_shape: *mut c_int, __param_stride: *mut c_int, __param_rank: c_int) {
    var __local_rank = __param_rank
    var __local_i: c_int = ((0 as c_int))

    while true {
        (__local_rank = __local_rank - 1)

        if (not ((if __local_i < __local_rank: 1 else: 0) != 0)) {
            break
        }

        loop {
            var __local__xp: *mut c_int = ((&(__param_shape[0]) as *mut c_int) + ((__local_i as c_long) as usize))

            var __local__yp: *mut c_int = ((&(__param_shape[0]) as *mut c_int) + ((__local_rank as c_long) as usize))


            var __local__tv: c_int = (((*__local__xp) as c_int))

            ((*__local__xp) = (((*__local__yp) as c_int)))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            var __local__xp_1: *mut c_int = ((&(__param_stride[0]) as *mut c_int) + ((__local_i as c_long) as usize))

            var __local__yp_1: *mut c_int = ((&(__param_stride[0]) as *mut c_int) + ((__local_rank as c_long) as usize))


            var __local__tv_1: c_int = (((*__local__xp_1) as c_int))

            ((*__local__xp_1) = (((*__local__yp_1) as c_int)))

            ((*__local__yp_1) = __local__tv_1)

            if not ((0 != 0)) {
                break
            }
        }

        (__local_i = __local_i + 1)

    }


}

pub unsafe fn _cspan_index(__param_shape: *mut c_int, __param_stride: *mut c_int, __param_args: *mut c_long, __param_rank: c_int) -> c_long {
    var __local_rank = __param_rank
    var __local_off: c_long = ((0 as c_long))


    while true {
        var __ci_expr_old_0: c_int = __local_rank

        (__local_rank = __local_rank - 1)

        if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
            break
        }

        if (((if not ((if (__param_args[__local_rank]) < (__param_shape[__local_rank]): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"_cspan_index".ptr, c"cspan.h".ptr, (364 as c_int), c"args[rank] < shape[rank]".ptr)
        } else {
            0
        }

        (__local_off = __local_off + ((__param_args[__local_rank]) * (__param_stride[__local_rank])))

    }

    return __local_off

}

pub unsafe fn _cspan_print_assist(__param_pos: *mut c_int, __param_shape: *mut c_int, __param_rank: c_int, __param_brackets: *const i8, __param_result: *mut [c_char; 20]) {
    var __local_n: c_int = ((0 as c_int))

    var __local_j: c_int = ((0 as c_int))

    var __local_r: c_int = (((__param_rank - 1) as c_int))


    with_memset(((&(__param_result[0]) as *mut [c_char; 20]) as *mut u8), (0 as c_int), ((32 as c_ulong) as i64))

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_n <= __local_r: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (__param_pos[(__local_r - __local_n)]) == 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        (__local_n = __local_n + 1)

    }

    if (__local_n != 0) {
        while ((if __local_j < __param_rank: 1 else: 0) != 0) {
            ((__param_result[0])[__local_j] = (((if (if __local_j < (__param_rank - __local_n): 1 else: 0) != 0: (32 as c_int) else: ((__param_brackets[0]) as c_int)) as c_char)))

            (__local_j = __local_j + 1)

        }
    }

    (__local_j = ((0 as c_int)))

    while true {
        var __ci_expr_logic_1: c_int = 0

        if ((if __local_r >= 0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if ((__param_pos[__local_r]) + 1) == (__param_shape[__local_r]): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        ((__param_result[1])[__local_j] = (((__param_brackets[1]) as c_char)))

        (__local_r = __local_r - 1)

        (__local_j = __local_j + 1)

    }


    (__local_n = ((((if __local_j > 0: 1 else: 0) + (((if __local_j > 1: 1 else: 0) as c_int) & ((if __local_j < __param_rank: 1 else: 0) as c_int))) as c_int)))

    var __ci_expr_logic_2: c_int = 0

    if ((__param_brackets[2]) != 0) {
        (__ci_expr_logic_2 = (if (if __local_j < __param_rank: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        var __ci_expr_old_3: c_int = __local_j

        (__local_j = __local_j + 1)

        ((__param_result[1])[__ci_expr_old_3] = (((__param_brackets[2]) as c_char)))

    }


    while true {
        var __ci_expr_old_4: c_int = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_4 != 0)) {
            break
        }

        var __ci_expr_old_5: c_int = __local_j

        (__local_j = __local_j + 1)

        ((__param_result[1])[__ci_expr_old_5] = ((10 as c_char)))

    }

}

pub unsafe fn _cspan_nextN(__param_pos: *mut c_int, __param_shape: *mut c_int, __param_stride: *mut c_int, __param_rank: c_int, __param_off: *mut c_long) -> bool {
    var __local_rank = __param_rank
    (__local_rank = __local_rank - 1)

    ((__param_pos[__local_rank]) = (__param_pos[__local_rank]) + 1)


    while true {
        var __ci_expr_logic_0: c_int = 0

        if (__local_rank != 0) {
            (__ci_expr_logic_0 = (if (if (__param_pos[__local_rank]) == (__param_shape[__local_rank]): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        ((__param_pos[__local_rank]) = ((0 as c_int)))

        ((__param_pos[(__local_rank - 1)]) = (__param_pos[(__local_rank - 1)]) + 1)

        ((*__param_off) = (*__param_off) + ((__param_stride[(__local_rank - 1)]) - (((__param_shape[__local_rank]) as c_long) * (__param_stride[__local_rank]))))

        (__local_rank = __local_rank - 1)

    }

    return (((__param_pos[__local_rank]) == (__param_shape[__local_rank])))

}

pub unsafe fn _cspan_slice(__param_oshape: *mut c_int, __param_ostride: *mut c_int, __param_orank: *mut c_int, __param_shape: *mut c_int, __param_stride: *mut c_int, __param_args: *mut [c_long; 3], __param_rank: c_int) -> c_long {
    var __local_end: c_long

    var __local_off: c_long = ((0 as c_long))


    var __local_i: c_int = ((0 as c_int))

    var __local_oi: c_int = ((0 as c_int))


    while ((if __local_i < __param_rank: 1 else: 0) != 0) {
        (__local_off = __local_off + ((__param_args[__local_i])[0] * (__param_stride[__local_i])))

        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match (__param_args[__local_i])[1] {
                0 => {
                    if (((if not ((if (((__param_args[__local_i])[0] as c_ulong)) < (((__param_shape[__local_i]) as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
                        __assert_rtn(c"_cspan_slice".ptr, c"cspan.h".ptr, (464 as c_int), c"((size_t)(args[i][0]) < (size_t)(shape[i]))".ptr)
                    }

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2147483647 => {
                    (__local_end = (((__param_shape[__local_i]) as c_long)))
                },
                _ => {
                    (__local_end = (((__param_args[__local_i])[1] as c_long)))
                },
            }

            break

        }

        if (__ci_expr_switch_continue_0 != 0) {
            (__local_i = __local_i + 1)

            continue

        }


        ((__param_oshape[__local_oi]) = (((__local_end - (__param_args[__local_i])[0]) as c_int)))

        ((__param_ostride[__local_oi]) = (((__param_stride[__local_i]) as c_int)))

        if (((if not ((((if (__param_oshape[__local_oi]) > 0: 1 else: 0) as c_int) & ((if not ((if (((__param_shape[__local_i]) as c_ulong)) < ((__local_end as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_int)) != 0): 1 else: 0) as c_long) != 0) {
            __assert_rtn(c"_cspan_slice".ptr, c"cspan.h".ptr, (470 as c_int), c"(oshape[oi] > 0) & !((size_t)(shape[i]) < (size_t)(end))".ptr)
        } else {
            0
        }

        if ((if (__param_args[__local_i])[2] > 0: 1 else: 0) != 0) {
            ((__param_ostride[__local_oi]) = (__param_ostride[__local_oi]) * ((__param_args[__local_i])[2] as c_int))

            ((__param_oshape[__local_oi]) = ((((((__param_oshape[__local_oi]) - 1) / ((__param_args[__local_i])[2] as c_int)) + 1) as c_int)))

        }

        (__local_oi = __local_oi + 1)


        (__local_i = __local_i + 1)

    }

    ((*__param_orank) = __local_oi)

    return __local_off

}

pub unsafe fn _cspan_shape2stride(__param_layout: i32, __param_shpstri: *mut c_int, __param_rank: c_int) -> *mut c_int {
    var __local_rank = __param_rank
    var __local_i: c_int

    var __local_inc: c_int


    if ((if __param_layout == 1: 1 else: 0) != 0) {
        (__local_i = ((0 as c_int)))

        (__local_inc = ((1 as c_int)))

    } else {
        (__local_i = (((__local_rank - 1) as c_int)))

        (__local_inc = ((-1 as c_int)))

    }

    var __local_k: c_int = ((1 as c_int))

    var __local_s1: c_int = (((__param_shpstri[__local_i]) as c_int))

    var __local_s2: c_int


    ((__param_shpstri[__local_i]) = ((1 as c_int)))

    while true {
        (__local_rank = __local_rank - 1)

        if (not (__local_rank != 0)) {
            break
        }

        (__local_i = __local_i + __local_inc)

        (__local_s2 = (((__param_shpstri[__local_i]) as c_int)))

        (__local_k = __local_k * __local_s1)

        ((__param_shpstri[__local_i]) = __local_k)

        (__local_s1 = __local_s2)

    }

    return (&(__param_shpstri[0]) as *mut c_int)

}

pub unsafe fn _cspan_is_layout(__param_layout: i32, __param_shape: *mut c_int, __param_strides: *mut c_int, __param_rank: c_int) -> bool {
    var __local_tmpshape: List[c_int] = [0; 16]

    var __local_sz: c_ulong = ((((__param_rank as c_ulong) *% (sizeof[c_int]() as c_ulong)) as c_ulong))

    with_memcpy(((&__local_tmpshape[0] as *mut c_int) as *mut u8), ((&(__param_shape[0]) as *mut c_int) as *const u8), (__local_sz as i64))

    return ((with_memcmp(((&(__param_strides[0]) as *mut c_int) as *const u8), ((_cspan_shape2stride(__param_layout, (&__local_tmpshape[0] as *mut c_int), __param_rank) as *const c_void) as *const u8), (__local_sz as i64)) == 0))

}
