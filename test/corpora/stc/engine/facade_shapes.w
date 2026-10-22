// Migrated from C
use std.engines.stc_testing.defs
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

pub unsafe fn stc_slot_set_drop(__param_cself: *const stc_slot_set) {
    var __local_self_: *mut stc_slot_set = ((__param_cself as *mut stc_slot_set))

    if ((if (*__param_cself).meta == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_set_wipe_(__local_self_)

    (sizeof[hmap_meta]() as usize)

    with_free((((*__local_self_).meta as *mut c_void) as *mut u8))


    (sizeof[usize]() as usize)

    with_free((((*__local_self_).table as *mut c_void) as *mut u8))


}

pub unsafe fn stc_slot_set_clear(__param_self_: *mut stc_slot_set) -> Unit {
    if ((if (*__param_self_).meta == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_set_wipe_(__param_self_)

    ((*__param_self_).size = ((0 as c_long)))

    with_memset((((*__param_self_).meta as *mut c_void) as *mut u8), (0 as c_int), (((if 1 != 0: (((sizeof[hmap_meta]() as c_long) * (*__param_self_).bucket_count) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

}

pub unsafe fn stc_slot_set_reserve(__param__self: *mut stc_slot_set, __param__cap: c_long) -> bool {
    var __local__newcap: c_long = (((if (if __param__cap == 9223372036854775807: 1 else: 0) != 0: (*__param__self).size else: __param__cap) as c_long))

    var __local__newbucks: c_long = ((((((__local__newcap as f32) / i_max_load_factor) as c_long) + 4) as c_long))

    (__local__newbucks = ((c_next_pow2(__local__newbucks) as c_long)))

    var __ci_expr_logic_0: c_int

    if ((if __local__newbucks == (*__param__self).bucket_count: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if (if __param__cap <= (((((*__param__self).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        return true
    }


    var __local_map: stc_slot_set = (*__param__self)

    var __local_self_: *mut stc_slot_set = ((&raw mut __local_map as *mut stc_slot_set))



    (__local_map.table = (((with_alloc((((if 1 != 0: ((__local__newbucks * (sizeof[usize]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))

    (__local_map.meta = (((with_alloc_zeroed((((if 1 != 0: ((__local__newbucks + 1) as c_long) else: (-1 as c_long)) as c_ulong) as i64), (((if 1 != 0: (sizeof[hmap_meta]() as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut hmap_meta)))

    (__local_map.bucket_count = __local__newbucks)

    var __local_ok: bool = with 0 as __ci_expr_seq_26 {
        var __ci_expr_logic_1: c_int = 0
        if ((*(&raw const __local_map as *const stc_slot_set)).table != null) {
            (__ci_expr_logic_1 = (if (*(&raw const __local_map as *const stc_slot_set)).meta != null: 1 else: 0))
        }
        (__ci_expr_logic_1 != 0)
    }

    if __local_ok {
        ((__local_map.meta[__local__newbucks])).set_dist(((1023 as c_ushort)))

        var __local_d: *const *mut stc_slot_head = (((*__param__self).table as *const *mut stc_slot_head))

        var __local_m: *const hmap_meta = (((*__param__self).meta as *const hmap_meta))

        var __local_i: c_long = ((0 as c_long))

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

            ((*__local__xp) = (*__local__yp))

            ((*__local__yp) = __local__tv)

            if not ((0 != 0)) {
                break
            }
        }

    }

    (sizeof[hmap_meta]() as usize)

    with_free((((*(&raw const __local_map as *const stc_slot_set)).meta as *mut c_void) as *mut u8))


    (sizeof[usize]() as usize)

    with_free((((*(&raw const __local_map as *const stc_slot_set)).table as *mut c_void) as *mut u8))


    return __local_ok

}

pub unsafe fn stc_slot_set_erase_entry(__param_self_: *mut stc_slot_set, __param__val: *mut *mut stc_slot_head) {
    var __local_d: *mut *mut stc_slot_head = (*__param_self_).table

    var __local_m: *mut hmap_meta = (*__param_self_).meta

    var __local_i: c_ulong = ((((((__param__val as usize) -% (__local_d as usize)) as c_long) / (sizeof[usize]() as c_long)) as c_ulong))

    var __local_j: c_ulong = __local_i


    var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    stc_slot_set_value_drop((__param_self_ as *const stc_slot_set), __param__val)

    while true {
        (__local_j = ((((((__local_j as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

        if ((if ((__local_m[__local_j])).dist() < 2: 1 else: 0) != 0) {
            break
        }

        ((__local_d[__local_i]) = (__local_d[__local_j]))

        ((__local_m[__local_i]) = (__local_m[__local_j]))

        ((__local_m[__local_i])).set_dist((((__local_m[__local_i])).dist() -% 1))

        (__local_i = __local_j)

    }

    ((__local_m[__local_i])).set_dist(((0 as c_ushort)))

    ((*__param_self_).size = (*__param_self_).size - 1)

}

pub unsafe fn stc_slot_set_max_load_factor(__param_self_: *const stc_slot_set) -> f32 {

    return i_max_load_factor

}

pub unsafe fn stc_slot_set_capacity(__param_map: *const stc_slot_set) -> c_long {
    return (((((*__param_map).bucket_count as f32) * i_max_load_factor) as c_long))

}

pub unsafe fn stc_slot_set_bucket_lookup_(__param_self_: *const stc_slot_set, __param_rkeyptr: *const *mut stc_slot_head) -> stc_slot_set_result {
    var __local__hash: c_ulong = (((*(*__param_rkeyptr)).hash.unwrap()(((*__param_rkeyptr) as *const c_void)) as c_ulong))

    var __local__idxmask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

    var __local__res: stc_slot_set_result = stc_slot_set_result { idx: ((__local__hash as c_ulong) & (__local__idxmask as c_ulong)), hashx: (((((((__local__hash as c_ulong) >> (24 as c_uint))) as c_ulong) & (63 as c_ulong))) as u8), dist: 1 }

    while ((if (*(&raw const __local__res as *const stc_slot_set_result)).dist <= (((*__param_self_).meta[(*(&raw const __local__res as *const stc_slot_set_result)).idx])).dist(): 1 else: 0) != 0) {
        if ((if (((*__param_self_).meta[(*(&raw const __local__res as *const stc_slot_set_result)).idx])).hashx() == (*(&raw const __local__res as *const stc_slot_set_result)).hashx: 1 else: 0) != 0) {
            var __local__raw: *mut stc_slot_head = (*((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const stc_slot_set_result)).idx]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

            if ((if (*(&raw const __local__raw as *const *mut stc_slot_head)).cmp.unwrap()(((*(&raw const __local__raw as *const *mut stc_slot_head)) as *const c_void), ((*__param_rkeyptr) as *const c_void)) == 0: 1 else: 0) != 0) {
                (__local__res.ref = (((&raw const ((*__param_self_).table[(*(&raw const __local__res as *const stc_slot_set_result)).idx]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

                break

            }

        }

        (__local__res.idx = (((((((*(&raw const __local__res as *const stc_slot_set_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local__idxmask as c_ulong)) as c_ulong)))

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

    var __local_mnew: hmap_meta = with 0 as __ci_bits_seq_59 { var __ci_bits: hmap_meta = hmap_meta.zeroed(); __ci_bits.set_hashx((((((((*(&raw const __local_res as *const stc_slot_set_result)).hashx as c_uint) as c_int) as c_uint) & (63 as c_uint))) as c_ushort)); __ci_bits.set_dist((((((((*(&raw const __local_res as *const stc_slot_set_result)).dist as c_uint) as c_int) as c_uint) & (1023 as c_uint))) as c_ushort)); __ci_bits }

    var __local_mcur: hmap_meta = ((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx])

    (((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) = __local_mnew)

    if ((if __local_mcur.dist() != 0: 1 else: 0) != 0) {
        var __local_mask: c_ulong = (((((*__param_self_).bucket_count as c_ulong) -% (1 as c_ulong)) as c_ulong))

        var __local_dcur: *mut stc_slot_head = (*((*(&raw const __local_res as *const stc_slot_set_result)).ref))

        while true {
            (__local_res.idx = (((((((*(&raw const __local_res as *const stc_slot_set_result)).idx as c_ulong) +% (1 as c_ulong)) as c_ulong) & (__local_mask as c_ulong)) as c_ulong)))

            __local_mcur.set_dist((__local_mcur.dist() +% 1))

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx])).dist() == 0: 1 else: 0) != 0) {
                break
            }

            if ((if (((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx])).dist() < __local_mcur.dist(): 1 else: 0) != 0) {
                loop {
                    var __local__xp: *mut hmap_meta = ((&raw mut __local_mcur as *mut hmap_meta))

                    var __local__yp: *mut hmap_meta = (((&raw const ((*__param_self_).meta[(*(&raw const __local_res as *const stc_slot_set_result)).idx]) as *const hmap_meta) as *mut hmap_meta))


                    var __local__tv: hmap_meta = (*__local__xp)

                    ((*__local__xp) = (*__local__yp))

                    ((*__local__yp) = __local__tv)

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
    return ((not ((*__param_map).size != 0)))

}

pub unsafe fn stc_slot_set_size(__param_map: *const stc_slot_set) -> c_long {
    return (*__param_map).size

}

pub unsafe fn stc_slot_set_bucket_count(__param_map: *mut stc_slot_set) -> c_long {
    return (*__param_map).bucket_count

}

pub unsafe fn stc_slot_set_contains(__param_self_: *const stc_slot_set, __param_rkey: *mut stc_slot_head) -> bool {
    var __ci_expr_logic_0: c_int = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref != null: 1 else: 0))
    }

    return (__ci_expr_logic_0 != 0)


}

pub unsafe fn stc_slot_set_shrink_to_fit(__param_self_: *mut stc_slot_set) -> Unit {
    stc_slot_set_reserve(__param_self_, (9223372036854775807 as c_long))

}

pub unsafe fn stc_slot_set_insert_entry_(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> stc_slot_set_result {
    if ((if (*__param_self_).size >= (((((*__param_self_).bucket_count as f32) * i_max_load_factor) as c_long)): 1 else: 0) != 0) {
        if ((if not stc_slot_set_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 2) as c_long)): 1 else: 0) != 0) {
            return ((stc_slot_set_result.zeroed() as stc_slot_set_result))
        }
    }

    var __local_res: stc_slot_set_result = stc_slot_set_bucket_insert_((__param_self_ as *const stc_slot_set), ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const stc_slot_set_result)).inserted as c_int))

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

    ((*__param_self_).size = ((0 as c_long)))

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

pub unsafe fn stc_slot_set_put_n(__param_self_: *mut stc_slot_set, __param_raw: *const *mut stc_slot_head, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

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

pub unsafe fn stc_slot_set_from_n(__param_raw: *const *mut stc_slot_head, __param_n: c_long) -> stc_slot_set {
    var __local_cx: stc_slot_set = stc_slot_set.zeroed()

    stc_slot_set_put_n((&raw mut __local_cx as *mut stc_slot_set), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_set_with_capacity(__param_cap: c_long) -> stc_slot_set {
    var __local_cx: stc_slot_set = stc_slot_set.zeroed()

    unsafe { stc_slot_set_reserve((&raw mut __local_cx as *mut stc_slot_set), __param_cap) }

    return __local_cx

}

pub unsafe fn stc_slot_set_begin(__param_self_: *const stc_slot_set) -> stc_slot_set_iter {
    var __local_it_: stc_slot_set_iter = stc_slot_set_iter { ref: (*__param_self_).table, _end: (*__param_self_).table, _mref: (*__param_self_).meta }

    if ((if (*(&raw const __local_it_ as *const stc_slot_set_iter)).ref == null: 1 else: 0) != 0) {
        return __local_it_
    }

    (__local_it_._end = (*(&raw const __local_it_ as *const stc_slot_set_iter))._end + (((*__param_self_).bucket_count as c_long) as usize))

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

pub fn stc_slot_set_advance(__param_it_: stc_slot_set_iter, __param_n: c_ulong) -> stc_slot_set_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_ulong = __local_n

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

    var __ci_expr_logic_0: c_int = 0

    if ((if (*__param_self_).size != 0: 1 else: 0) != 0) {
        (__local_ref = stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref)

        (__ci_expr_logic_0 = (if (if __local_ref != null: 1 else: 0) != 0: 1 else: 0))

    }

    if (__ci_expr_logic_0 != 0) {
        return ((stc_slot_set_iter { ref: __local_ref, _end: ((&raw const ((*__param_self_).table[(*__param_self_).bucket_count]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head), _mref: ((&raw const ((*__param_self_).meta[((((__local_ref as usize) -% ((*__param_self_).table as usize)) as c_long) / (sizeof[usize]() as c_long))]) as *const hmap_meta) as *mut hmap_meta) } as stc_slot_set_iter))
    }


    return stc_slot_set_end(__param_self_)

}

pub unsafe fn stc_slot_set_get(__param_self_: *const stc_slot_set, __param_rkey: *mut stc_slot_head) -> *const *mut stc_slot_head {
    return (((if (*__param_self_).size != 0: stc_slot_set_bucket_lookup_(__param_self_, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head)).ref else: (null as *mut *mut stc_slot_head)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_set_get_mut(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    return ((stc_slot_set_get((__param_self_ as *const stc_slot_set), __param_rkey) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_set_erase(__param_self_: *mut stc_slot_set, __param_rkey: *mut stc_slot_head) -> c_int {
    var __local_ref: *mut *mut stc_slot_head

    var __ci_expr_logic_0: c_int = 0

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
        return false
    }

    var __local_i: stc_slot_set_iter = stc_slot_set_begin(__param_self_)

    while ((*(&raw const __local_i as *const stc_slot_set_iter)).ref != null) {
        var __local__raw: *mut stc_slot_head = (*((*(&raw const __local_i as *const stc_slot_set_iter)).ref))

        if ((if not stc_slot_set_contains(__param_other, __local__raw): 1 else: 0) != 0) {
            return false
        }


        stc_slot_set_next((&raw mut __local_i as *mut stc_slot_set_iter))

    }


    return true

}

unsafe fn stc_slot_set_wipe_(__param_self_: *mut stc_slot_set) {
    var __local_d: *mut *mut stc_slot_head = (*__param_self_).table

    var __local_m: *const hmap_meta = (((*__param_self_).meta as *const hmap_meta))

    var __local_n: c_long = (*__param_self_).bucket_count

    var __local_i: c_long = ((0 as c_long))

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

    (sizeof[stc_slot_sset_node]() as usize)

    with_free((((*__local_self_).nodes as *mut c_void) as *mut u8))


}

pub unsafe fn stc_slot_sset_reserve(__param_self_: *mut stc_slot_sset, __param_cap: c_long) -> bool {
    if ((if __param_cap <= (*__param_self_).capacity: 1 else: 0) != 0) {
        return false
    }

    var __local_nodes: *mut stc_slot_sset_node = (((with_realloc((((*__param_self_).nodes as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: (((__param_cap + 1) * (sizeof[stc_slot_sset_node]() as c_long)) as c_long) else: ((((*__param_self_).capacity + 1) * (sizeof[stc_slot_sset_node]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut stc_slot_sset_node))

    if ((if __local_nodes == null: 1 else: 0) != 0) {
        return false
    }

    ((__local_nodes[0]) = ((stc_slot_sset_node.zeroed() as stc_slot_sset_node)))

    ((*__param_self_).nodes = __local_nodes)

    ((*__param_self_).capacity = ((__param_cap as c_int)))

    return true

}

pub unsafe fn stc_slot_sset_find_it(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head, __param_out: *mut stc_slot_sset_iter) -> *mut *mut stc_slot_head {
    var __local_tn: c_int = (*__param_self_).root

    var __local_d: *mut stc_slot_sset_node = with 0 as __ci_expr_seq_6 {
        ((*__param_out)._d = (*__param_self_).nodes)
        (*__param_out)._d
    }

    ((*__param_out)._top = ((0 as c_int)))

    while (__local_tn != 0) {
        var __local_c: c_int

        var __local__raw: *mut stc_slot_head = (*((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

        (__local_c = (((*(&raw const __local__raw as *const *mut stc_slot_head)).cmp.unwrap()(((*(&raw const __local__raw as *const *mut stc_slot_head)) as *const c_void), ((*(&raw mut __param_rkey as *mut *mut stc_slot_head)) as *const c_void)) as c_int)))

        if ((if __local_c < 0: 1 else: 0) != 0) {
            (__local_tn = (((__local_d[__local_tn]).link[1] as c_int)))
        } else {
            if ((if __local_c > 0: 1 else: 0) != 0) {
                var __ci_expr_old_0: c_int = (*__param_out)._top

                ((*__param_out)._top = (*__param_out)._top + 1)

                ((*__param_out)._st[__ci_expr_old_0] = __local_tn)


                (__local_tn = (((__local_d[__local_tn]).link[0] as c_int)))

            } else {
                ((*__param_out)._tn = (((__local_d[__local_tn]).link[1] as c_int)))

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

    var __ci_expr_logic_0: c_int = 0

    if ((if (*(&raw const __local_it_ as *const stc_slot_sset_iter)).ref == null: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw const __local_it_ as *const stc_slot_sset_iter))._top != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tn: c_int = with 0 as __ci_expr_seq_11 {
            (__local_it_._top = (*(&raw const __local_it_ as *const stc_slot_sset_iter))._top - 1)
            ((*(&raw const __local_it_ as *const stc_slot_sset_iter))._st[(*(&raw const __local_it_ as *const stc_slot_sset_iter))._top] as c_int)
        }

        (__local_it_._tn = ((((*(&raw const __local_it_ as *const stc_slot_sset_iter))._d[__local_tn]).link[1] as c_int)))

        (__local_it_.ref = (((&raw const (__local_it_._d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    }


    return __local_it_

}

pub unsafe fn stc_slot_sset_front(__param_self_: *const stc_slot_sset) -> *mut *mut stc_slot_head {
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_tn: c_int = (*__param_self_).root

    while ((__local_d[__local_tn]).link[0] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[0] as c_int)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_sset_back(__param_self_: *const stc_slot_sset) -> *mut *mut stc_slot_head {
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_tn: c_int = (*__param_self_).root

    while ((__local_d[__local_tn]).link[1] != 0) {
        (__local_tn = (((__local_d[__local_tn]).link[1] as c_int)))
    }

    return (((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_sset_erase(__param_self_: *mut stc_slot_sset, __param_rkey: *mut stc_slot_head) -> c_int {
    var __local_erased: c_int = ((0 as c_int))

    var __local_root: c_int = ((stc_slot_sset_erase_r_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head), (&raw mut __local_erased as *mut c_int)) as c_int))

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
        if ((if with_memcmp((((&raw mut __local_k1 as *mut *mut stc_slot_head) as *const c_void) as *const u8), (((&raw mut __local_k2 as *mut *mut stc_slot_head) as *const c_void) as *const u8), ((sizeof[usize]() as c_ulong) as i64)) == 0: 1 else: 0) != 0) {
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

    (__local_it_._top = ((0 as c_int)))


    (__local_it_._tn = (*__param_self_).root)

    if ((*(&raw const __local_it_ as *const stc_slot_sset_iter))._tn != 0) {
        stc_slot_sset_next((&raw mut __local_it_ as *mut stc_slot_sset_iter))
    }

    return __local_it_

}

pub unsafe fn stc_slot_sset_next(__param_it_: *mut stc_slot_sset_iter) -> Unit {
    var __local_tn: c_int = (*__param_it_)._tn

    var __ci_expr_logic_0: c_int

    if ((*__param_it_)._top != 0) {
        (__ci_expr_logic_0 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_0 = (if __local_tn != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        while (__local_tn != 0) {
            var __ci_expr_old_1: c_int = (*__param_it_)._top

            ((*__param_it_)._top = (*__param_it_)._top + 1)

            ((*__param_it_)._st[__ci_expr_old_1] = __local_tn)


            (__local_tn = ((((*__param_it_)._d[__local_tn]).link[0] as c_int)))

        }

        ((*__param_it_)._top = (*__param_it_)._top - 1)

        (__local_tn = (((*__param_it_)._st[(*__param_it_)._top] as c_int)))


        ((*__param_it_)._tn = ((((*__param_it_)._d[__local_tn]).link[1] as c_int)))

        ((*__param_it_).ref = (((&raw const ((*__param_it_)._d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

    } else {
        ((*__param_it_).ref = ((null as *mut *mut stc_slot_head)))
    }


}

pub unsafe fn stc_slot_sset_is_empty(__param_self_: *const stc_slot_sset) -> bool {
    return (((*__param_self_).size == 0))

}

pub unsafe fn stc_slot_sset_size(__param_self_: *const stc_slot_sset) -> c_long {
    return (((*__param_self_).size as c_long))

}

pub unsafe fn stc_slot_sset_capacity(__param_self_: *const stc_slot_sset) -> c_long {
    return (((*__param_self_).capacity as c_long))

}

pub unsafe fn stc_slot_sset_find(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> stc_slot_sset_iter {
    var __local_it_: stc_slot_sset_iter

    stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter))

    return __local_it_

}

pub unsafe fn stc_slot_sset_contains(__param_self_: *const stc_slot_sset, __param_rkey: *mut stc_slot_head) -> bool {
    var __local_it_: stc_slot_sset_iter

    return ((stc_slot_sset_find_it(__param_self_, __param_rkey, (&raw mut __local_it_ as *mut stc_slot_sset_iter)) != null))

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

    ((*__param_self_).head = ((0 as c_int)))

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

    var __local_tn: c_int = ((stc_slot_sset_insert_entry_i_(__param_self_, (*__param_self_).root, ((&raw mut __param_rkey as *mut *mut stc_slot_head) as *const *mut stc_slot_head), (&raw mut __local_res as *mut stc_slot_sset_result)) as c_int))

    ((*__param_self_).root = __local_tn)

    ((*__param_self_).size = (*__param_self_).size + ((*(&raw const __local_res as *const stc_slot_sset_result)).inserted as c_int))

    return __local_res

}

pub unsafe fn stc_slot_sset_end(__param_self_: *const stc_slot_sset) -> stc_slot_sset_iter {
    var __local_it_: stc_slot_sset_iter


    (__local_it_.ref = ((null as *mut *mut stc_slot_head)))

    (__local_it_._top = ((0 as c_int)))

    (__local_it_._tn = ((0 as c_int)))


    return __local_it_

}

pub fn stc_slot_sset_advance(__param_it_: stc_slot_sset_iter, __param_n: c_ulong) -> stc_slot_sset_iter {
    var __local_n = __param_n
    while true {
        var __ci_expr_logic_1: c_int = 0

        var __ci_expr_old_0: c_ulong = __local_n

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

pub unsafe fn stc_slot_sset_put_n(__param_self_: *mut stc_slot_sset, __param_raw: *const *mut stc_slot_head, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

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

pub unsafe fn stc_slot_sset_from_n(__param_raw: *const *mut stc_slot_head, __param_n: c_long) -> stc_slot_sset {
    var __local_cx: stc_slot_sset = stc_slot_sset.zeroed()

    stc_slot_sset_put_n((&raw mut __local_cx as *mut stc_slot_sset), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_sset_with_capacity(__param_cap: c_long) -> stc_slot_sset {
    var __local_cx: stc_slot_sset = stc_slot_sset.zeroed()

    unsafe { stc_slot_sset_reserve((&raw mut __local_cx as *mut stc_slot_sset), __param_cap) }

    return __local_cx

}

unsafe fn stc_slot_sset_new_node_(__param_self_: *mut stc_slot_sset, __param_level: c_int) -> c_int {
    var __local_tn: c_int

    if ((if (*__param_self_).disp != 0: 1 else: 0) != 0) {
        (__local_tn = (*__param_self_).disp)

        ((*__param_self_).disp = ((((*__param_self_).nodes[__local_tn]).link[1] as c_int)))

    } else {
        if ((if (*__param_self_).head == (*__param_self_).capacity: 1 else: 0) != 0) {
            if ((if not stc_slot_sset_reserve(__param_self_, (((((*__param_self_).head * 3) / 2) + 4) as c_long)): 1 else: 0) != 0) {
                return 0
            }
        }

        ((*__param_self_).head = (*__param_self_).head + 1)

        (__local_tn = (*__param_self_).head)


    }

    var __local_dn: *mut stc_slot_sset_node = (((&raw const ((*__param_self_).nodes[__local_tn]) as *const stc_slot_sset_node) as *mut stc_slot_sset_node))

    ((*__local_dn).link[1] = ((0 as c_int)))

    ((*__local_dn).link[0] = (((*__local_dn).link[1] as c_int)))


    ((*__local_dn).level = ((__param_level as c_char)))

    return __local_tn

}

pub unsafe fn stc_slot_sset_skew_(__param_d: *mut stc_slot_sset_node, __param_tn: c_int) -> c_int {
    var __local_tn = __param_tn
    var __ci_expr_logic_0: c_int = 0

    if ((if __local_tn != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_0 = (if (if (__param_d[(__param_d[__local_tn]).link[0]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_0 != 0) {
        var __local_tmp: c_int = (((__param_d[__local_tn]).link[0] as c_int))

        ((__param_d[__local_tn]).link[0] = (((__param_d[__local_tmp]).link[1] as c_int)))

        ((__param_d[__local_tmp]).link[1] = __local_tn)

        (__local_tn = __local_tmp)

    }


    return __local_tn

}

pub unsafe fn stc_slot_sset_split_(__param_d: *mut stc_slot_sset_node, __param_tn: c_int) -> c_int {
    var __local_tn = __param_tn
    if ((if (__param_d[(__param_d[(__param_d[__local_tn]).link[1]]).link[1]]).level == (__param_d[__local_tn]).level: 1 else: 0) != 0) {
        var __local_tmp: c_int = (((__param_d[__local_tn]).link[1] as c_int))

        ((__param_d[__local_tn]).link[1] = (((__param_d[__local_tmp]).link[0] as c_int)))

        ((__param_d[__local_tmp]).link[0] = __local_tn)

        (__local_tn = __local_tmp)

        ((__param_d[__local_tn]).level = (__param_d[__local_tn]).level + 1)

    }

    return __local_tn

}

pub unsafe fn stc_slot_sset_insert_entry_i_(__param_self_: *mut stc_slot_sset, __param_tn: c_int, __param_rkey: *const *mut stc_slot_head, __param__res: *mut stc_slot_sset_result) -> c_int {
    var __local_up: List[c_int] = [0; 64]

    var __local_tx: c_int = __param_tn


    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    var __local_c: c_int

    var __local_top: c_int = ((0 as c_int))

    var __local_dir: c_int = ((0 as c_int))


    while (__local_tx != 0) {
        var __ci_expr_old_0: c_int = __local_top

        (__local_top = __local_top + 1)

        (__local_up[__ci_expr_old_0] = __local_tx)


        var __local__raw: *mut stc_slot_head = (*((&raw const (__local_d[__local_tx]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

        (__local_c = (((*(&raw const __local__raw as *const *mut stc_slot_head)).cmp.unwrap()(((*(&raw const __local__raw as *const *mut stc_slot_head)) as *const c_void), ((*__param_rkey) as *const c_void)) as c_int)))

        if ((if __local_c == 0: 1 else: 0) != 0) {
            ((*__param__res).ref = (((&raw const (__local_d[__local_tx]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

            return __param_tn

        }


        (__local_dir = (((if __local_c < 0: 1 else: 0) as c_int)))

        (__local_tx = (((__local_d[__local_tx]).link[__local_dir] as c_int)))

    }

    (__local_tx = ((stc_slot_sset_new_node_(__param_self_, (1 as c_int)) as c_int)))

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
        var __ci_expr_old_1: c_int = __local_top

        (__local_top = __local_top - 1)

        if (not (__ci_expr_old_1 != 0)) {
            break
        }

        if ((if __local_top != 0: 1 else: 0) != 0) {
            (__local_dir = (((if (__local_d[__local_up[(__local_top - 1)]]).link[1] == __local_up[__local_top]: 1 else: 0) as c_int)))
        }

        (__local_up[__local_top] = ((stc_slot_sset_skew_(__local_d, (__local_up[__local_top] as c_int)) as c_int)))

        (__local_up[__local_top] = ((stc_slot_sset_split_(__local_d, (__local_up[__local_top] as c_int)) as c_int)))

        if (__local_top != 0) {
            ((__local_d[__local_up[(__local_top - 1)]]).link[__local_dir] = ((__local_up[__local_top] as c_int)))
        }

    }

    return __local_up[0]

}

pub unsafe fn stc_slot_sset_erase_r_(__param_self_: *mut stc_slot_sset, __param_tn: c_int, __param_rkey: *const *mut stc_slot_head, __param_erased: *mut c_int) -> c_int {
    var __local_tn = __param_tn
    var __local_d: *mut stc_slot_sset_node = (*__param_self_).nodes

    if ((if __local_tn == 0: 1 else: 0) != 0) {
        return 0
    }

    var __local_raw: *mut stc_slot_head = (*((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

    var __local_tx: c_int

    var __local_c: c_int = (((*(&raw mut __local_raw as *mut *mut stc_slot_head)).cmp.unwrap()(((*(&raw mut __local_raw as *mut *mut stc_slot_head)) as *const c_void), ((*__param_rkey) as *const c_void)) as c_int))

    if ((if __local_c != 0: 1 else: 0) != 0) {
        ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] = ((stc_slot_sset_erase_r_(__param_self_, ((__local_d[__local_tn]).link[(if __local_c < 0: 1 else: 0)] as c_int), __param_rkey, __param_erased) as c_int)))
    } else {
        var __ci_expr_old_0: c_int = (*__param_erased)

        ((*__param_erased) = (*__param_erased) + 1)

        if ((if __ci_expr_old_0 == 0: 1 else: 0) != 0) {
            stc_slot_sset_value_drop((__param_self_ as *const stc_slot_sset), ((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))
        }


        var __ci_expr_logic_1: c_int = 0

        if ((__local_d[__local_tn]).link[0] != 0) {
            (__ci_expr_logic_1 = (if (__local_d[__local_tn]).link[1] != 0: 1 else: 0))
        }

        if (__ci_expr_logic_1 != 0) {
            (__local_tx = (((__local_d[__local_tn]).link[0] as c_int)))

            while ((__local_d[__local_tx]).link[1] != 0) {
                (__local_tx = (((__local_d[__local_tx]).link[1] as c_int)))
            }

            ((__local_d[__local_tn]).value = (__local_d[__local_tx]).value)

            (__local_raw = (*((&raw const (__local_d[__local_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head)))

            ((__local_d[__local_tn]).link[0] = ((stc_slot_sset_erase_r_(__param_self_, ((__local_d[__local_tn]).link[0] as c_int), ((&raw mut __local_raw as *mut *mut stc_slot_head) as *const *mut stc_slot_head), __param_erased) as c_int)))

        } else {
            (__local_tx = __local_tn)

            (__local_tn = (((__local_d[__local_tn]).link[(if (__local_d[__local_tn]).link[0] == 0: 1 else: 0)] as c_int)))

            ((__local_d[__local_tx]).link[1] = (*__param_self_).disp)

            ((*__param_self_).disp = __local_tx)

        }


    }

    (__local_tx = (((__local_d[__local_tn]).link[1] as c_int)))

    var __ci_expr_logic_2: c_int

    if ((if (__local_d[(__local_d[__local_tn]).link[0]]).level < ((__local_d[__local_tn]).level - 1): 1 else: 0) != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (__local_d[__local_tx]).level < ((__local_d[__local_tn]).level - 1): 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        ((__local_d[__local_tn]).level = (__local_d[__local_tn]).level - 1)

        if ((if (__local_d[__local_tx]).level > (__local_d[__local_tn]).level: 1 else: 0) != 0) {
            ((__local_d[__local_tx]).level = (__local_d[__local_tn]).level)
        }


        (__local_tn = ((stc_slot_sset_skew_(__local_d, __local_tn) as c_int)))

        ((__local_d[__local_tn]).link[1] = ((stc_slot_sset_skew_(__local_d, ((__local_d[__local_tn]).link[1] as c_int)) as c_int)))

        (__local_tx = (((__local_d[__local_tn]).link[1] as c_int)))


        ((__local_d[__local_tx]).link[1] = ((stc_slot_sset_skew_(__local_d, ((__local_d[__local_tx]).link[1] as c_int)) as c_int)))

        (__local_tn = ((stc_slot_sset_split_(__local_d, __local_tn) as c_int)))

        ((__local_d[__local_tn]).link[1] = ((stc_slot_sset_split_(__local_d, ((__local_d[__local_tn]).link[1] as c_int)) as c_int)))

    }


    return __local_tn

}

unsafe fn stc_slot_sset_drop_r_(__param_s: *mut stc_slot_sset, __param_tn: c_int) -> Unit {
    if ((if __param_tn != 0: 1 else: 0) != 0) {
        stc_slot_sset_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[0] as c_int))

        stc_slot_sset_drop_r_(__param_s, (((*__param_s).nodes[__param_tn]).link[1] as c_int))

        stc_slot_sset_value_drop((__param_s as *const stc_slot_sset), ((&raw const ((*__param_s).nodes[__param_tn]).value as *const *mut stc_slot_head) as *mut *mut stc_slot_head))

    }

}

pub unsafe fn stc_slot_pqueue_make_heap(__param_self_: *mut stc_slot_pqueue) {
    var __local_n: c_long = (*__param_self_).size

    var __local_k: c_long = (((__local_n / 2) as c_long))

    while ((if __local_k != 0: 1 else: 0) != 0) {
        stc_slot_pqueue_sift_down_(__param_self_, __local_k, __local_n)

        (__local_k = __local_k - 1)

    }


}

pub unsafe fn stc_slot_pqueue_erase_at(__param_self_: *mut stc_slot_pqueue, __param_idx: c_long) {

    var __local_n: c_long = with 0 as __ci_expr_seq_6 {
        ((*__param_self_).size = (*__param_self_).size - 1)
        (*__param_self_).size
    }

    (((*__param_self_).data[__param_idx]) = ((*__param_self_).data[__local_n]))

    stc_slot_pqueue_sift_down_(__param_self_, ((__param_idx + 1) as c_long), __local_n)

}

pub unsafe fn stc_slot_pqueue_push(__param_self_: *mut stc_slot_pqueue, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    if ((if (*__param_self_).size == (*__param_self_).capacity: 1 else: 0) != 0) {
        if ((if not stc_slot_pqueue_reserve(__param_self_, (((((*__param_self_).size * 3) / 2) + 4) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }
    }

    var __local_arr: *mut *mut stc_slot_head = ((*__param_self_).data - ((1 as c_long) as usize))

    var __local_c: c_long = with 0 as __ci_expr_seq_9 {
        ((*__param_self_).size = (*__param_self_).size + 1)
        (*__param_self_).size
    }

    while true {
        var __ci_expr_logic_0: c_int = 0

        if ((if __local_c > 1: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if (*((&raw const (__local_arr[(__local_c / 2)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)).cmp.unwrap()(((*((&raw const (__local_arr[(__local_c / 2)]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*(&raw mut __param_value as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (not (__ci_expr_logic_0 != 0)) {
            break
        }

        ((__local_arr[__local_c]) = (__local_arr[(__local_c / 2)]))

        (__local_c = __local_c / 2)

    }

    ((__local_arr[__local_c]) = __param_value)

    return (((__local_arr + ((__local_c as c_long) as usize)) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_pqueue_sift_down_(__param_self_: *mut stc_slot_pqueue, __param_idx: c_long, __param_n: c_long) {
    var __local_t: *mut stc_slot_head

    var __local_arr: *mut *mut stc_slot_head = ((*__param_self_).data - ((1 as c_long) as usize))


    var __local_r: c_long = __param_idx

    var __local_c: c_long = (((__param_idx * 2) as c_long))


    while ((if __local_c <= __param_n: 1 else: 0) != 0) {
        (__local_c = __local_c + (if (*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)).cmp.unwrap()(((*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const (__local_arr[(__local_c + (if __local_c < __param_n: 1 else: 0))]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0))

        if ((if not ((if (*((&raw const (__local_arr[__local_r]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)).cmp.unwrap()(((*((&raw const (__local_arr[__local_r]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const (__local_arr[__local_c]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0) != 0): 1 else: 0) != 0) {
            return
        }

        (__local_t = (__local_arr[__local_r]))

        ((__local_arr[__local_r]) = (__local_arr[__local_c]))

        (__local_r = __local_c)

        ((__local_arr[__local_r]) = __local_t)



        (__local_c = __local_c * 2)

    }


}

pub unsafe fn stc_slot_pqueue_put_n(__param_self_: *mut stc_slot_pqueue, __param_raw: *const *mut stc_slot_head, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_slot_pqueue_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub unsafe fn stc_slot_pqueue_reserve(__param_self_: *mut stc_slot_pqueue, __param_cap: c_long) -> bool {
    var __local_n: c_long = (((if (if __param_cap == 9223372036854775807: 1 else: 0) != 0: (*__param_self_).size else: __param_cap) as c_long))

    if ((((if __param_cap > (*__param_self_).capacity: 1 else: 0) as c_int) & ((if __local_n != (*__param_self_).capacity: 1 else: 0) as c_int)) != 0) {
        var __local_d: *mut *mut stc_slot_head = (((with_realloc((((*__param_self_).data as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_n * (sizeof[usize]() as c_long)) as c_long) else: (((*__param_self_).capacity * (sizeof[usize]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

        if ((if __local_d == null: 1 else: 0) != 0) {
            return false
        }

        ((*__param_self_).data = __local_d)

        ((*__param_self_).capacity = __local_n)

    }

    return (((*__param_self_).data != null))

}

pub unsafe fn stc_slot_pqueue_shrink_to_fit(__param_self_: *mut stc_slot_pqueue) -> Unit {
    stc_slot_pqueue_reserve(__param_self_, (9223372036854775807 as c_long))

}

pub fn stc_slot_pqueue_init() -> stc_slot_pqueue {
    return ((stc_slot_pqueue.zeroed() as stc_slot_pqueue))

}

pub unsafe fn stc_slot_pqueue_from_n(__param_raw: *const *mut stc_slot_head, __param_n: c_long) -> stc_slot_pqueue {
    var __local_cx: stc_slot_pqueue = stc_slot_pqueue.zeroed()

    stc_slot_pqueue_put_n((&raw mut __local_cx as *mut stc_slot_pqueue), __param_raw, __param_n)

    return __local_cx

}

pub fn stc_slot_pqueue_with_capacity(__param_cap: c_long) -> stc_slot_pqueue {
    var __local_cx: stc_slot_pqueue = stc_slot_pqueue.zeroed()

    unsafe { stc_slot_pqueue_reserve((&raw mut __local_cx as *mut stc_slot_pqueue), __param_cap) }

    return __local_cx

}

pub unsafe fn stc_slot_pqueue_clear(__param_self_: *mut stc_slot_pqueue) {
    var __local_i: c_long = (*__param_self_).size

    while true {
        var __ci_expr_old_0: c_long = __local_i

        (__local_i = __local_i - 1)

        if (not ((if __ci_expr_old_0 != 0: 1 else: 0) != 0)) {
            break
        }

    }

    ((*__param_self_).size = ((0 as c_long)))

}

pub unsafe fn stc_slot_pqueue_drop(__param_cself: *const stc_slot_pqueue) {
    var __local_self_: *mut stc_slot_pqueue = ((__param_cself as *mut stc_slot_pqueue))

    if ((if (*__local_self_).data == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_pqueue_clear(__local_self_)

    (sizeof[usize]() as usize)

    with_free((((*__local_self_).data as *mut c_void) as *mut u8))


}

pub unsafe fn stc_slot_pqueue_move(__param_self_: *mut stc_slot_pqueue) -> stc_slot_pqueue {
    var __local_m: stc_slot_pqueue = (*__param_self_)

    ((*__param_self_).capacity = ((0 as c_long)))

    ((*__param_self_).size = (*__param_self_).capacity)


    ((*__param_self_).data = ((null as *mut *mut stc_slot_head)))

    return __local_m

}

pub unsafe fn stc_slot_pqueue_take(__param_self_: *mut stc_slot_pqueue, __param_unowned: stc_slot_pqueue) -> Unit {
    stc_slot_pqueue_drop((__param_self_ as *const stc_slot_pqueue))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_slot_pqueue]())

}

pub unsafe fn stc_slot_pqueue_size(__param_q: *const stc_slot_pqueue) -> c_long {
    return (*__param_q).size

}

pub unsafe fn stc_slot_pqueue_is_empty(__param_q: *const stc_slot_pqueue) -> bool {
    return ((not ((*__param_q).size != 0)))

}

pub unsafe fn stc_slot_pqueue_capacity(__param_q: *const stc_slot_pqueue) -> c_long {
    return (*__param_q).capacity

}

pub unsafe fn stc_slot_pqueue_top(__param_self_: *const stc_slot_pqueue) -> *const *mut stc_slot_head {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_pqueue_top".ptr, c"pqueue.h".ptr, (117 as c_int), c"self->size".ptr)
    } else {
        0
    }

    return ((((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_pqueue_pop(__param_self_: *mut stc_slot_pqueue) {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_pqueue_pop".ptr, c"pqueue.h".ptr, (120 as c_int), c"self->size".ptr)
    } else {
        0
    }

    stc_slot_pqueue_erase_at(__param_self_, (0 as c_long))

}

pub unsafe fn stc_slot_pqueue_pull(__param_self_: *mut stc_slot_pqueue) -> *mut stc_slot_head {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_pqueue_pull".ptr, c"pqueue.h".ptr, (123 as c_int), c"self->size".ptr)
    } else {
        0
    }

    var __local_v: *mut stc_slot_head = ((*__param_self_).data[0])

    stc_slot_pqueue_erase_at(__param_self_, (0 as c_long))

    return __local_v

}

pub unsafe fn stc_slot_pqueue_pushpull(__param_self_: *mut stc_slot_pqueue, __param_val: *mut stc_slot_head) -> *mut stc_slot_head {
    var __ci_expr_logic_0: c_int = 0

    if ((*__param_self_).size != 0) {
        (__ci_expr_logic_0 = (if (if (*(&raw mut __param_val as *mut *mut stc_slot_head)).cmp.unwrap()(((*(&raw mut __param_val as *mut *mut stc_slot_head)) as *const c_void), ((*((&raw const ((*__param_self_).data[0]) as *const *mut stc_slot_head) as *mut *mut stc_slot_head)) as *const c_void)) < 0: 1 else: 0) != 0: 1 else: 0))
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

        stc_slot_pqueue_sift_down_(__param_self_, (1 as c_long), (*__param_self_).size)

    }


    return __param_val

}

pub unsafe fn stc_slot_pqueue_exchange(__param_self_: *mut stc_slot_pqueue, __param_val: *mut stc_slot_head) -> *mut stc_slot_head {
    if (((if not ((*__param_self_).size != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_pqueue_exchange".ptr, c"pqueue.h".ptr, (138 as c_int), c"self->size".ptr)
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

    stc_slot_pqueue_sift_down_(__param_self_, (1 as c_long), (*__param_self_).size)

    return __param_val

}

pub unsafe fn stc_slot_deque_reserve(__param_self_: *mut stc_slot_deque, __param_cap: c_long) -> bool {
    var __local_oldpow2: c_long = ((((*__param_self_).capmask + (((*__param_self_).capmask as c_long) & (1 as c_long))) as c_long))

    var __local_newpow2: c_long = ((c_next_pow2(((__param_cap + 1) as c_long)) as c_long))

    if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
        return (((*__param_self_).cbuf != null))
    }

    var __local_d: *mut *mut stc_slot_head = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as c_long)) as c_long) else: ((__local_oldpow2 * (sizeof[usize]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut *mut stc_slot_head))

    if ((if __local_d == null: 1 else: 0) != 0) {
        return false
    }

    var __local_head: c_long = (((__local_oldpow2 - (*__param_self_).start) as c_long))

    if (not ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0)) {
        if ((if __local_head < (*__param_self_).end: 1 else: 0) != 0) {
            with_memcpy(((((__local_d + ((__local_newpow2 as c_long) as usize)) - ((__local_head as c_long) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((*__param_self_).start as c_long) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[usize]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

            ((*__param_self_).start = (((__local_newpow2 - __local_head) as c_long)))

        } else {
            with_memcpy((((__local_d + ((__local_oldpow2 as c_long) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((*__param_self_).end * (sizeof[usize]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

            ((*__param_self_).end = (*__param_self_).end + __local_oldpow2)

        }
    }

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as c_long)))

    ((*__param_self_).cbuf = __local_d)

    return true

}

pub unsafe fn stc_slot_deque_clear(__param_self_: *mut stc_slot_deque) {
    var __local_i: stc_slot_deque_iter = stc_slot_deque_begin((((&raw const (*__param_self_) as *const stc_slot_deque) as *mut stc_slot_deque) as *const stc_slot_deque))

    while ((*(&raw const __local_i as *const stc_slot_deque_iter)).ref != null) {


        stc_slot_deque_next((&raw mut __local_i as *mut stc_slot_deque_iter))

    }


    ((*__param_self_).start = ((0 as c_long)))

    ((*__param_self_).end = ((0 as c_long)))


}

pub unsafe fn stc_slot_deque_drop(__param_cself: *const stc_slot_deque) {
    var __local_self_: *mut stc_slot_deque = ((__param_cself as *mut stc_slot_deque))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    stc_slot_deque_clear(__local_self_)

    (sizeof[usize]() as usize)

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))


}

pub unsafe fn stc_slot_deque_push(__param_self_: *mut stc_slot_deque, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_end: c_long = ((((((*__param_self_).end + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    if ((if __local_end == (*__param_self_).start: 1 else: 0) != 0) {
        if ((if not stc_slot_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }

        (__local_end = ((((((*__param_self_).end + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    }

    var __local_v: *mut *mut stc_slot_head = ((*__param_self_).cbuf + (((*__param_self_).end as c_long) as usize))

    ((*__param_self_).end = __local_end)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_slot_deque_shrink_to_fit(__param_self_: *mut stc_slot_deque) {
    var __local_sz: c_long = ((stc_slot_deque_size((__param_self_ as *const stc_slot_deque)) as c_long))

    var __local_newpow2: c_long = ((c_next_pow2(((__local_sz + 1) as c_long)) as c_long))

    if ((if __local_newpow2 > (*__param_self_).capmask: 1 else: 0) != 0) {
        return
    }

    if ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove((((*__param_self_).cbuf as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[usize]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

        ((*__param_self_).start = ((0 as c_long)))

        ((*__param_self_).end = __local_sz)


    } else {
        var __local_n: c_long = (((((*__param_self_).capmask - (*__param_self_).start) + 1) as c_long))

        with_memmove(((((*__param_self_).cbuf + (((__local_newpow2 - __local_n) as c_long) as usize)) as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[usize]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

        ((*__param_self_).start = (((__local_newpow2 - __local_n) as c_long)))

    }

    ((*__param_self_).cbuf = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[usize]() as c_long)) as c_long) else: ((((*__param_self_).capmask + 1) * (sizeof[usize]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut *mut stc_slot_head)))

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as c_long)))

}

pub fn stc_slot_deque_advance(__param_it_: stc_slot_deque_iter, __param_n: c_long) -> stc_slot_deque_iter {
    var __local_len: c_long = ((unsafe { stc_slot_deque_size((*(&raw const __param_it_ as *const stc_slot_deque_iter))._s) } as c_long))

    var __local_pos: c_long = (unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos

    var __local_idx: c_long = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).start) as c_long) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).capmask as c_long)) as c_long))


    (__param_it_.pos = (((((__local_pos + __param_n) as c_long) & ((unsafe *(*(&raw const __param_it_ as *const stc_slot_deque_iter))._s).capmask as c_long)) as c_long)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - __local_pos) as c_long) as usize))

    if ((if not ((if (((__local_idx + __param_n) as c_ulong)) < ((__local_len as c_ulong)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it_

}

pub unsafe fn stc_slot_deque_put_n(__param_self_: *mut stc_slot_deque, __param_raw: *const *mut stc_slot_head, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

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

pub fn stc_slot_deque_with_capacity(__param_cap: c_long) -> stc_slot_deque {
    var __local_cap = __param_cap
    (__local_cap = ((c_next_pow2(((__local_cap + 1) as c_long)) as c_long)))

    var __local_out: stc_slot_deque = stc_slot_deque { cbuf: (((with_alloc((((if 1 != 0: ((__local_cap * (sizeof[usize]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut *mut stc_slot_head)), start: 0, end: 0, capmask: (__local_cap - 1) }

    return __local_out

}

pub fn stc_slot_deque_with_size_uninit(__param_size: c_long) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_size)

    (__local_out.end = __param_size)

    return __local_out

}

pub unsafe fn stc_slot_deque_with_size(__param_size: c_long, __param_default_raw: *mut stc_slot_head) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_size)

    while ((if (*(&raw const __local_out as *const stc_slot_deque)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: c_long = (*(&raw const __local_out as *const stc_slot_deque)).end

        (__local_out.end = (*(&raw const __local_out as *const stc_slot_deque)).end + 1)

        ((__local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

pub unsafe fn stc_slot_deque_from_n(__param_raw: *const *mut stc_slot_head, __param_n: c_long) -> stc_slot_deque {
    var __local_out: stc_slot_deque = stc_slot_deque_with_capacity(__param_n)

    stc_slot_deque_put_n((&raw mut __local_out as *mut stc_slot_deque), __param_raw, __param_n)

    return __local_out

}

pub unsafe fn stc_slot_deque_size(__param_self_: *const stc_slot_deque) -> c_long {
    return ((((*__param_self_).end - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long))

}

pub unsafe fn stc_slot_deque_capacity(__param_self_: *const stc_slot_deque) -> c_long {
    return (*__param_self_).capmask

}

pub unsafe fn stc_slot_deque_is_empty(__param_self_: *const stc_slot_deque) -> bool {
    return (((*__param_self_).start == (*__param_self_).end))

}

pub unsafe fn stc_slot_deque_value_toraw(__param_pval: *const *mut stc_slot_head) -> *mut stc_slot_head {
    return (*__param_pval)

}

pub unsafe fn stc_slot_deque_front(__param_self_: *const stc_slot_deque) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_front_mut(__param_self_: *mut stc_slot_deque) -> *mut *mut stc_slot_head {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_back(__param_self_: *const stc_slot_deque) -> *const *mut stc_slot_head {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long) as usize)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_back_mut(__param_self_: *mut stc_slot_deque) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_back((__param_self_ as *const stc_slot_deque)) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_move(__param_self_: *mut stc_slot_deque) -> stc_slot_deque {
    var __local_m: stc_slot_deque = (*__param_self_)

    ((*__param_self_).end = ((0 as c_long)))

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
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_deque_pop_front".ptr, c"queue_prv.h".ptr, (133 as c_int), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }


    ((*__param_self_).start = ((((((*__param_self_).start + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

}

pub unsafe fn stc_slot_deque_pull_front(__param_self_: *mut stc_slot_deque) -> *mut stc_slot_head {
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_deque_pull_front".ptr, c"queue_prv.h".ptr, (139 as c_int), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }

    var __local_s: c_long = (*__param_self_).start

    ((*__param_self_).start = (((((__local_s + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    return ((((*__param_self_).cbuf[__local_s]) as *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_begin(__param_self_: *const stc_slot_deque) -> stc_slot_deque_iter {
    return ((stc_slot_deque_iter { ref: (if stc_slot_deque_is_empty(__param_self_): ((null) as *mut *mut stc_slot_head) else: ((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize))), pos: (*__param_self_).start, _s: __param_self_ } as stc_slot_deque_iter))

}

pub unsafe fn stc_slot_deque_rbegin(__param_self_: *const stc_slot_deque) -> stc_slot_deque_iter {
    var __local_pos: c_long = ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    return ((stc_slot_deque_iter { ref: (if stc_slot_deque_is_empty(__param_self_): ((null) as *mut *mut stc_slot_head) else: ((*__param_self_).cbuf + ((__local_pos as c_long) as usize))), pos: __local_pos, _s: __param_self_ } as stc_slot_deque_iter))

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
        ((*__param_it_).ref = (*__param_it_).ref - (((*__param_it_).pos as c_long) as usize))

        ((*__param_it_).pos = ((0 as c_long)))

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

            ((*__param_it_).ref = (*__param_it_).ref + (((*__param_it_).pos as c_long) as usize))

        }
    }

}

pub unsafe fn stc_slot_deque_index(__param_self_: *const stc_slot_deque, __param_it_: stc_slot_deque_iter) -> c_long {
    return ((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long))

}

pub unsafe fn stc_slot_deque_adjust_end_(__param_self_: *mut stc_slot_deque, __param_n: c_long) {
    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

}

pub unsafe fn stc_slot_deque_push_front(__param_self_: *mut stc_slot_deque, __param_value: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    var __local_start: c_long = ((((((*__param_self_).start - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    if ((if __local_start == (*__param_self_).end: 1 else: 0) != 0) {
        if ((if not stc_slot_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut *mut stc_slot_head))
        }

        (__local_start = ((((((*__param_self_).start - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    }

    var __local_v: *mut *mut stc_slot_head = ((*__param_self_).cbuf + ((__local_start as c_long) as usize))

    ((*__param_self_).start = __local_start)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_slot_deque_insert_n(__param_self_: *mut stc_slot_deque, __param_idx: c_long, __param_arr: *const *mut stc_slot_head, __param_n: c_long) -> stc_slot_deque_iter {
    var __local_it_: stc_slot_deque_iter = stc_slot_deque_insert_uninit(__param_self_, __param_idx, __param_n)

    var __local_i: c_long = __param_idx

    var __local_j: c_long = ((0 as c_long))


    while ((if __local_j < __param_n: 1 else: 0) != 0) {
        ((*(stc_slot_deque_at_mut(__param_self_, __local_i))) = (__param_arr[__local_j]))

        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


    return __local_it_

}

pub unsafe fn stc_slot_deque_insert_uninit(__param_self_: *mut stc_slot_deque, __param_idx: c_long, __param_n: c_long) -> stc_slot_deque_iter {
    var __local_len: c_long = ((stc_slot_deque_size((__param_self_ as *const stc_slot_deque)) as c_long))

    var __local_it_: stc_slot_deque_iter = stc_slot_deque_iter { _s: (__param_self_ as *const stc_slot_deque) }

    if ((if (__local_len + __param_n) >= (*__param_self_).capmask: 1 else: 0) != 0) {
        if ((if not stc_slot_deque_reserve(__param_self_, ((__local_len + __param_n) as c_long)): 1 else: 0) != 0) {
            return __local_it_
        }
    }

    (__local_it_.pos = ((((((*__param_self_).start + __param_idx) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    (__local_it_.ref = (*__param_self_).cbuf + (((*(&raw const __local_it_ as *const stc_slot_deque_iter)).pos as c_long) as usize))

    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    if ((if (*(&raw const __local_it_ as *const stc_slot_deque_iter)).pos < (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove(((((*(&raw const __local_it_ as *const stc_slot_deque_iter)).ref + ((__param_n as c_long) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __local_it_ as *const stc_slot_deque_iter)).ref as *const c_void) as *const u8), (((if 1 != 0: (((__local_len - __param_idx) * (sizeof[usize]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))
    } else {
        var __local_i: c_long = (((__local_len - 1) as c_long))

        var __local_j: c_long = (((__local_i + __param_n) as c_long))


        while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
            ((*(stc_slot_deque_at_mut(__param_self_, __local_j))) = (*(stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __local_i))))

            (__local_i = __local_i - 1)

            (__local_j = __local_j - 1)


        }

    }

    return __local_it_

}

pub unsafe fn stc_slot_deque_erase_n(__param_self_: *mut stc_slot_deque, __param_idx: c_long, __param_n: c_long) {
    var __local_len: c_long = ((stc_slot_deque_size((__param_self_ as *const stc_slot_deque)) as c_long))

    if (((if not ((if (__param_idx + __param_n) <= __local_len: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_deque_erase_n".ptr, c"deque.h".ptr, (149 as c_int), c"idx + n <= len".ptr)
    } else {
        0
    }

    var __local_i: c_long = ((((__param_idx + __param_n) - 1) as c_long))

    while ((if __local_i >= __param_idx: 1 else: 0) != 0) {

        (__local_i = __local_i - 1)

    }


    var __local_i_1: c_long = __param_idx

    var __local_j: c_long = (((__local_i_1 + __param_n) as c_long))


    while ((if __local_j < __local_len: 1 else: 0) != 0) {
        ((*(stc_slot_deque_at_mut(__param_self_, __local_i_1))) = (*(stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __local_j))))

        (__local_i_1 = __local_i_1 + 1)

        (__local_j = __local_j + 1)


    }


    ((*__param_self_).end = ((((((*__param_self_).end - __param_n) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

}

pub unsafe fn stc_slot_deque_at(__param_self_: *const stc_slot_deque, __param_idx: c_long) -> *const *mut stc_slot_head {
    if (((if not ((if ((__param_idx as c_ulong)) < ((stc_slot_deque_size(__param_self_) as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_deque_at".ptr, c"deque.h".ptr, (53 as c_int), c"((size_t)(idx) < (size_t)(stc_slot_deque_size(self)))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).cbuf + ((((((*__param_self_).start + __param_idx) as c_long) & ((*__param_self_).capmask as c_long)) as c_long) as usize)) as *const *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_at_mut(__param_self_: *mut stc_slot_deque, __param_idx: c_long) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_at((__param_self_ as *const stc_slot_deque), __param_idx) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_push_back(__param_self_: *mut stc_slot_deque, __param_val: *mut stc_slot_head) -> *mut *mut stc_slot_head {
    return ((stc_slot_deque_push(__param_self_, __param_val) as *mut *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_pop_back(__param_self_: *mut stc_slot_deque) {
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_deque_pop_back".ptr, c"deque.h".ptr, (67 as c_int), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))


}

pub unsafe fn stc_slot_deque_pull_back(__param_self_: *mut stc_slot_deque) -> *mut stc_slot_head {
    if (((if not ((if not stc_slot_deque_is_empty((__param_self_ as *const stc_slot_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_slot_deque_pull_back".ptr, c"deque.h".ptr, (73 as c_int), c"!stc_slot_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    return ((((*__param_self_).cbuf[(*__param_self_).end]) as *mut stc_slot_head))

}

pub unsafe fn stc_slot_deque_insert_at(__param_self_: *mut stc_slot_deque, __param_it_: stc_slot_deque_iter, __param_val: *mut stc_slot_head) -> stc_slot_deque_iter {
    var __local_idx: c_long = ((((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    return stc_slot_deque_insert_n(__param_self_, __local_idx, (&raw const __param_val as *const *mut stc_slot_head), (1 as c_long))

}

pub unsafe fn stc_slot_deque_erase_at(__param_self_: *mut stc_slot_deque, __param_it_: stc_slot_deque_iter) -> stc_slot_deque_iter {
    stc_slot_deque_erase_n(__param_self_, (((((*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long), (1 as c_long))

    if ((if (*(&raw const __param_it_ as *const stc_slot_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it_

}

pub unsafe fn stc_slot_deque_erase_range(__param_self_: *mut stc_slot_deque, __param_it1: stc_slot_deque_iter, __param_it2: stc_slot_deque_iter) -> stc_slot_deque_iter {
    var __local_idx1: c_long = ((((((*(&raw const __param_it1 as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    var __local_idx2: c_long = ((((((*(&raw const __param_it2 as *const stc_slot_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    stc_slot_deque_erase_n(__param_self_, __local_idx1, ((__local_idx2 - __local_idx1) as c_long))

    if ((if (*(&raw const __param_it1 as *const stc_slot_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it1.ref = ((null as *mut *mut stc_slot_head)))
    }

    return __param_it1

}

pub unsafe fn stc_word_deque_reserve(__param_self_: *mut stc_word_deque, __param_cap: c_long) -> bool {
    var __local_oldpow2: c_long = ((((*__param_self_).capmask + (((*__param_self_).capmask as c_long) & (1 as c_long))) as c_long))

    var __local_newpow2: c_long = ((c_next_pow2(((__param_cap + 1) as c_long)) as c_long))

    if ((if __local_newpow2 <= __local_oldpow2: 1 else: 0) != 0) {
        return (((*__param_self_).cbuf != null))
    }

    var __local_d: *mut c_ulonglong = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[c_ulonglong]() as c_long)) as c_long) else: ((__local_oldpow2 * (sizeof[c_ulonglong]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_ulonglong))

    if ((if __local_d == null: 1 else: 0) != 0) {
        return false
    }

    var __local_head: c_long = (((__local_oldpow2 - (*__param_self_).start) as c_long))

    if (not ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0)) {
        if ((if __local_head < (*__param_self_).end: 1 else: 0) != 0) {
            with_memcpy(((((__local_d + ((__local_newpow2 as c_long) as usize)) - ((__local_head as c_long) as usize)) as *mut c_void) as *mut u8), (((__local_d + (((*__param_self_).start as c_long) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_head * (sizeof[c_ulonglong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

            ((*__param_self_).start = (((__local_newpow2 - __local_head) as c_long)))

        } else {
            with_memcpy((((__local_d + ((__local_oldpow2 as c_long) as usize)) as *mut c_void) as *mut u8), ((__local_d as *const c_void) as *const u8), (((if 1 != 0: (((*__param_self_).end * (sizeof[c_ulonglong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

            ((*__param_self_).end = (*__param_self_).end + __local_oldpow2)

        }
    }

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as c_long)))

    ((*__param_self_).cbuf = __local_d)

    return true

}

pub unsafe fn stc_word_deque_clear(__param_self_: *mut stc_word_deque) {
    var __local_i: stc_word_deque_iter = stc_word_deque_begin((((&raw const (*__param_self_) as *const stc_word_deque) as *mut stc_word_deque) as *const stc_word_deque))

    while ((*(&raw const __local_i as *const stc_word_deque_iter)).ref != null) {


        stc_word_deque_next((&raw mut __local_i as *mut stc_word_deque_iter))

    }


    ((*__param_self_).start = ((0 as c_long)))

    ((*__param_self_).end = ((0 as c_long)))


}

pub unsafe fn stc_word_deque_drop(__param_cself: *const stc_word_deque) {
    var __local_self_: *mut stc_word_deque = ((__param_cself as *mut stc_word_deque))

    if ((if (*__local_self_).cbuf == null: 1 else: 0) != 0) {
        return
    }

    stc_word_deque_clear(__local_self_)

    (sizeof[c_ulonglong]() as usize)

    with_free((((*__local_self_).cbuf as *mut c_void) as *mut u8))


}

pub unsafe fn stc_word_deque_push(__param_self_: *mut stc_word_deque, __param_value: c_ulonglong) -> *mut c_ulonglong {
    var __local_end: c_long = ((((((*__param_self_).end + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    if ((if __local_end == (*__param_self_).start: 1 else: 0) != 0) {
        if ((if not stc_word_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut c_ulonglong))
        }

        (__local_end = ((((((*__param_self_).end + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    }

    var __local_v: *mut c_ulonglong = ((*__param_self_).cbuf + (((*__param_self_).end as c_long) as usize))

    ((*__param_self_).end = __local_end)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_word_deque_shrink_to_fit(__param_self_: *mut stc_word_deque) {
    var __local_sz: c_long = ((stc_word_deque_size((__param_self_ as *const stc_word_deque)) as c_long))

    var __local_newpow2: c_long = ((c_next_pow2(((__local_sz + 1) as c_long)) as c_long))

    if ((if __local_newpow2 > (*__param_self_).capmask: 1 else: 0) != 0) {
        return
    }

    if ((if (*__param_self_).start <= (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove((((*__param_self_).cbuf as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_sz * (sizeof[c_ulonglong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

        ((*__param_self_).start = ((0 as c_long)))

        ((*__param_self_).end = __local_sz)


    } else {
        var __local_n: c_long = (((((*__param_self_).capmask - (*__param_self_).start) + 1) as c_long))

        with_memmove(((((*__param_self_).cbuf + (((__local_newpow2 - __local_n) as c_long) as usize)) as *mut c_void) as *mut u8), ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *const c_void) as *const u8), (((if 1 != 0: ((__local_n * (sizeof[c_ulonglong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

        ((*__param_self_).start = (((__local_newpow2 - __local_n) as c_long)))

    }

    ((*__param_self_).cbuf = (((with_realloc((((*__param_self_).cbuf as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_newpow2 * (sizeof[c_ulonglong]() as c_long)) as c_long) else: ((((*__param_self_).capmask + 1) * (sizeof[c_ulonglong]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_ulonglong)))

    ((*__param_self_).capmask = (((__local_newpow2 - 1) as c_long)))

}

pub fn stc_word_deque_advance(__param_it_: stc_word_deque_iter, __param_n: c_long) -> stc_word_deque_iter {
    var __local_len: c_long = ((unsafe { stc_word_deque_size((*(&raw const __param_it_ as *const stc_word_deque_iter))._s) } as c_long))

    var __local_pos: c_long = (unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos

    var __local_idx: c_long = (((((__local_pos - (unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).start) as c_long) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).capmask as c_long)) as c_long))


    (__param_it_.pos = (((((__local_pos + __param_n) as c_long) & ((unsafe *(*(&raw const __param_it_ as *const stc_word_deque_iter))._s).capmask as c_long)) as c_long)))

    (__param_it_.ref = (unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).ref + ((((unsafe *(&raw const __param_it_ as *const stc_word_deque_iter)).pos - __local_pos) as c_long) as usize))

    if ((if not ((if (((__local_idx + __param_n) as c_ulong)) < ((__local_len as c_ulong)): 1 else: 0) != 0): 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut c_ulonglong)))
    }

    return __param_it_

}

pub unsafe fn stc_word_deque_put_n(__param_self_: *mut stc_word_deque, __param_raw: *const c_ulonglong, __param_n: c_long) {
    var __local_raw = __param_raw
    var __local_n = __param_n
    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        stc_word_deque_push(__param_self_, (*__local_raw))

        (__local_raw = __local_raw + 1)

    }

}

pub unsafe fn stc_word_deque_value_drop(__param_self_: *const stc_word_deque, __param_val: *mut c_ulonglong) {
    return
}

pub fn stc_word_deque_init() -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque.zeroed()

    return __local_out

}

pub fn stc_word_deque_with_capacity(__param_cap: c_long) -> stc_word_deque {
    var __local_cap = __param_cap
    (__local_cap = ((c_next_pow2(((__local_cap + 1) as c_long)) as c_long)))

    var __local_out: stc_word_deque = stc_word_deque { cbuf: (((with_alloc((((if 1 != 0: ((__local_cap * (sizeof[c_ulonglong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_ulonglong)), start: 0, end: 0, capmask: (__local_cap - 1) }

    return __local_out

}

pub fn stc_word_deque_with_size_uninit(__param_size: c_long) -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque_with_capacity(__param_size)

    (__local_out.end = __param_size)

    return __local_out

}

pub fn stc_word_deque_with_size(__param_size: c_long, __param_default_raw: c_ulonglong) -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque_with_capacity(__param_size)

    while ((if (unsafe *(&raw const __local_out as *const stc_word_deque)).end < __param_size: 1 else: 0) != 0) {
        var __ci_expr_old_0: c_long = (unsafe *(&raw const __local_out as *const stc_word_deque)).end

        (__local_out.end = (unsafe *(&raw const __local_out as *const stc_word_deque)).end + 1)

        ((unsafe __local_out.cbuf[__ci_expr_old_0]) = __param_default_raw)

    }

    return __local_out

}

pub unsafe fn stc_word_deque_from_n(__param_raw: *const c_ulonglong, __param_n: c_long) -> stc_word_deque {
    var __local_out: stc_word_deque = stc_word_deque_with_capacity(__param_n)

    stc_word_deque_put_n((&raw mut __local_out as *mut stc_word_deque), __param_raw, __param_n)

    return __local_out

}

pub fn stc_word_deque_clone(__param_q: stc_word_deque) -> stc_word_deque {
    var __local_out: stc_word_deque = __param_q

    var __local_self_: *mut stc_word_deque = ((&raw mut __local_out as *mut stc_word_deque))



    (__local_out.start = ((0 as c_long)))

    (__local_out.end = ((unsafe { stc_word_deque_size(((&raw mut __param_q as *mut stc_word_deque) as *const stc_word_deque)) } as c_long)))

    (__local_out.capmask = (((c_next_pow2((((unsafe *(&raw const __local_out as *const stc_word_deque)).end + 1) as c_long)) - 1) as c_long)))

    (__local_out.cbuf = (((with_alloc((((if 1 != 0: ((((unsafe *(&raw const __local_out as *const stc_word_deque)).capmask + 1) * (sizeof[c_ulonglong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_ulonglong)))

    var __local_i: c_long = ((0 as c_long))

    if ((unsafe *(&raw const __local_out as *const stc_word_deque)).cbuf != null) {
        var __local_it_: stc_word_deque_iter = unsafe { stc_word_deque_begin(((&raw mut __param_q as *mut stc_word_deque) as *const stc_word_deque)) }

        while ((unsafe *(&raw const __local_it_ as *const stc_word_deque_iter)).ref != null) {
            var __ci_expr_old_0: c_long = __local_i

            (__local_i = __local_i + 1)

            ((unsafe __local_out.cbuf[__ci_expr_old_0]) = (unsafe *((*(&raw const __local_it_ as *const stc_word_deque_iter)).ref)))


            unsafe { stc_word_deque_next((&raw mut __local_it_ as *mut stc_word_deque_iter)) }

        }

    }

    return __local_out

}

pub unsafe fn stc_word_deque_value_clone(__param_self_: *const stc_word_deque, __param_val: c_ulonglong) -> c_ulonglong {

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

pub unsafe fn stc_word_deque_size(__param_self_: *const stc_word_deque) -> c_long {
    return ((((*__param_self_).end - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long))

}

pub unsafe fn stc_word_deque_capacity(__param_self_: *const stc_word_deque) -> c_long {
    return (*__param_self_).capmask

}

pub unsafe fn stc_word_deque_is_empty(__param_self_: *const stc_word_deque) -> bool {
    return (((*__param_self_).start == (*__param_self_).end))

}

pub unsafe fn stc_word_deque_value_toraw(__param_pval: *const c_ulonglong) -> c_ulonglong {
    return (*__param_pval)

}

pub unsafe fn stc_word_deque_front(__param_self_: *const stc_word_deque) -> *const c_ulonglong {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *const c_ulonglong))

}

pub unsafe fn stc_word_deque_front_mut(__param_self_: *mut stc_word_deque) -> *mut c_ulonglong {
    return ((((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize)) as *mut c_ulonglong))

}

pub unsafe fn stc_word_deque_back(__param_self_: *const stc_word_deque) -> *const c_ulonglong {
    return ((((*__param_self_).cbuf + ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long) as usize)) as *const c_ulonglong))

}

pub unsafe fn stc_word_deque_back_mut(__param_self_: *mut stc_word_deque) -> *mut c_ulonglong {
    return ((stc_word_deque_back((__param_self_ as *const stc_word_deque)) as *mut c_ulonglong))

}

pub unsafe fn stc_word_deque_move(__param_self_: *mut stc_word_deque) -> stc_word_deque {
    var __local_m: stc_word_deque = (*__param_self_)

    ((*__param_self_).end = ((0 as c_long)))

    ((*__param_self_).start = (*__param_self_).end)

    ((*__param_self_).capmask = (*__param_self_).start)


    ((*__param_self_).cbuf = ((null as *mut c_ulonglong)))

    return __local_m

}

pub unsafe fn stc_word_deque_take(__param_self_: *mut stc_word_deque, __param_unowned: stc_word_deque) -> Unit {
    stc_word_deque_drop((__param_self_ as *const stc_word_deque))

    with_memcpy((&raw mut (*__param_self_) as *mut u8), (&raw const __param_unowned as *const u8), sizeof[stc_word_deque]())

}

pub unsafe fn stc_word_deque_pop_front(__param_self_: *mut stc_word_deque) {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_word_deque_pop_front".ptr, c"queue_prv.h".ptr, (133 as c_int), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }


    ((*__param_self_).start = ((((((*__param_self_).start + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

}

pub unsafe fn stc_word_deque_pull_front(__param_self_: *mut stc_word_deque) -> c_ulonglong {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_word_deque_pull_front".ptr, c"queue_prv.h".ptr, (139 as c_int), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }

    var __local_s: c_long = (*__param_self_).start

    ((*__param_self_).start = (((((__local_s + 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    return ((*__param_self_).cbuf[__local_s])

}

pub unsafe fn stc_word_deque_begin(__param_self_: *const stc_word_deque) -> stc_word_deque_iter {
    return ((stc_word_deque_iter { ref: (if stc_word_deque_is_empty(__param_self_): ((null) as *mut c_ulonglong) else: ((*__param_self_).cbuf + (((*__param_self_).start as c_long) as usize))), pos: (*__param_self_).start, _s: __param_self_ } as stc_word_deque_iter))

}

pub unsafe fn stc_word_deque_rbegin(__param_self_: *const stc_word_deque) -> stc_word_deque_iter {
    var __local_pos: c_long = ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    return ((stc_word_deque_iter { ref: (if stc_word_deque_is_empty(__param_self_): ((null) as *mut c_ulonglong) else: ((*__param_self_).cbuf + ((__local_pos as c_long) as usize))), pos: __local_pos, _s: __param_self_ } as stc_word_deque_iter))

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
        ((*__param_it_).ref = (*__param_it_).ref - (((*__param_it_).pos as c_long) as usize))

        ((*__param_it_).pos = ((0 as c_long)))

    }

    if ((if (*__param_it_).pos == (*(*__param_it_)._s).end: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut c_ulonglong)))
    }

}

pub unsafe fn stc_word_deque_rnext(__param_it_: *mut stc_word_deque_iter) -> Unit {
    if ((if (*__param_it_).pos == (*(*__param_it_)._s).start: 1 else: 0) != 0) {
        ((*__param_it_).ref = ((null as *mut c_ulonglong)))
    } else {
        if ((if (*__param_it_).pos != 0: 1 else: 0) != 0) {
            ((*__param_it_).ref = (*__param_it_).ref - 1)

            ((*__param_it_).pos = (*__param_it_).pos - 1)

        } else {
            ((*__param_it_).pos = (*(*__param_it_)._s).capmask)

            ((*__param_it_).ref = (*__param_it_).ref + (((*__param_it_).pos as c_long) as usize))

        }
    }

}

pub unsafe fn stc_word_deque_index(__param_self_: *const stc_word_deque, __param_it_: stc_word_deque_iter) -> c_long {
    return ((((*(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long))

}

pub unsafe fn stc_word_deque_adjust_end_(__param_self_: *mut stc_word_deque, __param_n: c_long) {
    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

}

pub unsafe fn stc_word_deque_push_front(__param_self_: *mut stc_word_deque, __param_value: c_ulonglong) -> *mut c_ulonglong {
    var __local_start: c_long = ((((((*__param_self_).start - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    if ((if __local_start == (*__param_self_).end: 1 else: 0) != 0) {
        if ((if not stc_word_deque_reserve(__param_self_, (((*__param_self_).capmask + 3) as c_long)): 1 else: 0) != 0) {
            return ((null as *mut c_ulonglong))
        }

        (__local_start = ((((((*__param_self_).start - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    }

    var __local_v: *mut c_ulonglong = ((*__param_self_).cbuf + ((__local_start as c_long) as usize))

    ((*__param_self_).start = __local_start)

    ((*__local_v) = __param_value)

    return __local_v

}

pub unsafe fn stc_word_deque_insert_n(__param_self_: *mut stc_word_deque, __param_idx: c_long, __param_arr: *const c_ulonglong, __param_n: c_long) -> stc_word_deque_iter {
    var __local_it_: stc_word_deque_iter = stc_word_deque_insert_uninit(__param_self_, __param_idx, __param_n)

    var __local_i: c_long = __param_idx

    var __local_j: c_long = ((0 as c_long))


    while ((if __local_j < __param_n: 1 else: 0) != 0) {
        ((*(stc_word_deque_at_mut(__param_self_, __local_i))) = (((__param_arr[__local_j]) as c_ulonglong)))

        (__local_i = __local_i + 1)

        (__local_j = __local_j + 1)


    }


    return __local_it_

}

pub unsafe fn stc_word_deque_insert_uninit(__param_self_: *mut stc_word_deque, __param_idx: c_long, __param_n: c_long) -> stc_word_deque_iter {
    var __local_len: c_long = ((stc_word_deque_size((__param_self_ as *const stc_word_deque)) as c_long))

    var __local_it_: stc_word_deque_iter = stc_word_deque_iter { _s: (__param_self_ as *const stc_word_deque) }

    if ((if (__local_len + __param_n) >= (*__param_self_).capmask: 1 else: 0) != 0) {
        if ((if not stc_word_deque_reserve(__param_self_, ((__local_len + __param_n) as c_long)): 1 else: 0) != 0) {
            return __local_it_
        }
    }

    (__local_it_.pos = ((((((*__param_self_).start + __param_idx) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    (__local_it_.ref = (*__param_self_).cbuf + (((*(&raw const __local_it_ as *const stc_word_deque_iter)).pos as c_long) as usize))

    ((*__param_self_).end = ((((((*__param_self_).end + __param_n) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    if ((if (*(&raw const __local_it_ as *const stc_word_deque_iter)).pos < (*__param_self_).end: 1 else: 0) != 0) {
        with_memmove(((((*(&raw const __local_it_ as *const stc_word_deque_iter)).ref + ((__param_n as c_long) as usize)) as *mut c_void) as *mut u8), (((*(&raw const __local_it_ as *const stc_word_deque_iter)).ref as *const c_void) as *const u8), (((if 1 != 0: (((__local_len - __param_idx) * (sizeof[c_ulonglong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))
    } else {
        var __local_i: c_long = (((__local_len - 1) as c_long))

        var __local_j: c_long = (((__local_i + __param_n) as c_long))


        while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
            ((*(stc_word_deque_at_mut(__param_self_, __local_j))) = (*(stc_word_deque_at((__param_self_ as *const stc_word_deque), __local_i))))

            (__local_i = __local_i - 1)

            (__local_j = __local_j - 1)


        }

    }

    return __local_it_

}

pub unsafe fn stc_word_deque_erase_n(__param_self_: *mut stc_word_deque, __param_idx: c_long, __param_n: c_long) {
    var __local_len: c_long = ((stc_word_deque_size((__param_self_ as *const stc_word_deque)) as c_long))

    if (((if not ((if (__param_idx + __param_n) <= __local_len: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_word_deque_erase_n".ptr, c"deque.h".ptr, (149 as c_int), c"idx + n <= len".ptr)
    } else {
        0
    }

    var __local_i: c_long = ((((__param_idx + __param_n) - 1) as c_long))

    while ((if __local_i >= __param_idx: 1 else: 0) != 0) {
        stc_word_deque_at_mut(__param_self_, __local_i)

        (__local_i = __local_i - 1)

    }


    var __local_i_1: c_long = __param_idx

    var __local_j: c_long = (((__local_i_1 + __param_n) as c_long))


    while ((if __local_j < __local_len: 1 else: 0) != 0) {
        ((*(stc_word_deque_at_mut(__param_self_, __local_i_1))) = (*(stc_word_deque_at((__param_self_ as *const stc_word_deque), __local_j))))

        (__local_i_1 = __local_i_1 + 1)

        (__local_j = __local_j + 1)


    }


    ((*__param_self_).end = ((((((*__param_self_).end - __param_n) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

}

pub unsafe fn stc_word_deque_at(__param_self_: *const stc_word_deque, __param_idx: c_long) -> *const c_ulonglong {
    if (((if not ((if ((__param_idx as c_ulong)) < ((stc_word_deque_size(__param_self_) as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_word_deque_at".ptr, c"deque.h".ptr, (53 as c_int), c"((size_t)(idx) < (size_t)(stc_word_deque_size(self)))".ptr)
    } else {
        0
    }

    return ((((*__param_self_).cbuf + ((((((*__param_self_).start + __param_idx) as c_long) & ((*__param_self_).capmask as c_long)) as c_long) as usize)) as *const c_ulonglong))

}

pub unsafe fn stc_word_deque_at_mut(__param_self_: *mut stc_word_deque, __param_idx: c_long) -> *mut c_ulonglong {
    return ((stc_word_deque_at((__param_self_ as *const stc_word_deque), __param_idx) as *mut c_ulonglong))

}

pub unsafe fn stc_word_deque_push_back(__param_self_: *mut stc_word_deque, __param_val: c_ulonglong) -> *mut c_ulonglong {
    return ((stc_word_deque_push(__param_self_, __param_val) as *mut c_ulonglong))

}

pub unsafe fn stc_word_deque_pop_back(__param_self_: *mut stc_word_deque) {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_word_deque_pop_back".ptr, c"deque.h".ptr, (67 as c_int), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))


}

pub unsafe fn stc_word_deque_pull_back(__param_self_: *mut stc_word_deque) -> c_ulonglong {
    if (((if not ((if not stc_word_deque_is_empty((__param_self_ as *const stc_word_deque)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"stc_word_deque_pull_back".ptr, c"deque.h".ptr, (73 as c_int), c"!stc_word_deque_is_empty(self)".ptr)
    } else {
        0
    }

    ((*__param_self_).end = ((((((*__param_self_).end - 1) as c_long) & ((*__param_self_).capmask as c_long)) as c_long)))

    return ((*__param_self_).cbuf[(*__param_self_).end])

}

pub unsafe fn stc_word_deque_insert_at(__param_self_: *mut stc_word_deque, __param_it_: stc_word_deque_iter, __param_val: c_ulonglong) -> stc_word_deque_iter {
    var __local_idx: c_long = ((((((*(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    return stc_word_deque_insert_n(__param_self_, __local_idx, (&raw const __param_val as *const c_ulonglong), (1 as c_long))

}

pub unsafe fn stc_word_deque_erase_at(__param_self_: *mut stc_word_deque, __param_it_: stc_word_deque_iter) -> stc_word_deque_iter {
    stc_word_deque_erase_n(__param_self_, (((((*(&raw const __param_it_ as *const stc_word_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long), (1 as c_long))

    if ((if (*(&raw const __param_it_ as *const stc_word_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it_.ref = ((null as *mut c_ulonglong)))
    }

    return __param_it_

}

pub unsafe fn stc_word_deque_erase_range(__param_self_: *mut stc_word_deque, __param_it1: stc_word_deque_iter, __param_it2: stc_word_deque_iter) -> stc_word_deque_iter {
    var __local_idx1: c_long = ((((((*(&raw const __param_it1 as *const stc_word_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    var __local_idx2: c_long = ((((((*(&raw const __param_it2 as *const stc_word_deque_iter)).pos - (*__param_self_).start) as c_long) & ((*__param_self_).capmask as c_long)) as c_long))

    stc_word_deque_erase_n(__param_self_, __local_idx1, ((__local_idx2 - __local_idx1) as c_long))

    if ((if (*(&raw const __param_it1 as *const stc_word_deque_iter)).pos == (*__param_self_).end: 1 else: 0) != 0) {
        (__param_it1.ref = ((null as *mut c_ulonglong)))
    }

    return __param_it1

}

pub unsafe fn stc_slotrefs_sort_lowhigh(__param_self_: *mut stc_slotref, __param_lo: c_long, __param_hi: c_long) -> Unit {
    var __local_lo = __param_lo
    var __local_i: c_long = __local_lo

    var __local_j: c_long


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: stc_slotref = (*((&raw const (__param_self_[((__local_lo + (((__param_hi - __local_lo) * 7) / 16)) as c_long)]) as *const stc_slotref) as *mut stc_slotref))

        var __local_rx: stc_slotref


        (__local_j = __param_hi)

        loop {
            loop {
                with_memcpy((&raw mut __local_rx as *mut u8), (&raw const (*((&raw const (__param_self_[__local_i]) as *const stc_slotref) as *mut stc_slotref)) as *const u8), sizeof[stc_slotref]())

                var __ci_expr_logic_0: c_int = 0

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

                var __ci_expr_logic_1: c_int = 0

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
                var __local__xp_1: *mut c_long = ((&raw mut __local_lo as *mut c_long))

                var __local__yp_1: *mut c_long = ((&raw mut __local_i as *mut c_long))


                var __local__tv_1: c_long = (((*__local__xp_1) as c_long))

                ((*__local__xp_1) = (((*__local__yp_1) as c_long)))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut c_long = ((&raw mut __param_hi as *mut c_long))

                var __local__yp_2: *mut c_long = ((&raw mut __local_j as *mut c_long))


                var __local__tv_2: c_long = (((*__local__xp_2) as c_long))

                ((*__local__xp_2) = (((*__local__yp_2) as c_long)))

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

pub unsafe fn stc_slotrefs_lower_bound_range(__param_self_: *const stc_slotref, __param_raw: stc_slotref, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_start = __param_start
    var __local_count: c_long = (((__param_end - __local_start) as c_long))

    var __local_step: c_long = (((__local_count / 2) as c_long))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: stc_slotref = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const stc_slotref))

        if ((if (*(&raw const __local_rx as *const stc_slotref)).cmp.unwrap()(((&raw const __local_rx as *const stc_slotref) as *const c_void), ((&raw const __param_raw as *const stc_slotref) as *const c_void)) < 0: 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as c_long)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as c_long)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as c_long) else: __local_start)

}

pub unsafe fn stc_slotrefs_binary_search_range(__param_self_: *const stc_slotref, __param_raw: stc_slotref, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_res: c_long = ((stc_slotrefs_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as c_long))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: stc_slotref = (*(&raw const (__param_self_[__local_res]) as *const stc_slotref))

        if ((if (*(&raw const __param_raw as *const stc_slotref)).cmp.unwrap()(((&raw const __param_raw as *const stc_slotref) as *const c_void), ((&raw const __local_rx as *const stc_slotref) as *const c_void)) < 0: 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as c_long)))
        }

    }

    return __local_res

}

pub unsafe fn stc_slotrefs_sort(__param_arr: *mut stc_slotref, __param_n: c_long) {
    stc_slotrefs_sort_lowhigh(__param_arr, (0 as c_long), ((__param_n - 1) as c_long))

}

pub unsafe fn stc_slotrefs_lower_bound(__param_arr: *const stc_slotref, __param_raw: stc_slotref, __param_n: c_long) -> c_long {
    return stc_slotrefs_lower_bound_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

pub unsafe fn stc_slotrefs_binary_search(__param_arr: *const stc_slotref, __param_raw: stc_slotref, __param_n: c_long) -> c_long {
    return stc_slotrefs_binary_search_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

unsafe fn stc_slotrefs_insertsort_lowhigh(__param_self_: *mut stc_slotref, __param_lo: c_long, __param_hi: c_long) {
    var __local_j: c_long = __param_lo

    var __local_i: c_long = (((__param_lo + 1) as c_long))


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

pub unsafe fn stc_i64s_sort_lowhigh(__param_self_: *mut c_longlong, __param_lo: c_long, __param_hi: c_long) -> Unit {
    var __local_lo = __param_lo
    var __local_i: c_long = __local_lo

    var __local_j: c_long


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: c_longlong = (*((&raw const (__param_self_[((__local_lo + (((__param_hi - __local_lo) * 7) / 16)) as c_long)]) as *const c_longlong) as *mut c_longlong))

        var __local_rx: c_longlong


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_i]) as *const c_longlong) as *mut c_longlong)))

                var __ci_expr_logic_0: c_int = 0

                if ((if (*(&raw mut __local_rx as *mut c_longlong)) < (*(&raw mut __local_pivot as *mut c_longlong)): 1 else: 0) != 0) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_0 != 0)) {
                    break
                }
            }

            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_j]) as *const c_longlong) as *mut c_longlong)))

                var __ci_expr_logic_1: c_int = 0

                if ((if (*(&raw mut __local_pivot as *mut c_longlong)) < (*(&raw mut __local_rx as *mut c_longlong)): 1 else: 0) != 0) {
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
                var __local__xp: *mut c_longlong = (((&raw const (__param_self_[__local_i]) as *const c_longlong) as *mut c_longlong))

                var __local__yp: *mut c_longlong = (((&raw const (__param_self_[__local_j]) as *const c_longlong) as *mut c_longlong))


                var __local__tv: c_longlong = (((*__local__xp) as c_longlong))

                ((*__local__xp) = (((*__local__yp) as c_longlong)))

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
                var __local__xp_1: *mut c_long = ((&raw mut __local_lo as *mut c_long))

                var __local__yp_1: *mut c_long = ((&raw mut __local_i as *mut c_long))


                var __local__tv_1: c_long = (((*__local__xp_1) as c_long))

                ((*__local__xp_1) = (((*__local__yp_1) as c_long)))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut c_long = ((&raw mut __param_hi as *mut c_long))

                var __local__yp_2: *mut c_long = ((&raw mut __local_j as *mut c_long))


                var __local__tv_2: c_long = (((*__local__xp_2) as c_long))

                ((*__local__xp_2) = (((*__local__yp_2) as c_long)))

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

pub unsafe fn stc_i64s_lower_bound_range(__param_self_: *const c_longlong, __param_raw: c_longlong, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_start = __param_start
    var __local_count: c_long = (((__param_end - __local_start) as c_long))

    var __local_step: c_long = (((__local_count / 2) as c_long))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: c_longlong = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const c_longlong))

        if ((if (*(&raw const __local_rx as *const c_longlong)) < (*(&raw const __param_raw as *const c_longlong)): 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as c_long)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as c_long)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as c_long) else: __local_start)

}

pub unsafe fn stc_i64s_binary_search_range(__param_self_: *const c_longlong, __param_raw: c_longlong, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_res: c_long = ((stc_i64s_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as c_long))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: c_longlong = (*(&raw const (__param_self_[__local_res]) as *const c_longlong))

        if ((if (*(&raw const __param_raw as *const c_longlong)) < (*(&raw const __local_rx as *const c_longlong)): 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as c_long)))
        }

    }

    return __local_res

}

pub unsafe fn stc_i64s_sort(__param_arr: *mut c_longlong, __param_n: c_long) {
    stc_i64s_sort_lowhigh(__param_arr, (0 as c_long), ((__param_n - 1) as c_long))

}

pub unsafe fn stc_i64s_lower_bound(__param_arr: *const c_longlong, __param_raw: c_longlong, __param_n: c_long) -> c_long {
    return stc_i64s_lower_bound_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

pub unsafe fn stc_i64s_binary_search(__param_arr: *const c_longlong, __param_raw: c_longlong, __param_n: c_long) -> c_long {
    return stc_i64s_binary_search_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

unsafe fn stc_i64s_insertsort_lowhigh(__param_self_: *mut c_longlong, __param_lo: c_long, __param_hi: c_long) {
    var __local_j: c_long = __param_lo

    var __local_i: c_long = (((__param_lo + 1) as c_long))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: c_longlong = (*((&raw const (__param_self_[__local_i]) as *const c_longlong) as *mut c_longlong))

        var __local_rx: c_longlong = (*(&raw mut __local_x as *mut c_longlong))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: c_longlong = (*((&raw const (__param_self_[__local_j]) as *const c_longlong) as *mut c_longlong))

            if ((if not ((if (*(&raw mut __local_rx as *mut c_longlong)) < (*(&raw mut __local_ry as *mut c_longlong)): 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (__param_self_[(__local_j + 1)]) as *const c_longlong) as *mut c_longlong)) = (*((&raw const (__param_self_[__local_j]) as *const c_longlong) as *mut c_longlong)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (__param_self_[(__local_j + 1)]) as *const c_longlong) as *mut c_longlong)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

pub unsafe fn stc_u64s_sort_lowhigh(__param_self_: *mut c_ulonglong, __param_lo: c_long, __param_hi: c_long) -> Unit {
    var __local_lo = __param_lo
    var __local_i: c_long = __local_lo

    var __local_j: c_long


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: c_ulonglong = (*((&raw const (__param_self_[((__local_lo + (((__param_hi - __local_lo) * 7) / 16)) as c_long)]) as *const c_ulonglong) as *mut c_ulonglong))

        var __local_rx: c_ulonglong


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_i]) as *const c_ulonglong) as *mut c_ulonglong)))

                var __ci_expr_logic_0: c_int = 0

                if ((if (*(&raw mut __local_rx as *mut c_ulonglong)) < (*(&raw mut __local_pivot as *mut c_ulonglong)): 1 else: 0) != 0) {
                    (__local_i = __local_i + 1)

                    (__ci_expr_logic_0 = (if __local_i != 0: 1 else: 0))

                }

                if not ((__ci_expr_logic_0 != 0)) {
                    break
                }
            }

            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_j]) as *const c_ulonglong) as *mut c_ulonglong)))

                var __ci_expr_logic_1: c_int = 0

                if ((if (*(&raw mut __local_pivot as *mut c_ulonglong)) < (*(&raw mut __local_rx as *mut c_ulonglong)): 1 else: 0) != 0) {
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
                var __local__xp: *mut c_ulonglong = (((&raw const (__param_self_[__local_i]) as *const c_ulonglong) as *mut c_ulonglong))

                var __local__yp: *mut c_ulonglong = (((&raw const (__param_self_[__local_j]) as *const c_ulonglong) as *mut c_ulonglong))


                var __local__tv: c_ulonglong = (((*__local__xp) as c_ulonglong))

                ((*__local__xp) = (((*__local__yp) as c_ulonglong)))

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
                var __local__xp_1: *mut c_long = ((&raw mut __local_lo as *mut c_long))

                var __local__yp_1: *mut c_long = ((&raw mut __local_i as *mut c_long))


                var __local__tv_1: c_long = (((*__local__xp_1) as c_long))

                ((*__local__xp_1) = (((*__local__yp_1) as c_long)))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut c_long = ((&raw mut __param_hi as *mut c_long))

                var __local__yp_2: *mut c_long = ((&raw mut __local_j as *mut c_long))


                var __local__tv_2: c_long = (((*__local__xp_2) as c_long))

                ((*__local__xp_2) = (((*__local__yp_2) as c_long)))

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

pub unsafe fn stc_u64s_lower_bound_range(__param_self_: *const c_ulonglong, __param_raw: c_ulonglong, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_start = __param_start
    var __local_count: c_long = (((__param_end - __local_start) as c_long))

    var __local_step: c_long = (((__local_count / 2) as c_long))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: c_ulonglong = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const c_ulonglong))

        if ((if (*(&raw const __local_rx as *const c_ulonglong)) < (*(&raw const __param_raw as *const c_ulonglong)): 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as c_long)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as c_long)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as c_long) else: __local_start)

}

pub unsafe fn stc_u64s_binary_search_range(__param_self_: *const c_ulonglong, __param_raw: c_ulonglong, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_res: c_long = ((stc_u64s_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as c_long))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: c_ulonglong = (*(&raw const (__param_self_[__local_res]) as *const c_ulonglong))

        if ((if (*(&raw const __param_raw as *const c_ulonglong)) < (*(&raw const __local_rx as *const c_ulonglong)): 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as c_long)))
        }

    }

    return __local_res

}

pub unsafe fn stc_u64s_sort(__param_arr: *mut c_ulonglong, __param_n: c_long) {
    stc_u64s_sort_lowhigh(__param_arr, (0 as c_long), ((__param_n - 1) as c_long))

}

pub unsafe fn stc_u64s_lower_bound(__param_arr: *const c_ulonglong, __param_raw: c_ulonglong, __param_n: c_long) -> c_long {
    return stc_u64s_lower_bound_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

pub unsafe fn stc_u64s_binary_search(__param_arr: *const c_ulonglong, __param_raw: c_ulonglong, __param_n: c_long) -> c_long {
    return stc_u64s_binary_search_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

unsafe fn stc_u64s_insertsort_lowhigh(__param_self_: *mut c_ulonglong, __param_lo: c_long, __param_hi: c_long) {
    var __local_j: c_long = __param_lo

    var __local_i: c_long = (((__param_lo + 1) as c_long))


    while ((if __local_i <= __param_hi: 1 else: 0) != 0) {
        var __local_x: c_ulonglong = (*((&raw const (__param_self_[__local_i]) as *const c_ulonglong) as *mut c_ulonglong))

        var __local_rx: c_ulonglong = (*(&raw mut __local_x as *mut c_ulonglong))

        while ((if __local_j >= 0: 1 else: 0) != 0) {
            var __local_ry: c_ulonglong = (*((&raw const (__param_self_[__local_j]) as *const c_ulonglong) as *mut c_ulonglong))

            if ((if not ((if (*(&raw mut __local_rx as *mut c_ulonglong)) < (*(&raw mut __local_ry as *mut c_ulonglong)): 1 else: 0) != 0): 1 else: 0) != 0) {
                break
            }

            ((*((&raw const (__param_self_[(__local_j + 1)]) as *const c_ulonglong) as *mut c_ulonglong)) = (*((&raw const (__param_self_[__local_j]) as *const c_ulonglong) as *mut c_ulonglong)))

            (__local_j = __local_j - 1)

        }

        ((*((&raw const (__param_self_[(__local_j + 1)]) as *const c_ulonglong) as *mut c_ulonglong)) = __local_x)


        (__local_j = __local_i)

        (__local_i = __local_i + 1)


    }


}

pub unsafe fn stc_f64s_sort_lowhigh(__param_self_: *mut f64, __param_lo: c_long, __param_hi: c_long) -> Unit {
    var __local_lo = __param_lo
    var __local_i: c_long = __local_lo

    var __local_j: c_long


    while ((if __local_lo < __param_hi: 1 else: 0) != 0) {
        var __local_pivot: f64 = (*((&raw const (__param_self_[((__local_lo + (((__param_hi - __local_lo) * 7) / 16)) as c_long)]) as *const f64) as *mut f64))

        var __local_rx: f64


        (__local_j = __param_hi)

        loop {
            loop {
                (__local_rx = (*((&raw const (__param_self_[__local_i]) as *const f64) as *mut f64)))

                var __ci_expr_logic_0: c_int = 0

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

                var __ci_expr_logic_1: c_int = 0

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


                var __local__tv: f64 = (((*__local__xp) as f64))

                ((*__local__xp) = (((*__local__yp) as f64)))

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
                var __local__xp_1: *mut c_long = ((&raw mut __local_lo as *mut c_long))

                var __local__yp_1: *mut c_long = ((&raw mut __local_i as *mut c_long))


                var __local__tv_1: c_long = (((*__local__xp_1) as c_long))

                ((*__local__xp_1) = (((*__local__yp_1) as c_long)))

                ((*__local__yp_1) = __local__tv_1)

                if not ((0 != 0)) {
                    break
                }
            }

            loop {
                var __local__xp_2: *mut c_long = ((&raw mut __param_hi as *mut c_long))

                var __local__yp_2: *mut c_long = ((&raw mut __local_j as *mut c_long))


                var __local__tv_2: c_long = (((*__local__xp_2) as c_long))

                ((*__local__xp_2) = (((*__local__yp_2) as c_long)))

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

pub unsafe fn stc_f64s_lower_bound_range(__param_self_: *const f64, __param_raw: f64, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_start = __param_start
    var __local_count: c_long = (((__param_end - __local_start) as c_long))

    var __local_step: c_long = (((__local_count / 2) as c_long))


    while ((if __local_count > 0: 1 else: 0) != 0) {
        var __local_rx: f64 = (*(&raw const (__param_self_[(__local_start + __local_step)]) as *const f64))

        if ((if (*(&raw const __local_rx as *const f64)) < (*(&raw const __param_raw as *const f64)): 1 else: 0) != 0) {
            (__local_start = __local_start + (__local_step + 1))

            (__local_count = __local_count - (__local_step + 1))

            (__local_step = ((((__local_count * 7) / 8) as c_long)))

        } else {
            (__local_count = __local_step)

            (__local_step = (((__local_count / 8) as c_long)))

        }

    }

    return (if (if __local_start >= __param_end: 1 else: 0) != 0: (9223372036854775807 as c_long) else: __local_start)

}

pub unsafe fn stc_f64s_binary_search_range(__param_self_: *const f64, __param_raw: f64, __param_start: c_long, __param_end: c_long) -> c_long {
    var __local_res: c_long = ((stc_f64s_lower_bound_range(__param_self_, __param_raw, __param_start, __param_end) as c_long))

    if ((if __local_res != 9223372036854775807: 1 else: 0) != 0) {
        var __local_rx: f64 = (*(&raw const (__param_self_[__local_res]) as *const f64))

        if ((if (*(&raw const __param_raw as *const f64)) < (*(&raw const __local_rx as *const f64)): 1 else: 0) != 0) {
            (__local_res = ((9223372036854775807 as c_long)))
        }

    }

    return __local_res

}

pub unsafe fn stc_f64s_sort(__param_arr: *mut f64, __param_n: c_long) {
    stc_f64s_sort_lowhigh(__param_arr, (0 as c_long), ((__param_n - 1) as c_long))

}

pub unsafe fn stc_f64s_lower_bound(__param_arr: *const f64, __param_raw: f64, __param_n: c_long) -> c_long {
    return stc_f64s_lower_bound_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

pub unsafe fn stc_f64s_binary_search(__param_arr: *const f64, __param_raw: f64, __param_n: c_long) -> c_long {
    return stc_f64s_binary_search_range(__param_arr, __param_raw, (0 as c_long), __param_n)

}

unsafe fn stc_f64s_insertsort_lowhigh(__param_self_: *mut f64, __param_lo: c_long, __param_hi: c_long) {
    var __local_j: c_long = __param_lo

    var __local_i: c_long = (((__param_lo + 1) as c_long))


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

pub fn c_popcount(__param_x: c_ulong) -> c_int {
    return ((((__param_x as c_ulonglong) as u64).popcount() as c_int))

}

pub unsafe fn _cbits_count(__param_set: *const c_ulong, __param_sz: c_long) -> c_long {
    var __local_n: c_long = (((__param_sz / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    var __local_count: c_long = ((0 as c_long))

    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        (__local_count = __local_count + c_popcount(((__param_set[__local_i]) as c_ulong)))

        (__local_i = __local_i + 1)

    }


    if (((__param_sz as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) != 0) {
        (__local_count = __local_count + c_popcount(((((__param_set[__local_n]) as c_ulong) & (((((1 as c_ulong) << (((__param_sz as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong) -% (1 as c_ulong)) as c_ulong)) as c_ulong)))
    }

    return __local_count

}

pub unsafe fn _cbits_to_str(__param_set: *const c_ulong, __param_sz: c_long, __param_out: *mut i8, __param_start: c_long, __param_stop: c_long) -> *mut i8 {
    var __local_stop = __param_stop
    if ((if __local_stop > __param_sz: 1 else: 0) != 0) {
        (__local_stop = __param_sz)
    }

    if (((if not ((if __param_start <= __local_stop: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"_cbits_to_str".ptr, c"cbits.h".ptr, (115 as c_int), c"start <= stop".ptr)
    } else {
        0
    }

    with_memset(((__param_out as *mut c_void) as *mut u8), (48 as c_int), (((if 1 != 0: ((__local_stop - __param_start) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

    var __local_i: c_long = __param_start

    while ((if __local_i < __local_stop: 1 else: 0) != 0) {
        if ((if (((__param_set[(__local_i / (8 * (sizeof[c_ulong]() as c_long)))]) as c_ulong) & (((1 as c_ulong) << (((__local_i as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong)) != 0: 1 else: 0) != 0) {
            ((__param_out[(__local_i - __param_start)]) = ((49 as c_char)))
        }

        (__local_i = __local_i + 1)

    }


    ((__param_out[(__local_stop - __param_start)]) = ((0 as c_char)))

    return __param_out

}

pub unsafe fn _cbits_subset_of(__param_set: *const c_ulong, __param_other: *const c_ulong, __param_sz: c_long) -> bool {
    var __local_n: c_long = (((__param_sz / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        if ((if (((__param_set[__local_i]) as c_ulong) | ((__param_other[__local_i]) as c_ulong)) != (__param_set[__local_i]): 1 else: 0) != 0) {
            return false
        }

        (__local_i = __local_i + 1)

    }


    if ((if ((__param_sz as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) == 0: 1 else: 0) != 0) {
        return true
    }

    var __local_i_1: c_ulong = ((__local_n as c_ulong))

    var __local_m: c_ulong = ((((((1 as c_ulong) << (((__param_sz as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong) -% (1 as c_ulong)) as c_ulong))


    return (((((((__param_set[__local_i_1]) as c_ulong) | ((__param_other[__local_i_1]) as c_ulong)) as c_ulong) & (__local_m as c_ulong)) == (((__param_set[__local_i_1]) as c_ulong) & (__local_m as c_ulong))))

}

pub unsafe fn _cbits_disjoint(__param_set: *const c_ulong, __param_other: *const c_ulong, __param_sz: c_long) -> bool {
    var __local_n: c_long = (((__param_sz / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    var __local_i: c_long = ((0 as c_long))

    while ((if __local_i < __local_n: 1 else: 0) != 0) {
        if ((if (((__param_set[__local_i]) as c_ulong) & ((__param_other[__local_i]) as c_ulong)) != 0: 1 else: 0) != 0) {
            return false
        }

        (__local_i = __local_i + 1)

    }


    if ((if ((__param_sz as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) == 0: 1 else: 0) != 0) {
        return true
    }

    var __local_i_1: c_ulong = ((__local_n as c_ulong))

    var __local_m: c_ulong = ((((((1 as c_ulong) << (((__param_sz as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong) -% (1 as c_ulong)) as c_ulong))


    return (((((((__param_set[__local_i_1]) as c_ulong) & ((__param_other[__local_i_1]) as c_ulong)) as c_ulong) & (__local_m as c_ulong)) == ((0 as c_ulong) & (__local_m as c_ulong))))

}

pub unsafe fn cbits_drop(__param_self_: *mut cbits) {
    (sizeof[c_ulong]() as usize)

    (sizeof[c_ulong]() as usize)

    (sizeof[c_ulong]() as usize)

    with_free((((*__param_self_).buffer as *mut c_void) as *mut u8))


}

pub unsafe fn cbits_size(__param_self_: *const cbits) -> c_long {
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

    var __local_bytes: c_long = ((((((unsafe *(&raw const __param_other as *const cbits))._size + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) * (sizeof[c_ulong]() as c_long)) as c_long))

    (__local_set.buffer = ((unsafe { c_safe_memcpy((with_alloc((((if 1 != 0: __local_bytes else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void), ((*(&raw const __param_other as *const cbits)).buffer as *const c_void), __local_bytes) } as *mut c_ulong)))

    return __local_set

}

pub unsafe fn cbits_copy(__param_self_: *mut cbits, __param_other: *const cbits) -> *mut cbits {
    if ((if (*__param_self_).buffer == (*__param_other).buffer: 1 else: 0) != 0) {
        return __param_self_
    }

    if ((if (*__param_self_)._size != (*__param_other)._size: 1 else: 0) != 0) {
        return ((cbits_take(__param_self_, cbits_clone((*__param_other))) as *mut cbits))
    }

    with_memcpy((((*__param_self_).buffer as *mut c_void) as *mut u8), (((*__param_other).buffer as *const c_void) as *const u8), (((if 1 != 0: (((((*__param_other)._size + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) * (sizeof[c_ulong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

    return __param_self_

}

pub unsafe fn cbits_resize(__param_self_: *mut cbits, __param_size: c_long, __param_value: bool) -> bool {
    var __local_new_w: c_long = ((((__param_size + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    var __local_osize: c_long = (*__param_self_)._size

    var __local_old_w: c_long = ((((__local_osize + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) as c_long))


    var __local_b: *mut c_ulong = (((with_realloc((((*__param_self_).buffer as *mut c_void) as *mut u8), (0 as i64), (((if 1 != 0: ((if 1 != 0: ((__local_new_w * (sizeof[c_ulong]() as c_long)) as c_long) else: ((__local_old_w * (sizeof[c_ulong]() as c_long)) as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_ulong))

    if ((if __local_b == null: 1 else: 0) != 0) {
        return false
    }

    ((*__param_self_).buffer = __local_b)

    ((*__param_self_)._size = __param_size)

    if ((if __param_size > __local_osize: 1 else: 0) != 0) {
        with_memset(((((*__param_self_).buffer + ((__local_old_w as c_long) as usize)) as *mut c_void) as *mut u8), ((0 - (__param_value as c_int)) as c_int), (((if 1 != 0: (((__local_new_w - __local_old_w) * (sizeof[c_ulong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

        if (((__local_osize as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) != 0) {
            var __local_mask: c_ulong = ((((((1 as c_ulong) << (((__local_osize as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong) -% (1 as c_ulong)) as c_ulong))

            if __param_value {
                (((*__param_self_).buffer[(__local_old_w - 1)]) = (((*__param_self_).buffer[(__local_old_w - 1)]) as c_ulong) | ((~__local_mask) as c_ulong))
            } else {
                (((*__param_self_).buffer[(__local_old_w - 1)]) = (((*__param_self_).buffer[(__local_old_w - 1)]) as c_ulong) & (__local_mask as c_ulong))
            }

        }

    }

    return true

}

pub unsafe fn cbits_set_all(__param_self_: *mut cbits, __param_value: bool) -> Unit {
    with_memset((((*__param_self_).buffer as *mut c_void) as *mut u8), ((0 - (__param_value as c_int)) as c_int), (((if 1 != 0: ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) * (sizeof[c_ulong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64))

}

pub unsafe fn cbits_set_pattern(__param_self_: *mut cbits, __param_pattern: c_ulong) {
    var __local_n: c_long = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = __param_pattern)

    }

}

pub unsafe fn cbits_move(__param_self_: *mut cbits) -> cbits {
    var __local_tmp: cbits = (*__param_self_)

    ((*__param_self_).buffer = ((null as *mut c_ulong)))

    ((*__param_self_)._size = ((0 as c_long)))


    return __local_tmp

}

pub fn cbits_with_size(__param_size: c_long, __param_value: bool) -> cbits {
    var __local_set: cbits = cbits { buffer: ((with_alloc((((if 1 != 0: ((((__param_size + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) * (sizeof[c_ulong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_ulong), _size: __param_size }

    unsafe { cbits_set_all((&raw mut __local_set as *mut cbits), __param_value) }

    return __local_set

}

pub fn cbits_with_pattern(__param_size: c_long, __param_pattern: c_ulong) -> cbits {
    var __local_set: cbits = cbits { buffer: ((with_alloc((((if 1 != 0: ((((__param_size + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) * (sizeof[c_ulong]() as c_long)) as c_long) else: (-1 as c_long)) as c_ulong) as i64)) as *mut c_void) as *mut c_ulong), _size: __param_size }

    unsafe { cbits_set_pattern((&raw mut __local_set as *mut cbits), __param_pattern) }

    return __local_set

}

pub unsafe fn cbits_test(__param_self_: *const cbits, __param_i: c_long) -> bool {
    return ((((((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) as c_ulong) & (((1 as c_ulong) << (((__param_i as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong)) != 0))

}

pub unsafe fn cbits_at(__param_self_: *const cbits, __param_i: c_long) -> bool {
    if (((if not ((if ((__param_i as c_ulong)) < ((cbits_size(__param_self_) as c_ulong)): 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cbits_at".ptr, c"cbits.h".ptr, (269 as c_int), c"((size_t)(i) < (size_t)(cbits_size(self)))".ptr)
    } else {
        0
    }

    return cbits_test(__param_self_, __param_i)

}

pub unsafe fn cbits_set(__param_self_: *mut cbits, __param_i: c_long) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) as c_ulong) | (((1 as c_ulong) << (((__param_i as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong))

}

pub unsafe fn cbits_reset(__param_self_: *mut cbits, __param_i: c_long) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) as c_ulong) & ((~((1 as c_ulong) << (((__param_i as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint))) as c_ulong))

}

pub unsafe fn cbits_set_value(__param_self_: *mut cbits, __param_i: c_long, __param_b: bool) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) as c_ulong) ^ ((((((0 - (__param_b as c_int)) as c_ulong) ^ (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) as c_ulong)) as c_ulong) & (((1 as c_ulong) << (((__param_i as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong)) as c_ulong))

}

pub unsafe fn cbits_flip(__param_self_: *mut cbits, __param_i: c_long) {
    (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) = (((*__param_self_).buffer[(__param_i / (8 * (sizeof[c_ulong]() as c_long)))]) as c_ulong) ^ (((1 as c_ulong) << (((__param_i as c_long) & (((8 * (sizeof[c_ulong]() as c_long)) - 1) as c_long)) as c_uint)) as c_ulong))

}

pub unsafe fn cbits_flip_all(__param_self_: *mut cbits) {
    var __local_n: c_long = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as c_ulong) ^ ((~(0 as c_ulong)) as c_ulong))

    }

}

pub unsafe fn cbits_from(__param_str: *const i8) -> cbits {
    var __local_n: c_long = ((strlen(__param_str) as c_long))

    var __local_set: cbits = cbits_with_size(__local_n, (false as bool))

    while true {
        var __ci_expr_old_0: c_long = __local_n

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
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cbits_intersect".ptr, c"cbits.h".ptr, (298 as c_int), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: c_long = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as c_ulong) & (((*__param_other).buffer[__local_n]) as c_ulong))

    }

}

pub unsafe fn cbits_union(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cbits_union".ptr, c"cbits.h".ptr, (304 as c_int), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: c_long = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as c_ulong) | (((*__param_other).buffer[__local_n]) as c_ulong))

    }

}

pub unsafe fn cbits_xor(__param_self_: *mut cbits, __param_other: *const cbits) {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cbits_xor".ptr, c"cbits.h".ptr, (310 as c_int), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    var __local_n: c_long = ((((cbits_size((__param_self_ as *const cbits)) + ((8 * (sizeof[c_ulong]() as c_long)) - 1)) / (8 * (sizeof[c_ulong]() as c_long))) as c_long))

    while true {
        var __ci_expr_old_0: c_long = __local_n

        (__local_n = __local_n - 1)

        if (not (__ci_expr_old_0 != 0)) {
            break
        }

        (((*__param_self_).buffer[__local_n]) = (((*__param_self_).buffer[__local_n]) as c_ulong) ^ (((*__param_other).buffer[__local_n]) as c_ulong))

    }

}

pub unsafe fn cbits_count(__param_self_: *const cbits) -> c_long {
    return _cbits_count(((*__param_self_).buffer as *const c_ulong), (cbits_size(__param_self_) as c_long))

}

pub unsafe fn cbits_to_str(__param_self_: *const cbits, __param_out: *mut i8, __param_start: c_long, __param_stop: c_long) -> *mut i8 {
    return ((_cbits_to_str(((*__param_self_).buffer as *const c_ulong), (cbits_size(__param_self_) as c_long), __param_out, __param_start, __param_stop) as *mut i8))

}

pub unsafe fn cbits_subset_of(__param_self_: *const cbits, __param_other: *const cbits) -> bool {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cbits_subset_of".ptr, c"cbits.h".ptr, (322 as c_int), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    return _cbits_subset_of(((*__param_self_).buffer as *const c_ulong), ((*__param_other).buffer as *const c_ulong), (cbits_size(__param_self_) as c_long))

}

pub unsafe fn cbits_disjoint(__param_self_: *const cbits, __param_other: *const cbits) -> bool {
    if (((if not ((if (*__param_self_)._size == (*__param_other)._size: 1 else: 0) != 0): 1 else: 0) as c_long) != 0) {
        __assert_rtn(c"cbits_disjoint".ptr, c"cbits.h".ptr, (327 as c_int), c"self->_size == other->_size".ptr)
    } else {
        0
    }

    return _cbits_disjoint(((*__param_self_).buffer as *const c_ulong), ((*__param_other).buffer as *const c_ulong), (cbits_size(__param_self_) as c_long))

}
