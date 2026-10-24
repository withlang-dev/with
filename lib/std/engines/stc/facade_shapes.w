// Migrated from C
use std.engines.stc.defs
use std.libc
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

pub unsafe fn stc_slot_set_drop(__param_cself: *const stc_slot_set) {
    var __local_self_: *mut stc_slot_set = ((__param_cself as *mut stc_slot_set))

    if ((if (*__param_cself).meta == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_set_wipe_(__local_self_)

    with_free((((*__local_self_).meta as *mut c_void) as *mut u8))

    with_free((((*__local_self_).table as *mut c_void) as *mut u8))

}

pub unsafe fn stc_slot_set_clear(__param_self_: *mut stc_slot_set) -> Unit {
    if ((if (*__param_self_).meta == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_set_wipe_(__param_self_)

    ((*__param_self_).size = ((0 as i64)))

    with_memset((((*__param_self_).meta as *mut c_void) as *mut u8), (0 as i32), (((if 1 != 0: (((sizeof[hmap_meta]() as i64) * (*__param_self_).bucket_count) as i64) else: (-1 as i64)) as u64) as i64))

}

pub unsafe fn stc_slot_set_reserve(__param__self: *mut stc_slot_set, __param__cap: i64) -> bool {
    var __local__newcap: i64 = (((if (if __param__cap == 9223372036854775807: 1 else: 0) != 0: (*__param__self).size else: __param__cap) as i64))

    var __local__newbucks: i64 = ((((((__local__newcap as f32) / i_max_load_factor) as i64) + 4) as i64))

    (__local__newbucks = ((c_next_pow2(__local__newbucks) as i64)))

    var __ci_expr_logic_0: i32

    if ((if __local__newbucks == (*__param__self).bucket_count: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param__cap <= (((((*__param__self).bucket_count as f32) * i_max_load_factor) as i64)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return ((true as bool))
    }


    var __local_map: stc_slot_set = (*__param__self)

    var __local_self_: *mut stc_slot_set = ((&raw mut __local_map as *mut stc_slot_set))



    (__local_map.table = (((with_alloc((((if 1 != 0: ((__local__newbucks * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))

    (__local_map.meta = (((with_alloc_zeroed((((if 1 != 0: ((__local__newbucks + 1) as i64) else: (-1 as i64)) as u64) as i64), (((if 1 != 0: (sizeof[hmap_meta]() as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut hmap_meta)))

    (__local_map.bucket_count = __local__newbucks)

    var __local_ok: bool = with 0 as __ci_expr_seq_26 {
        var __ci_expr_logic_1: i32 = 0
        if ((*(&raw const __local_map as *const stc_slot_set)).table != null) {
            (__ci_expr_logic_1 = (if (*(&raw const __local_map as *const stc_slot_set)).meta != null: 1 else: 0))
        }
        (__ci_expr_logic_1 != 0)
    }

    if __local_ok {
        ((__local_map.meta[__local__newbucks])).set_dist(((1023 as u16)))

        var __local_d: *const *mut stc_slot_head = (((*__param__self).table as *const *mut stc_slot_head))

        var __local_m: *const hmap_meta = (((*__param__self).meta as *const hmap_meta))

        var __local_i: i64 = ((0 as i64))

        while ((if __local_i < (*__param__self).bucket_count: 1 else: 0) != 0) {
            if ((if ((__local_m[__local_i])).dist() != 0: 1 else: 0) != 0) {
                var __local_r: *mut stc_slot_head = (*__local_d)

                ((*(stc_slot_set_bucket_insert_(((&raw mut __local_map as *mut stc_slot_set) as *const stc_slot_set), ((&raw mut __local_r as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref)) = (*__local_d))

            }

            (__local_i = __local_i + 1)

            (__local_d = __local_d + 1)


        }


        loop {
            var __local__xp: *mut stc_slot_set = __param__self

            var __local__yp: *mut stc_slot_set = ((&raw mut __local_map as *mut stc_slot_set))


            var __local__tv: stc_slot_set = (*__local__xp)

            with_memcpy((&raw mut (*__local__xp) as *mut u8), (&raw const (*__local__yp) as *const u8), sizeof[stc_slot_set]())

            with_memcpy((&raw mut (*__local__yp) as *mut u8), (&raw const __local__tv as *const u8), sizeof[stc_slot_set]())

            if not ((0 != 0)) {
                break
            }
        }

    }

    with_free((((*(&raw const __local_map as *const stc_slot_set)).meta as *mut c_void) as *mut u8))

    with_free((((*(&raw const __local_map as *const stc_slot_set)).table as *mut c_void) as *mut u8))

    return __local_ok

}

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

pub unsafe fn stc_slot_set_max_load_factor(__param_self_: *const stc_slot_set) -> f32 {

    return i_max_load_factor

}

pub unsafe fn stc_slot_set_capacity(__param_map: *const stc_slot_set) -> i64 {
    return (((((*__param_map).bucket_count as f32) * i_max_load_factor) as i64))

}

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

pub unsafe fn stc_slot_set_is_empty(__param_map: *const stc_slot_set) -> bool {
    return ((((not ((*__param_map).size != 0))) as bool))

}

pub unsafe fn stc_slot_set_size(__param_map: *const stc_slot_set) -> i64 {
    return (*__param_map).size

}

pub unsafe fn stc_slot_set_bucket_count(__param_map: *mut stc_slot_set) -> i64 {
    return (*__param_map).bucket_count

}

pub unsafe fn stc_slot_set_contains(__param_self_: *const stc_slot_set, __param_rkey: *mut stc_slot_head) -> bool {
    var __ci_expr_logic_0: i32 = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref != null: 1 else: 0))
    }

    return (((__ci_expr_logic_0 != 0) as bool))


}

pub unsafe fn stc_slot_set_shrink_to_fit(__param_self_: *mut stc_slot_set) -> Unit {
    stc_slot_set_reserve(__param_self_, (9223372036854775807 as i64))

}

pub unsafe fn stc_slot_set_insert_entry_(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> stc_slot_set_result {
    if ((if (*__param_self_).size >= (((((*__param_self_).bucket_count as f32) * i_max_load_factor) as i64)): 1 else: 0) != 0) {
        if ((if not stc_slot_set_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 2) as i64)): 1 else: 0) != 0) {
            return ((stc_slot_set_result.zeroed() as stc_slot_set_result))
        }
    }

    var __local_res: stc_slot_set_result = stc_slot_set_bucket_insert_((__param_self_ as *const stc_slot_set), ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const stc_slot_set_result)).inserted as i32))

    return __local_res

}

pub unsafe fn stc_slot_set_value_toraw(__param_val: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_val)

}

pub unsafe fn stc_slot_set_value_drop(__param_self_: *const stc_slot_set, __param__val: *mut *mut stc_slot_head) {
    return
}

pub unsafe fn stc_slot_set_move(__param_self_: *mut stc_slot_set) -> stc_slot_set {
    var __local_m: stc_slot_set = (*__param_self_)

    ((*__param_self_).size = ((0 as i64)))

    ((*__param_self_).bucket_count = (*__param_self_).size)


    ((*__param_self_).meta = ((null as *mut hmap_meta)))

    ((*__param_self_).table = ((null as *mut *mut stc_slot_head)))

    return __local_m

}

pub unsafe fn stc_slot_set_take(__param_self_: *mut stc_slot_set, __param_unowned: stc_slot_set) -> Unit {
    stc_slot_set_drop((__param_self_ as *const stc_slot_set))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_set]())

}

pub unsafe fn stc_slot_set_insert(__param_self_: *mut stc_slot_set, __param__key: *mut stc_slot_head) -> stc_slot_set_result {
    var __local__res: stc_slot_set_result = stc_slot_set_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut *mut stc_slot_head)))

    if (*(&raw const __local__res as *const stc_slot_set_result)).inserted {
        ((*((*(&raw const __local__res as *const stc_slot_set_result)).ref)) = __param__key)

    } else {

    }

    return __local__res

}

pub unsafe fn stc_slot_set_push(__param_self_: *mut stc_slot_set, __param__val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local__res: stc_slot_set_result = stc_slot_set_insert_entry_(__param_self_, (*(&raw mut __param__val as *mut *mut stc_slot_head)))

    if ((if not (*(&raw const __local__res as *const stc_slot_set_result)).inserted: 1 else: 0) != 0) {
        stc_slot_set_value_drop((__param_self_ as *const stc_slot_set), (*(&raw const __local__res as *const stc_slot_set_result)).ref)
    }

    ((*((*(&raw const __local__res as *const stc_slot_set_result)).ref)) = __param__val)

    return (*(&raw const __local__res as *const stc_slot_set_result)).ref

}

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

pub unsafe fn stc_slot_set_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_set {
    var __local_cx: stc_slot_set = stc_slot_set.zeroed()

    stc_slot_set_put_n((&raw mut __local_cx as *mut stc_slot_set), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_set_with_capacity(__param_cap: i64) -> stc_slot_set {
    var __local_cx: stc_slot_set = stc_slot_set.zeroed()

    unsafe { stc_slot_set_reserve((&raw mut __local_cx as *mut stc_slot_set), __param_cap) }

    return __local_cx

}

pub unsafe fn stc_slot_set_begin(__param_self_: *const stc_slot_set) -> stc_slot_set_iter {
    var __local_it_: stc_slot_set_iter = stc_slot_set_iter { ref: (*__param_self_).table, _end: (*__param_self_).table, _mref: (*__param_self_).meta }

    if ((if (*(&raw const __local_it_ as *const stc_slot_set_iter)).ref == null: 1 else: 0) != 0) {
        return __local_it_
    }

    (__local_it_._end = (*(&raw const __local_it_ as *const stc_slot_set_iter))._end + (((*__param_self_).bucket_count as i64) as usize))

    while ((if (*(*(&raw const __local_it_ as *const stc_slot_set_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        (__local_it_.ref = (*(&raw const __local_it_ as *const stc_slot_set_iter)).ref + 1)

        (__local_it_._mref = (*(&raw const __local_it_ as *const stc_slot_set_iter))._mref + 1)

    }

    if ((if (*(&raw const __local_it_ as *const stc_slot_set_iter)).ref == (*(&raw const __local_it_ as *const stc_slot_set_iter))._end: 1 else: 0) != 0) {
        (__local_it_.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __local_it_

}

pub unsafe fn stc_slot_set_end(__param_self_: *const stc_slot_set) -> stc_slot_set_iter {

    return ((stc_slot_set_iter.zeroed() as stc_slot_set_iter))

}

pub unsafe fn stc_slot_set_next(__param_it_: *mut stc_slot_set_iter) {
    while true {
        ((*__param_it_).ref = (*__param_it_).ref + 1)

        ((*__param_it_)._mref = (*__param_it_)._mref + 1)

        if (not ((if (*(*__param_it_)._mref).dist() == 0: 1 else: 0) != 0)) {
            break
        }

    }

    if ((if (*__param_it_).ref == (*__param_it_)._end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut *mut stc_slot_head)))
    }

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

        unsafe { stc_slot_set_next((&raw mut __param_it_ as *mut stc_slot_set_iter)) }

    }

    return __param_it_

}

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


    return stc_slot_set_end(__param_self_)

}

pub unsafe fn stc_slot_set_get(__param_self_: *const stc_slot_set, __param_rkey: *mut stc_slot_head) -> *const *mut stc_slot_head {
    return (((if (*__param_self_).size != 0: stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref else: (null as *mut *mut stc_slot_head)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_set_get_mut(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    return ((stc_slot_set_get((__param_self_ as *const stc_slot_set), __param_rkey) as *mut *mut stc_slot_head))

}

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

pub unsafe fn stc_slot_set_erase_at(__param_self_: *mut stc_slot_set, __param_it_: stc_slot_set_iter) -> stc_slot_set_iter {
    stc_slot_set_erase_entry(__param_self_, (*(&raw const __param_it_ as *const stc_slot_set_iter)).ref)

    if ((if (*(*(&raw const __param_it_ as *const stc_slot_set_iter))._mref).dist() == 0: 1 else: 0) != 0) {
        stc_slot_set_next((&raw mut __param_it_ as *mut stc_slot_set_iter))
    }

    return __param_it_

}

pub unsafe fn stc_slot_set_eq(__param_self_: *const stc_slot_set, __param_other: *const stc_slot_set) -> bool {
    if ((if stc_slot_set_size(__param_self_) != stc_slot_set_size(__param_other): 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_i: stc_slot_set_iter = stc_slot_set_begin(__param_self_)

    while ((*(&raw const __local_i as *const stc_slot_set_iter)).ref != null) {
        var __local__raw: *mut stc_slot_head = (*((*(&raw const __local_i as *const stc_slot_set_iter)).ref))

        if ((if not stc_slot_set_contains(__param_other, __local__raw): 1 else: 0) != 0) {
            return ((false as bool))
        }


        stc_slot_set_next((&raw mut __local_i as *mut stc_slot_set_iter))

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

pub unsafe fn stc_slot_sset_drop(__param_cself: *const stc_slot_sset) {
    var __local_self_: *mut stc_slot_sset = ((__param_cself as *mut stc_slot_sset))

    if ((if (*__local_self_).nodes == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_sset_drop_r_(__local_self_, (*__local_self_).root)

    with_free((((*__local_self_).nodes as *mut c_void) as *mut u8))

}

pub unsafe fn stc_slot_sset_reserve(__param_self_: *mut stc_slot_sset, __param_cap: i64) -> bool {
    if ((if __param_cap <= (*__param_self_).capacity: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_nodes: *mut stc_slot_sset_node = (((with_realloc((((*__param_self_).nodes as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: (((__param_cap + 1) * (sizeof[stc_slot_sset_node]() as i64)) as i64) else: ((((*__param_self_).capacity + 1) * (sizeof[stc_slot_sset_node]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut stc_slot_sset_node))

    if ((if __local_nodes == null: 1 else: 0) != 0) {
        return ((false as bool))
    }

    ((__local_nodes[0]) = ((stc_slot_sset_node.zeroed() as stc_slot_sset_node)))

    ((*__param_self_).nodes = __local_nodes)

    ((*__param_self_).capacity = ((__param_cap as i32)))

    return ((true as bool))

}

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

pub unsafe fn stc_slot_sset_front(__param_self_: *const stc_slot_sset) -> *mut *mut stc_slot_head {
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while ((__local_d[__local_tn]).link[0] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[0] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_sset_back(__param_self_: *const stc_slot_sset) -> *mut *mut stc_slot_head {
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_tn: i32 = (*__param_self_).root

    while ((__local_d[__local_tn]).link[1] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[1] as i32)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

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

pub unsafe fn stc_slot_sset_erase_at(__param_self_: *mut stc_slot_sset, __param_it_: stc_slot_sset_iter) -> stc_slot_sset_iter {
    var __local_raw: *mut stc_slot_head = (*((*(&raw const __param_it_ as *const stc_slot_sset_iter)).ref))

    stc_slot_sset_next((&raw mut __param_it_ as *mut stc_slot_sset_iter))

    if ((if (*(&raw const __param_it_ as *const stc_slot_sset_iter)).ref != null: 1 else: 0) != 0) {
        var __local_nxt: *mut stc_slot_head = (*((*(&raw const __param_it_ as *const stc_slot_sset_iter)).ref))

        stc_slot_sset_erase(__param_self_, __local_raw)

        stc_slot_sset_find_it((__param_self_ as *const stc_slot_sset), __local_nxt, (&raw mut __param_it_ as *mut stc_slot_sset_iter))

    } else {
        stc_slot_sset_erase(__param_self_, __local_raw)
    }

    return __param_it_

}

pub unsafe fn stc_slot_sset_erase_range(__param_self_: *mut stc_slot_sset, __param_it1: stc_slot_sset_iter, __param_it2: stc_slot_sset_iter) -> stc_slot_sset_iter {
    var __local_it1 = __param_it1
    if ((if (*(&raw const __param_it2 as *const stc_slot_sset_iter)).ref == null: 1 else: 0) != 0) {
        while ((if (*(&raw const __local_it1 as *const stc_slot_sset_iter)).ref != null: 1 else: 0) != 0) {
            let __ci_copy_25: stc_slot_sset_iter = stc_slot_sset_erase_at(__param_self_, __local_it1)
            with_memcpy((&raw mut __local_it1 as *mut u8), (&raw const __ci_copy_25 as *const u8), sizeof[stc_slot_sset_iter]())
        }

        return __local_it1

    }

    var __local_k1: *mut stc_slot_head = (*((*(&raw const __local_it1 as *const stc_slot_sset_iter)).ref))

    var __local_k2: *mut stc_slot_head = (*((*(&raw const __param_it2 as *const stc_slot_sset_iter)).ref))


    var __local_r1: *mut stc_slot_head = (*(&raw mut __local_k1 as *mut *mut stc_slot_head))

    while true {
        if ((if with_memcmp((((&raw mut __local_k1 as *mut *mut stc_slot_head) as *const c_void) as *const u8), (((&raw mut __local_k2 as *mut *mut stc_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as u64) as i64)) == 0: 1 else: 0) != 0) {
            return __local_it1
        }

        stc_slot_sset_next((&raw mut __local_it1 as *mut stc_slot_sset_iter))

        (__local_k1 = (*((*(&raw const __local_it1 as *const stc_slot_sset_iter)).ref)))

        stc_slot_sset_erase(__param_self_, __local_r1)

        (__local_r1 = (*(&raw mut __local_k1 as *mut *mut stc_slot_head)))

        stc_slot_sset_find_it((__param_self_ as *const stc_slot_sset), __local_r1, (&raw mut __local_it1 as *mut stc_slot_sset_iter))

    }

}

pub unsafe fn stc_slot_sset_begin(__param_self_: *const stc_slot_sset) -> stc_slot_sset_iter {
    var __local_it_: stc_slot_sset_iter

    (__local_it_.ref = ((null as *mut *mut stc_slot_head)))

    (__local_it_._d = (*__param_self_).nodes)

    (__local_it_._top = ((0 as i32)))


    (__local_it_._tn = (*__param_self_).root)

    if ((*(&raw const __local_it_ as *const stc_slot_sset_iter))._tn != 0) {
        stc_slot_sset_next((&raw mut __local_it_ as *mut stc_slot_sset_iter))
    }

    return __local_it_

}

pub unsafe fn stc_slot_sset_next(__param_it_: *mut stc_slot_sset_iter) -> Unit {
    var __local_tn: i32 = (*__param_it_)._tn

    var __ci_expr_logic_0: i32

    if ((*__param_it_)._top != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_tn != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        while (__local_tn != 0) {
            var __ci_expr_old_1: i32 = (*__param_it_)._top

            ((*__param_it_)._top = (*__param_it_)._top + 1)

            ((*__param_it_)._st[__ci_expr_old_1] = __local_tn)


            (__local_tn = ((((*__param_it_)._d[__local_tn]).link[0] as i32)))

        }

        ((*__param_it_)._top = (*__param_it_)._top - 1)

        (__local_tn = (((*__param_it_)._st[(*__param_it_)._top] as i32)))


        ((*__param_it_)._tn = ((((*__param_it_)._d[__local_tn]).link[1] as i32)))

        ((*__param_it_).ref = (((&raw const ((*__param_it_)._d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    } else {
        ((*__param_it_).ref = ((null as *mut *mut stc_slot_head)))
    }


}

pub unsafe fn stc_slot_sset_is_empty(__param_self_: *const stc_slot_sset) -> bool {
    return (((((*__param_self_).size == 0)) as bool))

}

pub unsafe fn stc_slot_sset_size(__param_self_: *const stc_slot_sset) -> i64 {
    return (((*__param_self_).size as i64))

}

pub unsafe fn stc_slot_sset_capacity(__param_self_: *const stc_slot_sset) -> i64 {
    return (((*__param_self_).capacity as i64))

}

pub unsafe fn stc_slot_sset_find(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> stc_slot_sset_iter {
    var __local_it_: stc_slot_sset_iter

    stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter))

    return __local_it_

}

pub unsafe fn stc_slot_sset_contains(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> bool {
    var __local_it_: stc_slot_sset_iter

    return ((((stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter)) != null)) as bool))

}

pub unsafe fn stc_slot_sset_get(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> *const *mut stc_slot_head {
    var __local_it_: stc_slot_sset_iter

    return ((stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_sset_get_mut(__param_self_: *mut stc_slot_sset, __param_rkey: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_it_: stc_slot_sset_iter

    return ((stc_slot_sset_find_it((__param_self_ as *const stc_slot_sset), __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter)) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_sset_value_toraw(__param_val: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_val)

}

pub unsafe fn stc_slot_sset_value_drop(__param_self_: *const stc_slot_sset, __param_val: *mut *mut stc_slot_head) {
    return
}

pub unsafe fn stc_slot_sset_move(__param_self_: *mut stc_slot_sset) -> stc_slot_sset {
    var __local_m: stc_slot_sset = (*__param_self_)

    ((*__param_self_).head = ((0 as i32)))

    ((*__param_self_).disp = (*__param_self_).head)

    ((*__param_self_).root = (*__param_self_).disp)

    ((*__param_self_).size = (*__param_self_).root)

    ((*__param_self_).capacity = (*__param_self_).size)


    ((*__param_self_).nodes = ((null as *mut stc_slot_sset_node)))

    return __local_m

}

pub unsafe fn stc_slot_sset_clear(__param_self_: *mut stc_slot_sset) -> Unit {
    stc_slot_sset_drop((__param_self_ as *const stc_slot_sset))

    stc_slot_sset_move(__param_self_)

}

pub unsafe fn stc_slot_sset_take(__param_self_: *mut stc_slot_sset, __param_unowned: stc_slot_sset) -> Unit {
    stc_slot_sset_drop((__param_self_ as *const stc_slot_sset))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_sset]())

}

pub unsafe fn stc_slot_sset_insert_entry_(__param_self_: *mut stc_slot_sset, __param_rkey: *mut stc_slot_head) -> stc_slot_sset_result {
    var __local_res: stc_slot_sset_result = stc_slot_sset_result.zeroed()

    var __local_tn: i32 = ((stc_slot_sset_insert_entry_i_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head), (&raw mut __local_res as *mut stc_slot_sset_result)) as i32))

    ((*__param_self_).root = __local_tn)

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const stc_slot_sset_result)).inserted as i32))

    return __local_res

}

pub unsafe fn stc_slot_sset_end(__param_self_: *const stc_slot_sset) -> stc_slot_sset_iter {
    var __local_it_: stc_slot_sset_iter


    (__local_it_.ref = ((null as *mut *mut stc_slot_head)))

    (__local_it_._top = ((0 as i32)))

    (__local_it_._tn = ((0 as i32)))


    return __local_it_

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

        unsafe { stc_slot_sset_next((&raw mut __param_it_ as *mut stc_slot_sset_iter)) }

    }

    return __param_it_

}

pub unsafe fn stc_slot_sset_insert(__param_self_: *mut stc_slot_sset, __param__key: *mut stc_slot_head) -> stc_slot_sset_result {
    var __local__res: stc_slot_sset_result = stc_slot_sset_insert_entry_(__param_self_, (*(&raw mut __param__key as *mut *mut stc_slot_head)))

    if (*(&raw const __local__res as *const stc_slot_sset_result)).inserted {
        ((*((*(&raw const __local__res as *const stc_slot_sset_result)).ref)) = __param__key)

    } else {

    }

    return __local__res

}

pub unsafe fn stc_slot_sset_push(__param_self_: *mut stc_slot_sset, __param__val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local__res: stc_slot_sset_result = stc_slot_sset_insert_entry_(__param_self_, (*(&raw mut __param__val as *mut *mut stc_slot_head)))

    if ((if not (*(&raw const __local__res as *const stc_slot_sset_result)).inserted: 1 else: 0) != 0) {
        stc_slot_sset_value_drop((__param_self_ as *const stc_slot_sset), (*(&raw const __local__res as *const stc_slot_sset_result)).ref)
    }

    ((*((*(&raw const __local__res as *const stc_slot_sset_result)).ref)) = __param__val)

    return (*(&raw const __local__res as *const stc_slot_sset_result)).ref

}

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

pub unsafe fn stc_slot_sset_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_sset {
    var __local_cx: stc_slot_sset = stc_slot_sset.zeroed()

    stc_slot_sset_put_n((&raw mut __local_cx as *mut stc_slot_sset), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_sset_with_capacity(__param_cap: i64) -> stc_slot_sset {
    var __local_cx: stc_slot_sset = stc_slot_sset.zeroed()

    unsafe { stc_slot_sset_reserve((&raw mut __local_cx as *mut stc_slot_sset), __param_cap) }

    return __local_cx

}

unsafe fn stc_slot_sset_new_node_(__param_self_: *mut stc_slot_sset, __param_level: i32) -> i32 {
    var __local_tn: i32

    if ((if (*__param_self_).disp != 0: 1 else: 0) != 0) {
        (__local_tn = (*__param_self_).disp)

        ((*__param_self_).disp = ((((*__param_self_).nodes[__local_tn]).link[1] as i32)))

    } else {
        if ((if (*__param_self_).head == (*__param_self_).capacity: 1 else: 0) != 0) {
            if ((if not stc_slot_sset_reserve(__param_self_, (((((*__param_self_).head * 3) / 2) + 4) as i64)): 1 else: 0) != 0) {
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

pub unsafe fn stc_slot_pqueue_make_heap(__param_self_: *mut stc_slot_pqueue) {
    var __local_n: i64 = (*__param_self_).size

    var __local_k: i64 = (((__local_n / 2) as i64))

    while ((if __local_k != 0: 1 else: 0) != 0) {
        stc_slot_pqueue_sift_down_(__param_self_, __local_k, __local_n)

        (__local_k = __local_k - 1)

    }


}

pub unsafe fn stc_slot_pqueue_erase_at(__param_self_: *mut stc_slot_pqueue, __param_idx: i64) {

    var __local_n: i64 = with 0 as __ci_expr_seq_6 {
        ((*__param_self_).size = (*__param_self_).size - 1)
        (*__param_self_).size
    }

    (((*__param_self_).data[__param_idx]) = ((*__param_self_).data[__local_n]))

    stc_slot_pqueue_sift_down_(__param_self_, ((__param_idx + 1) as i64), __local_n)

}

pub unsafe fn stc_slot_pqueue_push(__param_self_: *mut stc_slot_pqueue, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    if ((if (*__param_self_).size == (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not stc_slot_pqueue_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 4) as i64)): 1 else: 0) != 0) {
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

    return (((__local_arr + ((__local_c as i64) as usize)) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_pqueue_sift_down_(__param_self_: *mut stc_slot_pqueue, __param_idx: i64, __param_n: i64) {
    var __local_t: *mut stc_slot_head

    var __local_arr: *mut *mut stc_slot_head = ((*__param_self_).data - ((1 as i64) as usize))


    var __local_r: i64 = __param_idx

    var __local_c: i64 = (((__param_idx * 2) as i64))


    while ((if __local_c <= __param_n: 1 else: 0) != 0) {
        (__local_c = __local_c + (if (*(*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))).cmp.unwrap()(((*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const (__local_arr[(__local_c + (if __local_c < __param_n: 1 else: 0))]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0))

        if ((if not ((if (*(*((&raw const (__local_arr[__local_r]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))).cmp.unwrap()(((*((&raw const (__local_arr[__local_r]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            return
        }

        (__local_t = (__local_arr[__local_r]))

        ((__local_arr[__local_r]) = (__local_arr[__local_c]))

        (__local_r = __local_c)

        ((__local_arr[__local_r]) = __local_t)



        (__local_c = __local_c * 2)

    }


}

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

pub unsafe fn stc_slot_pqueue_reserve(__param_self_: *mut stc_slot_pqueue, __param_cap: i64) -> bool {
    var __local_n: i64 = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (*__param_self_).size else: __param_cap) as i64))

    if ((((if __param_cap > (*__param_self_).capacity: 1 else: 0) as i32) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as i32)) != 0) {
        var __local_d: *mut *mut stc_slot_head = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[usize]() as i64)) as i64) else: (((*__param_self_).capacity * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return ((false as bool))
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((((*__param_self_).data != null)) as bool))

}

pub unsafe fn stc_slot_pqueue_shrink_to_fit(__param_self_: *mut stc_slot_pqueue) -> Unit {
    stc_slot_pqueue_reserve(__param_self_, (9223372036854775807 as i64))

}

pub fn stc_slot_pqueue_init() -> stc_slot_pqueue {
    return ((stc_slot_pqueue.zeroed() as stc_slot_pqueue))

}

pub unsafe fn stc_slot_pqueue_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_pqueue {
    var __local_cx: stc_slot_pqueue = stc_slot_pqueue.zeroed()

    stc_slot_pqueue_put_n((&raw mut __local_cx as *mut stc_slot_pqueue), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_pqueue_with_capacity(__param_cap: i64) -> stc_slot_pqueue {
    var __local_cx: stc_slot_pqueue = stc_slot_pqueue.zeroed()

    unsafe { stc_slot_pqueue_reserve((&raw mut __local_cx as *mut stc_slot_pqueue), __param_cap) }

    return __local_cx

}

pub unsafe fn stc_slot_pqueue_clear(__param_self_: *mut stc_slot_pqueue) {
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

pub unsafe fn stc_slot_pqueue_drop(__param_cself: *const stc_slot_pqueue) {
    var __local_self_: *mut stc_slot_pqueue = ((__param_cself as *mut stc_slot_pqueue))

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_pqueue_clear(__local_self_)

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))

}

pub unsafe fn stc_slot_pqueue_move(__param_self_: *mut stc_slot_pqueue) -> stc_slot_pqueue {
    var __local_m: stc_slot_pqueue = (*__param_self_)

    ((*__param_self_).capacity = ((0 as i64)))

    ((*__param_self_).size = (*__param_self_).capacity)


    ((*__param_self_).data = ((null as *mut *mut stc_slot_head)))

    return __local_m

}

pub unsafe fn stc_slot_pqueue_take(__param_self_: *mut stc_slot_pqueue, __param_unowned: stc_slot_pqueue) -> Unit {
    stc_slot_pqueue_drop((__param_self_ as *const stc_slot_pqueue))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_pqueue]())

}

pub unsafe fn stc_slot_pqueue_size(__param_q: *const stc_slot_pqueue) -> i64 {
    return (*__param_q).size

}

pub unsafe fn stc_slot_pqueue_is_empty(__param_q: *const stc_slot_pqueue) -> bool {
    return ((((not ((*__param_q).size != 0))) as bool))

}

pub unsafe fn stc_slot_pqueue_capacity(__param_q: *const stc_slot_pqueue) -> i64 {
    return (*__param_q).capacity

}

pub unsafe fn stc_slot_pqueue_top(__param_self_: *const stc_slot_pqueue) -> *const *mut stc_slot_head {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_pqueue_top".ptr, c"pqueue.h".ptr, (117 as i32), c"self->size".ptr)
    } else {
        0
    }

    return ((((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_pqueue_pop(__param_self_: *mut stc_slot_pqueue) {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_pqueue_pop".ptr, c"pqueue.h".ptr, (120 as i32), c"self->size".ptr)
    } else {
        0
    }

    stc_slot_pqueue_erase_at(__param_self_, (0 as i64))

}

pub unsafe fn stc_slot_pqueue_pull(__param_self_: *mut stc_slot_pqueue) -> *mut stc_slot_head {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_pqueue_pull".ptr, c"pqueue.h".ptr, (123 as i32), c"self->size".ptr)
    } else {
        0
    }

    var __local_v: *mut stc_slot_head = ((*__param_self_).data[0])

    stc_slot_pqueue_erase_at(__param_self_, (0 as i64))

    return __local_v

}

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

        stc_slot_pqueue_sift_down_(__param_self_, (1 as i64), (*__param_self_).size)

    }


    return __param_val

}

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

    stc_slot_pqueue_sift_down_(__param_self_, (1 as i64), (*__param_self_).size)

    return __param_val

}

pub unsafe fn stc_slot_deque_reserve(__param_self_: *mut stc_slot_deque, __param_cap: i64) -> bool {
    var __local_oldpow2: i64 = ((((*__param_self_).capmask + (((*__param_self_).capmask as i64) & (1 as i64))) as i64))

    var __local_newpow2: i64 = ((c_next_pow2(((__param_cap + 1) as i64)) as i64))

    if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
        return (((((*__param_self_).cbuf != null)) as bool))
    }

    var __local_d: *mut *mut stc_slot_head = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as i64)) as i64) else: ((__local_oldpow2 * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

    if ((if __local_d == null: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_head: i64 = (((__local_oldpow2 - (*__param_self_).start) as i64))

    if (not ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0)) {
        if ((if __local_head < (*__param_self_).end: 1 else: 0) != 0) {
            with_memcpy(((((__local_d + ((__local_newpow2 as i64) as usize)) - ((__local_head as i64) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((*__param_self_).start = (((__local_newpow2 - __local_head) as i64)))

        } else {
            with_memcpy((((__local_d + ((__local_oldpow2 as i64) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((*__param_self_).end * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((*__param_self_).end = (*__param_self_).end + __local_oldpow2)

        }
    }

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

    ((*__param_self_).cbuf = __local_d)

    return ((true as bool))

}

pub unsafe fn stc_slot_deque_clear(__param_self_: *mut stc_slot_deque) {
    var __local_i: stc_slot_deque_iter = stc_slot_deque_begin((((&raw const (*__param_self_) as *const stc_slot_deque) as *mut stc_slot_deque) as *const stc_slot_deque))

    while ((*(&raw const __local_i as *const stc_slot_deque_iter)).ref != null) {


        stc_slot_deque_next((&raw mut __local_i as *mut stc_slot_deque_iter))

    }


    ((*__param_self_).start = ((0 as i64)))

    ((*__param_self_).end = ((0 as i64)))


}

pub unsafe fn stc_slot_deque_drop(__param_cself: *const stc_slot_deque) {
    var __local_self_: *mut stc_slot_deque = ((__param_cself as *mut stc_slot_deque))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_deque_clear(__local_self_)

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))

}

pub unsafe fn stc_slot_deque_push(__param_self_: *mut stc_slot_deque, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_end: i64 = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_end == (*__param_self_).start: 1 else: 0) != 0) {
        if ((if not stc_slot_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }

        (__local_end = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut *mut stc_slot_head = ((*__param_self_).cbuf + (((*__param_self_).end as i64) as usize))

    ((*__param_self_).end = __local_end)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_slot_deque_shrink_to_fit(__param_self_: *mut stc_slot_deque) {
    var __local_sz: i64 = ((stc_slot_deque_size((__param_self_ as *const stc_slot_deque)) as i64))

    var __local_newpow2: i64 = ((c_next_pow2(((__local_sz + 1) as i64)) as i64))

    if ((if __local_newpow2 > (*__param_self_).capmask: 1 else: 0) != 0) {
        return
    }

    if ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove((((*__param_self_).cbuf as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

        ((*__param_self_).start = ((0 as i64)))

        ((*__param_self_).end = __local_sz)


    } else {
        var __local_n: i64 = (((((*__param_self_).capmask - (*__param_self_).start) + 1) as i64))

        with_memmove(((((*__param_self_).cbuf + (((__local_newpow2 - __local_n) as i64) as usize)) as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

        ((*__param_self_).start = (((__local_newpow2 - __local_n) as i64)))

    }

    ((*__param_self_).cbuf = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as i64)) as i64) else: ((((*__param_self_).capmask + 1) * (sizeof[usize]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

}

pub fn stc_slot_deque_advance(__param_it_: stc_slot_deque_iter, __param_n: i64) -> stc_slot_deque_iter {
    var __local_len: i64 = ((unsafe { stc_slot_deque_size((*(&raw const __param_it_ as *const stc_slot_deque_iter))._s) } as i64))

    var __local_pos: i64 = (unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos

    var __local_idx: i64 = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).start) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).capmask as i64)) as i64))


    (__param_it_.pos = (((((__local_pos + __param_n) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).capmask as i64)) as i64)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - __local_pos) as i64) as usize))

    if ((if not ((if (((__local_idx + __param_n) as u64)) < ((__local_len as u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it_

}

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

pub unsafe fn stc_slot_deque_with_size(__param_size: i64, __param_default_raw: *mut stc_slot_head) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_size)

    while ((if (*(&raw const __local_out as *const stc_slot_deque)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: i64 = (*(&raw const __local_out as *const stc_slot_deque)).end

        (__local_out.end = (*(&raw const __local_out as *const stc_slot_deque)).end + 1)

        ((__local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

pub unsafe fn stc_slot_deque_from_n(__param_raw: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_n)

    stc_slot_deque_put_n((&raw mut __local_out as *mut stc_slot_deque), __param_raw, __param_n)

    return __local_out

}

pub unsafe fn stc_slot_deque_size(__param_self_: *const stc_slot_deque) -> i64 {
    return ((((*__param_self_).end - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64))

}

pub unsafe fn stc_slot_deque_capacity(__param_self_: *const stc_slot_deque) -> i64 {
    return (*__param_self_).capmask

}

pub unsafe fn stc_slot_deque_is_empty(__param_self_: *const stc_slot_deque) -> bool {
    return (((((*__param_self_).start == (*__param_self_).end)) as bool))

}

pub unsafe fn stc_slot_deque_value_toraw(__param_pval: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_pval)

}

pub unsafe fn stc_slot_deque_front(__param_self_: *const stc_slot_deque) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_front_mut(__param_self_: *mut stc_slot_deque) -> *mut *mut stc_slot_head {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_back(__param_self_: *const stc_slot_deque) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_back_mut(__param_self_: *mut stc_slot_deque) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_back((__param_self_ as *const stc_slot_deque)) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_move(__param_self_: *mut stc_slot_deque) -> stc_slot_deque {
    var __local_m: stc_slot_deque = (*__param_self_)

    ((*__param_self_).end = ((0 as i64)))

    ((*__param_self_).start = (*__param_self_).end)

    ((*__param_self_).capmask = (*__param_self_).start)


    ((*__param_self_).cbuf = ((null as *mut *mut stc_slot_head)))

    return __local_m

}

pub unsafe fn stc_slot_deque_take(__param_self_: *mut stc_slot_deque, __param_unowned: stc_slot_deque) -> Unit {
    stc_slot_deque_drop((__param_self_ as *const stc_slot_deque))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_deque]())

}

pub unsafe fn stc_slot_deque_pop_front(__param_self_: *mut stc_slot_deque) {
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_deque_pop_front".ptr, c"queue_prv.h".ptr, (133 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }


    ((*__param_self_).start = ((((((*__param_self_).start + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

}

pub unsafe fn stc_slot_deque_pull_front(__param_self_: *mut stc_slot_deque) -> *mut stc_slot_head {
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_deque_pull_front".ptr, c"queue_prv.h".ptr, (139 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }

    var __local_s: i64 = (*__param_self_).start

    ((*__param_self_).start = (((((__local_s + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    return ((((*__param_self_).cbuf[__local_s]) as *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_begin(__param_self_: *const stc_slot_deque) -> stc_slot_deque_iter {
    return ((stc_slot_deque_iter { ref: (if stc_slot_deque_is_empty(__param_self_): ((null) as *mut *mut stc_slot_head) else: ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))), pos: (*__param_self_).start, _s: __param_self_ } as stc_slot_deque_iter))

}

pub unsafe fn stc_slot_deque_rbegin(__param_self_: *const stc_slot_deque) -> stc_slot_deque_iter {
    var __local_pos: i64 = ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    return ((stc_slot_deque_iter { ref: (if stc_slot_deque_is_empty(__param_self_): ((null) as *mut *mut stc_slot_head) else: ((*__param_self_).cbuf + ((__local_pos as i64) as usize))), pos: __local_pos, _s: __param_self_ } as stc_slot_deque_iter))

}

pub unsafe fn stc_slot_deque_end(__param_self_: *const stc_slot_deque) -> stc_slot_deque_iter {

    return ((stc_slot_deque_iter.zeroed() as stc_slot_deque_iter))

}

pub unsafe fn stc_slot_deque_rend(__param_self_: *const stc_slot_deque) -> stc_slot_deque_iter {

    return ((stc_slot_deque_iter.zeroed() as stc_slot_deque_iter))

}

pub unsafe fn stc_slot_deque_next(__param_it_: *mut stc_slot_deque_iter) {
    if ((if (*__param_it_).pos != (*(*__param_it_)._s).capmask: 1 else: 0) != 0) {
        ((*__param_it_).ref = (*__param_it_).ref + 1)

        ((*__param_it_).pos = (*__param_it_).pos + 1)

    } else {
        ((*__param_it_).ref = (*__param_it_).ref - (((*__param_it_).pos as i64) as usize))

        ((*__param_it_).pos = ((0 as i64)))

    }

    if ((if (*__param_it_).pos == (*(*__param_it_)._s).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut *mut stc_slot_head)))
    }

}

pub unsafe fn stc_slot_deque_rnext(__param_it_: *mut stc_slot_deque_iter) -> Unit {
    if ((if (*__param_it_).pos == (*(*__param_it_)._s).start: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut *mut stc_slot_head)))
    } else {
        if ((if (*__param_it_).pos != 0: 1 else: 0) != 0) {
            ((*__param_it_).ref = (*__param_it_).ref - 1)

            ((*__param_it_).pos = (*__param_it_).pos - 1)

        } else {
            ((*__param_it_).pos = (*(*__param_it_)._s).capmask)

            ((*__param_it_).ref = (*__param_it_).ref + (((*__param_it_).pos as i64) as usize))

        }
    }

}

pub unsafe fn stc_slot_deque_index(__param_self_: *const stc_slot_deque, __param_it_: stc_slot_deque_iter) -> i64 {
    return ((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64))

}

pub unsafe fn stc_slot_deque_adjust_end_(__param_self_: *mut stc_slot_deque, __param_n: i64) {
    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

}

pub unsafe fn stc_slot_deque_push_front(__param_self_: *mut stc_slot_deque, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_start: i64 = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_start == (*__param_self_).end: 1 else: 0) != 0) {
        if ((if not stc_slot_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }

        (__local_start = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut *mut stc_slot_head = ((*__param_self_).cbuf + ((__local_start as i64) as usize))

    ((*__param_self_).start = __local_start)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_slot_deque_insert_n(__param_self_: *mut stc_slot_deque, __param_idx: i64, __param_arr: *const *mut stc_slot_head, __param_n: i64) -> stc_slot_deque_iter {
    var __local_it_: stc_slot_deque_iter = stc_slot_deque_insert_uninit(__param_self_, __param_idx, __param_n)

    var __local_i: i64 = __param_idx

    var __local_j: i64 = ((0 as i64))


    while ((if __local_j < __param_n: 1 else: 0) != 0) {
        ((*(stc_slot_deque_at_mut(__param_self_, __local_i))) = (__param_arr[__local_j]))

        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


    return __local_it_

}

pub unsafe fn stc_slot_deque_insert_uninit(__param_self_: *mut stc_slot_deque, __param_idx: i64, __param_n: i64) -> stc_slot_deque_iter {
    var __local_len: i64 = ((stc_slot_deque_size((__param_self_ as *const stc_slot_deque)) as i64))

    var __local_it_: stc_slot_deque_iter = stc_slot_deque_iter { _s: (__param_self_ as *const stc_slot_deque) }

    if ((if (__local_len + __param_n) >= (*__param_self_).capmask: 1 else: 0) != 0) {
        if ((if not stc_slot_deque_reserve(__param_self_, ((__local_len + __param_n) as i64)): 1 else: 0) != 0) {
            return __local_it_
        }
    }

    (__local_it_.pos = ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    (__local_it_.ref = (*__param_self_).cbuf + (((*(&raw const __local_it_ as *const stc_slot_deque_iter)).pos as i64) as usize))

    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    if ((if (*(&raw const __local_it_ as *const stc_slot_deque_iter)).pos < (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove(((((*(&raw const __local_it_ as *const stc_slot_deque_iter)).ref + ((__param_n as i64) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __local_it_ as *const stc_slot_deque_iter)).ref as *const c_void) as *const u8), (((if 1 != 0: (((__local_len - __param_idx) * (sizeof[usize]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))
    } else {
        var __local_i: i64 = (((__local_len - 1) as i64))

        var __local_j: i64 = (((__local_i + __param_n) as i64))


        while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
            ((*(stc_slot_deque_at_mut(__param_self_, __local_j))) = (*(stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __local_i))))

            (__local_i = __local_i - 1)

            (__local_j = __local_j - 1)


        }

    }

    return __local_it_

}

pub unsafe fn stc_slot_deque_erase_n(__param_self_: *mut stc_slot_deque, __param_idx: i64, __param_n: i64) {
    var __local_len: i64 = ((stc_slot_deque_size((__param_self_ as *const stc_slot_deque)) as i64))

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
        ((*(stc_slot_deque_at_mut(__param_self_, __local_i_1))) = (*(stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __local_j))))

        (__local_i_1 = __local_i_1 + 1)

        (__local_j = __local_j + 1)


    }


    ((*__param_self_).end = ((((((*__param_self_).end - __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

}

pub unsafe fn stc_slot_deque_at(__param_self_: *const stc_slot_deque, __param_idx: i64) -> *const *mut stc_slot_head {
    if (((if not ((if ((__param_idx as u64)) < ((stc_slot_deque_size(__param_self_) as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_deque_at".ptr, c"deque.h".ptr, (53 as i32), c"((size_t)(idx) < (size_t)(stc_slot_deque_size(self)))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).cbuf + ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_at_mut(__param_self_: *mut stc_slot_deque, __param_idx: i64) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __param_idx) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_push_back(__param_self_: *mut stc_slot_deque, __param_val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_push(__param_self_, __param_val) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_pop_back(__param_self_: *mut stc_slot_deque) {
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_deque_pop_back".ptr, c"deque.h".ptr, (67 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))


}

pub unsafe fn stc_slot_deque_pull_back(__param_self_: *mut stc_slot_deque) -> *mut stc_slot_head {
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_slot_deque_pull_back".ptr, c"deque.h".ptr, (73 as i32), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    return ((((*__param_self_).cbuf[(*__param_self_).end]) as *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_insert_at(__param_self_: *mut stc_slot_deque, __param_it_: stc_slot_deque_iter, __param_val: *mut stc_slot_head) -> stc_slot_deque_iter {
    var __local_idx: i64 = ((((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64))

    return stc_slot_deque_insert_n(__param_self_, __local_idx, (&raw const __param_val as *const *mut stc_slot_head), (1 as i64))

}

pub unsafe fn stc_slot_deque_erase_at(__param_self_: *mut stc_slot_deque, __param_it_: stc_slot_deque_iter) -> stc_slot_deque_iter {
    stc_slot_deque_erase_n(__param_self_, (((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64), (1 as i64))

    if ((if (*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it_

}

pub unsafe fn stc_slot_deque_erase_range(__param_self_: *mut stc_slot_deque, __param_it1: stc_slot_deque_iter, __param_it2: stc_slot_deque_iter) -> stc_slot_deque_iter {
    var __local_idx1: i64 = ((((((*(&raw const __param_it1 as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64))

    var __local_idx2: i64 = ((((((*(&raw const __param_it2 as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64))

    stc_slot_deque_erase_n(__param_self_, __local_idx1, ((__local_idx2 - __local_idx1) as i64))

    if ((if (*(&raw const __param_it1 as *const stc_slot_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it1.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it1

}

pub unsafe fn stc_word_deque_reserve(__param_self_: *mut stc_word_deque, __param_cap: i64) -> bool {
    var __local_oldpow2: i64 = ((((*__param_self_).capmask + (((*__param_self_).capmask as i64) & (1 as i64))) as i64))

    var __local_newpow2: i64 = ((c_next_pow2(((__param_cap + 1) as i64)) as i64))

    if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
        return (((((*__param_self_).cbuf != null)) as bool))
    }

    var __local_d: *mut u64 = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[u64]() as i64)) as i64) else: ((__local_oldpow2 * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64))

    if ((if __local_d == null: 1 else: 0) != 0) {
        return ((false as bool))
    }

    var __local_head: i64 = (((__local_oldpow2 - (*__param_self_).start) as i64))

    if (not ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0)) {
        if ((if __local_head < (*__param_self_).end: 1 else: 0) != 0) {
            with_memcpy(((((__local_d + ((__local_newpow2 as i64) as usize)) - ((__local_head as i64) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((*__param_self_).start = (((__local_newpow2 - __local_head) as i64)))

        } else {
            with_memcpy((((__local_d + ((__local_oldpow2 as i64) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((*__param_self_).end * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

            ((*__param_self_).end = (*__param_self_).end + __local_oldpow2)

        }
    }

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

    ((*__param_self_).cbuf = __local_d)

    return ((true as bool))

}

pub unsafe fn stc_word_deque_clear(__param_self_: *mut stc_word_deque) {
    var __local_i: stc_word_deque_iter = stc_word_deque_begin((((&raw const (*__param_self_) as *const stc_word_deque) as *mut stc_word_deque) as *const stc_word_deque))

    while ((*(&raw const __local_i as *const stc_word_deque_iter)).ref != null) {


        stc_word_deque_next((&raw mut __local_i as *mut stc_word_deque_iter))

    }


    ((*__param_self_).start = ((0 as i64)))

    ((*__param_self_).end = ((0 as i64)))


}

pub unsafe fn stc_word_deque_drop(__param_cself: *const stc_word_deque) {
    var __local_self_: *mut stc_word_deque = ((__param_cself as *mut stc_word_deque))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    stc_word_deque_clear(__local_self_)

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))

}

pub unsafe fn stc_word_deque_push(__param_self_: *mut stc_word_deque, __param_value: u64) -> *mut u64 {
    var __local_end: i64 = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_end == (*__param_self_).start: 1 else: 0) != 0) {
        if ((if not stc_word_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut u64))
        }

        (__local_end = ((((((*__param_self_).end + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut u64 = ((*__param_self_).cbuf + (((*__param_self_).end as i64) as usize))

    ((*__param_self_).end = __local_end)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_word_deque_shrink_to_fit(__param_self_: *mut stc_word_deque) {
    var __local_sz: i64 = ((stc_word_deque_size((__param_self_ as *const stc_word_deque)) as i64))

    var __local_newpow2: i64 = ((c_next_pow2(((__local_sz + 1) as i64)) as i64))

    if ((if __local_newpow2 > (*__param_self_).capmask: 1 else: 0) != 0) {
        return
    }

    if ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove((((*__param_self_).cbuf as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

        ((*__param_self_).start = ((0 as i64)))

        ((*__param_self_).end = __local_sz)


    } else {
        var __local_n: i64 = (((((*__param_self_).capmask - (*__param_self_).start) + 1) as i64))

        with_memmove(((((*__param_self_).cbuf + (((__local_newpow2 - __local_n) as i64) as usize)) as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

        ((*__param_self_).start = (((__local_newpow2 - __local_n) as i64)))

    }

    ((*__param_self_).cbuf = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[u64]() as i64)) as i64) else: ((((*__param_self_).capmask + 1) * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as i64)))

}

pub fn stc_word_deque_advance(__param_it_: stc_word_deque_iter, __param_n: i64) -> stc_word_deque_iter {
    var __local_len: i64 = ((unsafe { stc_word_deque_size((*(&raw const __param_it_ as *const stc_word_deque_iter))._s) } as i64))

    var __local_pos: i64 = (unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos

    var __local_idx: i64 = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).start) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).capmask as i64)) as i64))


    (__param_it_.pos = (((((__local_pos + __param_n) as i64) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).capmask as i64)) as i64)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos - __local_pos) as i64) as usize))

    if ((if not ((if (((__local_idx + __param_n) as u64)) < ((__local_len as u64)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut u64)))
    }

    return __param_it_

}

pub unsafe fn stc_word_deque_put_n(__param_self_: *mut stc_word_deque, __param_raw: *const u64, __param_n: i64) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_word_deque_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

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

pub unsafe fn stc_word_deque_from_n(__param_raw: *const u64, __param_n: i64) -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque_with_capacity(__param_n)

    stc_word_deque_put_n((&raw mut __local_out as *mut stc_word_deque), __param_raw, __param_n)

    return __local_out

}

pub fn stc_word_deque_clone(__param_q: stc_word_deque) -> stc_word_deque {
    var __local_out: stc_word_deque = __param_q

    var __local_self_: *mut stc_word_deque = ((&raw mut __local_out as *mut stc_word_deque))



    (__local_out.start = ((0 as i64)))

    (__local_out.end = ((unsafe { stc_word_deque_size(((&raw mut __param_q as *mut stc_word_deque) as *const stc_word_deque)) } as i64)))

    (__local_out.capmask = (((c_next_pow2((((unsafe *(&raw const __local_out as *const stc_word_deque)).end + 1) as i64)) - 1) as i64)))

    (__local_out.cbuf = (((with_alloc((((if 1 != 0: ((((unsafe *(&raw const __local_out as *const stc_word_deque)).capmask + 1) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64)))

    var __local_i: i64 = ((0 as i64))

    if ((unsafe *(&raw const __local_out as *const stc_word_deque)).cbuf != null) {
        var __local_it_: stc_word_deque_iter = unsafe { stc_word_deque_begin(((&raw mut __param_q as *mut stc_word_deque) as *const stc_word_deque)) }

        while ((unsafe *(&raw const __local_it_ as *const stc_word_deque_iter)).ref != null) {
            var __ci_expr_old_0: i64 = __local_i

            (__local_i = __local_i + 1)

            ((unsafe __local_out.cbuf[__ci_expr_old_0]) = (unsafe *((*(&raw const __local_it_ as *const stc_word_deque_iter)).ref)))


            unsafe { stc_word_deque_next((&raw mut __local_it_ as *mut stc_word_deque_iter)) }

        }

    }

    return __local_out

}

pub unsafe fn stc_word_deque_value_clone(__param_self_: *const stc_word_deque, __param_val: u64) -> u64 {

    return __param_val

}

pub unsafe fn stc_word_deque_copy(__param_self_: *mut stc_word_deque, __param_other: *const stc_word_deque) -> Unit {
    if ((if __param_self_ == __param_other: 1 else: 0) != 0) {
        return
    }

    stc_word_deque_drop((__param_self_ as *const stc_word_deque))

    let __ci_copy_18: stc_word_deque = stc_word_deque_clone((*__param_other))
    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __ci_copy_18 as *const u8), sizeof[stc_word_deque]())

}

pub unsafe fn stc_word_deque_size(__param_self_: *const stc_word_deque) -> i64 {
    return ((((*__param_self_).end - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64))

}

pub unsafe fn stc_word_deque_capacity(__param_self_: *const stc_word_deque) -> i64 {
    return (*__param_self_).capmask

}

pub unsafe fn stc_word_deque_is_empty(__param_self_: *const stc_word_deque) -> bool {
    return (((((*__param_self_).start == (*__param_self_).end)) as bool))

}

pub unsafe fn stc_word_deque_value_toraw(__param_pval: *const u64) -> u64 {
    return (*__param_pval)

}

pub unsafe fn stc_word_deque_front(__param_self_: *const stc_word_deque) -> *const u64 {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *const u64))

}

pub unsafe fn stc_word_deque_front_mut(__param_self_: *mut stc_word_deque) -> *mut u64 {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize)) as *mut u64))

}

pub unsafe fn stc_word_deque_back(__param_self_: *const stc_word_deque) -> *const u64 {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const u64))

}

pub unsafe fn stc_word_deque_back_mut(__param_self_: *mut stc_word_deque) -> *mut u64 {
    return ((stc_word_deque_back((__param_self_ as *const stc_word_deque)) as *mut u64))

}

pub unsafe fn stc_word_deque_move(__param_self_: *mut stc_word_deque) -> stc_word_deque {
    var __local_m: stc_word_deque = (*__param_self_)

    ((*__param_self_).end = ((0 as i64)))

    ((*__param_self_).start = (*__param_self_).end)

    ((*__param_self_).capmask = (*__param_self_).start)


    ((*__param_self_).cbuf = ((null as *mut u64)))

    return __local_m

}

pub unsafe fn stc_word_deque_take(__param_self_: *mut stc_word_deque, __param_unowned: stc_word_deque) -> Unit {
    stc_word_deque_drop((__param_self_ as *const stc_word_deque))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_deque]())

}

pub unsafe fn stc_word_deque_pop_front(__param_self_: *mut stc_word_deque) {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_deque_pop_front".ptr, c"queue_prv.h".ptr, (133 as i32), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }


    ((*__param_self_).start = ((((((*__param_self_).start + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

}

pub unsafe fn stc_word_deque_pull_front(__param_self_: *mut stc_word_deque) -> u64 {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_deque_pull_front".ptr, c"queue_prv.h".ptr, (139 as i32), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }

    var __local_s: i64 = (*__param_self_).start

    ((*__param_self_).start = (((((__local_s + 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    return ((*__param_self_).cbuf[__local_s])

}

pub unsafe fn stc_word_deque_begin(__param_self_: *const stc_word_deque) -> stc_word_deque_iter {
    return ((stc_word_deque_iter { ref: (if stc_word_deque_is_empty(__param_self_): ((null) as *mut u64) else: ((*__param_self_).cbuf + (((*__param_self_).start as i64) as usize))), pos: (*__param_self_).start, _s: __param_self_ } as stc_word_deque_iter))

}

pub unsafe fn stc_word_deque_rbegin(__param_self_: *const stc_word_deque) -> stc_word_deque_iter {
    var __local_pos: i64 = ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    return ((stc_word_deque_iter { ref: (if stc_word_deque_is_empty(__param_self_): ((null) as *mut u64) else: ((*__param_self_).cbuf + ((__local_pos as i64) as usize))), pos: __local_pos, _s: __param_self_ } as stc_word_deque_iter))

}

pub unsafe fn stc_word_deque_end(__param_self_: *const stc_word_deque) -> stc_word_deque_iter {

    return ((stc_word_deque_iter.zeroed() as stc_word_deque_iter))

}

pub unsafe fn stc_word_deque_rend(__param_self_: *const stc_word_deque) -> stc_word_deque_iter {

    return ((stc_word_deque_iter.zeroed() as stc_word_deque_iter))

}

pub unsafe fn stc_word_deque_next(__param_it_: *mut stc_word_deque_iter) {
    if ((if (*__param_it_).pos != (*(*__param_it_)._s).capmask: 1 else: 0) != 0) {
        ((*__param_it_).ref = (*__param_it_).ref + 1)

        ((*__param_it_).pos = (*__param_it_).pos + 1)

    } else {
        ((*__param_it_).ref = (*__param_it_).ref - (((*__param_it_).pos as i64) as usize))

        ((*__param_it_).pos = ((0 as i64)))

    }

    if ((if (*__param_it_).pos == (*(*__param_it_)._s).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut u64)))
    }

}

pub unsafe fn stc_word_deque_rnext(__param_it_: *mut stc_word_deque_iter) -> Unit {
    if ((if (*__param_it_).pos == (*(*__param_it_)._s).start: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut u64)))
    } else {
        if ((if (*__param_it_).pos != 0: 1 else: 0) != 0) {
            ((*__param_it_).ref = (*__param_it_).ref - 1)

            ((*__param_it_).pos = (*__param_it_).pos - 1)

        } else {
            ((*__param_it_).pos = (*(*__param_it_)._s).capmask)

            ((*__param_it_).ref = (*__param_it_).ref + (((*__param_it_).pos as i64) as usize))

        }
    }

}

pub unsafe fn stc_word_deque_index(__param_self_: *const stc_word_deque, __param_it_: stc_word_deque_iter) -> i64 {
    return ((((*(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64))

}

pub unsafe fn stc_word_deque_adjust_end_(__param_self_: *mut stc_word_deque, __param_n: i64) {
    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

}

pub unsafe fn stc_word_deque_push_front(__param_self_: *mut stc_word_deque, __param_value: u64) -> *mut u64 {
    var __local_start: i64 = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64))

    if ((if __local_start == (*__param_self_).end: 1 else: 0) != 0) {
        if ((if not stc_word_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as i64)): 1 else: 0) != 0) {
            return ((null as *mut u64))
        }

        (__local_start = ((((((*__param_self_).start - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    }

    var __local_v: *mut u64 = ((*__param_self_).cbuf + ((__local_start as i64) as usize))

    ((*__param_self_).start = __local_start)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_word_deque_insert_n(__param_self_: *mut stc_word_deque, __param_idx: i64, __param_arr: *const u64, __param_n: i64) -> stc_word_deque_iter {
    var __local_it_: stc_word_deque_iter = stc_word_deque_insert_uninit(__param_self_, __param_idx, __param_n)

    var __local_i: i64 = __param_idx

    var __local_j: i64 = ((0 as i64))


    while ((if __local_j < __param_n: 1 else: 0) != 0) {
        ((*(stc_word_deque_at_mut(__param_self_, __local_i))) = (((__param_arr[__local_j]) as u64)))

        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


    return __local_it_

}

pub unsafe fn stc_word_deque_insert_uninit(__param_self_: *mut stc_word_deque, __param_idx: i64, __param_n: i64) -> stc_word_deque_iter {
    var __local_len: i64 = ((stc_word_deque_size((__param_self_ as *const stc_word_deque)) as i64))

    var __local_it_: stc_word_deque_iter = stc_word_deque_iter { _s: (__param_self_ as *const stc_word_deque) }

    if ((if (__local_len + __param_n) >= (*__param_self_).capmask: 1 else: 0) != 0) {
        if ((if not stc_word_deque_reserve(__param_self_, ((__local_len + __param_n) as i64)): 1 else: 0) != 0) {
            return __local_it_
        }
    }

    (__local_it_.pos = ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    (__local_it_.ref = (*__param_self_).cbuf + (((*(&raw const __local_it_ as *const stc_word_deque_iter)).pos as i64) as usize))

    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    if ((if (*(&raw const __local_it_ as *const stc_word_deque_iter)).pos < (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove(((((*(&raw const __local_it_ as *const stc_word_deque_iter)).ref + ((__param_n as i64) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __local_it_ as *const stc_word_deque_iter)).ref as *const c_void) as *const u8), (((if 1 != 0: (((__local_len - __param_idx) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))
    } else {
        var __local_i: i64 = (((__local_len - 1) as i64))

        var __local_j: i64 = (((__local_i + __param_n) as i64))


        while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
            ((*(stc_word_deque_at_mut(__param_self_, __local_j))) = (*(stc_word_deque_at((__param_self_ as *const stc_word_deque), __local_i))))

            (__local_i = __local_i - 1)

            (__local_j = __local_j - 1)


        }

    }

    return __local_it_

}

pub unsafe fn stc_word_deque_erase_n(__param_self_: *mut stc_word_deque, __param_idx: i64, __param_n: i64) {
    var __local_len: i64 = ((stc_word_deque_size((__param_self_ as *const stc_word_deque)) as i64))

    if (((if not ((if (__param_idx + __param_n) <= __local_len: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_deque_erase_n".ptr, c"deque.h".ptr, (149 as i32), c"idx + n <= len".ptr)
    } else {
        0
    }

    var __local_i: i64 = ((((__param_idx + __param_n) - 1) as i64))

    while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
        stc_word_deque_at_mut(__param_self_, __local_i)

        (__local_i = __local_i - 1)

    }


    var __local_i_1: i64 = __param_idx

    var __local_j: i64 = (((__local_i_1 + __param_n) as i64))


    while ((if __local_j < __local_len: 1 else: 0) != 0) {
        ((*(stc_word_deque_at_mut(__param_self_, __local_i_1))) = (*(stc_word_deque_at((__param_self_ as *const stc_word_deque), __local_j))))

        (__local_i_1 = __local_i_1 + 1)

        (__local_j = __local_j + 1)


    }


    ((*__param_self_).end = ((((((*__param_self_).end - __param_n) as i64) & ((*__param_self_).capmask as i64)) as i64)))

}

pub unsafe fn stc_word_deque_at(__param_self_: *const stc_word_deque, __param_idx: i64) -> *const u64 {
    if (((if not ((if ((__param_idx as u64)) < ((stc_word_deque_size(__param_self_) as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_deque_at".ptr, c"deque.h".ptr, (53 as i32), c"((size_t)(idx) < (size_t)(stc_word_deque_size(self)))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).cbuf + ((((((*__param_self_).start + __param_idx) as i64) & ((*__param_self_).capmask as i64)) as i64) as usize)) as *const u64))

}

pub unsafe fn stc_word_deque_at_mut(__param_self_: *mut stc_word_deque, __param_idx: i64) -> *mut u64 {
    return ((stc_word_deque_at((__param_self_ as *const stc_word_deque), __param_idx) as *mut u64))

}

pub unsafe fn stc_word_deque_push_back(__param_self_: *mut stc_word_deque, __param_val: u64) -> *mut u64 {
    return ((stc_word_deque_push(__param_self_, __param_val) as *mut u64))

}

pub unsafe fn stc_word_deque_pop_back(__param_self_: *mut stc_word_deque) {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_deque_pop_back".ptr, c"deque.h".ptr, (67 as i32), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))


}

pub unsafe fn stc_word_deque_pull_back(__param_self_: *mut stc_word_deque) -> u64 {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"stc_word_deque_pull_back".ptr, c"deque.h".ptr, (73 as i32), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as i64) & ((*__param_self_).capmask as i64)) as i64)))

    return ((*__param_self_).cbuf[(*__param_self_).end])

}

pub unsafe fn stc_word_deque_insert_at(__param_self_: *mut stc_word_deque, __param_it_: stc_word_deque_iter, __param_val: u64) -> stc_word_deque_iter {
    var __local_idx: i64 = ((((((*(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64))

    return stc_word_deque_insert_n(__param_self_, __local_idx, (&raw const __param_val as *const u64), (1 as i64))

}

pub unsafe fn stc_word_deque_erase_at(__param_self_: *mut stc_word_deque, __param_it_: stc_word_deque_iter) -> stc_word_deque_iter {
    stc_word_deque_erase_n(__param_self_, (((((*(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64), (1 as i64))

    if ((if (*(&raw const __param_it_ as *const stc_word_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut u64)))
    }

    return __param_it_

}

pub unsafe fn stc_word_deque_erase_range(__param_self_: *mut stc_word_deque, __param_it1: stc_word_deque_iter, __param_it2: stc_word_deque_iter) -> stc_word_deque_iter {
    var __local_idx1: i64 = ((((((*(&raw const __param_it1 as *const stc_word_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64))

    var __local_idx2: i64 = ((((((*(&raw const __param_it2 as *const stc_word_deque_iter)).pos - (*__param_self_).start) as i64) & ((*__param_self_).capmask as i64)) as i64))

    stc_word_deque_erase_n(__param_self_, __local_idx1, ((__local_idx2 - __local_idx1) as i64))

    if ((if (*(&raw const __param_it1 as *const stc_word_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it1.ref = ((null as *mut u64)))
    }

    return __param_it1

}

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

pub unsafe fn stc_slotrefs_sort(__param_arr: *mut stc_slotref, __param_n: i64) {
    stc_slotrefs_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

pub unsafe fn stc_slotrefs_lower_bound(__param_arr: *const stc_slotref, __param_raw: stc_slotref, __param_n: i64) -> i64 {
    return stc_slotrefs_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

pub unsafe fn stc_slotrefs_binary_search(__param_arr: *const stc_slotref, __param_raw: stc_slotref, __param_n: i64) -> i64 {
    return stc_slotrefs_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

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

pub unsafe fn stc_i64s_sort(__param_arr: *mut i64, __param_n: i64) {
    stc_i64s_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

pub unsafe fn stc_i64s_lower_bound(__param_arr: *const i64, __param_raw: i64, __param_n: i64) -> i64 {
    return stc_i64s_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

pub unsafe fn stc_i64s_binary_search(__param_arr: *const i64, __param_raw: i64, __param_n: i64) -> i64 {
    return stc_i64s_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

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

pub unsafe fn stc_u64s_sort(__param_arr: *mut u64, __param_n: i64) {
    stc_u64s_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

pub unsafe fn stc_u64s_lower_bound(__param_arr: *const u64, __param_raw: u64, __param_n: i64) -> i64 {
    return stc_u64s_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

pub unsafe fn stc_u64s_binary_search(__param_arr: *const u64, __param_raw: u64, __param_n: i64) -> i64 {
    return stc_u64s_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

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

pub unsafe fn stc_f64s_sort(__param_arr: *mut f64, __param_n: i64) {
    stc_f64s_sort_lowhigh(__param_arr, (0 as i64), ((__param_n - 1) as i64))

}

pub unsafe fn stc_f64s_lower_bound(__param_arr: *const f64, __param_raw: f64, __param_n: i64) -> i64 {
    return stc_f64s_lower_bound_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

pub unsafe fn stc_f64s_binary_search(__param_arr: *const f64, __param_raw: f64, __param_n: i64) -> i64 {
    return stc_f64s_binary_search_range(__param_arr, __param_raw, (0 as i64), __param_n)

}

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

pub fn c_popcount(__param_x: u64) -> i32 {
    return (__param_x as u64).popcount()

}

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

pub unsafe fn cbits_drop(__param_self_: *mut cbits) {
    with_free((((*__param_self_).buffer as *mut c_void) as *mut u8))

}

pub unsafe fn cbits_size(__param_self_: *const cbits) -> i64 {
    return (*__param_self_)._size

}

pub unsafe fn cbits_take(__param_self_: *mut cbits, __param_other: cbits) -> *mut cbits {
    if ((if (*__param_self_).buffer != (*(&raw const __param_other as *const cbits)).buffer: 1 else: 0) != 0) {
        cbits_drop(__param_self_)

        with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_other as *const u8), sizeof[cbits]())

    }

    return __param_self_

}

pub fn cbits_clone(__param_other: cbits) -> cbits {
    var __local_set: cbits = __param_other

    var __local_bytes: i64 = ((((((unsafe *(&raw const __param_other as *const cbits))._size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64))

    (__local_set.buffer = ((unsafe { c_safe_memcpy((with_alloc((((if 1 != 0: __local_bytes else: (-1 as i64)) as u64) as i64)) as *mut c_void), ((*(&raw const __param_other as *const cbits)).buffer as *const c_void), __local_bytes) } as *mut u64)))

    return __local_set

}

pub unsafe fn cbits_copy(__param_self_: *mut cbits, __param_other: *const cbits) -> *mut cbits {
    if ((if (*__param_self_).buffer == (*__param_other).buffer: 1 else: 0) != 0) {
        return __param_self_
    }

    if ((if (*__param_self_)._size != (*__param_other)._size: 1 else: 0) != 0) {
        return ((cbits_take(__param_self_, cbits_clone((*__param_other))) as *mut cbits))
    }

    with_memcpy((((*__param_self_).buffer as *mut c_void) as *mut u8), (((*__param_other).buffer as *const c_void) as *const u8), (((if 1 != 0: (((((*__param_other)._size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

    return __param_self_

}

pub unsafe fn cbits_resize(__param_self_: *mut cbits, __param_size: i64, __param_value: bool) -> bool {
    var __local_new_w: i64 = ((((__param_size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    var __local_osize: i64 = (*__param_self_)._size

    var __local_old_w: i64 = ((((__local_osize + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))


    var __local_b: *mut u64 = (((with_realloc((((*__param_self_).buffer as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_new_w * (sizeof[u64]() as i64)) as i64) else: ((__local_old_w * (sizeof[u64]() as i64)) as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64))

    if ((if __local_b == null: 1 else: 0) != 0) {
        return ((false as bool))
    }

    ((*__param_self_).buffer = __local_b)

    ((*__param_self_)._size = __param_size)

    if ((if __param_size > __local_osize: 1 else: 0) != 0) {
        with_memset(((((*__param_self_).buffer + ((__local_old_w as i64) as usize)) as *mut c_void) as *mut u8), ((0 - (__param_value as i32)) as i32), (((if 1 != 0: (((__local_new_w - __local_old_w) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

        if (((__local_osize as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) != 0) {
            var __local_mask: u64 = ((((((1 as u64) << (((__local_osize as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64) -% (1 as u64)) as u64))

            if __param_value {
                (((*__param_self_).buffer[(__local_old_w - 1)]) = (((*__param_self_).buffer[(__local_old_w - 1)]) as u64) | ((~__local_mask) as u64))
            } else {
                (((*__param_self_).buffer[(__local_old_w - 1)]) = (((*__param_self_).buffer[(__local_old_w - 1)]) as u64) & (__local_mask as u64))
            }

        }

    }

    return ((true as bool))

}

pub unsafe fn cbits_set_all(__param_self_: *mut cbits, __param_value: bool) -> Unit {
    with_memset((((*__param_self_).buffer as *mut c_void) as *mut u8), ((0 - (__param_value as i32)) as i32), (((if 1 != 0: ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64))

}

pub unsafe fn cbits_set_pattern(__param_self_: *mut cbits, __param_pattern: u64) {
    var __local_n: i64 = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = __param_pattern)

    }

}

pub unsafe fn cbits_move(__param_self_: *mut cbits) -> cbits {
    var __local_tmp: cbits = (*__param_self_)

    ((*__param_self_).buffer = ((null as *mut u64)))

    ((*__param_self_)._size = ((0 as i64)))


    return __local_tmp

}

pub fn cbits_with_size(__param_size: i64, __param_value: bool) -> cbits {
    var __local_set: cbits = cbits { buffer: ((with_alloc((((if 1 != 0: ((((__param_size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64), _size: __param_size }

    unsafe { cbits_set_all((&raw mut __local_set as *mut cbits), __param_value) }

    return __local_set

}

pub fn cbits_with_pattern(__param_size: i64, __param_pattern: u64) -> cbits {
    var __local_set: cbits = cbits { buffer: ((with_alloc((((if 1 != 0: ((((__param_size + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) * (sizeof[u64]() as i64)) as i64) else: (-1 as i64)) as u64) as i64)) as *mut c_void) as *mut u64), _size: __param_size }

    unsafe { cbits_set_pattern((&raw mut __local_set as *mut cbits), __param_pattern) }

    return __local_set

}

pub unsafe fn cbits_test(__param_self_: *const cbits, __param_i: i64) -> bool {
    return ((((((((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) & (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64)) != 0)) as bool))

}

pub unsafe fn cbits_at(__param_self_: *const cbits, __param_i: i64) -> bool {
    if (((if not ((if ((__param_i as u64)) < ((cbits_size(__param_self_) as u64)): 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_at".ptr, c"cbits.h".ptr, (269 as i32), c"((size_t)(i) < (size_t)(cbits_size(self)))".ptr)
    } else {
        0
    }

    return cbits_test(__param_self_, __param_i)

}

pub unsafe fn cbits_set(__param_self_: *mut cbits, __param_i: i64) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) | (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64))

}

pub unsafe fn cbits_reset(__param_self_: *mut cbits, __param_i: i64) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) & ((~((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32))) as u64))

}

pub unsafe fn cbits_set_value(__param_self_: *mut cbits, __param_i: i64, __param_b: bool) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) ^ ((((((0 - (__param_b as i32)) as u64) ^ (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64)) as u64) & (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64)) as u64))

}

pub unsafe fn cbits_flip(__param_self_: *mut cbits, __param_i: i64) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[u64]() as i64)))]) as u64) ^ (((1 as u64) << (((__param_i as i64) & (((8 * (sizeof[u64]() as i64)) - 1) as i64)) as u32)) as u64))

}

pub unsafe fn cbits_flip_all(__param_self_: *mut cbits) {
    var __local_n: i64 = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as u64) ^ ((~(0 as u64)) as u64))

    }

}

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
            cbits_set((&raw mut __local_set as *mut cbits), __local_n)
        }

    }

    return __local_set

}

pub unsafe fn cbits_intersect(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_intersect".ptr, c"cbits.h".ptr, (298 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: i64 = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as u64) & (((*__param_other).buffer[__local_n]) as u64))

    }

}

pub unsafe fn cbits_union(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_union".ptr, c"cbits.h".ptr, (304 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: i64 = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as u64) | (((*__param_other).buffer[__local_n]) as u64))

    }

}

pub unsafe fn cbits_xor(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_xor".ptr, c"cbits.h".ptr, (310 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: i64 = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[u64]() as i64)) - 1)) / (8 * (sizeof[u64]() as i64))) as i64))

    while true {
        var __ci_expr_old_0: i64 = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as u64) ^ (((*__param_other).buffer[__local_n]) as u64))

    }

}

pub unsafe fn cbits_count(__param_self_: *const cbits) -> i64 {
    return _cbits_count(((*__param_self_).buffer as *const u64), (cbits_size(__param_self_) as i64))

}

pub unsafe fn cbits_to_str(__param_self_: *const cbits, __param_out: *mut c_char, __param_start: i64, __param_stop: i64) -> *mut c_char {
    return ((_cbits_to_str(((*__param_self_).buffer as *const u64), (cbits_size(__param_self_) as i64), __param_out, __param_start, __param_stop) as *mut c_char))

}

pub unsafe fn cbits_subset_of(__param_self_: *const cbits, __param_other: *const cbits) -> bool {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_subset_of".ptr, c"cbits.h".ptr, (322 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    return _cbits_subset_of(((*__param_self_).buffer as *const u64), ((*__param_other).buffer as *const u64), (cbits_size(__param_self_) as i64))

}

pub unsafe fn cbits_disjoint(__param_self_: *const cbits, __param_other: *const cbits) -> bool {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as i64) != 0) {
        __assert_rtn(c"cbits_disjoint".ptr, c"cbits.h".ptr, (327 as i32), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    return _cbits_disjoint(((*__param_self_).buffer as *const u64), ((*__param_other).buffer as *const u64), (cbits_size(__param_self_) as i64))

}
