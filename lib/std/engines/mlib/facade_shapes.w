// Migrated from C
use std.engines.mlib.defs
use std.libc

// contract: unproved:0:out-parameter read before the write
pub unsafe fn m_core_str_nospace(__param_str: *mut *const c_char) -> c_char {
    var __local_c: c_char

    loop {
        var __ci_expr_old_0: *const c_char = (*__param_str)

        ((*__param_str) = (*__param_str) + 1)

        (__local_c = (*__ci_expr_old_0))


        if not (isspace(((__local_c as u8) as i32))) {
            break
        }
    }

    return __local_c

}

// contract: unproved:0:mutated through a pointer to no corpus record,stored-unknown:1,unproved:2:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn m_core_parse_char(__param_ptr: *mut c_char, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_str = __param_str
    var __ci_expr_old_0: *mut c_char = __local_str

    (__local_str = __local_str + 1)

    ((*__param_ptr) = (*(&(__ci_expr_old_0[0]) as *mut c_char)))


    if (__param_endptr != null) {
        ((*__param_endptr) = (((&(__local_str[0]) as *const c_char) as *const c_char)))

    }

    return ((true as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,stored-unknown:1,unproved:2:out-parameter read before the write — stores an argument; ownership not modeled
pub unsafe fn m_core_parse_bool(__param_ptr: *mut bool, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_str = __param_str
    var __local_c: c_char = with 0 as __ci_expr_seq_7 {
        var __ci_expr_old_0: *mut c_char = __local_str
        (__local_str = __local_str + 1)
        (*(&(__ci_expr_old_0[0]) as *mut c_char))
    }

    ((*__param_ptr) = ((__local_c == 49)))

    if (__param_endptr != null) {
        ((*__param_endptr) = (((&(__local_str[0]) as *const c_char) as *const c_char)))

    }

    var __ci_expr_logic_1: i32

    if (__local_c == 48) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if __local_c == 49: 1 else: 0))
    }

    return (((__ci_expr_logic_1 != 0) as bool))


}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_schar(__param_ptr: *mut i8, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtol((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)) as i8)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_uchar(__param_ptr: *mut u8, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtoul((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)) as u8)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_sshort(__param_ptr: *mut i16, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtol((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)) as i16)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_ushort(__param_ptr: *mut u16, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtoul((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)) as u16)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_sint(__param_ptr: *mut i32, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtol((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)) as i32)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_uint(__param_ptr: *mut u32, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtoul((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)) as u32)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_slong(__param_ptr: *mut i64, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = strtol((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_ulong(__param_ptr: *mut u64, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = strtoul((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_sllong(__param_ptr: *mut i64, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = strtoll((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_ullong(__param_ptr: *mut u64, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = strtoull((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_float(__param_ptr: *mut f32, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtof((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char)) as f32)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_double(__param_ptr: *mut f64, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtod((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char)) as f64)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn m_core_parse_ldouble(__param_ptr: *mut f64, __param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    ((*__param_ptr) = ((strtold((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char)) as f64)))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))

    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

pub fn m_core_rotl32a(__param_x: u32, __param_n: u32) -> u32 {
    var __ci_expr_logic_0: i32 = 0

    if (__param_n > 0) {
        (__ci_expr_logic_0 = (if __param_n < 32: 1 else: 0))
    }

    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
        __assert_rtn(c"m_core_rotl32a".ptr, c"m-core.h".ptr, (3179 as i32), c"n > 0 && n<32".ptr)
    } else {
        0
    }


    return ((((__param_x as u32) << (__param_n as u32)) as u32) | (((__param_x as u32) >> (((32 as u32) -% (__param_n as u32)) as u32)) as u32))

}

pub fn m_core_rotl64a(__param_x: u64, __param_n: u32) -> u64 {
    var __ci_expr_logic_0: i32 = 0

    if (__param_n > 0) {
        (__ci_expr_logic_0 = (if __param_n < 64: 1 else: 0))
    }

    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
        __assert_rtn(c"m_core_rotl64a".ptr, c"m-core.h".ptr, (3184 as i32), c"n > 0 && n<64".ptr)
    } else {
        0
    }


    return ((((__param_x as u64) << (__param_n as u32)) as u64) | (((__param_x as u64) >> (((64 as u32) -% (__param_n as u32)) as u32)) as u64))

}

pub fn m_core_roundpow2(__param_v: u64) -> u64 {
    var __local_v = __param_v
    (__local_v = (__local_v -% 1))

    (__local_v = (__local_v as u64) | (((__local_v as u64) >> (1 as u32)) as u64))

    (__local_v = (__local_v as u64) | (((__local_v as u64) >> (2 as u32)) as u64))

    (__local_v = (__local_v as u64) | (((__local_v as u64) >> (4 as u32)) as u64))

    (__local_v = (__local_v as u64) | (((__local_v as u64) >> (8 as u32)) as u64))

    (__local_v = (__local_v as u64) | (((__local_v as u64) >> (16 as u32)) as u64))

    (__local_v = (__local_v as u64) | (((__local_v as u64) >> (32 as u32)) as u64))

    (__local_v = (__local_v +% 1))

    return __local_v

}

pub fn m_core_clz32(__param_limb: u32) -> u32 {
    return (((if ((if not (not (__param_limb == 0)): 1 else: 0) as i64): (((sizeof[u32]() as u64) *% (8 as u64)) as u64) else: ((((__param_limb as u64).clz() as u64) -% (((((sizeof[u64]() as u64) -% (sizeof[u32]() as u64)) as u64) *% (8 as u64)) as u64)) as u64)) as u32))

}

pub fn m_core_clz64(__param_limb: u64) -> u32 {
    return (((if ((if not (not (__param_limb == 0)): 1 else: 0) as i64): (((sizeof[u64]() as u64) *% (8 as u64)) as u64) else: ((((__param_limb as u64).clz() as u64) -% (((((sizeof[u64]() as u64) -% (sizeof[u64]() as u64)) as u64) *% (8 as u64)) as u64)) as u64)) as u32))

}

pub fn m_core_ctz32(__param_limb: u32) -> u32 {
    return (((if ((if not (not (__param_limb == 0)): 1 else: 0) as i64): (((sizeof[u32]() as u64) *% (8 as u64)) as u64) else: ((__param_limb as u64).ctz() as u64)) as u32))

}

pub fn m_core_ctz64(__param_limb: u64) -> u32 {
    return (((if ((if not (not (__param_limb == 0)): 1 else: 0) as i64): (((sizeof[u64]() as u64) *% (8 as u64)) as u64) else: ((__param_limb as u64).ctz() as u64)) as u32))

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
pub unsafe fn m_core_hash(__param_str: *const c_void, __param_length: u64) -> u64 {
    var __local_length = __param_length
    var __local_prime: u64 = ((1099511628211 as u64))

    var __local_hash64: u64 = ((((((0 as u64) -% 3750763034362895579) as u64) ^ (0 as u64)) as u64))

    var __local_p: *const u8

    (__local_p = ((__param_str as *const u8)))


    var __ci_expr_logic_0: i32

    if (__param_str != null) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_length == 0: 1 else: 0))
    }

    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
        __assert_rtn(c"m_core_hash".ptr, c"m-core.h".ptr, (3384 as i32), c"str != ((void*)0) || length == 0".ptr)
    } else {
        0
    }


    var __ci_expr_logic_1: i32

    if (((__local_p as u64) & (((sizeof[u64]() as u64) -% (1 as u64)) as u64)) == 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if __local_length <= (sizeof[u32]() as usize): 1 else: 0))
    }

    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
        __assert_rtn(c"m_core_hash".ptr, c"m-core.h".ptr, (3385 as i32), c"(( (uintptr_t)p & (sizeof(uint64_t)-1) ) == 0) || (length <= sizeof(uint32_t))".ptr)
    } else {
        0
    }


    var __ci_expr_logic_2: i32

    if (((__local_p as u64) & (((sizeof[u32]() as u64) -% (1 as u64)) as u64)) == 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if __local_length <= (sizeof[u32]() as usize): 1 else: 0))
    }

    if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
        __assert_rtn(c"m_core_hash".ptr, c"m-core.h".ptr, (3386 as i32), c"(( (uintptr_t)p & (sizeof(uint32_t)-1) ) == 0) || (length <= sizeof(uint32_t))".ptr)
    } else {
        0
    }


    var __ci_expr_logic_3: i32

    if (((__local_p as u64) & (((sizeof[u16]() as u64) -% (1 as u64)) as u64)) == 0) {
        (__ci_expr_logic_3 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_3 = (if __local_length <= (sizeof[u16]() as usize): 1 else: 0))
    }

    if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
        __assert_rtn(c"m_core_hash".ptr, c"m-core.h".ptr, (3387 as i32), c"(( (uintptr_t)p & (sizeof(uint16_t)-1) ) == 0) || (length <= sizeof(uint16_t))".ptr)
    } else {
        0
    }


    while (__local_length >= ((2 as u64) *% (sizeof[u64]() as u64))) {
        var __local_ptr: *const u64 = (((__local_p as u64) as *const u64))

        (__local_hash64 = ((((((__local_hash64 as u64) ^ (((m_core_rotl64a(((__local_ptr[0]) as u64), (5 as u32)) as u64) ^ ((__local_ptr[1]) as u64)) as u64)) as u64) *% (1099511628211 as u64)) as u64)))

        (__local_length = (__local_length -% ((2 as u64) *% (sizeof[u64]() as u64))))

        (__local_p = __local_p + (((2 as u64) *% (sizeof[u64]() as u64)) as usize))

    }

    if ((__local_length as u64) & (sizeof[u64]() as u64)) {
        var __local_ptr_1: *const u64 = (((__local_p as u64) as *const u64))

        (__local_hash64 = ((((((__local_hash64 as u64) ^ ((__local_ptr_1[0]) as u64)) as u64) *% (1099511628211 as u64)) as u64)))

        (__local_p = __local_p + (sizeof[u64]() as usize))

    }

    if ((__local_length as u64) & (sizeof[u32]() as u64)) {
        var __local_ptr_2: *const u32 = (((__local_p as u64) as *const u32))

        (__local_hash64 = ((((((__local_hash64 as u64) ^ ((__local_ptr_2[0]) as u64)) as u64) *% (1099511628211 as u64)) as u64)))

        (__local_p = __local_p + (sizeof[u32]() as usize))

    }

    if ((__local_length as u64) & (sizeof[u16]() as u64)) {
        var __local_ptr_3: *const u16 = (((__local_p as u64) as *const u16))

        (__local_hash64 = ((((((__local_hash64 as u64) ^ (((__local_ptr_3[0]) as i32) as u64)) as u64) *% (1099511628211 as u64)) as u64)))

        (__local_p = __local_p + (sizeof[u16]() as usize))

    }

    if ((__local_length as u64) & (1 as u64)) {
        (__local_hash64 = ((((((__local_hash64 as u64) ^ (((*__local_p) as i32) as u64)) as u64) *% (1099511628211 as u64)) as u64)))
    }

    return ((__local_hash64 as u64) ^ (((__local_hash64 as u64) >> (32 as u32)) as u64))

}

// contract: unproved:0:read only
pub unsafe fn m_core_cstr_hash(__param_str: *mut c_char) -> u64 {
    var __local_str = __param_str
    var __local_hash: u64 = ((((0 as u64) ^ (0 as u64)) as u64))

    while (*__local_str) {
        var __local_u: u64 = with 0 as __ci_expr_seq_8 {
            var __ci_expr_old_0: *mut c_char = __local_str
            (__local_str = __local_str + 1)
            (((*(&(__ci_expr_old_0[0]) as *mut c_char)) as u8) as u64)
        }

        loop {
            (__local_hash = ((((((__local_hash as u64) *% (2166136261 as u64)) as u64) ^ (__local_u as u64)) as u64)))

            if not (false) {
                break
            }
        }

    }

    return ((((__local_hash as u64) >> (((((sizeof[u64]() as u64) *% (8 as u64)) as u64) / (2 as u64)) as u32)) as u64) ^ (__local_hash as u64))

}

// contract: unproved:0:read only
pub unsafe fn m_core_parse1_enum(__param_str: *mut c_char) -> i64 {
    return strtoll((&(__param_str[0]) as *mut c_char), (null as *mut *mut c_char), (10 as i32))

}

// contract: unproved:0:read only,unproved:1:out-parameter read before the write
pub unsafe fn m_core_parse2_enum(__param_str: *mut c_char, __param_endptr: *mut *const c_char) -> bool {
    var __local_end: *mut c_char

    strtoll((&(__param_str[0]) as *mut c_char), (&raw mut __local_end as *mut *mut c_char), (10 as i32))

    if (__param_endptr != null) {
        ((*__param_endptr) = ((__local_end as *const c_char)))
    }

    return ((((__local_end != (&(__param_str[0]) as *mut c_char))) as bool))

}

// contract: stored-unknown:0,out:1:c_char — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_char(__param_serial: *mut m_serial_read_s, __param_ptr: *mut c_char) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (1 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as c_char)))

    return __local_r

}

// contract: stored-unknown:0,out:1:i8 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_schar(__param_serial: *mut m_serial_read_s, __param_ptr: *mut i8) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (1 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as i8)))

    return __local_r

}

// contract: stored-unknown:0,out:1:u8 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_uchar(__param_serial: *mut m_serial_read_s, __param_ptr: *mut u8) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (1 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as u8)))

    return __local_r

}

// contract: stored-unknown:0,out:1:i16 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_sshort(__param_serial: *mut m_serial_read_s, __param_ptr: *mut i16) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (2 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as i16)))

    return __local_r

}

// contract: stored-unknown:0,out:1:u16 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_ushort(__param_serial: *mut m_serial_read_s, __param_ptr: *mut u16) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (2 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as u16)))

    return __local_r

}

// contract: stored-unknown:0,out:1:i32 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_sint(__param_serial: *mut m_serial_read_s, __param_ptr: *mut i32) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (4 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as i32)))

    return __local_r

}

// contract: stored-unknown:0,out:1:u32 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_uint(__param_serial: *mut m_serial_read_s, __param_ptr: *mut u32) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (4 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as u32)))

    return __local_r

}

// contract: stored-unknown:0,out:1:i64 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_slong(__param_serial: *mut m_serial_read_s, __param_ptr: *mut i64) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (8 as u64)) as i32)))

    ((*__param_ptr) = __local_i)

    return __local_r

}

// contract: stored-unknown:0,out:1:u64 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_ulong(__param_serial: *mut m_serial_read_s, __param_ptr: *mut u64) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (8 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as u64)))

    return __local_r

}

// contract: stored-unknown:0,out:1:i64 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_sllong(__param_serial: *mut m_serial_read_s, __param_ptr: *mut i64) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (8 as u64)) as i32)))

    ((*__param_ptr) = __local_i)

    return __local_r

}

// contract: stored-unknown:0,out:1:u64 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_ullong(__param_serial: *mut m_serial_read_s, __param_ptr: *mut u64) -> i32 {
    var __local_i: i64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (8 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as u64)))

    return __local_r

}

// contract: stored-unknown:0,out:1:f32 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_float(__param_serial: *mut m_serial_read_s, __param_ptr: *mut f32) -> i32 {
    var __local_i: f64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_float.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut f64), (4 as u64)) as i32)))

    ((*__param_ptr) = ((__local_i as f32)))

    return __local_r

}

// contract: stored-unknown:0,out:1:f64 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_double(__param_serial: *mut m_serial_read_s, __param_ptr: *mut f64) -> i32 {
    var __local_i: f64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_float.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut f64), (8 as u64)) as i32)))

    ((*__param_ptr) = __local_i)

    return __local_r

}

// contract: stored-unknown:0,out:1:f64 — stores an argument; ownership not modeled
pub unsafe fn m_core_in_serial_ldouble(__param_serial: *mut m_serial_read_s, __param_ptr: *mut f64) -> i32 {
    var __local_i: f64

    var __local_r: i32

    (__local_r = (((*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_float.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut f64), (8 as u64)) as i32)))

    ((*__param_ptr) = __local_i)

    return __local_r

}

