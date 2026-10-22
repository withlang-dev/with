// Migrated from C
use std.engines.stc_testing.defs

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

unsafe fn c_hash_str(__param_str: *const i8) -> c_ulong {
    var __local_msg: *const u8 = ((__param_str as *const u8))

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

unsafe fn c_strnstrn(__param_str: *const i8, __param_slen: c_long, __param_needle: *const i8, __param_nlen: c_long) -> *mut i8 {
    var __local_str = __param_str
    var __local_slen = __param_slen
    if ((if __param_nlen == 0: 1 else: 0) != 0) {
        return (((__local_str as *mut c_char) as *mut i8))
    }

    if ((if __param_nlen > __local_slen: 1 else: 0) != 0) {
        return ((null as *mut i8))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: c_int = 0

        if ((if (*__local_str) == (*__param_needle): 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if (if not (with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if 1 != 0: __param_nlen else: (-1 as c_long)) as c_ulong) as i64)) != 0): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            return (((__local_str as *mut c_char) as *mut i8))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: c_long = __local_slen

        (__local_slen = __local_slen - 1)

        if not ((__ci_expr_old_0 != 0)) {
            break
        }
    }

    return ((null as *mut i8))

}

pub unsafe fn crand64_normal(__param_d: *mut crand64_normal_dist) -> f64 {
    return crand64_normal_r(_stc64(), (1 as c_ulonglong), __param_d)

}

pub unsafe fn crand64_normal_r(__param_rng: *mut crand64, __param_stream: c_ulonglong, __param_d: *mut crand64_normal_dist) -> f64 {
    var __local_v1: f64

    var __local_v2: f64

    var __local_sq: f64

    var __local_rt: f64


    var __ci_expr_old_0: c_int = (*__param_d)._has_next

    ((*__param_d)._has_next = (*__param_d)._has_next + 1)

    if (((__ci_expr_old_0 as c_int) & (1 as c_int)) != 0) {
        return (((*__param_d)._next * (*__param_d).stddev) + (*__param_d).mean)
    }


    loop {
        (__local_v1 = ((((((crand64_uint_r(__param_rng, __param_stream) as c_longlong) >> (11 as c_uint)) as f64) * 2.2204460492503131e-16) as f64)))

        (__local_v2 = ((((((crand64_uint_r(__param_rng, __param_stream) as c_longlong) >> (11 as c_uint)) as f64) * 2.2204460492503131e-16) as f64)))

        (__local_sq = ((((__local_v1 * __local_v1) + (__local_v2 * __local_v2)) as f64)))

        var __ci_expr_logic_1: c_int

        if ((if __local_sq >= 1.0: 1 else: 0) != 0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if (if __local_sq == 0.0: 1 else: 0) != 0: 1 else: 0))
        }

        if not ((__ci_expr_logic_1 != 0)) {
            break
        }
    }

    (__local_rt = ((sqrt((((-2.0 * log(__local_sq)) / __local_sq) as f64)) as f64)))

    ((*__param_d)._next = (((__local_v2 * __local_rt) as f64)))

    return (((__local_v1 * __local_rt) * (*__param_d).stddev) + (*__param_d).mean)

}

pub unsafe fn crand64_seed_r(__param_rng: *mut crand64, __param_seed: c_ulonglong) {
    var __local_s: *mut c_ulonglong = ((&raw const (*__param_rng).data[0] as *mut c_ulonglong))

    ((__local_s[0]) = ((((__param_seed as c_ulonglong) *% (((0 as c_ulonglong) -% 7046029254386353131) as c_ulonglong)) as c_ulonglong)))

    ((__local_s[0]) = ((__local_s[0]) as c_ulonglong) ^ ((((__local_s[0]) as c_ulonglong) >> (30 as c_uint)) as c_ulonglong))

    ((__local_s[1]) = (((((__local_s[0]) as c_ulonglong) *% (((0 as c_ulonglong) -% 4658895280553007687) as c_ulonglong)) as c_ulonglong)))

    ((__local_s[1]) = ((__local_s[1]) as c_ulonglong) ^ ((((__local_s[1]) as c_ulonglong) >> (27 as c_uint)) as c_ulonglong))

    ((__local_s[2]) = (((((__local_s[1]) as c_ulonglong) *% (((0 as c_ulonglong) -% 7723592293110705685) as c_ulonglong)) as c_ulonglong)))

    ((__local_s[2]) = ((__local_s[2]) as c_ulonglong) ^ ((((__local_s[2]) as c_ulonglong) >> (31 as c_uint)) as c_ulonglong))

    ((__local_s[3]) = __param_seed)

}

