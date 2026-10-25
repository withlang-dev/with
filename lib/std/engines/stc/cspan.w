// Migrated from C
use std.engines.stc.defs
use std.libc
use std.collections

// contract: unproved:0:read only,unproved:1:read only
unsafe fn c_safe_memcpy(__param_dst: *mut c_void, __param_src: *const c_void, __param_size: i64) -> *mut c_void {
    return (((if __param_dst != null: with_memcpy((__param_dst as *mut u8), (__param_src as *const u8), ((__param_size as u64) as i64)) else: (null as *mut c_void)) as *mut c_void))

}

// contract: unproved:0:read only
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

// contract: unproved:0:read only
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

// contract: unproved:0:read only
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

// contract: unproved:0:out-parameter read before the write
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

// contract: unproved:0:read only,unproved:2:read only
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

// contract: unproved:0:read only
pub unsafe fn _cspan_size(__param_shape: *mut i32, __param_rank: i32) -> i64 {
    var __local_rank = __param_rank
    var __local_size: i64 = (((__param_shape[0]) as i64))

    while true {
        (__local_rank = __local_rank - 1)

        if (not (__local_rank != 0)) {
            break
        }

        (__local_size = __local_size * (__param_shape[__local_rank]))

    }

    return __local_size

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn _cspan_swap_axes(__param_shape: *mut i32, __param_stride: *mut i32, __param_rank: i32, __param_ax1: i32, __param_ax2: i32) {

    if (((if not ((((if ((__param_ax1 as u64)) < ((__param_rank as u64)): 1 else: 0) as i32) & ((if ((__param_ax2 as u64)) < ((__param_rank as u64)): 1 else: 0) as i32)) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"_cspan_swap_axes".ptr, c"cspan.h".ptr, (347 as i32), c"((size_t)(ax1) < (size_t)(rank)) & ((size_t)(ax2) < (size_t)(rank))".ptr)
    } else {
        0
    }

    loop {
        var __local__xp: *mut i32 = ((&raw const ((&(__param_shape[0]) as *mut i32) + ((__param_ax1 as i64) as usize))[0] as *mut i32))

        var __local__yp: *mut i32 = ((&raw const ((&(__param_shape[0]) as *mut i32) + ((__param_ax2 as i64) as usize))[0] as *mut i32))


        var __local__tv: i32 = (*__local__xp)

        ((*__local__xp) = (*__local__yp))

        ((*__local__yp) = __local__tv)

        if not ((0 != 0)) {
            break
        }
    }

    loop {
        var __local__xp_1: *mut i32 = ((&raw const ((&(__param_stride[0]) as *mut i32) + ((__param_ax1 as i64) as usize))[0] as *mut i32))

        var __local__yp_1: *mut i32 = ((&raw const ((&(__param_stride[0]) as *mut i32) + ((__param_ax2 as i64) as usize))[0] as *mut i32))


        var __local__tv_1: i32 = (*__local__xp_1)

        ((*__local__xp_1) = (*__local__yp_1))

        ((*__local__yp_1) = __local__tv_1)

        if not ((0 != 0)) {
            break
        }
    }

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn _cspan_transpose(__param_shape: *mut i32, __param_stride: *mut i32, __param_rank: i32) {
    var __local_rank = __param_rank
    var __local_i: i32 = ((0 as i32))

    while true {
        (__local_rank = __local_rank - 1)

        if (not ((if __local_i < __local_rank: 1 else: 0) != 0)) {
            break
        }

        loop {
            var __local__xp: *mut i32 = ((&raw const ((&(__param_shape[0]) as *mut i32) + ((__local_i as i64) as usize))[0] as *mut i32))

            var __local__yp: *mut i32 = ((&raw const ((&(__param_shape[0]) as *mut i32) + ((__local_rank as i64) as usize))[0] as *mut i32))


            var __local__tv: i32 = (*__local__xp)

            ((*__local__xp) = (*__local__yp))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

        loop {
            var __local__xp_1: *mut i32 = ((&raw const ((&(__param_stride[0]) as *mut i32) + ((__local_i as i64) as usize))[0] as *mut i32))

            var __local__yp_1: *mut i32 = ((&raw const ((&(__param_stride[0]) as *mut i32) + ((__local_rank as i64) as usize))[0] as *mut i32))


            var __local__tv_1: i32 = (*__local__xp_1)

            ((*__local__xp_1) = (*__local__yp_1))

            ((*__local__yp_1) = __local__tv_1)

            if not ((0 != 0)) {
                break
            }
        }

        (__local_i = __local_i + 1)

    }


}

// contract: unproved:0:read only,unproved:1:read only,unproved:2:read only
pub unsafe fn _cspan_index(__param_shape: *mut i32, __param_stride: *mut i32, __param_args: *mut i64, __param_rank: i32) -> i64 {
    var __local_rank = __param_rank
    var __local_off: i64 = ((0 as i64))


    while true {
        var __ci_expr_old_0: i32 = __local_rank

        (__local_rank = __local_rank - 1)

        if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
            break
        }

        if (((if not ((if (__param_args[__local_rank]) < (__param_shape[__local_rank]): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"_cspan_index".ptr, c"cspan.h".ptr, (364 as i32), c"args[rank] < shape[rank]".ptr)
        } else {
            0
        }

        (__local_off = __local_off + ((__param_args[__local_rank]) * (__param_stride[__local_rank])))

    }

    return __local_off

}

// contract: unproved:0:read only,unproved:1:read only,unproved:3:read only,unproved:4:out-parameter read before the write
pub unsafe fn _cspan_print_assist(__param_pos: *mut i32, __param_shape: *mut i32, __param_rank: i32, __param_brackets: *const c_char, __param_result: *mut [c_char; 20]) {
    var __local_n: i32 = ((0 as i32))

    var __local_j: i32 = ((0 as i32))

    var __local_r: i32 = (((__param_rank - 1) as i32))


    with_memset(((&(__param_result[0]) as *mut [c_char; 20]) as *mut u8), (0 as i32), ((32 as u64) as i64))

    while true {
        var __ci_expr_logic_0: i32 = 0

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
            ((__param_result[0])[__local_j] = (((if (if __local_j < (__param_rank - __local_n): 1 else: 0) != 0: (32 as i32) else: ((__param_brackets[0]) as i32)) as c_char)))

            (__local_j = __local_j + 1)

        }
    }

    (__local_j = ((0 as i32)))

    while true {
        var __ci_expr_logic_1: i32 = 0

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


    (__local_n = ((((if __local_j > 0: 1 else: 0) + (((if __local_j > 1: 1 else: 0) as i32) & ((if __local_j < __param_rank: 1 else: 0) as i32))) as i32)))

    var __ci_expr_logic_2: i32 = 0

    if ((__param_brackets[2]) != 0) {
        (__ci_expr_logic_2 = (if (if __local_j < __param_rank: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        var __ci_expr_old_3: i32 = __local_j

        (__local_j = __local_j + 1)

        ((__param_result[1])[__ci_expr_old_3] = (((__param_brackets[2]) as c_char)))

    }


    while true {
        var __ci_expr_old_4: i32 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_4 != 0)) {
            break
        }

        var __ci_expr_old_5: i32 = __local_j

        (__local_j = __local_j + 1)

        ((__param_result[1])[__ci_expr_old_5] = ((10 as c_char)))

    }

}

// contract: unproved:0:out-parameter read before the write,unproved:1:read only,unproved:2:read only,unproved:4:out-parameter read before the write
pub unsafe fn _cspan_nextN(__param_pos: *mut i32, __param_shape: *mut i32, __param_stride: *mut i32, __param_rank: i32, __param_off: *mut i64) -> bool {
    var __local_rank = __param_rank
    (__local_rank = __local_rank - 1)

    ((__param_pos[__local_rank]) = (__param_pos[__local_rank]) + 1)


    while true {
        var __ci_expr_logic_0: i32 = 0

        if (__local_rank != 0) {
            (__ci_expr_logic_0 = (if (if (__param_pos[__local_rank]) == (__param_shape[__local_rank]): 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        ((__param_pos[__local_rank]) = ((0 as i32)))

        ((__param_pos[(__local_rank - 1)]) = (__param_pos[(__local_rank - 1)]) + 1)

        ((*__param_off) = (*__param_off) + ((__param_stride[(__local_rank - 1)]) - (((__param_shape[__local_rank]) as i64) * (__param_stride[__local_rank]))))

        (__local_rank = __local_rank - 1)

    }

    return (((((__param_pos[__local_rank]) == (__param_shape[__local_rank]))) as bool))

}

// contract: unproved:0:out-parameter read before the write,unproved:1:out-parameter read before the write,out:2:i32,unproved:3:read only,unproved:4:read only,unproved:5:read only
pub unsafe fn _cspan_slice(__param_oshape: *mut i32, __param_ostride: *mut i32, __param_orank: *mut i32, __param_shape: *mut i32, __param_stride: *mut i32, __param_args: *mut [i64; 3], __param_rank: i32) -> i64 {
    var __local_end: i64

    var __local_off: i64 = ((0 as i64))


    var __local_i: i32 = ((0 as i32))

    var __local_oi: i32 = ((0 as i32))


    while ((if __local_i < __param_rank: 1 else: 0) != 0) {
        (__local_off = __local_off + ((__param_args[__local_i])[0] * (__param_stride[__local_i])))

        var __ci_expr_switch_continue_0: i32 = 0

        while true {
            match (__param_args[__local_i])[1] {
                0 => {
                    if (((if not ((if (((__param_args[__local_i])[0] as u64)) < (((__param_shape[__local_i]) as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
                        __assert_rtn(c"_cspan_slice".ptr, c"cspan.h".ptr, (464 as i32), c"((size_t)(args[i][0]) < (size_t)(shape[i]))".ptr)
                    }

                    (__ci_expr_switch_continue_0 = 1)

                    break


                },
                2147483647 => {
                    (__local_end = (((__param_shape[__local_i]) as i64)))
                },
                _ => {
                    (__local_end = (((__param_args[__local_i])[1] as i64)))
                },
            }

            break

        }

        if (__ci_expr_switch_continue_0 != 0) {
            (__local_i = __local_i + 1)

            continue

        }


        ((__param_oshape[__local_oi]) = (((__local_end - (__param_args[__local_i])[0]) as i32)))

        ((__param_ostride[__local_oi]) = (((__param_stride[__local_i]) as i32)))

        if (((if not ((((if (__param_oshape[__local_oi]) > 0: 1 else: 0) as i32) & ((if not ((if (((__param_shape[__local_i]) as u64)) < ((__local_end as u64)): 1 else: 0) != 0): 1 else: 0) as i32)) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"_cspan_slice".ptr, c"cspan.h".ptr, (470 as i32), c"(oshape[oi] > 0) & !((size_t)(shape[i]) < (size_t)(end))".ptr)
        } else {
            0
        }

        if ((if (__param_args[__local_i])[2] > 0: 1 else: 0) != 0) {
            ((__param_ostride[__local_oi]) = (__param_ostride[__local_oi]) * ((__param_args[__local_i])[2] as i32))

            ((__param_oshape[__local_oi]) = ((((((__param_oshape[__local_oi]) - 1) / ((__param_args[__local_i])[2] as i32)) + 1) as i32)))

        }

        (__local_oi = __local_oi + 1)


        (__local_i = __local_i + 1)

    }

    ((*__param_orank) = __local_oi)

    return __local_off

}

// contract: unproved:1:out-parameter read before the write
pub unsafe fn _cspan_shape2stride(__param_layout: i32, __param_shpstri: *mut i32, __param_rank: i32) -> *mut i32 {
    var __local_rank = __param_rank
    var __local_i: i32

    var __local_inc: i32


    if ((if __param_layout == 1: 1 else: 0) != 0) {
        (__local_i = ((0 as i32)))

        (__local_inc = ((1 as i32)))

    } else {
        (__local_i = (((__local_rank - 1) as i32)))

        (__local_inc = ((-1 as i32)))

    }

    var __local_k: i32 = ((1 as i32))

    var __local_s1: i32 = (((__param_shpstri[__local_i]) as i32))

    var __local_s2: i32


    ((__param_shpstri[__local_i]) = ((1 as i32)))

    while true {
        (__local_rank = __local_rank - 1)

        if (not (__local_rank != 0)) {
            break
        }

        (__local_i = __local_i + __local_inc)

        (__local_s2 = (((__param_shpstri[__local_i]) as i32)))

        (__local_k = __local_k * __local_s1)

        ((__param_shpstri[__local_i]) = __local_k)

        (__local_s1 = __local_s2)

    }

    return (&(__param_shpstri[0]) as *mut i32)

}

// contract: unproved:1:read only,unproved:2:read only
pub unsafe fn _cspan_is_layout(__param_layout: i32, __param_shape: *mut i32, __param_strides: *mut i32, __param_rank: i32) -> bool {
    var __local_tmpshape: List[i32] = [0; 16]

    var __local_sz: u64 = ((((__param_rank as u64) *% (sizeof[i32]() as u64)) as u64))

    with_memcpy(((&__local_tmpshape[0] as *mut i32) as *mut u8), ((&(__param_shape[0]) as *mut i32) as *const u8), (__local_sz as i64))

    return ((((with_memcmp(((&(__param_strides[0]) as *mut i32) as *const u8), ((_cspan_shape2stride(__param_layout, (&__local_tmpshape[0] as *mut i32), __param_rank) as *const c_void) as *const u8), (__local_sz as i64)) == 0)) as bool))

}
