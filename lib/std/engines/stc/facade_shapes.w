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

// contract: unproved:0:casts away const
pub unsafe fn stc_slot_set_drop(__param_cself: *const stc_slot_set) {
    var __local_self_: *mut stc_slot_set = ((__param_cself as *mut stc_slot_set))

    if ((if (*__param_cself).meta == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_set_wipe_(__local_self_)

    with_free((((*__local_self_).meta as *mut c_void) as *mut u8))

    with_free((((*__local_self_).table as *mut c_void) as *mut u8))

}

// contract: receiver-mut:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_erase_entry(__param_self_: *mut stc_slot_set, __param__val: *mut *mut stc_slot_head) {
    var __local_d: *mut *mut stc_slot_head = (*__param_self_).table

    var __local_m: *mut hmap_meta = (*__param_self_).meta

    var __local_i: u64 = ((((((__param__val as usize) -% (__local_d as usize)) as i64) / (sizeof[usize]() as i64)) as u64))

    var __local_j: u64 = __local_i


    var __local_mask: u64 = (((((*__param_self_).bucket_count as u64) -% (1 as u64)) as u64))

    stc_slot_set_value_drop((__param_self_ as *const stc_slot_set), __param__val)

    while true {
        (__local_j = ((((((__local_j as u64) +% (1 as u64)) as u64) & (__local_mask as u64)) as u64)))

        if ((if ((__local_m[__local_j])).dist() < 2: 1 else: 0) != 0) {
            break
        }

        ((__local_d[__local_i]) = (__local_d[__local_j]))

        ((__local_m[__local_i]) = (__local_m[__local_j]))

        ((__local_m[__local_i])).set_dist((((__local_m[__local_i])).dist() -% 1))

        (__local_i = __local_j)

    }

    ((__local_m[__local_i])).set_dist(((0 as u16)))

    ((*__param_self_).size = (*__param_self_).size - 1)

}

// contract: receiver:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_bucket_lookup_(__param_self_: *const stc_slot_set, __param_rkeyptr: *const *mut stc_slot_head) -> stc_slot_set_result {
    var __local__hash: u64 = (((*(*__param_rkeyptr)).hash.unwrap()(((*__param_rkeyptr) as *const c_void)) as u64))

    var __local__idxmask: u64 = (((((*__param_self_).bucket_count as u64) -% (1 as u64)) as u64))

    var __local__res: stc_slot_set_result = stc_slot_set_result { idx: ((__local__hash as u64) & (__local__idxmask as u64)), hashx: (((((((__local__hash as u64) >> (24 as u32))) as u64) & (63 as u64))) as u8), dist: 1 }

    while ((if (*(&raw const __local__res as *const stc_slot_set_result)).dist <= (((*__param_self_).meta[(*(&raw const __local__res as *const stc_slot_set_result)).idx])).dist(): 1 else: 0) != 0) {
        if ((if (((*__param_self_).meta[(*(&raw const __local__res as *const stc_slot_set_result)).idx])).hashx() == (*(&raw const __local__res as *const stc_slot_set_result)).hashx: 1 else: 0) != 0) {
            var __local__raw: *mut stc_slot_head = (*((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const stc_slot_set_result)).idx]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

            if ((if (*(*(&raw const __local__raw as *const *mut stc_slot_head))).cmp.unwrap()(((*(&raw const __local__raw as *const *mut stc_slot_head)) as *const c_void), ((*__param_rkeyptr) as *const c_void)) == 0: 1 else: 0) != 0) {
                (__local__res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const stc_slot_set_result)).idx]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

                break

            }

        }

        (__local__res.idx = (((((((*(&raw const __local__res as *const stc_slot_set_result)).idx as u64) +% (1 as u64)) as u64) & (__local__idxmask as u64)) as u64)))

        (__local__res.dist = ((*(&raw const __local__res as *const stc_slot_set_result)).dist +% 1))

    }

    return __local__res

}

// contract: receiver-mut:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_bucket_insert_(__param_self_: *const stc_slot_set, __param_rkeyptr: *const *mut stc_slot_head) -> stc_slot_set_result {
    var __local_res: stc_slot_set_result = stc_slot_set_bucket_lookup_(__param_self_, __param_rkeyptr)

    if ((*(&raw const __local_res as *const stc_slot_set_result)).ref != null) {
        return __local_res
    }

    (__local_res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    (__local_res.inserted = true)

    var __local_mnew: hmap_meta = with 0 as __ci_bits_seq_59 { var __ci_bits: hmap_meta = hmap_meta.zeroed(); __ci_bits.set_hashx((((((((*(&raw const __local_res as *const stc_slot_set_result)).hashx as u32) as i32) as u32) & (63 as u32))) as u16)); __ci_bits.set_dist((((((((*(&raw const __local_res as *const stc_slot_set_result)).dist as u32) as i32) as u32) & (1023 as u32))) as u16)); __ci_bits }

    var __local_mcur: hmap_meta = ((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx])

    (((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) = __local_mnew)

    if ((if __local_mcur.dist() != 0: 1 else: 0) != 0) {
        var __local_mask: u64 = (((((*__param_self_).bucket_count as u64) -% (1 as u64)) as u64))

        var __local_dcur: *mut stc_slot_head = (*((*(&raw const __local_res as *const stc_slot_set_result)).ref))

        while true {
            (__local_res.idx = (((((((*(&raw const __local_res as *const stc_slot_set_result)).idx as u64) +% (1 as u64)) as u64) & (__local_mask as u64)) as u64)))

            __local_mcur.set_dist((__local_mcur.dist() +% 1))

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx])).dist() == 0: 1 else: 0) != 0) {
                break
            }

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx])).dist() < __local_mcur.dist(): 1 else: 0) != 0) {
                loop {
                    var __local__xp: *mut hmap_meta = ((&raw mut __local_mcur as *mut hmap_meta))

                    var __local__yp: *mut hmap_meta = (((&raw const ((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) as *const hmap_meta) as *mut hmap_meta))


                    var __local__tv: hmap_meta = (*__local__xp)

                    with_memcpy((&raw mut (*__local__xp) as *mut u8), (&raw const (*__local__yp) as *const u8), sizeof[hmap_meta]())

                    with_memcpy((&raw mut (*__local__yp) as *mut u8), (&raw const __local__tv as *const u8), sizeof[hmap_meta]())

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    var __local__xp_1: *mut *mut stc_slot_head = ((&raw mut __local_dcur as *mut *mut stc_slot_head))

                    var __local__yp_1: *mut *mut stc_slot_head = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))


                    var __local__tv_1: *mut stc_slot_head = (*__local__xp_1)

                    ((*__local__xp_1) = (*__local__yp_1))

                    ((*__local__yp_1) = __local__tv_1)

                    if not ((0 != 0)) {
                        break
                    }
                }

            }

        }

        (((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) = __local_mcur)

        (((*__param_self_).table[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) = __local_dcur)

    }

    return __local_res

}

// contract: receiver:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_contains(__param_self_: *const stc_slot_set, __param_rkey: *mut stc_slot_head) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref != null: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

// contract: receiver-mut:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_insert_entry_(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> stc_slot_set_result {
    if ((if (*__param_self_).size >= (((((*__param_self_).bucket_count as f32) * i_max_load_factor) as i64)): 1 else: 0) != 0) {
        if ((if not (*__param_self_).reserve((((((*__param_self_).size * 3) / 2) + 2) as i64)): 1 else: 0) != 0) {
            return ((stc_slot_set_result.zeroed() as stc_slot_set_result))
        }
    }

    var __local_res: stc_slot_set_result = stc_slot_set_bucket_insert_((__param_self_ as *const stc_slot_set), ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const stc_slot_set_result)).inserted as i32))

    return __local_res

}

// contract: unproved:0:returns a pointer loaded from the parameter
pub unsafe fn stc_slot_set_value_toraw(__param_val: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_val)

}

// contract: receiver:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_value_drop(__param_self_: *const stc_slot_set, __param__val: *mut *mut stc_slot_head) {
    return
}

// contract: receiver-mut:stc_slot_set,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_set_insert(__param_self_: *mut stc_slot_set, __param__key: *mut stc_slot_head) -> stc_slot_set_result {
    var __local__res: stc_slot_set_result = stc_slot_set_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut *mut stc_slot_head)))

    if (*(&raw const __local__res as *const stc_slot_set_result)).inserted {
        ((*((*(&raw const __local__res as *const stc_slot_set_result)).ref)) = __param__key)

    } else {

    }

    return __local__res

}

// contract: receiver-mut:stc_slot_set,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_set_push(__param_self_: *mut stc_slot_set, __param__val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local__res: stc_slot_set_result = stc_slot_set_insert_entry_(__param_self_, (*(&raw mut __param__val as *mut *mut stc_slot_head)))

    if ((if not (*(&raw const __local__res as *const stc_slot_set_result)).inserted: 1 else: 0) != 0) {
        stc_slot_set_value_drop((__param_self_ as *const stc_slot_set), (*(&raw const __local__res as *const stc_slot_set_result)).ref)
    }

    ((*((*(&raw const __local__res as *const stc_slot_set_result)).ref)) = __param__val)

    return (*(&raw const __local__res as *const stc_slot_set_result)).ref

}

// contract: receiver-mut:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_put_n(__param_self_: *mut stc_slot_set, __param_raw: *const *mut stc_slot_head, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_set_insert(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_slot_set_init() -> stc_slot_set {
    var __local_cx: stc_slot_set = stc_slot_set.zeroed()

    return __local_cx

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_set_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_set {
    var __local_cx: stc_slot_set = stc_slot_set.zeroed()

    stc_slot_set_put_n((&raw mut __local_cx as *mut stc_slot_set), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_set_with_capacity(__param_cap: i64) -> stc_slot_set {
    var __local_cx: stc_slot_set = stc_slot_set.zeroed()

    unsafe { (*(&raw mut __local_cx as *mut stc_slot_set)).reserve(__param_cap) }

    return __local_cx

}

pub fn stc_slot_set_advance(__param_it_: stc_slot_set_iter, __param_n: u64) -> stc_slot_set_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const stc_slot_set_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { (*(&raw mut __param_it_ as *mut stc_slot_set_iter)).next() }

    }

    return __param_it_

}