pub unsafe fn crand64_uint_r(__param_rng: *mut crand64, __param_stream: c_ulonglong) -> c_ulonglong {
    var __local_s: *mut c_ulonglong = ((&raw const (*__param_rng).data[0] as *mut c_ulonglong))

    var __local_result: c_ulonglong = with 0 as __ci_expr_seq_6 {
        ((__local_s[3]) = ((__local_s[3]) +% __param_stream))
        ((((((__local_s[0]) as c_ulonglong) ^ ((__local_s[3]) as c_ulonglong)) as c_ulonglong) +% ((__local_s[1]) as c_ulonglong)) as c_ulonglong)
    }

    ((__local_s[0]) = (((((__local_s[1]) as c_ulonglong) ^ ((((__local_s[1]) as c_ulonglong) >> (11 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    ((__local_s[1]) = (((((__local_s[2]) as c_ulonglong) +% ((((__local_s[2]) as c_ulonglong) << (3 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    ((__local_s[2]) = (((((((((__local_s[2]) as c_ulonglong) << (24 as c_uint)) as c_ulonglong) | ((((__local_s[2]) as c_ulonglong) >> (40 as c_uint)) as c_ulonglong)) as c_ulonglong) +% (__local_result as c_ulonglong)) as c_ulonglong)))

    return __local_result

}

pub unsafe fn crand64_real_r(__param_rng: *mut crand64, __param_stream: c_ulonglong) -> f64 {
    return ((((crand64_uint_r(__param_rng, __param_stream) as c_ulonglong) >> (11 as c_uint)) as f64) * 1.1102230246251565e-16)

}

pub fn _stc64() -> *mut crand64 {
    var __local_rng: crand64 = crand64 { data: [(-7046029247804630288 as c_ulonglong), 8027708214854509594, (-2152535657050944081 as c_ulonglong), 1] }

    return ((&raw mut __local_rng as *mut crand64))

}

pub fn crand64_seed(__param_seed: c_ulonglong) {
    unsafe { crand64_seed_r(_stc64(), __param_seed) }

}

pub fn crand64_from(__param_seed: c_ulonglong) -> crand64 {
    var __local_rng: crand64

    unsafe { crand64_seed_r((&raw mut __local_rng as *mut crand64), __param_seed) }

    return __local_rng

}

pub fn crand64_uint() -> c_ulonglong {
    return unsafe { crand64_uint_r(_stc64(), (1 as c_ulonglong)) }

}

pub fn crand64_real() -> f64 {
    return unsafe { crand64_real_r(_stc64(), (1 as c_ulonglong)) }

}

pub fn crand64_make_uniform(__param_low: c_longlong, __param_high: c_longlong) -> crand64_uniform_dist {
    var __local_d: crand64_uniform_dist = crand64_uniform_dist { low: __param_low, range: ((((__param_high - __param_low) + 1)) as c_ulonglong) }

    (__local_d.threshold = ((((((0 as c_ulonglong) -% ((unsafe *(&raw const __local_d as *const crand64_uniform_dist)).range as c_ulonglong)) as c_ulonglong) % ((unsafe *(&raw const __local_d as *const crand64_uniform_dist)).range as c_ulonglong)) as c_ulonglong)))

    return __local_d

}

pub unsafe fn crand64_uniform_r(__param_rng: *mut crand64, __param_stream: c_ulonglong, __param_d: *mut crand64_uniform_dist) -> c_longlong {
    var __local_lo: c_ulonglong

    var __local_hi: c_ulonglong


    loop {
        loop {
            var __local__z: u128 = ((crand64_uint_r(__param_rng, __param_stream) as u128) *% ((*__param_d).range as u128))

            ((*(&raw mut __local_lo as *mut c_ulonglong)) = ((__local__z as c_ulonglong)))

            ((*(&raw mut __local_hi as *mut c_ulonglong)) = ((((__local__z as u128) >> (64 as c_uint)) as c_ulonglong)))


            if not ((0 != 0)) {
                break
            }
        }

        if not (((if __local_lo < (*__param_d).threshold: 1 else: 0) != 0)) {
            break
        }
    }

    return ((*__param_d).low + (__local_hi as c_longlong))

}

pub unsafe fn crand64_uniform(__param_d: *mut crand64_uniform_dist) -> c_longlong {
    return crand64_uniform_r(_stc64(), (1 as c_ulonglong), __param_d)

}

pub unsafe fn crand32_seed_r(__param_rng: *mut crand32, __param_seed: c_uint) {
    var __local_s: *mut c_uint = ((&raw const (*__param_rng).data[0] as *mut c_uint))

    ((__local_s[0]) = ((((__param_seed as c_uint) *% (2654435769 as c_uint)) as c_uint)))

    ((__local_s[0]) = ((__local_s[0]) as c_uint) ^ ((((__local_s[0]) as c_uint) >> (16 as c_uint)) as c_uint))

    ((__local_s[1]) = (((((__local_s[0]) as c_uint) *% (569420461 as c_uint)) as c_uint)))

    ((__local_s[1]) = ((__local_s[1]) as c_uint) ^ ((((__local_s[1]) as c_uint) >> (15 as c_uint)) as c_uint))

    ((__local_s[2]) = (((((__local_s[1]) as c_uint) *% (1935289751 as c_uint)) as c_uint)))

    ((__local_s[2]) = ((__local_s[2]) as c_uint) ^ ((((__local_s[2]) as c_uint) >> (15 as c_uint)) as c_uint))

    ((__local_s[3]) = __param_seed)

}

pub unsafe fn crand32_uint_r(__param_rng: *mut crand32, __param_stream: c_uint) -> c_uint {
    var __local_s: *mut c_uint = ((&raw const (*__param_rng).data[0] as *mut c_uint))

    var __local_result: c_uint = with 0 as __ci_expr_seq_6 {
        ((__local_s[3]) = ((__local_s[3]) +% __param_stream))
        ((((((__local_s[0]) as c_uint) ^ ((__local_s[3]) as c_uint)) as c_uint) +% ((__local_s[1]) as c_uint)) as c_uint)
    }

    ((__local_s[0]) = (((((__local_s[1]) as c_uint) ^ ((((__local_s[1]) as c_uint) >> (9 as c_uint)) as c_uint)) as c_uint)))

    ((__local_s[1]) = (((((__local_s[2]) as c_uint) +% ((((__local_s[2]) as c_uint) << (3 as c_uint)) as c_uint)) as c_uint)))

    ((__local_s[2]) = (((((((((__local_s[2]) as c_uint) << (21 as c_uint)) as c_uint) | ((((__local_s[2]) as c_uint) >> (11 as c_uint)) as c_uint)) as c_uint) +% (__local_result as c_uint)) as c_uint)))

    return __local_result

}

pub unsafe fn crand32_real_r(__param_rng: *mut crand32, __param_stream: c_uint) -> f64 {
    return ((crand32_uint_r(__param_rng, __param_stream) as f64) * 2.3283064365386963e-10)

}

pub fn _stc32() -> *mut crand32 {
    var __local_rng: crand32 = crand32 { data: [2654463886, 1856707489, 1684164658, 1] }

    return ((&raw mut __local_rng as *mut crand32))

}

pub fn crand32_seed(__param_seed: c_uint) {
    unsafe { crand32_seed_r(_stc32(), __param_seed) }

}

pub fn crand32_from(__param_seed: c_uint) -> crand32 {
    var __local_rng: crand32

    unsafe { crand32_seed_r((&raw mut __local_rng as *mut crand32), __param_seed) }

    return __local_rng

}

pub fn crand32_uint() -> c_uint {
    return unsafe { crand32_uint_r(_stc32(), (1 as c_uint)) }

}

pub fn crand32_real() -> f64 {
    return unsafe { crand32_real_r(_stc32(), (1 as c_uint)) }

}

pub fn crand32_make_uniform(__param_low: c_int, __param_high: c_int) -> crand32_uniform_dist {
    var __local_d: crand32_uniform_dist = crand32_uniform_dist { low: __param_low, range: ((((__param_high - __param_low) + 1)) as c_uint) }

    (__local_d.threshold = ((((((0 as c_uint) -% ((unsafe *(&raw const __local_d as *const crand32_uniform_dist)).range as c_uint)) as c_uint) % ((unsafe *(&raw const __local_d as *const crand32_uniform_dist)).range as c_uint)) as c_uint)))

    return __local_d

}

pub unsafe fn crand32_uniform_r(__param_rng: *mut crand32, __param_stream: c_uint, __param_d: *mut crand32_uniform_dist) -> c_int {
    var __local_r: c_ulonglong

    loop {
        (__local_r = ((((crand32_uint_r(__param_rng, __param_stream) as c_ulonglong) *% ((*__param_d).range as c_ulonglong)) as c_ulonglong)))

        if not (((if ((__local_r as c_uint)) < (*__param_d).threshold: 1 else: 0) != 0)) {
            break
        }
    }

    return ((*__param_d).low + (((__local_r as c_ulonglong) >> (32 as c_uint)) as c_int))

}

pub unsafe fn crand32_uniform(__param_d: *mut crand32_uniform_dist) -> c_longlong {
    return crand32_uniform_r(_stc32(), (1 as c_uint), __param_d)

}
