// Migrated from C
use std.engines.stc.defs

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


    while (__local_len >= ((sizeof[u64]() as i64))) {
        with_memcpy((((&raw mut __local_block as *mut u64) as *mut c_void) as *mut u8), ((__local_msg as *const c_void) as *const u8), ((sizeof[u64]() as u64) as i64))

        (__local_h = (__local_h as u64) ^ (__local_block as u64))

        (__local_h = (__local_h *% 1099511628211))

        (__local_msg = __local_msg + ((sizeof[u64]() as i64) as usize))

        (__local_len = __local_len - (sizeof[u64]() as i64))

    }

    while true {
        var __ci_expr_old_0: i64 = __local_len

        (__local_len = __local_len - 1)

        if (not __ci_expr_old_0) {
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

    while (*__local_msg) {
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

    while (__local_i < __param_n) {
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
    if (__param_nlen == 0) {
        return ((__local_str as *mut c_char))
    }

    if (__param_nlen > __local_slen) {
        return ((null as *mut c_char))
    }

    (__local_slen = __local_slen - __param_nlen)

    loop {
        var __ci_expr_logic_1: i32 = 0

        if ((*__local_str) == (*__param_needle)) {
            (__ci_expr_logic_1 = (if not with_memcmp(((__local_str as *const c_void) as *const u8), ((__param_needle as *const c_void) as *const u8), (((if true: __param_nlen else: (-1 as i64)) as u64) as i64)): 1 else: 0))
        }

        if __ci_expr_logic_1 {
            return ((__local_str as *mut c_char))
        }


        (__local_str = __local_str + 1)

        var __ci_expr_old_0: i64 = __local_slen

        (__local_slen = __local_slen - 1)

        if not (__ci_expr_old_0) {
            break
        }
    }

    return ((null as *mut c_char))

}

// contract: receiver:crand64,unproved:2:out-parameter written conditionally
pub unsafe fn crand64_normal_r(__param_rng: *mut crand64, __param_stream: u64, __param_d: *mut crand64_normal_dist) -> f64 {
    var __local_v1: f64

    var __local_v2: f64

    var __local_sq: f64

    var __local_rt: f64


    var __ci_expr_old_0: i32 = (*__param_d)._has_next

    ((*__param_d)._has_next = (*__param_d)._has_next + 1)

    if ((__ci_expr_old_0 as i32) & (1 as i32)) {
        return (((*__param_d)._next * (*__param_d).stddev) + (*__param_d).mean)
    }


    loop {
        (__local_v1 = (((((((*__param_rng).uint_r(__param_stream) as i64) >> (11 as u32)) as f64) * 2.2204460492503131e-16) as f64)))

        (__local_v2 = (((((((*__param_rng).uint_r(__param_stream) as i64) >> (11 as u32)) as f64) * 2.2204460492503131e-16) as f64)))

        (__local_sq = ((((__local_v1 * __local_v1) + (__local_v2 * __local_v2)) as f64)))

        var __ci_expr_logic_1: i32

        if (__local_sq >= 1.0) {
            (__ci_expr_logic_1 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_1 = (if __local_sq == 0.0: 1 else: 0))
        }

        if not (__ci_expr_logic_1) {
            break
        }
    }

    (__local_rt = ((sqrt((((-2.0 * log(__local_sq)) / __local_sq) as f64)) as f64)))

    ((*__param_d)._next = (((__local_v2 * __local_rt) as f64)))

    return (((__local_v1 * __local_rt) * (*__param_d).stddev) + (*__param_d).mean)

}

pub fn _stc64() -> *mut crand64 {
    var __local_rng: crand64 = crand64 { data: [(-7046029247804630288 as u64), 8027708214854509594, (-2152535657050944081 as u64), 1] }

    return ((&raw mut __local_rng as *mut crand64))

}

pub fn crand64_seed(__param_seed: u64) {
    unsafe { (*(_stc64())).seed_r(__param_seed) }

}

pub fn crand64_from(__param_seed: u64) -> crand64 {
    var __local_rng: crand64

    unsafe { (*(&raw mut __local_rng as *mut crand64)).seed_r(__param_seed) }

    return __local_rng

}

pub fn crand64_uint() -> u64 {
    return unsafe { (*(_stc64())).uint_r((1 as u64)) }

}

pub fn crand64_real() -> f64 {
    return unsafe { (*(_stc64())).real_r((1 as u64)) }

}

pub fn crand64_make_uniform(__param_low: i64, __param_high: i64) -> crand64_uniform_dist {
    var __local_d: crand64_uniform_dist = crand64_uniform_dist { low: __param_low, range: ((((__param_high - __param_low) + 1)) as u64) }

    (__local_d.threshold = ((((((0 as u64) -% ((unsafe *(&raw const __local_d as *const crand64_uniform_dist)).range as u64)) as u64) % ((unsafe *(&raw const __local_d as *const crand64_uniform_dist)).range as u64)) as u64)))

    return __local_d

}

// contract: receiver:crand64,unproved:2:read only
pub unsafe fn crand64_uniform_r(__param_rng: *mut crand64, __param_stream: u64, __param_d: *mut crand64_uniform_dist) -> i64 {
    var __local_lo: u64

    var __local_hi: u64


    loop {
        loop {
            var __local__z: u128 = (((*__param_rng).uint_r(__param_stream) as u128) *% ((*__param_d).range as u128))

            ((*(&raw mut __local_lo as *mut u64)) = ((__local__z as u64)))

            ((*(&raw mut __local_hi as *mut u64)) = ((((__local__z as u128) >> (64 as u32)) as u64)))


            if not (false) {
                break
            }
        }

        if not ((__local_lo < (*__param_d).threshold)) {
            break
        }
    }

    return ((*__param_d).low + (__local_hi as i64))

}

pub fn _stc32() -> *mut crand32 {
    var __local_rng: crand32 = crand32 { data: [2654463886, 1856707489, 1684164658, 1] }

    return ((&raw mut __local_rng as *mut crand32))

}

pub fn crand32_seed(__param_seed: u32) {
    unsafe { (*(_stc32())).seed_r(__param_seed) }

}

pub fn crand32_from(__param_seed: u32) -> crand32 {
    var __local_rng: crand32

    unsafe { (*(&raw mut __local_rng as *mut crand32)).seed_r(__param_seed) }

    return __local_rng

}

pub fn crand32_uint() -> u32 {
    return unsafe { (*(_stc32())).uint_r((1 as u32)) }

}

pub fn crand32_real() -> f64 {
    return unsafe { (*(_stc32())).real_r((1 as u32)) }

}

pub fn crand32_make_uniform(__param_low: i32, __param_high: i32) -> crand32_uniform_dist {
    var __local_d: crand32_uniform_dist = crand32_uniform_dist { low: __param_low, range: ((((__param_high - __param_low) + 1)) as u32) }

    (__local_d.threshold = ((((((0 as u32) -% ((unsafe *(&raw const __local_d as *const crand32_uniform_dist)).range as u32)) as u32) % ((unsafe *(&raw const __local_d as *const crand32_uniform_dist)).range as u32)) as u32)))

    return __local_d

}

// contract: receiver:crand32,unproved:2:read only
pub unsafe fn crand32_uniform_r(__param_rng: *mut crand32, __param_stream: u32, __param_d: *mut crand32_uniform_dist) -> i32 {
    var __local_r: u64

    loop {
        (__local_r = (((((*__param_rng).uint_r(__param_stream) as u64) *% ((*__param_d).range as u64)) as u64)))

        if not ((((__local_r as u32)) < (*__param_d).threshold)) {
            break
        }
    }

    return ((*__param_d).low + (((__local_r as u64) >> (32 as u32)) as i32))

}

impl crand32 {
    pub fn seed_r(__param_seed: u32) {
        let __param_rng: *mut crand32 = (self as *const crand32) as *mut crand32
        var __local_s: *mut u32 = ((&raw const (unsafe *__param_rng).data[0] as *mut u32))

        ((unsafe __local_s[0]) = ((((__param_seed as u32) *% (2654435769 as u32)) as u32)))

        ((unsafe __local_s[0]) = ((unsafe __local_s[0]) as u32) ^ ((((unsafe __local_s[0]) as u32) >> (16 as u32)) as u32))

        ((unsafe __local_s[1]) = (((((unsafe __local_s[0]) as u32) *% (569420461 as u32)) as u32)))

        ((unsafe __local_s[1]) = ((unsafe __local_s[1]) as u32) ^ ((((unsafe __local_s[1]) as u32) >> (15 as u32)) as u32))

        ((unsafe __local_s[2]) = (((((unsafe __local_s[1]) as u32) *% (1935289751 as u32)) as u32)))

        ((unsafe __local_s[2]) = ((unsafe __local_s[2]) as u32) ^ ((((unsafe __local_s[2]) as u32) >> (15 as u32)) as u32))

        ((unsafe __local_s[3]) = __param_seed)

    }

    pub fn uint_r(__param_stream: u32) -> u32 {
        let __param_rng: *mut crand32 = (self as *const crand32) as *mut crand32
        var __local_s: *mut u32 = ((&raw const (unsafe *__param_rng).data[0] as *mut u32))

        var __local_result: u32 = with 0 as __ci_expr_seq_6 {
            ((unsafe __local_s[3]) = ((unsafe __local_s[3]) +% __param_stream))
            ((((((unsafe __local_s[0]) as u32) ^ ((unsafe __local_s[3]) as u32)) as u32) +% ((unsafe __local_s[1]) as u32)) as u32)
        }

        ((unsafe __local_s[0]) = (((((unsafe __local_s[1]) as u32) ^ ((((unsafe __local_s[1]) as u32) >> (9 as u32)) as u32)) as u32)))

        ((unsafe __local_s[1]) = (((((unsafe __local_s[2]) as u32) +% ((((unsafe __local_s[2]) as u32) << (3 as u32)) as u32)) as u32)))

        ((unsafe __local_s[2]) = (((((((((unsafe __local_s[2]) as u32) << (21 as u32)) as u32) | ((((unsafe __local_s[2]) as u32) >> (11 as u32)) as u32)) as u32) +% (__local_result as u32)) as u32)))

        return __local_result

    }

    pub fn real_r(__param_stream: u32) -> f64 {
        let __param_rng: *mut crand32 = (self as *const crand32) as *mut crand32
        return ((unsafe { (*__param_rng).uint_r(__param_stream) } as f64) * 2.3283064365386963e-10)

    }

}

impl crand32_uniform_dist {
    pub fn crand32_uniform() -> i64 {
        let __param_d: *mut crand32_uniform_dist = (self as *const crand32_uniform_dist) as *mut crand32_uniform_dist
        return ((unsafe { crand32_uniform_r(_stc32(), (1 as u32), __param_d) } as i64))

    }

}

impl crand64 {
    pub fn seed_r(__param_seed: u64) {
        let __param_rng: *mut crand64 = (self as *const crand64) as *mut crand64
        var __local_s: *mut u64 = ((&raw const (unsafe *__param_rng).data[0] as *mut u64))

        ((unsafe __local_s[0]) = ((((__param_seed as u64) *% (((0 as u64) -% 7046029254386353131) as u64)) as u64)))

        ((unsafe __local_s[0]) = ((unsafe __local_s[0]) as u64) ^ ((((unsafe __local_s[0]) as u64) >> (30 as u32)) as u64))

        ((unsafe __local_s[1]) = (((((unsafe __local_s[0]) as u64) *% (((0 as u64) -% 4658895280553007687) as u64)) as u64)))

        ((unsafe __local_s[1]) = ((unsafe __local_s[1]) as u64) ^ ((((unsafe __local_s[1]) as u64) >> (27 as u32)) as u64))

        ((unsafe __local_s[2]) = (((((unsafe __local_s[1]) as u64) *% (((0 as u64) -% 7723592293110705685) as u64)) as u64)))

        ((unsafe __local_s[2]) = ((unsafe __local_s[2]) as u64) ^ ((((unsafe __local_s[2]) as u64) >> (31 as u32)) as u64))

        ((unsafe __local_s[3]) = __param_seed)

    }

    pub fn uint_r(__param_stream: u64) -> u64 {
        let __param_rng: *mut crand64 = (self as *const crand64) as *mut crand64
        var __local_s: *mut u64 = ((&raw const (unsafe *__param_rng).data[0] as *mut u64))

        var __local_result: u64 = with 0 as __ci_expr_seq_6 {
            ((unsafe __local_s[3]) = ((unsafe __local_s[3]) +% __param_stream))
            ((((((unsafe __local_s[0]) as u64) ^ ((unsafe __local_s[3]) as u64)) as u64) +% ((unsafe __local_s[1]) as u64)) as u64)
        }

        ((unsafe __local_s[0]) = (((((unsafe __local_s[1]) as u64) ^ ((((unsafe __local_s[1]) as u64) >> (11 as u32)) as u64)) as u64)))

        ((unsafe __local_s[1]) = (((((unsafe __local_s[2]) as u64) +% ((((unsafe __local_s[2]) as u64) << (3 as u32)) as u64)) as u64)))

        ((unsafe __local_s[2]) = (((((((((unsafe __local_s[2]) as u64) << (24 as u32)) as u64) | ((((unsafe __local_s[2]) as u64) >> (40 as u32)) as u64)) as u64) +% (__local_result as u64)) as u64)))

        return __local_result

    }

    pub fn real_r(__param_stream: u64) -> f64 {
        let __param_rng: *mut crand64 = (self as *const crand64) as *mut crand64
        return ((((unsafe { (*__param_rng).uint_r(__param_stream) } as u64) >> (11 as u32)) as f64) * 1.1102230246251565e-16)

    }

}

impl crand64_normal_dist {
    pub mut fn crand64_normal() -> f64 {
        let __param_d: *mut crand64_normal_dist = self as *mut crand64_normal_dist
        return unsafe { crand64_normal_r(_stc64(), (1 as u64), __param_d) }

    }

}

impl crand64_uniform_dist {
    pub fn crand64_uniform() -> i64 {
        let __param_d: *mut crand64_uniform_dist = (self as *const crand64_uniform_dist) as *mut crand64_uniform_dist
        return unsafe { crand64_uniform_r(_stc64(), (1 as u64), __param_d) }

    }

}