// contract: receiver:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_find(__param_self_: *const stc_slot_set, __param_rkey: *mut stc_slot_head) -> stc_slot_set_iter {
    var __local_ref: *mut *mut stc_slot_head

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return ((stc_slot_set_iter { ref: __local_ref, _end: ((&raw const ((*__param_self_).table[(*__param_self_).bucket_count]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head), _mref: ((&raw const ((*__param_self_).meta[((((__local_ref as usize) -% ((*__param_self_).table as usize)) as i64) / (sizeof[usize]() as i64))]) as *const hmap_meta) as *mut hmap_meta) } as stc_slot_set_iter))
    }


    return (*__param_self_).end()

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:1:read only
pub unsafe fn stc_slot_set_get(__param_self_: *const stc_slot_set, __param_rkey: *mut stc_slot_head) -> *const *mut stc_slot_head {
    return (((if (*__param_self_).size != 0: stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref else: (null as *mut *mut stc_slot_head)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:1:read only
pub unsafe fn stc_slot_set_get_mut(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    return ((stc_slot_set_get((__param_self_ as *const stc_slot_set), __param_rkey) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_erase(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> i32 {
    var __local_ref: *mut *mut stc_slot_head

    var __ci_expr_logic_0: i32 = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = stc_slot_set_bucket_lookup_((__param_self_ as *const stc_slot_set), ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        stc_slot_set_erase_entry(__param_self_, __local_ref)

        return 1

    }


    return 0

}

// contract: receiver:stc_slot_set,unproved:1:read only
pub unsafe fn stc_slot_set_eq(__param_self_: *const stc_slot_set, __param_other: *const stc_slot_set) -> bool {
    if ((if (*__param_self_).size() != (*__param_other).size(): 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_i: stc_slot_set_iter = (*__param_self_).begin()

    while ((*(&raw const __local_i as *const stc_slot_set_iter)).ref != null) {
        var __local__raw: *mut stc_slot_head = (*((*(&raw const __local_i as *const stc_slot_set_iter)).ref))

        if ((if not stc_slot_set_contains(__param_other, __local__raw): 1 else: 0) != 0) {
            return ((false as bool))
        }


        (*(&raw mut __local_i as *mut stc_slot_set_iter)).next()

    }


    return ((true as bool))

}

unsafe fn stc_slot_set_wipe_(__param_self_: *mut stc_slot_set) {
    var __local_d: *mut *mut stc_slot_head = (*__param_self_).table

    var __local_m: *const hmap_meta = (((*__param_self_).meta as *const hmap_meta))

    var __local_n: i64 = (*__param_self_).bucket_count

    var __local_i: i64 = ((0 as i64))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const hmap_meta = __local_m

        (__local_m = __local_m + 1)

        if ((*__ci_expr_old_0).dist() != 0) {
            stc_slot_set_value_drop((__param_self_ as *const stc_slot_set), ((&raw const (__local_d[__local_i]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))
        }


        (__local_i = __local_i + 1)

    }


}

// contract: unproved:0:casts away const
pub unsafe fn stc_slot_sset_drop(__param_cself: *const stc_slot_sset) {
    var __local_self_: *mut stc_slot_sset = ((__param_cself as *mut stc_slot_sset))

    if ((if (*__local_self_).nodes == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_sset_drop_r_(__local_self_, (*__local_self_).root)

    with_free((((*__local_self_).nodes as *mut c_void) as *mut u8))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:1:read only,unproved:2:out-parameter read before the write
pub unsafe fn stc_slot_sset_find_it(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head, __param_out: *mut stc_slot_sset_iter) -> *mut *mut stc_slot_head {
    var __local_tn: i32 = (*__param_self_).root

    var __local_d: *mut stc_slot_sset_node = with 0 as __ci_expr_seq_6 {
        ((*__param_out)._d = (*__param_self_).nodes)
        (*__param_out)._d
    }

    ((*__param_out)._top = ((0 as i32)))

    while (__local_tn != 0) {
        var __local_c: i32

        var __local__raw: *mut stc_slot_head = (*((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

        (__local_c = (((*(*(&raw const __local__raw as *const *mut stc_slot_head))).cmp.unwrap()(((*(&raw const __local__raw as *const *mut stc_slot_head)) as *const c_void), ((*(&raw mut __param_rkey as *mut *mut stc_slot_head)) as *const c_void)) as i32)))

        if ((if __local_c < 0: 1 else: 0) != 0) {
            (__local_tn = (((__local_d[__local_tn]).link[1] as i32)))
        } else {
            if ((if __local_c > 0: 1 else: 0) != 0) {
                var __ci_expr_old_0: i32 = (*__param_out)._top

                ((*__param_out)._top = (*__param_out)._top + 1)

                ((*__param_out)._st[__ci_expr_old_0] = __local_tn)


                (__local_tn = (((__local_d[__local_tn]).link[0] as i32)))

            } else {
                ((*__param_out)._tn = (((__local_d[__local_tn]).link[1] as i32)))

                ((*__param_out).ref = (((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

                return (*__param_out).ref


            }
        }


    }

    ((*__param_out).ref = ((null as *mut *mut stc_slot_head)))

    return (*__param_out).ref


}

// contract: receiver:stc_slot_sset,unproved:1:read only
pub unsafe fn stc_slot_sset_lower_bound(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> stc_slot_sset_iter {
    var __local_it_: stc_slot_sset_iter

    stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter))

    var __ci_expr_logic_0: i32 = 0

    if ((if (*(&raw const __local_it_ as *const stc_slot_sset_iter)).ref == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const __local_it_ as *const stc_slot_sset_iter))._top != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tn: i32 = with 0 as __ci_expr_seq_11 {
            (__local_it_._top = (*(&raw const __local_it_ as *const stc_slot_sset_iter))._top - 1)
            ((*(&raw const __local_it_ as *const stc_slot_sset_iter))._st[(*(&raw const __local_it_ as *const stc_slot_sset_iter))._top] as i32)
        }

        (__local_it_._tn = ((((*(&raw const __local_it_ as *const stc_slot_sset_iter))._d[__local_tn]).link[1] as i32)))

        (__local_it_.ref = (((&raw const (__local_it_._d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    }


    return __local_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_sset_front(__param_self_: *const stc_slot_sset) -> *mut *mut stc_slot_head {
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while ((__local_d[__local_tn]).link[0] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[0] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_sset_back(__param_self_: *const stc_slot_sset) -> *mut *mut stc_slot_head {
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while ((__local_d[__local_tn]).link[1] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[1] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_sset,unproved:1:read only
pub unsafe fn stc_slot_sset_erase(__param_self_: *mut stc_slot_sset, __param_rkey: *mut stc_slot_head) -> i32 {
    var __local_erased: i32 = ((0 as i32))

    var __local_root: i32 = ((stc_slot_sset_erase_r_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head), (&raw mut __local_erased as *mut i32)) as i32))

    if ((if __local_erased == 0: 1 else: 0) != 0) {
        return 0
    }

    ((*__param_self_).root = __local_root)

    ((*__param_self_).size = (*__param_self_).size - 1)

    return 1

}

// contract: receiver:stc_slot_sset,unproved:1:read only
pub unsafe fn stc_slot_sset_find(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> stc_slot_sset_iter {
    var __local_it_: stc_slot_sset_iter

    stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter))

    return __local_it_

}

// contract: receiver:stc_slot_sset,unproved:1:read only
pub unsafe fn stc_slot_sset_contains(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> bool {
    var __local_it_: stc_slot_sset_iter

    return ((((stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter)) != null)) as bool))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:1:read only
pub unsafe fn stc_slot_sset_get(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> *const *mut stc_slot_head {
    var __local_it_: stc_slot_sset_iter

    return ((stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry,unproved:1:read only
pub unsafe fn stc_slot_sset_get_mut(__param_self_: *mut stc_slot_sset, __param_rkey: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_it_: stc_slot_sset_iter

    return ((stc_slot_sset_find_it((__param_self_ as *const stc_slot_sset), __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter)) as *mut *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer loaded from the parameter
pub unsafe fn stc_slot_sset_value_toraw(__param_val: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_val)

}

// contract: receiver:stc_slot_sset,unproved:1:read only
pub unsafe fn stc_slot_sset_value_drop(__param_self_: *const stc_slot_sset, __param_val: *mut *mut stc_slot_head) {
    return
}

// contract: receiver-mut:stc_slot_sset,unproved:1:read only
pub unsafe fn stc_slot_sset_insert_entry_(__param_self_: *mut stc_slot_sset, __param_rkey: *mut stc_slot_head) -> stc_slot_sset_result {
    var __local_res: stc_slot_sset_result = stc_slot_sset_result.zeroed()

    var __local_tn: i32 = ((stc_slot_sset_insert_entry_i_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head), (&raw mut __local_res as *mut stc_slot_sset_result)) as i32))

    ((*__param_self_).root = __local_tn)

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const stc_slot_sset_result)).inserted as i32))

    return __local_res

}

pub fn stc_slot_sset_advance(__param_it_: stc_slot_sset_iter, __param_n: u64) -> stc_slot_sset_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const stc_slot_sset_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { (*(&raw mut __param_it_ as *mut stc_slot_sset_iter)).next() }

    }

    return __param_it_

}

// contract: receiver-mut:stc_slot_sset,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_sset_insert(__param_self_: *mut stc_slot_sset, __param__key: *mut stc_slot_head) -> stc_slot_sset_result {
    var __local__res: stc_slot_sset_result = stc_slot_sset_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut *mut stc_slot_head)))

    if (*(&raw const __local__res as *const stc_slot_sset_result)).inserted {
        ((*((*(&raw const __local__res as *const stc_slot_sset_result)).ref)) = __param__key)

    } else {

    }

    return __local__res

}

// contract: receiver-mut:stc_slot_sset,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_sset_push(__param_self_: *mut stc_slot_sset, __param__val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local__res: stc_slot_sset_result = stc_slot_sset_insert_entry_(__param_self_, (*(&raw mut __param__val as *mut *mut stc_slot_head)))

    if ((if not (*(&raw const __local__res as *const stc_slot_sset_result)).inserted: 1 else: 0) != 0) {
        stc_slot_sset_value_drop((__param_self_ as *const stc_slot_sset), (*(&raw const __local__res as *const stc_slot_sset_result)).ref)
    }

    ((*((*(&raw const __local__res as *const stc_slot_sset_result)).ref)) = __param__val)

    return (*(&raw const __local__res as *const stc_slot_sset_result)).ref

}

// contract: receiver-mut:stc_slot_sset,unproved:1:read only
pub unsafe fn stc_slot_sset_put_n(__param_self_: *mut stc_slot_sset, __param_raw: *const *mut stc_slot_head, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_sset_insert(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_slot_sset_init() -> stc_slot_sset {
    var __local_cx: stc_slot_sset = stc_slot_sset.zeroed()

    return __local_cx

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_sset_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_sset {
    var __local_cx: stc_slot_sset = stc_slot_sset.zeroed()

    stc_slot_sset_put_n((&raw mut __local_cx as *mut stc_slot_sset), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_sset_with_capacity(__param_cap: i64) -> stc_slot_sset {
    var __local_cx: stc_slot_sset = stc_slot_sset.zeroed()

    unsafe { (*(&raw mut __local_cx as *mut stc_slot_sset)).reserve(__param_cap) }

    return __local_cx

}

unsafe fn stc_slot_sset_new_node_(__param_self_: *mut stc_slot_sset, __param_level: i32) -> i32 {
    var __local_tn: i32

    if ((if (*__param_self_).disp != 0: 1 else: 0) != 0) {
        (__local_tn = (*__param_self_).disp)

        ((*__param_self_).disp = ((((*__param_self_).nodes[__local_tn]).link[1] as i32)))

    } else {
        if ((if (*__param_self_).head == (*__param_self_).capacity: 1 else: 0) != 0) {
            if ((if not (*__param_self_).reserve((((((*__param_self_).head * 3) / 2) + 4) as i64)): 1 else: 0) != 0) {
                return 0
            }
        }

        ((*__param_self_).head = (*__param_self_).head + 1)

        (__local_tn = (*__param_self_).head)


    }

    var __local_dn: *mut stc_slot_sset_node = (((&raw const ((*__param_self_).nodes[__local_tn]) as *const stc_slot_sset_node) as *mut stc_slot_sset_node))

    ((*__local_dn).link[1] = ((0 as i32)))

    ((*__local_dn).link[0] = (((*__local_dn).link[1] as i32)))


    ((*__local_dn).level = ((__param_level as i8)))

    return __local_tn

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slot_sset_skew_(__param_d: *mut stc_slot_sset_node, __param_tn: i32) -> i32 {
    var __local_tn = __param_tn
    var __ci_expr_logic_0: i32 = 0

    if ((if __local_tn != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (__param_d[(__param_d[__local_tn]).link[0]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tmp: i32 = (((__param_d[__local_tn]).link[0] as i32))

        ((__param_d[__local_tn]).link[0] = (((__param_d[__local_tmp]).link[1] as i32)))

        ((__param_d[__local_tmp]).link[1] = __local_tn)

        (__local_tn = __local_tmp)

    }


    return __local_tn

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slot_sset_split_(__param_d: *mut stc_slot_sset_node, __param_tn: i32) -> i32 {
    var __local_tn = __param_tn
    if ((if (__param_d[(__param_d[(__param_d[__local_tn]).link[1]]).link[1]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0) {
        var __local_tmp: i32 = (((__param_d[__local_tn]).link[1] as i32))

        ((__param_d[__local_tn]).link[1] = (((__param_d[__local_tmp]).link[0] as i32)))

        ((__param_d[__local_tmp]).link[0] = __local_tn)

        (__local_tn = __local_tmp)

        ((__param_d[__local_tn]).level = (__param_d[__local_tn]).level + 1)

    }

    return __local_tn

}

// contract: receiver-mut:stc_slot_sset,unproved:2:read only,unproved:3:out-parameter written conditionally
pub unsafe fn stc_slot_sset_insert_entry_i_(__param_self_: *mut stc_slot_sset, __param_tn: i32, __param_rkey: *const *mut stc_slot_head, __param__res: *mut stc_slot_sset_result) -> i32 {
    var __local_up: List[i32] = [0; 64]

    var __local_tx: i32 = __param_tn


    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_c: i32

    var __local_top: i32 = ((0 as i32))

    var __local_dir: i32 = ((0 as i32))


    while (__local_tx != 0) {
        var __ci_expr_old_0: i32 = __local_top

        (__local_top = __local_top + 1)

        (__local_up[__ci_expr_old_0] = __local_tx)


        var __local__raw: *mut stc_slot_head = (*((&raw const (__local_d[__local_tx]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

        (__local_c = (((*(*(&raw const __local__raw as *const *mut stc_slot_head))).cmp.unwrap()(((*(&raw const __local__raw as *const *mut stc_slot_head)) as *const c_void), ((*__param_rkey) as *const c_void)) as i32)))

        if ((if __local_c == 0: 1 else: 0) != 0) {
            ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

            return __param_tn

        }


        (__local_dir = (((if __local_c < 0: 1 else: 0) as i32)))

        (__local_tx = (((__local_d[__local_tx]).link[__local_dir] as i32)))

    }

    (__local_tx = ((stc_slot_sset_new_node_(__param_self_, (1 as i32)) as i32)))

    if ((if __local_tx == 0: 1 else: 0) != 0) {
        return 0
    }


    (__local_d = (*__param_self_).nodes)

    ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    ((*__param__res).inserted = true)

    if ((if __local_top == 0: 1 else: 0) != 0) {
        return __local_tx
    }

    ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = __local_tx)

    while true {
        var __ci_expr_old_1: i32 = __local_top

        (__local_top = __local_top - 1)

        if (not (__ci_expr_old_1 != 0)) {
            break
        }

        if ((if __local_top != 0: 1 else: 0) != 0) {
            (__local_dir = (((if (__local_d[__local_up[(__local_top - 1)]]).link[1] == __local_up[__local_top]: 1 else: 0) as i32)))
        }

        (__local_up[__local_top] = ((stc_slot_sset_skew_(__local_d, (__local_up[__local_top] as i32)) as i32)))

        (__local_up[__local_top] = ((stc_slot_sset_split_(__local_d, (__local_up[__local_top] as i32)) as i32)))

        if (__local_top != 0) {
            ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = ((__local_up[__local_top] as i32)))
        }

    }

    return __local_up[0]

}

// contract: receiver-mut:stc_slot_sset,unproved:2:read only,unproved:3:out-parameter a return before the write
pub unsafe fn stc_slot_sset_erase_r_(__param_self_: *mut stc_slot_sset, __param_tn: i32, __param_rkey: *const *mut stc_slot_head, __param_erased: *mut i32) -> i32 {
    var __local_tn = __param_tn
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    if ((if __local_tn == 0: 1 else: 0) != 0) {
        return 0
    }

    var __local_raw: *mut stc_slot_head = (*((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

    var __local_tx: i32

    var __local_c: i32 = (((*(*(&raw mut __local_raw as *mut *mut stc_slot_head))).cmp.unwrap()(((*(&raw mut __local_raw as *mut *mut stc_slot_head)) as *const c_void), ((*__param_rkey) as *const c_void)) as i32))

    if ((if __local_c != 0: 1 else: 0) != 0) {
        ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] = ((stc_slot_sset_erase_r_(__param_self_, ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] as i32), __param_rkey, __param_erased) as i32)))
    } else {
        var __ci_expr_old_0: i32 = (*__param_erased)

        ((*__param_erased) = (*__param_erased) + 1)

        if ((if __ci_expr_old_0 == 0: 1 else: 0) != 0) {
            stc_slot_sset_value_drop((__param_self_ as *const stc_slot_sset), ((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))
        }


        var __ci_expr_logic_1: i32 = 0

        if ((__local_d[__local_tn]).link[0] != 0) {
            (__ci_expr_logic_1 = (if (__local_d[__local_tn]).link[1] != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_tx = (((__local_d[__local_tn]).link[0] as i32)))

            while ((__local_d[__local_tx]).link[1] != 0) {
                (__local_tx = (((__local_d[__local_tx]).link[1] as i32)))
            }

            ((__local_d[__local_tn]).value = (__local_d[__local_tx]).value)

            (__local_raw = (*((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

            ((__local_d[__local_tn]).link[0] = ((stc_slot_sset_erase_r_(__param_self_, ((__local_d[__local_tn]).link[0] as i32), ((&raw mut __local_raw as *mut *mut stc_slot_head) as *const *mut stc_slot_head), __param_erased) as i32)))

        } else {
            (__local_tx = __local_tn)

            (__local_tn = (((__local_d[__local_tn]).link[(if (__local_d[__local_tn]).link[0] == 0: 1 else: 0)] as i32)))

            ((__local_d[__local_tx]).link[1] = (*__param_self_).disp)

            ((*__param_self_).disp = __local_tx)

        }


    }

    (__local_tx = (((__local_d[__local_tn]).link[1] as i32)))

    var __ci_expr_logic_2: i32

    if ((if (__local_d[(__local_d[__local_tn]).link[0]]).level < (((__local_d[__local_tn]).level as i32) - 1): 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (__local_d[__local_tx]).level < (((__local_d[__local_tn]).level as i32) - 1): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        ((__local_d[__local_tn]).level = (__local_d[__local_tn]).level - 1)

        if ((if (__local_d[__local_tx]).level > (__local_d[__local_tn]).level: 1 else: 0) != 0) {
            ((__local_d[__local_tx]).level = (__local_d[__local_tn]).level)
        }


        (__local_tn = ((stc_slot_sset_skew_(__local_d, __local_tn) as i32)))

        ((__local_d[__local_tn]).link[1] = ((stc_slot_sset_skew_(__local_d, ((__local_d[__local_tn]).link[1] as i32)) as i32)))

        (__local_tx = (((__local_d[__local_tn]).link[1] as i32)))


        ((__local_d[__local_tx]).link[1] = ((stc_slot_sset_skew_(__local_d, ((__local_d[__local_tx]).link[1] as i32)) as i32)))

        (__local_tn = ((stc_slot_sset_split_(__local_d, __local_tn) as i32)))

        ((__local_d[__local_tn]).link[1] = ((stc_slot_sset_split_(__local_d, ((__local_d[__local_tn]).link[1] as i32)) as i32)))

    }


    return __local_tn

}

unsafe fn stc_slot_sset_drop_r_(__param_s: *mut stc_slot_sset, __param_tn: i32) -> Unit {
    if ((if __param_tn != 0: 1 else: 0) != 0) {
        stc_slot_sset_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[0] as i32))

        stc_slot_sset_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[1] as i32))

        stc_slot_sset_value_drop((__param_s as *const stc_slot_sset), ((&raw const ((*__param_s).nodes[__param_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

    }

}

// contract: receiver-mut:stc_slot_pqueue,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_pqueue_push(__param_self_: *mut stc_slot_pqueue, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    if ((if (*__param_self_).size == (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not (*__param_self_).reserve((((((*__param_self_).size * 3) / 2) + 4) as i64)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }
    }

    var __local_arr: *mut *mut stc_slot_head = ((*__param_self_).data - ((1 as i64) as usize))

    var __local_c: i64 = with 0 as __ci_expr_seq_9 {
        ((*__param_self_).size = (*__param_self_).size + 1)
        (*__param_self_).size
    }

    while true {
        var __ci_expr_logic_0: i32 = 0

        if ((if __local_c > 1: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (*(*((&raw const (__local_arr[(__local_c / 2)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))).cmp.unwrap()(((*((&raw const (__local_arr[(__local_c / 2)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*(&raw mut __param_value as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        ((__local_arr[__local_c]) = (__local_arr[(__local_c / 2)]))

        (__local_c = __local_c / 2)

    }

    ((__local_arr[__local_c]) = __param_value)

    return (__local_arr + ((__local_c as i64) as usize))

}

// contract: receiver-mut:stc_slot_pqueue,unproved:1:read only
pub unsafe fn stc_slot_pqueue_put_n(__param_self_: *mut stc_slot_pqueue, __param_raw: *const *mut stc_slot_head, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_pqueue_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_slot_pqueue_init() -> stc_slot_pqueue {
    return ((stc_slot_pqueue.zeroed() as stc_slot_pqueue))

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_pqueue_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_pqueue {
    var __local_cx: stc_slot_pqueue = stc_slot_pqueue.zeroed()

    stc_slot_pqueue_put_n((&raw mut __local_cx as *mut stc_slot_pqueue), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_pqueue_with_capacity(__param_cap: i64) -> stc_slot_pqueue {
    var __local_cx: stc_slot_pqueue = stc_slot_pqueue.zeroed()

    unsafe { (*(&raw mut __local_cx as *mut stc_slot_pqueue)).reserve(__param_cap) }

    return __local_cx

}

// contract: unproved:0:casts away const
pub unsafe fn stc_slot_pqueue_drop(__param_cself: *const stc_slot_pqueue) {
    var __local_self_: *mut stc_slot_pqueue = ((__param_cself as *mut stc_slot_pqueue))

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    (*__local_self_).clear()

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_pqueue_top(__param_self_: *const stc_slot_pqueue) -> *const *mut stc_slot_head {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_pqueue_top".ptr, c"pqueue.h".ptr, (117 as i32), c"self->size".ptr)
    } else {
        0
    }

    return ((((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

}

// contract: unproved:0:stc_slot_pqueue_sift_down_ may write through it,ret-from:1
pub unsafe fn stc_slot_pqueue_pushpull(__param_self_: *mut stc_slot_pqueue, __param_val: *mut stc_slot_head) -> *mut stc_slot_head {
    var __ci_expr_logic_0: i32 = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if (if (*(*(&raw mut __param_val as *mut *mut stc_slot_head))).cmp.unwrap()(((*(&raw mut __param_val as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        loop {
            var __local__xp: *mut *mut stc_slot_head = ((&raw mut __param_val as *mut *mut stc_slot_head))

            var __local__yp: *mut *mut stc_slot_head = (((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))


            var __local__tv: *mut stc_slot_head = (*__local__xp)

            ((*__local__xp) = (*__local__yp))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

        (*__param_self_).sift_down_((1 as i64), (*__param_self_).size)

    }


    return __param_val

}

// contract: unproved:0:stc_slot_pqueue_sift_down_ may write through it,ret-from:1
pub unsafe fn stc_slot_pqueue_exchange(__param_self_: *mut stc_slot_pqueue, __param_val: *mut stc_slot_head) -> *mut stc_slot_head {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_pqueue_exchange".ptr, c"pqueue.h".ptr, (138 as i32), c"self->size".ptr)
    } else {
        0
    }

    loop {
        var __local__xp: *mut *mut stc_slot_head = ((&raw mut __param_val as *mut *mut stc_slot_head))

        var __local__yp: *mut *mut stc_slot_head = (((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))


        var __local__tv: *mut stc_slot_head = (*__local__xp)

        ((*__local__xp) = (*__local__yp))

        ((*__local__yp) = __local__tv)

        if not ((0 != 0)) {
            break
        }
    }

    (*__param_self_).sift_down_((1 as i64), (*__param_self_).size)

    return __param_val

}

// contract: unproved:0:casts away const
pub unsafe fn stc_slot_deque_drop(__param_cself: *const stc_slot_deque) {
    var __local_self_: *mut stc_slot_deque = ((__param_cself as *mut stc_slot_deque))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    (*__local_self_).clear()

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))

}

// contract: receiver-mut:stc_slot_deque,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_deque_push(__param_self_: *mut stc_slot_deque, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_end: i64 = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_end == (*__param_self_).start: 1 else: 0) != 0) {
        if ((if not (*__param_self_).reserve((((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }

        (__local_end = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut *mut stc_slot_head = ((*__param_self_).cbuf + (((*__param_self_).end as i64) as usize))

    ((*__param_self_).end = __local_end)

    ((*__local_v) = __param_value)

    return __local_v

}

pub fn stc_slot_deque_advance(__param_it_: stc_slot_deque_iter, __param_n: i64) -> stc_slot_deque_iter {
    var __local_len: i64 = ((unsafe { (*((*(&raw const __param_it_ as *const stc_slot_deque_iter))._s)).size() } as i64))

    var __local_pos: i64 = (unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos

    var __local_idx: i64 = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).start) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).capmask as i64)) as i64))


    (__param_it_.pos = (((((__local_pos + __param_n) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).capmask as i64)) as i64)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - __local_pos) as i64) as usize))

    if ((if not ((if (((__local_idx + __param_n) as u64)) < ((__local_len as u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it_

}

// contract: receiver-mut:stc_slot_deque,unproved:1:read only
pub unsafe fn stc_slot_deque_put_n(__param_self_: *mut stc_slot_deque, __param_raw: *const *mut stc_slot_head, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_deque_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

// contract: receiver:stc_slot_deque,unproved:1:read only
pub unsafe fn stc_slot_deque_value_drop(__param_self_: *const stc_slot_deque, __param_val: *mut *mut stc_slot_head) {
    return
}

pub fn stc_slot_deque_init() -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque.zeroed()

    return __local_out

}

pub fn stc_slot_deque_with_capacity(__param_cap: i64) -> stc_slot_deque {
    var __local_cap = __param_cap
    (__local_cap = ((c_next_pow2(((__local_cap + 1) as i64)) as i64)))

    var __local_out: stc_slot_deque = stc_slot_deque { cbuf: (((with_alloc((((if 1 != 0: ((__local_cap * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)), start: 0, end: 0, capmask: (__local_cap - 1) }

    return __local_out

}

pub fn stc_slot_deque_with_size_uninit(__param_size: i64) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_size)

    (__local_out.end = __param_size)

    return __local_out

}

// contract: stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_deque_with_size(__param_size: i64, __param_default_raw: *mut stc_slot_head) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_size)

    while ((if (*(&raw const __local_out as *const stc_slot_deque)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (*(&raw const __local_out as *const stc_slot_deque)).end

        (__local_out.end = (*(&raw const __local_out as *const stc_slot_deque)).end + 1)

        ((__local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_deque_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_n)

    stc_slot_deque_put_n((&raw mut __local_out as *mut stc_slot_deque), __param_raw, __param_n)

    return __local_out

}

// contract: unproved:0:returns a pointer loaded from the parameter
pub unsafe fn stc_slot_deque_value_toraw(__param_pval: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_pval)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_deque_front(__param_self_: *const stc_slot_deque) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_deque_front_mut(__param_self_: *mut stc_slot_deque) -> *mut *mut stc_slot_head {
    return ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_deque_back(__param_self_: *const stc_slot_deque) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_deque_back_mut(__param_self_: *mut stc_slot_deque) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_back((__param_self_ as *const stc_slot_deque)) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_deque,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_deque_push_front(__param_self_: *mut stc_slot_deque, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_start: i64 = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_start == (*__param_self_).end: 1 else: 0) != 0) {
        if ((if not (*__param_self_).reserve((((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }

        (__local_start = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut *mut stc_slot_head = ((*__param_self_).cbuf + ((__local_start as i64) as usize))

    ((*__param_self_).start = __local_start)

    ((*__local_v) = __param_value)

    return __local_v

}

// contract: receiver-mut:stc_slot_deque,unproved:2:read only
pub unsafe fn stc_slot_deque_insert_n(__param_self_: *mut stc_slot_deque, __param_idx: i64, __param_arr: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_deque_iter {
    var __local_it_: stc_slot_deque_iter = (*__param_self_).insert_uninit(__param_idx, __param_n)

    var __local_i: i64 = __param_idx

    var __local_j: i64 = ((0 as i64))


    while ((if __local_j < __param_n: 1 else: 0) != 0) {
        ((*(stc_slot_deque_at_mut(__param_self_, __local_i))) = (__param_arr[__local_j]))

        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


    return __local_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_deque_at(__param_self_: *const stc_slot_deque, __param_idx: i64) -> *const *mut stc_slot_head {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size() as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_deque_at".ptr, c"deque.h".ptr, (53 as i32), c"((size_t)(idx) < (size_t)(stc_slot_deque_size(self)))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).cbuf + ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_deque_at_mut(__param_self_: *mut stc_slot_deque, __param_idx: i64) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __param_idx) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_deque,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_deque_push_back(__param_self_: *mut stc_slot_deque, __param_val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_push(__param_self_, __param_val) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_deque,unproved:2:read only
pub unsafe fn stc_slot_deque_insert_at(__param_self_: *mut stc_slot_deque, __param_it_: stc_slot_deque_iter, __param_val: *mut stc_slot_head) -> stc_slot_deque_iter {
    var __local_idx: i64 = ((((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64))

    return stc_slot_deque_insert_n(__param_self_, __local_idx, (&raw const __param_val as *const *mut stc_slot_head), (1 as i64))

}

// contract: unproved:0:casts away const
pub unsafe fn stc_word_deque_drop(__param_cself: *const stc_word_deque) {
    var __local_self_: *mut stc_word_deque = ((__param_cself as *mut stc_word_deque))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    (*__local_self_).clear()

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))

}

pub fn stc_word_deque_advance(__param_it_: stc_word_deque_iter, __param_n: i64) -> stc_word_deque_iter {
    var __local_len: i64 = ((unsafe { (*((*(&raw const __param_it_ as *const stc_word_deque_iter))._s)).size() } as i64))

    var __local_pos: i64 = (unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos

    var __local_idx: i64 = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).start) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).capmask as i64)) as i64))


    (__param_it_.pos = (((((__local_pos + __param_n) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).capmask as i64)) as i64)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos - __local_pos) as i64) as usize))

    if ((if not ((if (((__local_idx + __param_n) as u64)) < ((__local_len as u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut u64)))
    }

    return __param_it_

}

// contract: receiver-mut:stc_word_deque,unproved:1:read only
pub unsafe fn stc_word_deque_put_n(__param_self_: *mut stc_word_deque, __param_raw: *const u64, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (*__param_self_).push((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

// contract: receiver:stc_word_deque,unproved:1:read only
pub unsafe fn stc_word_deque_value_drop(__param_self_: *const stc_word_deque, __param_val: *mut u64) {
    return
}

pub fn stc_word_deque_init() -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque.zeroed()

    return __local_out

}

pub fn stc_word_deque_with_capacity(__param_cap: i64) -> stc_word_deque {
    var __local_cap = __param_cap
    (__local_cap = ((c_next_pow2(((__local_cap + 1) as i64)) as i64)))

    var __local_out: stc_word_deque = stc_word_deque { cbuf: (((with_alloc((((if 1 != 0: ((__local_cap * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)), start: 0, end: 0, capmask: (__local_cap - 1) }

    return __local_out

}

pub fn stc_word_deque_with_size_uninit(__param_size: i64) -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque_with_capacity(__param_size)

    (__local_out.end = __param_size)

    return __local_out

}

pub fn stc_word_deque_with_size(__param_size: i64, __param_default_raw: u64) -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque_with_capacity(__param_size)

    while ((if (unsafe *(&raw const __local_out as *const stc_word_deque)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (unsafe *(&raw const __local_out as *const stc_word_deque)).end

        (__local_out.end = (unsafe *(&raw const __local_out as *const stc_word_deque)).end + 1)

        ((unsafe __local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn stc_word_deque_from_n(__param_raw: *const u64, __param_n: i64) -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque_with_capacity(__param_n)

    stc_word_deque_put_n((&raw mut __local_out as *mut stc_word_deque), __param_raw, __param_n)

    return __local_out

}

pub fn stc_word_deque_clone(__param_q: stc_word_deque) -> stc_word_deque {
    var __local_out: stc_word_deque = __param_q

    var __local_self_: *mut stc_word_deque = ((&raw mut __local_out as *mut stc_word_deque))



    (__local_out.start = ((0 as i64)))

    (__local_out.end = ((unsafe { (*((&raw mut __param_q as *mut stc_word_deque) as *const stc_word_deque)).size() } as i64)))

    (__local_out.capmask = (((c_next_pow2((((unsafe *(&raw const __local_out as *const stc_word_deque)).end + 1) as i64)) - 1) as i64)))

    (__local_out.cbuf = (((with_alloc((((if 1 != 0: ((((unsafe *(&raw const __local_out as *const stc_word_deque)).capmask + 1) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

    var __local_i: i64 = ((0 as i64))

    if ((unsafe *(&raw const __local_out as *const stc_word_deque)).cbuf != null) {
        var __local_it_: stc_word_deque_iter = unsafe { (*((&raw mut __param_q as *mut stc_word_deque) as *const stc_word_deque)).begin() }

        while ((unsafe *(&raw const __local_it_ as *const stc_word_deque_iter)).ref != null) {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i + 1)

            ((unsafe __local_out.cbuf[__ci_expr_old_0]) = (unsafe *((*(&raw const __local_it_ as *const stc_word_deque_iter)).ref)))


            unsafe { (*(&raw mut __local_it_ as *mut stc_word_deque_iter)).next() }

        }

    }

    return __local_out

}

// contract: receiver-mut:stc_word_deque,unproved:1:read only
pub unsafe fn stc_word_deque_copy(__param_self_: *mut stc_word_deque, __param_other: *const stc_word_deque) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    stc_word_deque_drop((__param_self_ as *const stc_word_deque))

    let __ci_copy_18: stc_word_deque = stc_word_deque_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[stc_word_deque]())

}

// contract: unproved:0:read only
pub unsafe fn stc_word_deque_value_toraw(__param_pval: *const u64) -> u64 {
    return (*__param_pval)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_deque_front(__param_self_: *const stc_word_deque) -> *const u64 {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_deque_front_mut(__param_self_: *mut stc_word_deque) -> *mut u64 {
    return ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_deque_back(__param_self_: *const stc_word_deque) -> *const u64 {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_deque_back_mut(__param_self_: *mut stc_word_deque) -> *mut u64 {
    return ((stc_word_deque_back((__param_self_ as *const stc_word_deque)) as *mut u64))

}

// contract: receiver-mut:stc_word_deque,unproved:2:read only
pub unsafe fn stc_word_deque_insert_n(__param_self_: *mut stc_word_deque, __param_idx: i64, __param_arr: *const u64, __param_n: i64) -> stc_word_deque_iter {
    var __local_it_: stc_word_deque_iter = (*__param_self_).insert_uninit(__param_idx, __param_n)

    var __local_i: i64 = __param_idx

    var __local_j: i64 = ((0 as i64))


    while ((if __local_j < __param_n: 1 else: 0) != 0) {
        ((*(stc_word_deque_at_mut(__param_self_, __local_i))) = (((__param_arr[__local_j]) as u64)))

        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


    return __local_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_deque_at(__param_self_: *const stc_word_deque, __param_idx: i64) -> *const u64 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size() as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_deque_at".ptr, c"deque.h".ptr, (53 as i32), c"((size_t)(idx) < (size_t)(stc_word_deque_size(self)))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).cbuf + ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_deque_at_mut(__param_self_: *mut stc_word_deque, __param_idx: i64) -> *mut u64 {
    return ((stc_word_deque_at((__param_self_ as *const stc_word_deque), __param_idx) as *mut u64))

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slotrefs_sort_lowhigh(__param_self_: *mut stc_slotref, __param_lo: i64, __param_hi: i64) -> Unit {
    var __local_lo = __param_lo
    var __local_i: i64 = __local_lo

    var __local_j: i64


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: stc_slotref = (*((&raw const (__param_self_[(__local_lo + (((__param_hi - __local_lo) * 7) / 16))]) as *const stc_slotref) as *mut stc_slotref))

        var __local_rx: stc_slotref


        (__local_j = __param_hi)

        loop {
            loop {
                with_memcpy((&raw mut __local_rx as *mut u8), (&raw const (*((&raw const (__param_self_[__local_i]) as *const stc_slotref) as *mut stc_slotref)) as *const u8), sizeof[stc_slotref]())

                var __ci_expr_logic_0: i32 = 0

                if ((if (*(&raw mut __local_rx as *mut stc_slotref)).cmp.unwrap()(((&raw mut __local_rx as *mut stc_slotref) as *const c_void), ((&raw mut __local_pivot as *mut stc_slotref) as *const c_void)) < 0: 1 else: 0) != 0) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_0 != 0)) {
                    break
                }
            }

            loop {
                with_memcpy((&raw mut __local_rx as *mut u8), (&raw const (*((&raw const (__param_self_[__local_j]) as *const stc_slotref) as *mut stc_slotref)) as *const u8), sizeof[stc_slotref]())

                var __ci_expr_logic_1: i32 = 0

                if ((if (*(&raw mut __local_pivot as *mut stc_slotref)).cmp.unwrap()(((&raw mut __local_pivot as *mut stc_slotref) as *const c_void), ((&raw mut __local_rx as *mut stc_slotref) as *const c_void)) < 0: 1 else: 0) != 0) {
                    (__local_j = __local_j - 1)

                    (__ci_expr_logic_1 = (if __local_j != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_1 != 0)) {
                    break
                }
            }

            if ((if __local_i > __local_j: 1 else: 0) != 0) {
                break
            }

            loop {
                var __local__xp: *mut stc_slotref = (((&raw const (__param_self_[__local_i]) as *const stc_slotref) as *mut stc_slotref))

                var __local__yp: *mut stc_slotref = (((&raw const (__param_self_[__local_j]) as *const stc_slotref) as *mut stc_slotref))


                var __local__tv: stc_slotref = (*__local__xp)

                with_memcpy((&raw mut (*__local__xp) as *mut u8), (&raw const (*__local__yp) as *const u8), sizeof[stc_slotref]())

                with_memcpy((&raw mut (*__local__yp) as *mut u8), (&raw const __local__tv as *const u8), sizeof[stc_slotref]())

                if not ((0 != 0)) {
                    break
                }
            }

            (__local_i = __local_i + 1)

            (__local_j = __local_j - 1)

            if not (((if __local_i <= __local_j: 1 else: 0) != 0)) {
                break
            }
        }

        if ((if (__local_j - __local_lo) > (__param_hi - __local_i): 1 else: 0) != 0) {
            loop {
                var __local__xp_1: *mut i64 = ((&raw mut __local_lo as *mut i64))

                var __local__yp_1: *mut i64 = ((&raw mut __local_i as *mut i64))


                var __local__tv_1: i64 = (*__local__xp_1)

                ((*__local__xp_1) = (*__local__yp_1))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut i64 = ((&raw mut __param_hi as *mut i64))

                var __local__yp_2: *mut i64 = ((&raw mut __local_j as *mut i64))


                var __local__tv_2: i64 = (*__local__xp_2)

                ((*__local__xp_2) = (*__local__yp_2))

                ((*__local__yp_2) = __local__tv_2)

                if not ((0 != 0)) {
                    break
                }
            }

        }

        if ((if (__local_j - __local_lo) > 64: 1 else: 0) != 0) {
            stc_slotrefs_sort_lowhigh(__param_self_, __local_lo, __local_j)
        } else {
            if ((if __local_j > __local_lo: 1 else: 0) != 0) {
                stc_slotrefs_insertsort_lowhigh(__param_self_, __local_lo, __local_j)
            }
        }

        (__local_lo = __local_i)

    }

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slotrefs_lower_bound_range(__param_self_: *const stc_slotref, __param_raw: stc_slotref, __param_start: i64, __param_end: i64) -> i64 {
    var __local_start = __param_start
    var __local_count: i64 = (((__param_end - __local_start) as i64))

    var __local_step: i64 = (((__local_count / 2) as i64))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: stc_slotref = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const stc_slotref))

        if ((if (*(&raw const __local_rx as *const stc_slotref)).cmp.unwrap()(((&raw const __local_rx as *const stc_slotref) as *const c_void), ((&raw const __param_raw as *const stc_slotref) as *const c_void)) < 0: 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as i64)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as i64)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as i64) else: __local_start)

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slotrefs_binary_search_range(__param_self_: *const stc_slotref, __param_raw: stc_slotref, __param_start: i64, __param_end: i64) -> i64 {
    var __local_res: i64 = ((stc_slotrefs_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as i64))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: stc_slotref = (*(&raw const (__param_self_[__local_res]) as *const stc_slotref))

        if ((if (*(&raw const __param_raw as *const stc_slotref)).cmp.unwrap()(((&raw const __param_raw as *const stc_slotref) as *const c_void), ((&raw const __local_rx as *const stc_slotref) as *const c_void)) < 0: 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as i64)))
        }

    }

    return __local_res

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slotrefs_sort(__param_arr: *mut stc_slotref, __param_n: i64) {
    stc_slotrefs_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slotrefs_lower_bound(__param_arr: *const stc_slotref, __param_raw: stc_slotref, __param_n: i64) -> i64 {
    return stc_slotrefs_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slotrefs_binary_search(__param_arr: *const stc_slotref, __param_raw: stc_slotref, __param_n: i64) -> i64 {
    return stc_slotrefs_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:indexed as an array
unsafe fn stc_slotrefs_insertsort_lowhigh(__param_self_: *mut stc_slotref, __param_lo: i64, __param_hi: i64) {
    var __local_j: i64 = __param_lo

    var __local_i: i64 = (((__param_lo + 1) as i64))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: stc_slotref = (*((&raw const (__param_self_[__local_i]) as *const stc_slotref) as *mut stc_slotref))

        var __local_rx: stc_slotref = (*(&raw mut __local_x as *mut stc_slotref))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: stc_slotref = (*((&raw const (__param_self_[__local_j]) as *const stc_slotref) as *mut stc_slotref))

            if ((if not ((if (*(&raw mut __local_rx as *mut stc_slotref)).cmp.unwrap()(((&raw mut __local_rx as *mut stc_slotref) as *const c_void), ((&raw mut __local_ry as *mut stc_slotref) as *const c_void)) < 0: 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            with_memcpy((&raw mut (*((&raw const (__param_self_[(__local_j + 1)]) as *const stc_slotref) as *mut stc_slotref)) as *mut u8), (&raw const (*((&raw const (__param_self_[__local_j]) as *const stc_slotref) as *mut stc_slotref)) as *const u8), sizeof[stc_slotref]())

            (__local_j = __local_j - 1)

        }

        with_memcpy((&raw mut (*((&raw const (__param_self_[(__local_j + 1)]) as *const stc_slotref) as *mut stc_slotref)) as *mut u8), (&raw const __local_x as *const u8), sizeof[stc_slotref]())


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn stc_i64s_sort_lowhigh(__param_self_: *mut i64, __param_lo: i64, __param_hi: i64) -> Unit {
    var __local_lo = __param_lo
    var __local_i: i64 = __local_lo

    var __local_j: i64


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: i64 = (*((&raw const (__param_self_[(__local_lo + (((__param_hi - __local_lo) * 7) / 16))]) as *const i64) as *mut i64))

        var __local_rx: i64


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_i]) as *const i64) as *mut i64)))

                var __ci_expr_logic_0: i32 = 0

                if ((if (*(&raw mut __local_rx as *mut i64)) < (*(&raw mut __local_pivot as *mut i64)): 1 else: 0) != 0) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_0 != 0)) {
                    break
                }
            }

            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_j]) as *const i64) as *mut i64)))

                var __ci_expr_logic_1: i32 = 0

                if ((if (*(&raw mut __local_pivot as *mut i64)) < (*(&raw mut __local_rx as *mut i64)): 1 else: 0) != 0) {
                    (__local_j = __local_j - 1)

                    (__ci_expr_logic_1 = (if __local_j != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_1 != 0)) {
                    break
                }
            }

            if ((if __local_i > __local_j: 1 else: 0) != 0) {
                break
            }

            loop {
                var __local__xp: *mut i64 = (((&raw const (__param_self_[__local_i]) as *const i64) as *mut i64))

                var __local__yp: *mut i64 = (((&raw const (__param_self_[__local_j]) as *const i64) as *mut i64))


                var __local__tv: i64 = (*__local__xp)

                ((*__local__xp) = (*__local__yp))

                ((*__local__yp) = __local__tv)

                if not ((0 != 0)) {
                    break
                }
            }

            (__local_i = __local_i + 1)

            (__local_j = __local_j - 1)

            if not (((if __local_i <= __local_j: 1 else: 0) != 0)) {
                break
            }
        }

        if ((if (__local_j - __local_lo) > (__param_hi - __local_i): 1 else: 0) != 0) {
            loop {
                var __local__xp_1: *mut i64 = ((&raw mut __local_lo as *mut i64))

                var __local__yp_1: *mut i64 = ((&raw mut __local_i as *mut i64))


                var __local__tv_1: i64 = (*__local__xp_1)

                ((*__local__xp_1) = (*__local__yp_1))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut i64 = ((&raw mut __param_hi as *mut i64))

                var __local__yp_2: *mut i64 = ((&raw mut __local_j as *mut i64))


                var __local__tv_2: i64 = (*__local__xp_2)

                ((*__local__xp_2) = (*__local__yp_2))

                ((*__local__yp_2) = __local__tv_2)

                if not ((0 != 0)) {
                    break
                }
            }

        }

        if ((if (__local_j - __local_lo) > 64: 1 else: 0) != 0) {
            stc_i64s_sort_lowhigh(__param_self_, __local_lo, __local_j)
        } else {
            if ((if __local_j > __local_lo: 1 else: 0) != 0) {
                stc_i64s_insertsort_lowhigh(__param_self_, __local_lo, __local_j)
            }
        }

        (__local_lo = __local_i)

    }

}

// contract: unproved:0:read only
pub unsafe fn stc_i64s_lower_bound_range(__param_self_: *const i64, __param_raw: i64, __param_start: i64, __param_end: i64) -> i64 {
    var __local_start = __param_start
    var __local_count: i64 = (((__param_end - __local_start) as i64))

    var __local_step: i64 = (((__local_count / 2) as i64))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: i64 = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const i64))

        if ((if (*(&raw const __local_rx as *const i64)) < (*(&raw const __param_raw as *const i64)): 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as i64)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as i64)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as i64) else: __local_start)

}

// contract: unproved:0:read only
pub unsafe fn stc_i64s_binary_search_range(__param_self_: *const i64, __param_raw: i64, __param_start: i64, __param_end: i64) -> i64 {
    var __local_res: i64 = ((stc_i64s_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as i64))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: i64 = (*(&raw const (__param_self_[__local_res]) as *const i64))

        if ((if (*(&raw const __param_raw as *const i64)) < (*(&raw const __local_rx as *const i64)): 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as i64)))
        }

    }

    return __local_res

}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn stc_i64s_sort(__param_arr: *mut i64, __param_n: i64) {
    stc_i64s_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

// contract: unproved:0:read only
pub unsafe fn stc_i64s_lower_bound(__param_arr: *const i64, __param_raw: i64, __param_n: i64) -> i64 {
    return stc_i64s_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:read only
pub unsafe fn stc_i64s_binary_search(__param_arr: *const i64, __param_raw: i64, __param_n: i64) -> i64 {
    return stc_i64s_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:out-parameter read before the write
unsafe fn stc_i64s_insertsort_lowhigh(__param_self_: *mut i64, __param_lo: i64, __param_hi: i64) {
    var __local_j: i64 = __param_lo

    var __local_i: i64 = (((__param_lo + 1) as i64))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: i64 = (*((&raw const (__param_self_[__local_i]) as *const i64) as *mut i64))

        var __local_rx: i64 = (*(&raw mut __local_x as *mut i64))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: i64 = (*((&raw const (__param_self_[__local_j]) as *const i64) as *mut i64))

            if ((if not ((if (*(&raw mut __local_rx as *mut i64)) < (*(&raw mut __local_ry as *mut i64)): 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (__param_self_[(__local_j + 1)]) as *const i64) as *mut i64)) = (*((&raw const (__param_self_[__local_j]) as *const i64) as *mut i64)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (__param_self_[(__local_j + 1)]) as *const i64) as *mut i64)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn stc_u64s_sort_lowhigh(__param_self_: *mut u64, __param_lo: i64, __param_hi: i64) -> Unit {
    var __local_lo = __param_lo
    var __local_i: i64 = __local_lo

    var __local_j: i64


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: u64 = (*((&raw const (__param_self_[(__local_lo + (((__param_hi - __local_lo) * 7) / 16))]) as *const u64) as *mut u64))

        var __local_rx: u64


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_i]) as *const u64) as *mut u64)))

                var __ci_expr_logic_0: i32 = 0

                if ((if (*(&raw mut __local_rx as *mut u64)) < (*(&raw mut __local_pivot as *mut u64)): 1 else: 0) != 0) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_0 != 0)) {
                    break
                }
            }

            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_j]) as *const u64) as *mut u64)))

                var __ci_expr_logic_1: i32 = 0

                if ((if (*(&raw mut __local_pivot as *mut u64)) < (*(&raw mut __local_rx as *mut u64)): 1 else: 0) != 0) {
                    (__local_j = __local_j - 1)

                    (__ci_expr_logic_1 = (if __local_j != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_1 != 0)) {
                    break
                }
            }

            if ((if __local_i > __local_j: 1 else: 0) != 0) {
                break
            }

            loop {
                var __local__xp: *mut u64 = (((&raw const (__param_self_[__local_i]) as *const u64) as *mut u64))

                var __local__yp: *mut u64 = (((&raw const (__param_self_[__local_j]) as *const u64) as *mut u64))


                var __local__tv: u64 = (*__local__xp)

                ((*__local__xp) = (*__local__yp))

                ((*__local__yp) = __local__tv)

                if not ((0 != 0)) {
                    break
                }
            }

            (__local_i = __local_i + 1)

            (__local_j = __local_j - 1)

            if not (((if __local_i <= __local_j: 1 else: 0) != 0)) {
                break
            }
        }

        if ((if (__local_j - __local_lo) > (__param_hi - __local_i): 1 else: 0) != 0) {
            loop {
                var __local__xp_1: *mut i64 = ((&raw mut __local_lo as *mut i64))

                var __local__yp_1: *mut i64 = ((&raw mut __local_i as *mut i64))


                var __local__tv_1: i64 = (*__local__xp_1)

                ((*__local__xp_1) = (*__local__yp_1))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut i64 = ((&raw mut __param_hi as *mut i64))

                var __local__yp_2: *mut i64 = ((&raw mut __local_j as *mut i64))


                var __local__tv_2: i64 = (*__local__xp_2)

                ((*__local__xp_2) = (*__local__yp_2))

                ((*__local__yp_2) = __local__tv_2)

                if not ((0 != 0)) {
                    break
                }
            }

        }

        if ((if (__local_j - __local_lo) > 64: 1 else: 0) != 0) {
            stc_u64s_sort_lowhigh(__param_self_, __local_lo, __local_j)
        } else {
            if ((if __local_j > __local_lo: 1 else: 0) != 0) {
                stc_u64s_insertsort_lowhigh(__param_self_, __local_lo, __local_j)
            }
        }

        (__local_lo = __local_i)

    }

}

// contract: unproved:0:read only
pub unsafe fn stc_u64s_lower_bound_range(__param_self_: *const u64, __param_raw: u64, __param_start: i64, __param_end: i64) -> i64 {
    var __local_start = __param_start
    var __local_count: i64 = (((__param_end - __local_start) as i64))

    var __local_step: i64 = (((__local_count / 2) as i64))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: u64 = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const u64))

        if ((if (*(&raw const __local_rx as *const u64)) < (*(&raw const __param_raw as *const u64)): 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as i64)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as i64)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as i64) else: __local_start)

}

// contract: unproved:0:read only
pub unsafe fn stc_u64s_binary_search_range(__param_self_: *const u64, __param_raw: u64, __param_start: i64, __param_end: i64) -> i64 {
    var __local_res: i64 = ((stc_u64s_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as i64))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: u64 = (*(&raw const (__param_self_[__local_res]) as *const u64))

        if ((if (*(&raw const __param_raw as *const u64)) < (*(&raw const __local_rx as *const u64)): 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as i64)))
        }

    }

    return __local_res

}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn stc_u64s_sort(__param_arr: *mut u64, __param_n: i64) {
    stc_u64s_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

// contract: unproved:0:read only
pub unsafe fn stc_u64s_lower_bound(__param_arr: *const u64, __param_raw: u64, __param_n: i64) -> i64 {
    return stc_u64s_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:read only
pub unsafe fn stc_u64s_binary_search(__param_arr: *const u64, __param_raw: u64, __param_n: i64) -> i64 {
    return stc_u64s_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:out-parameter read before the write
unsafe fn stc_u64s_insertsort_lowhigh(__param_self_: *mut u64, __param_lo: i64, __param_hi: i64) {
    var __local_j: i64 = __param_lo

    var __local_i: i64 = (((__param_lo + 1) as i64))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: u64 = (*((&raw const (__param_self_[__local_i]) as *const u64) as *mut u64))

        var __local_rx: u64 = (*(&raw mut __local_x as *mut u64))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: u64 = (*((&raw const (__param_self_[__local_j]) as *const u64) as *mut u64))

            if ((if not ((if (*(&raw mut __local_rx as *mut u64)) < (*(&raw mut __local_ry as *mut u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (__param_self_[(__local_j + 1)]) as *const u64) as *mut u64)) = (*((&raw const (__param_self_[__local_j]) as *const u64) as *mut u64)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (__param_self_[(__local_j + 1)]) as *const u64) as *mut u64)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn stc_f64s_sort_lowhigh(__param_self_: *mut f64, __param_lo: i64, __param_hi: i64) -> Unit {
    var __local_lo = __param_lo
    var __local_i: i64 = __local_lo

    var __local_j: i64


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: f64 = (*((&raw const (__param_self_[(__local_lo + (((__param_hi - __local_lo) * 7) / 16))]) as *const f64) as *mut f64))

        var __local_rx: f64


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_i]) as *const f64) as *mut f64)))

                var __ci_expr_logic_0: i32 = 0

                if ((if (*(&raw mut __local_rx as *mut f64)) < (*(&raw mut __local_pivot as *mut f64)): 1 else: 0) != 0) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_0 != 0)) {
                    break
                }
            }

            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_j]) as *const f64) as *mut f64)))

                var __ci_expr_logic_1: i32 = 0

                if ((if (*(&raw mut __local_pivot as *mut f64)) < (*(&raw mut __local_rx as *mut f64)): 1 else: 0) != 0) {
                    (__local_j = __local_j - 1)

                    (__ci_expr_logic_1 = (if __local_j != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_1 != 0)) {
                    break
                }
            }

            if ((if __local_i > __local_j: 1 else: 0) != 0) {
                break
            }

            loop {
                var __local__xp: *mut f64 = (((&raw const (__param_self_[__local_i]) as *const f64) as *mut f64))

                var __local__yp: *mut f64 = (((&raw const (__param_self_[__local_j]) as *const f64) as *mut f64))


                var __local__tv: f64 = (*__local__xp)

                ((*__local__xp) = (*__local__yp))

                ((*__local__yp) = __local__tv)

                if not ((0 != 0)) {
                    break
                }
            }

            (__local_i = __local_i + 1)

            (__local_j = __local_j - 1)

            if not (((if __local_i <= __local_j: 1 else: 0) != 0)) {
                break
            }
        }

        if ((if (__local_j - __local_lo) > (__param_hi - __local_i): 1 else: 0) != 0) {
            loop {
                var __local__xp_1: *mut i64 = ((&raw mut __local_lo as *mut i64))

                var __local__yp_1: *mut i64 = ((&raw mut __local_i as *mut i64))


                var __local__tv_1: i64 = (*__local__xp_1)

                ((*__local__xp_1) = (*__local__yp_1))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut i64 = ((&raw mut __param_hi as *mut i64))

                var __local__yp_2: *mut i64 = ((&raw mut __local_j as *mut i64))


                var __local__tv_2: i64 = (*__local__xp_2)

                ((*__local__xp_2) = (*__local__yp_2))

                ((*__local__yp_2) = __local__tv_2)

                if not ((0 != 0)) {
                    break
                }
            }

        }

        if ((if (__local_j - __local_lo) > 64: 1 else: 0) != 0) {
            stc_f64s_sort_lowhigh(__param_self_, __local_lo, __local_j)
        } else {
            if ((if __local_j > __local_lo: 1 else: 0) != 0) {
                stc_f64s_insertsort_lowhigh(__param_self_, __local_lo, __local_j)
            }
        }

        (__local_lo = __local_i)

    }

}

// contract: unproved:0:read only
pub unsafe fn stc_f64s_lower_bound_range(__param_self_: *const f64, __param_raw: f64, __param_start: i64, __param_end: i64) -> i64 {
    var __local_start = __param_start
    var __local_count: i64 = (((__param_end - __local_start) as i64))

    var __local_step: i64 = (((__local_count / 2) as i64))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: f64 = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const f64))

        if ((if (*(&raw const __local_rx as *const f64)) < (*(&raw const __param_raw as *const f64)): 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as i64)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as i64)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as i64) else: __local_start)

}

// contract: unproved:0:read only
pub unsafe fn stc_f64s_binary_search_range(__param_self_: *const f64, __param_raw: f64, __param_start: i64, __param_end: i64) -> i64 {
    var __local_res: i64 = ((stc_f64s_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as i64))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: f64 = (*(&raw const (__param_self_[__local_res]) as *const f64))

        if ((if (*(&raw const __param_raw as *const f64)) < (*(&raw const __local_rx as *const f64)): 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as i64)))
        }

    }

    return __local_res

}

// contract: unproved:0:out-parameter read before the write
pub unsafe fn stc_f64s_sort(__param_arr: *mut f64, __param_n: i64) {
    stc_f64s_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

// contract: unproved:0:read only
pub unsafe fn stc_f64s_lower_bound(__param_arr: *const f64, __param_raw: f64, __param_n: i64) -> i64 {
    return stc_f64s_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:read only
pub unsafe fn stc_f64s_binary_search(__param_arr: *const f64, __param_raw: f64, __param_n: i64) -> i64 {
    return stc_f64s_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

// contract: unproved:0:out-parameter read before the write
unsafe fn stc_f64s_insertsort_lowhigh(__param_self_: *mut f64, __param_lo: i64, __param_hi: i64) {
    var __local_j: i64 = __param_lo

    var __local_i: i64 = (((__param_lo + 1) as i64))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: f64 = (*((&raw const (__param_self_[__local_i]) as *const f64) as *mut f64))

        var __local_rx: f64 = (*(&raw mut __local_x as *mut f64))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: f64 = (*((&raw const (__param_self_[__local_j]) as *const f64) as *mut f64))

            if ((if not ((if (*(&raw mut __local_rx as *mut f64)) < (*(&raw mut __local_ry as *mut f64)): 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (__param_self_[(__local_j + 1)]) as *const f64) as *mut f64)) = (*((&raw const (__param_self_[__local_j]) as *const f64) as *mut f64)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (__param_self_[(__local_j + 1)]) as *const f64) as *mut f64)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

pub fn stc_word_set_clone(__param_map: stc_word_set) -> stc_word_set {
    if ((if (unsafe *(&raw const __param_map as *const stc_word_set)).bucket_count == 0: 1 else: 0) != 0) {
        return ((stc_word_set.zeroed() as stc_word_set))
    }

    var __local_out: stc_word_set = __param_map

    var __local_self_: *mut stc_word_set = ((&raw mut __local_out as *mut stc_word_set))


    var __local__mbytes: i64 = (((((unsafe *(&raw const __param_map as *const stc_word_set)).bucket_count + 1) * (sizeof[hmap_meta]() as i64)) as i64))

    (__local_out.table = (((with_alloc((((if 1 != 0: (((unsafe *(&raw const __param_map as *const stc_word_set)).bucket_count * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

    (__local_out.meta = (((with_alloc((((if 1 != 0: __local__mbytes else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut hmap_meta)))

    var __ci_expr_logic_0: i32 = 0

    if ((unsafe *(&raw const __local_out as *const stc_word_set)).table != null) {
        (__ci_expr_logic_0 = (if (unsafe *(&raw const __local_out as *const stc_word_set)).meta != null: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        with_memcpy((((unsafe *(&raw const __local_out as *const stc_word_set)).meta as *mut c_void) as *mut u8), (((unsafe *(&raw const __param_map as *const stc_word_set)).meta as *const c_void) as *const u8), (((if 1 != 0: __local__mbytes else: (-1 as i64)) as u64) as i64))

        var __local_i: i64 = ((0 as i64))

        while ((if __local_i < (unsafe *(&raw const __param_map as *const stc_word_set)).bucket_count: 1 else: 0) != 0) {
            if (((unsafe __param_map.meta[__local_i])).dist() != 0) {
                ((unsafe __local_out.table[__local_i]) = ((unsafe { (*(__local_self_ as *const stc_word_set)).value_clone((((*(&raw const __param_map as *const stc_word_set)).table[__local_i]) as u64)) } as u64)))
            }

            (__local_i = __local_i + 1)

        }


        return __local_out

    }
    if ((unsafe *(&raw const __local_out as *const stc_word_set)).meta != null) {
        with_free((((unsafe *(&raw const __local_out as *const stc_word_set)).meta as *mut c_void) as *mut u8))
    }

    if ((unsafe *(&raw const __local_out as *const stc_word_set)).table != null) {
        with_free((((unsafe *(&raw const __local_out as *const stc_word_set)).table as *mut c_void) as *mut u8))
    }

    return ((stc_word_set.zeroed() as stc_word_set))



}

// contract: unproved:0:casts away const
pub unsafe fn stc_word_set_drop(__param_cself: *const stc_word_set) {
    var __local_self_: *mut stc_word_set = ((__param_cself as *mut stc_word_set))

    if ((if (*__param_cself).meta == null: 1 else: 0) != 0) {
        return
    }

    stc_word_set_wipe_(__local_self_)

    with_free((((*__local_self_).meta as *mut c_void) as *mut u8))

    with_free((((*__local_self_).table as *mut c_void) as *mut u8))

}

// contract: receiver-mut:stc_word_set,unproved:1:read only
pub unsafe fn stc_word_set_erase_entry(__param_self_: *mut stc_word_set, __param__val: *mut u64) {
    var __local_d: *mut u64 = (*__param_self_).table

    var __local_m: *mut hmap_meta = (*__param_self_).meta

    var __local_i: u64 = ((((((__param__val as usize) -% (__local_d as usize)) as i64) / (sizeof[u64]() as i64)) as u64))

    var __local_j: u64 = __local_i


    var __local_mask: u64 = (((((*__param_self_).bucket_count as u64) -% (1 as u64)) as u64))

    stc_word_set_value_drop((__param_self_ as *const stc_word_set), __param__val)

    while true {
        (__local_j = ((((((__local_j as u64) +% (1 as u64)) as u64) & (__local_mask as u64)) as u64)))

        if ((if ((__local_m[__local_j])).dist() < 2: 1 else: 0) != 0) {
            break
        }

        ((__local_d[__local_i]) = (((__local_d[__local_j]) as u64)))

        ((__local_m[__local_i]) = (__local_m[__local_j]))

        ((__local_m[__local_i])).set_dist((((__local_m[__local_i])).dist() -% 1))

        (__local_i = __local_j)

    }

    ((__local_m[__local_i])).set_dist(((0 as u16)))

    ((*__param_self_).size = (*__param_self_).size - 1)

}

// contract: receiver:stc_word_set,unproved:1:read only
pub unsafe fn stc_word_set_bucket_lookup_(__param_self_: *const stc_word_set, __param_rkeyptr: *const u64) -> stc_word_set_result {
    var __local__hash: u64 = ((c_hash_n((__param_rkeyptr as *const c_void), (8 as i64)) as u64))

    var __local__idxmask: u64 = (((((*__param_self_).bucket_count as u64) -% (1 as u64)) as u64))

    var __local__res: stc_word_set_result = stc_word_set_result { idx: ((__local__hash as u64) & (__local__idxmask as u64)), hashx: (((((((__local__hash as u64) >> (24 as u32))) as u64) & (63 as u64))) as u8), dist: 1 }

    while ((if (*(&raw const __local__res as *const stc_word_set_result)).dist <= (((*__param_self_).meta[(*(&raw const __local__res as *const stc_word_set_result)).idx])).dist(): 1 else: 0) != 0) {
        if ((if (((*__param_self_).meta[(*(&raw const __local__res as *const stc_word_set_result)).idx])).hashx() == (*(&raw const __local__res as *const stc_word_set_result)).hashx: 1 else: 0) != 0) {
            var __local__raw: u64 = (*((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const stc_word_set_result)).idx]) as *const u64) as *mut u64))

            if ((if (*(&raw const __local__raw as *const u64)) == (*__param_rkeyptr): 1 else: 0) != 0) {
                (__local__res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const stc_word_set_result)).idx]) as *const u64) as *mut u64)))

                break

            }

        }

        (__local__res.idx = (((((((*(&raw const __local__res as *const stc_word_set_result)).idx as u64) +% (1 as u64)) as u64) & (__local__idxmask as u64)) as u64)))

        (__local__res.dist = ((*(&raw const __local__res as *const stc_word_set_result)).dist +% 1))

    }

    return __local__res

}

// contract: receiver-mut:stc_word_set,unproved:1:read only
pub unsafe fn stc_word_set_bucket_insert_(__param_self_: *const stc_word_set, __param_rkeyptr: *const u64) -> stc_word_set_result {
    var __local_res: stc_word_set_result = stc_word_set_bucket_lookup_(__param_self_, __param_rkeyptr)

    if ((*(&raw const __local_res as *const stc_word_set_result)).ref != null) {
        return __local_res
    }

    (__local_res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const stc_word_set_result)).idx]) as *const u64) as *mut u64)))

    (__local_res.inserted = true)

    var __local_mnew: hmap_meta = with 0 as __ci_bits_seq_59 { var __ci_bits: hmap_meta = hmap_meta.zeroed(); __ci_bits.set_hashx((((((((*(&raw const __local_res as *const stc_word_set_result)).hashx as u32) as i32) as u32) & (63 as u32))) as u16)); __ci_bits.set_dist((((((((*(&raw const __local_res as *const stc_word_set_result)).dist as u32) as i32) as u32) & (1023 as u32))) as u16)); __ci_bits }

    var __local_mcur: hmap_meta = ((*__param_self_).meta[(*(&raw const __local_res as *const stc_word_set_result)).idx])

    (((*__param_self_).meta[(*(&raw const __local_res as *const stc_word_set_result)).idx]) = __local_mnew)

    if ((if __local_mcur.dist() != 0: 1 else: 0) != 0) {
        var __local_mask: u64 = (((((*__param_self_).bucket_count as u64) -% (1 as u64)) as u64))

        var __local_dcur: u64 = (*((*(&raw const __local_res as *const stc_word_set_result)).ref))

        while true {
            (__local_res.idx = (((((((*(&raw const __local_res as *const stc_word_set_result)).idx as u64) +% (1 as u64)) as u64) & (__local_mask as u64)) as u64)))

            __local_mcur.set_dist((__local_mcur.dist() +% 1))

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const stc_word_set_result)).idx])).dist() == 0: 1 else: 0) != 0) {
                break
            }

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const stc_word_set_result)).idx])).dist() < __local_mcur.dist(): 1 else: 0) != 0) {
                loop {
                    var __local__xp: *mut hmap_meta = ((&raw mut __local_mcur as *mut hmap_meta))

                    var __local__yp: *mut hmap_meta = (((&raw const ((*__param_self_).meta[(*(&raw const __local_res as *const stc_word_set_result)).idx]) as *const hmap_meta) as *mut hmap_meta))


                    var __local__tv: hmap_meta = (*__local__xp)

                    with_memcpy((&raw mut (*__local__xp) as *mut u8), (&raw const (*__local__yp) as *const u8), sizeof[hmap_meta]())

                    with_memcpy((&raw mut (*__local__yp) as *mut u8), (&raw const __local__tv as *const u8), sizeof[hmap_meta]())

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    var __local__xp_1: *mut u64 = ((&raw mut __local_dcur as *mut u64))

                    var __local__yp_1: *mut u64 = (((&raw const ((*__param_self_).table[(*(&raw const __local_res as *const stc_word_set_result)).idx]) as *const u64) as *mut u64))


                    var __local__tv_1: u64 = (*__local__xp_1)

                    ((*__local__xp_1) = (*__local__yp_1))

                    ((*__local__yp_1) = __local__tv_1)

                    if not ((0 != 0)) {
                        break
                    }
                }

            }

        }

        (((*__param_self_).meta[(*(&raw const __local_res as *const stc_word_set_result)).idx]) = __local_mcur)

        (((*__param_self_).table[(*(&raw const __local_res as *const stc_word_set_result)).idx]) = __local_dcur)

    }

    return __local_res

}

// contract: receiver-mut:stc_word_set,unproved:1:read only
pub unsafe fn stc_word_set_copy(__param_self_: *mut stc_word_set, __param_other: *const stc_word_set) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    stc_word_set_drop((__param_self_ as *const stc_word_set))

    let __ci_copy_18: stc_word_set = stc_word_set_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[stc_word_set]())

}

// contract: unproved:0:read only
pub unsafe fn stc_word_set_value_toraw(__param_val: *const u64) -> u64 {
    return (*__param_val)

}

// contract: receiver:stc_word_set,unproved:1:read only
pub unsafe fn stc_word_set_value_drop(__param_self_: *const stc_word_set, __param__val: *mut u64) {
    return
}

// contract: receiver-mut:stc_word_set,unproved:1:read only
pub unsafe fn stc_word_set_put_n(__param_self_: *mut stc_word_set, __param_raw: *const u64, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (*__param_self_).insert((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_word_set_init() -> stc_word_set {
    var __local_cx: stc_word_set = stc_word_set.zeroed()

    return __local_cx

}

// contract: unproved:0:read only
pub unsafe fn stc_word_set_from_n(__param_raw: *const u64, __param_n: i64) -> stc_word_set {
    var __local_cx: stc_word_set = stc_word_set.zeroed()

    stc_word_set_put_n((&raw mut __local_cx as *mut stc_word_set), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_word_set_with_capacity(__param_cap: i64) -> stc_word_set {
    var __local_cx: stc_word_set = stc_word_set.zeroed()

    unsafe { (*(&raw mut __local_cx as *mut stc_word_set)).reserve(__param_cap) }

    return __local_cx

}

pub fn stc_word_set_advance(__param_it_: stc_word_set_iter, __param_n: u64) -> stc_word_set_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const stc_word_set_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { (*(&raw mut __param_it_ as *mut stc_word_set_iter)).next() }

    }

    return __param_it_

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_set_get(__param_self_: *const stc_word_set, __param_rkey: u64) -> *const u64 {
    return (((if (*__param_self_).size != 0: stc_word_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut u64) as *const u64)).ref else: (null as *mut u64)) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_set_get_mut(__param_self_: *mut stc_word_set, __param_rkey: u64) -> *mut u64 {
    return ((stc_word_set_get((__param_self_ as *const stc_word_set), __param_rkey) as *mut u64))

}

// contract: receiver:stc_word_set,unproved:1:read only
pub unsafe fn stc_word_set_eq(__param_self_: *const stc_word_set, __param_other: *const stc_word_set) -> bool {
    if ((if (*__param_self_).size() != (*__param_other).size(): 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_i: stc_word_set_iter = (*__param_self_).begin()

    while ((*(&raw const __local_i as *const stc_word_set_iter)).ref != null) {
        var __local__raw: u64 = (*((*(&raw const __local_i as *const stc_word_set_iter)).ref))

        if ((if not (*__param_other).contains(__local__raw): 1 else: 0) != 0) {
            return ((false as bool))
        }


        (*(&raw mut __local_i as *mut stc_word_set_iter)).next()

    }


    return ((true as bool))

}

unsafe fn stc_word_set_wipe_(__param_self_: *mut stc_word_set) {
    var __local_d: *mut u64 = (*__param_self_).table

    var __local_m: *const hmap_meta = (((*__param_self_).meta as *const hmap_meta))

    var __local_n: i64 = (*__param_self_).bucket_count

    var __local_i: i64 = ((0 as i64))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        var __ci_expr_old_0: *const hmap_meta = __local_m

        (__local_m = __local_m + 1)

        if ((*__ci_expr_old_0).dist() != 0) {
            stc_word_set_value_drop((__param_self_ as *const stc_word_set), ((&raw const (__local_d[__local_i]) as *const u64) as *mut u64))
        }


        (__local_i = __local_i + 1)

    }


}

// contract: receiver-mut:stc_word_pqueue,unproved:1:read only
pub unsafe fn stc_word_pqueue_put_n(__param_self_: *mut stc_word_pqueue, __param_raw: *const i64, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (*__param_self_).push((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_word_pqueue_init() -> stc_word_pqueue {
    return ((stc_word_pqueue.zeroed() as stc_word_pqueue))

}

// contract: unproved:0:read only
pub unsafe fn stc_word_pqueue_from_n(__param_raw: *const i64, __param_n: i64) -> stc_word_pqueue {
    var __local_cx: stc_word_pqueue = stc_word_pqueue.zeroed()

    stc_word_pqueue_put_n((&raw mut __local_cx as *mut stc_word_pqueue), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_word_pqueue_with_capacity(__param_cap: i64) -> stc_word_pqueue {
    var __local_cx: stc_word_pqueue = stc_word_pqueue.zeroed()

    unsafe { (*(&raw mut __local_cx as *mut stc_word_pqueue)).reserve(__param_cap) }

    return __local_cx

}

// contract: unproved:0:casts away const
pub unsafe fn stc_word_pqueue_drop(__param_cself: *const stc_word_pqueue) {
    var __local_self_: *mut stc_word_pqueue = ((__param_cself as *mut stc_word_pqueue))

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    (*__local_self_).clear()

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_pqueue_top(__param_self_: *const stc_word_pqueue) -> *const i64 {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_pqueue_top".ptr, c"pqueue.h".ptr, (117 as i32), c"self->size".ptr)
    } else {
        0
    }

    return ((((&raw const ((*__param_self_).data[0]) as *const i64) as *mut i64) as *const i64))

}

// contract: unproved:0:stc_word_pqueue_sift_down_ may write through it
pub unsafe fn stc_word_pqueue_pushpull(__param_self_: *mut stc_word_pqueue, __param_val: i64) -> i64 {
    var __ci_expr_logic_0: i32 = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw mut __param_val as *mut i64)) < (*((&raw const ((*__param_self_).data[0]) as *const i64) as *mut i64)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        loop {
            var __local__xp: *mut i64 = ((&raw mut __param_val as *mut i64))

            var __local__yp: *mut i64 = (((&raw const ((*__param_self_).data[0]) as *const i64) as *mut i64))


            var __local__tv: i64 = (*__local__xp)

            ((*__local__xp) = (*__local__yp))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

        (*__param_self_).sift_down_((1 as i64), (*__param_self_).size)

    }


    return __param_val

}

// contract: unproved:0:stc_word_pqueue_sift_down_ may write through it
pub unsafe fn stc_word_pqueue_exchange(__param_self_: *mut stc_word_pqueue, __param_val: i64) -> i64 {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_pqueue_exchange".ptr, c"pqueue.h".ptr, (138 as i32), c"self->size".ptr)
    } else {
        0
    }

    loop {
        var __local__xp: *mut i64 = ((&raw mut __param_val as *mut i64))

        var __local__yp: *mut i64 = (((&raw const ((*__param_self_).data[0]) as *const i64) as *mut i64))


        var __local__tv: i64 = (*__local__xp)

        ((*__local__xp) = (*__local__yp))

        ((*__local__yp) = __local__tv)

        if not ((0 != 0)) {
            break
        }
    }

    (*__param_self_).sift_down_((1 as i64), (*__param_self_).size)

    return __param_val

}

pub fn stc_word_pqueue_clone(__param_q: stc_word_pqueue) -> stc_word_pqueue {
    var __local_out: stc_word_pqueue = __param_q

    var __local_self_: *mut stc_word_pqueue = ((&raw mut __local_out as *mut stc_word_pqueue))



    (__local_out.size = ((0 as i64)))

    (__local_out.capacity = (unsafe *(&raw const __local_out as *const stc_word_pqueue)).size)


    (__local_out.data = ((null as *mut i64)))

    unsafe { (*(&raw mut __local_out as *mut stc_word_pqueue)).reserve((*(&raw const __param_q as *const stc_word_pqueue)).size) }

    (__local_out.size = (unsafe *(&raw const __param_q as *const stc_word_pqueue)).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (unsafe *(&raw const __param_q as *const stc_word_pqueue)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (((unsafe (*(&raw const __param_q as *const stc_word_pqueue)).data[__local_i]) as i64)))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

// contract: receiver-mut:stc_word_pqueue,unproved:1:read only
pub unsafe fn stc_word_pqueue_copy(__param_self_: *mut stc_word_pqueue, __param_other: *const stc_word_pqueue) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    stc_word_pqueue_drop((__param_self_ as *const stc_word_pqueue))

    let __ci_copy_18: stc_word_pqueue = stc_word_pqueue_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[stc_word_pqueue]())

}

// contract: unproved:0:casts away const
pub unsafe fn stc_slot_stack_drop(__param_cself: *const stc_slot_stack) {
    var __local_self_: *mut stc_slot_stack = ((__param_cself as *mut stc_slot_stack))

    (*__local_self_).clear()

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

// contract: receiver:stc_slot_stack,unproved:1:read only
pub unsafe fn stc_slot_stack_value_drop(__param_self_: *const stc_slot_stack, __param_val: *mut *mut stc_slot_head) {
    return
}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_front(__param_self_: *const stc_slot_stack) -> *const *mut stc_slot_head {
    return ((((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_front_mut(__param_self_: *mut stc_slot_stack) -> *mut *mut stc_slot_head {
    return (((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_back(__param_self_: *const stc_slot_stack) -> *const *mut stc_slot_head {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_back_mut(__param_self_: *mut stc_slot_stack) -> *mut *mut stc_slot_head {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_top(__param_self_: *const stc_slot_stack) -> *const *mut stc_slot_head {
    return ((stc_slot_stack_back(__param_self_) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_top_mut(__param_self_: *mut stc_slot_stack) -> *mut *mut stc_slot_head {
    return ((stc_slot_stack_back_mut(__param_self_) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_stack,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_stack_push(__param_self_: *mut stc_slot_stack, __param_val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    if ((if (*__param_self_).size == (*(__param_self_ as *const stc_slot_stack)).capacity(): 1 else: 0) != 0) {
        if ((if not (*__param_self_).reserve((((((*__param_self_).size * 3) / 2) + 4) as i64)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }
    }

    var __local_vp: *mut *mut stc_slot_head = with 0 as __ci_expr_seq_10 {
        var __ci_expr_old_0: i64 = (*__param_self_).size
        ((*__param_self_).size = (*__param_self_).size + 1)
        ((*__param_self_).data + ((__ci_expr_old_0 as i64) as usize))
    }

    ((*__local_vp) = __param_val)

    return __local_vp

}

// contract: receiver-mut:stc_slot_stack,unproved:1:read only
pub unsafe fn stc_slot_stack_put_n(__param_self_: *mut stc_slot_stack, __param_raw: *const *mut stc_slot_head, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_stack_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_slot_stack_init() -> stc_slot_stack {
    var __local_out: stc_slot_stack = stc_slot_stack.zeroed()

    return __local_out

}

pub fn stc_slot_stack_with_capacity(__param_cap: i64) -> stc_slot_stack {
    var __local_out: stc_slot_stack = stc_slot_stack { data: (((with_alloc((((if 1 != 0: ((__param_cap * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)), size: 0, capacity: __param_cap }

    return __local_out

}

pub fn stc_slot_stack_with_size_uninit(__param_size: i64) -> stc_slot_stack {
    var __local_out: stc_slot_stack = stc_slot_stack { data: (((with_alloc((((if 1 != 0: ((__param_size * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)), size: __param_size, capacity: __param_size }

    return __local_out

}

// contract: stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_stack_with_size(__param_size: i64, __param_default_raw: *mut stc_slot_head) -> stc_slot_stack {
    var __local_size = __param_size
    var __local_out: stc_slot_stack = stc_slot_stack { data: (((with_alloc((((if 1 != 0: ((__local_size * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)), size: __local_size, capacity: __local_size }

    while (__local_size != 0) {
        (__local_size = __local_size - 1)

        ((__local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_stack_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_stack {
    var __local_out: stc_slot_stack = stc_slot_stack_with_capacity(__param_n)

    stc_slot_stack_put_n((&raw mut __local_out as *mut stc_slot_stack), __param_raw, __param_n)

    return __local_out

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_at(__param_self_: *const stc_slot_stack, __param_idx: i64) -> *const *mut stc_slot_head {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_stack_at".ptr, c"stack.h".ptr, (189 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_stack_at_mut(__param_self_: *mut stc_slot_stack, __param_idx: i64) -> *mut *mut stc_slot_head {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_stack_at_mut".ptr, c"stack.h".ptr, (192 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((*__param_self_).data + ((__param_idx as i64) as usize))

}

// contract: unproved:0:returns a pointer loaded from the parameter
pub unsafe fn stc_slot_stack_value_toraw(__param_val: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_val)

}

pub fn stc_slot_stack_advance(__param_it_: stc_slot_stack_iter, __param_n: u64) -> stc_slot_stack_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_slot_stack_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const stc_slot_stack_iter)).ref >= (unsafe *(&raw const __param_it_ as *const stc_slot_stack_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
    }


    return __param_it_

}

// contract: unproved:0:casts away const
pub unsafe fn stc_word_stack_drop(__param_cself: *const stc_word_stack) {
    var __local_self_: *mut stc_word_stack = ((__param_cself as *mut stc_word_stack))

    (*__local_self_).clear()

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

// contract: receiver:stc_word_stack,unproved:1:read only
pub unsafe fn stc_word_stack_value_drop(__param_self_: *const stc_word_stack, __param_val: *mut u64) {
    return
}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_front(__param_self_: *const stc_word_stack) -> *const u64 {
    return ((((&raw const ((*__param_self_).data[0]) as *const u64) as *mut u64) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_front_mut(__param_self_: *mut stc_word_stack) -> *mut u64 {
    return (((&raw const ((*__param_self_).data[0]) as *const u64) as *mut u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_back(__param_self_: *const stc_word_stack) -> *const u64 {
    return ((((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const u64) as *mut u64) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_back_mut(__param_self_: *mut stc_word_stack) -> *mut u64 {
    return (((&raw const ((*__param_self_).data[((*__param_self_).size - 1)]) as *const u64) as *mut u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_top(__param_self_: *const stc_word_stack) -> *const u64 {
    return ((stc_word_stack_back(__param_self_) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_top_mut(__param_self_: *mut stc_word_stack) -> *mut u64 {
    return ((stc_word_stack_back_mut(__param_self_) as *mut u64))

}

// contract: receiver-mut:stc_word_stack,unproved:1:read only
pub unsafe fn stc_word_stack_put_n(__param_self_: *mut stc_word_stack, __param_raw: *const u64, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (*__param_self_).push((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_word_stack_init() -> stc_word_stack {
    var __local_out: stc_word_stack = stc_word_stack.zeroed()

    return __local_out

}

pub fn stc_word_stack_with_capacity(__param_cap: i64) -> stc_word_stack {
    var __local_out: stc_word_stack = stc_word_stack { data: (((with_alloc((((if 1 != 0: ((__param_cap * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)), size: 0, capacity: __param_cap }

    return __local_out

}

pub fn stc_word_stack_with_size_uninit(__param_size: i64) -> stc_word_stack {
    var __local_out: stc_word_stack = stc_word_stack { data: (((with_alloc((((if 1 != 0: ((__param_size * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)), size: __param_size, capacity: __param_size }

    return __local_out

}

pub fn stc_word_stack_with_size(__param_size: i64, __param_default_raw: u64) -> stc_word_stack {
    var __local_size = __param_size
    var __local_out: stc_word_stack = stc_word_stack { data: (((with_alloc((((if 1 != 0: ((__local_size * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)), size: __local_size, capacity: __local_size }

    while (__local_size != 0) {
        (__local_size = __local_size - 1)

        ((unsafe __local_out.data[__local_size]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn stc_word_stack_from_n(__param_raw: *const u64, __param_n: i64) -> stc_word_stack {
    var __local_out: stc_word_stack = stc_word_stack_with_capacity(__param_n)

    stc_word_stack_put_n((&raw mut __local_out as *mut stc_word_stack), __param_raw, __param_n)

    return __local_out

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_at(__param_self_: *const stc_word_stack, __param_idx: i64) -> *const u64 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_stack_at".ptr, c"stack.h".ptr, (189 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).data + ((__param_idx as i64) as usize)) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_stack_at_mut(__param_self_: *mut stc_word_stack, __param_idx: i64) -> *mut u64 {
    if (((if not ((if ((__param_idx as u64)) < (((*__param_self_).size as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_stack_at_mut".ptr, c"stack.h".ptr, (192 as i32), c"((size_t)(idx) < (size_t)(self->size))".ptr)
    } else {
        0
    }

    return ((*__param_self_).data + ((__param_idx as i64) as usize))

}

pub fn stc_word_stack_clone(__param_stk: stc_word_stack) -> stc_word_stack {
    var __local_out: stc_word_stack = __param_stk

    var __local_self_: *mut stc_word_stack = ((&raw mut __local_out as *mut stc_word_stack))



    (__local_out.data = ((null as *mut u64)))

    (__local_out.capacity = ((0 as i64)))

    (__local_out.size = (unsafe *(&raw const __local_out as *const stc_word_stack)).capacity)


    unsafe { (*(&raw mut __local_out as *mut stc_word_stack)).reserve((*(&raw const __param_stk as *const stc_word_stack)).size) }

    (__local_out.size = (unsafe *(&raw const __param_stk as *const stc_word_stack)).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (unsafe *(&raw const __param_stk as *const stc_word_stack)).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        ((unsafe __local_out.data[__local_i]) = (((unsafe (*(&raw const __param_stk as *const stc_word_stack)).data[__local_i]) as u64)))

        (__local_i = __local_i + 1)

    }


    return __local_out

}

// contract: receiver-mut:stc_word_stack,unproved:1:read only
pub unsafe fn stc_word_stack_copy(__param_self_: *mut stc_word_stack, __param_other: *const stc_word_stack) {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    (*__param_self_).clear()

    (*__param_self_).reserve((*__param_other).size)

    var __local_i: i64 = ((0 as i64))

    var __local__c_end_i: i64 = (*__param_other).size


    while ((if __local_i < __local__c_end_i: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (*__param_self_).size

        ((*__param_self_).size = (*__param_self_).size + 1)

        (((*__param_self_).data[__ci_expr_old_0]) = ((((*__param_other).data[__local_i]) as u64)))


        (__local_i = __local_i + 1)

    }


}

// contract: unproved:0:read only
pub unsafe fn stc_word_stack_value_toraw(__param_val: *const u64) -> u64 {
    return (*__param_val)

}

pub fn stc_word_stack_advance(__param_it_: stc_word_stack_iter, __param_n: u64) -> stc_word_stack_iter {
    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_word_stack_iter)).ref + (__param_n as usize))

    if ((if (unsafe *(&raw const __param_it_ as *const stc_word_stack_iter)).ref >= (unsafe *(&raw const __param_it_ as *const stc_word_stack_iter)).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut u64)))
    }


    return __param_it_

}

// contract: unproved:0:casts away const
pub unsafe fn stc_slot_queue_drop(__param_cself: *const stc_slot_queue) {
    var __local_self_: *mut stc_slot_queue = ((__param_cself as *mut stc_slot_queue))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    (*__local_self_).clear()

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))

}

// contract: receiver-mut:stc_slot_queue,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_queue_push(__param_self_: *mut stc_slot_queue, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_end: i64 = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_end == (*__param_self_).start: 1 else: 0) != 0) {
        if ((if not (*__param_self_).reserve((((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }

        (__local_end = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut *mut stc_slot_head = ((*__param_self_).cbuf + (((*__param_self_).end as i64) as usize))

    ((*__param_self_).end = __local_end)

    ((*__local_v) = __param_value)

    return __local_v

}

pub fn stc_slot_queue_advance(__param_it_: stc_slot_queue_iter, __param_n: i64) -> stc_slot_queue_iter {
    var __local_len: i64 = ((unsafe { (*((*(&raw const __param_it_ as *const stc_slot_queue_iter))._s)).size() } as i64))

    var __local_pos: i64 = (unsafe *(&raw const __param_it_ as *const stc_slot_queue_iter)).pos

    var __local_idx: i64 = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_slot_queue_iter))._s).start) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_queue_iter))._s).capmask as i64)) as i64))


    (__param_it_.pos = (((((__local_pos + __param_n) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_queue_iter))._s).capmask as i64)) as i64)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_slot_queue_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_slot_queue_iter)).pos - __local_pos) as i64) as usize))

    if ((if not ((if (((__local_idx + __param_n) as u64)) < ((__local_len as u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it_

}

// contract: receiver-mut:stc_slot_queue,unproved:1:read only
pub unsafe fn stc_slot_queue_put_n(__param_self_: *mut stc_slot_queue, __param_raw: *const *mut stc_slot_head, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_queue_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

// contract: receiver:stc_slot_queue,unproved:1:read only
pub unsafe fn stc_slot_queue_value_drop(__param_self_: *const stc_slot_queue, __param_val: *mut *mut stc_slot_head) {
    return
}

pub fn stc_slot_queue_init() -> stc_slot_queue {
    var __local_out: stc_slot_queue = stc_slot_queue.zeroed()

    return __local_out

}

pub fn stc_slot_queue_with_capacity(__param_cap: i64) -> stc_slot_queue {
    var __local_cap = __param_cap
    (__local_cap = ((c_next_pow2(((__local_cap + 1) as i64)) as i64)))

    var __local_out: stc_slot_queue = stc_slot_queue { cbuf: (((with_alloc((((if 1 != 0: ((__local_cap * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)), start: 0, end: 0, capmask: (__local_cap - 1) }

    return __local_out

}

pub fn stc_slot_queue_with_size_uninit(__param_size: i64) -> stc_slot_queue {
    var __local_out: stc_slot_queue = stc_slot_queue_with_capacity(__param_size)

    (__local_out.end = __param_size)

    return __local_out

}

// contract: stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_queue_with_size(__param_size: i64, __param_default_raw: *mut stc_slot_head) -> stc_slot_queue {
    var __local_out: stc_slot_queue = stc_slot_queue_with_capacity(__param_size)

    while ((if (*(&raw const __local_out as *const stc_slot_queue)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (*(&raw const __local_out as *const stc_slot_queue)).end

        (__local_out.end = (*(&raw const __local_out as *const stc_slot_queue)).end + 1)

        ((__local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_queue_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_queue {
    var __local_out: stc_slot_queue = stc_slot_queue_with_capacity(__param_n)

    stc_slot_queue_put_n((&raw mut __local_out as *mut stc_slot_queue), __param_raw, __param_n)

    return __local_out

}

// contract: unproved:0:returns a pointer loaded from the parameter
pub unsafe fn stc_slot_queue_value_toraw(__param_pval: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_pval)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_queue_front(__param_self_: *const stc_slot_queue) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_queue_front_mut(__param_self_: *mut stc_slot_queue) -> *mut *mut stc_slot_head {
    return ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_queue_back(__param_self_: *const stc_slot_queue) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_queue_back_mut(__param_self_: *mut stc_slot_queue) -> *mut *mut stc_slot_head {
    return ((stc_slot_queue_back((__param_self_ as *const stc_slot_queue)) as *mut *mut stc_slot_head))

}

// contract: unproved:0:casts away const
pub unsafe fn stc_word_queue_drop(__param_cself: *const stc_word_queue) {
    var __local_self_: *mut stc_word_queue = ((__param_cself as *mut stc_word_queue))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    (*__local_self_).clear()

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))

}

pub fn stc_word_queue_advance(__param_it_: stc_word_queue_iter, __param_n: i64) -> stc_word_queue_iter {
    var __local_len: i64 = ((unsafe { (*((*(&raw const __param_it_ as *const stc_word_queue_iter))._s)).size() } as i64))

    var __local_pos: i64 = (unsafe *(&raw const __param_it_ as *const stc_word_queue_iter)).pos

    var __local_idx: i64 = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_word_queue_iter))._s).start) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_queue_iter))._s).capmask as i64)) as i64))


    (__param_it_.pos = (((((__local_pos + __param_n) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_queue_iter))._s).capmask as i64)) as i64)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_word_queue_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_word_queue_iter)).pos - __local_pos) as i64) as usize))

    if ((if not ((if (((__local_idx + __param_n) as u64)) < ((__local_len as u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut u64)))
    }

    return __param_it_

}

// contract: receiver-mut:stc_word_queue,unproved:1:read only
pub unsafe fn stc_word_queue_put_n(__param_self_: *mut stc_word_queue, __param_raw: *const u64, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (*__param_self_).push((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

// contract: receiver:stc_word_queue,unproved:1:read only
pub unsafe fn stc_word_queue_value_drop(__param_self_: *const stc_word_queue, __param_val: *mut u64) {
    return
}

pub fn stc_word_queue_init() -> stc_word_queue {
    var __local_out: stc_word_queue = stc_word_queue.zeroed()

    return __local_out

}

pub fn stc_word_queue_with_capacity(__param_cap: i64) -> stc_word_queue {
    var __local_cap = __param_cap
    (__local_cap = ((c_next_pow2(((__local_cap + 1) as i64)) as i64)))

    var __local_out: stc_word_queue = stc_word_queue { cbuf: (((with_alloc((((if 1 != 0: ((__local_cap * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)), start: 0, end: 0, capmask: (__local_cap - 1) }

    return __local_out

}

pub fn stc_word_queue_with_size_uninit(__param_size: i64) -> stc_word_queue {
    var __local_out: stc_word_queue = stc_word_queue_with_capacity(__param_size)

    (__local_out.end = __param_size)

    return __local_out

}

pub fn stc_word_queue_with_size(__param_size: i64, __param_default_raw: u64) -> stc_word_queue {
    var __local_out: stc_word_queue = stc_word_queue_with_capacity(__param_size)

    while ((if (unsafe *(&raw const __local_out as *const stc_word_queue)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (unsafe *(&raw const __local_out as *const stc_word_queue)).end

        (__local_out.end = (unsafe *(&raw const __local_out as *const stc_word_queue)).end + 1)

        ((unsafe __local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

// contract: unproved:0:read only
pub unsafe fn stc_word_queue_from_n(__param_raw: *const u64, __param_n: i64) -> stc_word_queue {
    var __local_out: stc_word_queue = stc_word_queue_with_capacity(__param_n)

    stc_word_queue_put_n((&raw mut __local_out as *mut stc_word_queue), __param_raw, __param_n)

    return __local_out

}

pub fn stc_word_queue_clone(__param_q: stc_word_queue) -> stc_word_queue {
    var __local_out: stc_word_queue = __param_q

    var __local_self_: *mut stc_word_queue = ((&raw mut __local_out as *mut stc_word_queue))



    (__local_out.start = ((0 as i64)))

    (__local_out.end = ((unsafe { (*((&raw mut __param_q as *mut stc_word_queue) as *const stc_word_queue)).size() } as i64)))

    (__local_out.capmask = (((c_next_pow2((((unsafe *(&raw const __local_out as *const stc_word_queue)).end + 1) as i64)) - 1) as i64)))

    (__local_out.cbuf = (((with_alloc((((if 1 != 0: ((((unsafe *(&raw const __local_out as *const stc_word_queue)).capmask + 1) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

    var __local_i: i64 = ((0 as i64))

    if ((unsafe *(&raw const __local_out as *const stc_word_queue)).cbuf != null) {
        var __local_it_: stc_word_queue_iter = unsafe { (*((&raw mut __param_q as *mut stc_word_queue) as *const stc_word_queue)).begin() }

        while ((unsafe *(&raw const __local_it_ as *const stc_word_queue_iter)).ref != null) {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i + 1)

            ((unsafe __local_out.cbuf[__ci_expr_old_0]) = (unsafe *((*(&raw const __local_it_ as *const stc_word_queue_iter)).ref)))


            unsafe { (*(&raw mut __local_it_ as *mut stc_word_queue_iter)).next() }

        }

    }

    return __local_out

}

// contract: receiver-mut:stc_word_queue,unproved:1:read only
pub unsafe fn stc_word_queue_copy(__param_self_: *mut stc_word_queue, __param_other: *const stc_word_queue) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    stc_word_queue_drop((__param_self_ as *const stc_word_queue))

    let __ci_copy_18: stc_word_queue = stc_word_queue_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[stc_word_queue]())

}

// contract: unproved:0:read only
pub unsafe fn stc_word_queue_value_toraw(__param_pval: *const u64) -> u64 {
    return (*__param_pval)

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_queue_front(__param_self_: *const stc_word_queue) -> *const u64 {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_queue_front_mut(__param_self_: *mut stc_word_queue) -> *mut u64 {
    return ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_queue_back(__param_self_: *const stc_word_queue) -> *const u64 {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const u64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_queue_back_mut(__param_self_: *mut stc_word_queue) -> *mut u64 {
    return ((stc_word_queue_back((__param_self_ as *const stc_word_queue)) as *mut u64))

}

// contract: unproved:0:casts away const
pub unsafe fn stc_slot_list_drop(__param_cself: *const stc_slot_list) {
    var __local_self_: *mut stc_slot_list = ((__param_cself as *mut stc_slot_list))

    while ((*__local_self_).last != null) {
        stc_slot_list_erase_after_node(__local_self_, (*__local_self_).last)
    }

}

// contract: receiver-mut:stc_slot_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_push_back(__param_self_: *mut stc_slot_list, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_entry: *mut stc_slot_list_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[stc_slot_list_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_slot_list_node))

    ((*__local_entry).value = __param_value)

    if ((*__param_self_).last != null) {
        ((*__local_entry).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    ((*__param_self_).last = __local_entry)

    return (((&raw const (*__local_entry).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_push_front(__param_self_: *mut stc_slot_list, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_entry: *mut stc_slot_list_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[stc_slot_list_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_slot_list_node))

    ((*__local_entry).value = __param_value)

    if ((*__param_self_).last != null) {
        ((*__local_entry).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = __local_entry)
    }

    return (((&raw const (*__local_entry).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_list,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_insert_at(__param_self_: *mut stc_slot_list, __param_it_: stc_slot_list_iter, __param_value: *mut stc_slot_head) -> stc_slot_list_iter {
    var __local_node: *mut stc_slot_list_node = (if (*(&raw const __param_it_ as *const stc_slot_list_iter)).ref != null: (*(&raw const __param_it_ as *const stc_slot_list_iter)).prev else: (*__param_self_).last)

    var __local_entry: *mut stc_slot_list_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[stc_slot_list_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_slot_list_node))

    ((*__local_entry).value = __param_value)

    if (__local_node != null) {
        ((*__local_entry).next = (*__local_node).next)

        ((*__local_node).next = __local_entry)

    } else {
        ((*__local_entry).next = __local_entry)
    }

    var __ci_expr_logic_0: i32

    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if (*(&raw const __param_it_ as *const stc_slot_list_iter)).ref == null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        (__param_it_.prev = (if (*__param_self_).last != null: (*__param_self_).last else: __local_entry))

        ((*__param_self_).last = __local_entry)

    }


    (__param_it_.ref = (((&raw const (*__local_entry).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    return __param_it_

}

// contract: receiver-mut:stc_slot_list,unproved:2:out-parameter read before the write
pub unsafe fn stc_slot_list_splice(__param_self_: *mut stc_slot_list, __param_it_: stc_slot_list_iter, __param_other: *mut stc_slot_list) -> stc_slot_list_iter {
    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = (*__param_other).last)
    } else {
        if ((*__param_other).last != null) {
            var __local_p: *mut stc_slot_list_node = (if (*(&raw const __param_it_ as *const stc_slot_list_iter)).ref != null: (*(&raw const __param_it_ as *const stc_slot_list_iter)).prev else: (*__param_self_).last)

            var __local_next: *mut stc_slot_list_node = (*__local_p).next


            (__param_it_.prev = (*__param_other).last)

            ((*__local_p).next = (*(*(&raw const __param_it_ as *const stc_slot_list_iter)).prev).next)

            ((*(*(&raw const __param_it_ as *const stc_slot_list_iter)).prev).next = __local_next)

            if ((if (*(&raw const __param_it_ as *const stc_slot_list_iter)).ref == null: 1 else: 0) != 0) {
                ((*__param_self_).last = (*(&raw const __param_it_ as *const stc_slot_list_iter)).prev)
            }

        }
    }

    ((*__param_other).last = ((null as *mut stc_slot_list_node)))

    return __param_it_

}

// contract: receiver-mut:stc_slot_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_push_back_node(__param_self_: *mut stc_slot_list, __param_node: *mut stc_slot_list_node) -> *mut *mut stc_slot_head {
    if ((*__param_self_).last != null) {
        ((*__param_node).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    ((*__param_self_).last = __param_node)

    return (((&raw const (*__param_node).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_list,unproved:1:out-parameter read before the write,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_insert_after_node(__param_self_: *mut stc_slot_list, __param_ref: *mut stc_slot_list_node, __param_node: *mut stc_slot_list_node) -> *mut *mut stc_slot_head {
    if (__param_ref != null) {
        ((*__param_node).next = (*__param_ref).next)

        ((*__param_ref).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = __param_node)
    }

    return (((&raw const (*__param_node).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: receiver-mut:stc_slot_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_unlink_after_node(__param_self_: *mut stc_slot_list, __param_ref: *mut stc_slot_list_node) -> *mut stc_slot_list_node {
    var __local_node: *mut stc_slot_list_node = (*__param_ref).next

    var __local_next: *mut stc_slot_list_node = (*__local_node).next


    ((*__param_ref).next = __local_next)

    if ((if __local_node == __local_next: 1 else: 0) != 0) {
        ((*__param_self_).last = ((null as *mut stc_slot_list_node)))
    } else {
        if ((if __local_node == (*__param_self_).last: 1 else: 0) != 0) {
            ((*__param_self_).last = __param_ref)
        }
    }

    return __local_node

}

// contract: receiver-mut:stc_slot_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_erase_after_node(__param_self_: *mut stc_slot_list, __param_ref: *mut stc_slot_list_node) {
    var __local_node: *mut stc_slot_list_node = stc_slot_list_unlink_after_node(__param_self_, __param_ref)


    with_free(((__local_node as *mut c_void) as *mut u8))

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_list_get_node(__param_pval: *mut *mut stc_slot_head) -> *mut stc_slot_list_node {
    return (((if 1 != 0: __param_pval else: (null as *mut *mut stc_slot_head)) as *mut stc_slot_list_node))

}

// contract: receiver-mut:stc_slot_list,unproved:1:read only
pub unsafe fn stc_slot_list_put_n(__param_self_: *mut stc_slot_list, __param_raw: *const *mut stc_slot_head, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_list_push_back(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_slot_list_init() -> stc_slot_list {
    return ((stc_slot_list.zeroed() as stc_slot_list))

}

// contract: unproved:0:read only
pub unsafe fn stc_slot_list_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_list {
    var __local_cx: stc_slot_list = stc_slot_list.zeroed()

    stc_slot_list_put_n((&raw mut __local_cx as *mut stc_slot_list), __param_raw, __param_n)

    return __local_cx

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_slot_list_reserve(__param_self_: *mut stc_slot_list, __param_n: i64) -> bool {

    return ((true as bool))

}

// contract: unproved:0:stc_slot_list_drop may write through it
pub unsafe fn stc_slot_list_clear(__param_self_: *mut stc_slot_list) {
    stc_slot_list_drop((__param_self_ as *const stc_slot_list))

}

// contract: receiver-mut:stc_slot_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_slot_list_push(__param_self_: *mut stc_slot_list, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    return ((stc_slot_list_push_back(__param_self_, __param_value) as *mut *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_list_front(__param_self_: *const stc_slot_list) -> *const *mut stc_slot_head {
    return ((((&raw const (*(*(*__param_self_).last).next).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_list_front_mut(__param_self_: *mut stc_slot_list) -> *mut *mut stc_slot_head {
    return (((&raw const (*(*(*__param_self_).last).next).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_list_back(__param_self_: *const stc_slot_list) -> *const *mut stc_slot_head {
    return ((((&raw const (*(*__param_self_).last).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_slot_list_back_mut(__param_self_: *mut stc_slot_list) -> *mut *mut stc_slot_head {
    return (((&raw const (*(*__param_self_).last).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

// contract: unproved:0:returns a pointer loaded from the parameter
pub unsafe fn stc_slot_list_value_toraw(__param_pval: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_pval)

}

// contract: receiver:stc_slot_list,unproved:1:read only
pub unsafe fn stc_slot_list_value_drop(__param_self_: *const stc_slot_list, __param_pval: *mut *mut stc_slot_head) {
    return
}

pub fn stc_slot_list_advance(__param_it_: stc_slot_list_iter, __param_n: u64) -> stc_slot_list_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const stc_slot_list_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { (*(&raw mut __param_it_ as *mut stc_slot_list_iter)).next() }

    }

    return __param_it_

}

// contract: receiver-mut:stc_slot_list,unproved:2:out-parameter read before the write
pub unsafe fn stc_slot_list_splice_range(__param_self_: *mut stc_slot_list, __param_it_: stc_slot_list_iter, __param_other: *mut stc_slot_list, __param_it1: stc_slot_list_iter, __param_it2: stc_slot_list_iter) -> stc_slot_list_iter {
    var __local_tmp: stc_slot_list = (*__param_other).split_off(__param_it1, __param_it2)

    return stc_slot_list_splice(__param_self_, __param_it_, (&raw mut __local_tmp as *mut stc_slot_list))

}

unsafe fn stc_slot_list_insertsort_lowhigh(__param_self_: *mut stc_slot_list, __param_lo: i64, __param_hi: i64) {
    var __local_j: i64 = __param_lo

    var __local_i: i64 = (((__param_lo + 1) as i64))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: *mut stc_slot_head = (*((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[__local_i]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

        var __local_rx: *mut stc_slot_head = (*(&raw mut __local_x as *mut *mut stc_slot_head))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: *mut stc_slot_head = (*((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[__local_j]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

            if ((if not ((if (*(*(&raw mut __local_rx as *mut *mut stc_slot_head))).cmp.unwrap()(((*(&raw mut __local_rx as *mut *mut stc_slot_head)) as *const c_void), ((*(&raw mut __local_ry as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[(__local_j + 1)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) = (*((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[__local_j]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[(__local_j + 1)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

// contract: unproved:0:casts away const
pub unsafe fn stc_word_list_drop(__param_cself: *const stc_word_list) {
    var __local_self_: *mut stc_word_list = ((__param_cself as *mut stc_word_list))

    while ((*__local_self_).last != null) {
        stc_word_list_erase_after_node(__local_self_, (*__local_self_).last)
    }

}

// contract: receiver-mut:stc_word_list,unproved:2:out-parameter read before the write
pub unsafe fn stc_word_list_splice(__param_self_: *mut stc_word_list, __param_it_: stc_word_list_iter, __param_other: *mut stc_word_list) -> stc_word_list_iter {
    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = (*__param_other).last)
    } else {
        if ((*__param_other).last != null) {
            var __local_p: *mut stc_word_list_node = (if (*(&raw const __param_it_ as *const stc_word_list_iter)).ref != null: (*(&raw const __param_it_ as *const stc_word_list_iter)).prev else: (*__param_self_).last)

            var __local_next: *mut stc_word_list_node = (*__local_p).next


            (__param_it_.prev = (*__param_other).last)

            ((*__local_p).next = (*(*(&raw const __param_it_ as *const stc_word_list_iter)).prev).next)

            ((*(*(&raw const __param_it_ as *const stc_word_list_iter)).prev).next = __local_next)

            if ((if (*(&raw const __param_it_ as *const stc_word_list_iter)).ref == null: 1 else: 0) != 0) {
                ((*__param_self_).last = (*(&raw const __param_it_ as *const stc_word_list_iter)).prev)
            }

        }
    }

    ((*__param_other).last = ((null as *mut stc_word_list_node)))

    return __param_it_

}

// contract: receiver-mut:stc_word_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_word_list_push_back_node(__param_self_: *mut stc_word_list, __param_node: *mut stc_word_list_node) -> *mut i64 {
    if ((*__param_self_).last != null) {
        ((*__param_node).next = (*(*__param_self_).last).next)

        ((*(*__param_self_).last).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    ((*__param_self_).last = __param_node)

    return (((&raw const (*__param_node).value as *const i64) as *mut i64))

}

// contract: receiver-mut:stc_word_list,unproved:1:out-parameter read before the write,stored-unknown:2 — stores an argument; ownership not modeled
pub unsafe fn stc_word_list_insert_after_node(__param_self_: *mut stc_word_list, __param_ref: *mut stc_word_list_node, __param_node: *mut stc_word_list_node) -> *mut i64 {
    if (__param_ref != null) {
        ((*__param_node).next = (*__param_ref).next)

        ((*__param_ref).next = __param_node)

    } else {
        ((*__param_node).next = __param_node)
    }

    if ((if (*__param_self_).last == null: 1 else: 0) != 0) {
        ((*__param_self_).last = __param_node)
    }

    return (((&raw const (*__param_node).value as *const i64) as *mut i64))

}

// contract: receiver-mut:stc_word_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_word_list_unlink_after_node(__param_self_: *mut stc_word_list, __param_ref: *mut stc_word_list_node) -> *mut stc_word_list_node {
    var __local_node: *mut stc_word_list_node = (*__param_ref).next

    var __local_next: *mut stc_word_list_node = (*__local_node).next


    ((*__param_ref).next = __local_next)

    if ((if __local_node == __local_next: 1 else: 0) != 0) {
        ((*__param_self_).last = ((null as *mut stc_word_list_node)))
    } else {
        if ((if __local_node == (*__param_self_).last: 1 else: 0) != 0) {
            ((*__param_self_).last = __param_ref)
        }
    }

    return __local_node

}

// contract: receiver-mut:stc_word_list,stored-unknown:1 — stores an argument; ownership not modeled
pub unsafe fn stc_word_list_erase_after_node(__param_self_: *mut stc_word_list, __param_ref: *mut stc_word_list_node) {
    var __local_node: *mut stc_word_list_node = stc_word_list_unlink_after_node(__param_self_, __param_ref)


    with_free(((__local_node as *mut c_void) as *mut u8))

}

// contract: unproved:0:read only
pub unsafe fn stc_word_list_get_node(__param_pval: *mut i64) -> *mut stc_word_list_node {
    return (((if 1 != 0: __param_pval else: (null as *mut i64)) as *mut stc_word_list_node))

}

pub fn stc_word_list_clone(__param_lst: stc_word_list) -> stc_word_list {
    var __local_out: stc_word_list = __param_lst

    var __local_self_: *mut stc_word_list = ((&raw mut __local_out as *mut stc_word_list))



    (__local_out.last = ((null as *mut stc_word_list_node)))

    var __local_it_: stc_word_list_iter = unsafe { (*((&raw mut __param_lst as *mut stc_word_list) as *const stc_word_list)).begin() }

    while ((unsafe *(&raw const __local_it_ as *const stc_word_list_iter)).ref != null) {
        unsafe { (*(&raw mut __local_out as *mut stc_word_list)).push_back((*((*(&raw const __local_it_ as *const stc_word_list_iter)).ref))) }

        unsafe { (*(&raw mut __local_it_ as *mut stc_word_list_iter)).next() }

    }


    return __local_out

}

// contract: receiver-mut:stc_word_list,unproved:1:read only
pub unsafe fn stc_word_list_copy(__param_self_: *mut stc_word_list, __param_other: *const stc_word_list) -> Unit {
    if ((if (*__param_self_).last == (*__param_other).last: 1 else: 0) != 0) {
        return
    }

    stc_word_list_drop((__param_self_ as *const stc_word_list))

    let __ci_copy_20: stc_word_list = stc_word_list_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_20 as *const u8), sizeof[stc_word_list]())

}

// contract: receiver-mut:stc_word_list,unproved:1:read only
pub unsafe fn stc_word_list_put_n(__param_self_: *mut stc_word_list, __param_raw: *const i64, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (*__param_self_).push_back((*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub fn stc_word_list_init() -> stc_word_list {
    return ((stc_word_list.zeroed() as stc_word_list))

}

// contract: unproved:0:read only
pub unsafe fn stc_word_list_from_n(__param_raw: *const i64, __param_n: i64) -> stc_word_list {
    var __local_cx: stc_word_list = stc_word_list.zeroed()

    stc_word_list_put_n((&raw mut __local_cx as *mut stc_word_list), __param_raw, __param_n)

    return __local_cx

}

// contract: unproved:0:indexed as an array
pub unsafe fn stc_word_list_reserve(__param_self_: *mut stc_word_list, __param_n: i64) -> bool {

    return ((true as bool))

}

// contract: unproved:0:stc_word_list_drop may write through it
pub unsafe fn stc_word_list_clear(__param_self_: *mut stc_word_list) {
    stc_word_list_drop((__param_self_ as *const stc_word_list))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_list_front(__param_self_: *const stc_word_list) -> *const i64 {
    return ((((&raw const (*(*(*__param_self_).last).next).value as *const i64) as *mut i64) as *const i64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_list_front_mut(__param_self_: *mut stc_word_list) -> *mut i64 {
    return (((&raw const (*(*(*__param_self_).last).next).value as *const i64) as *mut i64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_list_back(__param_self_: *const stc_word_list) -> *const i64 {
    return ((((&raw const (*(*__param_self_).last).value as *const i64) as *mut i64) as *const i64))

}

// contract: unproved:0:returns a pointer the receiver's view cannot carry
pub unsafe fn stc_word_list_back_mut(__param_self_: *mut stc_word_list) -> *mut i64 {
    return (((&raw const (*(*__param_self_).last).value as *const i64) as *mut i64))

}

// contract: unproved:0:read only
pub unsafe fn stc_word_list_value_toraw(__param_pval: *const i64) -> i64 {
    return (*__param_pval)

}

// contract: receiver:stc_word_list,unproved:1:read only
pub unsafe fn stc_word_list_value_drop(__param_self_: *const stc_word_list, __param_pval: *mut i64) {
    return
}

pub fn stc_word_list_advance(__param_it_: stc_word_list_iter, __param_n: u64) -> stc_word_list_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: i32 = 0

        var __ci_expr_old_0: u64 = __local_n

        (__local_n = (__local_n -% 1))

        if (__ci_expr_old_0 != 0) {
            (__ci_expr_logic_1 = (if (unsafe *(&raw const __param_it_ as *const stc_word_list_iter)).ref != null: 1 else: 0))
        }

        if (not (__ci_expr_logic_1 != 0)) {
            break
        }

        unsafe { (*(&raw mut __param_it_ as *mut stc_word_list_iter)).next() }

    }

    return __param_it_

}

// contract: receiver-mut:stc_word_list,unproved:2:out-parameter read before the write
pub unsafe fn stc_word_list_splice_range(__param_self_: *mut stc_word_list, __param_it_: stc_word_list_iter, __param_other: *mut stc_word_list, __param_it1: stc_word_list_iter, __param_it2: stc_word_list_iter) -> stc_word_list_iter {
    var __local_tmp: stc_word_list = (*__param_other).split_off(__param_it1, __param_it2)

    return stc_word_list_splice(__param_self_, __param_it_, (&raw mut __local_tmp as *mut stc_word_list))

}

unsafe fn stc_word_list_insertsort_lowhigh(__param_self_: *mut stc_word_list, __param_lo: i64, __param_hi: i64) {
    var __local_j: i64 = __param_lo

    var __local_i: i64 = (((__param_lo + 1) as i64))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: i64 = (*((&raw const (((*__param_self_).last as *mut i64)[__local_i]) as *const i64) as *mut i64))

        var __local_rx: i64 = (*(&raw mut __local_x as *mut i64))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: i64 = (*((&raw const (((*__param_self_).last as *mut i64)[__local_j]) as *const i64) as *mut i64))

            if ((if not ((if (*(&raw mut __local_rx as *mut i64)) < (*(&raw mut __local_ry as *mut i64)): 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (((*__param_self_).last as *mut i64)[(__local_j + 1)]) as *const i64) as *mut i64)) = (*((&raw const (((*__param_self_).last as *mut i64)[__local_j]) as *const i64) as *mut i64)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (((*__param_self_).last as *mut i64)[(__local_j + 1)]) as *const i64) as *mut i64)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

pub fn c_popcount(__param_x: u64) -> i32 {
    return (__param_x as u64).popcount()

}

// contract: unproved:0:read only
pub unsafe fn _cbits_count(__param_set: *const u64, __param_sz: i64) -> i64 {
    var __local_n: i64 = (((__param_sz / (8 * (sizeof[u64]() as i64))) as i64))

    var __local_count: i64 = ((0 as i64))

    var __local_i: i64 = ((0 as i64))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        (__local_count = __local_count + c_popcount(((__param_set[__local_i]) as u64)))

        (__local_i = __local_i + 1)

    }


    if (((__param_sz as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) != 0) {
        (__local_count = __local_count + c_popcount(((((__param_set[__local_n]) as u64) & (((((1 as u64) << (((__param_sz as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64) -% (1 as u64)) as u64)) as u64)))
    }

    return __local_count

}

// contract: unproved:0:read only,ret-from:2
pub unsafe fn _cbits_to_str(__param_set: *const u64, __param_sz: i64, __param_out: *mut c_char, __param_start: i64, __param_stop: i64) -> *mut c_char {
    var __local_stop = __param_stop
    if ((if __local_stop > __param_sz: 1 else: 0) != 0) {
        (__local_stop = __param_sz)
    }

    if (((if not ((if __param_start <= __local_stop: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"_cbits_to_str".ptr, c"cbits.h".ptr, (115 as i32), c"start <= stop".ptr)
    } else {
        0
    }

    with_memset(((__param_out as *mut c_void) as *mut u8), (48 as i32), (((if 1 != 0: ((__local_stop - __param_start) as i64) else: (-1 as i64)) as u64) as i64))

    var __local_i: i64 = __param_start

    while ((if __local_i < __local_stop: 1 else: 0) != 0) {
        if ((if (((__param_set[(__local_i / (8 * (sizeof[u64]() as i64)))]) as u64) & (((1 as u64) << (((__local_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64)) != 0: 1 else: 0) != 0) {
            ((__param_out[(__local_i - __param_start)]) = ((49 as c_char)))
        }

        (__local_i = __local_i + 1)

    }


    ((__param_out[(__local_stop - __param_start)]) = ((0 as c_char)))

    return __param_out

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn _cbits_subset_of(__param_set: *const u64, __param_other: *const u64, __param_sz: i64) -> bool {
    var __local_n: i64 = (((__param_sz / (8 * (sizeof[u64]() as i64))) as i64))

    var __local_i: i64 = ((0 as i64))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        if ((if (((__param_set[__local_i]) as u64) | ((__param_other[__local_i]) as u64)) != (__param_set[__local_i]): 1 else: 0) != 0) {
            return ((false as bool))
        }

        (__local_i = __local_i + 1)

    }


    if ((if ((__param_sz as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) == 0: 1 else: 0) != 0) {
        return ((true as bool))
    }

    var __local_i_1: u64 = ((__local_n as u64))

    var __local_m: u64 = ((((((1 as u64) << (((__param_sz as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64) -% (1 as u64)) as u64))


    return (((((((((__param_set[__local_i_1]) as u64) | ((__param_other[__local_i_1]) as u64)) as u64) & (__local_m as u64)) == (((__param_set[__local_i_1]) as u64) & (__local_m as u64)))) as bool))

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn _cbits_disjoint(__param_set: *const u64, __param_other: *const u64, __param_sz: i64) -> bool {
    var __local_n: i64 = (((__param_sz / (8 * (sizeof[u64]() as i64))) as i64))

    var __local_i: i64 = ((0 as i64))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        if ((if (((__param_set[__local_i]) as u64) & ((__param_other[__local_i]) as u64)) != 0: 1 else: 0) != 0) {
            return ((false as bool))
        }

        (__local_i = __local_i + 1)

    }


    if ((if ((__param_sz as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) == 0: 1 else: 0) != 0) {
        return ((true as bool))
    }

    var __local_i_1: u64 = ((__local_n as u64))

    var __local_m: u64 = ((((((1 as u64) << (((__param_sz as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64) -% (1 as u64)) as u64))


    return (((((((((__param_set[__local_i_1]) as u64) & ((__param_other[__local_i_1]) as u64)) as u64) & (__local_m as u64)) == ((0 as u64) & (__local_m as u64)))) as bool))

}

// contract: unproved:0:frees a part of it
pub unsafe fn cbits_drop(__param_self_: *mut cbits) {
    with_free((((*__param_self_).buffer as *mut c_void) as *mut u8))

}

pub fn cbits_clone(__param_other: cbits) -> cbits {
    var __local_set: cbits = __param_other

    var __local_bytes: i64 = ((((((unsafe *(&raw const __param_other as *const cbits))._size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64))

    (__local_set.buffer = ((unsafe { c_safe_memcpy((with_alloc((((if 1 != 0: __local_bytes else: (-1 as i64)) as u64) as i64)) as *mut c_void), ((*(&raw const __param_other as *const cbits)).buffer as *const c_void), __local_bytes) } as *mut u64)))

    return __local_set

}

// contract: receiver-mut:cbits,unproved:1:read only
pub unsafe fn cbits_copy(__param_self_: *mut cbits, __param_other: *const cbits) -> *mut cbits {
    if ((if (*__param_self_).buffer == (*__param_other).buffer: 1 else: 0) != 0) {
        return __param_self_
    }

    if ((if (*__param_self_)._size != (*__param_other)._size: 1 else: 0) != 0) {
        return ((((*__param_self_).take(cbits_clone((*__param_other))) as *const cbits) as *mut cbits))
    }

    with_memcpy((((*__param_self_).buffer as *mut c_void) as *mut u8), (((*__param_other).buffer as *const c_void) as *const u8), (((if 1 != 0: (((((*__param_other)._size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

    return __param_self_

}

// contract: unproved:0:memset is outside the corpus and not a known pure reader
pub unsafe fn cbits_set_all(__param_self_: *mut cbits, __param_value: bool) -> Unit {
    with_memset((((*__param_self_).buffer as *mut c_void) as *mut u8), ((0 - (__param_value as i32)) as i32), (((if 1 != 0: (((((*(__param_self_ as *const cbits)).size() + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

}

pub fn cbits_with_size(__param_size: i64, __param_value: bool) -> cbits {
    var __local_set: cbits = cbits { buffer: ((with_alloc((((if 1 != 0: ((((__param_size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64), _size: __param_size }

    unsafe { cbits_set_all((&raw mut __local_set as *mut cbits), __param_value) }

    return __local_set

}

pub fn cbits_with_pattern(__param_size: i64, __param_pattern: u64) -> cbits {
    var __local_set: cbits = cbits { buffer: ((with_alloc((((if 1 != 0: ((((__param_size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64), _size: __param_size }

    unsafe { (*(&raw mut __local_set as *mut cbits)).set_pattern(__param_pattern) }

    return __local_set

}

// contract: unproved:0:read only
pub unsafe fn cbits_from(__param_str: *const c_char) -> cbits {
    var __local_n: i64 = ((strlen(__param_str) as i64))

    var __local_set: cbits = cbits_with_size(__local_n, (false as bool))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        if ((if (__param_str[__local_n]) == 49: 1 else: 0) != 0) {
            (*(&raw mut __local_set as *mut cbits)).set(__local_n)
        }

    }

    return __local_set

}

// contract: receiver-mut:cbits,unproved:1:read only
pub unsafe fn cbits_intersect(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_intersect".ptr, c"cbits.h".ptr, (298 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: i64 = (((((*(__param_self_ as *const cbits)).size() + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as u64) & (((*__param_other).buffer[__local_n]) as u64))

    }

}

// contract: receiver-mut:cbits,unproved:1:read only
pub unsafe fn cbits_union(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_union".ptr, c"cbits.h".ptr, (304 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: i64 = (((((*(__param_self_ as *const cbits)).size() + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as u64) | (((*__param_other).buffer[__local_n]) as u64))

    }

}

// contract: receiver-mut:cbits,unproved:1:read only
pub unsafe fn cbits_xor(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_xor".ptr, c"cbits.h".ptr, (310 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: i64 = (((((*(__param_self_ as *const cbits)).size() + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as u64) ^ (((*__param_other).buffer[__local_n]) as u64))

    }

}

// contract: unproved:0:_cbits_count may write through it
pub unsafe fn cbits_count(__param_self_: *const cbits) -> i64 {
    return _cbits_count(((*__param_self_).buffer as *const u64), ((*__param_self_).size() as i64))

}

// contract: unproved:0:_cbits_to_str may write through it,unproved:1:out-parameter written conditionally
pub unsafe fn cbits_to_str(__param_self_: *const cbits, __param_out: *mut c_char, __param_start: i64, __param_stop: i64) -> *mut c_char {
    return ((_cbits_to_str(((*__param_self_).buffer as *const u64), ((*__param_self_).size() as i64), __param_out, __param_start, __param_stop) as *mut c_char))

}

// contract: unproved:0:_cbits_subset_of may write through it,unproved:1:read only
pub unsafe fn cbits_subset_of(__param_self_: *const cbits, __param_other: *const cbits) -> bool {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_subset_of".ptr, c"cbits.h".ptr, (322 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    return _cbits_subset_of(((*__param_self_).buffer as *const u64), ((*__param_other).buffer as *const u64), ((*__param_self_).size() as i64))

}

// contract: unproved:0:_cbits_disjoint may write through it,unproved:1:read only
pub unsafe fn cbits_disjoint(__param_self_: *const cbits, __param_other: *const cbits) -> bool {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_disjoint".ptr, c"cbits.h".ptr, (327 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    return _cbits_disjoint(((*__param_self_).buffer as *const u64), ((*__param_other).buffer as *const u64), ((*__param_self_).size() as i64))

}

impl cbits {
    pub fn size() -> i64 {
        let __param_self_: *const cbits = self as *const cbits
        return (unsafe *__param_self_)._size

    }

    pub mut fn take(__param_other: cbits) -> &cbits from self {
        let __param_self_: *mut cbits = self as *mut cbits
        if ((if (unsafe *__param_self_).buffer != (unsafe *(&raw const __param_other as *const cbits)).buffer: 1 else: 0) != 0) {
            unsafe { cbits_drop(__param_self_) }

            with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_other as *const u8), sizeof[cbits]())

        }

        return unsafe { &*(__param_self_) }

    }

    pub mut fn resize(__param_size: i64, __param_value: bool) -> bool {
        let __param_self_: *mut cbits = self as *mut cbits
        var __local_new_w: i64 = ((((__param_size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

        var __local_osize: i64 = (unsafe *__param_self_)._size

        var __local_old_w: i64 = ((((__local_osize + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))


        var __local_b: *mut u64 = (((with_realloc((((unsafe *__param_self_).buffer as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_new_w * (sizeof[u64]() as i64)) as i64) else: ((__local_old_w * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64))

        if ((if __local_b == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        ((unsafe *__param_self_).buffer = __local_b)

        ((unsafe *__param_self_)._size = __param_size)

        if ((if __param_size > __local_osize: 1 else: 0) != 0) {
            with_memset(((((unsafe *__param_self_).buffer + ((__local_old_w as i64) as usize)) as *mut c_void) as *mut u8), ((0 - (__param_value as i32)) as i32), (((if 1 != 0: (((__local_new_w - __local_old_w) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            if (((__local_osize as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) != 0) {
                var __local_mask: u64 = ((((((1 as u64) << (((__local_osize as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64) -% (1 as u64)) as u64))

                if __param_value {
                    ((unsafe (*__param_self_).buffer[(__local_old_w - 1)]) = ((unsafe (*__param_self_).buffer[(__local_old_w - 1)]) as u64) | ((~__local_mask) as u64))
                } else {
                    ((unsafe (*__param_self_).buffer[(__local_old_w - 1)]) = ((unsafe (*__param_self_).buffer[(__local_old_w - 1)]) as u64) & (__local_mask as u64))
                }

            }

        }

        return ((true as bool))

    }

    pub mut fn set_pattern(__param_pattern: u64) {
        let __param_self_: *mut cbits = self as *mut cbits
        var __local_n: i64 = ((((unsafe { (*(__param_self_ as *const cbits)).size() } + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

        while true {
            var __ci_expr_old_0: i64 = __local_n

            (__local_n = __local_n - 1)

            if (not (__ci_expr_old_0 != 0)) {
                break
            }

            ((unsafe (*__param_self_).buffer[__local_n]) = __param_pattern)

        }

    }

    pub mut fn move_() -> cbits {
        let __param_self_: *mut cbits = self as *mut cbits
        var __local_tmp: cbits = (unsafe *__param_self_)

        ((unsafe *__param_self_).buffer = ((null as *mut u64)))

        ((unsafe *__param_self_)._size = ((0 as i64)))


        return __local_tmp

    }

    pub fn test(__param_i: i64) -> bool {
        let __param_self_: *const cbits = self as *const cbits
        return (((((((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) & (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64)) != 0)) as bool))

    }

    pub fn at(__param_i: i64) -> bool {
        let __param_self_: *const cbits = self as *const cbits
        if (((if not ((if ((__param_i as u64)) < ((unsafe { (*__param_self_).size() } as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"cbits_at".ptr, c"cbits.h".ptr, (269 as i32), c"((size_t)(i) < (size_t)(cbits_size(self)))".ptr)
        } else {
            0
        }

        return unsafe { (*__param_self_).test(__param_i) }

    }

    pub mut fn set(__param_i: i64) {
        let __param_self_: *mut cbits = self as *mut cbits
        ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) | (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64))

    }

    pub mut fn reset(__param_i: i64) {
        let __param_self_: *mut cbits = self as *mut cbits
        ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) & ((~((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32))) as u64))

    }

    pub mut fn set_value(__param_i: i64, __param_b: bool) {
        let __param_self_: *mut cbits = self as *mut cbits
        ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) ^ ((((((0 - (__param_b as i32)) as u64) ^ ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64)) as u64) & (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64)) as u64))

    }

    pub mut fn flip(__param_i: i64) {
        let __param_self_: *mut cbits = self as *mut cbits
        ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = ((unsafe (*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) ^ (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64))

    }

    pub mut fn flip_all() {
        let __param_self_: *mut cbits = self as *mut cbits
        var __local_n: i64 = ((((unsafe { (*(__param_self_ as *const cbits)).size() } + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

        while true {
            var __ci_expr_old_0: i64 = __local_n

            (__local_n = __local_n - 1)

            if (not (__ci_expr_old_0 != 0)) {
                break
            }

            ((unsafe (*__param_self_).buffer[__local_n]) = ((unsafe (*__param_self_).buffer[__local_n]) as u64) ^ ((~(0 as u64)) as u64))

        }

    }

}

impl stc_slot_deque {
    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        var __local_oldpow2: i64 = ((((unsafe *__param_self_).capmask + (((unsafe *__param_self_).capmask as i64) & (1 as i64))) as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__param_cap + 1) as i64)) as i64))

        if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
            return (((((unsafe *__param_self_).cbuf != null)) as bool))
        }

        var __local_d: *mut *mut stc_slot_head = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as i64)) as i64) else: ((__local_oldpow2 * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        var __local_head: i64 = (((__local_oldpow2 - (unsafe *__param_self_).start) as i64))

        if (not ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0)) {
            if ((if __local_head < (unsafe *__param_self_).end: 1 else: 0) != 0) {
                with_memcpy(((((__local_d + ((__local_newpow2 as i64) as usize)) - ((__local_head as i64) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).start = (((__local_newpow2 - __local_head) as i64)))

            } else {
                with_memcpy((((__local_d + ((__local_oldpow2 as i64) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((unsafe *__param_self_).end * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).end = (unsafe *__param_self_).end + __local_oldpow2)

            }
        }

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

        ((unsafe *__param_self_).cbuf = __local_d)

        return ((true as bool))

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        var __local_i: stc_slot_deque_iter = unsafe { (*(((&raw const (*__param_self_) as *const stc_slot_deque) as *mut stc_slot_deque) as *const stc_slot_deque)).begin() }

        while ((unsafe *(&raw const __local_i as *const stc_slot_deque_iter)).ref != null) {


            unsafe { (*(&raw mut __local_i as *mut stc_slot_deque_iter)).next() }

        }


        ((unsafe *__param_self_).start = ((0 as i64)))

        ((unsafe *__param_self_).end = ((0 as i64)))


    }

    pub mut fn shrink_to_fit() {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        var __local_sz: i64 = ((unsafe { (*(__param_self_ as *const stc_slot_deque)).size() } as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__local_sz + 1) as i64)) as i64))

        if ((if __local_newpow2 > (unsafe *__param_self_).capmask: 1 else: 0) != 0) {
            return
        }

        if ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0) {
            with_memmove((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = ((0 as i64)))

            ((unsafe *__param_self_).end = __local_sz)


        } else {
            var __local_n: i64 = (((((unsafe *__param_self_).capmask - (unsafe *__param_self_).start) + 1) as i64))

            with_memmove(((((unsafe *__param_self_).cbuf + (((__local_newpow2 - __local_n) as i64) as usize)) as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = (((__local_newpow2 - __local_n) as i64)))

        }

        ((unsafe *__param_self_).cbuf = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as i64)) as i64) else: ((((unsafe *__param_self_).capmask + 1) * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

    }

    pub fn size() -> i64 {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque
        return ((((unsafe *__param_self_).end - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque
        return (unsafe *__param_self_).capmask

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque
        return (((((unsafe *__param_self_).start == (unsafe *__param_self_).end)) as bool))

    }

    pub mut fn move_() -> stc_slot_deque {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        var __local_m: stc_slot_deque = (unsafe *__param_self_)

        ((unsafe *__param_self_).end = ((0 as i64)))

        ((unsafe *__param_self_).start = (unsafe *__param_self_).end)

        ((unsafe *__param_self_).capmask = (unsafe *__param_self_).start)


        ((unsafe *__param_self_).cbuf = ((null as *mut *mut stc_slot_head)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_slot_deque) -> Unit {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        unsafe { stc_slot_deque_drop((__param_self_ as *const stc_slot_deque)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_deque]())

    }

    pub mut fn pop_front() {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_slot_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_deque_pop_front".ptr, c"queue_prv.h".ptr, (133 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
        } else {
            0
        }


        ((unsafe *__param_self_).start = ((((((unsafe *__param_self_).start + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn pull_front() -> *mut stc_slot_head {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_slot_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_deque_pull_front".ptr, c"queue_prv.h".ptr, (139 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
        } else {
            0
        }

        var __local_s: i64 = (unsafe *__param_self_).start

        ((unsafe *__param_self_).start = (((((__local_s + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (((unsafe (*__param_self_).cbuf[__local_s]) as *mut stc_slot_head))

    }

    pub fn begin() -> stc_slot_deque_iter {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque
        return ((stc_slot_deque_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut *mut stc_slot_head) else: ((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize))), pos: (unsafe *__param_self_).start, _s: __param_self_ } as stc_slot_deque_iter))

    }

    pub fn rbegin() -> stc_slot_deque_iter {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque
        var __local_pos: i64 = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        return ((stc_slot_deque_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut *mut stc_slot_head) else: ((unsafe *__param_self_).cbuf + ((__local_pos as i64) as usize))), pos: __local_pos, _s: __param_self_ } as stc_slot_deque_iter))

    }

    pub fn end() -> stc_slot_deque_iter {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque

        return ((stc_slot_deque_iter.zeroed() as stc_slot_deque_iter))

    }

    pub fn rend() -> stc_slot_deque_iter {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque

        return ((stc_slot_deque_iter.zeroed() as stc_slot_deque_iter))

    }

    pub fn index(__param_it_: stc_slot_deque_iter) -> i64 {
        let __param_self_: *const stc_slot_deque = self as *const stc_slot_deque
        return ((((unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end + __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn insert_uninit(__param_idx: i64, __param_n: i64) -> stc_slot_deque_iter {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        var __local_len: i64 = ((unsafe { (*(__param_self_ as *const stc_slot_deque)).size() } as i64))

        var __local_it_: stc_slot_deque_iter = stc_slot_deque_iter { _s: (__param_self_ as *const stc_slot_deque) }

        if ((if (__local_len + __param_n) >= (unsafe *__param_self_).capmask: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve(((__local_len + __param_n) as i64)) }: 1 else: 0) != 0) {
                return __local_it_
            }
        }

        (__local_it_.pos = ((((((unsafe *__param_self_).start + __param_idx) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        (__local_it_.ref = (unsafe *__param_self_).cbuf + (((unsafe *(&raw const __local_it_ as *const stc_slot_deque_iter)).pos as i64) as usize))

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end + __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        if ((if (unsafe *(&raw const __local_it_ as *const stc_slot_deque_iter)).pos < (unsafe *__param_self_).end: 1 else: 0) != 0) {
            with_memmove(((((unsafe *(&raw const __local_it_ as *const stc_slot_deque_iter)).ref + ((__param_n as i64) as usize)) as *mut c_void) as *mut u8), (((unsafe *(&raw const __local_it_ as *const stc_slot_deque_iter)).ref as *const c_void) as *const u8), (((if 1 != 0: (((__local_len - __param_idx) * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))
        } else {
            var __local_i: i64 = (((__local_len - 1) as i64))

            var __local_j: i64 = (((__local_i + __param_n) as i64))


            while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
                ((unsafe *unsafe { stc_slot_deque_at_mut(__param_self_, __local_j) }) = (unsafe *unsafe { stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __local_i) }))

                (__local_i = __local_i - 1)

                (__local_j = __local_j - 1)


            }

        }

        return __local_it_

    }

    pub mut fn erase_n(__param_idx: i64, __param_n: i64) {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        var __local_len: i64 = ((unsafe { (*(__param_self_ as *const stc_slot_deque)).size() } as i64))

        if (((if not ((if (__param_idx + __param_n) <= __local_len: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_deque_erase_n".ptr, c"deque.h".ptr, (149 as i32), c"idx + n <= len".ptr)
        } else {
            0
        }

        var __local_i: i64 = ((((__param_idx + __param_n) - 1) as i64))

        while ((if __local_i >= __param_idx: 1 else: 0) != 0) {

            (__local_i = __local_i - 1)

        }


        var __local_i_1: i64 = __param_idx

        var __local_j: i64 = (((__local_i_1 + __param_n) as i64))


        while ((if __local_j < __local_len: 1 else: 0) != 0) {
            ((unsafe *unsafe { stc_slot_deque_at_mut(__param_self_, __local_i_1) }) = (unsafe *unsafe { stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __local_j) }))

            (__local_i_1 = __local_i_1 + 1)

            (__local_j = __local_j + 1)


        }


        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn pop_back() {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_slot_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_deque_pop_back".ptr, c"deque.h".ptr, (67 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))


    }

    pub mut fn pull_back() -> *mut stc_slot_head {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_slot_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_deque_pull_back".ptr, c"deque.h".ptr, (73 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (((unsafe (*__param_self_).cbuf[(*__param_self_).end]) as *mut stc_slot_head))

    }

    pub mut fn erase_at(__param_it_: stc_slot_deque_iter) -> stc_slot_deque_iter {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        unsafe { (*__param_self_).erase_n((((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64), (1 as i64)) }

        if ((if (unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos == (unsafe *__param_self_).end: 1 else: 0) != 0) {
            (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
        }

        return __param_it_

    }

    pub mut fn erase_range(__param_it1: stc_slot_deque_iter, __param_it2: stc_slot_deque_iter) -> stc_slot_deque_iter {
        let __param_self_: *mut stc_slot_deque = self as *mut stc_slot_deque
        var __local_idx1: i64 = ((((((unsafe *(&raw const __param_it1 as *const stc_slot_deque_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        var __local_idx2: i64 = ((((((unsafe *(&raw const __param_it2 as *const stc_slot_deque_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        unsafe { (*__param_self_).erase_n(__local_idx1, ((__local_idx2 - __local_idx1) as i64)) }

        if ((if (unsafe *(&raw const __param_it1 as *const stc_slot_deque_iter)).pos == (unsafe *__param_self_).end: 1 else: 0) != 0) {
            (__param_it1.ref = ((null as *mut *mut stc_slot_head)))
        }

        return __param_it1

    }

}

impl stc_slot_deque_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_slot_deque_iter = self as *mut stc_slot_deque_iter
        if ((if (unsafe *__param_it_).pos != (unsafe *(*__param_it_)._s).capmask: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

            ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos + 1)

        } else {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - (((unsafe *__param_it_).pos as i64) as usize))

            ((unsafe *__param_it_).pos = ((0 as i64)))

        }

        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        }

    }

    pub mut fn rnext() -> Unit {
        let __param_it_: *mut stc_slot_deque_iter = self as *mut stc_slot_deque_iter
        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).start: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        } else {
            if ((if (unsafe *__param_it_).pos != 0: 1 else: 0) != 0) {
                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

                ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos - 1)

            } else {
                ((unsafe *__param_it_).pos = (unsafe *(*__param_it_)._s).capmask)

                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + (((unsafe *__param_it_).pos as i64) as usize))

            }
        }

    }

}

impl stc_slot_list {
    pub mut fn erase_at(__param_it_: stc_slot_list_iter) -> stc_slot_list_iter {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        var __local_node: *mut stc_slot_list_node = (((if 1 != 0: (unsafe *(&raw const __param_it_ as *const stc_slot_list_iter)).ref else: (null as *mut *mut stc_slot_head)) as *mut stc_slot_list_node))

        (__param_it_.ref = (if (if __local_node == (unsafe *__param_self_).last: 1 else: 0) != 0: (null as *mut *mut stc_slot_head) else: ((&raw const (unsafe *(*__local_node).next).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

        unsafe { stc_slot_list_erase_after_node(__param_self_, (*(&raw const __param_it_ as *const stc_slot_list_iter)).prev) }

        return __param_it_

    }

    pub mut fn erase_range(__param_it1: stc_slot_list_iter, __param_it2: stc_slot_list_iter) -> stc_slot_list_iter {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        var __local_end: *mut stc_slot_list_node = (if (unsafe *(&raw const __param_it2 as *const stc_slot_list_iter)).ref != null: ((if 1 != 0: (unsafe *(&raw const __param_it2 as *const stc_slot_list_iter)).ref else: (null as *mut *mut stc_slot_head)) as *mut stc_slot_list_node) else: (unsafe *(*__param_self_).last).next)

        if ((if (unsafe *(&raw const __param_it1 as *const stc_slot_list_iter)).ref != (unsafe *(&raw const __param_it2 as *const stc_slot_list_iter)).ref: 1 else: 0) != 0) {
            loop {
                unsafe { stc_slot_list_erase_after_node(__param_self_, (*(&raw const __param_it1 as *const stc_slot_list_iter)).prev) }

                if ((if (unsafe *__param_self_).last == null: 1 else: 0) != 0) {
                    break
                }

                if not (((if (unsafe *(*(&raw const __param_it1 as *const stc_slot_list_iter)).prev).next != __local_end: 1 else: 0) != 0)) {
                    break
                }
            }
        }

        return __param_it2

    }

    pub mut fn sort() -> bool {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        var __local_len__goto_410_13: i64 = 0

        var __local_cap__goto_410_22: i64 = 0

        var __local_arr__goto_411_15: *mut *mut stc_slot_head = null

        var __local_p__goto_411_28: *mut *mut stc_slot_head = null

        var __local_keep__goto_412_14: *mut stc_slot_list_node = null

        var __local_i__goto_413_10: stc_slot_list_iter = stc_slot_list_iter.zeroed()

        var __local_cap_n__goto_415_21: i64 = 0

        var __local_i__goto_426_10: stc_slot_list_iter = stc_slot_list_iter.zeroed()

        var __ci_expr_old_0: i64 = 0

        var __ci_expr_old_1: *mut *mut stc_slot_head = null

        goto '__ci_bb_0

        '__ci_bb_0 {
            (__local_len__goto_410_13 = ((0 as i64)))
            (__local_cap__goto_410_22 = ((0 as i64)))
            (__local_arr__goto_411_15 = ((null as *mut *mut stc_slot_head)))
            (__local_p__goto_411_28 = ((null as *mut *mut stc_slot_head)))
            (__local_i__goto_413_10 = unsafe { (*(((&raw const (*__param_self_) as *const stc_slot_list) as *mut stc_slot_list) as *const stc_slot_list)).begin() })
            goto '__ci_bb_1
        }

        '__ci_bb_1 {
            if ((unsafe *(&raw const __local_i__goto_413_10 as *const stc_slot_list_iter)).ref != null) {
                goto '__ci_bb_2
            } else {
                goto '__ci_bb_4
            }
        }

        '__ci_bb_2 {
            if ((if __local_len__goto_410_13 == __local_cap__goto_410_22: 1 else: 0) != 0) {
                goto '__ci_bb_5
            } else {
                goto '__ci_bb_6
            }
        }

        '__ci_bb_3 {
            unsafe { (*(&raw mut __local_i__goto_413_10 as *mut stc_slot_list_iter)).next() }
            goto '__ci_bb_1
        }

        '__ci_bb_4 {
            (__local_keep__goto_412_14 = (unsafe *__param_self_).last)
            ((unsafe *__param_self_).last = ((__local_arr__goto_411_15 as *mut stc_slot_list_node)))
            unsafe { (*__param_self_).sort_lowhigh((0 as i64), ((__local_len__goto_410_13 - 1) as i64)) }
            ((unsafe *__param_self_).last = __local_keep__goto_412_14)
            (__local_i__goto_426_10 = unsafe { (*(((&raw const (*__param_self_) as *const stc_slot_list) as *mut stc_slot_list) as *const stc_slot_list)).begin() })
            goto '__ci_bb_10
        }

        '__ci_bb_5 {
            (__local_cap_n__goto_415_21 = ((((__local_cap__goto_410_22 + (__local_cap__goto_410_22 / 2)) + 8) as i64)))
            (__local_p__goto_411_28 = (((with_realloc(((__local_arr__goto_411_15 as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_cap_n__goto_415_21 * (sizeof[usize]() as i64)) as i64) else: ((__local_cap__goto_410_22 * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))
            if ((if __local_p__goto_411_28 == null: 1 else: 0) != 0) {
                goto '__ci_bb_7
            } else {
                goto '__ci_bb_8
            }
        }

        '__ci_bb_6 {
            (__ci_expr_old_0 = __local_len__goto_410_13)
            (__local_len__goto_410_13 = __local_len__goto_410_13 + 1)
            ((unsafe __local_arr__goto_411_15[__ci_expr_old_0]) = (unsafe *((*(&raw const __local_i__goto_413_10 as *const stc_slot_list_iter)).ref)))
            goto '__ci_bb_3
        }

        '__ci_bb_7 {
            goto '__ci_bb_9
        }

        '__ci_bb_8 {
            (__local_arr__goto_411_15 = __local_p__goto_411_28)
            (__local_cap__goto_410_22 = __local_cap_n__goto_415_21)
            goto '__ci_bb_6
        }

        '__ci_bb_9 {
            with_free(((__local_arr__goto_411_15 as *mut c_void) as *mut u8))
            return ((__local_p__goto_411_28 != null))
        }

        '__ci_bb_10 {
            if ((unsafe *(&raw const __local_i__goto_426_10 as *const stc_slot_list_iter)).ref != null) {
                goto '__ci_bb_11
            } else {
                goto '__ci_bb_13
            }
        }

        '__ci_bb_11 {
            (__ci_expr_old_1 = __local_p__goto_411_28)
            (__local_p__goto_411_28 = __local_p__goto_411_28 + 1)
            ((unsafe *((*(&raw const __local_i__goto_426_10 as *const stc_slot_list_iter)).ref)) = (unsafe *__ci_expr_old_1))
            goto '__ci_bb_12
        }

        '__ci_bb_12 {
            unsafe { (*(&raw mut __local_i__goto_426_10 as *mut stc_slot_list_iter)).next() }
            goto '__ci_bb_10
        }

        '__ci_bb_13 {
            goto '__ci_bb_9
        }

        __ci_unreachable()

    }

    pub mut fn reverse() -> Unit {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        var __local_rev: stc_slot_list = (unsafe *__param_self_)

        (__local_rev.last = ((null as *mut stc_slot_list_node)))

        while ((unsafe *__param_self_).last != null) {
            var __local_node: *mut stc_slot_list_node = unsafe { stc_slot_list_unlink_after_node(__param_self_, (*__param_self_).last) }

            unsafe { stc_slot_list_insert_after_node((&raw mut __local_rev as *mut stc_slot_list), (*(&raw const __local_rev as *const stc_slot_list)).last, __local_node) }

        }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __local_rev as *const u8), sizeof[stc_slot_list]())

    }

    pub mut fn split_off(__param_it1: stc_slot_list_iter, __param_it2: stc_slot_list_iter) -> stc_slot_list {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        var __local_lst: stc_slot_list = (unsafe *__param_self_)

        (__local_lst.last = ((null as *mut stc_slot_list_node)))

        if ((if (unsafe *(&raw const __param_it1 as *const stc_slot_list_iter)).ref == (unsafe *(&raw const __param_it2 as *const stc_slot_list_iter)).ref: 1 else: 0) != 0) {
            return __local_lst
        }

        var __local_p1: *mut stc_slot_list_node = (unsafe *(&raw const __param_it1 as *const stc_slot_list_iter)).prev

        var __local_p2: *mut stc_slot_list_node = (if (unsafe *(&raw const __param_it2 as *const stc_slot_list_iter)).ref != null: (unsafe *(&raw const __param_it2 as *const stc_slot_list_iter)).prev else: (unsafe *__param_self_).last)


        ((unsafe *__local_p1).next = (unsafe *__local_p2).next)

        ((unsafe *__local_p2).next = (((if 1 != 0: (unsafe *(&raw const __param_it1 as *const stc_slot_list_iter)).ref else: (null as *mut *mut stc_slot_head)) as *mut stc_slot_list_node)))

        if ((if (unsafe *__param_self_).last == __local_p2: 1 else: 0) != 0) {
            ((unsafe *__param_self_).last = (if (if __local_p1 == __local_p2: 1 else: 0) != 0: (null as *mut stc_slot_list_node) else: __local_p1))
        }

        (__local_lst.last = __local_p2)

        return __local_lst

    }

    pub mut fn unlink_front_node() -> *mut stc_slot_list_node {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        return ((unsafe { stc_slot_list_unlink_after_node(__param_self_, (*__param_self_).last) } as *mut stc_slot_list_node))

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_slot_list = self as *const stc_slot_list
        return (((((unsafe *__param_self_).last == null)) as bool))

    }

    pub mut fn pop_front() {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_slot_list)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_list_pop_front".ptr, c"list.h".ptr, (162 as i32), c"!stc_slot_list_is_empty(self)".ptr)
        } else {
            0
        }

        unsafe { stc_slot_list_erase_after_node(__param_self_, (*__param_self_).last) }

    }

    pub mut fn move_() -> stc_slot_list {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        var __local_m: stc_slot_list = (unsafe *__param_self_)

        ((unsafe *__param_self_).last = ((null as *mut stc_slot_list_node)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_slot_list) -> Unit {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        unsafe { stc_slot_list_drop((__param_self_ as *const stc_slot_list)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_list]())

    }

    pub fn count() -> i64 {
        let __param_self_: *const stc_slot_list = self as *const stc_slot_list
        var __local_n: i64 = ((1 as i64))

        var __local_node: *const stc_slot_list_node = (((unsafe *__param_self_).last as *const stc_slot_list_node))

        if ((if __local_node == null: 1 else: 0) != 0) {
            return ((0 as i64))
        }

        while true {
            (__local_node = (((unsafe *__local_node).next as *const stc_slot_list_node)))

            if (not ((if __local_node != (unsafe *__param_self_).last: 1 else: 0) != 0)) {
                break
            }

            (__local_n = __local_n + 1)

        }

        return __local_n

    }

    pub fn begin() -> stc_slot_list_iter {
        let __param_self_: *const stc_slot_list = self as *const stc_slot_list
        var __local_head: *mut *mut stc_slot_head = (if (unsafe *__param_self_).last != null: ((&raw const (unsafe *(*(*__param_self_).last).next).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head) else: (null as *mut *mut stc_slot_head))

        return ((stc_slot_list_iter { ref: __local_head, _last: (&raw const (unsafe *__param_self_).last as *const *mut stc_slot_list_node), prev: (unsafe *__param_self_).last } as stc_slot_list_iter))

    }

    pub fn end() -> stc_slot_list_iter {
        let __param_self_: *const stc_slot_list = self as *const stc_slot_list

        return ((stc_slot_list_iter.zeroed() as stc_slot_list_iter))

    }

    pub mut fn sort_lowhigh(__param_lo: i64, __param_hi: i64) {
        let __param_self_: *mut stc_slot_list = self as *mut stc_slot_list
        var __local_lo = __param_lo
        var __local_i: i64 = __local_lo

        var __local_j: i64


        while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
            var __local_pivot: *mut stc_slot_head = (unsafe *((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[(__local_lo + (((__param_hi - __local_lo) * 7) / 16))]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

            var __local_rx: *mut stc_slot_head


            (__local_j = __param_hi)

            loop {
                loop {
                    (__local_rx = (unsafe *((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[__local_i]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

                    var __ci_expr_logic_0: i32 = 0

                    if ((if unsafe { (*(*(&raw mut __local_rx as *mut *mut stc_slot_head))).cmp.unwrap()(((*(&raw mut __local_rx as *mut *mut stc_slot_head)) as *const c_void), ((*(&raw mut __local_pivot as *mut *mut stc_slot_head)) as *const c_void)) } < 0: 1 else: 0) != 0) {
                        (__local_i = __local_i + 1)

                        (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                    }

                    if not ((__ci_expr_logic_0 != 0)) {
                        break
                    }
                }

                loop {
                    (__local_rx = (unsafe *((&raw const (((*__param_self_).last as *mut *mut stc_slot_head)[__local_j]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

                    var __ci_expr_logic_1: i32 = 0

                    if ((if unsafe { (*(*(&raw mut __local_pivot as *mut *mut stc_slot_head))).cmp.unwrap()(((*(&raw mut __local_pivot as *mut *mut stc_slot_head)) as *const c_void), ((*(&raw mut __local_rx as *mut *mut stc_slot_head)) as *const c_void)) } < 0: 1 else: 0) != 0) {
                        (__local_j = __local_j - 1)

                        (__ci_expr_logic_1 = (if __local_j != 0: 1 else: 0))

                    }

                    if not ((__ci_expr_logic_1 != 0)) {
                        break
                    }
                }

                if ((if __local_i > __local_j: 1 else: 0) != 0) {
                    break
                }

                loop {
                    var __local__xp: *mut *mut stc_slot_head = (((&raw const (unsafe ((*__param_self_).last as *mut *mut stc_slot_head)[__local_i]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

                    var __local__yp: *mut *mut stc_slot_head = (((&raw const (unsafe ((*__param_self_).last as *mut *mut stc_slot_head)[__local_j]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))


                    var __local__tv: *mut stc_slot_head = (unsafe *__local__xp)

                    ((unsafe *__local__xp) = (unsafe *__local__yp))

                    ((unsafe *__local__yp) = __local__tv)

                    if not ((0 != 0)) {
                        break
                    }
                }

                (__local_i = __local_i + 1)

                (__local_j = __local_j - 1)

                if not (((if __local_i <= __local_j: 1 else: 0) != 0)) {
                    break
                }
            }

            if ((if (__local_j - __local_lo) > (__param_hi - __local_i): 1 else: 0) != 0) {
                loop {
                    var __local__xp_1: *mut i64 = ((&raw mut __local_lo as *mut i64))

                    var __local__yp_1: *mut i64 = ((&raw mut __local_i as *mut i64))


                    var __local__tv_1: i64 = (unsafe *__local__xp_1)

                    ((unsafe *__local__xp_1) = (unsafe *__local__yp_1))

                    ((unsafe *__local__yp_1) = __local__tv_1)

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    var __local__xp_2: *mut i64 = ((&raw mut __param_hi as *mut i64))

                    var __local__yp_2: *mut i64 = ((&raw mut __local_j as *mut i64))


                    var __local__tv_2: i64 = (unsafe *__local__xp_2)

                    ((unsafe *__local__xp_2) = (unsafe *__local__yp_2))

                    ((unsafe *__local__yp_2) = __local__tv_2)

                    if not ((0 != 0)) {
                        break
                    }
                }

            }

            if ((if (__local_j - __local_lo) > 64: 1 else: 0) != 0) {
                unsafe { (*__param_self_).sort_lowhigh(__local_lo, __local_j) }
            } else {
                if ((if __local_j > __local_lo: 1 else: 0) != 0) {
                    unsafe { stc_slot_list_insertsort_lowhigh(__param_self_, __local_lo, __local_j) }
                }
            }

            (__local_lo = __local_i)

        }

    }

}

impl stc_slot_list_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_slot_list_iter = self as *mut stc_slot_list_iter
        var __local_node: *mut stc_slot_list_node = with 0 as __ci_expr_seq_5 {
            ((unsafe *__param_it_).prev = (((if 1 != 0: (unsafe *__param_it_).ref else: (null as *mut *mut stc_slot_head)) as *mut stc_slot_list_node)))
            (unsafe *__param_it_).prev
        }

        ((unsafe *__param_it_).ref = (if (if __local_node == (unsafe *((*__param_it_)._last)): 1 else: 0) != 0: (null as *mut *mut stc_slot_head) else: ((&raw const (unsafe *(*__local_node).next).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    }

}

impl stc_slot_pqueue {
    pub fn make_heap() {
        let __param_self_: *mut stc_slot_pqueue = (self as *const stc_slot_pqueue) as *mut stc_slot_pqueue
        var __local_n: i64 = (unsafe *__param_self_).size

        var __local_k: i64 = (((__local_n / 2) as i64))

        while ((if __local_k != 0: 1 else: 0) != 0) {
            unsafe { (*__param_self_).sift_down_(__local_k, __local_n) }

            (__local_k = __local_k - 1)

        }


    }

    pub mut fn erase_at(__param_idx: i64) {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue

        var __local_n: i64 = with 0 as __ci_expr_seq_6 {
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)
            (unsafe *__param_self_).size
        }

        ((unsafe (*__param_self_).data[__param_idx]) = (unsafe (*__param_self_).data[__local_n]))

        unsafe { (*__param_self_).sift_down_(((__param_idx + 1) as i64), __local_n) }

    }

    pub fn sift_down_(__param_idx: i64, __param_n: i64) {
        let __param_self_: *mut stc_slot_pqueue = (self as *const stc_slot_pqueue) as *mut stc_slot_pqueue
        var __local_t: *mut stc_slot_head

        var __local_arr: *mut *mut stc_slot_head = ((unsafe *__param_self_).data - ((1 as i64) as usize))


        var __local_r: i64 = __param_idx

        var __local_c: i64 = (((__param_idx * 2) as i64))


        while ((if __local_c <= __param_n: 1 else: 0) != 0) {
            (__local_c = __local_c + (if unsafe { (*(*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))).cmp.unwrap()(((*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const (__local_arr[(__local_c + (if __local_c < __param_n: 1 else: 0))]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) } < 0: 1 else: 0))

            if ((if not ((if unsafe { (*(*((&raw const (__local_arr[__local_r]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))).cmp.unwrap()(((*((&raw const (__local_arr[__local_r]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) } < 0: 1 else: 0) != 0): 1 else: 0) != 0) {
                return
            }

            (__local_t = (unsafe __local_arr[__local_r]))

            ((unsafe __local_arr[__local_r]) = (unsafe __local_arr[__local_c]))

            (__local_r = __local_c)

            ((unsafe __local_arr[__local_r]) = __local_t)



            (__local_c = __local_c * 2)

        }


    }

    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue
        var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (unsafe *__param_self_).size else: __param_cap) as i64))

        if ((((if __param_cap > (unsafe *__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (unsafe *__param_self_).capacity: 1 else: 0) as i32)) != 0) {
            var __local_d: *mut *mut stc_slot_head = (((with_realloc((((unsafe *__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[usize]() as i64)) as i64) else: (((unsafe *__param_self_).capacity * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

            if ((if __local_d == null: 1 else: 0) != 0) {
                return ((false as bool))
            }

            ((unsafe *__param_self_).data = __local_d)

            ((unsafe *__param_self_).capacity = __local_n)

        }

        return (((((unsafe *__param_self_).data != null)) as bool))

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue
        unsafe { (*__param_self_).reserve((9223372036854775807 as i64)) }

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue
        var __local_i: i64 = (unsafe *__param_self_).size

        while true {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i - 1)

            if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
                break
            }

        }

        ((unsafe *__param_self_).size = ((0 as i64)))

    }

    pub mut fn move_() -> stc_slot_pqueue {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue
        var __local_m: stc_slot_pqueue = (unsafe *__param_self_)

        ((unsafe *__param_self_).capacity = ((0 as i64)))

        ((unsafe *__param_self_).size = (unsafe *__param_self_).capacity)


        ((unsafe *__param_self_).data = ((null as *mut *mut stc_slot_head)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_slot_pqueue) -> Unit {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue
        unsafe { stc_slot_pqueue_drop((__param_self_ as *const stc_slot_pqueue)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_pqueue]())

    }

    pub fn size() -> i64 {
        let __param_q: *const stc_slot_pqueue = self as *const stc_slot_pqueue
        return (unsafe *__param_q).size

    }

    pub fn is_empty() -> bool {
        let __param_q: *const stc_slot_pqueue = self as *const stc_slot_pqueue
        return ((((not ((unsafe *__param_q).size != 0))) as bool))

    }

    pub fn capacity() -> i64 {
        let __param_q: *const stc_slot_pqueue = self as *const stc_slot_pqueue
        return (unsafe *__param_q).capacity

    }

    pub mut fn pop() {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_pqueue_pop".ptr, c"pqueue.h".ptr, (120 as i32), c"self->size".ptr)
        } else {
            0
        }

        unsafe { (*__param_self_).erase_at((0 as i64)) }

    }

    pub mut fn pull() -> *mut stc_slot_head {
        let __param_self_: *mut stc_slot_pqueue = self as *mut stc_slot_pqueue
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_pqueue_pull".ptr, c"pqueue.h".ptr, (123 as i32), c"self->size".ptr)
        } else {
            0
        }

        var __local_v: *mut stc_slot_head = (unsafe (*__param_self_).data[0])

        unsafe { (*__param_self_).erase_at((0 as i64)) }

        return __local_v

    }

}

impl stc_slot_queue {
    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        var __local_oldpow2: i64 = ((((unsafe *__param_self_).capmask + (((unsafe *__param_self_).capmask as i64) & (1 as i64))) as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__param_cap + 1) as i64)) as i64))

        if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
            return (((((unsafe *__param_self_).cbuf != null)) as bool))
        }

        var __local_d: *mut *mut stc_slot_head = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as i64)) as i64) else: ((__local_oldpow2 * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        var __local_head: i64 = (((__local_oldpow2 - (unsafe *__param_self_).start) as i64))

        if (not ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0)) {
            if ((if __local_head < (unsafe *__param_self_).end: 1 else: 0) != 0) {
                with_memcpy(((((__local_d + ((__local_newpow2 as i64) as usize)) - ((__local_head as i64) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).start = (((__local_newpow2 - __local_head) as i64)))

            } else {
                with_memcpy((((__local_d + ((__local_oldpow2 as i64) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((unsafe *__param_self_).end * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).end = (unsafe *__param_self_).end + __local_oldpow2)

            }
        }

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

        ((unsafe *__param_self_).cbuf = __local_d)

        return ((true as bool))

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        var __local_i: stc_slot_queue_iter = unsafe { (*(((&raw const (*__param_self_) as *const stc_slot_queue) as *mut stc_slot_queue) as *const stc_slot_queue)).begin() }

        while ((unsafe *(&raw const __local_i as *const stc_slot_queue_iter)).ref != null) {


            unsafe { (*(&raw mut __local_i as *mut stc_slot_queue_iter)).next() }

        }


        ((unsafe *__param_self_).start = ((0 as i64)))

        ((unsafe *__param_self_).end = ((0 as i64)))


    }

    pub mut fn shrink_to_fit() {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        var __local_sz: i64 = ((unsafe { (*(__param_self_ as *const stc_slot_queue)).size() } as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__local_sz + 1) as i64)) as i64))

        if ((if __local_newpow2 > (unsafe *__param_self_).capmask: 1 else: 0) != 0) {
            return
        }

        if ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0) {
            with_memmove((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = ((0 as i64)))

            ((unsafe *__param_self_).end = __local_sz)


        } else {
            var __local_n: i64 = (((((unsafe *__param_self_).capmask - (unsafe *__param_self_).start) + 1) as i64))

            with_memmove(((((unsafe *__param_self_).cbuf + (((__local_newpow2 - __local_n) as i64) as usize)) as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = (((__local_newpow2 - __local_n) as i64)))

        }

        ((unsafe *__param_self_).cbuf = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as i64)) as i64) else: ((((unsafe *__param_self_).capmask + 1) * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

    }

    pub fn size() -> i64 {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue
        return ((((unsafe *__param_self_).end - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue
        return (unsafe *__param_self_).capmask

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue
        return (((((unsafe *__param_self_).start == (unsafe *__param_self_).end)) as bool))

    }

    pub mut fn move_() -> stc_slot_queue {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        var __local_m: stc_slot_queue = (unsafe *__param_self_)

        ((unsafe *__param_self_).end = ((0 as i64)))

        ((unsafe *__param_self_).start = (unsafe *__param_self_).end)

        ((unsafe *__param_self_).capmask = (unsafe *__param_self_).start)


        ((unsafe *__param_self_).cbuf = ((null as *mut *mut stc_slot_head)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_slot_queue) -> Unit {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        unsafe { stc_slot_queue_drop((__param_self_ as *const stc_slot_queue)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_queue]())

    }

    pub mut fn pop() {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_slot_queue)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_queue_pop".ptr, c"queue_prv.h".ptr, (133 as i32), c"!stc_slot_queue_is_empty(self)".ptr)
        } else {
            0
        }


        ((unsafe *__param_self_).start = ((((((unsafe *__param_self_).start + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn pull() -> *mut stc_slot_head {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_slot_queue)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_queue_pull".ptr, c"queue_prv.h".ptr, (139 as i32), c"!stc_slot_queue_is_empty(self)".ptr)
        } else {
            0
        }

        var __local_s: i64 = (unsafe *__param_self_).start

        ((unsafe *__param_self_).start = (((((__local_s + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (((unsafe (*__param_self_).cbuf[__local_s]) as *mut stc_slot_head))

    }

    pub fn begin() -> stc_slot_queue_iter {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue
        return ((stc_slot_queue_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut *mut stc_slot_head) else: ((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize))), pos: (unsafe *__param_self_).start, _s: __param_self_ } as stc_slot_queue_iter))

    }

    pub fn rbegin() -> stc_slot_queue_iter {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue
        var __local_pos: i64 = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        return ((stc_slot_queue_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut *mut stc_slot_head) else: ((unsafe *__param_self_).cbuf + ((__local_pos as i64) as usize))), pos: __local_pos, _s: __param_self_ } as stc_slot_queue_iter))

    }

    pub fn end() -> stc_slot_queue_iter {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue

        return ((stc_slot_queue_iter.zeroed() as stc_slot_queue_iter))

    }

    pub fn rend() -> stc_slot_queue_iter {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue

        return ((stc_slot_queue_iter.zeroed() as stc_slot_queue_iter))

    }

    pub fn index(__param_it_: stc_slot_queue_iter) -> i64 {
        let __param_self_: *const stc_slot_queue = self as *const stc_slot_queue
        return ((((unsafe *(&raw const __param_it_ as *const stc_slot_queue_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut stc_slot_queue = self as *mut stc_slot_queue
        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end + __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

}

impl stc_slot_queue_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_slot_queue_iter = self as *mut stc_slot_queue_iter
        if ((if (unsafe *__param_it_).pos != (unsafe *(*__param_it_)._s).capmask: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

            ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos + 1)

        } else {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - (((unsafe *__param_it_).pos as i64) as usize))

            ((unsafe *__param_it_).pos = ((0 as i64)))

        }

        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        }

    }

    pub mut fn rnext() -> Unit {
        let __param_it_: *mut stc_slot_queue_iter = self as *mut stc_slot_queue_iter
        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).start: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        } else {
            if ((if (unsafe *__param_it_).pos != 0: 1 else: 0) != 0) {
                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

                ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos - 1)

            } else {
                ((unsafe *__param_it_).pos = (unsafe *(*__param_it_)._s).capmask)

                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + (((unsafe *__param_it_).pos as i64) as usize))

            }
        }

    }

}

impl stc_slot_set {
    pub mut fn clear() -> Unit {
        let __param_self_: *mut stc_slot_set = self as *mut stc_slot_set
        if ((if (unsafe *__param_self_).meta == null: 1 else: 0) != 0) {
            return
        }

        unsafe { stc_slot_set_wipe_(__param_self_) }

        ((unsafe *__param_self_).size = ((0 as i64)))

        with_memset((((unsafe *__param_self_).meta as *mut c_void) as *mut u8), (0 as i32), (((if 1 != 0: (((sizeof[hmap_meta]() as i64) * (unsafe *__param_self_).bucket_count) as i64) else: (-1 as i64)) as u64) as i64))

    }

    pub mut fn reserve(__param__cap: i64) -> bool {
        let __param__self: *mut stc_slot_set = self as *mut stc_slot_set
        var __local__newcap: i64 = (((if (if __param__cap == 9223372036854775807: 1 else: 0) != 0: (unsafe *__param__self).size else: __param__cap) as i64))

        var __local__newbucks: i64 = ((((((__local__newcap as f32) / i_max_load_factor) as i64) + 4) as i64))

        (__local__newbucks = ((c_next_pow2(__local__newbucks) as i64)))

        var __ci_expr_logic_0: i32

        if ((if __local__newbucks == (unsafe *__param__self).bucket_count: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __param__cap <= (((((unsafe *__param__self).bucket_count as f32) * i_max_load_factor) as i64)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return ((true as bool))
        }


        var __local_map: stc_slot_set = (unsafe *__param__self)

        var __local_self_: *mut stc_slot_set = ((&raw mut __local_map as *mut stc_slot_set))



        (__local_map.table = (((with_alloc((((if 1 != 0: ((__local__newbucks * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))

        (__local_map.meta = (((with_alloc_zeroed((((if 1 != 0: ((__local__newbucks + 1) as i64) else: (-1 as i64)) as u64) as i64), (((if 1 != 0: (sizeof[hmap_meta]() as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut hmap_meta)))

        (__local_map.bucket_count = __local__newbucks)

        var __local_ok: bool = with 0 as __ci_expr_seq_26 {
            var __ci_expr_logic_1: i32 = 0
            if ((unsafe *(&raw const __local_map as *const stc_slot_set)).table != null) {
                (__ci_expr_logic_1 = (if (unsafe *(&raw const __local_map as *const stc_slot_set)).meta != null: 1 else: 0))
            }
            (__ci_expr_logic_1 != 0)
        }

        if __local_ok {
            ((unsafe __local_map.meta[__local__newbucks])).set_dist(((1023 as u16)))

            var __local_d: *const *mut stc_slot_head = (((unsafe *__param__self).table as *const *mut stc_slot_head))

            var __local_m: *const hmap_meta = (((unsafe *__param__self).meta as *const hmap_meta))

            var __local_i: i64 = ((0 as i64))

            while ((if __local_i < (unsafe *__param__self).bucket_count: 1 else: 0) != 0) {
                if ((if ((unsafe __local_m[__local_i])).dist() != 0: 1 else: 0) != 0) {
                    var __local_r: *mut stc_slot_head = (unsafe *__local_d)

                    ((unsafe *(unsafe { stc_slot_set_bucket_insert_(((&raw mut __local_map as *mut stc_slot_set) as *const stc_slot_set), ((&raw mut __local_r as *mut *mut stc_slot_head) as *const *mut stc_slot_head)) }.ref)) = (unsafe *__local_d))

                }

                (__local_i = __local_i + 1)

                (__local_d = __local_d + 1)


            }


            loop {
                var __local__xp: *mut stc_slot_set = __param__self

                var __local__yp: *mut stc_slot_set = ((&raw mut __local_map as *mut stc_slot_set))


                var __local__tv: stc_slot_set = (unsafe *__local__xp)

                with_memcpy((&raw mut (unsafe *__local__xp) as *mut u8), (&raw const (unsafe *__local__yp) as *const u8), sizeof[stc_slot_set]())

                with_memcpy((&raw mut (unsafe *__local__yp) as *mut u8), (&raw const __local__tv as *const u8), sizeof[stc_slot_set]())

                if not ((0 != 0)) {
                    break
                }
            }

        }

        with_free((((unsafe *(&raw const __local_map as *const stc_slot_set)).meta as *mut c_void) as *mut u8))

        with_free((((unsafe *(&raw const __local_map as *const stc_slot_set)).table as *mut c_void) as *mut u8))

        return __local_ok

    }

    pub fn max_load_factor() -> f32 {
        let __param_self_: *const stc_slot_set = self as *const stc_slot_set

        return i_max_load_factor

    }

    pub fn capacity() -> i64 {
        let __param_map: *const stc_slot_set = self as *const stc_slot_set
        return (((((unsafe *__param_map).bucket_count as f32) * i_max_load_factor) as i64))

    }

    pub fn is_empty() -> bool {
        let __param_map: *const stc_slot_set = self as *const stc_slot_set
        return ((((not ((unsafe *__param_map).size != 0))) as bool))

    }

    pub fn size() -> i64 {
        let __param_map: *const stc_slot_set = self as *const stc_slot_set
        return (unsafe *__param_map).size

    }

    pub fn bucket_count() -> i64 {
        let __param_map: *mut stc_slot_set = (self as *const stc_slot_set) as *mut stc_slot_set
        return (unsafe *__param_map).bucket_count

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut stc_slot_set = self as *mut stc_slot_set
        unsafe { (*__param_self_).reserve((9223372036854775807 as i64)) }

    }

    pub mut fn move_() -> stc_slot_set {
        let __param_self_: *mut stc_slot_set = self as *mut stc_slot_set
        var __local_m: stc_slot_set = (unsafe *__param_self_)

        ((unsafe *__param_self_).size = ((0 as i64)))

        ((unsafe *__param_self_).bucket_count = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).meta = ((null as *mut hmap_meta)))

        ((unsafe *__param_self_).table = ((null as *mut *mut stc_slot_head)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_slot_set) -> Unit {
        let __param_self_: *mut stc_slot_set = self as *mut stc_slot_set
        unsafe { stc_slot_set_drop((__param_self_ as *const stc_slot_set)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_set]())

    }

    pub fn begin() -> stc_slot_set_iter {
        let __param_self_: *const stc_slot_set = self as *const stc_slot_set
        var __local_it_: stc_slot_set_iter = stc_slot_set_iter { ref: (unsafe *__param_self_).table, _end: (unsafe *__param_self_).table, _mref: (unsafe *__param_self_).meta }

        if ((if (unsafe *(&raw const __local_it_ as *const stc_slot_set_iter)).ref == null: 1 else: 0) != 0) {
            return __local_it_
        }

        (__local_it_._end = (unsafe *(&raw const __local_it_ as *const stc_slot_set_iter))._end + (((unsafe *__param_self_).bucket_count as i64) as usize))

        while ((if (unsafe *(*(&raw const __local_it_ as *const stc_slot_set_iter))._mref).dist() == 0: 1 else: 0) != 0) {
            (__local_it_.ref = (unsafe *(&raw const __local_it_ as *const stc_slot_set_iter)).ref + 1)

            (__local_it_._mref = (unsafe *(&raw const __local_it_ as *const stc_slot_set_iter))._mref + 1)

        }

        if ((if (unsafe *(&raw const __local_it_ as *const stc_slot_set_iter)).ref == (unsafe *(&raw const __local_it_ as *const stc_slot_set_iter))._end: 1 else: 0) != 0) {
            (__local_it_.ref = ((null as *mut *mut stc_slot_head)))
        }

        return __local_it_

    }

    pub fn end() -> stc_slot_set_iter {
        let __param_self_: *const stc_slot_set = self as *const stc_slot_set

        return ((stc_slot_set_iter.zeroed() as stc_slot_set_iter))

    }

    pub mut fn erase_at(__param_it_: stc_slot_set_iter) -> stc_slot_set_iter {
        let __param_self_: *mut stc_slot_set = self as *mut stc_slot_set
        unsafe { stc_slot_set_erase_entry(__param_self_, (*(&raw const __param_it_ as *const stc_slot_set_iter)).ref) }

        if ((if (unsafe *(*(&raw const __param_it_ as *const stc_slot_set_iter))._mref).dist() == 0: 1 else: 0) != 0) {
            unsafe { (*(&raw mut __param_it_ as *mut stc_slot_set_iter)).next() }
        }

        return __param_it_

    }

}

impl stc_slot_set_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_slot_set_iter = self as *mut stc_slot_set_iter
        while true {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

            ((unsafe *__param_it_)._mref = (unsafe *__param_it_)._mref + 1)

            if (not ((if (unsafe *(*__param_it_)._mref).dist() == 0: 1 else: 0) != 0)) {
                break
            }

        }

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_)._end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        }

    }

}

impl stc_slot_sset {
    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_slot_sset = self as *mut stc_slot_sset
        if ((if __param_cap <= (unsafe *__param_self_).capacity: 1 else: 0) != 0) {
            return ((false as bool))
        }

        var __local_nodes: *mut stc_slot_sset_node = (((with_realloc((((unsafe *__param_self_).nodes as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: (((__param_cap + 1) * (sizeof[stc_slot_sset_node]() as i64)) as i64) else: ((((unsafe *__param_self_).capacity + 1) * (sizeof[stc_slot_sset_node]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_slot_sset_node))

        if ((if __local_nodes == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        ((unsafe __local_nodes[0]) = ((stc_slot_sset_node.zeroed() as stc_slot_sset_node)))

        ((unsafe *__param_self_).nodes = __local_nodes)

        ((unsafe *__param_self_).capacity = ((__param_cap as i32)))

        return ((true as bool))

    }

    pub mut fn erase_at(__param_it_: stc_slot_sset_iter) -> stc_slot_sset_iter {
        let __param_self_: *mut stc_slot_sset = self as *mut stc_slot_sset
        var __local_raw: *mut stc_slot_head = (unsafe *((*(&raw const __param_it_ as *const stc_slot_sset_iter)).ref))

        unsafe { (*(&raw mut __param_it_ as *mut stc_slot_sset_iter)).next() }

        if ((if (unsafe *(&raw const __param_it_ as *const stc_slot_sset_iter)).ref != null: 1 else: 0) != 0) {
            var __local_nxt: *mut stc_slot_head = (unsafe *((*(&raw const __param_it_ as *const stc_slot_sset_iter)).ref))

            unsafe { stc_slot_sset_erase(__param_self_, __local_raw) }

            unsafe { stc_slot_sset_find_it((__param_self_ as *const stc_slot_sset), __local_nxt, (&raw mut __param_it_ as *mut stc_slot_sset_iter)) }

        } else {
            unsafe { stc_slot_sset_erase(__param_self_, __local_raw) }
        }

        return __param_it_

    }

    pub mut fn erase_range(__param_it1: stc_slot_sset_iter, __param_it2: stc_slot_sset_iter) -> stc_slot_sset_iter {
        let __param_self_: *mut stc_slot_sset = self as *mut stc_slot_sset
        var __local_it1 = __param_it1
        if ((if (unsafe *(&raw const __param_it2 as *const stc_slot_sset_iter)).ref == null: 1 else: 0) != 0) {
            while ((if (unsafe *(&raw const __local_it1 as *const stc_slot_sset_iter)).ref != null: 1 else: 0) != 0) {
                let __ci_copy_28: stc_slot_sset_iter = unsafe { (*__param_self_).erase_at(__local_it1) }
                with_memcpy((&raw mut __local_it1 as *mut u8), (&raw const __ci_copy_28 as *const u8), sizeof[stc_slot_sset_iter]())
            }

            return __local_it1

        }

        var __local_k1: *mut stc_slot_head = (unsafe *((*(&raw const __local_it1 as *const stc_slot_sset_iter)).ref))

        var __local_k2: *mut stc_slot_head = (unsafe *((*(&raw const __param_it2 as *const stc_slot_sset_iter)).ref))


        var __local_r1: *mut stc_slot_head = (unsafe *(&raw mut __local_k1 as *mut *mut stc_slot_head))

        while true {
            if ((if with_memcmp((((&raw mut __local_k1 as *mut *mut stc_slot_head) as *const c_void) as *const u8), (((&raw mut __local_k2 as *mut *mut stc_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64)) == 0: 1 else: 0) != 0) {
                return __local_it1
            }

            unsafe { (*(&raw mut __local_it1 as *mut stc_slot_sset_iter)).next() }

            (__local_k1 = (unsafe *((*(&raw const __local_it1 as *const stc_slot_sset_iter)).ref)))

            unsafe { stc_slot_sset_erase(__param_self_, __local_r1) }

            (__local_r1 = (unsafe *(&raw mut __local_k1 as *mut *mut stc_slot_head)))

            unsafe { stc_slot_sset_find_it((__param_self_ as *const stc_slot_sset), __local_r1, (&raw mut __local_it1 as *mut stc_slot_sset_iter)) }

        }

    }

    pub fn begin() -> stc_slot_sset_iter {
        let __param_self_: *const stc_slot_sset = self as *const stc_slot_sset
        var __local_it_: stc_slot_sset_iter

        (__local_it_.ref = ((null as *mut *mut stc_slot_head)))

        (__local_it_._d = (unsafe *__param_self_).nodes)

        (__local_it_._top = ((0 as i32)))


        (__local_it_._tn = (unsafe *__param_self_).root)

        if ((unsafe *(&raw const __local_it_ as *const stc_slot_sset_iter))._tn != 0) {
            unsafe { (*(&raw mut __local_it_ as *mut stc_slot_sset_iter)).next() }
        }

        return __local_it_

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_slot_sset = self as *const stc_slot_sset
        return (((((unsafe *__param_self_).size == 0)) as bool))

    }

    pub fn size() -> i64 {
        let __param_self_: *const stc_slot_sset = self as *const stc_slot_sset
        return (((unsafe *__param_self_).size as i64))

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const stc_slot_sset = self as *const stc_slot_sset
        return (((unsafe *__param_self_).capacity as i64))

    }

    pub mut fn move_() -> stc_slot_sset {
        let __param_self_: *mut stc_slot_sset = self as *mut stc_slot_sset
        var __local_m: stc_slot_sset = (unsafe *__param_self_)

        ((unsafe *__param_self_).head = ((0 as i32)))

        ((unsafe *__param_self_).disp = (unsafe *__param_self_).head)

        ((unsafe *__param_self_).root = (unsafe *__param_self_).disp)

        ((unsafe *__param_self_).size = (unsafe *__param_self_).root)

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).nodes = ((null as *mut stc_slot_sset_node)))

        return __local_m

    }

    pub mut fn clear() -> Unit {
        let __param_self_: *mut stc_slot_sset = self as *mut stc_slot_sset
        unsafe { stc_slot_sset_drop((__param_self_ as *const stc_slot_sset)) }

        unsafe { (*__param_self_).move_() }

    }

    pub mut fn take(__param_unowned: stc_slot_sset) -> Unit {
        let __param_self_: *mut stc_slot_sset = self as *mut stc_slot_sset
        unsafe { stc_slot_sset_drop((__param_self_ as *const stc_slot_sset)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_sset]())

    }

    pub fn end() -> stc_slot_sset_iter {
        let __param_self_: *const stc_slot_sset = self as *const stc_slot_sset
        var __local_it_: stc_slot_sset_iter


        (__local_it_.ref = ((null as *mut *mut stc_slot_head)))

        (__local_it_._top = ((0 as i32)))

        (__local_it_._tn = ((0 as i32)))


        return __local_it_

    }

}

impl stc_slot_sset_iter {
    pub mut fn next() -> Unit {
        let __param_it_: *mut stc_slot_sset_iter = self as *mut stc_slot_sset_iter
        var __local_tn: i32 = (unsafe *__param_it_)._tn

        var __ci_expr_logic_0: i32

        if ((unsafe *__param_it_)._top != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if __local_tn != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            while (__local_tn != 0) {
                var __ci_expr_old_1: i32 = (unsafe *__param_it_)._top

                ((unsafe *__param_it_)._top = (unsafe *__param_it_)._top + 1)

                ((unsafe *__param_it_)._st[__ci_expr_old_1] = __local_tn)


                (__local_tn = (((unsafe (*__param_it_)._d[__local_tn]).link[0] as i32)))

            }

            ((unsafe *__param_it_)._top = (unsafe *__param_it_)._top - 1)

            (__local_tn = (((unsafe *__param_it_)._st[(unsafe *__param_it_)._top] as i32)))


            ((unsafe *__param_it_)._tn = (((unsafe (*__param_it_)._d[__local_tn]).link[1] as i32)))

            ((unsafe *__param_it_).ref = (((&raw const (unsafe (*__param_it_)._d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

        } else {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        }


    }

}

impl stc_slot_stack {
    pub mut fn move_() -> stc_slot_stack {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        var __local_m: stc_slot_stack = (unsafe *__param_self_)

        ((unsafe *__param_self_).size = ((0 as i64)))

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).data = ((null as *mut *mut stc_slot_head)))

        return __local_m

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack
        return (unsafe *__param_self_).capacity

    }

    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (unsafe *__param_self_).size else: __param_cap) as i64))

        if ((((if __param_cap > (unsafe *__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (unsafe *__param_self_).capacity: 1 else: 0) as i32)) != 0) {
            var __local_d: *mut *mut stc_slot_head = (((with_realloc((((unsafe *__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[usize]() as i64)) as i64) else: (((unsafe *__param_self_).capacity * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

            if ((if __local_d == null: 1 else: 0) != 0) {
                return ((false as bool))
            }

            ((unsafe *__param_self_).data = __local_d)

            ((unsafe *__param_self_).capacity = __local_n)

        }

        return (((((unsafe *__param_self_).data != null)) as bool))

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        var __local_i: i64 = (unsafe *__param_self_).size

        while true {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i - 1)

            if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
                break
            }

        }

        ((unsafe *__param_self_).size = ((0 as i64)))

    }

    pub mut fn take(__param_unowned: stc_slot_stack) -> Unit {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        unsafe { stc_slot_stack_drop((__param_self_ as *const stc_slot_stack)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_stack]())

    }

    pub fn size() -> i64 {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack
        return (unsafe *__param_self_).size

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack
        return ((((not ((unsafe *__param_self_).size != 0))) as bool))

    }

    pub mut fn append_uninit(__param_n: i64) -> *mut *mut stc_slot_head {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        var __local_len: i64 = (unsafe *__param_self_).size

        if ((if (__local_len + __param_n) >= unsafe { (*(__param_self_ as *const stc_slot_stack)).capacity() }: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve(((((__local_len * 3) / 2) + __param_n) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut *mut stc_slot_head))
            }
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

        return ((unsafe *__param_self_).data + ((__local_len as i64) as usize))

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        unsafe { (*__param_self_).reserve((9223372036854775807 as i64)) }

    }

    pub mut fn pop() {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_stack_pop".ptr, c"stack.h".ptr, (149 as i32), c"self->size".ptr)
        } else {
            0
        }

        var __local_p: *mut *mut stc_slot_head = with 0 as __ci_expr_seq_8 {
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)
            ((&raw const (unsafe (*__param_self_).data[(*__param_self_).size]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)
        }


    }

    pub mut fn pull() -> *mut stc_slot_head {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_slot_stack_pull".ptr, c"stack.h".ptr, (152 as i32), c"self->size".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)

        return (((unsafe (*__param_self_).data[(*__param_self_).size]) as *mut stc_slot_head))


    }

    pub fn begin() -> stc_slot_stack_iter {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack
        var __local_it_: stc_slot_stack_iter = stc_slot_stack_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if ((unsafe *__param_self_).size != 0) {
            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const stc_slot_stack_iter)).end + (((unsafe *__param_self_).size as i64) as usize))
        } else {
            (__local_it_.ref = ((null as *mut *mut stc_slot_head)))
        }

        return __local_it_

    }

    pub fn rbegin() -> stc_slot_stack_iter {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack
        var __local_it_: stc_slot_stack_iter = stc_slot_stack_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if ((unsafe *__param_self_).size != 0) {
            (__local_it_.ref = (unsafe *(&raw const __local_it_ as *const stc_slot_stack_iter)).ref + ((((unsafe *__param_self_).size - 1) as i64) as usize))

            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const stc_slot_stack_iter)).end - ((1 as i64) as usize))

        } else {
            (__local_it_.ref = ((null as *mut *mut stc_slot_head)))
        }

        return __local_it_

    }

    pub fn end() -> stc_slot_stack_iter {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack

        var __local_it_: stc_slot_stack_iter = stc_slot_stack_iter.zeroed()

        return __local_it_

    }

    pub fn rend() -> stc_slot_stack_iter {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack

        var __local_it_: stc_slot_stack_iter = stc_slot_stack_iter.zeroed()

        return __local_it_

    }

    pub fn index(__param_it_: stc_slot_stack_iter) -> i64 {
        let __param_self_: *const stc_slot_stack = self as *const stc_slot_stack
        return (((((unsafe *(&raw const __param_it_ as *const stc_slot_stack_iter)).ref as usize) -% ((unsafe *__param_self_).data as usize)) as i64) / (sizeof[usize]() as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut stc_slot_stack = self as *mut stc_slot_stack
        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

    }

}

impl stc_slot_stack_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_slot_stack_iter = self as *mut stc_slot_stack_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        }


    }

    pub mut fn rnext() {
        let __param_it_: *mut stc_slot_stack_iter = self as *mut stc_slot_stack_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut *mut stc_slot_head)))
        }


    }

}

impl stc_word_deque {
    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_oldpow2: i64 = ((((unsafe *__param_self_).capmask + (((unsafe *__param_self_).capmask as i64) & (1 as i64))) as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__param_cap + 1) as i64)) as i64))

        if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
            return (((((unsafe *__param_self_).cbuf != null)) as bool))
        }

        var __local_d: *mut u64 = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[u64]() as i64)) as i64) else: ((__local_oldpow2 * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        var __local_head: i64 = (((__local_oldpow2 - (unsafe *__param_self_).start) as i64))

        if (not ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0)) {
            if ((if __local_head < (unsafe *__param_self_).end: 1 else: 0) != 0) {
                with_memcpy(((((__local_d + ((__local_newpow2 as i64) as usize)) - ((__local_head as i64) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).start = (((__local_newpow2 - __local_head) as i64)))

            } else {
                with_memcpy((((__local_d + ((__local_oldpow2 as i64) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((unsafe *__param_self_).end * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).end = (unsafe *__param_self_).end + __local_oldpow2)

            }
        }

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

        ((unsafe *__param_self_).cbuf = __local_d)

        return ((true as bool))

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_i: stc_word_deque_iter = unsafe { (*(((&raw const (*__param_self_) as *const stc_word_deque) as *mut stc_word_deque) as *const stc_word_deque)).begin() }

        while ((unsafe *(&raw const __local_i as *const stc_word_deque_iter)).ref != null) {


            unsafe { (*(&raw mut __local_i as *mut stc_word_deque_iter)).next() }

        }


        ((unsafe *__param_self_).start = ((0 as i64)))

        ((unsafe *__param_self_).end = ((0 as i64)))


    }

    pub mut fn push(__param_value: u64) -> *mut u64 {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_end: i64 = ((((((unsafe *__param_self_).end + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        if ((if __local_end == (unsafe *__param_self_).start: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve((((*__param_self_).capmask + 3) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut u64))
            }

            (__local_end = ((((((unsafe *__param_self_).end + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        }

        var __local_v: *mut u64 = ((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).end as i64) as usize))

        ((unsafe *__param_self_).end = __local_end)

        ((unsafe *__local_v) = __param_value)

        return __local_v

    }

    pub mut fn shrink_to_fit() {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_sz: i64 = ((unsafe { (*(__param_self_ as *const stc_word_deque)).size() } as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__local_sz + 1) as i64)) as i64))

        if ((if __local_newpow2 > (unsafe *__param_self_).capmask: 1 else: 0) != 0) {
            return
        }

        if ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0) {
            with_memmove((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = ((0 as i64)))

            ((unsafe *__param_self_).end = __local_sz)


        } else {
            var __local_n: i64 = (((((unsafe *__param_self_).capmask - (unsafe *__param_self_).start) + 1) as i64))

            with_memmove(((((unsafe *__param_self_).cbuf + (((__local_newpow2 - __local_n) as i64) as usize)) as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = (((__local_newpow2 - __local_n) as i64)))

        }

        ((unsafe *__param_self_).cbuf = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[u64]() as i64)) as i64) else: ((((unsafe *__param_self_).capmask + 1) * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

    }

    pub fn value_clone(__param_val: u64) -> u64 {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque

        return __param_val

    }

    pub fn size() -> i64 {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque
        return ((((unsafe *__param_self_).end - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque
        return (unsafe *__param_self_).capmask

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque
        return (((((unsafe *__param_self_).start == (unsafe *__param_self_).end)) as bool))

    }

    pub mut fn move_() -> stc_word_deque {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_m: stc_word_deque = (unsafe *__param_self_)

        ((unsafe *__param_self_).end = ((0 as i64)))

        ((unsafe *__param_self_).start = (unsafe *__param_self_).end)

        ((unsafe *__param_self_).capmask = (unsafe *__param_self_).start)


        ((unsafe *__param_self_).cbuf = ((null as *mut u64)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_word_deque) -> Unit {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        unsafe { stc_word_deque_drop((__param_self_ as *const stc_word_deque)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_deque]())

    }

    pub mut fn pop_front() {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_word_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_deque_pop_front".ptr, c"queue_prv.h".ptr, (133 as i32), c"!stc_word_deque_is_empty(self)".ptr)
        } else {
            0
        }


        ((unsafe *__param_self_).start = ((((((unsafe *__param_self_).start + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn pull_front() -> u64 {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_word_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_deque_pull_front".ptr, c"queue_prv.h".ptr, (139 as i32), c"!stc_word_deque_is_empty(self)".ptr)
        } else {
            0
        }

        var __local_s: i64 = (unsafe *__param_self_).start

        ((unsafe *__param_self_).start = (((((__local_s + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (unsafe (*__param_self_).cbuf[__local_s])

    }

    pub fn begin() -> stc_word_deque_iter {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque
        return ((stc_word_deque_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut u64) else: ((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize))), pos: (unsafe *__param_self_).start, _s: __param_self_ } as stc_word_deque_iter))

    }

    pub fn rbegin() -> stc_word_deque_iter {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque
        var __local_pos: i64 = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        return ((stc_word_deque_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut u64) else: ((unsafe *__param_self_).cbuf + ((__local_pos as i64) as usize))), pos: __local_pos, _s: __param_self_ } as stc_word_deque_iter))

    }

    pub fn end() -> stc_word_deque_iter {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque

        return ((stc_word_deque_iter.zeroed() as stc_word_deque_iter))

    }

    pub fn rend() -> stc_word_deque_iter {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque

        return ((stc_word_deque_iter.zeroed() as stc_word_deque_iter))

    }

    pub fn index(__param_it_: stc_word_deque_iter) -> i64 {
        let __param_self_: *const stc_word_deque = self as *const stc_word_deque
        return ((((unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end + __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn push_front(__param_value: u64) -> *mut u64 {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_start: i64 = ((((((unsafe *__param_self_).start - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        if ((if __local_start == (unsafe *__param_self_).end: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve((((*__param_self_).capmask + 3) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut u64))
            }

            (__local_start = ((((((unsafe *__param_self_).start - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        }

        var __local_v: *mut u64 = ((unsafe *__param_self_).cbuf + ((__local_start as i64) as usize))

        ((unsafe *__param_self_).start = __local_start)

        ((unsafe *__local_v) = __param_value)

        return __local_v

    }

    pub mut fn insert_uninit(__param_idx: i64, __param_n: i64) -> stc_word_deque_iter {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_len: i64 = ((unsafe { (*(__param_self_ as *const stc_word_deque)).size() } as i64))

        var __local_it_: stc_word_deque_iter = stc_word_deque_iter { _s: (__param_self_ as *const stc_word_deque) }

        if ((if (__local_len + __param_n) >= (unsafe *__param_self_).capmask: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve(((__local_len + __param_n) as i64)) }: 1 else: 0) != 0) {
                return __local_it_
            }
        }

        (__local_it_.pos = ((((((unsafe *__param_self_).start + __param_idx) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        (__local_it_.ref = (unsafe *__param_self_).cbuf + (((unsafe *(&raw const __local_it_ as *const stc_word_deque_iter)).pos as i64) as usize))

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end + __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        if ((if (unsafe *(&raw const __local_it_ as *const stc_word_deque_iter)).pos < (unsafe *__param_self_).end: 1 else: 0) != 0) {
            with_memmove(((((unsafe *(&raw const __local_it_ as *const stc_word_deque_iter)).ref + ((__param_n as i64) as usize)) as *mut c_void) as *mut u8), (((unsafe *(&raw const __local_it_ as *const stc_word_deque_iter)).ref as *const c_void) as *const u8), (((if 1 != 0: (((__local_len - __param_idx) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))
        } else {
            var __local_i: i64 = (((__local_len - 1) as i64))

            var __local_j: i64 = (((__local_i + __param_n) as i64))


            while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
                ((unsafe *unsafe { stc_word_deque_at_mut(__param_self_, __local_j) }) = (unsafe *unsafe { stc_word_deque_at((__param_self_ as *const stc_word_deque), __local_i) }))

                (__local_i = __local_i - 1)

                (__local_j = __local_j - 1)


            }

        }

        return __local_it_

    }

    pub mut fn erase_n(__param_idx: i64, __param_n: i64) {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_len: i64 = ((unsafe { (*(__param_self_ as *const stc_word_deque)).size() } as i64))

        if (((if not ((if (__param_idx + __param_n) <= __local_len: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_deque_erase_n".ptr, c"deque.h".ptr, (149 as i32), c"idx + n <= len".ptr)
        } else {
            0
        }

        var __local_i: i64 = ((((__param_idx + __param_n) - 1) as i64))

        while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
            unsafe { stc_word_deque_at_mut(__param_self_, __local_i) }

            (__local_i = __local_i - 1)

        }


        var __local_i_1: i64 = __param_idx

        var __local_j: i64 = (((__local_i_1 + __param_n) as i64))


        while ((if __local_j < __local_len: 1 else: 0) != 0) {
            ((unsafe *unsafe { stc_word_deque_at_mut(__param_self_, __local_i_1) }) = (unsafe *unsafe { stc_word_deque_at((__param_self_ as *const stc_word_deque), __local_j) }))

            (__local_i_1 = __local_i_1 + 1)

            (__local_j = __local_j + 1)


        }


        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn push_back(__param_val: u64) -> *mut u64 {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        return ((unsafe { (*__param_self_).push(__param_val) } as *mut u64))

    }

    pub mut fn pop_back() {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_word_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_deque_pop_back".ptr, c"deque.h".ptr, (67 as i32), c"!stc_word_deque_is_empty(self)".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))


    }

    pub mut fn pull_back() -> u64 {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_word_deque)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_deque_pull_back".ptr, c"deque.h".ptr, (73 as i32), c"!stc_word_deque_is_empty(self)".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (unsafe (*__param_self_).cbuf[(*__param_self_).end])

    }

    pub mut fn insert_at(__param_it_: stc_word_deque_iter, __param_val: u64) -> stc_word_deque_iter {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_idx: i64 = ((((((unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        return unsafe { stc_word_deque_insert_n(__param_self_, __local_idx, (&raw const __param_val as *const u64), (1 as i64)) }

    }

    pub mut fn erase_at(__param_it_: stc_word_deque_iter) -> stc_word_deque_iter {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        unsafe { (*__param_self_).erase_n((((((*(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64), (1 as i64)) }

        if ((if (unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos == (unsafe *__param_self_).end: 1 else: 0) != 0) {
            (__param_it_.ref = ((null as *mut u64)))
        }

        return __param_it_

    }

    pub mut fn erase_range(__param_it1: stc_word_deque_iter, __param_it2: stc_word_deque_iter) -> stc_word_deque_iter {
        let __param_self_: *mut stc_word_deque = self as *mut stc_word_deque
        var __local_idx1: i64 = ((((((unsafe *(&raw const __param_it1 as *const stc_word_deque_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        var __local_idx2: i64 = ((((((unsafe *(&raw const __param_it2 as *const stc_word_deque_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        unsafe { (*__param_self_).erase_n(__local_idx1, ((__local_idx2 - __local_idx1) as i64)) }

        if ((if (unsafe *(&raw const __param_it1 as *const stc_word_deque_iter)).pos == (unsafe *__param_self_).end: 1 else: 0) != 0) {
            (__param_it1.ref = ((null as *mut u64)))
        }

        return __param_it1

    }

}

impl stc_word_deque_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_word_deque_iter = self as *mut stc_word_deque_iter
        if ((if (unsafe *__param_it_).pos != (unsafe *(*__param_it_)._s).capmask: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

            ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos + 1)

        } else {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - (((unsafe *__param_it_).pos as i64) as usize))

            ((unsafe *__param_it_).pos = ((0 as i64)))

        }

        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut u64)))
        }

    }

    pub mut fn rnext() -> Unit {
        let __param_it_: *mut stc_word_deque_iter = self as *mut stc_word_deque_iter
        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).start: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut u64)))
        } else {
            if ((if (unsafe *__param_it_).pos != 0: 1 else: 0) != 0) {
                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

                ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos - 1)

            } else {
                ((unsafe *__param_it_).pos = (unsafe *(*__param_it_)._s).capmask)

                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + (((unsafe *__param_it_).pos as i64) as usize))

            }
        }

    }

}

impl stc_word_list {
    pub mut fn push_back(__param_value: i64) -> *mut i64 {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_entry: *mut stc_word_list_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[stc_word_list_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_word_list_node))

        ((unsafe *__local_entry).value = __param_value)

        if ((unsafe *__param_self_).last != null) {
            ((unsafe *__local_entry).next = (unsafe *(*__param_self_).last).next)

            ((unsafe *(*__param_self_).last).next = __local_entry)

        } else {
            ((unsafe *__local_entry).next = __local_entry)
        }

        ((unsafe *__param_self_).last = __local_entry)

        return (((&raw const (unsafe *__local_entry).value as *const i64) as *mut i64))

    }

    pub mut fn push_front(__param_value: i64) -> *mut i64 {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_entry: *mut stc_word_list_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[stc_word_list_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_word_list_node))

        ((unsafe *__local_entry).value = __param_value)

        if ((unsafe *__param_self_).last != null) {
            ((unsafe *__local_entry).next = (unsafe *(*__param_self_).last).next)

            ((unsafe *(*__param_self_).last).next = __local_entry)

        } else {
            ((unsafe *__local_entry).next = __local_entry)
        }

        if ((if (unsafe *__param_self_).last == null: 1 else: 0) != 0) {
            ((unsafe *__param_self_).last = __local_entry)
        }

        return (((&raw const (unsafe *__local_entry).value as *const i64) as *mut i64))

    }

    pub mut fn insert_at(__param_it_: stc_word_list_iter, __param_value: i64) -> stc_word_list_iter {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_node: *mut stc_word_list_node = (if (unsafe *(&raw const __param_it_ as *const stc_word_list_iter)).ref != null: (unsafe *(&raw const __param_it_ as *const stc_word_list_iter)).prev else: (unsafe *__param_self_).last)

        var __local_entry: *mut stc_word_list_node = (((with_alloc((((if 1 != 0: ((1 * (sizeof[stc_word_list_node]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_word_list_node))

        ((unsafe *__local_entry).value = __param_value)

        if (__local_node != null) {
            ((unsafe *__local_entry).next = (unsafe *__local_node).next)

            ((unsafe *__local_node).next = __local_entry)

        } else {
            ((unsafe *__local_entry).next = __local_entry)
        }

        var __ci_expr_logic_0: i32

        if ((if (unsafe *__param_self_).last == null: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe *(&raw const __param_it_ as *const stc_word_list_iter)).ref == null: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__param_it_.prev = (if (unsafe *__param_self_).last != null: (unsafe *__param_self_).last else: __local_entry))

            ((unsafe *__param_self_).last = __local_entry)

        }


        (__param_it_.ref = (((&raw const (unsafe *__local_entry).value as *const i64) as *mut i64)))

        return __param_it_

    }

    pub mut fn erase_at(__param_it_: stc_word_list_iter) -> stc_word_list_iter {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_node: *mut stc_word_list_node = (((if 1 != 0: (unsafe *(&raw const __param_it_ as *const stc_word_list_iter)).ref else: (null as *mut i64)) as *mut stc_word_list_node))

        (__param_it_.ref = (if (if __local_node == (unsafe *__param_self_).last: 1 else: 0) != 0: (null as *mut i64) else: ((&raw const (unsafe *(*__local_node).next).value as *const i64) as *mut i64)))

        unsafe { stc_word_list_erase_after_node(__param_self_, (*(&raw const __param_it_ as *const stc_word_list_iter)).prev) }

        return __param_it_

    }

    pub mut fn erase_range(__param_it1: stc_word_list_iter, __param_it2: stc_word_list_iter) -> stc_word_list_iter {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_end: *mut stc_word_list_node = (if (unsafe *(&raw const __param_it2 as *const stc_word_list_iter)).ref != null: ((if 1 != 0: (unsafe *(&raw const __param_it2 as *const stc_word_list_iter)).ref else: (null as *mut i64)) as *mut stc_word_list_node) else: (unsafe *(*__param_self_).last).next)

        if ((if (unsafe *(&raw const __param_it1 as *const stc_word_list_iter)).ref != (unsafe *(&raw const __param_it2 as *const stc_word_list_iter)).ref: 1 else: 0) != 0) {
            loop {
                unsafe { stc_word_list_erase_after_node(__param_self_, (*(&raw const __param_it1 as *const stc_word_list_iter)).prev) }

                if ((if (unsafe *__param_self_).last == null: 1 else: 0) != 0) {
                    break
                }

                if not (((if (unsafe *(*(&raw const __param_it1 as *const stc_word_list_iter)).prev).next != __local_end: 1 else: 0) != 0)) {
                    break
                }
            }
        }

        return __param_it2

    }

    pub mut fn sort() -> bool {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_len__goto_410_13: i64 = 0

        var __local_cap__goto_410_22: i64 = 0

        var __local_arr__goto_411_15: *mut i64 = null

        var __local_p__goto_411_28: *mut i64 = null

        var __local_keep__goto_412_14: *mut stc_word_list_node = null

        var __local_i__goto_413_10: stc_word_list_iter = stc_word_list_iter.zeroed()

        var __local_cap_n__goto_415_21: i64 = 0

        var __local_i__goto_426_10: stc_word_list_iter = stc_word_list_iter.zeroed()

        var __ci_expr_old_0: i64 = 0

        var __ci_expr_old_1: *mut i64 = null

        goto '__ci_bb_0

        '__ci_bb_0 {
            (__local_len__goto_410_13 = ((0 as i64)))
            (__local_cap__goto_410_22 = ((0 as i64)))
            (__local_arr__goto_411_15 = ((null as *mut i64)))
            (__local_p__goto_411_28 = ((null as *mut i64)))
            (__local_i__goto_413_10 = unsafe { (*(((&raw const (*__param_self_) as *const stc_word_list) as *mut stc_word_list) as *const stc_word_list)).begin() })
            goto '__ci_bb_1
        }

        '__ci_bb_1 {
            if ((unsafe *(&raw const __local_i__goto_413_10 as *const stc_word_list_iter)).ref != null) {
                goto '__ci_bb_2
            } else {
                goto '__ci_bb_4
            }
        }

        '__ci_bb_2 {
            if ((if __local_len__goto_410_13 == __local_cap__goto_410_22: 1 else: 0) != 0) {
                goto '__ci_bb_5
            } else {
                goto '__ci_bb_6
            }
        }

        '__ci_bb_3 {
            unsafe { (*(&raw mut __local_i__goto_413_10 as *mut stc_word_list_iter)).next() }
            goto '__ci_bb_1
        }

        '__ci_bb_4 {
            (__local_keep__goto_412_14 = (unsafe *__param_self_).last)
            ((unsafe *__param_self_).last = ((__local_arr__goto_411_15 as *mut stc_word_list_node)))
            unsafe { (*__param_self_).sort_lowhigh((0 as i64), ((__local_len__goto_410_13 - 1) as i64)) }
            ((unsafe *__param_self_).last = __local_keep__goto_412_14)
            (__local_i__goto_426_10 = unsafe { (*(((&raw const (*__param_self_) as *const stc_word_list) as *mut stc_word_list) as *const stc_word_list)).begin() })
            goto '__ci_bb_10
        }

        '__ci_bb_5 {
            (__local_cap_n__goto_415_21 = ((((__local_cap__goto_410_22 + (__local_cap__goto_410_22 / 2)) + 8) as i64)))
            (__local_p__goto_411_28 = (((with_realloc(((__local_arr__goto_411_15 as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_cap_n__goto_415_21 * (sizeof[i64]() as i64)) as i64) else: ((__local_cap__goto_410_22 * (sizeof[i64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i64)))
            if ((if __local_p__goto_411_28 == null: 1 else: 0) != 0) {
                goto '__ci_bb_7
            } else {
                goto '__ci_bb_8
            }
        }

        '__ci_bb_6 {
            (__ci_expr_old_0 = __local_len__goto_410_13)
            (__local_len__goto_410_13 = __local_len__goto_410_13 + 1)
            ((unsafe __local_arr__goto_411_15[__ci_expr_old_0]) = (unsafe *((*(&raw const __local_i__goto_413_10 as *const stc_word_list_iter)).ref)))
            goto '__ci_bb_3
        }

        '__ci_bb_7 {
            goto '__ci_bb_9
        }

        '__ci_bb_8 {
            (__local_arr__goto_411_15 = __local_p__goto_411_28)
            (__local_cap__goto_410_22 = __local_cap_n__goto_415_21)
            goto '__ci_bb_6
        }

        '__ci_bb_9 {
            with_free(((__local_arr__goto_411_15 as *mut c_void) as *mut u8))
            return ((__local_p__goto_411_28 != null))
        }

        '__ci_bb_10 {
            if ((unsafe *(&raw const __local_i__goto_426_10 as *const stc_word_list_iter)).ref != null) {
                goto '__ci_bb_11
            } else {
                goto '__ci_bb_13
            }
        }

        '__ci_bb_11 {
            (__ci_expr_old_1 = __local_p__goto_411_28)
            (__local_p__goto_411_28 = __local_p__goto_411_28 + 1)
            ((unsafe *((*(&raw const __local_i__goto_426_10 as *const stc_word_list_iter)).ref)) = (unsafe *__ci_expr_old_1))
            goto '__ci_bb_12
        }

        '__ci_bb_12 {
            unsafe { (*(&raw mut __local_i__goto_426_10 as *mut stc_word_list_iter)).next() }
            goto '__ci_bb_10
        }

        '__ci_bb_13 {
            goto '__ci_bb_9
        }

        __ci_unreachable()

    }

    pub mut fn reverse() -> Unit {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_rev: stc_word_list = (unsafe *__param_self_)

        (__local_rev.last = ((null as *mut stc_word_list_node)))

        while ((unsafe *__param_self_).last != null) {
            var __local_node: *mut stc_word_list_node = unsafe { stc_word_list_unlink_after_node(__param_self_, (*__param_self_).last) }

            unsafe { stc_word_list_insert_after_node((&raw mut __local_rev as *mut stc_word_list), (*(&raw const __local_rev as *const stc_word_list)).last, __local_node) }

        }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __local_rev as *const u8), sizeof[stc_word_list]())

    }

    pub mut fn split_off(__param_it1: stc_word_list_iter, __param_it2: stc_word_list_iter) -> stc_word_list {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_lst: stc_word_list = (unsafe *__param_self_)

        (__local_lst.last = ((null as *mut stc_word_list_node)))

        if ((if (unsafe *(&raw const __param_it1 as *const stc_word_list_iter)).ref == (unsafe *(&raw const __param_it2 as *const stc_word_list_iter)).ref: 1 else: 0) != 0) {
            return __local_lst
        }

        var __local_p1: *mut stc_word_list_node = (unsafe *(&raw const __param_it1 as *const stc_word_list_iter)).prev

        var __local_p2: *mut stc_word_list_node = (if (unsafe *(&raw const __param_it2 as *const stc_word_list_iter)).ref != null: (unsafe *(&raw const __param_it2 as *const stc_word_list_iter)).prev else: (unsafe *__param_self_).last)


        ((unsafe *__local_p1).next = (unsafe *__local_p2).next)

        ((unsafe *__local_p2).next = (((if 1 != 0: (unsafe *(&raw const __param_it1 as *const stc_word_list_iter)).ref else: (null as *mut i64)) as *mut stc_word_list_node)))

        if ((if (unsafe *__param_self_).last == __local_p2: 1 else: 0) != 0) {
            ((unsafe *__param_self_).last = (if (if __local_p1 == __local_p2: 1 else: 0) != 0: (null as *mut stc_word_list_node) else: __local_p1))
        }

        (__local_lst.last = __local_p2)

        return __local_lst

    }

    pub mut fn unlink_front_node() -> *mut stc_word_list_node {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        return ((unsafe { stc_word_list_unlink_after_node(__param_self_, (*__param_self_).last) } as *mut stc_word_list_node))

    }

    pub fn value_clone(__param_val: i64) -> i64 {
        let __param_self_: *const stc_word_list = self as *const stc_word_list

        return __param_val

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_word_list = self as *const stc_word_list
        return (((((unsafe *__param_self_).last == null)) as bool))

    }

    pub mut fn push(__param_value: i64) -> *mut i64 {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        return ((unsafe { (*__param_self_).push_back(__param_value) } as *mut i64))

    }

    pub mut fn pop_front() {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_word_list)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_list_pop_front".ptr, c"list.h".ptr, (162 as i32), c"!stc_word_list_is_empty(self)".ptr)
        } else {
            0
        }

        unsafe { stc_word_list_erase_after_node(__param_self_, (*__param_self_).last) }

    }

    pub mut fn move_() -> stc_word_list {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_m: stc_word_list = (unsafe *__param_self_)

        ((unsafe *__param_self_).last = ((null as *mut stc_word_list_node)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_word_list) -> Unit {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        unsafe { stc_word_list_drop((__param_self_ as *const stc_word_list)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_list]())

    }

    pub fn count() -> i64 {
        let __param_self_: *const stc_word_list = self as *const stc_word_list
        var __local_n: i64 = ((1 as i64))

        var __local_node: *const stc_word_list_node = (((unsafe *__param_self_).last as *const stc_word_list_node))

        if ((if __local_node == null: 1 else: 0) != 0) {
            return ((0 as i64))
        }

        while true {
            (__local_node = (((unsafe *__local_node).next as *const stc_word_list_node)))

            if (not ((if __local_node != (unsafe *__param_self_).last: 1 else: 0) != 0)) {
                break
            }

            (__local_n = __local_n + 1)

        }

        return __local_n

    }

    pub fn begin() -> stc_word_list_iter {
        let __param_self_: *const stc_word_list = self as *const stc_word_list
        var __local_head: *mut i64 = (if (unsafe *__param_self_).last != null: ((&raw const (unsafe *(*(*__param_self_).last).next).value as *const i64) as *mut i64) else: (null as *mut i64))

        return ((stc_word_list_iter { ref: __local_head, _last: (&raw const (unsafe *__param_self_).last as *const *mut stc_word_list_node), prev: (unsafe *__param_self_).last } as stc_word_list_iter))

    }

    pub fn end() -> stc_word_list_iter {
        let __param_self_: *const stc_word_list = self as *const stc_word_list

        return ((stc_word_list_iter.zeroed() as stc_word_list_iter))

    }

    pub mut fn sort_lowhigh(__param_lo: i64, __param_hi: i64) {
        let __param_self_: *mut stc_word_list = self as *mut stc_word_list
        var __local_lo = __param_lo
        var __local_i: i64 = __local_lo

        var __local_j: i64


        while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
            var __local_pivot: i64 = (unsafe *((&raw const (((*__param_self_).last as *mut i64)[(__local_lo + (((__param_hi - __local_lo) * 7) / 16))]) as *const i64) as *mut i64))

            var __local_rx: i64


            (__local_j = __param_hi)

            loop {
                loop {
                    (__local_rx = (unsafe *((&raw const (((*__param_self_).last as *mut i64)[__local_i]) as *const i64) as *mut i64)))

                    var __ci_expr_logic_0: i32 = 0

                    if ((if (unsafe *(&raw mut __local_rx as *mut i64)) < (unsafe *(&raw mut __local_pivot as *mut i64)): 1 else: 0) != 0) {
                        (__local_i = __local_i + 1)

                        (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                    }

                    if not ((__ci_expr_logic_0 != 0)) {
                        break
                    }
                }

                loop {
                    (__local_rx = (unsafe *((&raw const (((*__param_self_).last as *mut i64)[__local_j]) as *const i64) as *mut i64)))

                    var __ci_expr_logic_1: i32 = 0

                    if ((if (unsafe *(&raw mut __local_pivot as *mut i64)) < (unsafe *(&raw mut __local_rx as *mut i64)): 1 else: 0) != 0) {
                        (__local_j = __local_j - 1)

                        (__ci_expr_logic_1 = (if __local_j != 0: 1 else: 0))

                    }

                    if not ((__ci_expr_logic_1 != 0)) {
                        break
                    }
                }

                if ((if __local_i > __local_j: 1 else: 0) != 0) {
                    break
                }

                loop {
                    var __local__xp: *mut i64 = (((&raw const (unsafe ((*__param_self_).last as *mut i64)[__local_i]) as *const i64) as *mut i64))

                    var __local__yp: *mut i64 = (((&raw const (unsafe ((*__param_self_).last as *mut i64)[__local_j]) as *const i64) as *mut i64))


                    var __local__tv: i64 = (unsafe *__local__xp)

                    ((unsafe *__local__xp) = (unsafe *__local__yp))

                    ((unsafe *__local__yp) = __local__tv)

                    if not ((0 != 0)) {
                        break
                    }
                }

                (__local_i = __local_i + 1)

                (__local_j = __local_j - 1)

                if not (((if __local_i <= __local_j: 1 else: 0) != 0)) {
                    break
                }
            }

            if ((if (__local_j - __local_lo) > (__param_hi - __local_i): 1 else: 0) != 0) {
                loop {
                    var __local__xp_1: *mut i64 = ((&raw mut __local_lo as *mut i64))

                    var __local__yp_1: *mut i64 = ((&raw mut __local_i as *mut i64))


                    var __local__tv_1: i64 = (unsafe *__local__xp_1)

                    ((unsafe *__local__xp_1) = (unsafe *__local__yp_1))

                    ((unsafe *__local__yp_1) = __local__tv_1)

                    if not ((0 != 0)) {
                        break
                    }
                }

                loop {
                    var __local__xp_2: *mut i64 = ((&raw mut __param_hi as *mut i64))

                    var __local__yp_2: *mut i64 = ((&raw mut __local_j as *mut i64))


                    var __local__tv_2: i64 = (unsafe *__local__xp_2)

                    ((unsafe *__local__xp_2) = (unsafe *__local__yp_2))

                    ((unsafe *__local__yp_2) = __local__tv_2)

                    if not ((0 != 0)) {
                        break
                    }
                }

            }

            if ((if (__local_j - __local_lo) > 64: 1 else: 0) != 0) {
                unsafe { (*__param_self_).sort_lowhigh(__local_lo, __local_j) }
            } else {
                if ((if __local_j > __local_lo: 1 else: 0) != 0) {
                    unsafe { stc_word_list_insertsort_lowhigh(__param_self_, __local_lo, __local_j) }
                }
            }

            (__local_lo = __local_i)

        }

    }

}

impl stc_word_list_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_word_list_iter = self as *mut stc_word_list_iter
        var __local_node: *mut stc_word_list_node = with 0 as __ci_expr_seq_5 {
            ((unsafe *__param_it_).prev = (((if 1 != 0: (unsafe *__param_it_).ref else: (null as *mut i64)) as *mut stc_word_list_node)))
            (unsafe *__param_it_).prev
        }

        ((unsafe *__param_it_).ref = (if (if __local_node == (unsafe *((*__param_it_)._last)): 1 else: 0) != 0: (null as *mut i64) else: ((&raw const (unsafe *(*__local_node).next).value as *const i64) as *mut i64)))

    }

}

impl stc_word_pqueue {
    pub fn make_heap() {
        let __param_self_: *mut stc_word_pqueue = (self as *const stc_word_pqueue) as *mut stc_word_pqueue
        var __local_n: i64 = (unsafe *__param_self_).size

        var __local_k: i64 = (((__local_n / 2) as i64))

        while ((if __local_k != 0: 1 else: 0) != 0) {
            unsafe { (*__param_self_).sift_down_(__local_k, __local_n) }

            (__local_k = __local_k - 1)

        }


    }

    pub mut fn erase_at(__param_idx: i64) {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue

        var __local_n: i64 = with 0 as __ci_expr_seq_10 {
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)
            (unsafe *__param_self_).size
        }

        ((unsafe (*__param_self_).data[__param_idx]) = (((unsafe (*__param_self_).data[__local_n]) as i64)))

        unsafe { (*__param_self_).sift_down_(((__param_idx + 1) as i64), __local_n) }

    }

    pub mut fn push(__param_value: i64) -> *mut i64 {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        if ((if (unsafe *__param_self_).size == (unsafe *__param_self_).capacity: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve((((((*__param_self_).size * 3) / 2) + 4) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut i64))
            }
        }

        var __local_arr: *mut i64 = ((unsafe *__param_self_).data - ((1 as i64) as usize))

        var __local_c: i64 = with 0 as __ci_expr_seq_9 {
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size + 1)
            (unsafe *__param_self_).size
        }

        while true {
            var __ci_expr_logic_0: i32 = 0

            if ((if __local_c > 1: 1 else: 0) != 0) {
                (__ci_expr_logic_0 = (if (if (unsafe *((&raw const (__local_arr[(__local_c / 2)]) as *const i64) as *mut i64)) < (unsafe *(&raw mut __param_value as *mut i64)): 1 else: 0) != 0: 1 else: 0))
            }

            if (not (__ci_expr_logic_0 != 0)) {
                break
            }

            ((unsafe __local_arr[__local_c]) = (((unsafe __local_arr[(__local_c / 2)]) as i64)))

            (__local_c = __local_c / 2)

        }

        ((unsafe __local_arr[__local_c]) = __param_value)

        return (__local_arr + ((__local_c as i64) as usize))

    }

    pub fn sift_down_(__param_idx: i64, __param_n: i64) {
        let __param_self_: *mut stc_word_pqueue = (self as *const stc_word_pqueue) as *mut stc_word_pqueue
        var __local_t: i64

        var __local_arr: *mut i64 = ((unsafe *__param_self_).data - ((1 as i64) as usize))


        var __local_r: i64 = __param_idx

        var __local_c: i64 = (((__param_idx * 2) as i64))


        while ((if __local_c <= __param_n: 1 else: 0) != 0) {
            (__local_c = __local_c + (if (unsafe *((&raw const (__local_arr[__local_c]) as *const i64) as *mut i64)) < (unsafe *((&raw const (__local_arr[(__local_c + (if __local_c < __param_n: 1 else: 0))]) as *const i64) as *mut i64)): 1 else: 0))

            if ((if not ((if (unsafe *((&raw const (__local_arr[__local_r]) as *const i64) as *mut i64)) < (unsafe *((&raw const (__local_arr[__local_c]) as *const i64) as *mut i64)): 1 else: 0) != 0): 1 else: 0) != 0) {
                return
            }

            (__local_t = (((unsafe __local_arr[__local_r]) as i64)))

            ((unsafe __local_arr[__local_r]) = (((unsafe __local_arr[__local_c]) as i64)))

            (__local_r = __local_c)

            ((unsafe __local_arr[__local_r]) = __local_t)



            (__local_c = __local_c * 2)

        }


    }

    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (unsafe *__param_self_).size else: __param_cap) as i64))

        if ((((if __param_cap > (unsafe *__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (unsafe *__param_self_).capacity: 1 else: 0) as i32)) != 0) {
            var __local_d: *mut i64 = (((with_realloc((((unsafe *__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[i64]() as i64)) as i64) else: (((unsafe *__param_self_).capacity * (sizeof[i64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut i64))

            if ((if __local_d == null: 1 else: 0) != 0) {
                return ((false as bool))
            }

            ((unsafe *__param_self_).data = __local_d)

            ((unsafe *__param_self_).capacity = __local_n)

        }

        return (((((unsafe *__param_self_).data != null)) as bool))

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        unsafe { (*__param_self_).reserve((9223372036854775807 as i64)) }

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        var __local_i: i64 = (unsafe *__param_self_).size

        while true {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i - 1)

            if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
                break
            }

        }

        ((unsafe *__param_self_).size = ((0 as i64)))

    }

    pub mut fn move_() -> stc_word_pqueue {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        var __local_m: stc_word_pqueue = (unsafe *__param_self_)

        ((unsafe *__param_self_).capacity = ((0 as i64)))

        ((unsafe *__param_self_).size = (unsafe *__param_self_).capacity)


        ((unsafe *__param_self_).data = ((null as *mut i64)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_word_pqueue) -> Unit {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        unsafe { stc_word_pqueue_drop((__param_self_ as *const stc_word_pqueue)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_pqueue]())

    }

    pub fn size() -> i64 {
        let __param_q: *const stc_word_pqueue = self as *const stc_word_pqueue
        return (unsafe *__param_q).size

    }

    pub fn is_empty() -> bool {
        let __param_q: *const stc_word_pqueue = self as *const stc_word_pqueue
        return ((((not ((unsafe *__param_q).size != 0))) as bool))

    }

    pub fn capacity() -> i64 {
        let __param_q: *const stc_word_pqueue = self as *const stc_word_pqueue
        return (unsafe *__param_q).capacity

    }

    pub mut fn pop() {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_pqueue_pop".ptr, c"pqueue.h".ptr, (120 as i32), c"self->size".ptr)
        } else {
            0
        }

        unsafe { (*__param_self_).erase_at((0 as i64)) }

    }

    pub mut fn pull() -> i64 {
        let __param_self_: *mut stc_word_pqueue = self as *mut stc_word_pqueue
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_pqueue_pull".ptr, c"pqueue.h".ptr, (123 as i32), c"self->size".ptr)
        } else {
            0
        }

        var __local_v: i64 = (((unsafe (*__param_self_).data[0]) as i64))

        unsafe { (*__param_self_).erase_at((0 as i64)) }

        return __local_v

    }

    pub fn value_clone(__param_val: i64) -> i64 {
        let __param_self_: *const stc_word_pqueue = self as *const stc_word_pqueue

        return __param_val

    }

}

impl stc_word_queue {
    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        var __local_oldpow2: i64 = ((((unsafe *__param_self_).capmask + (((unsafe *__param_self_).capmask as i64) & (1 as i64))) as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__param_cap + 1) as i64)) as i64))

        if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
            return (((((unsafe *__param_self_).cbuf != null)) as bool))
        }

        var __local_d: *mut u64 = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[u64]() as i64)) as i64) else: ((__local_oldpow2 * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        var __local_head: i64 = (((__local_oldpow2 - (unsafe *__param_self_).start) as i64))

        if (not ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0)) {
            if ((if __local_head < (unsafe *__param_self_).end: 1 else: 0) != 0) {
                with_memcpy(((((__local_d + ((__local_newpow2 as i64) as usize)) - ((__local_head as i64) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).start = (((__local_newpow2 - __local_head) as i64)))

            } else {
                with_memcpy((((__local_d + ((__local_oldpow2 as i64) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((unsafe *__param_self_).end * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

                ((unsafe *__param_self_).end = (unsafe *__param_self_).end + __local_oldpow2)

            }
        }

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

        ((unsafe *__param_self_).cbuf = __local_d)

        return ((true as bool))

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        var __local_i: stc_word_queue_iter = unsafe { (*(((&raw const (*__param_self_) as *const stc_word_queue) as *mut stc_word_queue) as *const stc_word_queue)).begin() }

        while ((unsafe *(&raw const __local_i as *const stc_word_queue_iter)).ref != null) {


            unsafe { (*(&raw mut __local_i as *mut stc_word_queue_iter)).next() }

        }


        ((unsafe *__param_self_).start = ((0 as i64)))

        ((unsafe *__param_self_).end = ((0 as i64)))


    }

    pub mut fn push(__param_value: u64) -> *mut u64 {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        var __local_end: i64 = ((((((unsafe *__param_self_).end + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        if ((if __local_end == (unsafe *__param_self_).start: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve((((*__param_self_).capmask + 3) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut u64))
            }

            (__local_end = ((((((unsafe *__param_self_).end + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        }

        var __local_v: *mut u64 = ((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).end as i64) as usize))

        ((unsafe *__param_self_).end = __local_end)

        ((unsafe *__local_v) = __param_value)

        return __local_v

    }

    pub mut fn shrink_to_fit() {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        var __local_sz: i64 = ((unsafe { (*(__param_self_ as *const stc_word_queue)).size() } as i64))

        var __local_newpow2: i64 = ((c_next_pow2(((__local_sz + 1) as i64)) as i64))

        if ((if __local_newpow2 > (unsafe *__param_self_).capmask: 1 else: 0) != 0) {
            return
        }

        if ((if (unsafe *__param_self_).start <= (unsafe *__param_self_).end: 1 else: 0) != 0) {
            with_memmove((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = ((0 as i64)))

            ((unsafe *__param_self_).end = __local_sz)


        } else {
            var __local_n: i64 = (((((unsafe *__param_self_).capmask - (unsafe *__param_self_).start) + 1) as i64))

            with_memmove(((((unsafe *__param_self_).cbuf + (((__local_newpow2 - __local_n) as i64) as usize)) as *mut c_void) as *mut u8), ((((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((unsafe *__param_self_).start = (((__local_newpow2 - __local_n) as i64)))

        }

        ((unsafe *__param_self_).cbuf = (((with_realloc((((unsafe *__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[u64]() as i64)) as i64) else: ((((unsafe *__param_self_).capmask + 1) * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

        ((unsafe *__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

    }

    pub fn value_clone(__param_val: u64) -> u64 {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue

        return __param_val

    }

    pub fn size() -> i64 {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue
        return ((((unsafe *__param_self_).end - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue
        return (unsafe *__param_self_).capmask

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue
        return (((((unsafe *__param_self_).start == (unsafe *__param_self_).end)) as bool))

    }

    pub mut fn move_() -> stc_word_queue {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        var __local_m: stc_word_queue = (unsafe *__param_self_)

        ((unsafe *__param_self_).end = ((0 as i64)))

        ((unsafe *__param_self_).start = (unsafe *__param_self_).end)

        ((unsafe *__param_self_).capmask = (unsafe *__param_self_).start)


        ((unsafe *__param_self_).cbuf = ((null as *mut u64)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_word_queue) -> Unit {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        unsafe { stc_word_queue_drop((__param_self_ as *const stc_word_queue)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_queue]())

    }

    pub mut fn pop() {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_word_queue)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_queue_pop".ptr, c"queue_prv.h".ptr, (133 as i32), c"!stc_word_queue_is_empty(self)".ptr)
        } else {
            0
        }


        ((unsafe *__param_self_).start = ((((((unsafe *__param_self_).start + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

    pub mut fn pull() -> u64 {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        if (((if not ((if not unsafe { (*(__param_self_ as *const stc_word_queue)).is_empty() }: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_queue_pull".ptr, c"queue_prv.h".ptr, (139 as i32), c"!stc_word_queue_is_empty(self)".ptr)
        } else {
            0
        }

        var __local_s: i64 = (unsafe *__param_self_).start

        ((unsafe *__param_self_).start = (((((__local_s + 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

        return (unsafe (*__param_self_).cbuf[__local_s])

    }

    pub fn begin() -> stc_word_queue_iter {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue
        return ((stc_word_queue_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut u64) else: ((unsafe *__param_self_).cbuf + (((unsafe *__param_self_).start as i64) as usize))), pos: (unsafe *__param_self_).start, _s: __param_self_ } as stc_word_queue_iter))

    }

    pub fn rbegin() -> stc_word_queue_iter {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue
        var __local_pos: i64 = ((((((unsafe *__param_self_).end - 1) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64))

        return ((stc_word_queue_iter { ref: (if unsafe { (*__param_self_).is_empty() }: ((null) as *mut u64) else: ((unsafe *__param_self_).cbuf + ((__local_pos as i64) as usize))), pos: __local_pos, _s: __param_self_ } as stc_word_queue_iter))

    }

    pub fn end() -> stc_word_queue_iter {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue

        return ((stc_word_queue_iter.zeroed() as stc_word_queue_iter))

    }

    pub fn rend() -> stc_word_queue_iter {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue

        return ((stc_word_queue_iter.zeroed() as stc_word_queue_iter))

    }

    pub fn index(__param_it_: stc_word_queue_iter) -> i64 {
        let __param_self_: *const stc_word_queue = self as *const stc_word_queue
        return ((((unsafe *(&raw const __param_it_ as *const stc_word_queue_iter)).pos - (unsafe *__param_self_).start) as i64) & ((unsafe *__param_self_).capmask as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut stc_word_queue = self as *mut stc_word_queue
        ((unsafe *__param_self_).end = ((((((unsafe *__param_self_).end + __param_n) as i64) & ((unsafe *__param_self_).capmask as i64)) as i64)))

    }

}

impl stc_word_queue_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_word_queue_iter = self as *mut stc_word_queue_iter
        if ((if (unsafe *__param_it_).pos != (unsafe *(*__param_it_)._s).capmask: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

            ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos + 1)

        } else {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - (((unsafe *__param_it_).pos as i64) as usize))

            ((unsafe *__param_it_).pos = ((0 as i64)))

        }

        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut u64)))
        }

    }

    pub mut fn rnext() -> Unit {
        let __param_it_: *mut stc_word_queue_iter = self as *mut stc_word_queue_iter
        if ((if (unsafe *__param_it_).pos == (unsafe *(*__param_it_)._s).start: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut u64)))
        } else {
            if ((if (unsafe *__param_it_).pos != 0: 1 else: 0) != 0) {
                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

                ((unsafe *__param_it_).pos = (unsafe *__param_it_).pos - 1)

            } else {
                ((unsafe *__param_it_).pos = (unsafe *(*__param_it_)._s).capmask)

                ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + (((unsafe *__param_it_).pos as i64) as usize))

            }
        }

    }

}

impl stc_word_set {
    pub mut fn clear() -> Unit {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        if ((if (unsafe *__param_self_).meta == null: 1 else: 0) != 0) {
            return
        }

        unsafe { stc_word_set_wipe_(__param_self_) }

        ((unsafe *__param_self_).size = ((0 as i64)))

        with_memset((((unsafe *__param_self_).meta as *mut c_void) as *mut u8), (0 as i32), (((if 1 != 0: (((sizeof[hmap_meta]() as i64) * (unsafe *__param_self_).bucket_count) as i64) else: (-1 as i64)) as u64) as i64))

    }

    pub mut fn reserve(__param__cap: i64) -> bool {
        let __param__self: *mut stc_word_set = self as *mut stc_word_set
        var __local__newcap: i64 = (((if (if __param__cap == 9223372036854775807: 1 else: 0) != 0: (unsafe *__param__self).size else: __param__cap) as i64))

        var __local__newbucks: i64 = ((((((__local__newcap as f32) / i_max_load_factor) as i64) + 4) as i64))

        (__local__newbucks = ((c_next_pow2(__local__newbucks) as i64)))

        var __ci_expr_logic_0: i32

        if ((if __local__newbucks == (unsafe *__param__self).bucket_count: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if __param__cap <= (((((unsafe *__param__self).bucket_count as f32) * i_max_load_factor) as i64)): 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return ((true as bool))
        }


        var __local_map: stc_word_set = (unsafe *__param__self)

        var __local_self_: *mut stc_word_set = ((&raw mut __local_map as *mut stc_word_set))



        (__local_map.table = (((with_alloc((((if 1 != 0: ((__local__newbucks * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

        (__local_map.meta = (((with_alloc_zeroed((((if 1 != 0: ((__local__newbucks + 1) as i64) else: (-1 as i64)) as u64) as i64), (((if 1 != 0: (sizeof[hmap_meta]() as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut hmap_meta)))

        (__local_map.bucket_count = __local__newbucks)

        var __local_ok: bool = with 0 as __ci_expr_seq_26 {
            var __ci_expr_logic_1: i32 = 0
            if ((unsafe *(&raw const __local_map as *const stc_word_set)).table != null) {
                (__ci_expr_logic_1 = (if (unsafe *(&raw const __local_map as *const stc_word_set)).meta != null: 1 else: 0))
            }
            (__ci_expr_logic_1 != 0)
        }

        if __local_ok {
            ((unsafe __local_map.meta[__local__newbucks])).set_dist(((1023 as u16)))

            var __local_d: *const u64 = (((unsafe *__param__self).table as *const u64))

            var __local_m: *const hmap_meta = (((unsafe *__param__self).meta as *const hmap_meta))

            var __local_i: i64 = ((0 as i64))

            while ((if __local_i < (unsafe *__param__self).bucket_count: 1 else: 0) != 0) {
                if ((if ((unsafe __local_m[__local_i])).dist() != 0: 1 else: 0) != 0) {
                    var __local_r: u64 = (unsafe *__local_d)

                    ((unsafe *(unsafe { stc_word_set_bucket_insert_(((&raw mut __local_map as *mut stc_word_set) as *const stc_word_set), ((&raw mut __local_r as *mut u64) as *const u64)) }.ref)) = (unsafe *__local_d))

                }

                (__local_i = __local_i + 1)

                (__local_d = __local_d + 1)


            }


            loop {
                var __local__xp: *mut stc_word_set = __param__self

                var __local__yp: *mut stc_word_set = ((&raw mut __local_map as *mut stc_word_set))


                var __local__tv: stc_word_set = (unsafe *__local__xp)

                with_memcpy((&raw mut (unsafe *__local__xp) as *mut u8), (&raw const (unsafe *__local__yp) as *const u8), sizeof[stc_word_set]())

                with_memcpy((&raw mut (unsafe *__local__yp) as *mut u8), (&raw const __local__tv as *const u8), sizeof[stc_word_set]())

                if not ((0 != 0)) {
                    break
                }
            }

        }

        with_free((((unsafe *(&raw const __local_map as *const stc_word_set)).meta as *mut c_void) as *mut u8))

        with_free((((unsafe *(&raw const __local_map as *const stc_word_set)).table as *mut c_void) as *mut u8))

        return __local_ok

    }

    pub fn max_load_factor() -> f32 {
        let __param_self_: *const stc_word_set = self as *const stc_word_set

        return i_max_load_factor

    }

    pub fn capacity() -> i64 {
        let __param_map: *const stc_word_set = self as *const stc_word_set
        return (((((unsafe *__param_map).bucket_count as f32) * i_max_load_factor) as i64))

    }

    pub fn is_empty() -> bool {
        let __param_map: *const stc_word_set = self as *const stc_word_set
        return ((((not ((unsafe *__param_map).size != 0))) as bool))

    }

    pub fn size() -> i64 {
        let __param_map: *const stc_word_set = self as *const stc_word_set
        return (unsafe *__param_map).size

    }

    pub fn bucket_count() -> i64 {
        let __param_map: *mut stc_word_set = (self as *const stc_word_set) as *mut stc_word_set
        return (unsafe *__param_map).bucket_count

    }

    pub fn contains(__param_rkey: u64) -> bool {
        let __param_self_: *const stc_word_set = self as *const stc_word_set
        var __ci_expr_logic_0: i32 = 0

        if ((unsafe *__param_self_).size != 0) {
            (__ci_expr_logic_0 = (if unsafe { stc_word_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut u64) as *const u64)) }.ref != null: 1 else: 0))
        }

        return (((__ci_expr_logic_0 != 0) as bool))


    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        unsafe { (*__param_self_).reserve((9223372036854775807 as i64)) }

    }

    pub mut fn insert_entry_(__param_rkey: u64) -> stc_word_set_result {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        if ((if (unsafe *__param_self_).size >= (((((unsafe *__param_self_).bucket_count as f32) * i_max_load_factor) as i64)): 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve((((((*__param_self_).size * 3) / 2) + 2) as i64)) }: 1 else: 0) != 0) {
                return ((stc_word_set_result.zeroed() as stc_word_set_result))
            }
        }

        var __local_res: stc_word_set_result = unsafe { stc_word_set_bucket_insert_((__param_self_ as *const stc_word_set), ((&raw mut __param_rkey as *mut u64) as *const u64)) }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + ((unsafe *(&raw const __local_res as *const stc_word_set_result)).inserted as i32))

        return __local_res

    }

    pub fn value_clone(__param__val: u64) -> u64 {
        let __param_self_: *const stc_word_set = self as *const stc_word_set

        ((unsafe *(&raw mut __param__val as *mut u64)) = (unsafe *(&raw mut __param__val as *mut u64)))

        return __param__val

    }

    pub mut fn move_() -> stc_word_set {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        var __local_m: stc_word_set = (unsafe *__param_self_)

        ((unsafe *__param_self_).size = ((0 as i64)))

        ((unsafe *__param_self_).bucket_count = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).meta = ((null as *mut hmap_meta)))

        ((unsafe *__param_self_).table = ((null as *mut u64)))

        return __local_m

    }

    pub mut fn take(__param_unowned: stc_word_set) -> Unit {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        unsafe { stc_word_set_drop((__param_self_ as *const stc_word_set)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_set]())

    }

    pub mut fn insert(__param__key: u64) -> stc_word_set_result {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        var __local__res: stc_word_set_result = unsafe { (*__param_self_).insert_entry_((*(&raw mut __param__key as *mut u64))) }

        if (unsafe *(&raw const __local__res as *const stc_word_set_result)).inserted {
            ((unsafe *((*(&raw const __local__res as *const stc_word_set_result)).ref)) = __param__key)

        } else {

        }

        return __local__res

    }

    pub mut fn push(__param__val: u64) -> *mut u64 {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        var __local__res: stc_word_set_result = unsafe { (*__param_self_).insert_entry_((*(&raw mut __param__val as *mut u64))) }

        if ((if not (unsafe *(&raw const __local__res as *const stc_word_set_result)).inserted: 1 else: 0) != 0) {
            unsafe { stc_word_set_value_drop((__param_self_ as *const stc_word_set), (*(&raw const __local__res as *const stc_word_set_result)).ref) }
        }

        ((unsafe *((*(&raw const __local__res as *const stc_word_set_result)).ref)) = __param__val)

        return (unsafe *(&raw const __local__res as *const stc_word_set_result)).ref

    }

    pub fn begin() -> stc_word_set_iter {
        let __param_self_: *const stc_word_set = self as *const stc_word_set
        var __local_it_: stc_word_set_iter = stc_word_set_iter { ref: (unsafe *__param_self_).table, _end: (unsafe *__param_self_).table, _mref: (unsafe *__param_self_).meta }

        if ((if (unsafe *(&raw const __local_it_ as *const stc_word_set_iter)).ref == null: 1 else: 0) != 0) {
            return __local_it_
        }

        (__local_it_._end = (unsafe *(&raw const __local_it_ as *const stc_word_set_iter))._end + (((unsafe *__param_self_).bucket_count as i64) as usize))

        while ((if (unsafe *(*(&raw const __local_it_ as *const stc_word_set_iter))._mref).dist() == 0: 1 else: 0) != 0) {
            (__local_it_.ref = (unsafe *(&raw const __local_it_ as *const stc_word_set_iter)).ref + 1)

            (__local_it_._mref = (unsafe *(&raw const __local_it_ as *const stc_word_set_iter))._mref + 1)

        }

        if ((if (unsafe *(&raw const __local_it_ as *const stc_word_set_iter)).ref == (unsafe *(&raw const __local_it_ as *const stc_word_set_iter))._end: 1 else: 0) != 0) {
            (__local_it_.ref = ((null as *mut u64)))
        }

        return __local_it_

    }

    pub fn end() -> stc_word_set_iter {
        let __param_self_: *const stc_word_set = self as *const stc_word_set

        return ((stc_word_set_iter.zeroed() as stc_word_set_iter))

    }

    pub fn find(__param_rkey: u64) -> stc_word_set_iter {
        let __param_self_: *const stc_word_set = self as *const stc_word_set
        var __local_ref: *mut u64

        var __ci_expr_logic_0: i32 = 0

        if ((if (unsafe *__param_self_).size != 0: 1 else: 0) != 0) {
            (__local_ref = unsafe { stc_word_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut u64) as *const u64)) }.ref)

            (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

        }

        if (__ci_expr_logic_0 != 0) {
            return ((stc_word_set_iter { ref: __local_ref, _end: ((&raw const (unsafe (*__param_self_).table[(*__param_self_).bucket_count]) as *const u64) as *mut u64), _mref: ((&raw const (unsafe (*__param_self_).meta[((((__local_ref as usize) -% ((*__param_self_).table as usize)) as i64) / (sizeof[u64]() as i64))]) as *const hmap_meta) as *mut hmap_meta) } as stc_word_set_iter))
        }


        return unsafe { (*__param_self_).end() }

    }

    pub mut fn erase(__param_rkey: u64) -> i32 {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        var __local_ref: *mut u64

        var __ci_expr_logic_0: i32 = 0

        if ((if (unsafe *__param_self_).size != 0: 1 else: 0) != 0) {
            (__local_ref = unsafe { stc_word_set_bucket_lookup_((__param_self_ as *const stc_word_set), ((&raw mut __param_rkey as *mut u64) as *const u64)) }.ref)

            (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

        }

        if (__ci_expr_logic_0 != 0) {
            unsafe { stc_word_set_erase_entry(__param_self_, __local_ref) }

            return 1

        }


        return 0

    }

    pub mut fn erase_at(__param_it_: stc_word_set_iter) -> stc_word_set_iter {
        let __param_self_: *mut stc_word_set = self as *mut stc_word_set
        unsafe { stc_word_set_erase_entry(__param_self_, (*(&raw const __param_it_ as *const stc_word_set_iter)).ref) }

        if ((if (unsafe *(*(&raw const __param_it_ as *const stc_word_set_iter))._mref).dist() == 0: 1 else: 0) != 0) {
            unsafe { (*(&raw mut __param_it_ as *mut stc_word_set_iter)).next() }
        }

        return __param_it_

    }

}

impl stc_word_set_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_word_set_iter = self as *mut stc_word_set_iter
        while true {
            ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

            ((unsafe *__param_it_)._mref = (unsafe *__param_it_)._mref + 1)

            if (not ((if (unsafe *(*__param_it_)._mref).dist() == 0: 1 else: 0) != 0)) {
                break
            }

        }

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_)._end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut u64)))
        }

    }

}

impl stc_word_stack {
    pub mut fn move_() -> stc_word_stack {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        var __local_m: stc_word_stack = (unsafe *__param_self_)

        ((unsafe *__param_self_).size = ((0 as i64)))

        ((unsafe *__param_self_).capacity = (unsafe *__param_self_).size)


        ((unsafe *__param_self_).data = ((null as *mut u64)))

        return __local_m

    }

    pub fn capacity() -> i64 {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack
        return (unsafe *__param_self_).capacity

    }

    pub mut fn reserve(__param_cap: i64) -> bool {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (unsafe *__param_self_).size else: __param_cap) as i64))

        if ((((if __param_cap > (unsafe *__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (unsafe *__param_self_).capacity: 1 else: 0) as i32)) != 0) {
            var __local_d: *mut u64 = (((with_realloc((((unsafe *__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[u64]() as i64)) as i64) else: (((unsafe *__param_self_).capacity * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64))

            if ((if __local_d == null: 1 else: 0) != 0) {
                return ((false as bool))
            }

            ((unsafe *__param_self_).data = __local_d)

            ((unsafe *__param_self_).capacity = __local_n)

        }

        return (((((unsafe *__param_self_).data != null)) as bool))

    }

    pub mut fn clear() {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        var __local_i: i64 = (unsafe *__param_self_).size

        while true {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i - 1)

            if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
                break
            }

        }

        ((unsafe *__param_self_).size = ((0 as i64)))

    }

    pub mut fn take(__param_unowned: stc_word_stack) -> Unit {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        unsafe { stc_word_stack_drop((__param_self_ as *const stc_word_stack)) }

        with_memcpy((&raw mut (unsafe *__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_stack]())

    }

    pub fn size() -> i64 {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack
        return (unsafe *__param_self_).size

    }

    pub fn is_empty() -> bool {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack
        return ((((not ((unsafe *__param_self_).size != 0))) as bool))

    }

    pub mut fn append_uninit(__param_n: i64) -> *mut u64 {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        var __local_len: i64 = (unsafe *__param_self_).size

        if ((if (__local_len + __param_n) >= unsafe { (*(__param_self_ as *const stc_word_stack)).capacity() }: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve(((((__local_len * 3) / 2) + __param_n) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut u64))
            }
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

        return ((unsafe *__param_self_).data + ((__local_len as i64) as usize))

    }

    pub mut fn shrink_to_fit() -> Unit {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        unsafe { (*__param_self_).reserve((9223372036854775807 as i64)) }

    }

    pub mut fn push(__param_val: u64) -> *mut u64 {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        if ((if (unsafe *__param_self_).size == unsafe { (*(__param_self_ as *const stc_word_stack)).capacity() }: 1 else: 0) != 0) {
            if ((if not unsafe { (*__param_self_).reserve((((((*__param_self_).size * 3) / 2) + 4) as i64)) }: 1 else: 0) != 0) {
                return ((null as *mut u64))
            }
        }

        var __local_vp: *mut u64 = with 0 as __ci_expr_seq_10 {
            var __ci_expr_old_0: i64 = (unsafe *__param_self_).size
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size + 1)
            ((unsafe *__param_self_).data + ((__ci_expr_old_0 as i64) as usize))
        }

        ((unsafe *__local_vp) = __param_val)

        return __local_vp

    }

    pub mut fn pop() {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_stack_pop".ptr, c"stack.h".ptr, (149 as i32), c"self->size".ptr)
        } else {
            0
        }

        var __local_p: *mut u64 = with 0 as __ci_expr_seq_8 {
            ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)
            ((&raw const (unsafe (*__param_self_).data[(*__param_self_).size]) as *const u64) as *mut u64)
        }


    }

    pub mut fn pull() -> u64 {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        if (((if not ((unsafe *__param_self_).size != 0): 1 else: 0) as i64) != 0) {
            __assert_rtn(c"stc_word_stack_pull".ptr, c"stack.h".ptr, (152 as i32), c"self->size".ptr)
        } else {
            0
        }

        ((unsafe *__param_self_).size = (unsafe *__param_self_).size - 1)

        return (unsafe (*__param_self_).data[(*__param_self_).size])


    }

    pub fn value_clone(__param_val: u64) -> u64 {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack

        return __param_val

    }

    pub fn begin() -> stc_word_stack_iter {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack
        var __local_it_: stc_word_stack_iter = stc_word_stack_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if ((unsafe *__param_self_).size != 0) {
            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const stc_word_stack_iter)).end + (((unsafe *__param_self_).size as i64) as usize))
        } else {
            (__local_it_.ref = ((null as *mut u64)))
        }

        return __local_it_

    }

    pub fn rbegin() -> stc_word_stack_iter {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack
        var __local_it_: stc_word_stack_iter = stc_word_stack_iter { ref: (unsafe *__param_self_).data, end: (unsafe *__param_self_).data }

        if ((unsafe *__param_self_).size != 0) {
            (__local_it_.ref = (unsafe *(&raw const __local_it_ as *const stc_word_stack_iter)).ref + ((((unsafe *__param_self_).size - 1) as i64) as usize))

            (__local_it_.end = (unsafe *(&raw const __local_it_ as *const stc_word_stack_iter)).end - ((1 as i64) as usize))

        } else {
            (__local_it_.ref = ((null as *mut u64)))
        }

        return __local_it_

    }

    pub fn end() -> stc_word_stack_iter {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack

        var __local_it_: stc_word_stack_iter = stc_word_stack_iter.zeroed()

        return __local_it_

    }

    pub fn rend() -> stc_word_stack_iter {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack

        var __local_it_: stc_word_stack_iter = stc_word_stack_iter.zeroed()

        return __local_it_

    }

    pub fn index(__param_it_: stc_word_stack_iter) -> i64 {
        let __param_self_: *const stc_word_stack = self as *const stc_word_stack
        return (((((unsafe *(&raw const __param_it_ as *const stc_word_stack_iter)).ref as usize) -% ((unsafe *__param_self_).data as usize)) as i64) / (sizeof[u64]() as i64))

    }

    pub mut fn adjust_end_(__param_n: i64) {
        let __param_self_: *mut stc_word_stack = self as *mut stc_word_stack
        ((unsafe *__param_self_).size = (unsafe *__param_self_).size + __param_n)

    }

}

impl stc_word_stack_iter {
    pub mut fn next() {
        let __param_it_: *mut stc_word_stack_iter = self as *mut stc_word_stack_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref + 1)

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut u64)))
        }


    }

    pub mut fn rnext() {
        let __param_it_: *mut stc_word_stack_iter = self as *mut stc_word_stack_iter
        ((unsafe *__param_it_).ref = (unsafe *__param_it_).ref - 1)

        if ((if (unsafe *__param_it_).ref == (unsafe *__param_it_).end: 1 else: 0) != 0) {
            ((unsafe *__param_it_).ref = ((null as *mut u64)))
        }


    }

}