// contract: unproved:0:read only
pub unsafe fn m_core_out_serial_strlen(__param_s: *mut c_char) -> u64 {
    if ((if not ((&(__param_s[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"m_core_out_serial_strlen".ptr, c"m-core.h".ptr, (5842 as i32), c"s != ((void*)0)".ptr)
    } else {
        0
    }

    return strlen((&(__param_s[0]) as *mut c_char))

}

pub fn m_core_serial_fail() -> i32 {
    return 2

}

// contract: receiver-mut:m_bptr33_transaction_t_anon,stored-unknown:2,stored-unknown:3 — stores an argument; ownership not modeled
pub unsafe fn m_bptr33_add_transaction(__param_records: *mut m_bptr33_transaction_t_anon, __param_type_: i32, __param_data_dst: *mut c_void, __param_data_src: *mut c_void) {
    if ((if not ((&(__param_records[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"m_bptr33_add_transaction".ptr, c"m-bptree.h".ptr, (431 as i32), c"records != ((void*)0)".ptr)
    } else {
        0
    }

    if ((if not ((*(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size < (5 + (4 * (((1 as u64) +% (((8 as u64) *% (sizeof[u64]() as u64)) as u64)) as i32)))): 1 else: 0) as i64) {
        __assert_rtn(c"m_bptr33_add_transaction".ptr, c"m-bptree.h".ptr, (432 as i32), c"records->size < (5+4*((int)(1 + 8*sizeof (size_t))))".ptr)
    } else {
        0
    }

    if ((if not (__param_type_ != 0): 1 else: 0) as i64) {
        __assert_rtn(c"m_bptr33_add_transaction".ptr, c"m-bptree.h".ptr, (433 as i32), c"type != M_BPTR33_NONE".ptr)
    } else {
        0
    }

    ((__param_records[0]).tab[(*(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size].type_ = __param_type_)

    ((__param_records[0]).tab[(*(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size].data_dst = __param_data_dst)

    ((__param_records[0]).tab[(*(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size].data_src = __param_data_src)

    ((__param_records[0]).size = (*(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size + 1)

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
unsafe fn mlib_slot_clone(__param_s: *mut mlib_slot_head) -> *mut mlib_slot_head {
    return (((*__param_s).clone.unwrap()((__param_s as *const c_void)) as *mut mlib_slot_head))

}

// contract: stored-unknown:0 — stores an argument; ownership not modeled
unsafe fn mlib_slot_release(__param_s: *mut mlib_slot_head) {
    (*__param_s).drop.unwrap()((__param_s as *mut c_void))

}

pub fn m_c0re_ctype_mlib_slot_tree1() {
    var __local_x: *mut mlib_slot_head


}

pub fn m_c0re_ctype_mlib_slot_tree2() {
    var __local_x: *mut mlib_slot_head


}

pub fn mlib_slot_tree_new_node() -> *mut mlib_slot_tree_node_s {
    var __local_n: *mut mlib_slot_tree_node_s = (((with_alloc(((sizeof[mlib_slot_tree_node_s]() as u64) as i64)) as *mut c_void) as *mut mlib_slot_tree_node_s))

    if ((if not (not (__local_n == null)): 1 else: 0) as i64) {
        abort()

    }

    ((unsafe *__local_n).next = ((null as *mut mlib_slot_tree_node_s)))

    ((unsafe *__local_n).prev = ((null as *mut mlib_slot_tree_node_s)))

    ((unsafe *__local_n).num = ((0 as i32)))

    return __local_n

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:read only
pub unsafe fn mlib_slot_tree_copy_node(__param_dst: *mut *mut mlib_slot_tree_node_s, __param_o: *mut mlib_slot_tree_node_s, __param_root: *mut mlib_slot_tree_node_s) -> Unit {
    var __local_n: *mut mlib_slot_tree_node_s = mlib_slot_tree_new_node()

    ((*__param_dst) = __local_n)


    var __local_num: i32 = (((*__param_o).mlib_slot_tree_get_num() as i32))

    if (*__param_o).mlib_slot_tree_is_leaf() {
        var __local_i: i32 = ((0 as i32))

        while (__local_i < __local_num) {
            ((*__local_n).key[__local_i] = mlib_slot_clone((*__param_o).key[__local_i]))





            (__local_i = __local_i + 1)

        }


    } else {
        if ((if not (__local_num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num != 0".ptr)
        } else {
            0
        }

        var __local_i_1: i32 = ((0 as i32))

        while (__local_i_1 < __local_num) {
            ((*__local_n).key[__local_i_1] = mlib_slot_clone((*__param_o).key[__local_i_1]))



            (__local_i_1 = __local_i_1 + 1)

        }


        var __local_i_2: i32 = ((0 as i32))

        while (__local_i_2 <= __local_num) {
            if ((if not ((*(&raw const (*__param_o).kind as *const mlib_slot_tree_kind_s)).node[__local_i_2] != __param_root): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"o->kind.node[i] != root".ptr)
            } else {
                0
            }

            mlib_slot_tree_copy_node(((&raw const (*__local_n).kind.node[__local_i_2] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s), (*(&raw const (*__param_o).kind as *const mlib_slot_tree_kind_s)).node[__local_i_2], __param_root)


            (__local_i_2 = __local_i_2 + 1)

        }


        var __local_i_3: i32 = ((0 as i32))

        while (__local_i_3 < __local_num) {
            var __local_current: *mut mlib_slot_tree_node_s = (*(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[__local_i_3]

            var __local_next: *mut mlib_slot_tree_node_s = (*(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[(__local_i_3 + 1)]

            ((*__local_current).next = __local_next)

            ((*__local_next).prev = __local_current)

            while (not (*__local_current).mlib_slot_tree_is_leaf()) {
                if ((if not (not (*__local_next).mlib_slot_tree_is_leaf()): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"!mlib_slot_tree_is_leaf(next)".ptr)
                } else {
                    0
                }

                (__local_current = (*(&raw const (*__local_current).kind as *const mlib_slot_tree_kind_s)).node[(*__local_current).num])

                (__local_next = (*(&raw const (*__local_next).kind as *const mlib_slot_tree_kind_s)).node[0])

                ((*__local_current).next = __local_next)

                ((*__local_next).prev = __local_current)

            }


            (__local_i_3 = __local_i_3 + 1)

        }


    }


    ((*__local_n).num = (*__param_o).num)

    loop {
        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((if __param_o == __param_root: __local_n else: __param_root) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((o==root) ? n : root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2: i32 = (*__local_n).num

        var __local_is_leaf2: bool = ((__local_num2 <= 0))

        (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

        if (__local_n == (if __param_o == __param_root: __local_n else: __param_root)) {
            var __ci_expr_logic_0: i32 = 0

            if (0 <= __local_num2) {
                (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


            if (__local_num2 == 0) {
                if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2: i32 = (((16 / 2) as i32))

            if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_1: i32 = 0

            if (__local_c2 <= __local_num2) {
                (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


        }

        var __local_i2: i32 = ((1 as i32))

        while (__local_i2 < __local_num2) {
            if ((if not ((*__local_n).key[(__local_i2 - 1)].cmp.unwrap()(((*__local_n).key[(__local_i2 - 1)] as *const c_void), ((*__local_n).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[i2-1])->cmp(((n)->key[i2-1]), ((n)->key[i2]))) < 0".ptr)
            } else {
                0
            }


            (__local_i2 = __local_i2 + 1)

        }


        if ((*__local_n).next != null) {
            if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            if ((if not ((*__local_n).key[(__local_num2 - 1)].cmp.unwrap()(((*__local_n).key[(__local_num2 - 1)] as *const c_void), ((*(*__local_n).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[num2-1])->cmp(((n)->key[num2-1]), ((n)->next->key[0]))) < 0".ptr)
            } else {
                0
            }

        }

        if ((*__local_n).prev != null) {
            if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev: i32 = (*(*__local_n).prev).num

            (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

            if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if ((if not ((*(*__local_n).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*__local_n).prev).key[(__local_num_prev - 1)] as *const c_void), ((*__local_n).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_copy_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->prev->key[num_prev-1])->cmp(((n)->prev->key[num_prev-1]), ((n)->key[0]))) < 0".ptr)
            } else {
                0
            }

        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_slot_tree_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_init_set(__param_b: *mut mlib_slot_tree_s, __param_o: *mut mlib_slot_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((o)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((o)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((o)->root+0)->key[i2-1])->cmp((((o)->root+0)->key[i2-1]), (((o)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((o)->root+0)->key[num2-1])->cmp((((o)->root+0)->key[num2-1]), (((o)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((o)->root+0)->prev->key[num_prev-1])->cmp((((o)->root+0)->prev->key[num_prev-1]), (((o)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(o)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(o)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(o)->root->num == (int) (o)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_b[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"b != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_cont: bool = true

    while __local_cont {

        mlib_slot_tree_copy_node(((&raw const (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s), (*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root, (*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).root)

        ((__param_b[0]).size = (*(&raw const (__param_o[0]) as *const mlib_slot_tree_s)).size)


        (__local_cont = false)

    }


    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_slot_tree_parent_it_s,unproved:1:read only,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_i_search_for_leaf(__param_pit: *mut mlib_slot_tree_parent_it_s, __param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) -> *mut mlib_slot_tree_node_s {
    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root

    var __local_np: i32 = ((0 as i32))

    while (not (*__local_n).mlib_slot_tree_is_leaf()) {
        if ((if not (__local_np <= ((((1 as u64) +% (((8 as u64) *% (sizeof[u64]() as u64)) as u64)) as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
        } else {
            0
        }

        var __local_i: i32

        var __local_hi: i32 = (*__local_n).num


        if ((if not (__local_hi > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"hi > 0".ptr)
        } else {
            0
        }

        (__local_i = ((0 as i32)))

        while (__local_i < __local_hi) {
            if ((*__param_key).cmp.unwrap()((__param_key as *const c_void), ((*__local_n).key[__local_i] as *const c_void)) <= 0) {
                break
            }


            (__local_i = __local_i + 1)

        }


        var __ci_expr_old_0: i32 = __local_np

        (__local_np = __local_np + 1)

        ((__param_pit[0]).parent[__ci_expr_old_0] = __local_n)


        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[__local_i])

        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"n != ((void*)0)".ptr)
        } else {
            0
        }

        loop {
            if ((if not (__local_n != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(n) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*__local_n).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (__local_n == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_1: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_2: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_2 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*__local_n).key[(__local_i2 - 1)].cmp.unwrap()(((*__local_n).key[(__local_i2 - 1)] as *const c_void), ((*__local_n).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[i2-1])->cmp(((n)->key[i2-1]), ((n)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*__local_n).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*__local_n).key[(__local_num2 - 1)].cmp.unwrap()(((*__local_n).key[(__local_num2 - 1)] as *const c_void), ((*(*__local_n).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[num2-1])->cmp(((n)->key[num2-1]), ((n)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*__local_n).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*__local_n).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*__local_n).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*__local_n).prev).key[(__local_num_prev - 1)] as *const c_void), ((*__local_n).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->prev->key[num_prev-1])->cmp(((n)->prev->key[num_prev-1]), ((n)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

    }

    ((__param_pit[0]).num = __local_np)

    return __local_n

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_get(__param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) -> *mut *mut mlib_slot_head {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __local_pit: [mlib_slot_tree_parent_it_s; 1]

    var __local_n: *mut mlib_slot_tree_node_s = mlib_slot_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_slot_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key)

    var __local_cmp: i32 = ((0 as i32))

    loop {
        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2_1: i32 = (*__local_n).num

        var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

        (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

        if (__local_n == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            var __ci_expr_logic_2: i32 = 0

            if (0 <= __local_num2_1) {
                (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


            if (__local_num2_1 == 0) {
                if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2_1: i32 = (((16 / 2) as i32))

            if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_3: i32 = 0

            if (__local_c2_1 <= __local_num2_1) {
                (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


        }

        var __local_i2_1: i32 = ((1 as i32))

        while (__local_i2_1 < __local_num2_1) {
            if ((if not ((*__local_n).key[(__local_i2_1 - 1)].cmp.unwrap()(((*__local_n).key[(__local_i2_1 - 1)] as *const c_void), ((*__local_n).key[__local_i2_1] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[i2-1])->cmp(((n)->key[i2-1]), ((n)->key[i2]))) < 0".ptr)
            } else {
                0
            }


            (__local_i2_1 = __local_i2_1 + 1)

        }


        if ((*__local_n).next != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            if ((if not ((*__local_n).key[(__local_num2_1 - 1)].cmp.unwrap()(((*__local_n).key[(__local_num2_1 - 1)] as *const c_void), ((*(*__local_n).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[num2-1])->cmp(((n)->key[num2-1]), ((n)->next->key[0]))) < 0".ptr)
            } else {
                0
            }

        }

        if ((*__local_n).prev != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev_1: i32 = (*(*__local_n).prev).num

            (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

            if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if ((if not ((*(*__local_n).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*__local_n).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*__local_n).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->prev->key[num_prev-1])->cmp(((n)->prev->key[num_prev-1]), ((n)->key[0]))) < 0".ptr)
            } else {
                0
            }

        }

        if not (false) {
            break
        }
    }

    var __local_i: i32 = ((0 as i32))

    while true {
        var __ci_expr_logic_4: i32 = 0

        if (__local_cmp >= 0) {
            (__ci_expr_logic_4 = (if __local_i < (0 - (*__local_n).num): 1 else: 0))
        }

        if (not __ci_expr_logic_4) {
            break
        }

        (__local_cmp = (((*__param_key).cmp.unwrap()((__param_key as *const c_void), ((*__local_n).key[__local_i] as *const c_void)) as i32)))

        if (__local_cmp == 0) {
            return (((&raw const (*__local_n).key[__local_i] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head))

        }

        (__local_i = __local_i + 1)

    }


    return ((null as *mut *mut mlib_slot_head))

}

@[repr(C)]
pub type mlib_slot_tree_cget_literal_anon = union { ptr: *mut *mut mlib_slot_head = null, cptr: *const *mut mlib_slot_head = null }
impl Copy for mlib_slot_tree_cget_literal_anon
// contract: unproved:0:returns a pointer the receiver's view cannot carry,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_cget(__param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) -> *const *mut mlib_slot_head {
    return (mlib_slot_tree_cget_literal_anon { ptr: mlib_slot_tree_get((&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key) } as mlib_slot_tree_cget_literal_anon).cptr

}

// contract: receiver-mut:mlib_slot_tree_node_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_i_search_and_insert_in_leaf(__param_n: *mut mlib_slot_tree_node_s, __param_key: *mut mlib_slot_head) -> i32 {
    if ((if not (*__param_n).mlib_slot_tree_is_leaf(): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_i_search_and_insert_in_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_i: i32

    var __local_num: i32 = (((*__param_n).mlib_slot_tree_get_num() as i32))


    if ((if not (__local_num <= 16): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_i_search_and_insert_in_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num <= 16".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num) {
        var __local_cmp: i32 = (((*__param_key).cmp.unwrap()((__param_key as *const c_void), ((*__param_n).key[__local_i] as *const c_void)) as i32))

        if (__local_cmp <= 0) {
            if ((if not (not (__local_cmp == 0)): 1 else: 0) as i64) {
                return -1

            }

            with_memmove(((((&raw const (*__param_n).key[(__local_i + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[__local_i] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

            break

        }


        (__local_i = __local_i + 1)

    }



    ((*__param_n).num = (*__param_n).num + -1)

    ((*__param_n).key[__local_i] = mlib_slot_clone(__param_key))



    return __local_i

}

// contract: receiver-mut:mlib_slot_tree_node_s,unproved:1:read only,unproved:2:read only
pub unsafe fn mlib_slot_tree_i_search_and_insert_in_node(__param_n: *mut mlib_slot_tree_node_s, __param_l: *mut mlib_slot_tree_node_s, __param_key: *mut *mut mlib_slot_head) -> i32 {
    if ((if not (not (*__param_n).mlib_slot_tree_is_leaf()): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_i_search_and_insert_in_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"!mlib_slot_tree_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_i: i32

    var __local_num: i32 = (((*__param_n).mlib_slot_tree_get_num() as i32))


    if ((if not (__local_num <= 16): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_i_search_and_insert_in_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num <= 16".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num) {
        if ((*(&raw const (*__param_n).kind as *const mlib_slot_tree_kind_s)).node[__local_i] == __param_l) {
            with_memmove(((((&raw const (*__param_n).key[(__local_i + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[__local_i] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (*__param_n).kind.node[(__local_i + 1)] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).kind.node[__local_i] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num - __local_i) + 1) as u32) as u64)) as u64) as i64))

            break

        }


        (__local_i = __local_i + 1)

    }



    ((*__param_n).num = (*__param_n).num + 1)

    if (*__param_l).mlib_slot_tree_is_leaf() {
        ((*__param_n).key[__local_i] = mlib_slot_clone((*__param_key)))


    } else {
        ((*__param_n).key[__local_i] = (*__param_key))


    }

    return __local_i

}

// contract: receiver-mut:mlib_slot_tree_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_push(__param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) -> Unit {
    var __local_pit__goto_34_1: [mlib_slot_tree_parent_it_s; 1]

    var __local_num2__goto_34_1: i32 = 0

    var __local_is_leaf2__goto_34_1: bool = false

    var __local_c2__goto_34_1: i32 = 0

    var __local_i2__goto_34_1: i32 = 0

    var __local_num_prev__goto_34_1: i32 = 0

    var __local_cont__goto_34_1: bool = false

    var __local_leaf__goto_34_1: *mut mlib_slot_tree_node_s = null

    var __local_nleaf__goto_34_1: *mut mlib_slot_tree_node_s = null

    var __local_key_ptr__goto_34_1: *mut *mut mlib_slot_head = null

    var __local_num__goto_34_1: i32 = 0

    var __local_nnum__goto_34_1: i32 = 0

    var __local_i__goto_34_1: i32 = 0

    var __local_parent__goto_34_1: *mut mlib_slot_tree_node_s = null

    var __local_nnp__goto_34_1: i32 = 0

    var __local_np__goto_34_1: i32 = 0

    var __local_nparent__goto_34_1: *mut mlib_slot_tree_node_s = null

    var __ci_expr_logic_0: i32 = 0

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_logic_6: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_8: i32 = 0

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_logic_10: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_logic_15: i32 = 0

    var __ci_expr_logic_14: i32 = 0

    var __ci_expr_logic_16: i32 = 0

    var __ci_expr_logic_17: i32 = 0

    var __ci_expr_logic_18: i32 = 0

    var __ci_expr_logic_19: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if false {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        (__local_cont__goto_34_1 = true)
        goto '__ci_bb_22
    }

    '__ci_bb_4 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_5 {
        if false {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_6 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_7 {
        (__ci_expr_logic_0 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_0 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_1 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_1 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_12
    }

    '__ci_bb_10 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_14
    }

    '__ci_bb_14 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_12
    }

    '__ci_bb_15 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        goto '__ci_bb_5
    }

    '__ci_bb_20 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        goto '__ci_bb_2
    }

    '__ci_bb_22 {
        if __local_cont__goto_34_1 {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_23 {
        (__local_leaf__goto_34_1 = mlib_slot_tree_i_search_for_leaf((&__local_pit__goto_34_1[0] as *mut mlib_slot_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key))
        (__local_i__goto_34_1 = ((mlib_slot_tree_i_search_and_insert_in_leaf(__local_leaf__goto_34_1, __param_key) as i32)))
        if (__local_i__goto_34_1 < 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_24 {
        (__local_cont__goto_34_1 = false)
        goto '__ci_bb_22
    }

    '__ci_bb_25 {
        return
    }

    '__ci_bb_26 {
        goto '__ci_bb_28
    }

    '__ci_bb_27 {
        ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size +% 1))
        (__local_num__goto_34_1 = (((0 - (*__local_leaf__goto_34_1).num) as i32)))
        if ((if not (__local_num__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num > 0".ptr)
        } else {
            0
        }
        if ((if not (not (__local_num__goto_34_1 <= 16)): 1 else: 0) as i64) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_31
    }

    '__ci_bb_29 {
        if false {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_30 {
        goto '__ci_bb_49
    }

    '__ci_bb_31 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_32 {
        if false {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_33 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_34 {
        (__ci_expr_logic_2 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_2 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_35 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_3 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_3 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_39
    }

    '__ci_bb_37 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_38
    }

    '__ci_bb_38 {
        goto '__ci_bb_36
    }

    '__ci_bb_39 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_40 {
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_41
    }

    '__ci_bb_41 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_39
    }

    '__ci_bb_42 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_45 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_46
    }

    '__ci_bb_46 {
        goto '__ci_bb_32
    }

    '__ci_bb_47 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_48
    }

    '__ci_bb_48 {
        goto '__ci_bb_29
    }

    '__ci_bb_49 {
        goto '__ci_bb_24
    }

    '__ci_bb_50 {
        goto '__ci_bb_52
    }

    '__ci_bb_51 {
        if ((if not (__local_num__goto_34_1 == (16 + 1)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num == 16+1".ptr)
        } else {
            0
        }
        (__local_nnum__goto_34_1 = ((((16 + 1) / 2) as i32)))
        (__local_num__goto_34_1 = ((((16 + 1) - __local_nnum__goto_34_1) as i32)))
        (__local_nleaf__goto_34_1 = mlib_slot_tree_new_node())
        with_memmove(((((&raw const (*__local_nleaf__goto_34_1).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (*__local_leaf__goto_34_1).key[__local_num__goto_34_1] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_nnum__goto_34_1 as u32) as u64)) as u64) as i64))
        ((*__local_leaf__goto_34_1).num = (((0 - __local_num__goto_34_1) as i32)))
        ((*__local_nleaf__goto_34_1).num = (((0 - __local_nnum__goto_34_1) as i32)))
        ((*__local_nleaf__goto_34_1).next = (*__local_leaf__goto_34_1).next)
        ((*__local_leaf__goto_34_1).next = __local_nleaf__goto_34_1)
        ((*__local_nleaf__goto_34_1).prev = __local_leaf__goto_34_1)
        if ((*__local_nleaf__goto_34_1).next != null) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_52 {
        goto '__ci_bb_55
    }

    '__ci_bb_53 {
        if false {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        goto '__ci_bb_49
    }

    '__ci_bb_55 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_56 {
        if false {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_57 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_58 {
        (__ci_expr_logic_4 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_4 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_59 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_5 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_5 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_60
    }

    '__ci_bb_60 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_63
    }

    '__ci_bb_61 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_62
    }

    '__ci_bb_62 {
        goto '__ci_bb_60
    }

    '__ci_bb_63 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_64 {
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_65
    }

    '__ci_bb_65 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_63
    }

    '__ci_bb_66 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_67 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_69 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_70
    }

    '__ci_bb_70 {
        goto '__ci_bb_56
    }

    '__ci_bb_71 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        goto '__ci_bb_53
    }

    '__ci_bb_73 {
        ((*(*__local_nleaf__goto_34_1).next).prev = __local_nleaf__goto_34_1)
        goto '__ci_bb_74
    }

    '__ci_bb_74 {
        goto '__ci_bb_75
    }

    '__ci_bb_75 {
        if ((if not (__local_leaf__goto_34_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(leaf) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*__local_leaf__goto_34_1).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (__local_leaf__goto_34_1 == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_76 {
        if false {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_91
    }

    '__ci_bb_78 {
        (__ci_expr_logic_6 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_6 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_6: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_79 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_7 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_7 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_7: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_80
    }

    '__ci_bb_80 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_83
    }

    '__ci_bb_81 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        goto '__ci_bb_80
    }

    '__ci_bb_83 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_84 {
        if ((if not ((*__local_leaf__goto_34_1).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*__local_leaf__goto_34_1).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*__local_leaf__goto_34_1).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((leaf)->key[i2-1])->cmp(((leaf)->key[i2-1]), ((leaf)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_85
    }

    '__ci_bb_85 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_83
    }

    '__ci_bb_86 {
        if ((*__local_leaf__goto_34_1).next != null) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_88
        }
    }

    '__ci_bb_87 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*__local_leaf__goto_34_1).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*__local_leaf__goto_34_1).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*__local_leaf__goto_34_1).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((leaf)->key[num2-1])->cmp(((leaf)->key[num2-1]), ((leaf)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_88
    }

    '__ci_bb_88 {
        if ((*__local_leaf__goto_34_1).prev != null) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_89 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*__local_leaf__goto_34_1).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*__local_leaf__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*__local_leaf__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*__local_leaf__goto_34_1).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((leaf)->prev->key[num_prev-1])->cmp(((leaf)->prev->key[num_prev-1]), ((leaf)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_90
    }

    '__ci_bb_90 {
        goto '__ci_bb_76
    }

    '__ci_bb_91 {
        if ((if not (__local_nleaf__goto_34_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(nleaf) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*__local_nleaf__goto_34_1).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (__local_nleaf__goto_34_1 == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_92 {
        if false {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_93
        }
    }

    '__ci_bb_93 {
        (__local_key_ptr__goto_34_1 = (((&raw const (*__local_leaf__goto_34_1).key[(__local_num__goto_34_1 - 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head)))
        goto '__ci_bb_107
    }

    '__ci_bb_94 {
        (__ci_expr_logic_8 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_8 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_8: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_95 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_9 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_9 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_9: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_96
    }

    '__ci_bb_96 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_99
    }

    '__ci_bb_97 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_98
    }

    '__ci_bb_98 {
        goto '__ci_bb_96
    }

    '__ci_bb_99 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_100 {
        if ((if not ((*__local_nleaf__goto_34_1).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*__local_nleaf__goto_34_1).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*__local_nleaf__goto_34_1).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((nleaf)->key[i2-1])->cmp(((nleaf)->key[i2-1]), ((nleaf)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_101
    }

    '__ci_bb_101 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_99
    }

    '__ci_bb_102 {
        if ((*__local_nleaf__goto_34_1).next != null) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_103 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*__local_nleaf__goto_34_1).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*__local_nleaf__goto_34_1).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*__local_nleaf__goto_34_1).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((nleaf)->key[num2-1])->cmp(((nleaf)->key[num2-1]), ((nleaf)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        if ((*__local_nleaf__goto_34_1).prev != null) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_105 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*__local_nleaf__goto_34_1).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*__local_nleaf__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*__local_nleaf__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*__local_nleaf__goto_34_1).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((nleaf)->prev->key[num_prev-1])->cmp(((nleaf)->prev->key[num_prev-1]), ((nleaf)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_106
    }

    '__ci_bb_106 {
        goto '__ci_bb_92
    }

    '__ci_bb_107 {
        if true {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_108 {
        if ((*(&raw const __local_pit__goto_34_1[0] as *const mlib_slot_tree_parent_it_s)).num == 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_109 {
        goto '__ci_bb_49
    }

    '__ci_bb_110 {
        (__local_parent__goto_34_1 = mlib_slot_tree_new_node())
        ((*__local_parent__goto_34_1).num = ((1 as i32)))
        if (*__local_leaf__goto_34_1).mlib_slot_tree_is_leaf() {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_111 {
        (__local_pit__goto_34_1[0].num = (*(&raw const __local_pit__goto_34_1[0] as *const mlib_slot_tree_parent_it_s)).num - 1)
        (__local_parent__goto_34_1 = (*(&raw const __local_pit__goto_34_1[0] as *const mlib_slot_tree_parent_it_s)).parent[(*(&raw const __local_pit__goto_34_1[0] as *const mlib_slot_tree_parent_it_s)).num])
        (__local_i__goto_34_1 = ((mlib_slot_tree_i_search_and_insert_in_node(__local_parent__goto_34_1, __local_leaf__goto_34_1, __local_key_ptr__goto_34_1) as i32)))
        ((*__local_parent__goto_34_1).kind.node[__local_i__goto_34_1] = __local_leaf__goto_34_1)
        ((*__local_parent__goto_34_1).kind.node[(__local_i__goto_34_1 + 1)] = __local_nleaf__goto_34_1)
        if ((if not (not ((*__local_parent__goto_34_1).num <= 16)): 1 else: 0) as i64) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_112 {
        ((*__local_parent__goto_34_1).key[0] = mlib_slot_clone((*__local_key_ptr__goto_34_1)))
        goto '__ci_bb_114
    }

    '__ci_bb_113 {
        ((*__local_parent__goto_34_1).key[0] = (*__local_key_ptr__goto_34_1))
        goto '__ci_bb_114
    }

    '__ci_bb_114 {
        ((*__local_parent__goto_34_1).kind.node[0] = __local_leaf__goto_34_1)
        ((*__local_parent__goto_34_1).kind.node[1] = __local_nleaf__goto_34_1)
        ((__param_b[0]).root = __local_parent__goto_34_1)
        goto '__ci_bb_115
    }

    '__ci_bb_115 {
        goto '__ci_bb_118
    }

    '__ci_bb_116 {
        if false {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_117 {
        goto '__ci_bb_49
    }

    '__ci_bb_118 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_119 {
        if false {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_120 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_121 {
        (__ci_expr_logic_10 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_10 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_10: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_122 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_11 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_11 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_11: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_123
    }

    '__ci_bb_123 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_126
    }

    '__ci_bb_124 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_125
    }

    '__ci_bb_125 {
        goto '__ci_bb_123
    }

    '__ci_bb_126 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_127 {
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_128
    }

    '__ci_bb_128 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_126
    }

    '__ci_bb_129 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_130 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_131
    }

    '__ci_bb_131 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_132 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_133
    }

    '__ci_bb_133 {
        goto '__ci_bb_119
    }

    '__ci_bb_134 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        goto '__ci_bb_116
    }

    '__ci_bb_136 {
        goto '__ci_bb_138
    }

    '__ci_bb_137 {
        if ((if not ((*__local_parent__goto_34_1).num == (16 + 1)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"parent->num == 16+1".ptr)
        } else {
            0
        }
        (__local_nnp__goto_34_1 = (((16 / 2) as i32)))
        (__local_np__goto_34_1 = (((16 - __local_nnp__goto_34_1) as i32)))
        (__ci_expr_logic_15 = 0)
        (__ci_expr_logic_14 = 0)
        if (__local_nnp__goto_34_1 > 0) {
            (__ci_expr_logic_14 = (if __local_np__goto_34_1 > 0: 1 else: 0))
        }
        if __ci_expr_logic_14 {
            (__ci_expr_logic_15 = (if ((__local_nnp__goto_34_1 + __local_np__goto_34_1) + 1) == (16 + 1): 1 else: 0))
        }
        if ((if not __ci_expr_logic_15: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"nnp > 0 && np > 0 && nnp+np+1 == 16+1".ptr)
        } else {
            0
        }
        (__local_nparent__goto_34_1 = mlib_slot_tree_new_node())
        with_memmove(((((&raw const (*__local_nparent__goto_34_1).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (*__local_parent__goto_34_1).key[(__local_np__goto_34_1 + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_nnp__goto_34_1 as u32) as u64)) as u64) as i64))
        with_memmove(((((&raw const (*__local_nparent__goto_34_1).kind.node[0] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_parent__goto_34_1).kind.node[(__local_np__goto_34_1 + 1)] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_nnp__goto_34_1 + 1) as u32) as u64)) as u64) as i64))
        ((*__local_parent__goto_34_1).num = __local_np__goto_34_1)
        ((*__local_nparent__goto_34_1).num = __local_nnp__goto_34_1)
        ((*__local_nparent__goto_34_1).next = (*__local_parent__goto_34_1).next)
        ((*__local_parent__goto_34_1).next = __local_nparent__goto_34_1)
        ((*__local_nparent__goto_34_1).prev = __local_parent__goto_34_1)
        if ((*__local_nparent__goto_34_1).next != null) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_138 {
        goto '__ci_bb_141
    }

    '__ci_bb_139 {
        if false {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_140 {
        goto '__ci_bb_49
    }

    '__ci_bb_141 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_142 {
        if false {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_143 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_144 {
        (__ci_expr_logic_12 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_12 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_12: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_148
        }
    }

    '__ci_bb_145 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_13 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_13 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_13: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_146
    }

    '__ci_bb_146 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_149
    }

    '__ci_bb_147 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_148
    }

    '__ci_bb_148 {
        goto '__ci_bb_146
    }

    '__ci_bb_149 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_150 {
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_151
    }

    '__ci_bb_151 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_149
    }

    '__ci_bb_152 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_153 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_155 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_156
    }

    '__ci_bb_156 {
        goto '__ci_bb_142
    }

    '__ci_bb_157 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_158
    }

    '__ci_bb_158 {
        goto '__ci_bb_139
    }

    '__ci_bb_159 {
        ((*(*__local_nparent__goto_34_1).next).prev = __local_nparent__goto_34_1)
        goto '__ci_bb_160
    }

    '__ci_bb_160 {
        goto '__ci_bb_161
    }

    '__ci_bb_161 {
        if ((if not (__local_parent__goto_34_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(parent) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*__local_parent__goto_34_1).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (__local_parent__goto_34_1 == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_162 {
        if false {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_163 {
        goto '__ci_bb_177
    }

    '__ci_bb_164 {
        (__ci_expr_logic_16 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_16 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_16: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_165 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_17 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_17 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_17: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_166
    }

    '__ci_bb_166 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_169
    }

    '__ci_bb_167 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_168
    }

    '__ci_bb_168 {
        goto '__ci_bb_166
    }

    '__ci_bb_169 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_170
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_170 {
        if ((if not ((*__local_parent__goto_34_1).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*__local_parent__goto_34_1).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*__local_parent__goto_34_1).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((parent)->key[i2-1])->cmp(((parent)->key[i2-1]), ((parent)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_171
    }

    '__ci_bb_171 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_169
    }

    '__ci_bb_172 {
        if ((*__local_parent__goto_34_1).next != null) {
            goto '__ci_bb_173
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_173 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*__local_parent__goto_34_1).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*__local_parent__goto_34_1).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*__local_parent__goto_34_1).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((parent)->key[num2-1])->cmp(((parent)->key[num2-1]), ((parent)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_174
    }

    '__ci_bb_174 {
        if ((*__local_parent__goto_34_1).prev != null) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_175 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*__local_parent__goto_34_1).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*__local_parent__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*__local_parent__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*__local_parent__goto_34_1).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((parent)->prev->key[num_prev-1])->cmp(((parent)->prev->key[num_prev-1]), ((parent)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_176
    }

    '__ci_bb_176 {
        goto '__ci_bb_162
    }

    '__ci_bb_177 {
        if ((if not (__local_nparent__goto_34_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(nparent) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_34_1 = (*__local_nparent__goto_34_1).num)
        (__local_is_leaf2__goto_34_1 = ((__local_num2__goto_34_1 <= 0)))
        (__local_num2__goto_34_1 = (((if __local_num2__goto_34_1 < 0: ((0 - __local_num2__goto_34_1) as i32) else: __local_num2__goto_34_1) as i32)))
        if (__local_nparent__goto_34_1 == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_178 {
        if false {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_179 {
        (__local_key_ptr__goto_34_1 = (((&raw const (*__local_parent__goto_34_1).key[__local_np__goto_34_1] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head)))
        (__local_leaf__goto_34_1 = __local_parent__goto_34_1)
        (__local_nleaf__goto_34_1 = __local_nparent__goto_34_1)
        goto '__ci_bb_107
    }

    '__ci_bb_180 {
        (__ci_expr_logic_18 = 0)
        if (0 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_18 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_18: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_34_1 == 0) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_181 {
        (__local_c2__goto_34_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_34_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_19 = 0)
        if (__local_c2__goto_34_1 <= __local_num2__goto_34_1) {
            (__ci_expr_logic_19 = (if __local_num2__goto_34_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_19: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_182
    }

    '__ci_bb_182 {
        (__local_i2__goto_34_1 = ((1 as i32)))
        goto '__ci_bb_185
    }

    '__ci_bb_183 {
        if ((if not __local_is_leaf2__goto_34_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_184
    }

    '__ci_bb_184 {
        goto '__ci_bb_182
    }

    '__ci_bb_185 {
        if (__local_i2__goto_34_1 < __local_num2__goto_34_1) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_186 {
        if ((if not ((*__local_nparent__goto_34_1).key[(__local_i2__goto_34_1 - 1)].cmp.unwrap()(((*__local_nparent__goto_34_1).key[(__local_i2__goto_34_1 - 1)] as *const c_void), ((*__local_nparent__goto_34_1).key[__local_i2__goto_34_1] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((nparent)->key[i2-1])->cmp(((nparent)->key[i2-1]), ((nparent)->key[i2]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_187
    }

    '__ci_bb_187 {
        (__local_i2__goto_34_1 = __local_i2__goto_34_1 + 1)
        goto '__ci_bb_185
    }

    '__ci_bb_188 {
        if ((*__local_nparent__goto_34_1).next != null) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_189 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*__local_nparent__goto_34_1).key[(__local_num2__goto_34_1 - 1)].cmp.unwrap()(((*__local_nparent__goto_34_1).key[(__local_num2__goto_34_1 - 1)] as *const c_void), ((*(*__local_nparent__goto_34_1).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((nparent)->key[num2-1])->cmp(((nparent)->key[num2-1]), ((nparent)->next->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_190
    }

    '__ci_bb_190 {
        if ((*__local_nparent__goto_34_1).prev != null) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_191 {
        if ((if not (__local_num2__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_34_1 = (*(*__local_nparent__goto_34_1).prev).num)
        (__local_num_prev__goto_34_1 = (((if __local_num_prev__goto_34_1 < 0: ((0 - __local_num_prev__goto_34_1) as i32) else: __local_num_prev__goto_34_1) as i32)))
        if ((if not (__local_num_prev__goto_34_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((*(*__local_nparent__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)].cmp.unwrap()(((*(*__local_nparent__goto_34_1).prev).key[(__local_num_prev__goto_34_1 - 1)] as *const c_void), ((*__local_nparent__goto_34_1).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_push".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((nparent)->prev->key[num_prev-1])->cmp(((nparent)->prev->key[num_prev-1]), ((nparent)->key[0]))) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_192
    }

    '__ci_bb_192 {
        goto '__ci_bb_178
    }

    __ci_unreachable()

}

// contract: receiver-mut:mlib_slot_tree_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_safe_get(__param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) -> *mut *mut mlib_slot_head {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_safe_get".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __local_ret: *mut *mut mlib_slot_head = mlib_slot_tree_get((&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key)

    if (__local_ret == null) {
        mlib_slot_tree_push((&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key)

        (__local_ret = mlib_slot_tree_get((&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key))

    }

    return __local_ret

}

// contract: receiver-mut:mlib_slot_tree_node_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_i_search_and_remove_in_leaf(__param_n: *mut mlib_slot_tree_node_s, __param_key: *mut mlib_slot_head) -> i32 {
    if ((if not (*__param_n).mlib_slot_tree_is_leaf(): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_i_search_and_remove_in_leaf".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_num: i32 = (((*__param_n).mlib_slot_tree_get_num() as i32))

    var __local_i: i32 = ((0 as i32))

    while (__local_i < __local_num) {
        var __local_cmp: i32 = (((*__param_key).cmp.unwrap()((__param_key as *const c_void), ((*__param_n).key[__local_i] as *const c_void)) as i32))

        if (__local_cmp == 0) {
            mlib_slot_release((*__param_n).key[__local_i])

            with_memmove(((((&raw const (*__param_n).key[__local_i] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[(__local_i + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num - 1) - __local_i) as u32) as u64)) as u64) as i64))

            ((*__param_n).num = (*__param_n).num - -1)

            return __local_i

        }


        (__local_i = __local_i + 1)

    }


    return -1

}

// contract: receiver:mlib_slot_tree_node_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_i_search_for_node(__param_parent: *mut mlib_slot_tree_node_s, __param_child: *mut mlib_slot_tree_node_s) -> i32 {
    if ((if not (not (*__param_parent).mlib_slot_tree_is_leaf()): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_i_search_for_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"!mlib_slot_tree_is_leaf(parent)".ptr)
    } else {
        0
    }

    var __local_num: i32 = (((*__param_parent).mlib_slot_tree_get_num() as i32))

    var __local_i: i32 = ((0 as i32))

    while (__local_i <= __local_num) {
        if ((*(&raw const (*__param_parent).kind as *const mlib_slot_tree_kind_s)).node[__local_i] == __param_child) {
            return __local_i
        }


        (__local_i = __local_i + 1)

    }


    return -1

}

// contract: receiver-mut:mlib_slot_tree_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_erase(__param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) -> bool {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __local_pit: [mlib_slot_tree_parent_it_s; 1]

    var __local_leaf: *mut mlib_slot_tree_node_s = mlib_slot_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_slot_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key)

    var __local_k: i32 = ((mlib_slot_tree_i_search_and_remove_in_leaf(__local_leaf, __param_key) as i32))

    if (__local_k < 0) {
        return ((false as bool))
    }

    ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size -% 1))

    var __ci_expr_logic_2: i32

    if ((if not (not ((*__local_leaf).mlib_slot_tree_get_num() >= (16 / 2))): 1 else: 0) as i64) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num == 0: 1 else: 0))
    }

    if __ci_expr_logic_2 {
        return ((true as bool))
    }


    if ((if not ((*__local_leaf).mlib_slot_tree_get_num() == ((16 / 2) - 1)): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_get_num(leaf) == 16/2-1".ptr)
    } else {
        0
    }

    var __local_pass1: bool = true

    while true {
        if ((if not ((*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"pit->num > 0".ptr)
        } else {
            0
        }

        var __local_parent: *mut mlib_slot_tree_node_s = with 0 as __ci_expr_seq_155 {
            (__local_pit[0].num = (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num - 1)
            (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).parent[(*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num]
        }

        if ((if not (__local_parent != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"parent != ((void*)0)".ptr)
        } else {
            0
        }

        (__local_k = ((mlib_slot_tree_i_search_for_node(__local_parent, __local_leaf) as i32)))

        if ((if not (__local_k >= 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"k >= 0".ptr)
        } else {
            0
        }

        var __ci_expr_logic_3: i32 = 0

        if (__local_k > 0) {
            (__ci_expr_logic_3 = (if (*((*(&raw const (*__local_parent).kind as *const mlib_slot_tree_kind_s)).node[(__local_k - 1)] as *mut mlib_slot_tree_node_s)).mlib_slot_tree_get_num() > (16 / 2): 1 else: 0))
        }

        if __ci_expr_logic_3 {
            (*__local_parent).mlib_slot_tree_i_left_shift(((__local_k - 1) as i32))

            return ((true as bool))

        }
        var __ci_expr_logic_4: i32 = 0

        if (__local_k < (*__local_parent).mlib_slot_tree_get_num()) {
            (__ci_expr_logic_4 = (if (*((*(&raw const (*__local_parent).kind as *const mlib_slot_tree_kind_s)).node[(__local_k + 1)] as *mut mlib_slot_tree_node_s)).mlib_slot_tree_get_num() > (16 / 2): 1 else: 0))
        }

        if __ci_expr_logic_4 {
            (*__local_parent).mlib_slot_tree_i_right_shift(__local_k)

            return ((true as bool))

        }



        if (__local_k == (*__local_parent).mlib_slot_tree_get_num()) {
            (__local_k = __local_k - 1)
        }

        var __ci_expr_logic_5: i32 = 0

        if (__local_k >= 0) {
            (__ci_expr_logic_5 = (if __local_k < (*__local_parent).mlib_slot_tree_get_num(): 1 else: 0))
        }

        if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_erase".ptr, c"facade_shapes.c".ptr, (34 as i32), c"k >= 0 && k < mlib_slot_tree_get_num(parent)".ptr)
        } else {
            0
        }


        (*__local_parent).mlib_slot_tree_i_merge_node(__local_k, __local_pass1)

        if ((*__local_parent).mlib_slot_tree_get_num() >= (16 / 2)) {
            return ((true as bool))
        }

        if ((*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num == 0) {
            if ((*__local_parent).mlib_slot_tree_get_num() == 0) {
                ((__param_b[0]).root = (*(&raw const (*__local_parent).kind as *const mlib_slot_tree_kind_s)).node[0])

                with_free(((__local_parent as *mut c_void) as *mut u8))

            }

            return ((true as bool))

        }

        (__local_leaf = __local_parent)

        (__local_pass1 = false)

    }

}

// contract: unproved:0:out-parameter written conditionally,unproved:1:out-parameter written conditionally,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_pop_at(__param_ptr: *mut *mut mlib_slot_head, __param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) -> bool {
    if (__param_ptr != null) {
        var __local_ref: *mut *mut mlib_slot_head = mlib_slot_tree_get((&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key)

        if (__local_ref == null) {
            return ((false as bool))

        }

        mlib_slot_release((*__param_ptr))

        ((*__param_ptr) = mlib_slot_clone((*__local_ref)))


    }

    return mlib_slot_tree_erase((&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_slot_tree_min(__param_b: *mut mlib_slot_tree_s) -> *mut *mut mlib_slot_head {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_min".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not (not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size == 0)): 1 else: 0) as i64) {
        return ((null as *mut *mut mlib_slot_head))
    }

    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root

    while (not (*__local_n).mlib_slot_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[0])

    }

    return (((&raw const (*__local_n).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_slot_tree_max(__param_b: *mut mlib_slot_tree_s) -> *mut *mut mlib_slot_head {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_max".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not (not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size == 0)): 1 else: 0) as i64) {
        return ((null as *mut *mut mlib_slot_head))
    }

    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root

    while (not (*__local_n).mlib_slot_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[(*__local_n).num])

    }

    return (((&raw const (*__local_n).key[((0 - (*__local_n).num) - 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head))

}

@[repr(C)]
pub type mlib_slot_tree_cmin_literal_anon = union { ptr: *mut *mut mlib_slot_head = null, cptr: *const *mut mlib_slot_head = null }
impl Copy for mlib_slot_tree_cmin_literal_anon
// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_slot_tree_cmin(__param_tree: *mut mlib_slot_tree_s) -> *const *mut mlib_slot_head {
    return (mlib_slot_tree_cmin_literal_anon { ptr: mlib_slot_tree_min((&(__param_tree[0]) as *mut mlib_slot_tree_s)) } as mlib_slot_tree_cmin_literal_anon).cptr

}

@[repr(C)]
pub type mlib_slot_tree_cmax_literal_anon = union { ptr: *mut *mut mlib_slot_head = null, cptr: *const *mut mlib_slot_head = null }
impl Copy for mlib_slot_tree_cmax_literal_anon
// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_slot_tree_cmax(__param_tree: *mut mlib_slot_tree_s) -> *const *mut mlib_slot_head {
    return (mlib_slot_tree_cmax_literal_anon { ptr: mlib_slot_tree_max((&(__param_tree[0]) as *mut mlib_slot_tree_s)) } as mlib_slot_tree_cmax_literal_anon).cptr

}

// contract: receiver-mut:mlib_slot_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_slot_tree_init_move(__param_b: *mut mlib_slot_tree_s, __param_ref: *mut mlib_slot_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((ref)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((ref)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((ref)->root+0)->key[i2-1])->cmp((((ref)->root+0)->key[i2-1]), (((ref)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((ref)->root+0)->key[num2-1])->cmp((((ref)->root+0)->key[num2-1]), (((ref)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((ref)->root+0)->prev->key[num_prev-1])->cmp((((ref)->root+0)->prev->key[num_prev-1]), (((ref)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(ref)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(ref)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(ref)->root->num == (int) (ref)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __ci_expr_logic_2: i32 = 0

    if ((&(__param_b[0]) as *mut c_void) != null) {
        (__ci_expr_logic_2 = (if (&(__param_b[0]) as *mut mlib_slot_tree_s) != (&(__param_ref[0]) as *mut mlib_slot_tree_s): 1 else: 0))
    }

    if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"b != ((void*)0) && b != ref".ptr)
    } else {
        0
    }


    ((__param_b[0]).size = (*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).size)

    ((__param_b[0]).root = (*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root)

    ((__param_ref[0]).root = ((null as *mut mlib_slot_tree_node_s)))

    ((__param_ref[0]).size = ((1 as u64)))

    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_3: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_4: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_4 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_slot_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_slot_tree_move(__param_b: *mut mlib_slot_tree_s, __param_ref: *mut mlib_slot_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((ref)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((ref)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] as *const c_void), ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((ref)->root+0)->key[i2-1])->cmp((((ref)->root+0)->key[i2-1]), (((ref)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((ref)->root+0)->key[num2-1])->cmp((((ref)->root+0)->key[num2-1]), (((ref)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((ref)->root+0)->prev->key[num_prev-1])->cmp((((ref)->root+0)->prev->key[num_prev-1]), (((ref)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(ref)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(ref)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_ref[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(ref)->root->num == (int) (ref)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_b[0]) as *mut mlib_slot_tree_s) != (&(__param_ref[0]) as *mut mlib_slot_tree_s)): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"b != ref".ptr)
    } else {
        0
    }

    (*(&(__param_b[0]) as *mut mlib_slot_tree_s)).mlib_slot_tree_clear()

    mlib_slot_tree_init_move((&(__param_b[0]) as *mut mlib_slot_tree_s), (&(__param_ref[0]) as *mut mlib_slot_tree_s))

    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_2: bool = ((__local_num2_2 <= 0))

            (__local_num2_2 = (((if __local_num2_2 < 0: ((0 - __local_num2_2) as i32) else: __local_num2_2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_4: i32 = 0

                if (0 <= __local_num2_2) {
                    (__ci_expr_logic_4 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_2 == 0) {
                    if ((if not __local_is_leaf2_2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_5: i32 = 0

                if (__local_c2_2 <= __local_num2_2) {
                    (__ci_expr_logic_5 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_2: i32 = ((1 as i32))

            while (__local_i2_2 < __local_num2_2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_2 = __local_i2_2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_2: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_2 = (((if __local_num_prev_2 < 0: ((0 - __local_num_prev_2) as i32) else: __local_num_prev_2) as i32)))

                if ((if not (__local_num_prev_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_move".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_slot_tree_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_set(__param_b: *mut mlib_slot_tree_s, __param_o: *mut mlib_slot_tree_s) {
    var __local_tmp: [mlib_slot_tree_s; 1]

    var __local_cont: bool = true

    while __local_cont {
        mlib_slot_tree_init_set((&__local_tmp[0] as *mut mlib_slot_tree_s), (&(__param_o[0]) as *mut mlib_slot_tree_s))

        mlib_slot_tree_move((&(__param_b[0]) as *mut mlib_slot_tree_s), (&__local_tmp[0] as *mut mlib_slot_tree_s))


        (__local_cont = false)

    }


}

// contract: receiver-mut:mlib_slot_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_slot_tree_swap(__param_tree1: *mut mlib_slot_tree_s, __param_tree2: *mut mlib_slot_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree1)->root+0)->key[i2-1])->cmp((((tree1)->root+0)->key[i2-1]), (((tree1)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree1)->root+0)->key[num2-1])->cmp((((tree1)->root+0)->key[num2-1]), (((tree1)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree1)->root+0)->prev->key[num_prev-1])->cmp((((tree1)->root+0)->prev->key[num_prev-1]), (((tree1)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(tree1)->root->num == (int) (tree1)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] as *const c_void), ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree2)->root+0)->key[i2-1])->cmp((((tree2)->root+0)->key[i2-1]), (((tree2)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree2)->root+0)->key[num2-1])->cmp((((tree2)->root+0)->key[num2-1]), (((tree2)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree2)->root+0)->prev->key[num_prev-1])->cmp((((tree2)->root+0)->prev->key[num_prev-1]), (((tree2)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(tree2)->root->num == (int) (tree2)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {
        var __local__tmp: u64 = (*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).size

        ((__param_tree1[0]).size = (*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).size)

        ((__param_tree2[0]).size = __local__tmp)

        if not (false) {
            break
        }
    }

    loop {
        var __local__tmp_1: *mut mlib_slot_tree_node_s = (*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root

        ((__param_tree1[0]).root = (*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root)

        ((__param_tree2[0]).root = __local__tmp_1)

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_2: i32 = (*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_2: bool = ((__local_num2_2 <= 0))

            (__local_num2_2 = (((if __local_num2_2 < 0: ((0 - __local_num2_2) as i32) else: __local_num2_2) as i32)))

            if (((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_4: i32 = 0

                if (0 <= __local_num2_2) {
                    (__ci_expr_logic_4 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_2 == 0) {
                    if ((if not __local_is_leaf2_2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_5: i32 = 0

                if (__local_c2_2 <= __local_num2_2) {
                    (__ci_expr_logic_5 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_2: i32 = ((1 as i32))

            while (__local_i2_2 < __local_num2_2) {
                if ((if not ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)] as *const c_void), ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree1)->root+0)->key[i2-1])->cmp((((tree1)->root+0)->key[i2-1]), (((tree1)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_2 = __local_i2_2 + 1)

            }


            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree1)->root+0)->key[num2-1])->cmp((((tree1)->root+0)->key[num2-1]), (((tree1)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_2: i32 = (*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_2 = (((if __local_num_prev_2 < 0: ((0 - __local_num_prev_2) as i32) else: __local_num_prev_2) as i32)))

                if ((if not (__local_num_prev_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)] as *const c_void), ((*((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree1)->root+0)->prev->key[num_prev-1])->cmp((((tree1)->root+0)->prev->key[num_prev-1]), (((tree1)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_tree1[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(tree1)->root->num == (int) (tree1)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((tree2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_3: i32 = (*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_3: bool = ((__local_num2_3 <= 0))

            (__local_num2_3 = (((if __local_num2_3 < 0: ((0 - __local_num2_3) as i32) else: __local_num2_3) as i32)))

            if (((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_6: i32 = 0

                if (0 <= __local_num2_3) {
                    (__ci_expr_logic_6 = (if __local_num2_3 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_6: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_3 == 0) {
                    if ((if not __local_is_leaf2_3: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_3: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_3 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_7: i32 = 0

                if (__local_c2_3 <= __local_num2_3) {
                    (__ci_expr_logic_7 = (if __local_num2_3 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_7: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_3: i32 = ((1 as i32))

            while (__local_i2_3 < __local_num2_3) {
                if ((if not ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_3 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_3 - 1)] as *const c_void), ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_3] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree2)->root+0)->key[i2-1])->cmp((((tree2)->root+0)->key[i2-1]), (((tree2)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_3 = __local_i2_3 + 1)

            }


            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_3 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_3 - 1)].cmp.unwrap()(((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_3 - 1)] as *const c_void), ((*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree2)->root+0)->key[num2-1])->cmp((((tree2)->root+0)->key[num2-1]), (((tree2)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_3 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_3: i32 = (*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_3 = (((if __local_num_prev_3 < 0: ((0 - __local_num_prev_3) as i32) else: __local_num_prev_3) as i32)))

                if ((if not (__local_num_prev_3 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_3 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_3 - 1)] as *const c_void), ((*((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((tree2)->root+0)->prev->key[num_prev-1])->cmp((((tree2)->root+0)->prev->key[num_prev-1]), (((tree2)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(tree2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_tree2[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_swap".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(tree2)->root->num == (int) (tree2)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_slot_tree_it_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_it(__param_it_: *mut mlib_slot_tree_it_s, __param_b: *mut mlib_slot_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_it".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root

    while (not (*__local_n).mlib_slot_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[0])

    }

    ((__param_it_[0]).node = __local_n)

    ((__param_it_[0]).idx = ((0 as i32)))

}

// contract: receiver-mut:mlib_slot_tree_it_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_it_end(__param_it_: *mut mlib_slot_tree_it_s, __param_b: *mut mlib_slot_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_it_end".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root

    while (not (*__local_n).mlib_slot_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[(*__local_n).num])

    }

    ((__param_it_[0]).node = __local_n)

    ((__param_it_[0]).idx = (((0 - (*__local_n).num) as i32)))

}

// contract: receiver-mut:mlib_slot_tree_it_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_it_set(__param_itd: *mut mlib_slot_tree_it_s, __param_its: *mut mlib_slot_tree_it_s) {
    var __ci_expr_logic_0: i32 = 0

    if ((&(__param_itd[0]) as *mut c_void) != null) {
        (__ci_expr_logic_0 = (if (&(__param_its[0]) as *mut c_void) != null: 1 else: 0))
    }

    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_it_set".ptr, c"facade_shapes.c".ptr, (34 as i32), c"itd != ((void*)0) && its != ((void*)0)".ptr)
    } else {
        0
    }


    ((__param_itd[0]).node = (*(&raw const (__param_its[0]) as *const mlib_slot_tree_it_s)).node)

    ((__param_itd[0]).idx = (*(&raw const (__param_its[0]) as *const mlib_slot_tree_it_s)).idx)

}

// contract: receiver:mlib_slot_tree_it_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_it_equal_p(__param_it1: *mut mlib_slot_tree_it_s, __param_it2: *mut mlib_slot_tree_it_s) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((*(&raw const (__param_it1[0]) as *const mlib_slot_tree_it_s)).node == (*(&raw const (__param_it2[0]) as *const mlib_slot_tree_it_s)).node) {
        (__ci_expr_logic_0 = (if (*(&raw const (__param_it1[0]) as *const mlib_slot_tree_it_s)).idx == (*(&raw const (__param_it2[0]) as *const mlib_slot_tree_it_s)).idx: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver-mut:mlib_slot_tree_it_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_it_last(__param_it_: *mut mlib_slot_tree_it_s, __param_b: *mut mlib_slot_tree_s) {
    mlib_slot_tree_it_end((&(__param_it_[0]) as *mut mlib_slot_tree_it_s), (&(__param_b[0]) as *mut mlib_slot_tree_s))

    (*(&(__param_it_[0]) as *mut mlib_slot_tree_it_s)).mlib_slot_tree_previous()

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_slot_tree_ref(__param_it_: *mut mlib_slot_tree_it_s) -> *mut *mut mlib_slot_head {
    var __ci_expr_logic_0: i32 = 0

    if ((&(__param_it_[0]) as *mut c_void) != null) {
        (__ci_expr_logic_0 = (if (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node != null: 1 else: 0))
    }

    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_ref".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
    } else {
        0
    }


    if ((if not (*((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node)).mlib_slot_tree_is_leaf(): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_ref".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(it->node)".ptr)
    } else {
        0
    }

    var __ci_expr_logic_1: i32 = 0

    if ((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx >= 0) {
        (__ci_expr_logic_1 = (if (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx <= (0 - (*(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).num): 1 else: 0))
    }

    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_ref".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it->idx >= 0 && it->idx <= -it->node->num".ptr)
    } else {
        0
    }


    return (((&raw const (*(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).key[(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head))

}

@[repr(C)]
pub type mlib_slot_tree_cref_literal_anon = union { ptr: *mut *mut mlib_slot_head = null, cptr: *const *mut mlib_slot_head = null }
impl Copy for mlib_slot_tree_cref_literal_anon
// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_slot_tree_cref(__param_it_: *mut mlib_slot_tree_it_s) -> *const *mut mlib_slot_head {
    return (mlib_slot_tree_cref_literal_anon { ptr: mlib_slot_tree_ref((&(__param_it_[0]) as *mut mlib_slot_tree_it_s)) } as mlib_slot_tree_cref_literal_anon).cptr

}

// contract: receiver-mut:mlib_slot_tree_it_s,unproved:1:read only,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_it_from(__param_it_: *mut mlib_slot_tree_it_s, __param_b: *mut mlib_slot_tree_s, __param_key: *mut mlib_slot_head) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_pit: [mlib_slot_tree_parent_it_s; 1]

    var __local_n: *mut mlib_slot_tree_node_s = mlib_slot_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_slot_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_slot_tree_s), __param_key)

    ((__param_it_[0]).node = __local_n)

    var __local_i: i32

    loop {
        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2_1: i32 = (*__local_n).num

        var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

        (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

        if (__local_n == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
            var __ci_expr_logic_2: i32 = 0

            if (0 <= __local_num2_1) {
                (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


            if (__local_num2_1 == 0) {
                if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2_1: i32 = (((16 / 2) as i32))

            if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_3: i32 = 0

            if (__local_c2_1 <= __local_num2_1) {
                (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


        }

        var __local_i2_1: i32 = ((1 as i32))

        while (__local_i2_1 < __local_num2_1) {
            if ((if not ((*__local_n).key[(__local_i2_1 - 1)].cmp.unwrap()(((*__local_n).key[(__local_i2_1 - 1)] as *const c_void), ((*__local_n).key[__local_i2_1] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[i2-1])->cmp(((n)->key[i2-1]), ((n)->key[i2]))) < 0".ptr)
            } else {
                0
            }


            (__local_i2_1 = __local_i2_1 + 1)

        }


        if ((*__local_n).next != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            if ((if not ((*__local_n).key[(__local_num2_1 - 1)].cmp.unwrap()(((*__local_n).key[(__local_num2_1 - 1)] as *const c_void), ((*(*__local_n).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->key[num2-1])->cmp(((n)->key[num2-1]), ((n)->next->key[0]))) < 0".ptr)
            } else {
                0
            }

        }

        if ((*__local_n).prev != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev_1: i32 = (*(*__local_n).prev).num

            (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

            if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if ((if not ((*(*__local_n).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*__local_n).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*__local_n).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_it_from".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(((n)->prev->key[num_prev-1])->cmp(((n)->prev->key[num_prev-1]), ((n)->key[0]))) < 0".ptr)
            } else {
                0
            }

        }

        if not (false) {
            break
        }
    }

    (__local_i = ((0 as i32)))

    while (__local_i < (0 - (*__local_n).num)) {
        if ((*__param_key).cmp.unwrap()((__param_key as *const c_void), ((*__local_n).key[__local_i] as *const c_void)) <= 0) {
            break
        }


        (__local_i = __local_i + 1)

    }


    var __ci_expr_logic_4: i32 = 0

    if (__local_i == (0 - (*__local_n).num)) {
        (__ci_expr_logic_4 = (if (*__local_n).next != null: 1 else: 0))
    }

    if __ci_expr_logic_4 {
        ((__param_it_[0]).node = (*__local_n).next)

        (__local_i = ((0 as i32)))

    }


    ((__param_it_[0]).idx = __local_i)

}

// contract: receiver:mlib_slot_tree_it_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_it_until_p(__param_it_: *mut mlib_slot_tree_it_s, __param_key: *mut mlib_slot_head) -> bool {
    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_it_until_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node

    if ((((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx as u32)) >= (((0 - (*__local_n).num) as u32))) {
        return (((((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx >= 0)) as bool))
    }

    var __local_cmp: i32 = (((*__local_n).key[(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx].cmp.unwrap()(((*__local_n).key[(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx] as *const c_void), (__param_key as *const c_void)) as i32))

    return ((((__local_cmp >= 0)) as bool))

}

// contract: receiver:mlib_slot_tree_it_s,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn mlib_slot_tree_it_while_p(__param_it_: *mut mlib_slot_tree_it_s, __param_key: *mut mlib_slot_head) -> bool {
    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_it_while_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node

    if ((((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx as u32)) >= (((0 - (*__local_n).num) as u32))) {
        return (((((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx < 0)) as bool))
    }

    var __local_cmp: i32 = (((*__local_n).key[(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx].cmp.unwrap()(((*__local_n).key[(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx] as *const c_void), (__param_key as *const c_void)) as i32))

    return ((((__local_cmp <= 0)) as bool))

}

// contract: receiver-mut:mlib_slot_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_slot_tree_remove(__param_b: *mut mlib_slot_tree_s, __param_it_: *mut mlib_slot_tree_it_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __local_n: *mut mlib_slot_tree_node_s = (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node

    if ((if not ((*__local_n).num < 0): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"n->num < 0".ptr)
    } else {
        0
    }

    var __local_i: i32 = (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx

    var __local_num: i32 = (((*__local_n).mlib_slot_tree_get_num() as i32))

    var __ci_expr_logic_2: i32 = 0

    if (__local_i >= 0) {
        (__ci_expr_logic_2 = (if __local_i < __local_num: 1 else: 0))
    }

    if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"i >= 0 && i < num".ptr)
    } else {
        0
    }


    var __local_pit: [mlib_slot_tree_parent_it_s; 1]

    var __local_leaf: *mut mlib_slot_tree_node_s = mlib_slot_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_slot_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_slot_tree_s), (*__local_n).key[__local_i])

    mlib_slot_release((*__local_n).key[__local_i])

    with_memmove(((((&raw const (*__local_n).key[__local_i] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (*__local_n).key[(__local_i + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num - 1) - __local_i) as u32) as u64)) as u64) as i64))

    ((*__local_n).num = (*__local_n).num - -1)

    ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size -% 1))

    var __ci_expr_logic_3: i32 = 0

    if (__local_i >= (__local_num - 1)) {
        (__ci_expr_logic_3 = (if (*__local_n).next != null: 1 else: 0))
    }

    if ((if not (not __ci_expr_logic_3): 1 else: 0) as i64) {
        ((__param_it_[0]).node = (*__local_n).next)

        ((__param_it_[0]).idx = ((0 as i32)))

    }


    var __ci_expr_logic_4: i32

    if ((if not (not ((*__local_n).mlib_slot_tree_get_num() >= (16 / 2))): 1 else: 0) as i64) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root == __local_n: 1 else: 0))
    }

    if __ci_expr_logic_4 {
        return
    }


    while ((if not (not (__local_n != __local_leaf)): 1 else: 0) as i64) {
        if ((if not ((*__local_leaf).next != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"leaf->next != ((void*)0)".ptr)
        } else {
            0
        }

        (__local_leaf = (*__local_leaf).next)

        var __local_p_num: i32 = (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num

        var __local_p_n: *mut mlib_slot_tree_node_s = __local_leaf

        loop {
            if ((if not (__local_p_num >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"p_num >= 1".ptr)
            } else {
                0
            }

            var __local_parent: *mut mlib_slot_tree_node_s = with 0 as __ci_expr_seq_189 {
                (__local_p_num = __local_p_num - 1)
                (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).parent[__local_p_num]
            }

            var __local_k: i32 = ((mlib_slot_tree_i_search_for_node(__local_parent, __local_p_n) as i32))

            if (__local_k >= 0) {
                break
            }

            (__local_pit[0].parent[__local_p_num] = (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).parent[__local_p_num].next)

            (__local_p_n = (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).parent[__local_p_num])

            if not (true) {
                break
            }
        }

    }

    if ((if not ((*__local_leaf).mlib_slot_tree_get_num() == ((16 / 2) - 1)): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_get_num(leaf) == 16/2-1".ptr)
    } else {
        0
    }

    var __local_pass1: bool = true

    while true {
        if ((if not ((*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"pit->num > 0".ptr)
        } else {
            0
        }

        var __local_parent_1: *mut mlib_slot_tree_node_s = with 0 as __ci_expr_seq_206 {
            (__local_pit[0].num = (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num - 1)
            (*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).parent[(*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num]
        }

        if ((if not (__local_parent_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"parent != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_k_1: i32 = ((mlib_slot_tree_i_search_for_node(__local_parent_1, __local_leaf) as i32))

        if ((if not (__local_k_1 >= 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"k >= 0".ptr)
        } else {
            0
        }

        var __ci_expr_logic_5: i32 = 0

        if (__local_k_1 > 0) {
            (__ci_expr_logic_5 = (if (*((*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[(__local_k_1 - 1)] as *mut mlib_slot_tree_node_s)).mlib_slot_tree_get_num() > (16 / 2): 1 else: 0))
        }

        if __ci_expr_logic_5 {
            (*__local_parent_1).mlib_slot_tree_i_left_shift(((__local_k_1 - 1) as i32))

            if ((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[__local_k_1]) {
                ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx + 1)

            } else {
                if ((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[(__local_k_1 - 1)]) {
                    if ((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx >= (*((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node)).mlib_slot_tree_get_num()) {
                        ((__param_it_[0]).idx = ((0 as i32)))

                        ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[(__local_k_1 - 1)])

                    }

                }
            }

            return

        }
        var __ci_expr_logic_6: i32 = 0

        if (__local_k_1 < (*__local_parent_1).mlib_slot_tree_get_num()) {
            (__ci_expr_logic_6 = (if (*((*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[(__local_k_1 + 1)] as *mut mlib_slot_tree_node_s)).mlib_slot_tree_get_num() > (16 / 2): 1 else: 0))
        }

        if __ci_expr_logic_6 {
            (*__local_parent_1).mlib_slot_tree_i_right_shift(__local_k_1)

            if ((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[(__local_k_1 + 1)]) {
                if ((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx == 0) {
                    ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[__local_k_1])

                    ((__param_it_[0]).idx = ((((*((*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[__local_k_1] as *mut mlib_slot_tree_node_s)).mlib_slot_tree_get_num() - 1) as i32)))

                } else {
                    ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx - 1)

                }

            }

            return

        }



        if (__local_k_1 == (*__local_parent_1).mlib_slot_tree_get_num()) {
            (__local_k_1 = __local_k_1 - 1)
        }

        var __ci_expr_logic_7: i32 = 0

        if (__local_k_1 >= 0) {
            (__ci_expr_logic_7 = (if __local_k_1 < (*__local_parent_1).mlib_slot_tree_get_num(): 1 else: 0))
        }

        if ((if not __ci_expr_logic_7: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_remove".ptr, c"facade_shapes.c".ptr, (34 as i32), c"k >= 0 && k < mlib_slot_tree_get_num(parent)".ptr)
        } else {
            0
        }


        (__local_num = (((*((*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[__local_k_1] as *mut mlib_slot_tree_node_s)).mlib_slot_tree_get_num() as i32)))

        var __local_it_to_fix: bool = (((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[(__local_k_1 + 1)]))

        (*__local_parent_1).mlib_slot_tree_i_merge_node(__local_k_1, __local_pass1)

        if __local_it_to_fix {
            ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[__local_k_1])

            ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx + __local_num)

        }

        if ((*__local_parent_1).mlib_slot_tree_get_num() >= (16 / 2)) {
            return
        }

        if ((*(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).num == 0) {
            if ((*__local_parent_1).mlib_slot_tree_get_num() == 0) {
                ((__param_b[0]).root = (*(&raw const (*__local_parent_1).kind as *const mlib_slot_tree_kind_s)).node[0])

                with_free(((__local_parent_1 as *mut c_void) as *mut u8))

            }

            return

        }

        (__local_leaf = __local_parent_1)

        (__local_pass1 = false)

    }

}

// contract: receiver:mlib_slot_tree_s,unproved:1:read only
pub unsafe fn mlib_slot_tree_equal_p(__param_t1: *mut mlib_slot_tree_s, __param_t2: *mut mlib_slot_tree_s) -> bool {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((t1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((t1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((t1)->root+0)->key[i2-1])->cmp((((t1)->root+0)->key[i2-1]), (((t1)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((t1)->root+0)->key[num2-1])->cmp((((t1)->root+0)->key[num2-1]), (((t1)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((t1)->root+0)->prev->key[num_prev-1])->cmp((((t1)->root+0)->prev->key[num_prev-1]), (((t1)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(t1)->root->num == (int) (t1)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((t2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((t2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] as *const c_void), ((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((t2)->root+0)->key[i2-1])->cmp((((t2)->root+0)->key[i2-1]), (((t2)->root+0)->key[i2]))) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((t2)->root+0)->key[num2-1])->cmp((((t2)->root+0)->key[num2-1]), (((t2)->root+0)->next->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((*(*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((t2)->root+0)->prev->key[num_prev-1])->cmp((((t2)->root+0)->prev->key[num_prev-1]), (((t2)->root+0)->key[0]))) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(t2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(t2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).root).num) == (((*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_equal_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(t2)->root->num == (int) (t2)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).size != (*(&raw const (__param_t2[0]) as *const mlib_slot_tree_s)).size) {
        return ((false as bool))
    }

    if ((*(&raw const (__param_t1[0]) as *const mlib_slot_tree_s)).size == 0) {
        return ((true as bool))
    }

    var __local_it1: [mlib_slot_tree_it_s; 1]

    var __local_it2: [mlib_slot_tree_it_s; 1]

    mlib_slot_tree_it((&__local_it1[0] as *mut mlib_slot_tree_it_s), (&(__param_t1[0]) as *mut mlib_slot_tree_s))

    mlib_slot_tree_it((&__local_it2[0] as *mut mlib_slot_tree_it_s), (&(__param_t2[0]) as *mut mlib_slot_tree_s))

    while true {
        var __ci_expr_logic_4: i32 = 0

        if (not (*(&__local_it1[0] as *mut mlib_slot_tree_it_s)).mlib_slot_tree_end_p()) {
            (__ci_expr_logic_4 = (if not (*(&__local_it2[0] as *mut mlib_slot_tree_it_s)).mlib_slot_tree_end_p(): 1 else: 0))
        }

        if (not __ci_expr_logic_4) {
            break
        }

        var __local_ref1: *const *mut mlib_slot_head = mlib_slot_tree_cref((&__local_it1[0] as *mut mlib_slot_tree_it_s))

        var __local_ref2: *const *mut mlib_slot_head = mlib_slot_tree_cref((&__local_it2[0] as *mut mlib_slot_tree_it_s))

        if (not ((*__local_ref1) == (*__local_ref2))) {
            return ((false as bool))
        }

        (*(&__local_it1[0] as *mut mlib_slot_tree_it_s)).mlib_slot_tree_next()

        (*(&__local_it2[0] as *mut mlib_slot_tree_it_s)).mlib_slot_tree_next()

    }

    var __ci_expr_logic_5: i32 = 0

    if (*(&__local_it1[0] as *mut mlib_slot_tree_it_s)).mlib_slot_tree_end_p() {
        (__ci_expr_logic_5 = (if (*(&__local_it2[0] as *mut mlib_slot_tree_it_s)).mlib_slot_tree_end_p(): 1 else: 0))
    }

    return (((__ci_expr_logic_5 != 0) as bool))


}

pub fn mlib_word_tree_new_node() -> *mut mlib_word_tree_node_s {
    var __local_n: *mut mlib_word_tree_node_s = (((with_alloc(((sizeof[mlib_word_tree_node_s]() as u64) as i64)) as *mut c_void) as *mut mlib_word_tree_node_s))

    if ((if not (not (__local_n == null)): 1 else: 0) as i64) {
        abort()

    }

    ((unsafe *__local_n).next = ((null as *mut mlib_word_tree_node_s)))

    ((unsafe *__local_n).prev = ((null as *mut mlib_word_tree_node_s)))

    ((unsafe *__local_n).num = ((0 as i32)))

    return __local_n

}

// contract: unproved:0:mutated through a pointer to no corpus record,unproved:1:read only,unproved:2:read only
pub unsafe fn mlib_word_tree_copy_node(__param_dst: *mut *mut mlib_word_tree_node_s, __param_o: *mut mlib_word_tree_node_s, __param_root: *mut mlib_word_tree_node_s) -> Unit {
    var __local_n: *mut mlib_word_tree_node_s = mlib_word_tree_new_node()

    ((*__param_dst) = __local_n)


    var __local_num: i32 = (((*__param_o).mlib_word_tree_get_num() as i32))

    if (*__param_o).mlib_word_tree_is_leaf() {
        var __local_i: i32 = ((0 as i32))

        while (__local_i < __local_num) {
            ((*__local_n).key[__local_i] = (((*__param_o).key[__local_i] as i64)))


            ((*__local_n).kind.value[__local_i] = (*(&raw const (*__param_o).kind as *const mlib_word_tree_kind_s)).value[__local_i])




            (__local_i = __local_i + 1)

        }


    } else {
        if ((if not (__local_num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num != 0".ptr)
        } else {
            0
        }

        var __local_i_1: i32 = ((0 as i32))

        while (__local_i_1 < __local_num) {
            ((*__local_n).key[__local_i_1] = (((*__param_o).key[__local_i_1] as i64)))



            (__local_i_1 = __local_i_1 + 1)

        }


        var __local_i_2: i32 = ((0 as i32))

        while (__local_i_2 <= __local_num) {
            if ((if not ((*(&raw const (*__param_o).kind as *const mlib_word_tree_kind_s)).node[__local_i_2] != __param_root): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"o->kind.node[i] != root".ptr)
            } else {
                0
            }

            mlib_word_tree_copy_node(((&raw const (*__local_n).kind.node[__local_i_2] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s), (*(&raw const (*__param_o).kind as *const mlib_word_tree_kind_s)).node[__local_i_2], __param_root)


            (__local_i_2 = __local_i_2 + 1)

        }


        var __local_i_3: i32 = ((0 as i32))

        while (__local_i_3 < __local_num) {
            var __local_current: *mut mlib_word_tree_node_s = (*(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[__local_i_3]

            var __local_next: *mut mlib_word_tree_node_s = (*(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[(__local_i_3 + 1)]

            ((*__local_current).next = __local_next)

            ((*__local_next).prev = __local_current)

            while (not (*__local_current).mlib_word_tree_is_leaf()) {
                if ((if not (not (*__local_next).mlib_word_tree_is_leaf()): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"!mlib_word_tree_is_leaf(next)".ptr)
                } else {
                    0
                }

                (__local_current = (*(&raw const (*__local_current).kind as *const mlib_word_tree_kind_s)).node[(*__local_current).num])

                (__local_next = (*(&raw const (*__local_next).kind as *const mlib_word_tree_kind_s)).node[0])

                ((*__local_current).next = __local_next)

                ((*__local_next).prev = __local_current)

            }


            (__local_i_3 = __local_i_3 + 1)

        }


    }


    ((*__local_n).num = (*__param_o).num)

    loop {
        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((if __param_o == __param_root: __local_n else: __param_root) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((o==root) ? n : root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2: i32 = (*__local_n).num

        var __local_is_leaf2: bool = ((__local_num2 <= 0))

        (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

        if (__local_n == (if __param_o == __param_root: __local_n else: __param_root)) {
            var __ci_expr_logic_0: i32 = 0

            if (0 <= __local_num2) {
                (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


            if (__local_num2 == 0) {
                if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2: i32 = (((16 / 2) as i32))

            if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_1: i32 = 0

            if (__local_c2 <= __local_num2) {
                (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


        }

        var __local_i2: i32 = ((1 as i32))

        while (__local_i2 < __local_num2) {
            if ((if not ((if (*__local_n).key[(__local_i2 - 1)] < (*__local_n).key[__local_i2]: (-1 as i32) else: ((if (*__local_n).key[(__local_i2 - 1)] > (*__local_n).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) < 0".ptr)
            } else {
                0
            }


            (__local_i2 = __local_i2 + 1)

        }


        if ((*__local_n).next != null) {
            if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            if ((if not ((if (*__local_n).key[(__local_num2 - 1)] < (*(*__local_n).next).key[0]: (-1 as i32) else: ((if (*__local_n).key[(__local_num2 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) < 0".ptr)
            } else {
                0
            }

        }

        if ((*__local_n).prev != null) {
            if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev: i32 = (*(*__local_n).prev).num

            (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

            if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if ((if not ((if (*(*__local_n).prev).key[(__local_num_prev - 1)] < (*__local_n).key[0]: (-1 as i32) else: ((if (*(*__local_n).prev).key[(__local_num_prev - 1)] > (*__local_n).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_copy_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) < 0".ptr)
            } else {
                0
            }

        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_word_tree_s,unproved:1:read only
pub unsafe fn mlib_word_tree_init_set(__param_b: *mut mlib_word_tree_s, __param_o: *mut mlib_word_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((o)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((o)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((o)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((o)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((o)->root+0)->key[i2-1]) < (((o)->root+0)->key[i2]) ? -1 : (((o)->root+0)->key[i2-1]) > (((o)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((o)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((o)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((o)->root+0)->key[num2-1]) < (((o)->root+0)->next->key[0]) ? -1 : (((o)->root+0)->key[num2-1]) > (((o)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((o)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((o)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((o)->root+0)->prev->key[num_prev-1]) < (((o)->root+0)->key[0]) ? -1 : (((o)->root+0)->prev->key[num_prev-1]) > (((o)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(o)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(o)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(o)->root->num == (int) (o)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_b[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"b != ((void*)0)".ptr)
    } else {
        0
    }


    var __local_cont: bool = true

    while __local_cont {

        mlib_word_tree_copy_node(((&raw const (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s), (*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root, (*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).root)

        ((__param_b[0]).size = (*(&raw const (__param_o[0]) as *const mlib_word_tree_s)).size)


        (__local_cont = false)

    }


    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_word_tree_parent_it_s,unproved:1:read only
pub unsafe fn mlib_word_tree_i_search_for_leaf(__param_pit: *mut mlib_word_tree_parent_it_s, __param_b: *mut mlib_word_tree_s, __param_key: i64) -> *mut mlib_word_tree_node_s {
    var __local_n: *mut mlib_word_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root

    var __local_np: i32 = ((0 as i32))

    while (not (*__local_n).mlib_word_tree_is_leaf()) {
        if ((if not (__local_np <= ((((1 as u64) +% (((8 as u64) *% (sizeof[u64]() as u64)) as u64)) as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
        } else {
            0
        }

        var __local_i: i32

        var __local_hi: i32 = (*__local_n).num


        if ((if not (__local_hi > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"hi > 0".ptr)
        } else {
            0
        }

        (__local_i = ((0 as i32)))

        while (__local_i < __local_hi) {
            if ((if __param_key < (*__local_n).key[__local_i]: (-1 as i32) else: ((if __param_key > (*__local_n).key[__local_i]: 1 else: 0) as i32)) <= 0) {
                break
            }


            (__local_i = __local_i + 1)

        }


        var __ci_expr_old_0: i32 = __local_np

        (__local_np = __local_np + 1)

        ((__param_pit[0]).parent[__ci_expr_old_0] = __local_n)


        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[__local_i])

        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"n != ((void*)0)".ptr)
        } else {
            0
        }

        loop {
            if ((if not (__local_n != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(n) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*__local_n).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (__local_n == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_1: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_2: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_2 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*__local_n).key[(__local_i2 - 1)] < (*__local_n).key[__local_i2]: (-1 as i32) else: ((if (*__local_n).key[(__local_i2 - 1)] > (*__local_n).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*__local_n).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*__local_n).key[(__local_num2 - 1)] < (*(*__local_n).next).key[0]: (-1 as i32) else: ((if (*__local_n).key[(__local_num2 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*__local_n).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*__local_n).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*__local_n).prev).key[(__local_num_prev - 1)] < (*__local_n).key[0]: (-1 as i32) else: ((if (*(*__local_n).prev).key[(__local_num_prev - 1)] > (*__local_n).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_i_search_for_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

    }

    ((__param_pit[0]).num = __local_np)

    return __local_n

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_word_tree_get(__param_b: *mut mlib_word_tree_s, __param_key: i64) -> *mut *mut c_void {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __local_pit: [mlib_word_tree_parent_it_s; 1]

    var __local_n: *mut mlib_word_tree_node_s = mlib_word_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_word_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_word_tree_s), __param_key)

    var __local_cmp: i32 = ((0 as i32))

    loop {
        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2_1: i32 = (*__local_n).num

        var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

        (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

        if (__local_n == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            var __ci_expr_logic_2: i32 = 0

            if (0 <= __local_num2_1) {
                (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


            if (__local_num2_1 == 0) {
                if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2_1: i32 = (((16 / 2) as i32))

            if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_3: i32 = 0

            if (__local_c2_1 <= __local_num2_1) {
                (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


        }

        var __local_i2_1: i32 = ((1 as i32))

        while (__local_i2_1 < __local_num2_1) {
            if ((if not ((if (*__local_n).key[(__local_i2_1 - 1)] < (*__local_n).key[__local_i2_1]: (-1 as i32) else: ((if (*__local_n).key[(__local_i2_1 - 1)] > (*__local_n).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) < 0".ptr)
            } else {
                0
            }


            (__local_i2_1 = __local_i2_1 + 1)

        }


        if ((*__local_n).next != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            if ((if not ((if (*__local_n).key[(__local_num2_1 - 1)] < (*(*__local_n).next).key[0]: (-1 as i32) else: ((if (*__local_n).key[(__local_num2_1 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) < 0".ptr)
            } else {
                0
            }

        }

        if ((*__local_n).prev != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev_1: i32 = (*(*__local_n).prev).num

            (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

            if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if ((if not ((if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] < (*__local_n).key[0]: (-1 as i32) else: ((if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] > (*__local_n).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) < 0".ptr)
            } else {
                0
            }

        }

        if not (false) {
            break
        }
    }

    var __local_i: i32 = ((0 as i32))

    while true {
        var __ci_expr_logic_4: i32 = 0

        if (__local_cmp >= 0) {
            (__ci_expr_logic_4 = (if __local_i < (0 - (*__local_n).num): 1 else: 0))
        }

        if (not __ci_expr_logic_4) {
            break
        }

        (__local_cmp = (((if __param_key < (*__local_n).key[__local_i]: (-1 as i32) else: ((if __param_key > (*__local_n).key[__local_i]: 1 else: 0) as i32)) as i32)))

        if (__local_cmp == 0) {
            return (((&raw const (*__local_n).kind.value[__local_i] as *const *mut c_void) as *mut *mut c_void))

        }

        (__local_i = __local_i + 1)

    }


    return ((null as *mut *mut c_void))

}

@[repr(C)]
pub type mlib_word_tree_cget_literal_anon = union { ptr: *mut *mut c_void = null, cptr: *const *mut c_void = null }
impl Copy for mlib_word_tree_cget_literal_anon
// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_word_tree_cget(__param_b: *mut mlib_word_tree_s, __param_key: i64) -> *const *mut c_void {
    return (mlib_word_tree_cget_literal_anon { ptr: mlib_word_tree_get((&(__param_b[0]) as *mut mlib_word_tree_s), __param_key) } as mlib_word_tree_cget_literal_anon).cptr

}

// contract: receiver-mut:mlib_word_tree_node_s,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn mlib_word_tree_i_search_and_insert_in_leaf(__param_n: *mut mlib_word_tree_node_s, __param_key: i64, __param_value: *mut c_void) -> i32 {
    if ((if not (*__param_n).mlib_word_tree_is_leaf(): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_i_search_and_insert_in_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_i: i32

    var __local_num: i32 = (((*__param_n).mlib_word_tree_get_num() as i32))


    if ((if not (__local_num <= 16): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_i_search_and_insert_in_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num <= 16".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num) {
        var __local_cmp: i32

        (__local_cmp = (((if __param_key < (*__param_n).key[__local_i]: (-1 as i32) else: ((if __param_key > (*__param_n).key[__local_i]: 1 else: 0) as i32)) as i32)))


        if (__local_cmp <= 0) {
            if ((if not (not (__local_cmp == 0)): 1 else: 0) as i64) {
                ((*__param_n).kind.value[__local_i] = __param_value)

                return -1

            }

            with_memmove(((((&raw const (*__param_n).key[(__local_i + 1)] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[__local_i] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (*__param_n).kind.value[(__local_i + 1)] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).kind.value[__local_i] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

            break

        }


        (__local_i = __local_i + 1)

    }



    ((*__param_n).num = (*__param_n).num + -1)

    ((*__param_n).key[__local_i] = __param_key)


    ((*__param_n).kind.value[__local_i] = __param_value)


    return __local_i

}

// contract: receiver-mut:mlib_word_tree_node_s,unproved:1:read only,unproved:2:read only
pub unsafe fn mlib_word_tree_i_search_and_insert_in_node(__param_n: *mut mlib_word_tree_node_s, __param_l: *mut mlib_word_tree_node_s, __param_key: *mut i64) -> i32 {
    if ((if not (not (*__param_n).mlib_word_tree_is_leaf()): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_i_search_and_insert_in_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"!mlib_word_tree_is_leaf(n)".ptr)
    } else {
        0
    }


    var __local_i: i32

    var __local_num: i32 = (((*__param_n).mlib_word_tree_get_num() as i32))


    if ((if not (__local_num <= 16): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_i_search_and_insert_in_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num <= 16".ptr)
    } else {
        0
    }

    (__local_i = ((0 as i32)))

    while (__local_i < __local_num) {
        if ((*(&raw const (*__param_n).kind as *const mlib_word_tree_kind_s)).node[__local_i] == __param_l) {
            with_memmove(((((&raw const (*__param_n).key[(__local_i + 1)] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).key[__local_i] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (*__param_n).kind.node[(__local_i + 1)] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__param_n).kind.node[__local_i] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num - __local_i) + 1) as u32) as u64)) as u64) as i64))

            break

        }


        (__local_i = __local_i + 1)

    }



    ((*__param_n).num = (*__param_n).num + 1)

    if (*__param_l).mlib_word_tree_is_leaf() {
        ((*__param_n).key[__local_i] = (*__param_key))


    } else {
        ((*__param_n).key[__local_i] = (*__param_key))


    }

    return __local_i

}

// contract: receiver-mut:mlib_word_tree_s,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn mlib_word_tree_set_at(__param_b: *mut mlib_word_tree_s, __param_key: i64, __param_value: *mut c_void) -> Unit {
    var __local_pit__goto_40_1: [mlib_word_tree_parent_it_s; 1]

    var __local_num2__goto_40_1: i32 = 0

    var __local_is_leaf2__goto_40_1: bool = false

    var __local_c2__goto_40_1: i32 = 0

    var __local_i2__goto_40_1: i32 = 0

    var __local_num_prev__goto_40_1: i32 = 0

    var __local_cont__goto_40_1: bool = false

    var __local_leaf__goto_40_1: *mut mlib_word_tree_node_s = null

    var __local_nleaf__goto_40_1: *mut mlib_word_tree_node_s = null

    var __local_key_ptr__goto_40_1: *mut i64 = null

    var __local_num__goto_40_1: i32 = 0

    var __local_nnum__goto_40_1: i32 = 0

    var __local_i__goto_40_1: i32 = 0

    var __local_parent__goto_40_1: *mut mlib_word_tree_node_s = null

    var __local_nnp__goto_40_1: i32 = 0

    var __local_np__goto_40_1: i32 = 0

    var __local_nparent__goto_40_1: *mut mlib_word_tree_node_s = null

    var __ci_expr_logic_0: i32 = 0

    var __ci_expr_logic_1: i32 = 0

    var __ci_expr_logic_2: i32 = 0

    var __ci_expr_logic_3: i32 = 0

    var __ci_expr_logic_4: i32 = 0

    var __ci_expr_logic_5: i32 = 0

    var __ci_expr_logic_6: i32 = 0

    var __ci_expr_logic_7: i32 = 0

    var __ci_expr_logic_8: i32 = 0

    var __ci_expr_logic_9: i32 = 0

    var __ci_expr_logic_10: i32 = 0

    var __ci_expr_logic_11: i32 = 0

    var __ci_expr_logic_12: i32 = 0

    var __ci_expr_logic_13: i32 = 0

    var __ci_expr_logic_15: i32 = 0

    var __ci_expr_logic_14: i32 = 0

    var __ci_expr_logic_16: i32 = 0

    var __ci_expr_logic_17: i32 = 0

    var __ci_expr_logic_18: i32 = 0

    var __ci_expr_logic_19: i32 = 0

    goto '__ci_bb_0

    '__ci_bb_0 {
        goto '__ci_bb_1
    }

    '__ci_bb_1 {
        goto '__ci_bb_4
    }

    '__ci_bb_2 {
        if false {
            goto '__ci_bb_1
        } else {
            goto '__ci_bb_3
        }
    }

    '__ci_bb_3 {
        (__local_cont__goto_40_1 = true)
        goto '__ci_bb_22
    }

    '__ci_bb_4 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_7
        } else {
            goto '__ci_bb_8
        }
    }

    '__ci_bb_5 {
        if false {
            goto '__ci_bb_4
        } else {
            goto '__ci_bb_6
        }
    }

    '__ci_bb_6 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            goto '__ci_bb_20
        } else {
            goto '__ci_bb_21
        }
    }

    '__ci_bb_7 {
        (__ci_expr_logic_0 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_0 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_10
        } else {
            goto '__ci_bb_11
        }
    }

    '__ci_bb_8 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_1 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_1 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_9
    }

    '__ci_bb_9 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_12
    }

    '__ci_bb_10 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_11
    }

    '__ci_bb_11 {
        goto '__ci_bb_9
    }

    '__ci_bb_12 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_13
        } else {
            goto '__ci_bb_15
        }
    }

    '__ci_bb_13 {
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_14
    }

    '__ci_bb_14 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_12
    }

    '__ci_bb_15 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_16
        } else {
            goto '__ci_bb_17
        }
    }

    '__ci_bb_16 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_17
    }

    '__ci_bb_17 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_18
        } else {
            goto '__ci_bb_19
        }
    }

    '__ci_bb_18 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_19
    }

    '__ci_bb_19 {
        goto '__ci_bb_5
    }

    '__ci_bb_20 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_21
    }

    '__ci_bb_21 {
        goto '__ci_bb_2
    }

    '__ci_bb_22 {
        if __local_cont__goto_40_1 {
            goto '__ci_bb_23
        } else {
            goto '__ci_bb_25
        }
    }

    '__ci_bb_23 {
        (__local_leaf__goto_40_1 = mlib_word_tree_i_search_for_leaf((&__local_pit__goto_40_1[0] as *mut mlib_word_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_word_tree_s), __param_key))
        (__local_i__goto_40_1 = ((mlib_word_tree_i_search_and_insert_in_leaf(__local_leaf__goto_40_1, __param_key, __param_value) as i32)))
        if (__local_i__goto_40_1 < 0) {
            goto '__ci_bb_26
        } else {
            goto '__ci_bb_27
        }
    }

    '__ci_bb_24 {
        (__local_cont__goto_40_1 = false)
        goto '__ci_bb_22
    }

    '__ci_bb_25 {
        return
    }

    '__ci_bb_26 {
        goto '__ci_bb_28
    }

    '__ci_bb_27 {
        ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size +% 1))
        (__local_num__goto_40_1 = (((0 - (*__local_leaf__goto_40_1).num) as i32)))
        if ((if not (__local_num__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num > 0".ptr)
        } else {
            0
        }
        if ((if not (not (__local_num__goto_40_1 <= 16)): 1 else: 0) as i64) {
            goto '__ci_bb_50
        } else {
            goto '__ci_bb_51
        }
    }

    '__ci_bb_28 {
        goto '__ci_bb_31
    }

    '__ci_bb_29 {
        if false {
            goto '__ci_bb_28
        } else {
            goto '__ci_bb_30
        }
    }

    '__ci_bb_30 {
        goto '__ci_bb_49
    }

    '__ci_bb_31 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_34
        } else {
            goto '__ci_bb_35
        }
    }

    '__ci_bb_32 {
        if false {
            goto '__ci_bb_31
        } else {
            goto '__ci_bb_33
        }
    }

    '__ci_bb_33 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            goto '__ci_bb_47
        } else {
            goto '__ci_bb_48
        }
    }

    '__ci_bb_34 {
        (__ci_expr_logic_2 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_2 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_37
        } else {
            goto '__ci_bb_38
        }
    }

    '__ci_bb_35 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_3 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_3 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_36
    }

    '__ci_bb_36 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_39
    }

    '__ci_bb_37 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_38
    }

    '__ci_bb_38 {
        goto '__ci_bb_36
    }

    '__ci_bb_39 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_40
        } else {
            goto '__ci_bb_42
        }
    }

    '__ci_bb_40 {
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_41
    }

    '__ci_bb_41 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_39
    }

    '__ci_bb_42 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_43
        } else {
            goto '__ci_bb_44
        }
    }

    '__ci_bb_43 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_44
    }

    '__ci_bb_44 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_45
        } else {
            goto '__ci_bb_46
        }
    }

    '__ci_bb_45 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_46
    }

    '__ci_bb_46 {
        goto '__ci_bb_32
    }

    '__ci_bb_47 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_48
    }

    '__ci_bb_48 {
        goto '__ci_bb_29
    }

    '__ci_bb_49 {
        goto '__ci_bb_24
    }

    '__ci_bb_50 {
        goto '__ci_bb_52
    }

    '__ci_bb_51 {
        if ((if not (__local_num__goto_40_1 == (16 + 1)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num == 16+1".ptr)
        } else {
            0
        }
        (__local_nnum__goto_40_1 = ((((16 + 1) / 2) as i32)))
        (__local_num__goto_40_1 = ((((16 + 1) - __local_nnum__goto_40_1) as i32)))
        (__local_nleaf__goto_40_1 = mlib_word_tree_new_node())
        with_memmove(((((&raw const (*__local_nleaf__goto_40_1).key[0] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (*__local_leaf__goto_40_1).key[__local_num__goto_40_1] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((__local_nnum__goto_40_1 as u32) as u64)) as u64) as i64))
        with_memmove(((((&raw const (*__local_nleaf__goto_40_1).kind.value[0] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (*__local_leaf__goto_40_1).kind.value[__local_num__goto_40_1] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% ((__local_nnum__goto_40_1 as u32) as u64)) as u64) as i64))
        ((*__local_leaf__goto_40_1).num = (((0 - __local_num__goto_40_1) as i32)))
        ((*__local_nleaf__goto_40_1).num = (((0 - __local_nnum__goto_40_1) as i32)))
        ((*__local_nleaf__goto_40_1).next = (*__local_leaf__goto_40_1).next)
        ((*__local_leaf__goto_40_1).next = __local_nleaf__goto_40_1)
        ((*__local_nleaf__goto_40_1).prev = __local_leaf__goto_40_1)
        if ((*__local_nleaf__goto_40_1).next != null) {
            goto '__ci_bb_73
        } else {
            goto '__ci_bb_74
        }
    }

    '__ci_bb_52 {
        goto '__ci_bb_55
    }

    '__ci_bb_53 {
        if false {
            goto '__ci_bb_52
        } else {
            goto '__ci_bb_54
        }
    }

    '__ci_bb_54 {
        goto '__ci_bb_49
    }

    '__ci_bb_55 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_58
        } else {
            goto '__ci_bb_59
        }
    }

    '__ci_bb_56 {
        if false {
            goto '__ci_bb_55
        } else {
            goto '__ci_bb_57
        }
    }

    '__ci_bb_57 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            goto '__ci_bb_71
        } else {
            goto '__ci_bb_72
        }
    }

    '__ci_bb_58 {
        (__ci_expr_logic_4 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_4 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_61
        } else {
            goto '__ci_bb_62
        }
    }

    '__ci_bb_59 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_5 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_5 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_60
    }

    '__ci_bb_60 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_63
    }

    '__ci_bb_61 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_62
    }

    '__ci_bb_62 {
        goto '__ci_bb_60
    }

    '__ci_bb_63 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_64
        } else {
            goto '__ci_bb_66
        }
    }

    '__ci_bb_64 {
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_65
    }

    '__ci_bb_65 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_63
    }

    '__ci_bb_66 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_67
        } else {
            goto '__ci_bb_68
        }
    }

    '__ci_bb_67 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_68
    }

    '__ci_bb_68 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_69
        } else {
            goto '__ci_bb_70
        }
    }

    '__ci_bb_69 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_70
    }

    '__ci_bb_70 {
        goto '__ci_bb_56
    }

    '__ci_bb_71 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_72
    }

    '__ci_bb_72 {
        goto '__ci_bb_53
    }

    '__ci_bb_73 {
        ((*(*__local_nleaf__goto_40_1).next).prev = __local_nleaf__goto_40_1)
        goto '__ci_bb_74
    }

    '__ci_bb_74 {
        goto '__ci_bb_75
    }

    '__ci_bb_75 {
        if ((if not (__local_leaf__goto_40_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(leaf) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*__local_leaf__goto_40_1).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (__local_leaf__goto_40_1 == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_78
        } else {
            goto '__ci_bb_79
        }
    }

    '__ci_bb_76 {
        if false {
            goto '__ci_bb_75
        } else {
            goto '__ci_bb_77
        }
    }

    '__ci_bb_77 {
        goto '__ci_bb_91
    }

    '__ci_bb_78 {
        (__ci_expr_logic_6 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_6 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_6: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_81
        } else {
            goto '__ci_bb_82
        }
    }

    '__ci_bb_79 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_7 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_7 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_7: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_80
    }

    '__ci_bb_80 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_83
    }

    '__ci_bb_81 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_82
    }

    '__ci_bb_82 {
        goto '__ci_bb_80
    }

    '__ci_bb_83 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_84
        } else {
            goto '__ci_bb_86
        }
    }

    '__ci_bb_84 {
        if ((if not ((if (*__local_leaf__goto_40_1).key[(__local_i2__goto_40_1 - 1)] < (*__local_leaf__goto_40_1).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*__local_leaf__goto_40_1).key[(__local_i2__goto_40_1 - 1)] > (*__local_leaf__goto_40_1).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((leaf)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(leaf)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((leaf)->key[i2-1]) < ((leaf)->key[i2]) ? -1 : ((leaf)->key[i2-1]) > ((leaf)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_85
    }

    '__ci_bb_85 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_83
    }

    '__ci_bb_86 {
        if ((*__local_leaf__goto_40_1).next != null) {
            goto '__ci_bb_87
        } else {
            goto '__ci_bb_88
        }
    }

    '__ci_bb_87 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*__local_leaf__goto_40_1).key[(__local_num2__goto_40_1 - 1)] < (*(*__local_leaf__goto_40_1).next).key[0]: (-1 as i32) else: ((if (*__local_leaf__goto_40_1).key[(__local_num2__goto_40_1 - 1)] > (*(*__local_leaf__goto_40_1).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((leaf)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(leaf)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((leaf)->key[num2-1]) < ((leaf)->next->key[0]) ? -1 : ((leaf)->key[num2-1]) > ((leaf)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_88
    }

    '__ci_bb_88 {
        if ((*__local_leaf__goto_40_1).prev != null) {
            goto '__ci_bb_89
        } else {
            goto '__ci_bb_90
        }
    }

    '__ci_bb_89 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*__local_leaf__goto_40_1).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*__local_leaf__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*__local_leaf__goto_40_1).key[0]: (-1 as i32) else: ((if (*(*__local_leaf__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*__local_leaf__goto_40_1).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((leaf)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(leaf)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((leaf)->prev->key[num_prev-1]) < ((leaf)->key[0]) ? -1 : ((leaf)->prev->key[num_prev-1]) > ((leaf)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_90
    }

    '__ci_bb_90 {
        goto '__ci_bb_76
    }

    '__ci_bb_91 {
        if ((if not (__local_nleaf__goto_40_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(nleaf) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*__local_nleaf__goto_40_1).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (__local_nleaf__goto_40_1 == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_94
        } else {
            goto '__ci_bb_95
        }
    }

    '__ci_bb_92 {
        if false {
            goto '__ci_bb_91
        } else {
            goto '__ci_bb_93
        }
    }

    '__ci_bb_93 {
        (__local_key_ptr__goto_40_1 = (((&raw const (*__local_leaf__goto_40_1).key[(__local_num__goto_40_1 - 1)] as *const i64) as *mut i64)))
        goto '__ci_bb_107
    }

    '__ci_bb_94 {
        (__ci_expr_logic_8 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_8 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_8: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_97
        } else {
            goto '__ci_bb_98
        }
    }

    '__ci_bb_95 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_9 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_9 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_9: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_96
    }

    '__ci_bb_96 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_99
    }

    '__ci_bb_97 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_98
    }

    '__ci_bb_98 {
        goto '__ci_bb_96
    }

    '__ci_bb_99 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_100
        } else {
            goto '__ci_bb_102
        }
    }

    '__ci_bb_100 {
        if ((if not ((if (*__local_nleaf__goto_40_1).key[(__local_i2__goto_40_1 - 1)] < (*__local_nleaf__goto_40_1).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*__local_nleaf__goto_40_1).key[(__local_i2__goto_40_1 - 1)] > (*__local_nleaf__goto_40_1).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nleaf)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nleaf)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nleaf)->key[i2-1]) < ((nleaf)->key[i2]) ? -1 : ((nleaf)->key[i2-1]) > ((nleaf)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_101
    }

    '__ci_bb_101 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_99
    }

    '__ci_bb_102 {
        if ((*__local_nleaf__goto_40_1).next != null) {
            goto '__ci_bb_103
        } else {
            goto '__ci_bb_104
        }
    }

    '__ci_bb_103 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*__local_nleaf__goto_40_1).key[(__local_num2__goto_40_1 - 1)] < (*(*__local_nleaf__goto_40_1).next).key[0]: (-1 as i32) else: ((if (*__local_nleaf__goto_40_1).key[(__local_num2__goto_40_1 - 1)] > (*(*__local_nleaf__goto_40_1).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nleaf)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nleaf)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nleaf)->key[num2-1]) < ((nleaf)->next->key[0]) ? -1 : ((nleaf)->key[num2-1]) > ((nleaf)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_104
    }

    '__ci_bb_104 {
        if ((*__local_nleaf__goto_40_1).prev != null) {
            goto '__ci_bb_105
        } else {
            goto '__ci_bb_106
        }
    }

    '__ci_bb_105 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*__local_nleaf__goto_40_1).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*__local_nleaf__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*__local_nleaf__goto_40_1).key[0]: (-1 as i32) else: ((if (*(*__local_nleaf__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*__local_nleaf__goto_40_1).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nleaf)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nleaf)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nleaf)->prev->key[num_prev-1]) < ((nleaf)->key[0]) ? -1 : ((nleaf)->prev->key[num_prev-1]) > ((nleaf)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_106
    }

    '__ci_bb_106 {
        goto '__ci_bb_92
    }

    '__ci_bb_107 {
        if true {
            goto '__ci_bb_108
        } else {
            goto '__ci_bb_109
        }
    }

    '__ci_bb_108 {
        if ((*(&raw const __local_pit__goto_40_1[0] as *const mlib_word_tree_parent_it_s)).num == 0) {
            goto '__ci_bb_110
        } else {
            goto '__ci_bb_111
        }
    }

    '__ci_bb_109 {
        goto '__ci_bb_49
    }

    '__ci_bb_110 {
        (__local_parent__goto_40_1 = mlib_word_tree_new_node())
        ((*__local_parent__goto_40_1).num = ((1 as i32)))
        if (*__local_leaf__goto_40_1).mlib_word_tree_is_leaf() {
            goto '__ci_bb_112
        } else {
            goto '__ci_bb_113
        }
    }

    '__ci_bb_111 {
        (__local_pit__goto_40_1[0].num = (*(&raw const __local_pit__goto_40_1[0] as *const mlib_word_tree_parent_it_s)).num - 1)
        (__local_parent__goto_40_1 = (*(&raw const __local_pit__goto_40_1[0] as *const mlib_word_tree_parent_it_s)).parent[(*(&raw const __local_pit__goto_40_1[0] as *const mlib_word_tree_parent_it_s)).num])
        (__local_i__goto_40_1 = ((mlib_word_tree_i_search_and_insert_in_node(__local_parent__goto_40_1, __local_leaf__goto_40_1, __local_key_ptr__goto_40_1) as i32)))
        ((*__local_parent__goto_40_1).kind.node[__local_i__goto_40_1] = __local_leaf__goto_40_1)
        ((*__local_parent__goto_40_1).kind.node[(__local_i__goto_40_1 + 1)] = __local_nleaf__goto_40_1)
        if ((if not (not ((*__local_parent__goto_40_1).num <= 16)): 1 else: 0) as i64) {
            goto '__ci_bb_136
        } else {
            goto '__ci_bb_137
        }
    }

    '__ci_bb_112 {
        ((*__local_parent__goto_40_1).key[0] = (*__local_key_ptr__goto_40_1))
        goto '__ci_bb_114
    }

    '__ci_bb_113 {
        ((*__local_parent__goto_40_1).key[0] = (*__local_key_ptr__goto_40_1))
        goto '__ci_bb_114
    }

    '__ci_bb_114 {
        ((*__local_parent__goto_40_1).kind.node[0] = __local_leaf__goto_40_1)
        ((*__local_parent__goto_40_1).kind.node[1] = __local_nleaf__goto_40_1)
        ((__param_b[0]).root = __local_parent__goto_40_1)
        goto '__ci_bb_115
    }

    '__ci_bb_115 {
        goto '__ci_bb_118
    }

    '__ci_bb_116 {
        if false {
            goto '__ci_bb_115
        } else {
            goto '__ci_bb_117
        }
    }

    '__ci_bb_117 {
        goto '__ci_bb_49
    }

    '__ci_bb_118 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_121
        } else {
            goto '__ci_bb_122
        }
    }

    '__ci_bb_119 {
        if false {
            goto '__ci_bb_118
        } else {
            goto '__ci_bb_120
        }
    }

    '__ci_bb_120 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            goto '__ci_bb_134
        } else {
            goto '__ci_bb_135
        }
    }

    '__ci_bb_121 {
        (__ci_expr_logic_10 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_10 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_10: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_124
        } else {
            goto '__ci_bb_125
        }
    }

    '__ci_bb_122 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_11 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_11 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_11: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_123
    }

    '__ci_bb_123 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_126
    }

    '__ci_bb_124 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_125
    }

    '__ci_bb_125 {
        goto '__ci_bb_123
    }

    '__ci_bb_126 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_127
        } else {
            goto '__ci_bb_129
        }
    }

    '__ci_bb_127 {
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_128
    }

    '__ci_bb_128 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_126
    }

    '__ci_bb_129 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_130
        } else {
            goto '__ci_bb_131
        }
    }

    '__ci_bb_130 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_131
    }

    '__ci_bb_131 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_132
        } else {
            goto '__ci_bb_133
        }
    }

    '__ci_bb_132 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_133
    }

    '__ci_bb_133 {
        goto '__ci_bb_119
    }

    '__ci_bb_134 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_135
    }

    '__ci_bb_135 {
        goto '__ci_bb_116
    }

    '__ci_bb_136 {
        goto '__ci_bb_138
    }

    '__ci_bb_137 {
        if ((if not ((*__local_parent__goto_40_1).num == (16 + 1)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"parent->num == 16+1".ptr)
        } else {
            0
        }
        (__local_nnp__goto_40_1 = (((16 / 2) as i32)))
        (__local_np__goto_40_1 = (((16 - __local_nnp__goto_40_1) as i32)))
        (__ci_expr_logic_15 = 0)
        (__ci_expr_logic_14 = 0)
        if (__local_nnp__goto_40_1 > 0) {
            (__ci_expr_logic_14 = (if __local_np__goto_40_1 > 0: 1 else: 0))
        }
        if __ci_expr_logic_14 {
            (__ci_expr_logic_15 = (if ((__local_nnp__goto_40_1 + __local_np__goto_40_1) + 1) == (16 + 1): 1 else: 0))
        }
        if ((if not __ci_expr_logic_15: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"nnp > 0 && np > 0 && nnp+np+1 == 16+1".ptr)
        } else {
            0
        }
        (__local_nparent__goto_40_1 = mlib_word_tree_new_node())
        with_memmove(((((&raw const (*__local_nparent__goto_40_1).key[0] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (*__local_parent__goto_40_1).key[(__local_np__goto_40_1 + 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((__local_nnp__goto_40_1 as u32) as u64)) as u64) as i64))
        with_memmove(((((&raw const (*__local_nparent__goto_40_1).kind.node[0] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (*__local_parent__goto_40_1).kind.node[(__local_np__goto_40_1 + 1)] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_nnp__goto_40_1 + 1) as u32) as u64)) as u64) as i64))
        ((*__local_parent__goto_40_1).num = __local_np__goto_40_1)
        ((*__local_nparent__goto_40_1).num = __local_nnp__goto_40_1)
        ((*__local_nparent__goto_40_1).next = (*__local_parent__goto_40_1).next)
        ((*__local_parent__goto_40_1).next = __local_nparent__goto_40_1)
        ((*__local_nparent__goto_40_1).prev = __local_parent__goto_40_1)
        if ((*__local_nparent__goto_40_1).next != null) {
            goto '__ci_bb_159
        } else {
            goto '__ci_bb_160
        }
    }

    '__ci_bb_138 {
        goto '__ci_bb_141
    }

    '__ci_bb_139 {
        if false {
            goto '__ci_bb_138
        } else {
            goto '__ci_bb_140
        }
    }

    '__ci_bb_140 {
        goto '__ci_bb_49
    }

    '__ci_bb_141 {
        if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_144
        } else {
            goto '__ci_bb_145
        }
    }

    '__ci_bb_142 {
        if false {
            goto '__ci_bb_141
        } else {
            goto '__ci_bb_143
        }
    }

    '__ci_bb_143 {
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }
        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            goto '__ci_bb_157
        } else {
            goto '__ci_bb_158
        }
    }

    '__ci_bb_144 {
        (__ci_expr_logic_12 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_12 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_12: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_147
        } else {
            goto '__ci_bb_148
        }
    }

    '__ci_bb_145 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_13 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_13 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_13: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_146
    }

    '__ci_bb_146 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_149
    }

    '__ci_bb_147 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_148
    }

    '__ci_bb_148 {
        goto '__ci_bb_146
    }

    '__ci_bb_149 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_150
        } else {
            goto '__ci_bb_152
        }
    }

    '__ci_bb_150 {
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_151
    }

    '__ci_bb_151 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_149
    }

    '__ci_bb_152 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
            goto '__ci_bb_153
        } else {
            goto '__ci_bb_154
        }
    }

    '__ci_bb_153 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2__goto_40_1 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_154
    }

    '__ci_bb_154 {
        if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
            goto '__ci_bb_155
        } else {
            goto '__ci_bb_156
        }
    }

    '__ci_bb_155 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_156
    }

    '__ci_bb_156 {
        goto '__ci_bb_142
    }

    '__ci_bb_157 {
        if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
        } else {
            0
        }
        goto '__ci_bb_158
    }

    '__ci_bb_158 {
        goto '__ci_bb_139
    }

    '__ci_bb_159 {
        ((*(*__local_nparent__goto_40_1).next).prev = __local_nparent__goto_40_1)
        goto '__ci_bb_160
    }

    '__ci_bb_160 {
        goto '__ci_bb_161
    }

    '__ci_bb_161 {
        if ((if not (__local_parent__goto_40_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(parent) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*__local_parent__goto_40_1).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (__local_parent__goto_40_1 == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_164
        } else {
            goto '__ci_bb_165
        }
    }

    '__ci_bb_162 {
        if false {
            goto '__ci_bb_161
        } else {
            goto '__ci_bb_163
        }
    }

    '__ci_bb_163 {
        goto '__ci_bb_177
    }

    '__ci_bb_164 {
        (__ci_expr_logic_16 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_16 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_16: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_167
        } else {
            goto '__ci_bb_168
        }
    }

    '__ci_bb_165 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_17 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_17 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_17: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_166
    }

    '__ci_bb_166 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_169
    }

    '__ci_bb_167 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_168
    }

    '__ci_bb_168 {
        goto '__ci_bb_166
    }

    '__ci_bb_169 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_170
        } else {
            goto '__ci_bb_172
        }
    }

    '__ci_bb_170 {
        if ((if not ((if (*__local_parent__goto_40_1).key[(__local_i2__goto_40_1 - 1)] < (*__local_parent__goto_40_1).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*__local_parent__goto_40_1).key[(__local_i2__goto_40_1 - 1)] > (*__local_parent__goto_40_1).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((parent)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(parent)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((parent)->key[i2-1]) < ((parent)->key[i2]) ? -1 : ((parent)->key[i2-1]) > ((parent)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_171
    }

    '__ci_bb_171 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_169
    }

    '__ci_bb_172 {
        if ((*__local_parent__goto_40_1).next != null) {
            goto '__ci_bb_173
        } else {
            goto '__ci_bb_174
        }
    }

    '__ci_bb_173 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*__local_parent__goto_40_1).key[(__local_num2__goto_40_1 - 1)] < (*(*__local_parent__goto_40_1).next).key[0]: (-1 as i32) else: ((if (*__local_parent__goto_40_1).key[(__local_num2__goto_40_1 - 1)] > (*(*__local_parent__goto_40_1).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((parent)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(parent)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((parent)->key[num2-1]) < ((parent)->next->key[0]) ? -1 : ((parent)->key[num2-1]) > ((parent)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_174
    }

    '__ci_bb_174 {
        if ((*__local_parent__goto_40_1).prev != null) {
            goto '__ci_bb_175
        } else {
            goto '__ci_bb_176
        }
    }

    '__ci_bb_175 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*__local_parent__goto_40_1).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*__local_parent__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*__local_parent__goto_40_1).key[0]: (-1 as i32) else: ((if (*(*__local_parent__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*__local_parent__goto_40_1).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((parent)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(parent)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((parent)->prev->key[num_prev-1]) < ((parent)->key[0]) ? -1 : ((parent)->prev->key[num_prev-1]) > ((parent)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_176
    }

    '__ci_bb_176 {
        goto '__ci_bb_162
    }

    '__ci_bb_177 {
        if ((if not (__local_nparent__goto_40_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(nparent) != ((void*)0)".ptr)
        } else {
            0
        }
        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }
        (__local_num2__goto_40_1 = (*__local_nparent__goto_40_1).num)
        (__local_is_leaf2__goto_40_1 = ((__local_num2__goto_40_1 <= 0)))
        (__local_num2__goto_40_1 = (((if __local_num2__goto_40_1 < 0: ((0 - __local_num2__goto_40_1) as i32) else: __local_num2__goto_40_1) as i32)))
        if (__local_nparent__goto_40_1 == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            goto '__ci_bb_180
        } else {
            goto '__ci_bb_181
        }
    }

    '__ci_bb_178 {
        if false {
            goto '__ci_bb_177
        } else {
            goto '__ci_bb_179
        }
    }

    '__ci_bb_179 {
        (__local_key_ptr__goto_40_1 = (((&raw const (*__local_parent__goto_40_1).key[__local_np__goto_40_1] as *const i64) as *mut i64)))
        (__local_leaf__goto_40_1 = __local_parent__goto_40_1)
        (__local_nleaf__goto_40_1 = __local_nparent__goto_40_1)
        goto '__ci_bb_107
    }

    '__ci_bb_180 {
        (__ci_expr_logic_18 = 0)
        if (0 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_18 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_18: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        if (__local_num2__goto_40_1 == 0) {
            goto '__ci_bb_183
        } else {
            goto '__ci_bb_184
        }
    }

    '__ci_bb_181 {
        (__local_c2__goto_40_1 = (((16 / 2) as i32)))
        if ((if not (__local_c2__goto_40_1 > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
        } else {
            0
        }
        (__ci_expr_logic_19 = 0)
        if (__local_c2__goto_40_1 <= __local_num2__goto_40_1) {
            (__ci_expr_logic_19 = (if __local_num2__goto_40_1 <= 16: 1 else: 0))
        }
        if ((if not __ci_expr_logic_19: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
        } else {
            0
        }
        goto '__ci_bb_182
    }

    '__ci_bb_182 {
        (__local_i2__goto_40_1 = ((1 as i32)))
        goto '__ci_bb_185
    }

    '__ci_bb_183 {
        if ((if not __local_is_leaf2__goto_40_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
        } else {
            0
        }
        goto '__ci_bb_184
    }

    '__ci_bb_184 {
        goto '__ci_bb_182
    }

    '__ci_bb_185 {
        if (__local_i2__goto_40_1 < __local_num2__goto_40_1) {
            goto '__ci_bb_186
        } else {
            goto '__ci_bb_188
        }
    }

    '__ci_bb_186 {
        if ((if not ((if (*__local_nparent__goto_40_1).key[(__local_i2__goto_40_1 - 1)] < (*__local_nparent__goto_40_1).key[__local_i2__goto_40_1]: (-1 as i32) else: ((if (*__local_nparent__goto_40_1).key[(__local_i2__goto_40_1 - 1)] > (*__local_nparent__goto_40_1).key[__local_i2__goto_40_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nparent)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nparent)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nparent)->key[i2-1]) < ((nparent)->key[i2]) ? -1 : ((nparent)->key[i2-1]) > ((nparent)->key[i2])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_187
    }

    '__ci_bb_187 {
        (__local_i2__goto_40_1 = __local_i2__goto_40_1 + 1)
        goto '__ci_bb_185
    }

    '__ci_bb_188 {
        if ((*__local_nparent__goto_40_1).next != null) {
            goto '__ci_bb_189
        } else {
            goto '__ci_bb_190
        }
    }

    '__ci_bb_189 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*__local_nparent__goto_40_1).key[(__local_num2__goto_40_1 - 1)] < (*(*__local_nparent__goto_40_1).next).key[0]: (-1 as i32) else: ((if (*__local_nparent__goto_40_1).key[(__local_num2__goto_40_1 - 1)] > (*(*__local_nparent__goto_40_1).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nparent)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nparent)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nparent)->key[num2-1]) < ((nparent)->next->key[0]) ? -1 : ((nparent)->key[num2-1]) > ((nparent)->next->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_190
    }

    '__ci_bb_190 {
        if ((*__local_nparent__goto_40_1).prev != null) {
            goto '__ci_bb_191
        } else {
            goto '__ci_bb_192
        }
    }

    '__ci_bb_191 {
        if ((if not (__local_num2__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
        } else {
            0
        }
        (__local_num_prev__goto_40_1 = (*(*__local_nparent__goto_40_1).prev).num)
        (__local_num_prev__goto_40_1 = (((if __local_num_prev__goto_40_1 < 0: ((0 - __local_num_prev__goto_40_1) as i32) else: __local_num_prev__goto_40_1) as i32)))
        if ((if not (__local_num_prev__goto_40_1 >= 1): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
        } else {
            0
        }
        if ((if not ((if (*(*__local_nparent__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] < (*__local_nparent__goto_40_1).key[0]: (-1 as i32) else: ((if (*(*__local_nparent__goto_40_1).prev).key[(__local_num_prev__goto_40_1 - 1)] > (*__local_nparent__goto_40_1).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_set_at".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((nparent)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(nparent)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((nparent)->prev->key[num_prev-1]) < ((nparent)->key[0]) ? -1 : ((nparent)->prev->key[num_prev-1]) > ((nparent)->key[0])) < 0".ptr)
        } else {
            0
        }
        goto '__ci_bb_192
    }

    '__ci_bb_192 {
        goto '__ci_bb_178
    }

    __ci_unreachable()

}

// contract: receiver:mlib_word_tree_node_s,unproved:1:read only
pub unsafe fn mlib_word_tree_i_search_for_node(__param_parent: *mut mlib_word_tree_node_s, __param_child: *mut mlib_word_tree_node_s) -> i32 {
    if ((if not (not (*__param_parent).mlib_word_tree_is_leaf()): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_i_search_for_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"!mlib_word_tree_is_leaf(parent)".ptr)
    } else {
        0
    }

    var __local_num: i32 = (((*__param_parent).mlib_word_tree_get_num() as i32))

    var __local_i: i32 = ((0 as i32))

    while (__local_i <= __local_num) {
        if ((*(&raw const (*__param_parent).kind as *const mlib_word_tree_kind_s)).node[__local_i] == __param_child) {
            return __local_i
        }


        (__local_i = __local_i + 1)

    }


    return -1

}

// contract: unproved:0:out-parameter written conditionally,unproved:1:out-parameter written conditionally
pub unsafe fn mlib_word_tree_pop_at(__param_ptr: *mut *mut c_void, __param_b: *mut mlib_word_tree_s, __param_key: i64) -> bool {
    if (__param_ptr != null) {
        var __local_ref: *mut *mut c_void = mlib_word_tree_get((&(__param_b[0]) as *mut mlib_word_tree_s), __param_key)

        if (__local_ref == null) {
            return ((false as bool))

        }

        ((*__param_ptr) = (*__local_ref))

    }

    return (*(&(__param_b[0]) as *mut mlib_word_tree_s)).mlib_word_tree_erase(__param_key)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_word_tree_min(__param_b: *mut mlib_word_tree_s) -> *mut *mut c_void {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_min".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not (not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size == 0)): 1 else: 0) as i64) {
        return ((null as *mut *mut c_void))
    }

    var __local_n: *mut mlib_word_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root

    while (not (*__local_n).mlib_word_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[0])

    }

    return (((&raw const (*__local_n).kind.value[0] as *const *mut c_void) as *mut *mut c_void))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_word_tree_max(__param_b: *mut mlib_word_tree_s) -> *mut *mut c_void {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_max".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not (not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size == 0)): 1 else: 0) as i64) {
        return ((null as *mut *mut c_void))
    }

    var __local_n: *mut mlib_word_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root

    while (not (*__local_n).mlib_word_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[(*__local_n).num])

    }

    return (((&raw const (*__local_n).kind.value[((0 - (*__local_n).num) - 1)] as *const *mut c_void) as *mut *mut c_void))

}

@[repr(C)]
pub type mlib_word_tree_cmin_literal_anon = union { ptr: *mut *mut c_void = null, cptr: *const *mut c_void = null }
impl Copy for mlib_word_tree_cmin_literal_anon
// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_word_tree_cmin(__param_tree: *mut mlib_word_tree_s) -> *const *mut c_void {
    return (mlib_word_tree_cmin_literal_anon { ptr: mlib_word_tree_min((&(__param_tree[0]) as *mut mlib_word_tree_s)) } as mlib_word_tree_cmin_literal_anon).cptr

}

@[repr(C)]
pub type mlib_word_tree_cmax_literal_anon = union { ptr: *mut *mut c_void = null, cptr: *const *mut c_void = null }
impl Copy for mlib_word_tree_cmax_literal_anon
// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn mlib_word_tree_cmax(__param_tree: *mut mlib_word_tree_s) -> *const *mut c_void {
    return (mlib_word_tree_cmax_literal_anon { ptr: mlib_word_tree_max((&(__param_tree[0]) as *mut mlib_word_tree_s)) } as mlib_word_tree_cmax_literal_anon).cptr

}

// contract: receiver-mut:mlib_word_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_word_tree_init_move(__param_b: *mut mlib_word_tree_s, __param_ref: *mut mlib_word_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((ref)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((ref)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[i2-1]) < (((ref)->root+0)->key[i2]) ? -1 : (((ref)->root+0)->key[i2-1]) > (((ref)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[num2-1]) < (((ref)->root+0)->next->key[0]) ? -1 : (((ref)->root+0)->key[num2-1]) > (((ref)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->prev->key[num_prev-1]) < (((ref)->root+0)->key[0]) ? -1 : (((ref)->root+0)->prev->key[num_prev-1]) > (((ref)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(ref)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(ref)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(ref)->root->num == (int) (ref)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __ci_expr_logic_2: i32 = 0

    if ((&(__param_b[0]) as *mut c_void) != null) {
        (__ci_expr_logic_2 = (if (&(__param_b[0]) as *mut mlib_word_tree_s) != (&(__param_ref[0]) as *mut mlib_word_tree_s): 1 else: 0))
    }

    if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"b != ((void*)0) && b != ref".ptr)
    } else {
        0
    }


    ((__param_b[0]).size = (*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).size)

    ((__param_b[0]).root = (*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root)

    ((__param_ref[0]).root = ((null as *mut mlib_word_tree_node_s)))

    ((__param_ref[0]).size = ((1 as u64)))

    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_3: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_4: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_4 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_word_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_word_tree_move(__param_b: *mut mlib_word_tree_s, __param_ref: *mut mlib_word_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((ref)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((ref)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] < (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] > (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[i2-1]) < (((ref)->root+0)->key[i2]) ? -1 : (((ref)->root+0)->key[i2-1]) > (((ref)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] < (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] > (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->key[num2-1]) < (((ref)->root+0)->next->key[0]) ? -1 : (((ref)->root+0)->key[num2-1]) > (((ref)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] < (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] > (*((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((ref)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((ref)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((ref)->root+0)->prev->key[num_prev-1]) < (((ref)->root+0)->key[0]) ? -1 : (((ref)->root+0)->prev->key[num_prev-1]) > (((ref)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(ref)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(ref)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_ref[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(ref)->root->num == (int) (ref)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_b[0]) as *mut mlib_word_tree_s) != (&(__param_ref[0]) as *mut mlib_word_tree_s)): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"b != ref".ptr)
    } else {
        0
    }

    (*(&(__param_b[0]) as *mut mlib_word_tree_s)).mlib_word_tree_clear()

    mlib_word_tree_init_move((&(__param_b[0]) as *mut mlib_word_tree_s), (&(__param_ref[0]) as *mut mlib_word_tree_s))

    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_2: bool = ((__local_num2_2 <= 0))

            (__local_num2_2 = (((if __local_num2_2 < 0: ((0 - __local_num2_2) as i32) else: __local_num2_2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_4: i32 = 0

                if (0 <= __local_num2_2) {
                    (__ci_expr_logic_4 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_2 == 0) {
                    if ((if not __local_is_leaf2_2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_5: i32 = 0

                if (__local_c2_2 <= __local_num2_2) {
                    (__ci_expr_logic_5 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_2: i32 = ((1 as i32))

            while (__local_i2_2 < __local_num2_2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_2 = __local_i2_2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_2: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_2 = (((if __local_num_prev_2 < 0: ((0 - __local_num_prev_2) as i32) else: __local_num_prev_2) as i32)))

                if ((if not (__local_num_prev_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_move".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_word_tree_s,unproved:1:read only
pub unsafe fn mlib_word_tree_set(__param_b: *mut mlib_word_tree_s, __param_o: *mut mlib_word_tree_s) {
    var __local_tmp: [mlib_word_tree_s; 1]

    var __local_cont: bool = true

    while __local_cont {
        mlib_word_tree_init_set((&__local_tmp[0] as *mut mlib_word_tree_s), (&(__param_o[0]) as *mut mlib_word_tree_s))

        mlib_word_tree_move((&(__param_b[0]) as *mut mlib_word_tree_s), (&__local_tmp[0] as *mut mlib_word_tree_s))


        (__local_cont = false)

    }


}

// contract: receiver-mut:mlib_word_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_word_tree_swap(__param_tree1: *mut mlib_word_tree_s, __param_tree2: *mut mlib_word_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[i2-1]) < (((tree1)->root+0)->key[i2]) ? -1 : (((tree1)->root+0)->key[i2-1]) > (((tree1)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[num2-1]) < (((tree1)->root+0)->next->key[0]) ? -1 : (((tree1)->root+0)->key[num2-1]) > (((tree1)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->prev->key[num_prev-1]) < (((tree1)->root+0)->key[0]) ? -1 : (((tree1)->root+0)->prev->key[num_prev-1]) > (((tree1)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(tree1)->root->num == (int) (tree1)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] < (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] > (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[i2-1]) < (((tree2)->root+0)->key[i2]) ? -1 : (((tree2)->root+0)->key[i2-1]) > (((tree2)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] < (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] > (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[num2-1]) < (((tree2)->root+0)->next->key[0]) ? -1 : (((tree2)->root+0)->key[num2-1]) > (((tree2)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] < (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] > (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->prev->key[num_prev-1]) < (((tree2)->root+0)->key[0]) ? -1 : (((tree2)->root+0)->prev->key[num_prev-1]) > (((tree2)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(tree2)->root->num == (int) (tree2)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {
        var __local__tmp: u64 = (*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).size

        ((__param_tree1[0]).size = (*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).size)

        ((__param_tree2[0]).size = __local__tmp)

        if not (false) {
            break
        }
    }

    loop {
        var __local__tmp_1: *mut mlib_word_tree_node_s = (*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root

        ((__param_tree1[0]).root = (*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root)

        ((__param_tree2[0]).root = __local__tmp_1)

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_2: i32 = (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_2: bool = ((__local_num2_2 <= 0))

            (__local_num2_2 = (((if __local_num2_2 < 0: ((0 - __local_num2_2) as i32) else: __local_num2_2) as i32)))

            if (((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_4: i32 = 0

                if (0 <= __local_num2_2) {
                    (__ci_expr_logic_4 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_2 == 0) {
                    if ((if not __local_is_leaf2_2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_5: i32 = 0

                if (__local_c2_2 <= __local_num2_2) {
                    (__ci_expr_logic_5 = (if __local_num2_2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_2: i32 = ((1 as i32))

            while (__local_i2_2 < __local_num2_2) {
                if ((if not ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)] < (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_2]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_2 - 1)] > (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[i2-1]) < (((tree1)->root+0)->key[i2]) ? -1 : (((tree1)->root+0)->key[i2-1]) > (((tree1)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_2 = __local_i2_2 + 1)

            }


            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)] < (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_2 - 1)] > (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->key[num2-1]) < (((tree1)->root+0)->next->key[0]) ? -1 : (((tree1)->root+0)->key[num2-1]) > (((tree1)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_2: i32 = (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_2 = (((if __local_num_prev_2 < 0: ((0 - __local_num_prev_2) as i32) else: __local_num_prev_2) as i32)))

                if ((if not (__local_num_prev_2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)] < (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_2 - 1)] > (*((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree1)->root+0)->prev->key[num_prev-1]) < (((tree1)->root+0)->key[0]) ? -1 : (((tree1)->root+0)->prev->key[num_prev-1]) > (((tree1)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_tree1[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(tree1)->root->num == (int) (tree1)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((tree2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_3: i32 = (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_3: bool = ((__local_num2_3 <= 0))

            (__local_num2_3 = (((if __local_num2_3 < 0: ((0 - __local_num2_3) as i32) else: __local_num2_3) as i32)))

            if (((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_6: i32 = 0

                if (0 <= __local_num2_3) {
                    (__ci_expr_logic_6 = (if __local_num2_3 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_6: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_3 == 0) {
                    if ((if not __local_is_leaf2_3: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_3: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_3 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_7: i32 = 0

                if (__local_c2_3 <= __local_num2_3) {
                    (__ci_expr_logic_7 = (if __local_num2_3 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_7: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_3: i32 = ((1 as i32))

            while (__local_i2_3 < __local_num2_3) {
                if ((if not ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_3 - 1)] < (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_3]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_3 - 1)] > (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_3]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[i2-1]) < (((tree2)->root+0)->key[i2]) ? -1 : (((tree2)->root+0)->key[i2-1]) > (((tree2)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_3 = __local_i2_3 + 1)

            }


            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_3 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_3 - 1)] < (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_3 - 1)] > (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->key[num2-1]) < (((tree2)->root+0)->next->key[0]) ? -1 : (((tree2)->root+0)->key[num2-1]) > (((tree2)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_3 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_3: i32 = (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_3 = (((if __local_num_prev_3 < 0: ((0 - __local_num_prev_3) as i32) else: __local_num_prev_3) as i32)))

                if ((if not (__local_num_prev_3 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_3 - 1)] < (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_3 - 1)] > (*((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((tree2)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((tree2)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((tree2)->root+0)->prev->key[num_prev-1]) < (((tree2)->root+0)->key[0]) ? -1 : (((tree2)->root+0)->prev->key[num_prev-1]) > (((tree2)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(tree2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_tree2[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_swap".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(tree2)->root->num == (int) (tree2)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

}

// contract: receiver-mut:mlib_word_tree_it_s,unproved:1:read only
pub unsafe fn mlib_word_tree_it(__param_it_: *mut mlib_word_tree_it_s, __param_b: *mut mlib_word_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_it".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut mlib_word_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root

    while (not (*__local_n).mlib_word_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[0])

    }

    ((__param_it_[0]).node = __local_n)

    ((__param_it_[0]).idx = ((0 as i32)))

}

// contract: receiver-mut:mlib_word_tree_it_s,unproved:1:read only
pub unsafe fn mlib_word_tree_it_end(__param_it_: *mut mlib_word_tree_it_s, __param_b: *mut mlib_word_tree_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_it_end".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_n: *mut mlib_word_tree_node_s = (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root

    while (not (*__local_n).mlib_word_tree_is_leaf()) {
        (__local_n = (*(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[(*__local_n).num])

    }

    ((__param_it_[0]).node = __local_n)

    ((__param_it_[0]).idx = (((0 - (*__local_n).num) as i32)))

}

// contract: receiver-mut:mlib_word_tree_it_s,unproved:1:read only
pub unsafe fn mlib_word_tree_it_set(__param_itd: *mut mlib_word_tree_it_s, __param_its: *mut mlib_word_tree_it_s) {
    var __ci_expr_logic_0: i32 = 0

    if ((&(__param_itd[0]) as *mut c_void) != null) {
        (__ci_expr_logic_0 = (if (&(__param_its[0]) as *mut c_void) != null: 1 else: 0))
    }

    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_it_set".ptr, c"facade_shapes.c".ptr, (40 as i32), c"itd != ((void*)0) && its != ((void*)0)".ptr)
    } else {
        0
    }


    ((__param_itd[0]).node = (*(&raw const (__param_its[0]) as *const mlib_word_tree_it_s)).node)

    ((__param_itd[0]).idx = (*(&raw const (__param_its[0]) as *const mlib_word_tree_it_s)).idx)

}

// contract: receiver:mlib_word_tree_it_s,unproved:1:read only
pub unsafe fn mlib_word_tree_it_equal_p(__param_it1: *mut mlib_word_tree_it_s, __param_it2: *mut mlib_word_tree_it_s) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((*(&raw const (__param_it1[0]) as *const mlib_word_tree_it_s)).node == (*(&raw const (__param_it2[0]) as *const mlib_word_tree_it_s)).node) {
        (__ci_expr_logic_0 = (if (*(&raw const (__param_it1[0]) as *const mlib_word_tree_it_s)).idx == (*(&raw const (__param_it2[0]) as *const mlib_word_tree_it_s)).idx: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver-mut:mlib_word_tree_it_s,unproved:1:read only
pub unsafe fn mlib_word_tree_it_last(__param_it_: *mut mlib_word_tree_it_s, __param_b: *mut mlib_word_tree_s) {
    mlib_word_tree_it_end((&(__param_it_[0]) as *mut mlib_word_tree_it_s), (&(__param_b[0]) as *mut mlib_word_tree_s))

    (*(&(__param_it_[0]) as *mut mlib_word_tree_it_s)).mlib_word_tree_previous()

}

@[repr(C)]
pub type mlib_word_tree_cref_literal_anon = union { ptr: *mut mlib_word_tree_pair_s = null, cptr: *const mlib_word_tree_pair_s = null }
impl Copy for mlib_word_tree_cref_literal_anon
// contract: receiver-mut:mlib_word_tree_it_s,unproved:1:read only
pub unsafe fn mlib_word_tree_it_from(__param_it_: *mut mlib_word_tree_it_s, __param_b: *mut mlib_word_tree_s, __param_key: i64) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((if not ((&(__param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0)".ptr)
    } else {
        0
    }

    var __local_pit: [mlib_word_tree_parent_it_s; 1]

    var __local_n: *mut mlib_word_tree_node_s = mlib_word_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_word_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_word_tree_s), __param_key)

    ((__param_it_[0]).node = __local_n)

    var __local_i: i32

    loop {
        if ((if not (__local_n != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(n) != ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b->root) != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_num2_1: i32 = (*__local_n).num

        var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

        (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

        if (__local_n == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
            var __ci_expr_logic_2: i32 = 0

            if (0 <= __local_num2_1) {
                (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


            if (__local_num2_1 == 0) {
                if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                } else {
                    0
                }
            }

        } else {
            var __local_c2_1: i32 = (((16 / 2) as i32))

            if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_3: i32 = 0

            if (__local_c2_1 <= __local_num2_1) {
                (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
            }

            if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
            } else {
                0
            }


        }

        var __local_i2_1: i32 = ((1 as i32))

        while (__local_i2_1 < __local_num2_1) {
            if ((if not ((if (*__local_n).key[(__local_i2_1 - 1)] < (*__local_n).key[__local_i2_1]: (-1 as i32) else: ((if (*__local_n).key[(__local_i2_1 - 1)] > (*__local_n).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[i2-1]) < ((n)->key[i2]) ? -1 : ((n)->key[i2-1]) > ((n)->key[i2])) < 0".ptr)
            } else {
                0
            }


            (__local_i2_1 = __local_i2_1 + 1)

        }


        if ((*__local_n).next != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            if ((if not ((if (*__local_n).key[(__local_num2_1 - 1)] < (*(*__local_n).next).key[0]: (-1 as i32) else: ((if (*__local_n).key[(__local_num2_1 - 1)] > (*(*__local_n).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->key[num2-1]) < ((n)->next->key[0]) ? -1 : ((n)->key[num2-1]) > ((n)->next->key[0])) < 0".ptr)
            } else {
                0
            }

        }

        if ((*__local_n).prev != null) {
            if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
            } else {
                0
            }

            var __local_num_prev_1: i32 = (*(*__local_n).prev).num

            (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

            if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
            } else {
                0
            }

            if ((if not ((if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] < (*__local_n).key[0]: (-1 as i32) else: ((if (*(*__local_n).prev).key[(__local_num_prev_1 - 1)] > (*__local_n).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_it_from".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic((n)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"(n)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), ((n)->prev->key[num_prev-1]) < ((n)->key[0]) ? -1 : ((n)->prev->key[num_prev-1]) > ((n)->key[0])) < 0".ptr)
            } else {
                0
            }

        }

        if not (false) {
            break
        }
    }

    (__local_i = ((0 as i32)))

    while (__local_i < (0 - (*__local_n).num)) {
        if ((if __param_key < (*__local_n).key[__local_i]: (-1 as i32) else: ((if __param_key > (*__local_n).key[__local_i]: 1 else: 0) as i32)) <= 0) {
            break
        }


        (__local_i = __local_i + 1)

    }


    var __ci_expr_logic_4: i32 = 0

    if (__local_i == (0 - (*__local_n).num)) {
        (__ci_expr_logic_4 = (if (*__local_n).next != null: 1 else: 0))
    }

    if __ci_expr_logic_4 {
        ((__param_it_[0]).node = (*__local_n).next)

        (__local_i = ((0 as i32)))

    }


    ((__param_it_[0]).idx = __local_i)

}

// contract: receiver-mut:mlib_word_tree_s,unproved:1:out-parameter read before the write
pub unsafe fn mlib_word_tree_remove(__param_b: *mut mlib_word_tree_s, __param_it_: *mut mlib_word_tree_it_s) {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    var __local_n: *mut mlib_word_tree_node_s = (*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node

    if ((if not ((*__local_n).num < 0): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"n->num < 0".ptr)
    } else {
        0
    }

    var __local_i: i32 = (*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx

    var __local_num: i32 = (((*__local_n).mlib_word_tree_get_num() as i32))

    var __ci_expr_logic_2: i32 = 0

    if (__local_i >= 0) {
        (__ci_expr_logic_2 = (if __local_i < __local_num: 1 else: 0))
    }

    if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"i >= 0 && i < num".ptr)
    } else {
        0
    }


    var __local_pit: [mlib_word_tree_parent_it_s; 1]

    var __local_leaf: *mut mlib_word_tree_node_s = mlib_word_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_word_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_word_tree_s), ((*__local_n).key[__local_i] as i64))



    with_memmove(((((&raw const (*__local_n).key[__local_i] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (*__local_n).key[(__local_i + 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((((__local_num - 1) - __local_i) as u32) as u64)) as u64) as i64))

    with_memmove(((((&raw const (*__local_n).kind.value[__local_i] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (*__local_n).kind.value[(__local_i + 1)] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% ((((__local_num - 1) - __local_i) as u32) as u64)) as u64) as i64))

    ((*__local_n).num = (*__local_n).num - -1)

    ((__param_b[0]).size = ((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size -% 1))

    var __ci_expr_logic_3: i32 = 0

    if (__local_i >= (__local_num - 1)) {
        (__ci_expr_logic_3 = (if (*__local_n).next != null: 1 else: 0))
    }

    if ((if not (not __ci_expr_logic_3): 1 else: 0) as i64) {
        ((__param_it_[0]).node = (*__local_n).next)

        ((__param_it_[0]).idx = ((0 as i32)))

    }


    var __ci_expr_logic_4: i32

    if ((if not (not ((*__local_n).mlib_word_tree_get_num() >= (16 / 2))): 1 else: 0) as i64) {
        (__ci_expr_logic_4 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_4 = (if (*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root == __local_n: 1 else: 0))
    }

    if __ci_expr_logic_4 {
        return
    }


    while ((if not (not (__local_n != __local_leaf)): 1 else: 0) as i64) {
        if ((if not ((*__local_leaf).next != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"leaf->next != ((void*)0)".ptr)
        } else {
            0
        }

        (__local_leaf = (*__local_leaf).next)

        var __local_p_num: i32 = (*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num

        var __local_p_n: *mut mlib_word_tree_node_s = __local_leaf

        loop {
            if ((if not (__local_p_num >= 1): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"p_num >= 1".ptr)
            } else {
                0
            }

            var __local_parent: *mut mlib_word_tree_node_s = with 0 as __ci_expr_seq_208 {
                (__local_p_num = __local_p_num - 1)
                (*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).parent[__local_p_num]
            }

            var __local_k: i32 = ((mlib_word_tree_i_search_for_node(__local_parent, __local_p_n) as i32))

            if (__local_k >= 0) {
                break
            }

            (__local_pit[0].parent[__local_p_num] = (*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).parent[__local_p_num].next)

            (__local_p_n = (*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).parent[__local_p_num])

            if not (true) {
                break
            }
        }

    }

    if ((if not ((*__local_leaf).mlib_word_tree_get_num() == ((16 / 2) - 1)): 1 else: 0) as i64) {
        __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_get_num(leaf) == 16/2-1".ptr)
    } else {
        0
    }

    var __local_pass1: bool = true

    while true {
        if ((if not ((*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num > 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"pit->num > 0".ptr)
        } else {
            0
        }

        var __local_parent_1: *mut mlib_word_tree_node_s = with 0 as __ci_expr_seq_225 {
            (__local_pit[0].num = (*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num - 1)
            (*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).parent[(*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num]
        }

        if ((if not (__local_parent_1 != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"parent != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_k_1: i32 = ((mlib_word_tree_i_search_for_node(__local_parent_1, __local_leaf) as i32))

        if ((if not (__local_k_1 >= 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"k >= 0".ptr)
        } else {
            0
        }

        var __ci_expr_logic_5: i32 = 0

        if (__local_k_1 > 0) {
            (__ci_expr_logic_5 = (if (*((*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[(__local_k_1 - 1)] as *mut mlib_word_tree_node_s)).mlib_word_tree_get_num() > (16 / 2): 1 else: 0))
        }

        if __ci_expr_logic_5 {
            (*__local_parent_1).mlib_word_tree_i_left_shift(((__local_k_1 - 1) as i32))

            if ((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[__local_k_1]) {
                ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx + 1)

            } else {
                if ((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[(__local_k_1 - 1)]) {
                    if ((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx >= (*((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node)).mlib_word_tree_get_num()) {
                        ((__param_it_[0]).idx = ((0 as i32)))

                        ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[(__local_k_1 - 1)])

                    }

                }
            }

            return

        }
        var __ci_expr_logic_6: i32 = 0

        if (__local_k_1 < (*__local_parent_1).mlib_word_tree_get_num()) {
            (__ci_expr_logic_6 = (if (*((*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[(__local_k_1 + 1)] as *mut mlib_word_tree_node_s)).mlib_word_tree_get_num() > (16 / 2): 1 else: 0))
        }

        if __ci_expr_logic_6 {
            (*__local_parent_1).mlib_word_tree_i_right_shift(__local_k_1)

            if ((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[(__local_k_1 + 1)]) {
                if ((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx == 0) {
                    ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[__local_k_1])

                    ((__param_it_[0]).idx = ((((*((*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[__local_k_1] as *mut mlib_word_tree_node_s)).mlib_word_tree_get_num() - 1) as i32)))

                } else {
                    ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx - 1)

                }

            }

            return

        }



        if (__local_k_1 == (*__local_parent_1).mlib_word_tree_get_num()) {
            (__local_k_1 = __local_k_1 - 1)
        }

        var __ci_expr_logic_7: i32 = 0

        if (__local_k_1 >= 0) {
            (__ci_expr_logic_7 = (if __local_k_1 < (*__local_parent_1).mlib_word_tree_get_num(): 1 else: 0))
        }

        if ((if not __ci_expr_logic_7: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_remove".ptr, c"facade_shapes.c".ptr, (40 as i32), c"k >= 0 && k < mlib_word_tree_get_num(parent)".ptr)
        } else {
            0
        }


        (__local_num = (((*((*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[__local_k_1] as *mut mlib_word_tree_node_s)).mlib_word_tree_get_num() as i32)))

        var __local_it_to_fix: bool = (((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node == (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[(__local_k_1 + 1)]))

        (*__local_parent_1).mlib_word_tree_i_merge_node(__local_k_1, __local_pass1)

        if __local_it_to_fix {
            ((__param_it_[0]).node = (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[__local_k_1])

            ((__param_it_[0]).idx = (*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx + __local_num)

        }

        if ((*__local_parent_1).mlib_word_tree_get_num() >= (16 / 2)) {
            return
        }

        if ((*(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num == 0) {
            if ((*__local_parent_1).mlib_word_tree_get_num() == 0) {
                ((__param_b[0]).root = (*(&raw const (*__local_parent_1).kind as *const mlib_word_tree_kind_s)).node[0])

                with_free(((__local_parent_1 as *mut c_void) as *mut u8))

            }

            return

        }

        (__local_leaf = __local_parent_1)

        (__local_pass1 = false)

    }

}

// contract: receiver:mlib_word_tree_s,unproved:1:read only
pub unsafe fn mlib_word_tree_equal_p(__param_t1: *mut mlib_word_tree_s, __param_t2: *mut mlib_word_tree_s) -> bool {
    loop {

        loop {
            if ((if not (((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((t1)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((t1)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2: i32 = (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2: bool = ((__local_num2 <= 0))

            (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

            if (((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_0: i32 = 0

                if (0 <= __local_num2) {
                    (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2 == 0) {
                    if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_1: i32 = 0

                if (__local_c2 <= __local_num2) {
                    (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2: i32 = ((1 as i32))

            while (__local_i2 < __local_num2) {
                if ((if not ((if (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[i2-1]) < (((t1)->root+0)->key[i2]) ? -1 : (((t1)->root+0)->key[i2-1]) > (((t1)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2 = __local_i2 + 1)

            }


            if ((*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (*(*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (*(*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->key[num2-1]) < (((t1)->root+0)->next->key[0]) ? -1 : (((t1)->root+0)->key[num2-1]) > (((t1)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev: i32 = (*(*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (*((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t1)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t1)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t1)->root+0)->prev->key[num_prev-1]) < (((t1)->root+0)->key[0]) ? -1 : (((t1)->root+0)->prev->key[num_prev-1]) > (((t1)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(t1)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(t1)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(t1)->root->num == (int) (t1)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    loop {

        loop {
            if ((if not (((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((t2)->root+0) != ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((t2)->root) != ((void*)0)".ptr)
            } else {
                0
            }

            var __local_num2_1: i32 = (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

            var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

            (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

            if (((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root) {
                var __ci_expr_logic_2: i32 = 0

                if (0 <= __local_num2_1) {
                    (__ci_expr_logic_2 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


                if (__local_num2_1 == 0) {
                    if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                    } else {
                        0
                    }
                }

            } else {
                var __local_c2_1: i32 = (((16 / 2) as i32))

                if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                } else {
                    0
                }

                var __ci_expr_logic_3: i32 = 0

                if (__local_c2_1 <= __local_num2_1) {
                    (__ci_expr_logic_3 = (if __local_num2_1 <= 16: 1 else: 0))
                }

                if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                } else {
                    0
                }


            }

            var __local_i2_1: i32 = ((1 as i32))

            while (__local_i2_1 < __local_num2_1) {
                if ((if not ((if (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] < (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: (-1 as i32) else: ((if (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] > (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t2)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t2)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t2)->root+0)->key[i2-1]) < (((t2)->root+0)->key[i2]) ? -1 : (((t2)->root+0)->key[i2-1]) > (((t2)->root+0)->key[i2])) < 0".ptr)
                } else {
                    0
                }


                (__local_i2_1 = __local_i2_1 + 1)

            }


            if ((*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] < (*(*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] > (*(*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t2)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t2)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t2)->root+0)->key[num2-1]) < (((t2)->root+0)->next->key[0]) ? -1 : (((t2)->root+0)->key[num2-1]) > (((t2)->root+0)->next->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if ((*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                } else {
                    0
                }

                var __local_num_prev_1: i32 = (*(*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                } else {
                    0
                }

                if ((if not ((if (*(*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] < (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (*(*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] > (*((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((t2)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((t2)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((t2)->root+0)->prev->key[num_prev-1]) < (((t2)->root+0)->key[0]) ? -1 : (((t2)->root+0)->prev->key[num_prev-1]) > (((t2)->root+0)->key[0])) < 0".ptr)
                } else {
                    0
                }

            }

            if not (false) {
                break
            }
        }

        if ((if not ((*(*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(t2)->root->next == ((void*)0)".ptr)
        } else {
            0
        }

        if ((if not ((*(*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(t2)->root->prev == ((void*)0)".ptr)
        } else {
            0
        }

        if ((*(*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root).num <= 0) {
            if ((if not ((0 - (*(*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).root).num) == (((*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_equal_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(t2)->root->num == (int) (t2)->size".ptr)
            } else {
                0
            }
        }

        if not (false) {
            break
        }
    }

    if ((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).size != (*(&raw const (__param_t2[0]) as *const mlib_word_tree_s)).size) {
        return ((false as bool))
    }

    if ((*(&raw const (__param_t1[0]) as *const mlib_word_tree_s)).size == 0) {
        return ((true as bool))
    }

    var __local_it1: [mlib_word_tree_it_s; 1]

    var __local_it2: [mlib_word_tree_it_s; 1]

    mlib_word_tree_it((&__local_it1[0] as *mut mlib_word_tree_it_s), (&(__param_t1[0]) as *mut mlib_word_tree_s))

    mlib_word_tree_it((&__local_it2[0] as *mut mlib_word_tree_it_s), (&(__param_t2[0]) as *mut mlib_word_tree_s))

    while true {
        var __ci_expr_logic_4: i32 = 0

        if (not (*(&__local_it1[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_end_p()) {
            (__ci_expr_logic_4 = (if not (*(&__local_it2[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_end_p(): 1 else: 0))
        }

        if (not __ci_expr_logic_4) {
            break
        }

        var __local_ref1: *const mlib_word_tree_pair_s = (*(&__local_it1[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_cref()

        var __local_ref2: *const mlib_word_tree_pair_s = (*(&__local_it2[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_cref()

        if (not ((*((*__local_ref1).key_ptr)) == (*((*__local_ref2).key_ptr)))) {
            return ((false as bool))
        }

        if (not ((*((*__local_ref1).value_ptr)) == (*((*__local_ref2).value_ptr)))) {
            return ((false as bool))
        }

        (*(&__local_it1[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_next()

        (*(&__local_it2[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_next()

    }

    var __ci_expr_logic_5: i32 = 0

    if (*(&__local_it1[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_end_p() {
        (__ci_expr_logic_5 = (if (*(&__local_it2[0] as *mut mlib_word_tree_it_s)).mlib_word_tree_end_p(): 1 else: 0))
    }

    return (((__ci_expr_logic_5 != 0) as bool))


}

impl m_bptr33_transaction_t_anon {
    pub mut fn mlib_slot_tree_rewind_transaction() {
        let __param_records: *mut m_bptr33_transaction_t_anon = self as *mut m_bptr33_transaction_t_anon
        if ((if not ((&(unsafe __param_records[0]) as *mut c_void) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"records != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_j: i32 = ((((unsafe *(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size - 1) as i32))

        while (__local_j >= 0) {
            var __local_record: *mut m_bptr33_transaction_record_t = (((&raw const (unsafe __param_records[0]).tab[__local_j] as *const m_bptr33_transaction_record_t) as *mut m_bptr33_transaction_record_t))

            while true {
                match (unsafe *__local_record).type_ {
                    1 => {
                        with_free(((((unsafe *__local_record).data_dst as *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8))
                    },
                    2 => {
                        unsafe { mlib_slot_release((*((*__local_record).data_dst as *mut *mut mlib_slot_head))) }
                    },
                    3 => {
                        ((unsafe *((*__local_record).data_src as *mut *mut mlib_slot_head)) = (unsafe *((*__local_record).data_dst as *mut *mut mlib_slot_head)))
                    },
                    4 => {
                        unsafe { mlib_slot_release((*((*__local_record).data_dst as *mut *mut mlib_slot_head))) }
                    },
                    9 => {
                        var __local_t: *mut mlib_slot_tree_s = (((unsafe *__local_record).data_dst as *mut mlib_slot_tree_s))

                        if ((if not (__local_t != null): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"t != ((void*)0)".ptr)
                        } else {
                            0
                        }

                        if ((if not ((unsafe *__local_t).size > 0): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"t->size > 0".ptr)
                        } else {
                            0
                        }

                        ((unsafe *__local_t).size = ((unsafe *__local_t).size -% 1))

                    },
                    5 => {
                        var __local_a: *mut mlib_slot_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_slot_tree_node_s))

                        var __local_b: *mut mlib_slot_tree_node_s = (((unsafe *__local_record).data_src as *mut mlib_slot_tree_node_s))

                        var __ci_expr_logic_0: i32 = 0

                        if (__local_a != null) {
                            (__ci_expr_logic_0 = (if (unsafe *__local_a).next == __local_b: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"a != ((void*)0) && a->next == b".ptr)
                        } else {
                            0
                        }


                        var __ci_expr_logic_1: i32 = 0

                        if unsafe { (*__local_a).mlib_slot_tree_is_leaf() } {
                            (__ci_expr_logic_1 = (if unsafe { (*__local_b).mlib_slot_tree_is_leaf() }: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(a) && mlib_slot_tree_is_leaf(b)".ptr)
                        } else {
                            0
                        }


                        ((unsafe *__local_a).next = (unsafe *__local_b).next)

                        if ((unsafe *__local_b).next != null) {
                            ((unsafe *(*__local_b).next).prev = __local_a)

                        }

                        var __local_na: i32 = ((unsafe { (*__local_a).mlib_slot_tree_get_num() } as i32))

                        var __local_nb: i32 = ((unsafe { (*__local_b).mlib_slot_tree_get_num() } as i32))

                        if ((if not ((__local_na + __local_nb) == (16 + 1)): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"na + nb == 16 + 1".ptr)
                        } else {
                            0
                        }

                        with_memmove(((((&raw const (unsafe *__local_a).key[__local_na] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_b).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_nb as u32) as u64)) as u64) as i64))

                        ((unsafe *__local_a).num = (unsafe *__local_a).num - __local_nb)

                    },
                    6 => {
                        var __local_a_1: *mut mlib_slot_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_slot_tree_node_s))

                        var __local_b_1: *mut mlib_slot_tree_node_s = (((unsafe *__local_record).data_src as *mut mlib_slot_tree_node_s))

                        var __ci_expr_logic_2: i32 = 0

                        if (__local_a_1 != null) {
                            (__ci_expr_logic_2 = (if (unsafe *__local_a_1).next == __local_b_1: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"a != ((void*)0) && a->next == b".ptr)
                        } else {
                            0
                        }


                        var __ci_expr_logic_3: i32 = 0

                        if (not unsafe { (*__local_a_1).mlib_slot_tree_is_leaf() }) {
                            (__ci_expr_logic_3 = (if not unsafe { (*__local_b_1).mlib_slot_tree_is_leaf() }: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"!mlib_slot_tree_is_leaf(a) && !mlib_slot_tree_is_leaf(b)".ptr)
                        } else {
                            0
                        }


                        ((unsafe *__local_a_1).next = (unsafe *__local_b_1).next)

                        if ((unsafe *__local_b_1).next != null) {
                            ((unsafe *(*__local_b_1).next).prev = __local_a_1)

                        }

                        var __local_na_1: i32 = ((unsafe { (*__local_a_1).mlib_slot_tree_get_num() } as i32))

                        var __local_nb_1: i32 = ((unsafe { (*__local_b_1).mlib_slot_tree_get_num() } as i32))

                        if ((if not (((__local_na_1 + __local_nb_1) + 1) == (16 + 1)): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"na + nb + 1 == 16 + 1".ptr)
                        } else {
                            0
                        }

                        with_memmove(((((&raw const (unsafe *__local_a_1).key[(__local_na_1 + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_b_1).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_nb_1 as u32) as u64)) as u64) as i64))

                        with_memmove(((((&raw const (unsafe *__local_a_1).kind.node[(__local_na_1 + 1)] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_b_1).kind.node[0] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_nb_1 + 1) as u32) as u64)) as u64) as i64))

                        ((unsafe *__local_a_1).num = (unsafe *__local_a_1).num + (__local_nb_1 + 1))

                    },
                    7 => {
                        var __local_n: *mut mlib_slot_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_slot_tree_node_s))

                        if ((if not unsafe { (*__local_n).mlib_slot_tree_is_leaf() }: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(n)".ptr)
                        } else {
                            0
                        }

                        var __local_i: i32 = ((((unsafe *__local_record).data_src as i64) as i32))

                        var __local_num: i32 = with 0 as __ci_expr_seq_89 {
                            ((unsafe *__local_n).num = (unsafe *__local_n).num + 1)
                            ((0 - (unsafe *__local_n).num) as i32)
                        }

                        with_memmove(((((&raw const (unsafe *__local_n).key[__local_i] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_n).key[(__local_i + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

                    },
                    8 => {
                        var __local_n_1: *mut mlib_slot_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_slot_tree_node_s))

                        if ((if not (not unsafe { (*__local_n_1).mlib_slot_tree_is_leaf() }): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"!mlib_slot_tree_is_leaf(n)".ptr)
                        } else {
                            0
                        }

                        var __local_i_1: i32 = ((((unsafe *__local_record).data_src as i64) as i32))

                        var __local_num_1: i32 = with 0 as __ci_expr_seq_101 {
                            ((unsafe *__local_n_1).num = (unsafe *__local_n_1).num - 1)
                            (unsafe *__local_n_1).num
                        }

                        with_memmove(((((&raw const (unsafe *__local_n_1).key[__local_i_1] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_n_1).key[(__local_i_1 + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num_1 - __local_i_1) as u32) as u64)) as u64) as i64))

                        with_memmove(((((&raw const (unsafe *__local_n_1).kind.node[__local_i_1] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_n_1).kind.node[(__local_i_1 + 1)] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num_1 - __local_i_1) + 1) as u32) as u64)) as u64) as i64))

                    },
                    _ => {
                        if (1 as i64) {
                            __assert_rtn(c"mlib_slot_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0".ptr)
                        } else {
                            0
                        }
                    },
                }

                break

            }


            (__local_j = __local_j - 1)

        }


        ((unsafe __param_records[0]).size = ((0 as i32)))

        return

    }

    pub mut fn mlib_word_tree_rewind_transaction() {
        let __param_records: *mut m_bptr33_transaction_t_anon = self as *mut m_bptr33_transaction_t_anon
        if ((if not ((&(unsafe __param_records[0]) as *mut c_void) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"records != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_j: i32 = ((((unsafe *(&raw const (__param_records[0]) as *const m_bptr33_transaction_t_anon)).size - 1) as i32))

        while (__local_j >= 0) {
            var __local_record: *mut m_bptr33_transaction_record_t = (((&raw const (unsafe __param_records[0]).tab[__local_j] as *const m_bptr33_transaction_record_t) as *mut m_bptr33_transaction_record_t))

            while true {
                match (unsafe *__local_record).type_ {
                    1 => {
                        with_free(((((unsafe *__local_record).data_dst as *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8))
                    },
                    2 => {
                        0
                    },
                    3 => {
                        ((unsafe *((*__local_record).data_src as *mut i64)) = (unsafe *((*__local_record).data_dst as *mut i64)))
                    },
                    4 => {
                        0
                    },
                    9 => {
                        var __local_t: *mut mlib_word_tree_s = (((unsafe *__local_record).data_dst as *mut mlib_word_tree_s))

                        if ((if not (__local_t != null): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"t != ((void*)0)".ptr)
                        } else {
                            0
                        }

                        if ((if not ((unsafe *__local_t).size > 0): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"t->size > 0".ptr)
                        } else {
                            0
                        }

                        ((unsafe *__local_t).size = ((unsafe *__local_t).size -% 1))

                    },
                    5 => {
                        var __local_a: *mut mlib_word_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_word_tree_node_s))

                        var __local_b: *mut mlib_word_tree_node_s = (((unsafe *__local_record).data_src as *mut mlib_word_tree_node_s))

                        var __ci_expr_logic_0: i32 = 0

                        if (__local_a != null) {
                            (__ci_expr_logic_0 = (if (unsafe *__local_a).next == __local_b: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"a != ((void*)0) && a->next == b".ptr)
                        } else {
                            0
                        }


                        var __ci_expr_logic_1: i32 = 0

                        if unsafe { (*__local_a).mlib_word_tree_is_leaf() } {
                            (__ci_expr_logic_1 = (if unsafe { (*__local_b).mlib_word_tree_is_leaf() }: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(a) && mlib_word_tree_is_leaf(b)".ptr)
                        } else {
                            0
                        }


                        ((unsafe *__local_a).next = (unsafe *__local_b).next)

                        if ((unsafe *__local_b).next != null) {
                            ((unsafe *(*__local_b).next).prev = __local_a)

                        }

                        var __local_na: i32 = ((unsafe { (*__local_a).mlib_word_tree_get_num() } as i32))

                        var __local_nb: i32 = ((unsafe { (*__local_b).mlib_word_tree_get_num() } as i32))

                        if ((if not ((__local_na + __local_nb) == (16 + 1)): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"na + nb == 16 + 1".ptr)
                        } else {
                            0
                        }

                        with_memmove(((((&raw const (unsafe *__local_a).key[__local_na] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_b).key[0] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((__local_nb as u32) as u64)) as u64) as i64))

                        with_memmove(((((&raw const (unsafe *__local_a).kind.value[__local_na] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_b).kind.value[0] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% ((__local_nb as u32) as u64)) as u64) as i64))

                        ((unsafe *__local_a).num = (unsafe *__local_a).num - __local_nb)

                    },
                    6 => {
                        var __local_a_1: *mut mlib_word_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_word_tree_node_s))

                        var __local_b_1: *mut mlib_word_tree_node_s = (((unsafe *__local_record).data_src as *mut mlib_word_tree_node_s))

                        var __ci_expr_logic_2: i32 = 0

                        if (__local_a_1 != null) {
                            (__ci_expr_logic_2 = (if (unsafe *__local_a_1).next == __local_b_1: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"a != ((void*)0) && a->next == b".ptr)
                        } else {
                            0
                        }


                        var __ci_expr_logic_3: i32 = 0

                        if (not unsafe { (*__local_a_1).mlib_word_tree_is_leaf() }) {
                            (__ci_expr_logic_3 = (if not unsafe { (*__local_b_1).mlib_word_tree_is_leaf() }: 1 else: 0))
                        }

                        if ((if not __ci_expr_logic_3: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"!mlib_word_tree_is_leaf(a) && !mlib_word_tree_is_leaf(b)".ptr)
                        } else {
                            0
                        }


                        ((unsafe *__local_a_1).next = (unsafe *__local_b_1).next)

                        if ((unsafe *__local_b_1).next != null) {
                            ((unsafe *(*__local_b_1).next).prev = __local_a_1)

                        }

                        var __local_na_1: i32 = ((unsafe { (*__local_a_1).mlib_word_tree_get_num() } as i32))

                        var __local_nb_1: i32 = ((unsafe { (*__local_b_1).mlib_word_tree_get_num() } as i32))

                        if ((if not (((__local_na_1 + __local_nb_1) + 1) == (16 + 1)): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"na + nb + 1 == 16 + 1".ptr)
                        } else {
                            0
                        }

                        with_memmove(((((&raw const (unsafe *__local_a_1).key[(__local_na_1 + 1)] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_b_1).key[0] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((__local_nb_1 as u32) as u64)) as u64) as i64))

                        with_memmove(((((&raw const (unsafe *__local_a_1).kind.node[(__local_na_1 + 1)] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_b_1).kind.node[0] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_nb_1 + 1) as u32) as u64)) as u64) as i64))

                        ((unsafe *__local_a_1).num = (unsafe *__local_a_1).num + (__local_nb_1 + 1))

                    },
                    7 => {
                        var __local_n: *mut mlib_word_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_word_tree_node_s))

                        if ((if not unsafe { (*__local_n).mlib_word_tree_is_leaf() }: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(n)".ptr)
                        } else {
                            0
                        }

                        var __local_i: i32 = ((((unsafe *__local_record).data_src as i64) as i32))

                        var __local_num: i32 = with 0 as __ci_expr_seq_94 {
                            ((unsafe *__local_n).num = (unsafe *__local_n).num + 1)
                            ((0 - (unsafe *__local_n).num) as i32)
                        }

                        with_memmove(((((&raw const (unsafe *__local_n).key[__local_i] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_n).key[(__local_i + 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

                        with_memmove(((((&raw const (unsafe *__local_n).kind.value[__local_i] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_n).kind.value[(__local_i + 1)] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% (((__local_num - __local_i) as u32) as u64)) as u64) as i64))

                    },
                    8 => {
                        var __local_n_1: *mut mlib_word_tree_node_s = (((unsafe *__local_record).data_dst as *mut mlib_word_tree_node_s))

                        if ((if not (not unsafe { (*__local_n_1).mlib_word_tree_is_leaf() }): 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"!mlib_word_tree_is_leaf(n)".ptr)
                        } else {
                            0
                        }

                        var __local_i_1: i32 = ((((unsafe *__local_record).data_src as i64) as i32))

                        var __local_num_1: i32 = with 0 as __ci_expr_seq_107 {
                            ((unsafe *__local_n_1).num = (unsafe *__local_n_1).num - 1)
                            (unsafe *__local_n_1).num
                        }

                        with_memmove(((((&raw const (unsafe *__local_n_1).key[__local_i_1] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_n_1).key[(__local_i_1 + 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% (((__local_num_1 - __local_i_1) as u32) as u64)) as u64) as i64))

                        with_memmove(((((&raw const (unsafe *__local_n_1).kind.node[__local_i_1] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_n_1).kind.node[(__local_i_1 + 1)] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num_1 - __local_i_1) + 1) as u32) as u64)) as u64) as i64))

                    },
                    _ => {
                        if (1 as i64) {
                            __assert_rtn(c"mlib_word_tree_rewind_transaction".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0".ptr)
                        } else {
                            0
                        }
                    },
                }

                break

            }


            (__local_j = __local_j - 1)

        }


        ((unsafe __param_records[0]).size = ((0 as i32)))

        return

    }

}

impl m_core_backoff_s {
    pub mut fn m_core_backoff_init() {
        let __param_backoff: *mut m_core_backoff_s = self as *mut m_core_backoff_s
        ((unsafe __param_backoff[0]).count = ((0 as u32)))

        ((unsafe __param_backoff[0]).seed = ((0 as u32)))

    }

    pub mut fn m_core_backoff_reset() {
        let __param_backoff: *mut m_core_backoff_s = self as *mut m_core_backoff_s
        ((unsafe __param_backoff[0]).count = ((0 as u32)))

    }

    pub mut fn m_core_backoff_wait() {
        let __param_backoff: *mut m_core_backoff_s = self as *mut m_core_backoff_s
        if ((unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).count <= 2) {
            ((unsafe __param_backoff[0]).count = ((unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).count +% 1))

            if ((unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).count < 3) {
                return
            }

            ((unsafe __param_backoff[0]).seed = ((rand() as u32)))

        }

        var __local_x: i32 = ((0 as i32))

        ((unsafe __param_backoff[0]).seed = (((((((unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).seed as u32) *% (34721 as u32)) as u32) +% (17449 as u32)) as u32)))

        var __local_mask: u32 = ((((((1 as u32) << ((unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).count as u32)) as u32) -% (1 as u32)) as u32))

        var __local_count: u32 = ((((__local_mask as u32) & ((((unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).seed as u32) >> (8 as u32)) as u32)) as u32))

        var __local_i: u32 = ((0 as u32))

        while (__local_i <= __local_count) {
            (__local_x = ((0 as i32)))

            (__local_i = (__local_i +% 1))

        }


        __local_x

        ((unsafe __param_backoff[0]).count = ((unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).count +% ((if (unsafe *(&raw const (__param_backoff[0]) as *const m_core_backoff_s)).count < 8: 1 else: 0) as u32)))

    }

    pub fn m_core_backoff_clear() {
        let __param_backoff: *mut m_core_backoff_s = (self as *const m_core_backoff_s) as *mut m_core_backoff_s
        return
    }

}

impl m_serial_read_s {
    pub mut fn m_core_in_serial_enum() -> i64 {
        let __param_serial: *mut m_serial_read_s = self as *mut m_serial_read_s
        var __local_i: i64

        ((unsafe __param_serial[0]).tmp.r = ((unsafe { (*(*(&raw const (__param_serial[0]) as *const m_serial_read_s)).m_interface).read_integer.unwrap()((&(__param_serial[0]) as *mut m_serial_read_s), (&raw mut __local_i as *mut i64), (sizeof[i64]() as u64)) } as i32)))

        return __local_i

    }

}

impl mlib_slot_tree_it_s {
    pub fn mlib_slot_tree_end_p() -> bool {
        let __param_it_: *mut mlib_slot_tree_it_s = (self as *const mlib_slot_tree_it_s) as *mut mlib_slot_tree_it_s
        var __ci_expr_logic_0: i32 = 0

        if ((&(unsafe __param_it_[0]) as *mut c_void) != null) {
            (__ci_expr_logic_0 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_end_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
        } else {
            0
        }


        if ((if not unsafe { (*((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node)).mlib_slot_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_end_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(it->node)".ptr)
        } else {
            0
        }

        return (((((((unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx as u32)) >= (((0 - (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).num) as u32)))) as bool))

    }

    pub mut fn mlib_slot_tree_next() {
        let __param_it_: *mut mlib_slot_tree_it_s = self as *mut mlib_slot_tree_it_s
        var __ci_expr_logic_0: i32 = 0

        if ((&(unsafe __param_it_[0]) as *mut c_void) != null) {
            (__ci_expr_logic_0 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_next".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
        } else {
            0
        }


        if ((if not unsafe { (*((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node)).mlib_slot_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_next".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(it->node)".ptr)
        } else {
            0
        }

        ((unsafe __param_it_[0]).idx = (unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx + 1)

        var __ci_expr_logic_1: i32 = 0

        if ((unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx >= (0 - (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).num)) {
            (__ci_expr_logic_1 = (if (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).next != null: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            ((unsafe __param_it_[0]).node = (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).next)

            ((unsafe __param_it_[0]).idx = ((0 as i32)))

        }


    }

    pub mut fn mlib_slot_tree_previous() {
        let __param_it_: *mut mlib_slot_tree_it_s = self as *mut mlib_slot_tree_it_s
        var __ci_expr_logic_0: i32 = 0

        if ((&(unsafe __param_it_[0]) as *mut c_void) != null) {
            (__ci_expr_logic_0 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_previous".ptr, c"facade_shapes.c".ptr, (34 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
        } else {
            0
        }


        if ((if not unsafe { (*((*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node)).mlib_slot_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_previous".ptr, c"facade_shapes.c".ptr, (34 as i32), c"mlib_slot_tree_is_leaf(it->node)".ptr)
        } else {
            0
        }

        ((unsafe __param_it_[0]).idx = (unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx - 1)

        var __ci_expr_logic_1: i32 = 0

        if ((unsafe *(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).idx < 0) {
            (__ci_expr_logic_1 = (if (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).prev != null: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            ((unsafe __param_it_[0]).node = (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).prev)

            ((unsafe __param_it_[0]).idx = ((((0 - (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_slot_tree_it_s)).node).num) - 1) as i32)))

        }


    }

}

impl mlib_slot_tree_node_s {
    pub fn mlib_slot_tree_is_leaf() -> bool {
        let __param_n: *mut mlib_slot_tree_node_s = (self as *const mlib_slot_tree_node_s) as *mut mlib_slot_tree_node_s
        return (((((unsafe *__param_n).num <= 0)) as bool))

    }

    pub fn mlib_slot_tree_get_num() -> i32 {
        let __param_n: *mut mlib_slot_tree_node_s = (self as *const mlib_slot_tree_node_s) as *mut mlib_slot_tree_node_s
        var __local_num: i32 = (unsafe *__param_n).num

        (__local_num = (((if __local_num < 0: ((0 - __local_num) as i32) else: __local_num) as i32)))

        if ((if not (__local_num <= 16): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_get_num".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num <= 16".ptr)
        } else {
            0
        }

        return __local_num

    }

    pub mut fn mlib_slot_tree_i_left_shift(__param_k: i32) -> Unit {
        let __param_parent: *mut mlib_slot_tree_node_s = self as *mut mlib_slot_tree_node_s
        var __ci_expr_logic_0: i32 = 0

        if (__param_parent != null) {
            (__ci_expr_logic_0 = (if not unsafe { (*__param_parent).mlib_slot_tree_is_leaf() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"parent != ((void*)0) && !mlib_slot_tree_is_leaf(parent)".ptr)
        } else {
            0
        }


        var __ci_expr_logic_1: i32 = 0

        if (0 <= __param_k) {
            (__ci_expr_logic_1 = (if __param_k < unsafe { (*__param_parent).mlib_slot_tree_get_num() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= k && k < mlib_slot_tree_get_num(parent)".ptr)
        } else {
            0
        }



        var __local_left: *mut mlib_slot_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_slot_tree_kind_s)).node[__param_k]

        var __local_right: *mut mlib_slot_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_slot_tree_kind_s)).node[(__param_k + 1)]

        var __ci_expr_logic_2: i32 = 0

        if (__local_left != null) {
            (__ci_expr_logic_2 = (if __local_right != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"left != ((void*)0) && right != ((void*)0)".ptr)
        } else {
            0
        }


        var __local_num_left: i32 = ((unsafe { (*__local_left).mlib_slot_tree_get_num() } as i32))

        var __local_num_right: i32 = ((unsafe { (*__local_right).mlib_slot_tree_get_num() } as i32))

        if ((if not (__local_num_left > (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_left > 16/2".ptr)
        } else {
            0
        }

        if ((if not (__local_num_right < (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_right < 16/2".ptr)
        } else {
            0
        }

        with_memmove(((((&raw const (unsafe *__local_right).key[1] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

        if unsafe { (*__local_left).mlib_slot_tree_is_leaf() } {
            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_left).key[(__local_num_left - 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64))

            ((unsafe *__local_right).num = ((((0 - __local_num_right) - 1) as i32)))

            ((unsafe *__local_left).num = ((((0 - __local_num_left) + 1) as i32)))

            unsafe { mlib_slot_release((*__param_parent).key[__param_k]) }

            ((unsafe *__param_parent).key[__param_k] = unsafe { mlib_slot_clone((*__local_left).key[(__local_num_left - 2)]) })


        } else {
            with_memmove(((((&raw const (unsafe *__local_right).kind.node[1] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.node[0] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num_right + 1) as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).key[__param_k] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64))

            ((unsafe *__local_right).kind.node[0] = (unsafe *(&raw const (*__local_left).kind as *const mlib_slot_tree_kind_s)).node[__local_num_left])

            ((unsafe *__local_right).num = (((__local_num_right + 1) as i32)))

            ((unsafe *__local_left).num = (((__local_num_left - 1) as i32)))

            with_memmove(((((&raw const (unsafe *__param_parent).key[__param_k] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_left).key[(__local_num_left - 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64))

        }

        if ((if not ((unsafe *__local_right).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"right->num != 0".ptr)
        } else {
            0
        }

        if ((if not ((unsafe *__local_left).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"left->num != 0".ptr)
        } else {
            0
        }

    }

    pub mut fn mlib_slot_tree_i_right_shift(__param_k: i32) -> Unit {
        let __param_parent: *mut mlib_slot_tree_node_s = self as *mut mlib_slot_tree_node_s
        var __ci_expr_logic_0: i32 = 0

        if (__param_parent != null) {
            (__ci_expr_logic_0 = (if not unsafe { (*__param_parent).mlib_slot_tree_is_leaf() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"parent != ((void*)0) && !mlib_slot_tree_is_leaf(parent)".ptr)
        } else {
            0
        }


        var __ci_expr_logic_1: i32 = 0

        if (0 <= __param_k) {
            (__ci_expr_logic_1 = (if __param_k < unsafe { (*__param_parent).mlib_slot_tree_get_num() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= k && k < mlib_slot_tree_get_num(parent)".ptr)
        } else {
            0
        }



        var __local_left: *mut mlib_slot_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_slot_tree_kind_s)).node[__param_k]

        var __local_right: *mut mlib_slot_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_slot_tree_kind_s)).node[(__param_k + 1)]

        var __ci_expr_logic_2: i32 = 0

        if (__local_left != null) {
            (__ci_expr_logic_2 = (if __local_right != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"left != ((void*)0) && right != ((void*)0)".ptr)
        } else {
            0
        }


        var __local_num_left: i32 = ((unsafe { (*__local_left).mlib_slot_tree_get_num() } as i32))

        var __local_num_right: i32 = ((unsafe { (*__local_right).mlib_slot_tree_get_num() } as i32))

        if ((if not (__local_num_left < (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_left < 16/2".ptr)
        } else {
            0
        }

        if ((if not (__local_num_right > (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_right > 16/2".ptr)
        } else {
            0
        }

        if unsafe { (*__local_right).mlib_slot_tree_is_leaf() } {
            with_memmove(((((&raw const (unsafe *__local_left).key[__local_num_left] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[1] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num_right - 1) as u32) as u64)) as u64) as i64))

            ((unsafe *__local_right).num = ((((0 - __local_num_right) + 1) as i32)))

            ((unsafe *__local_left).num = ((((0 - __local_num_left) - 1) as i32)))

            unsafe { mlib_slot_release((*__param_parent).key[__param_k]) }

            ((unsafe *__param_parent).key[__param_k] = unsafe { mlib_slot_clone((*__local_left).key[__local_num_left]) })


        } else {
            with_memmove(((((&raw const (unsafe *__local_left).key[__local_num_left] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).key[__param_k] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64))

            with_memmove(((((&raw const (unsafe *__param_parent).key[__param_k] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[1] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num_right - 1) as u32) as u64)) as u64) as i64))

            ((unsafe *__local_left).kind.node[(__local_num_left + 1)] = (unsafe *(&raw const (*__local_right).kind as *const mlib_slot_tree_kind_s)).node[0])

            with_memmove(((((&raw const (unsafe *__local_right).kind.node[0] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.node[1] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            ((unsafe *__local_right).num = (((__local_num_right - 1) as i32)))

            ((unsafe *__local_left).num = (((__local_num_left + 1) as i32)))

        }

        if ((if not ((unsafe *__local_right).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"right->num != 0".ptr)
        } else {
            0
        }

        if ((if not ((unsafe *__local_left).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (34 as i32), c"left->num != 0".ptr)
        } else {
            0
        }

    }

    pub mut fn mlib_slot_tree_i_merge_node(__param_k: i32, __param_leaf: bool) {
        let __param_parent: *mut mlib_slot_tree_node_s = self as *mut mlib_slot_tree_node_s
        var __ci_expr_logic_0: i32 = 0

        if (__param_parent != null) {
            (__ci_expr_logic_0 = (if not unsafe { (*__param_parent).mlib_slot_tree_is_leaf() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"parent != ((void*)0) && !mlib_slot_tree_is_leaf(parent)".ptr)
        } else {
            0
        }


        var __ci_expr_logic_1: i32 = 0

        if (0 <= __param_k) {
            (__ci_expr_logic_1 = (if __param_k < unsafe { (*__param_parent).mlib_slot_tree_get_num() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= k && k < mlib_slot_tree_get_num(parent)".ptr)
        } else {
            0
        }


        var __local_left: *mut mlib_slot_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_slot_tree_kind_s)).node[__param_k]

        var __local_right: *mut mlib_slot_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_slot_tree_kind_s)).node[(__param_k + 1)]

        var __ci_expr_logic_2: i32 = 0

        if (__local_left != null) {
            (__ci_expr_logic_2 = (if __local_right != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"left != ((void*)0) && right != ((void*)0)".ptr)
        } else {
            0
        }


        var __local_num_parent: i32 = ((unsafe { (*__param_parent).mlib_slot_tree_get_num() } as i32))

        var __local_num_left: i32 = ((unsafe { (*__local_left).mlib_slot_tree_get_num() } as i32))

        var __local_num_right: i32 = ((unsafe { (*__local_right).mlib_slot_tree_get_num() } as i32))

        if __param_leaf {
            if ((if not ((__local_num_left + __local_num_right) <= 16): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_left + num_right <= 16".ptr)
            } else {
                0
            }

            with_memmove(((((&raw const (unsafe *__local_left).key[__local_num_left] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            ((unsafe *__local_left).num = ((((0 - __local_num_left) - __local_num_right) as i32)))

        } else {
            if ((if not ((__local_num_left + __local_num_right) <= (16 - 1)): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_left + num_right <= 16 -1".ptr)
            } else {
                0
            }

            with_memmove(((((&raw const (unsafe *__local_left).key[(__local_num_left + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_left).kind.node[(__local_num_left + 1)] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.node[0] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num_right + 1) as u32) as u64)) as u64) as i64))

            ((unsafe *__local_left).key[__local_num_left] = unsafe { mlib_slot_clone((*__param_parent).key[__param_k]) })

            ((unsafe *__local_left).num = ((((__local_num_left + 1) + __local_num_right) as i32)))

        }

        ((unsafe *__local_left).next = (unsafe *__local_right).next)

        if ((unsafe *__local_left).next != null) {
            ((unsafe *(*__local_left).next).prev = __local_left)

        }

        with_free(((__local_right as *mut c_void) as *mut u8))

        unsafe { mlib_slot_release((*__param_parent).key[__param_k]) }

        with_memmove(((((&raw const (unsafe *__param_parent).key[__param_k] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).key[(__param_k + 1)] as *const *mut mlib_slot_head) as *mut *mut mlib_slot_head) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num_parent - __param_k) - 1) as u32) as u64)) as u64) as i64))

        with_memmove(((((&raw const (unsafe *__param_parent).kind.node[(__param_k + 1)] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).kind.node[(__param_k + 2)] as *const *mut mlib_slot_tree_node_s) as *mut *mut mlib_slot_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num_parent - __param_k) - 1) as u32) as u64)) as u64) as i64))

        ((unsafe *__param_parent).num = (unsafe *__param_parent).num - 1)

    }

}

impl mlib_slot_tree_s {
    pub mut fn mlib_slot_tree_init() {
        let __param_b: *mut mlib_slot_tree_s = self as *mut mlib_slot_tree_s
        ((unsafe __param_b[0]).root = mlib_slot_tree_new_node())

        ((unsafe __param_b[0]).size = ((0 as u64)))

        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_init".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

    }

    pub mut fn mlib_slot_tree_reset() {
        let __param_b: *mut mlib_slot_tree_s = self as *mut mlib_slot_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        var __local_next: *mut mlib_slot_tree_node_s

        var __local_n: *mut mlib_slot_tree_node_s = (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root


        var __local_pit: [mlib_slot_tree_parent_it_s; 1]

        var __local_np: i32 = ((0 as i32))

        while (not unsafe { (*__local_n).mlib_slot_tree_is_leaf() }) {
            var __ci_expr_old_2: i32 = __local_np

            (__local_np = __local_np + 1)

            (__local_pit[0].parent[__ci_expr_old_2] = __local_n)


            if ((if not (__local_np <= ((((1 as u64) +% (((8 as u64) *% (sizeof[u64]() as u64)) as u64)) as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
            } else {
                0
            }

            (__local_n = (unsafe *(&raw const (*__local_n).kind as *const mlib_slot_tree_kind_s)).node[0])

        }

        var __ci_expr_old_3: i32 = __local_np

        (__local_np = __local_np + 1)

        (__local_pit[0].parent[__ci_expr_old_3] = __local_n)


        if ((if not (__local_np <= ((((1 as u64) +% (((8 as u64) *% (sizeof[u64]() as u64)) as u64)) as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
        } else {
            0
        }

        var __local_i: i32 = ((0 as i32))

        while (__local_i < __local_np) {
            (__local_n = (unsafe *(&raw const __local_pit[0] as *const mlib_slot_tree_parent_it_s)).parent[__local_i])

            while (__local_n != null) {
                var __local_num: i32 = ((unsafe { (*__local_n).mlib_slot_tree_get_num() } as i32))

                var __local_j: i32 = ((0 as i32))

                while (__local_j < __local_num) {
                    unsafe { mlib_slot_release((*__local_n).key[__local_j]) }


                    (__local_j = __local_j + 1)

                }


                (__local_next = (unsafe *__local_n).next)

                if (__local_i != 0) {
                    with_free(((__local_n as *mut c_void) as *mut u8))

                }

                (__local_n = __local_next)

            }


            (__local_i = __local_i + 1)

        }


        ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num = ((0 as i32)))

        ((unsafe __param_b[0]).size = ((0 as u64)))

        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2_1: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

                (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                    var __ci_expr_logic_4: i32 = 0

                    if (0 <= __local_num2_1) {
                        (__ci_expr_logic_4 = (if __local_num2_1 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2_1 == 0) {
                        if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2_1: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_5: i32 = 0

                    if (__local_c2_1 <= __local_num2_1) {
                        (__ci_expr_logic_5 = (if __local_num2_1 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2_1: i32 = ((1 as i32))

                while (__local_i2_1 < __local_num2_1) {
                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2_1 = __local_i2_1 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev_1: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                    if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_reset".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

    }

    pub mut fn mlib_slot_tree_clear() {
        let __param_b: *mut mlib_slot_tree_s = self as *mut mlib_slot_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_clear".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        unsafe { (*(&(__param_b[0]) as *mut mlib_slot_tree_s)).mlib_slot_tree_reset() }

        with_free((((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root as *mut c_void) as *mut u8))

        ((unsafe __param_b[0]).root = ((null as *mut mlib_slot_tree_node_s)))

    }

    pub fn mlib_slot_tree_empty_p() -> bool {
        let __param_b: *mut mlib_slot_tree_s = (self as *const mlib_slot_tree_s) as *mut mlib_slot_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_empty_p".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        return (((((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size == 0)) as bool))

    }

    pub fn mlib_slot_tree_size() -> u64 {
        let __param_b: *mut mlib_slot_tree_s = (self as *const mlib_slot_tree_s) as *mut mlib_slot_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[__local_i2] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[i2-1])->cmp((((b)->root+0)->key[i2-1]), (((b)->root+0)->key[i2]))) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)].cmp.unwrap()(((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] as *const c_void), ((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).next).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->key[num2-1])->cmp((((b)->root+0)->key[num2-1]), (((b)->root+0)->next->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not (unsafe { (*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)].cmp.unwrap()(((*(*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] as *const c_void), ((*((*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root + ((0 as isize) as usize))).key[0] as *const c_void)) } < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"((((b)->root+0)->prev->key[num_prev-1])->cmp((((b)->root+0)->prev->key[num_prev-1]), (((b)->root+0)->key[0]))) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_slot_tree_size".ptr, c"facade_shapes.c".ptr, (34 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        return (unsafe *(&raw const (__param_b[0]) as *const mlib_slot_tree_s)).size

    }

}

impl mlib_word_tree_it_s {
    pub fn mlib_word_tree_end_p() -> bool {
        let __param_it_: *mut mlib_word_tree_it_s = (self as *const mlib_word_tree_it_s) as *mut mlib_word_tree_it_s
        var __ci_expr_logic_0: i32 = 0

        if ((&(unsafe __param_it_[0]) as *mut c_void) != null) {
            (__ci_expr_logic_0 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_end_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
        } else {
            0
        }


        if ((if not unsafe { (*((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node)).mlib_word_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_end_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(it->node)".ptr)
        } else {
            0
        }

        return (((((((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx as u32)) >= (((0 - (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).num) as u32)))) as bool))

    }

    pub mut fn mlib_word_tree_next() {
        let __param_it_: *mut mlib_word_tree_it_s = self as *mut mlib_word_tree_it_s
        var __ci_expr_logic_0: i32 = 0

        if ((&(unsafe __param_it_[0]) as *mut c_void) != null) {
            (__ci_expr_logic_0 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_next".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
        } else {
            0
        }


        if ((if not unsafe { (*((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node)).mlib_word_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_next".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(it->node)".ptr)
        } else {
            0
        }

        ((unsafe __param_it_[0]).idx = (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx + 1)

        var __ci_expr_logic_1: i32 = 0

        if ((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx >= (0 - (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).num)) {
            (__ci_expr_logic_1 = (if (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).next != null: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            ((unsafe __param_it_[0]).node = (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).next)

            ((unsafe __param_it_[0]).idx = ((0 as i32)))

        }


    }

    pub mut fn mlib_word_tree_previous() {
        let __param_it_: *mut mlib_word_tree_it_s = self as *mut mlib_word_tree_it_s
        var __ci_expr_logic_0: i32 = 0

        if ((&(unsafe __param_it_[0]) as *mut c_void) != null) {
            (__ci_expr_logic_0 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_previous".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
        } else {
            0
        }


        if ((if not unsafe { (*((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node)).mlib_word_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_previous".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(it->node)".ptr)
        } else {
            0
        }

        ((unsafe __param_it_[0]).idx = (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx - 1)

        var __ci_expr_logic_1: i32 = 0

        if ((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx < 0) {
            (__ci_expr_logic_1 = (if (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).prev != null: 1 else: 0))
        }

        if __ci_expr_logic_1 {
            ((unsafe __param_it_[0]).node = (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).prev)

            ((unsafe __param_it_[0]).idx = ((((0 - (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).num) - 1) as i32)))

        }


    }

    pub mut fn mlib_word_tree_ref() -> &mlib_word_tree_pair_s from self {
        let __param_it_: *mut mlib_word_tree_it_s = self as *mut mlib_word_tree_it_s
        var __ci_expr_logic_0: i32 = 0

        if ((&(unsafe __param_it_[0]) as *mut c_void) != null) {
            (__ci_expr_logic_0 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_ref".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0) && it->node != ((void*)0)".ptr)
        } else {
            0
        }


        if ((if not unsafe { (*((*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node)).mlib_word_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_ref".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(it->node)".ptr)
        } else {
            0
        }

        var __ci_expr_logic_1: i32 = 0

        if ((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx >= 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx <= (0 - (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).num): 1 else: 0))
        }

        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_ref".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it->idx >= 0 && it->idx <= -it->node->num".ptr)
        } else {
            0
        }


        ((unsafe __param_it_[0]).pair.key_ptr = (((&raw const (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).key[(unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx] as *const i64) as *mut i64)))

        ((unsafe __param_it_[0]).pair.value_ptr = (((&raw const (unsafe *(*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node).kind.value[(unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx] as *const *mut c_void) as *mut *mut c_void)))

        return unsafe { &*(((&raw const (*(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).pair as *const mlib_word_tree_pair_s) as *mut mlib_word_tree_pair_s)) }

    }

    pub mut fn mlib_word_tree_cref() -> *const mlib_word_tree_pair_s {
        let __param_it_: *mut mlib_word_tree_it_s = self as *mut mlib_word_tree_it_s
        return (mlib_word_tree_cref_literal_anon { ptr: unsafe { (((*(&(__param_it_[0]) as *mut mlib_word_tree_it_s)).mlib_word_tree_ref() as *const mlib_word_tree_pair_s) as *mut mlib_word_tree_pair_s) } } as mlib_word_tree_cref_literal_anon).cptr

    }

    pub fn mlib_word_tree_it_until_p(__param_key: i64) -> bool {
        let __param_it_: *mut mlib_word_tree_it_s = (self as *const mlib_word_tree_it_s) as *mut mlib_word_tree_it_s
        if ((if not ((&(unsafe __param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_until_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_n: *mut mlib_word_tree_node_s = (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node

        if ((((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx as u32)) >= (((0 - (unsafe *__local_n).num) as u32))) {
            return (((((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx >= 0)) as bool))
        }

        var __local_cmp: i32

        (__local_cmp = (((if (unsafe *__local_n).key[(unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx] < __param_key: (-1 as i32) else: ((if (unsafe *__local_n).key[(unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx] > __param_key: 1 else: 0) as i32)) as i32)))


        return ((((__local_cmp >= 0)) as bool))

    }

    pub fn mlib_word_tree_it_while_p(__param_key: i64) -> bool {
        let __param_it_: *mut mlib_word_tree_it_s = (self as *const mlib_word_tree_it_s) as *mut mlib_word_tree_it_s
        if ((if not ((&(unsafe __param_it_[0]) as *mut c_void) != null): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_it_while_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"it != ((void*)0)".ptr)
        } else {
            0
        }

        var __local_n: *mut mlib_word_tree_node_s = (unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).node

        if ((((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx as u32)) >= (((0 - (unsafe *__local_n).num) as u32))) {
            return (((((unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx < 0)) as bool))
        }

        var __local_cmp: i32

        (__local_cmp = (((if (unsafe *__local_n).key[(unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx] < __param_key: (-1 as i32) else: ((if (unsafe *__local_n).key[(unsafe *(&raw const (__param_it_[0]) as *const mlib_word_tree_it_s)).idx] > __param_key: 1 else: 0) as i32)) as i32)))


        return ((((__local_cmp <= 0)) as bool))

    }

}

impl mlib_word_tree_node_s {
    pub fn mlib_word_tree_is_leaf() -> bool {
        let __param_n: *mut mlib_word_tree_node_s = (self as *const mlib_word_tree_node_s) as *mut mlib_word_tree_node_s
        return (((((unsafe *__param_n).num <= 0)) as bool))

    }

    pub fn mlib_word_tree_get_num() -> i32 {
        let __param_n: *mut mlib_word_tree_node_s = (self as *const mlib_word_tree_node_s) as *mut mlib_word_tree_node_s
        var __local_num: i32 = (unsafe *__param_n).num

        (__local_num = (((if __local_num < 0: ((0 - __local_num) as i32) else: __local_num) as i32)))

        if ((if not (__local_num <= 16): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_get_num".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num <= 16".ptr)
        } else {
            0
        }

        return __local_num

    }

    pub mut fn mlib_word_tree_i_search_and_remove_in_leaf(__param_key: i64) -> i32 {
        let __param_n: *mut mlib_word_tree_node_s = self as *mut mlib_word_tree_node_s
        if ((if not unsafe { (*__param_n).mlib_word_tree_is_leaf() }: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_search_and_remove_in_leaf".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_is_leaf(n)".ptr)
        } else {
            0
        }


        var __local_num: i32 = ((unsafe { (*__param_n).mlib_word_tree_get_num() } as i32))

        var __local_i: i32 = ((0 as i32))

        while (__local_i < __local_num) {
            var __local_cmp: i32

            (__local_cmp = (((if __param_key < (unsafe *__param_n).key[__local_i]: (-1 as i32) else: ((if __param_key > (unsafe *__param_n).key[__local_i]: 1 else: 0) as i32)) as i32)))


            if (__local_cmp == 0) {


                with_memmove(((((&raw const (unsafe *__param_n).key[__local_i] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_n).key[(__local_i + 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((((__local_num - 1) - __local_i) as u32) as u64)) as u64) as i64))

                with_memmove(((((&raw const (unsafe *__param_n).kind.value[__local_i] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_n).kind.value[(__local_i + 1)] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% ((((__local_num - 1) - __local_i) as u32) as u64)) as u64) as i64))

                ((unsafe *__param_n).num = (unsafe *__param_n).num - -1)

                return __local_i

            }


            (__local_i = __local_i + 1)

        }


        return -1

    }

    pub mut fn mlib_word_tree_i_left_shift(__param_k: i32) -> Unit {
        let __param_parent: *mut mlib_word_tree_node_s = self as *mut mlib_word_tree_node_s
        var __ci_expr_logic_0: i32 = 0

        if (__param_parent != null) {
            (__ci_expr_logic_0 = (if not unsafe { (*__param_parent).mlib_word_tree_is_leaf() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"parent != ((void*)0) && !mlib_word_tree_is_leaf(parent)".ptr)
        } else {
            0
        }


        var __ci_expr_logic_1: i32 = 0

        if (0 <= __param_k) {
            (__ci_expr_logic_1 = (if __param_k < unsafe { (*__param_parent).mlib_word_tree_get_num() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= k && k < mlib_word_tree_get_num(parent)".ptr)
        } else {
            0
        }



        var __local_left: *mut mlib_word_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_word_tree_kind_s)).node[__param_k]

        var __local_right: *mut mlib_word_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_word_tree_kind_s)).node[(__param_k + 1)]

        var __ci_expr_logic_2: i32 = 0

        if (__local_left != null) {
            (__ci_expr_logic_2 = (if __local_right != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"left != ((void*)0) && right != ((void*)0)".ptr)
        } else {
            0
        }


        var __local_num_left: i32 = ((unsafe { (*__local_left).mlib_word_tree_get_num() } as i32))

        var __local_num_right: i32 = ((unsafe { (*__local_right).mlib_word_tree_get_num() } as i32))

        if ((if not (__local_num_left > (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_left > 16/2".ptr)
        } else {
            0
        }

        if ((if not (__local_num_right < (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_right < 16/2".ptr)
        } else {
            0
        }

        with_memmove(((((&raw const (unsafe *__local_right).key[1] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

        if unsafe { (*__local_left).mlib_word_tree_is_leaf() } {
            with_memmove(((((&raw const (unsafe *__local_right).kind.value[1] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.value[0] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_left).key[(__local_num_left - 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((sizeof[i64]() as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).kind.value[0] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_left).kind.value[(__local_num_left - 1)] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((8 as u64) as i64))

            ((unsafe *__local_right).num = ((((0 - __local_num_right) - 1) as i32)))

            ((unsafe *__local_left).num = ((((0 - __local_num_left) + 1) as i32)))

            ((unsafe *__param_parent).key[__param_k] = (((unsafe *__local_left).key[(__local_num_left - 2)] as i64)))

        } else {
            with_memmove(((((&raw const (unsafe *__local_right).kind.node[1] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.node[0] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num_right + 1) as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).key[__param_k] as *const i64) as *mut i64) as *const c_void) as *const u8), ((sizeof[i64]() as u64) as i64))

            ((unsafe *__local_right).kind.node[0] = (unsafe *(&raw const (*__local_left).kind as *const mlib_word_tree_kind_s)).node[__local_num_left])

            ((unsafe *__local_right).num = (((__local_num_right + 1) as i32)))

            ((unsafe *__local_left).num = (((__local_num_left - 1) as i32)))

            with_memmove(((((&raw const (unsafe *__param_parent).key[__param_k] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_left).key[(__local_num_left - 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((sizeof[i64]() as u64) as i64))

        }

        if ((if not ((unsafe *__local_right).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"right->num != 0".ptr)
        } else {
            0
        }

        if ((if not ((unsafe *__local_left).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_left_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"left->num != 0".ptr)
        } else {
            0
        }

    }

    pub mut fn mlib_word_tree_i_right_shift(__param_k: i32) -> Unit {
        let __param_parent: *mut mlib_word_tree_node_s = self as *mut mlib_word_tree_node_s
        var __ci_expr_logic_0: i32 = 0

        if (__param_parent != null) {
            (__ci_expr_logic_0 = (if not unsafe { (*__param_parent).mlib_word_tree_is_leaf() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"parent != ((void*)0) && !mlib_word_tree_is_leaf(parent)".ptr)
        } else {
            0
        }


        var __ci_expr_logic_1: i32 = 0

        if (0 <= __param_k) {
            (__ci_expr_logic_1 = (if __param_k < unsafe { (*__param_parent).mlib_word_tree_get_num() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= k && k < mlib_word_tree_get_num(parent)".ptr)
        } else {
            0
        }



        var __local_left: *mut mlib_word_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_word_tree_kind_s)).node[__param_k]

        var __local_right: *mut mlib_word_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_word_tree_kind_s)).node[(__param_k + 1)]

        var __ci_expr_logic_2: i32 = 0

        if (__local_left != null) {
            (__ci_expr_logic_2 = (if __local_right != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"left != ((void*)0) && right != ((void*)0)".ptr)
        } else {
            0
        }


        var __local_num_left: i32 = ((unsafe { (*__local_left).mlib_word_tree_get_num() } as i32))

        var __local_num_right: i32 = ((unsafe { (*__local_right).mlib_word_tree_get_num() } as i32))

        if ((if not (__local_num_left < (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_left < 16/2".ptr)
        } else {
            0
        }

        if ((if not (__local_num_right > (16 / 2)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_right > 16/2".ptr)
        } else {
            0
        }

        if unsafe { (*__local_right).mlib_word_tree_is_leaf() } {
            with_memmove(((((&raw const (unsafe *__local_left).key[__local_num_left] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *const c_void) as *const u8), ((sizeof[i64]() as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[1] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% (((__local_num_right - 1) as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_left).kind.value[__local_num_left] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.value[0] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((8 as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).kind.value[0] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.value[1] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% (((__local_num_right - 1) as u32) as u64)) as u64) as i64))

            ((unsafe *__local_right).num = ((((0 - __local_num_right) + 1) as i32)))

            ((unsafe *__local_left).num = ((((0 - __local_num_left) - 1) as i32)))

            ((unsafe *__param_parent).key[__param_k] = (((unsafe *__local_left).key[__local_num_left] as i64)))

        } else {
            with_memmove(((((&raw const (unsafe *__local_left).key[__local_num_left] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).key[__param_k] as *const i64) as *mut i64) as *const c_void) as *const u8), ((sizeof[i64]() as u64) as i64))

            with_memmove(((((&raw const (unsafe *__param_parent).key[__param_k] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *const c_void) as *const u8), ((sizeof[i64]() as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[1] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% (((__local_num_right - 1) as u32) as u64)) as u64) as i64))

            ((unsafe *__local_left).kind.node[(__local_num_left + 1)] = (unsafe *(&raw const (*__local_right).kind as *const mlib_word_tree_kind_s)).node[0])

            with_memmove(((((&raw const (unsafe *__local_right).kind.node[0] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.node[1] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            ((unsafe *__local_right).num = (((__local_num_right - 1) as i32)))

            ((unsafe *__local_left).num = (((__local_num_left + 1) as i32)))

        }

        if ((if not ((unsafe *__local_right).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"right->num != 0".ptr)
        } else {
            0
        }

        if ((if not ((unsafe *__local_left).num != 0): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_right_shift".ptr, c"facade_shapes.c".ptr, (40 as i32), c"left->num != 0".ptr)
        } else {
            0
        }

    }

    pub mut fn mlib_word_tree_i_merge_node(__param_k: i32, __param_leaf: bool) {
        let __param_parent: *mut mlib_word_tree_node_s = self as *mut mlib_word_tree_node_s
        var __ci_expr_logic_0: i32 = 0

        if (__param_parent != null) {
            (__ci_expr_logic_0 = (if not unsafe { (*__param_parent).mlib_word_tree_is_leaf() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"parent != ((void*)0) && !mlib_word_tree_is_leaf(parent)".ptr)
        } else {
            0
        }


        var __ci_expr_logic_1: i32 = 0

        if (0 <= __param_k) {
            (__ci_expr_logic_1 = (if __param_k < unsafe { (*__param_parent).mlib_word_tree_get_num() }: 1 else: 0))
        }

        if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= k && k < mlib_word_tree_get_num(parent)".ptr)
        } else {
            0
        }


        var __local_left: *mut mlib_word_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_word_tree_kind_s)).node[__param_k]

        var __local_right: *mut mlib_word_tree_node_s = (unsafe *(&raw const (*__param_parent).kind as *const mlib_word_tree_kind_s)).node[(__param_k + 1)]

        var __ci_expr_logic_2: i32 = 0

        if (__local_left != null) {
            (__ci_expr_logic_2 = (if __local_right != null: 1 else: 0))
        }

        if ((if not __ci_expr_logic_2: 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"left != ((void*)0) && right != ((void*)0)".ptr)
        } else {
            0
        }


        var __local_num_parent: i32 = ((unsafe { (*__param_parent).mlib_word_tree_get_num() } as i32))

        var __local_num_left: i32 = ((unsafe { (*__local_left).mlib_word_tree_get_num() } as i32))

        var __local_num_right: i32 = ((unsafe { (*__local_right).mlib_word_tree_get_num() } as i32))

        if __param_leaf {
            if ((if not ((__local_num_left + __local_num_right) <= 16): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_left + num_right <= 16".ptr)
            } else {
                0
            }

            with_memmove(((((&raw const (unsafe *__local_left).key[__local_num_left] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_left).kind.value[__local_num_left] as *const *mut c_void) as *mut *mut c_void) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.value[0] as *const *mut c_void) as *mut *mut c_void) as *const c_void) as *const u8), ((((8 as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            ((unsafe *__local_left).num = ((((0 - __local_num_left) - __local_num_right) as i32)))

        } else {
            if ((if not ((__local_num_left + __local_num_right) <= (16 - 1)): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_i_merge_node".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_left + num_right <= 16 -1".ptr)
            } else {
                0
            }

            with_memmove(((((&raw const (unsafe *__local_left).key[(__local_num_left + 1)] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).key[0] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((__local_num_right as u32) as u64)) as u64) as i64))

            with_memmove(((((&raw const (unsafe *__local_left).kind.node[(__local_num_left + 1)] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__local_right).kind.node[0] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% (((__local_num_right + 1) as u32) as u64)) as u64) as i64))

            ((unsafe *__local_left).key[__local_num_left] = (((unsafe *__param_parent).key[__param_k] as i64)))

            ((unsafe *__local_left).num = ((((__local_num_left + 1) + __local_num_right) as i32)))

        }

        ((unsafe *__local_left).next = (unsafe *__local_right).next)

        if ((unsafe *__local_left).next != null) {
            ((unsafe *(*__local_left).next).prev = __local_left)

        }

        with_free(((__local_right as *mut c_void) as *mut u8))


        with_memmove(((((&raw const (unsafe *__param_parent).key[__param_k] as *const i64) as *mut i64) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).key[(__param_k + 1)] as *const i64) as *mut i64) as *const c_void) as *const u8), ((((sizeof[i64]() as u64) *% ((((__local_num_parent - __param_k) - 1) as u32) as u64)) as u64) as i64))

        with_memmove(((((&raw const (unsafe *__param_parent).kind.node[(__param_k + 1)] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *mut c_void) as *mut u8), ((((&raw const (unsafe *__param_parent).kind.node[(__param_k + 2)] as *const *mut mlib_word_tree_node_s) as *mut *mut mlib_word_tree_node_s) as *const c_void) as *const u8), ((((sizeof[usize]() as u64) *% ((((__local_num_parent - __param_k) - 1) as u32) as u64)) as u64) as i64))

        ((unsafe *__param_parent).num = (unsafe *__param_parent).num - 1)

    }

}

impl mlib_word_tree_s {
    pub mut fn mlib_word_tree_init() {
        let __param_b: *mut mlib_word_tree_s = self as *mut mlib_word_tree_s
        ((unsafe __param_b[0]).root = mlib_word_tree_new_node())

        ((unsafe __param_b[0]).size = ((0 as u64)))

        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_init".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

    }

    pub mut fn mlib_word_tree_reset() {
        let __param_b: *mut mlib_word_tree_s = self as *mut mlib_word_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        var __local_next: *mut mlib_word_tree_node_s

        var __local_n: *mut mlib_word_tree_node_s = (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root


        var __local_pit: [mlib_word_tree_parent_it_s; 1]

        var __local_np: i32 = ((0 as i32))

        while (not unsafe { (*__local_n).mlib_word_tree_is_leaf() }) {
            var __ci_expr_old_2: i32 = __local_np

            (__local_np = __local_np + 1)

            (__local_pit[0].parent[__ci_expr_old_2] = __local_n)


            if ((if not (__local_np <= ((((1 as u64) +% (((8 as u64) *% (sizeof[u64]() as u64)) as u64)) as i32))): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
            } else {
                0
            }

            (__local_n = (unsafe *(&raw const (*__local_n).kind as *const mlib_word_tree_kind_s)).node[0])

        }

        var __ci_expr_old_3: i32 = __local_np

        (__local_np = __local_np + 1)

        (__local_pit[0].parent[__ci_expr_old_3] = __local_n)


        if ((if not (__local_np <= ((((1 as u64) +% (((8 as u64) *% (sizeof[u64]() as u64)) as u64)) as i32))): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"np <= ((int)(1 + 8*sizeof (size_t)))".ptr)
        } else {
            0
        }

        var __local_i: i32 = ((0 as i32))

        while (__local_i < __local_np) {
            (__local_n = (unsafe *(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).parent[__local_i])

            while (__local_n != null) {
                var __local_num: i32 = ((unsafe { (*__local_n).mlib_word_tree_get_num() } as i32))

                var __local_is_leaf: bool = unsafe { (*__local_n).mlib_word_tree_is_leaf() }

                var __local_j: i32 = ((0 as i32))

                while (__local_j < __local_num) {

                    if __local_is_leaf {

                    }


                    (__local_j = __local_j + 1)

                }


                (__local_next = (unsafe *__local_n).next)

                if (__local_i != 0) {
                    with_free(((__local_n as *mut c_void) as *mut u8))

                }

                (__local_n = __local_next)

            }


            (__local_i = __local_i + 1)

        }


        ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num = ((0 as i32)))

        ((unsafe __param_b[0]).size = ((0 as u64)))

        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2_1: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2_1: bool = ((__local_num2_1 <= 0))

                (__local_num2_1 = (((if __local_num2_1 < 0: ((0 - __local_num2_1) as i32) else: __local_num2_1) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_4: i32 = 0

                    if (0 <= __local_num2_1) {
                        (__ci_expr_logic_4 = (if __local_num2_1 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_4: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2_1 == 0) {
                        if ((if not __local_is_leaf2_1: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2_1: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2_1 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_5: i32 = 0

                    if (__local_c2_1 <= __local_num2_1) {
                        (__ci_expr_logic_5 = (if __local_num2_1 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2_1: i32 = ((1 as i32))

                while (__local_i2_1 < __local_num2_1) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2_1 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2_1]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2_1 = __local_i2_1 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2_1 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2_1 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev_1: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev_1 = (((if __local_num_prev_1 < 0: ((0 - __local_num_prev_1) as i32) else: __local_num_prev_1) as i32)))

                    if ((if not (__local_num_prev_1 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev_1 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_reset".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

    }

    pub mut fn mlib_word_tree_clear() {
        let __param_b: *mut mlib_word_tree_s = self as *mut mlib_word_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_clear".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        unsafe { (*(&(__param_b[0]) as *mut mlib_word_tree_s)).mlib_word_tree_reset() }

        with_free((((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root as *mut c_void) as *mut u8))

        ((unsafe __param_b[0]).root = ((null as *mut mlib_word_tree_node_s)))

    }

    pub fn mlib_word_tree_empty_p() -> bool {
        let __param_b: *mut mlib_word_tree_s = (self as *const mlib_word_tree_s) as *mut mlib_word_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_empty_p".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        return (((((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size == 0)) as bool))

    }

    pub fn mlib_word_tree_size() -> u64 {
        let __param_b: *mut mlib_word_tree_s = (self as *const mlib_word_tree_s) as *mut mlib_word_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_size".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        return (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size

    }

    pub mut fn mlib_word_tree_safe_get(__param_key: i64) -> *mut *mut c_void {
        let __param_b: *mut mlib_word_tree_s = self as *mut mlib_word_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_safe_get".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        var __local_ret: *mut *mut c_void = unsafe { mlib_word_tree_get((&(__param_b[0]) as *mut mlib_word_tree_s), __param_key) }

        if (__local_ret == null) {
            var __local_v: *mut c_void

            (__local_v = null)

            var __local_m_var_40: bool = true

            while __local_m_var_40 {

                while __local_m_var_40 {

                    while __local_m_var_40 {
                        unsafe { mlib_word_tree_set_at((&(__param_b[0]) as *mut mlib_word_tree_s), __param_key, __local_v) }


                        (__local_m_var_40 = false)

                    }


                    (__local_m_var_40 = false)

                }


                (__local_m_var_40 = false)

            }


            (__local_ret = unsafe { mlib_word_tree_get((&(__param_b[0]) as *mut mlib_word_tree_s), __param_key) })

        }

        return __local_ret

    }

    pub mut fn mlib_word_tree_erase(__param_key: i64) -> bool {
        let __param_b: *mut mlib_word_tree_s = self as *mut mlib_word_tree_s
        loop {

            loop {
                if ((if not (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root+0) != ((void*)0)".ptr)
                } else {
                    0
                }

                if ((if not ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root != null): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"((b)->root) != ((void*)0)".ptr)
                } else {
                    0
                }

                var __local_num2: i32 = (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).num

                var __local_is_leaf2: bool = ((__local_num2 <= 0))

                (__local_num2 = (((if __local_num2 < 0: ((0 - __local_num2) as i32) else: __local_num2) as i32)))

                if (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize)) == (unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root) {
                    var __ci_expr_logic_0: i32 = 0

                    if (0 <= __local_num2) {
                        (__ci_expr_logic_0 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_0: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"0 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                    if (__local_num2 == 0) {
                        if ((if not __local_is_leaf2: 1 else: 0) as i64) {
                            __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"is_leaf2".ptr)
                        } else {
                            0
                        }
                    }

                } else {
                    var __local_c2: i32 = (((16 / 2) as i32))

                    if ((if not (__local_c2 > 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 > 0".ptr)
                    } else {
                        0
                    }

                    var __ci_expr_logic_1: i32 = 0

                    if (__local_c2 <= __local_num2) {
                        (__ci_expr_logic_1 = (if __local_num2 <= 16: 1 else: 0))
                    }

                    if ((if not __ci_expr_logic_1: 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"c2 <= num2 && num2 <= 16".ptr)
                    } else {
                        0
                    }


                }

                var __local_i2: i32 = ((1 as i32))

                while (__local_i2 < __local_num2) {
                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_i2 - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[__local_i2]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[i2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[i2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[i2-1]) < (((b)->root+0)->key[i2]) ? -1 : (((b)->root+0)->key[i2-1]) > (((b)->root+0)->key[i2])) < 0".ptr)
                    } else {
                        0
                    }


                    (__local_i2 = __local_i2 + 1)

                }


                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] < (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: (-1 as i32) else: ((if (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[(__local_num2 - 1)] > (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).next).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->key[num2-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->key[num2-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->key[num2-1]) < (((b)->root+0)->next->key[0]) ? -1 : (((b)->root+0)->key[num2-1]) > (((b)->root+0)->next->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if ((unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev != null) {
                    if ((if not (__local_num2 >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num2 >= 1".ptr)
                    } else {
                        0
                    }

                    var __local_num_prev: i32 = (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).num

                    (__local_num_prev = (((if __local_num_prev < 0: ((0 - __local_num_prev) as i32) else: __local_num_prev) as i32)))

                    if ((if not (__local_num_prev >= 1): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"num_prev >= 1".ptr)
                    } else {
                        0
                    }

                    if ((if not ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] < (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: (-1 as i32) else: ((if (unsafe *(*((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).prev).key[(__local_num_prev - 1)] > (unsafe *((*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root + ((0 as isize) as usize))).key[0]: 1 else: 0) as i32)) < 0): 1 else: 0) as i64) {
                        __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(((void) sizeof(struct { int M_LIB_NOT_A_BASIC_TYPE; _Static_assert(_Generic(((b)->root+0)->prev->key[num_prev-1], _Bool: 1, char: 1, unsigned char: 1, signed char: 1, unsigned short: 1, signed short: 1, unsigned int: 1, signed int: 1, unsigned long: 1, signed long: 1, unsigned long long: 1, signed long long:1, float: 1, double:1, long double: 1, char *:1, void*:1, default: 0), \"M_LIB_NOT_A_BASIC_TYPE\" \": \" \"The variable \" \"((b)->root+0)->prev->key[num_prev-1]\" \" is not a basic C type (int/float), \" \"but the given methods use it like this. \" \"It is likely the given oplist is not the right one.\");})), (((b)->root+0)->prev->key[num_prev-1]) < (((b)->root+0)->key[0]) ? -1 : (((b)->root+0)->prev->key[num_prev-1]) > (((b)->root+0)->key[0])) < 0".ptr)
                    } else {
                        0
                    }

                }

                if not (false) {
                    break
                }
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).next == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->next == ((void*)0)".ptr)
            } else {
                0
            }

            if ((if not ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).prev == null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"(b)->root->prev == ((void*)0)".ptr)
            } else {
                0
            }

            if ((unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num <= 0) {
                if ((if not ((0 - (unsafe *(*(&raw const (__param_b[0]) as *const mlib_word_tree_s)).root).num) == (((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size as i32))): 1 else: 0) as i64) {
                    __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"-(b)->root->num == (int) (b)->size".ptr)
                } else {
                    0
                }
            }

            if not (false) {
                break
            }
        }

        var __local_pit: [mlib_word_tree_parent_it_s; 1]

        var __local_leaf: *mut mlib_word_tree_node_s = unsafe { mlib_word_tree_i_search_for_leaf((&__local_pit[0] as *mut mlib_word_tree_parent_it_s), (&(__param_b[0]) as *mut mlib_word_tree_s), __param_key) }

        var __local_k: i32 = ((unsafe { (*__local_leaf).mlib_word_tree_i_search_and_remove_in_leaf(__param_key) } as i32))

        if (__local_k < 0) {
            return ((false as bool))
        }

        ((unsafe __param_b[0]).size = ((unsafe *(&raw const (__param_b[0]) as *const mlib_word_tree_s)).size -% 1))

        var __ci_expr_logic_2: i32

        if ((if not (not (unsafe { (*__local_leaf).mlib_word_tree_get_num() } >= (16 / 2))): 1 else: 0) as i64) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (unsafe *(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num == 0: 1 else: 0))
        }

        if __ci_expr_logic_2 {
            return ((true as bool))
        }


        if ((if not (unsafe { (*__local_leaf).mlib_word_tree_get_num() } == ((16 / 2) - 1)): 1 else: 0) as i64) {
            __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"mlib_word_tree_get_num(leaf) == 16/2-1".ptr)
        } else {
            0
        }

        var __local_pass1: bool = true

        while true {
            if ((if not ((unsafe *(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num > 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"pit->num > 0".ptr)
            } else {
                0
            }

            var __local_parent: *mut mlib_word_tree_node_s = with 0 as __ci_expr_seq_158 {
                (__local_pit[0].num = (unsafe *(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num - 1)
                (unsafe *(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).parent[(unsafe *(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num]
            }

            if ((if not (__local_parent != null): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"parent != ((void*)0)".ptr)
            } else {
                0
            }

            (__local_k = ((unsafe { mlib_word_tree_i_search_for_node(__local_parent, __local_leaf) } as i32)))

            if ((if not (__local_k >= 0): 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"k >= 0".ptr)
            } else {
                0
            }

            var __ci_expr_logic_3: i32 = 0

            if (__local_k > 0) {
                (__ci_expr_logic_3 = (if unsafe { (*((*(&raw const (*__local_parent).kind as *const mlib_word_tree_kind_s)).node[(__local_k - 1)] as *mut mlib_word_tree_node_s)).mlib_word_tree_get_num() } > (16 / 2): 1 else: 0))
            }

            if __ci_expr_logic_3 {
                unsafe { (*__local_parent).mlib_word_tree_i_left_shift(((__local_k - 1) as i32)) }

                return ((true as bool))

            }
            var __ci_expr_logic_4: i32 = 0

            if (__local_k < unsafe { (*__local_parent).mlib_word_tree_get_num() }) {
                (__ci_expr_logic_4 = (if unsafe { (*((*(&raw const (*__local_parent).kind as *const mlib_word_tree_kind_s)).node[(__local_k + 1)] as *mut mlib_word_tree_node_s)).mlib_word_tree_get_num() } > (16 / 2): 1 else: 0))
            }

            if __ci_expr_logic_4 {
                unsafe { (*__local_parent).mlib_word_tree_i_right_shift(__local_k) }

                return ((true as bool))

            }



            if (__local_k == unsafe { (*__local_parent).mlib_word_tree_get_num() }) {
                (__local_k = __local_k - 1)
            }

            var __ci_expr_logic_5: i32 = 0

            if (__local_k >= 0) {
                (__ci_expr_logic_5 = (if __local_k < unsafe { (*__local_parent).mlib_word_tree_get_num() }: 1 else: 0))
            }

            if ((if not __ci_expr_logic_5: 1 else: 0) as i64) {
                __assert_rtn(c"mlib_word_tree_erase".ptr, c"facade_shapes.c".ptr, (40 as i32), c"k >= 0 && k < mlib_word_tree_get_num(parent)".ptr)
            } else {
                0
            }


            unsafe { (*__local_parent).mlib_word_tree_i_merge_node(__local_k, __local_pass1) }

            if (unsafe { (*__local_parent).mlib_word_tree_get_num() } >= (16 / 2)) {
                return ((true as bool))
            }

            if ((unsafe *(&raw const __local_pit[0] as *const mlib_word_tree_parent_it_s)).num == 0) {
                if (unsafe { (*__local_parent).mlib_word_tree_get_num() } == 0) {
                    ((unsafe __param_b[0]).root = (unsafe *(&raw const (*__local_parent).kind as *const mlib_word_tree_kind_s)).node[0])

                    with_free(((__local_parent as *mut c_void) as *mut u8))

                }

                return ((true as bool))

            }

            (__local_leaf = __local_parent)

            (__local_pass1 = false)

        }

    }

}
