// Migrated from C
use std.zlib.defs
use std.zlib.zutil
use std.zlib.deflate
use std.zlib.inflate
use std.zlib.infback
use std.zlib.compress
use std.zlib.uncompr
use std.zlib.gzlib
use std.zlib.gzwrite
use std.zlib.gzread
use std.zlib.gzclose
use std.zlib.adler32
use std.zlib.crc32
use std.zlib.inftrees

pub unsafe fn _tr_init(__param_s: *mut internal_state) -> Unit {
    tr_static_init()

    ((unsafe *__param_s).l_desc.dyn_tree = (&(unsafe *__param_s).dyn_ltree[0] as *mut ct_data_s))

    ((unsafe *__param_s).l_desc.stat_desc = ((&raw const static_l_desc as *const static_tree_desc_s)))

    ((unsafe *__param_s).d_desc.dyn_tree = (&(unsafe *__param_s).dyn_dtree[0] as *mut ct_data_s))

    ((unsafe *__param_s).d_desc.stat_desc = ((&raw const static_d_desc as *const static_tree_desc_s)))

    ((unsafe *__param_s).bl_desc.dyn_tree = (&(unsafe *__param_s).bl_tree[0] as *mut ct_data_s))

    ((unsafe *__param_s).bl_desc.stat_desc = ((&raw const static_bl_desc as *const static_tree_desc_s)))

    ((unsafe *__param_s).bi_buf = ((0 as c_ushort)))

    ((unsafe *__param_s).bi_valid = ((0 as c_int)))

    ((unsafe *__param_s).bi_used = ((0 as c_int)))

    init_block(__param_s)

}

pub unsafe fn _tr_tally(__param_s: *mut internal_state, __param_dist: c_uint, __param_lc: c_uint) -> c_int {
    var __local_dist = __param_dist
    var __ci_expr_old_0: c_uint = (unsafe *__param_s).sym_next

    ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

    ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_0]) = ((__local_dist as u8)))


    var __ci_expr_old_1: c_uint = (unsafe *__param_s).sym_next

    ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

    ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_1]) = ((((__local_dist as c_uint) >> (8 as c_uint)) as u8)))


    var __ci_expr_old_2: c_uint = (unsafe *__param_s).sym_next

    ((unsafe *__param_s).sym_next = ((unsafe *__param_s).sym_next +% 1))

    ((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_2]) = ((__param_lc as u8)))


    if ((if __local_dist == 0: 1 else: 0) != 0) {
        ((unsafe *__param_s).dyn_ltree[__param_lc].fc.freq = ((unsafe *__param_s).dyn_ltree[__param_lc].fc.freq +% 1))

    } else {
        ((unsafe *__param_s).matches = ((unsafe *__param_s).matches +% 1))

        (__local_dist = (__local_dist -% 1))

        ((unsafe *__param_s).dyn_ltree[(((_length_code[__param_lc] as c_int) + 256) + 1)].fc.freq = ((unsafe *__param_s).dyn_ltree[(((_length_code[__param_lc] as c_int) + 256) + 1)].fc.freq +% 1))

        var __ci_expr_ternary_3: c_int = 0

        if ((if __local_dist < 256: 1 else: 0) != 0) {
            (__ci_expr_ternary_3 = ((_dist_code[__local_dist] as c_int)))
        } else {
            (__ci_expr_ternary_3 = ((_dist_code[((256 as c_uint) +% (((__local_dist as c_uint) >> (7 as c_uint)) as c_uint))] as c_int)))
        }

        ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_3].fc.freq = ((unsafe *__param_s).dyn_dtree[__ci_expr_ternary_3].fc.freq +% 1))


    }

    return (if (unsafe *__param_s).sym_next == (unsafe *__param_s).sym_end: 1 else: 0)

}

pub unsafe fn _tr_flush_block(__param_s: *mut internal_state, __param_buf: *mut i8, __param_stored_len: c_ulong, __param_last: c_int) -> Unit {
    var __local_opt_lenb: c_ulong

    var __local_static_lenb: c_ulong


    var __local_max_blindex: c_int = ((0 as c_int))

    if ((if (unsafe *__param_s).level > 0: 1 else: 0) != 0) {
        if ((if (unsafe *__param_s).strm.data_type == 2: 1 else: 0) != 0) {
            ((unsafe *__param_s).strm.data_type = ((detect_data_type(__param_s) as c_int)))
        }

        build_tree(__param_s, ((&raw const (unsafe *__param_s).l_desc as *const tree_desc_s) as *mut tree_desc_s))

        build_tree(__param_s, ((&raw const (unsafe *__param_s).d_desc as *const tree_desc_s) as *mut tree_desc_s))

        (__local_max_blindex = ((build_bl_tree(__param_s) as c_int)))

        (__local_opt_lenb = (((((((((unsafe *__param_s).opt_len as c_ulong) +% (3 as c_ulong)) as c_ulong) +% (7 as c_ulong)) as c_ulong) >> (3 as c_uint)) as c_ulong)))

        (__local_static_lenb = (((((((((unsafe *__param_s).static_len as c_ulong) +% (3 as c_ulong)) as c_ulong) +% (7 as c_ulong)) as c_ulong) >> (3 as c_uint)) as c_ulong)))

        var __ci_expr_logic_0: c_int

        if ((if __local_static_lenb <= __local_opt_lenb: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_0 = (if (if (unsafe *__param_s).strategy == 4: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_opt_lenb = __local_static_lenb)
        }


    } else {
        (__local_static_lenb = ((((__param_stored_len as c_ulong) +% (5 as c_ulong)) as c_ulong)))

        (__local_opt_lenb = __local_static_lenb)


    }

    var __ci_expr_logic_1: c_int = 0

    if ((if ((__param_stored_len as c_ulong) +% (4 as c_ulong)) <= __local_opt_lenb: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if (if __param_buf != null: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        _tr_stored_block(__param_s, __param_buf, __param_stored_len, __param_last)

    } else {
        if ((if __local_static_lenb == __local_opt_lenb: 1 else: 0) != 0) {
            var __local_len: c_int = ((3 as c_int))

            if ((if (unsafe *__param_s).bi_valid > (16 - __local_len): 1 else: 0) != 0) {
                var __local_val: c_int = (((((1 as c_int) << (1 as c_uint)) + __param_last) as c_int))

                ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                var __ci_expr_old_2: c_ulong = (unsafe *__param_s).pending

                ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_2]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                var __ci_expr_old_3: c_ulong = (unsafe *__param_s).pending

                ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_3]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                ((unsafe *__param_s).bi_buf = (((((__local_val as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len - 16))

            } else {
                ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((((1 as c_int) << (1 as c_uint)) + __param_last) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len)

            }


            compress_block(__param_s, (&static_ltree[0] as *const ct_data_s), (&static_dtree[0] as *const ct_data_s))

        } else {
            var __local_len_1: c_int = ((3 as c_int))

            if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_1): 1 else: 0) != 0) {
                var __local_val_1: c_int = (((((2 as c_int) << (1 as c_uint)) + __param_last) as c_int))

                ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_1 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                var __ci_expr_old_4: c_ulong = (unsafe *__param_s).pending

                ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_4]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                var __ci_expr_old_5: c_ulong = (unsafe *__param_s).pending

                ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_5]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                ((unsafe *__param_s).bi_buf = (((((__local_val_1 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_1 - 16))

            } else {
                ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((((2 as c_int) << (1 as c_uint)) + __param_last) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_1)

            }


            send_all_trees(__param_s, (((unsafe *(&raw const (unsafe *__param_s).l_desc as *const tree_desc_s)).max_code + 1) as c_int), (((unsafe *(&raw const (unsafe *__param_s).d_desc as *const tree_desc_s)).max_code + 1) as c_int), ((__local_max_blindex + 1) as c_int))

            compress_block(__param_s, (&(unsafe *__param_s).dyn_ltree[0] as *const ct_data_s), (&(unsafe *__param_s).dyn_dtree[0] as *const ct_data_s))

        }
    }


    init_block(__param_s)

    if (__param_last != 0) {
        bi_windup(__param_s)

    }

}

pub unsafe fn _tr_flush_bits(__param_s: *mut internal_state) -> Unit {
    bi_flush(__param_s)

}

pub unsafe fn _tr_align(__param_s: *mut internal_state) -> Unit {
    var __local_len: c_int = ((3 as c_int))

    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len): 1 else: 0) != 0) {
        var __local_val: c_int = ((((1 as c_int) << (1 as c_uint)) as c_int))

        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        var __ci_expr_old_0: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_0]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_1: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_1]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = (((((__local_val as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len - 16))

    } else {
        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((2 as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len)

    }


    var __local_len_1: c_int = ((static_ltree[256].dl.len as c_int))

    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_1): 1 else: 0) != 0) {
        var __local_val_1: c_int = ((static_ltree[256].fc.code as c_int))

        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_1 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        var __ci_expr_old_2: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_2]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_3: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_3]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = (((((__local_val_1 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_1 - 16))

    } else {
        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((static_ltree[256].fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_1)

    }


    bi_flush(__param_s)

}

pub unsafe fn _tr_stored_block(__param_s: *mut internal_state, __param_buf: *mut i8, __param_stored_len: c_ulong, __param_last: c_int) -> Unit {
    var __local_len: c_int = ((3 as c_int))

    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len): 1 else: 0) != 0) {
        var __local_val: c_int = (((((0 as c_int) << (1 as c_uint)) + __param_last) as c_int))

        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        var __ci_expr_old_0: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_0]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_1: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_1]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = (((((__local_val as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len - 16))

    } else {
        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((((0 as c_int) << (1 as c_uint)) + __param_last) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len)

    }


    bi_windup(__param_s)

    var __ci_expr_old_2: c_ulong = (unsafe *__param_s).pending

    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_2]) = ((((((__param_stored_len as c_ushort) as c_int) as c_int) & (255 as c_int)) as u8)))



    var __ci_expr_old_3: c_ulong = (unsafe *__param_s).pending

    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_3]) = (((((__param_stored_len as c_ushort) as c_int) >> (8 as c_uint)) as u8)))




    var __ci_expr_old_4: c_ulong = (unsafe *__param_s).pending

    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_4]) = (((((((~__param_stored_len) as c_ushort) as c_int) as c_int) & (255 as c_int)) as u8)))



    var __ci_expr_old_5: c_ulong = (unsafe *__param_s).pending

    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_5]) = ((((((~__param_stored_len) as c_ushort) as c_int) >> (8 as c_uint)) as u8)))




    if (__param_stored_len != 0) {
        with_memcpy(((((unsafe *__param_s).pending_buf + ((unsafe *__param_s).pending as usize)) as *mut c_void) as *i8), ((__param_buf as *mut u8) as *i8), (__param_stored_len as i64))
    }

    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% __param_stored_len))

}

fn bi_reverse(__param_code: c_uint, __param_len: c_int) -> c_uint {
    var __local_code = __param_code
    var __local_len = __param_len
    var __local_res: c_uint = ((0 as c_uint))

    loop {
        (__local_res = (__local_res as c_uint) | (((__local_code as c_uint) & (1 as c_uint)) as c_uint))

        (__local_code = __local_code >> (1 as c_uint))

        (__local_res = __local_res << (1 as c_uint))


        (__local_len = __local_len - 1)
        if not (((if __local_len > 0: 1 else: 0) != 0)) {
            break
        }
    }

    return ((__local_res as c_uint) >> (1 as c_uint))

}

unsafe fn bi_flush(__param_s: *mut internal_state) -> Unit {
    if ((if (unsafe *__param_s).bi_valid == 16: 1 else: 0) != 0) {
        var __ci_expr_old_0: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_0]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_1: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_1]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = ((0 as c_ushort)))

        ((unsafe *__param_s).bi_valid = ((0 as c_int)))

    } else {
        if ((if (unsafe *__param_s).bi_valid >= 8: 1 else: 0) != 0) {
            var __ci_expr_old_2: c_ulong = (unsafe *__param_s).pending

            ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

            ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_2]) = (((unsafe *__param_s).bi_buf as u8)))



            ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_uint) >> (8 as c_uint))

            ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid - 8)

        }
    }

}

unsafe fn bi_windup(__param_s: *mut internal_state) -> Unit {
    if ((if (unsafe *__param_s).bi_valid > 8: 1 else: 0) != 0) {
        var __ci_expr_old_0: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_0]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_1: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_1]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




    } else {
        if ((if (unsafe *__param_s).bi_valid > 0: 1 else: 0) != 0) {
            var __ci_expr_old_2: c_ulong = (unsafe *__param_s).pending

            ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

            ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_2]) = (((unsafe *__param_s).bi_buf as u8)))



        }
    }

    ((unsafe *__param_s).bi_used = (((((((unsafe *__param_s).bi_valid - 1) as c_int) & (7 as c_int)) + 1) as c_int)))

    ((unsafe *__param_s).bi_buf = ((0 as c_ushort)))

    ((unsafe *__param_s).bi_valid = ((0 as c_int)))

}

unsafe fn gen_codes(__param_tree: *mut ct_data_s, __param_max_code: c_int, __param_bl_count: *mut c_ushort) -> Unit {
    var __local_next_code: [16]c_ushort

    var __local_code: c_uint = ((0 as c_uint))

    var __local_bits: c_int

    var __local_n: c_int

    (__local_bits = ((1 as c_int)))

    while ((if __local_bits <= 15: 1 else: 0) != 0) {
        (__local_code = ((((((__local_code as c_uint) +% (((unsafe __param_bl_count[(__local_bits - 1)]) as c_int) as c_uint)) as c_uint) << (1 as c_uint)) as c_uint)))

        (__local_next_code[__local_bits] = ((__local_code as c_ushort)))


        (__local_bits = __local_bits + 1)

    }


    (__local_n = ((0 as c_int)))

    while ((if __local_n <= __param_max_code: 1 else: 0) != 0) {
        var __local_len: c_int = (((unsafe __param_tree[__local_n]).dl.len as c_int))

        if ((if __local_len == 0: 1 else: 0) != 0) {
            (__local_n = __local_n + 1)

            continue

        }

        var __ci_expr_old_0: c_ushort = __local_next_code[__local_len]

        (__local_next_code[__local_len] = (__local_next_code[__local_len] +% 1))

        ((unsafe __param_tree[__local_n]).fc.code = ((bi_reverse((__ci_expr_old_0 as c_uint), __local_len) as c_ushort)))



        (__local_n = __local_n + 1)

    }


}

fn tr_static_init() -> Unit {
    return
}

unsafe fn init_block(__param_s: *mut internal_state) -> Unit {
    var __local_n: c_int

    (__local_n = ((0 as c_int)))

    while ((if __local_n < ((256 + 1) + 29): 1 else: 0) != 0) {
        ((unsafe *__param_s).dyn_ltree[__local_n].fc.freq = ((0 as c_ushort)))

        (__local_n = __local_n + 1)

    }


    (__local_n = ((0 as c_int)))

    while ((if __local_n < 30: 1 else: 0) != 0) {
        ((unsafe *__param_s).dyn_dtree[__local_n].fc.freq = ((0 as c_ushort)))

        (__local_n = __local_n + 1)

    }


    (__local_n = ((0 as c_int)))

    while ((if __local_n < 19: 1 else: 0) != 0) {
        ((unsafe *__param_s).bl_tree[__local_n].fc.freq = ((0 as c_ushort)))

        (__local_n = __local_n + 1)

    }


    ((unsafe *__param_s).dyn_ltree[256].fc.freq = ((1 as c_ushort)))

    ((unsafe *__param_s).static_len = ((0 as c_ulong)))

    ((unsafe *__param_s).opt_len = (unsafe *__param_s).static_len)


    ((unsafe *__param_s).matches = ((0 as c_uint)))

    ((unsafe *__param_s).sym_next = (unsafe *__param_s).matches)


}

unsafe fn pqdownheap(__param_s: *mut internal_state, __param_tree: *mut ct_data_s, __param_k: c_int) -> Unit {
    var __local_k = __param_k
    var __local_v: c_int = (((unsafe *__param_s).heap[__local_k] as c_int))

    var __local_j: c_int = ((((__local_k as c_int) << (1 as c_uint)) as c_int))

    while ((if __local_j <= (unsafe *__param_s).heap_len: 1 else: 0) != 0) {
        var __ci_expr_logic_2: c_int = 0

        if ((if __local_j < (unsafe *__param_s).heap_len: 1 else: 0) != 0) {
            var __ci_expr_logic_1: c_int

            if ((if (unsafe __param_tree[(unsafe *__param_s).heap[(__local_j + 1)]]).fc.freq < (unsafe __param_tree[(unsafe *__param_s).heap[__local_j]]).fc.freq: 1 else: 0) != 0) {
                (__ci_expr_logic_1 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_0: c_int = 0

                if ((if (unsafe __param_tree[(unsafe *__param_s).heap[(__local_j + 1)]]).fc.freq == (unsafe __param_tree[(unsafe *__param_s).heap[__local_j]]).fc.freq: 1 else: 0) != 0) {
                    (__ci_expr_logic_0 = (if (if (unsafe *__param_s).depth[(unsafe *__param_s).heap[(__local_j + 1)]] <= (unsafe *__param_s).depth[(unsafe *__param_s).heap[__local_j]]: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_1 = (if __ci_expr_logic_0 != 0: 1 else: 0))

            }

            (__ci_expr_logic_2 = (if __ci_expr_logic_1 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_2 != 0) {
            (__local_j = __local_j + 1)

        }


        var __ci_expr_logic_4: c_int

        if ((if (unsafe __param_tree[__local_v]).fc.freq < (unsafe __param_tree[(unsafe *__param_s).heap[__local_j]]).fc.freq: 1 else: 0) != 0) {
            (__ci_expr_logic_4 = (if true: 1 else: 0))
        } else {
            var __ci_expr_logic_3: c_int = 0

            if ((if (unsafe __param_tree[__local_v]).fc.freq == (unsafe __param_tree[(unsafe *__param_s).heap[__local_j]]).fc.freq: 1 else: 0) != 0) {
                (__ci_expr_logic_3 = (if (if (unsafe *__param_s).depth[__local_v] <= (unsafe *__param_s).depth[(unsafe *__param_s).heap[__local_j]]: 1 else: 0) != 0: 1 else: 0))
            }

            (__ci_expr_logic_4 = (if __ci_expr_logic_3 != 0: 1 else: 0))

        }

        if (__ci_expr_logic_4 != 0) {
            break
        }


        ((unsafe *__param_s).heap[__local_k] = (((unsafe *__param_s).heap[__local_j] as c_int)))

        (__local_k = __local_j)

        (__local_j = __local_j << (1 as c_uint))

    }

    ((unsafe *__param_s).heap[__local_k] = __local_v)

}

unsafe fn gen_bitlen(__param_s: *mut internal_state, __param_desc: *mut tree_desc_s) -> Unit {
    var __local_tree: *mut ct_data_s = (unsafe *__param_desc).dyn_tree

    var __local_max_code: c_int = (unsafe *__param_desc).max_code

    var __local_stree: *const ct_data_s = (unsafe *(unsafe *__param_desc).stat_desc).static_tree

    var __local_extra: *const c_int = (unsafe *(unsafe *__param_desc).stat_desc).extra_bits

    var __local_base: c_int = (unsafe *(unsafe *__param_desc).stat_desc).extra_base

    var __local_max_length: c_int = (unsafe *(unsafe *__param_desc).stat_desc).max_length

    var __local_h: c_int

    var __local_n: c_int

    var __local_m: c_int


    var __local_bits: c_int

    var __local_xbits: c_int

    var __local_f: c_ushort

    var __local_overflow: c_int = ((0 as c_int))

    (__local_bits = ((0 as c_int)))

    while ((if __local_bits <= 15: 1 else: 0) != 0) {
        ((unsafe *__param_s).bl_count[__local_bits] = ((0 as c_ushort)))

        (__local_bits = __local_bits + 1)

    }


    ((unsafe __local_tree[(unsafe *__param_s).heap[(unsafe *__param_s).heap_max]]).dl.len = ((0 as c_ushort)))

    (__local_h = ((((unsafe *__param_s).heap_max + 1) as c_int)))

    while ((if __local_h < ((2 * ((256 + 1) + 29)) + 1): 1 else: 0) != 0) {
        (__local_n = (((unsafe *__param_s).heap[__local_h] as c_int)))

        (__local_bits = (((((unsafe __local_tree[(unsafe __local_tree[__local_n]).dl.dad]).dl.len as c_int) + 1) as c_int)))

        if ((if __local_bits > __local_max_length: 1 else: 0) != 0) {
            (__local_bits = __local_max_length)

            (__local_overflow = __local_overflow + 1)

        }

        ((unsafe __local_tree[__local_n]).dl.len = ((__local_bits as c_ushort)))

        if ((if __local_n > __local_max_code: 1 else: 0) != 0) {
            (__local_h = __local_h + 1)

            continue

        }

        ((unsafe *__param_s).bl_count[__local_bits] = ((unsafe *__param_s).bl_count[__local_bits] +% 1))

        (__local_xbits = ((0 as c_int)))

        if ((if __local_n >= __local_base: 1 else: 0) != 0) {
            (__local_xbits = (((unsafe __local_extra[(__local_n - __local_base)]) as c_int)))
        }

        (__local_f = (unsafe __local_tree[__local_n]).fc.freq)

        ((unsafe *__param_s).opt_len = ((unsafe *__param_s).opt_len +% (((__local_f as c_ulong) as c_ulong) *% (((__local_bits + __local_xbits) as c_uint) as c_ulong))))

        if (__local_stree != null) {
            ((unsafe *__param_s).static_len = ((unsafe *__param_s).static_len +% (((__local_f as c_ulong) as c_ulong) *% (((((unsafe __local_stree[__local_n]).dl.len as c_int) + __local_xbits) as c_uint) as c_ulong))))
        }


        (__local_h = __local_h + 1)

    }


    if ((if __local_overflow == 0: 1 else: 0) != 0) {
        return
    }

    loop {
        (__local_bits = (((__local_max_length - 1) as c_int)))

        while ((if (unsafe *__param_s).bl_count[__local_bits] == 0: 1 else: 0) != 0) {
            (__local_bits = __local_bits - 1)
        }

        ((unsafe *__param_s).bl_count[__local_bits] = ((unsafe *__param_s).bl_count[__local_bits] -% 1))

        ((unsafe *__param_s).bl_count[(__local_bits + 1)] = ((unsafe *__param_s).bl_count[(__local_bits + 1)] +% 2))

        ((unsafe *__param_s).bl_count[__local_max_length] = ((unsafe *__param_s).bl_count[__local_max_length] -% 1))

        (__local_overflow = __local_overflow - 2)

        if not (((if __local_overflow > 0: 1 else: 0) != 0)) {
            break
        }
    }

    (__local_bits = __local_max_length)

    while ((if __local_bits != 0: 1 else: 0) != 0) {
        (__local_n = (((unsafe *__param_s).bl_count[__local_bits] as c_int)))

        while ((if __local_n != 0: 1 else: 0) != 0) {
            (__local_h = __local_h - 1)

            (__local_m = (((unsafe *__param_s).heap[__local_h] as c_int)))


            if ((if __local_m > __local_max_code: 1 else: 0) != 0) {
                continue
            }

            if ((if (((unsafe __local_tree[__local_m]).dl.len as c_uint)) != ((__local_bits as c_uint)): 1 else: 0) != 0) {
                ((unsafe *__param_s).opt_len = ((unsafe *__param_s).opt_len +% (((((__local_bits as c_ulong) as c_ulong) -% (((unsafe __local_tree[__local_m]).dl.len as c_int) as c_ulong)) as c_ulong) *% (((unsafe __local_tree[__local_m]).fc.freq as c_int) as c_ulong))))

                ((unsafe __local_tree[__local_m]).dl.len = ((__local_bits as c_ushort)))

            }

            (__local_n = __local_n - 1)

        }


        (__local_bits = __local_bits - 1)

    }


}

unsafe fn build_tree(__param_s: *mut internal_state, __param_desc: *mut tree_desc_s) -> Unit {
    var __local_tree: *mut ct_data_s = (unsafe *__param_desc).dyn_tree

    var __local_stree: *const ct_data_s = (unsafe *(unsafe *__param_desc).stat_desc).static_tree

    var __local_elems: c_int = (unsafe *(unsafe *__param_desc).stat_desc).elems

    var __local_n: c_int

    var __local_m: c_int


    var __local_max_code: c_int = ((-1 as c_int))

    var __local_node: c_int

    ((unsafe *__param_s).heap_len = ((0 as c_int)))

    ((unsafe *__param_s).heap_max = ((((2 * ((256 + 1) + 29)) + 1) as c_int)))


    (__local_n = ((0 as c_int)))

    while ((if __local_n < __local_elems: 1 else: 0) != 0) {
        if ((if (unsafe __local_tree[__local_n]).fc.freq != 0: 1 else: 0) != 0) {
            ((unsafe *__param_s).heap_len = (unsafe *__param_s).heap_len + 1)

            (__local_max_code = __local_n)

            ((unsafe *__param_s).heap[(unsafe *__param_s).heap_len] = __local_max_code)


            ((unsafe *__param_s).depth[__local_n] = ((0 as u8)))

        } else {
            ((unsafe __local_tree[__local_n]).dl.len = ((0 as c_ushort)))

        }


        (__local_n = __local_n + 1)

    }


    while ((if (unsafe *__param_s).heap_len < 2: 1 else: 0) != 0) {
        ((unsafe *__param_s).heap_len = (unsafe *__param_s).heap_len + 1)

        var __ci_expr_ternary_0: c_int = 0

        if ((if __local_max_code < 2: 1 else: 0) != 0) {
            (__local_max_code = __local_max_code + 1)

            (__ci_expr_ternary_0 = __local_max_code)

        } else {
            (__ci_expr_ternary_0 = ((0 as c_int)))
        }

        ((unsafe *__param_s).heap[(unsafe *__param_s).heap_len] = __ci_expr_ternary_0)

        (__local_node = (((unsafe *__param_s).heap[(unsafe *__param_s).heap_len] as c_int)))


        ((unsafe __local_tree[__local_node]).fc.freq = ((1 as c_ushort)))

        ((unsafe *__param_s).depth[__local_node] = ((0 as u8)))

        ((unsafe *__param_s).opt_len = ((unsafe *__param_s).opt_len -% 1))

        if (__local_stree != null) {
            ((unsafe *__param_s).static_len = ((unsafe *__param_s).static_len -% (unsafe __local_stree[__local_node]).dl.len))
        }

    }

    ((unsafe *__param_desc).max_code = __local_max_code)

    (__local_n = ((((unsafe *__param_s).heap_len / 2) as c_int)))

    while ((if __local_n >= 1: 1 else: 0) != 0) {
        pqdownheap(__param_s, __local_tree, __local_n)

        (__local_n = __local_n - 1)

    }


    (__local_node = __local_elems)

    loop {
        (__local_n = (((unsafe *__param_s).heap[1] as c_int)))

        var __ci_expr_old_1: c_int = (unsafe *__param_s).heap_len

        ((unsafe *__param_s).heap_len = (unsafe *__param_s).heap_len - 1)

        ((unsafe *__param_s).heap[1] = (((unsafe *__param_s).heap[__ci_expr_old_1] as c_int)))


        pqdownheap(__param_s, __local_tree, (1 as c_int))


        (__local_m = (((unsafe *__param_s).heap[1] as c_int)))

        ((unsafe *__param_s).heap_max = (unsafe *__param_s).heap_max - 1)

        ((unsafe *__param_s).heap[(unsafe *__param_s).heap_max] = __local_n)


        ((unsafe *__param_s).heap_max = (unsafe *__param_s).heap_max - 1)

        ((unsafe *__param_s).heap[(unsafe *__param_s).heap_max] = __local_m)


        ((unsafe __local_tree[__local_node]).fc.freq = (((((unsafe __local_tree[__local_n]).fc.freq as c_int) + ((unsafe __local_tree[__local_m]).fc.freq as c_int)) as c_ushort)))

        var __ci_expr_ternary_2: c_int = 0

        if ((if (unsafe *__param_s).depth[__local_n] >= (unsafe *__param_s).depth[__local_m]: 1 else: 0) != 0) {
            (__ci_expr_ternary_2 = (((unsafe *__param_s).depth[__local_n] as c_int)))
        } else {
            (__ci_expr_ternary_2 = (((unsafe *__param_s).depth[__local_m] as c_int)))
        }

        ((unsafe *__param_s).depth[__local_node] = (((__ci_expr_ternary_2 + 1) as u8)))


        ((unsafe __local_tree[__local_m]).dl.dad = ((__local_node as c_ushort)))

        ((unsafe __local_tree[__local_n]).dl.dad = (unsafe __local_tree[__local_m]).dl.dad)


        var __ci_expr_old_3: c_int = __local_node

        (__local_node = __local_node + 1)

        ((unsafe *__param_s).heap[1] = __ci_expr_old_3)


        pqdownheap(__param_s, __local_tree, (1 as c_int))

        if not (((if (unsafe *__param_s).heap_len >= 2: 1 else: 0) != 0)) {
            break
        }
    }

    ((unsafe *__param_s).heap_max = (unsafe *__param_s).heap_max - 1)

    ((unsafe *__param_s).heap[(unsafe *__param_s).heap_max] = (((unsafe *__param_s).heap[1] as c_int)))


    gen_bitlen(__param_s, __param_desc)

    gen_codes(__local_tree, __local_max_code, (&(unsafe *__param_s).bl_count[0] as *mut c_ushort))

}

unsafe fn scan_tree(__param_s: *mut internal_state, __param_tree: *mut ct_data_s, __param_max_code: c_int) -> Unit {
    var __local_n: c_int

    var __local_prevlen: c_int = ((-1 as c_int))

    var __local_curlen: c_int

    var __local_nextlen: c_int = (((unsafe __param_tree[0]).dl.len as c_int))

    var __local_count: c_int = ((0 as c_int))

    var __local_max_count: c_int = ((7 as c_int))

    var __local_min_count: c_int = ((4 as c_int))

    if ((if __local_nextlen == 0: 1 else: 0) != 0) {
        (__local_max_count = ((138 as c_int)))

        (__local_min_count = ((3 as c_int)))

    }

    ((unsafe __param_tree[(__param_max_code + 1)]).dl.len = ((65535 as c_ushort)))

    (__local_n = ((0 as c_int)))

    while ((if __local_n <= __param_max_code: 1 else: 0) != 0) {
        (__local_curlen = __local_nextlen)

        (__local_nextlen = (((unsafe __param_tree[(__local_n + 1)]).dl.len as c_int)))

        var __ci_expr_logic_0: c_int = 0

        (__local_count = __local_count + 1)

        if ((if __local_count < __local_max_count: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_curlen == __local_nextlen: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_n = __local_n + 1)

            continue


        }
        if ((if __local_count < __local_min_count: 1 else: 0) != 0) {
            ((unsafe *__param_s).bl_tree[__local_curlen].fc.freq = ((unsafe *__param_s).bl_tree[__local_curlen].fc.freq +% (__local_count as c_ushort)))

        } else {
            if ((if __local_curlen != 0: 1 else: 0) != 0) {
                if ((if __local_curlen != __local_prevlen: 1 else: 0) != 0) {
                    ((unsafe *__param_s).bl_tree[__local_curlen].fc.freq = ((unsafe *__param_s).bl_tree[__local_curlen].fc.freq +% 1))
                }

                ((unsafe *__param_s).bl_tree[16].fc.freq = ((unsafe *__param_s).bl_tree[16].fc.freq +% 1))

            } else {
                if ((if __local_count <= 10: 1 else: 0) != 0) {
                    ((unsafe *__param_s).bl_tree[17].fc.freq = ((unsafe *__param_s).bl_tree[17].fc.freq +% 1))

                } else {
                    ((unsafe *__param_s).bl_tree[18].fc.freq = ((unsafe *__param_s).bl_tree[18].fc.freq +% 1))

                }
            }
        }


        (__local_count = ((0 as c_int)))

        (__local_prevlen = __local_curlen)

        if ((if __local_nextlen == 0: 1 else: 0) != 0) {
            (__local_max_count = ((138 as c_int)))

            (__local_min_count = ((3 as c_int)))


        } else {
            if ((if __local_curlen == __local_nextlen: 1 else: 0) != 0) {
                (__local_max_count = ((6 as c_int)))

                (__local_min_count = ((3 as c_int)))


            } else {
                (__local_max_count = ((7 as c_int)))

                (__local_min_count = ((4 as c_int)))


            }
        }


        (__local_n = __local_n + 1)

    }


}

unsafe fn send_tree(__param_s: *mut internal_state, __param_tree: *mut ct_data_s, __param_max_code: c_int) -> Unit {
    var __local_n: c_int

    var __local_prevlen: c_int = ((-1 as c_int))

    var __local_curlen: c_int

    var __local_nextlen: c_int = (((unsafe __param_tree[0]).dl.len as c_int))

    var __local_count: c_int = ((0 as c_int))

    var __local_max_count: c_int = ((7 as c_int))

    var __local_min_count: c_int = ((4 as c_int))

    if ((if __local_nextlen == 0: 1 else: 0) != 0) {
        (__local_max_count = ((138 as c_int)))

        (__local_min_count = ((3 as c_int)))

    }

    (__local_n = ((0 as c_int)))

    while ((if __local_n <= __param_max_code: 1 else: 0) != 0) {
        (__local_curlen = __local_nextlen)

        (__local_nextlen = (((unsafe __param_tree[(__local_n + 1)]).dl.len as c_int)))

        var __ci_expr_logic_0: c_int = 0

        (__local_count = __local_count + 1)

        if ((if __local_count < __local_max_count: 1 else: 0) != 0) {
            (__ci_expr_logic_0 = (if (if __local_curlen == __local_nextlen: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            (__local_n = __local_n + 1)

            continue


        }
        if ((if __local_count < __local_min_count: 1 else: 0) != 0) {
            loop {
                var __local_len: c_int = (((unsafe *__param_s).bl_tree[__local_curlen].dl.len as c_int))

                if ((if (unsafe *__param_s).bi_valid > (16 - __local_len): 1 else: 0) != 0) {
                    var __local_val: c_int = (((unsafe *__param_s).bl_tree[__local_curlen].fc.code as c_int))

                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    var __ci_expr_old_1: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_1]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                    var __ci_expr_old_2: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_2]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                    ((unsafe *__param_s).bi_buf = (((((__local_val as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len - 16))

                } else {
                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe *__param_s).bl_tree[__local_curlen].fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len)

                }


                (__local_count = __local_count - 1)
                if not (((if __local_count != 0: 1 else: 0) != 0)) {
                    break
                }
            }

        } else {
            if ((if __local_curlen != 0: 1 else: 0) != 0) {
                if ((if __local_curlen != __local_prevlen: 1 else: 0) != 0) {
                    var __local_len_1: c_int = (((unsafe *__param_s).bl_tree[__local_curlen].dl.len as c_int))

                    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_1): 1 else: 0) != 0) {
                        var __local_val_1: c_int = (((unsafe *__param_s).bl_tree[__local_curlen].fc.code as c_int))

                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_1 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        var __ci_expr_old_3: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_3]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                        var __ci_expr_old_4: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_4]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                        ((unsafe *__param_s).bi_buf = (((((__local_val_1 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_1 - 16))

                    } else {
                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe *__param_s).bl_tree[__local_curlen].fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_1)

                    }


                    (__local_count = __local_count - 1)

                }

                var __local_len_2: c_int = (((unsafe *__param_s).bl_tree[16].dl.len as c_int))

                if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_2): 1 else: 0) != 0) {
                    var __local_val_2: c_int = (((unsafe *__param_s).bl_tree[16].fc.code as c_int))

                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_2 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    var __ci_expr_old_5: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_5]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                    var __ci_expr_old_6: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_6]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                    ((unsafe *__param_s).bi_buf = (((((__local_val_2 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_2 - 16))

                } else {
                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe *__param_s).bl_tree[16].fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_2)

                }


                var __local_len_3: c_int = ((2 as c_int))

                if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_3): 1 else: 0) != 0) {
                    var __local_val_3: c_int = (((__local_count - 3) as c_int))

                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_3 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    var __ci_expr_old_7: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_7]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                    var __ci_expr_old_8: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_8]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                    ((unsafe *__param_s).bi_buf = (((((__local_val_3 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_3 - 16))

                } else {
                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((__local_count - 3) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_3)

                }


            } else {
                if ((if __local_count <= 10: 1 else: 0) != 0) {
                    var __local_len_4: c_int = (((unsafe *__param_s).bl_tree[17].dl.len as c_int))

                    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_4): 1 else: 0) != 0) {
                        var __local_val_4: c_int = (((unsafe *__param_s).bl_tree[17].fc.code as c_int))

                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_4 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        var __ci_expr_old_9: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_9]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                        var __ci_expr_old_10: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_10]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                        ((unsafe *__param_s).bi_buf = (((((__local_val_4 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_4 - 16))

                    } else {
                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe *__param_s).bl_tree[17].fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_4)

                    }


                    var __local_len_5: c_int = ((3 as c_int))

                    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_5): 1 else: 0) != 0) {
                        var __local_val_5: c_int = (((__local_count - 3) as c_int))

                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_5 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        var __ci_expr_old_11: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_11]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                        var __ci_expr_old_12: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_12]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                        ((unsafe *__param_s).bi_buf = (((((__local_val_5 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_5 - 16))

                    } else {
                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((__local_count - 3) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_5)

                    }


                } else {
                    var __local_len_6: c_int = (((unsafe *__param_s).bl_tree[18].dl.len as c_int))

                    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_6): 1 else: 0) != 0) {
                        var __local_val_6: c_int = (((unsafe *__param_s).bl_tree[18].fc.code as c_int))

                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_6 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        var __ci_expr_old_13: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_13]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                        var __ci_expr_old_14: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_14]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                        ((unsafe *__param_s).bi_buf = (((((__local_val_6 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_6 - 16))

                    } else {
                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe *__param_s).bl_tree[18].fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_6)

                    }


                    var __local_len_7: c_int = ((7 as c_int))

                    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_7): 1 else: 0) != 0) {
                        var __local_val_7: c_int = (((__local_count - 11) as c_int))

                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_7 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        var __ci_expr_old_15: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_15]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                        var __ci_expr_old_16: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_16]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                        ((unsafe *__param_s).bi_buf = (((((__local_val_7 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_7 - 16))

                    } else {
                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((__local_count - 11) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_7)

                    }


                }
            }
        }


        (__local_count = ((0 as c_int)))

        (__local_prevlen = __local_curlen)

        if ((if __local_nextlen == 0: 1 else: 0) != 0) {
            (__local_max_count = ((138 as c_int)))

            (__local_min_count = ((3 as c_int)))


        } else {
            if ((if __local_curlen == __local_nextlen: 1 else: 0) != 0) {
                (__local_max_count = ((6 as c_int)))

                (__local_min_count = ((3 as c_int)))


            } else {
                (__local_max_count = ((7 as c_int)))

                (__local_min_count = ((4 as c_int)))


            }
        }


        (__local_n = __local_n + 1)

    }


}

unsafe fn build_bl_tree(__param_s: *mut internal_state) -> c_int {
    var __local_max_blindex: c_int

    scan_tree(__param_s, (&(unsafe *__param_s).dyn_ltree[0] as *mut ct_data_s), (unsafe *(&raw const (unsafe *__param_s).l_desc as *const tree_desc_s)).max_code)

    scan_tree(__param_s, (&(unsafe *__param_s).dyn_dtree[0] as *mut ct_data_s), (unsafe *(&raw const (unsafe *__param_s).d_desc as *const tree_desc_s)).max_code)

    build_tree(__param_s, ((&raw const (unsafe *__param_s).bl_desc as *const tree_desc_s) as *mut tree_desc_s))

    (__local_max_blindex = (((19 - 1) as c_int)))

    while ((if __local_max_blindex >= 3: 1 else: 0) != 0) {
        if ((if (unsafe *__param_s).bl_tree[bl_order[__local_max_blindex]].dl.len != 0: 1 else: 0) != 0) {
            break
        }


        (__local_max_blindex = __local_max_blindex - 1)

    }


    ((unsafe *__param_s).opt_len = ((unsafe *__param_s).opt_len +% ((((((((3 as c_ulong) *% ((((__local_max_blindex as c_ulong) as c_ulong) +% (1 as c_ulong)) as c_ulong)) as c_ulong) +% (5 as c_ulong)) as c_ulong) +% (5 as c_ulong)) as c_ulong) +% (4 as c_ulong))))

    return __local_max_blindex

}

unsafe fn send_all_trees(__param_s: *mut internal_state, __param_lcodes: c_int, __param_dcodes: c_int, __param_blcodes: c_int) -> Unit {
    var __local_rank: c_int

    var __local_len: c_int = ((5 as c_int))

    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len): 1 else: 0) != 0) {
        var __local_val: c_int = (((__param_lcodes - 257) as c_int))

        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        var __ci_expr_old_0: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_0]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_1: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_1]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = (((((__local_val as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len - 16))

    } else {
        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((__param_lcodes - 257) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len)

    }


    var __local_len_1: c_int = ((5 as c_int))

    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_1): 1 else: 0) != 0) {
        var __local_val_1: c_int = (((__param_dcodes - 1) as c_int))

        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_1 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        var __ci_expr_old_2: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_2]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_3: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_3]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = (((((__local_val_1 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_1 - 16))

    } else {
        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((__param_dcodes - 1) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_1)

    }


    var __local_len_2: c_int = ((4 as c_int))

    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_2): 1 else: 0) != 0) {
        var __local_val_2: c_int = (((__param_blcodes - 4) as c_int))

        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_2 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        var __ci_expr_old_4: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_4]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_5: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_5]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = (((((__local_val_2 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_2 - 16))

    } else {
        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((__param_blcodes - 4) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_2)

    }


    (__local_rank = ((0 as c_int)))

    while ((if __local_rank < __param_blcodes: 1 else: 0) != 0) {
        var __local_len_3: c_int = ((3 as c_int))

        if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_3): 1 else: 0) != 0) {
            var __local_val_3: c_int = (((unsafe *__param_s).bl_tree[bl_order[__local_rank]].dl.len as c_int))

            ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_3 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

            var __ci_expr_old_6: c_ulong = (unsafe *__param_s).pending

            ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

            ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_6]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



            var __ci_expr_old_7: c_ulong = (unsafe *__param_s).pending

            ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

            ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_7]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




            ((unsafe *__param_s).bi_buf = (((((__local_val_3 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

            ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_3 - 16))

        } else {
            ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe *__param_s).bl_tree[bl_order[__local_rank]].dl.len as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

            ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_3)

        }



        (__local_rank = __local_rank + 1)

    }


    send_tree(__param_s, (&(unsafe *__param_s).dyn_ltree[0] as *mut ct_data_s), ((__param_lcodes - 1) as c_int))

    send_tree(__param_s, (&(unsafe *__param_s).dyn_dtree[0] as *mut ct_data_s), ((__param_dcodes - 1) as c_int))

}

unsafe fn compress_block(__param_s: *mut internal_state, __param_ltree: *const ct_data_s, __param_dtree: *const ct_data_s) -> Unit {
    var __local_dist: c_uint

    var __local_lc: c_int

    var __local_sx: c_uint = ((0 as c_uint))

    var __local_code: c_uint

    var __local_extra: c_int

    if ((if (unsafe *__param_s).sym_next != 0: 1 else: 0) != 0) {
        loop {
            var __ci_expr_old_0: c_uint = __local_sx

            (__local_sx = (__local_sx +% 1))

            (__local_dist = ((((((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_0]) as c_int) as c_int) & (255 as c_int)) as c_uint)))


            var __ci_expr_old_1: c_uint = __local_sx

            (__local_sx = (__local_sx +% 1))

            (__local_dist = (__local_dist +% (((((((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_1]) as c_int) as c_int) & (255 as c_int)) as c_uint) as c_uint) << (8 as c_uint))))


            var __ci_expr_old_2: c_uint = __local_sx

            (__local_sx = (__local_sx +% 1))

            (__local_lc = (((unsafe (unsafe *__param_s).sym_buf[__ci_expr_old_2]) as c_int)))


            if ((if __local_dist == 0: 1 else: 0) != 0) {
                var __local_len: c_int = (((unsafe __param_ltree[__local_lc]).dl.len as c_int))

                if ((if (unsafe *__param_s).bi_valid > (16 - __local_len): 1 else: 0) != 0) {
                    var __local_val: c_int = (((unsafe __param_ltree[__local_lc]).fc.code as c_int))

                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    var __ci_expr_old_3: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_3]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                    var __ci_expr_old_4: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_4]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                    ((unsafe *__param_s).bi_buf = (((((__local_val as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len - 16))

                } else {
                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe __param_ltree[__local_lc]).fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len)

                }


            } else {
                (__local_code = ((_length_code[__local_lc] as c_uint)))

                var __local_len_1: c_int = (((unsafe __param_ltree[((((__local_code as c_uint) +% (256 as c_uint)) as c_uint) +% (1 as c_uint))]).dl.len as c_int))

                if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_1): 1 else: 0) != 0) {
                    var __local_val_1: c_int = (((unsafe __param_ltree[((((__local_code as c_uint) +% (256 as c_uint)) as c_uint) +% (1 as c_uint))]).fc.code as c_int))

                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_1 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    var __ci_expr_old_5: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_5]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                    var __ci_expr_old_6: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_6]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                    ((unsafe *__param_s).bi_buf = (((((__local_val_1 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_1 - 16))

                } else {
                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe __param_ltree[((((__local_code as c_uint) +% (256 as c_uint)) as c_uint) +% (1 as c_uint))]).fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_1)

                }


                (__local_extra = ((extra_lbits[__local_code] as c_int)))

                if ((if __local_extra != 0: 1 else: 0) != 0) {
                    (__local_lc = __local_lc - base_length[__local_code])

                    var __local_len_2: c_int = __local_extra

                    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_2): 1 else: 0) != 0) {
                        var __local_val_2: c_int = __local_lc

                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_2 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        var __ci_expr_old_7: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_7]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                        var __ci_expr_old_8: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_8]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                        ((unsafe *__param_s).bi_buf = (((((__local_val_2 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_2 - 16))

                    } else {
                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_lc as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_2)

                    }


                }

                (__local_dist = (__local_dist -% 1))

                var __ci_expr_ternary_9: c_int = 0

                if ((if __local_dist < 256: 1 else: 0) != 0) {
                    (__ci_expr_ternary_9 = ((_dist_code[__local_dist] as c_int)))
                } else {
                    (__ci_expr_ternary_9 = ((_dist_code[((256 as c_uint) +% (((__local_dist as c_uint) >> (7 as c_uint)) as c_uint))] as c_int)))
                }

                (__local_code = ((__ci_expr_ternary_9 as c_uint)))


                var __local_len_3: c_int = (((unsafe __param_dtree[__local_code]).dl.len as c_int))

                if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_3): 1 else: 0) != 0) {
                    var __local_val_3: c_int = (((unsafe __param_dtree[__local_code]).fc.code as c_int))

                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_3 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    var __ci_expr_old_10: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_10]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                    var __ci_expr_old_11: c_ulong = (unsafe *__param_s).pending

                    ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                    ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_11]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                    ((unsafe *__param_s).bi_buf = (((((__local_val_3 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_3 - 16))

                } else {
                    ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe __param_dtree[__local_code]).fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                    ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_3)

                }


                (__local_extra = ((extra_dbits[__local_code] as c_int)))

                if ((if __local_extra != 0: 1 else: 0) != 0) {
                    (__local_dist = (__local_dist -% (base_dist[__local_code] as c_uint)))

                    var __local_len_4: c_int = __local_extra

                    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_4): 1 else: 0) != 0) {
                        var __local_val_4: c_int = ((__local_dist as c_int))

                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_4 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        var __ci_expr_old_12: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_12]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



                        var __ci_expr_old_13: c_ulong = (unsafe *__param_s).pending

                        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

                        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_13]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




                        ((unsafe *__param_s).bi_buf = (((((__local_val_4 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_4 - 16))

                    } else {
                        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | (((((__local_dist as c_int) as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

                        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_4)

                    }


                }

            }

            if not (((if __local_sx < (unsafe *__param_s).sym_next: 1 else: 0) != 0)) {
                break
            }
        }
    }

    var __local_len_5: c_int = (((unsafe __param_ltree[256]).dl.len as c_int))

    if ((if (unsafe *__param_s).bi_valid > (16 - __local_len_5): 1 else: 0) != 0) {
        var __local_val_5: c_int = (((unsafe __param_ltree[256]).fc.code as c_int))

        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((__local_val_5 as c_ushort) as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        var __ci_expr_old_14: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_14]) = ((((((unsafe *__param_s).bi_buf as c_int) as c_int) & (255 as c_int)) as u8)))



        var __ci_expr_old_15: c_ulong = (unsafe *__param_s).pending

        ((unsafe *__param_s).pending = ((unsafe *__param_s).pending +% 1))

        ((unsafe (unsafe *__param_s).pending_buf[__ci_expr_old_15]) = (((((unsafe *__param_s).bi_buf as c_int) >> (8 as c_uint)) as u8)))




        ((unsafe *__param_s).bi_buf = (((((__local_val_5 as c_ushort) as c_int) >> ((16 - (unsafe *__param_s).bi_valid) as c_uint)) as c_ushort)))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + (__local_len_5 - 16))

    } else {
        ((unsafe *__param_s).bi_buf = ((unsafe *__param_s).bi_buf as c_ushort) | ((((unsafe __param_ltree[256]).fc.code as c_int) << ((unsafe *__param_s).bi_valid as c_uint)) as c_ushort))

        ((unsafe *__param_s).bi_valid = (unsafe *__param_s).bi_valid + __local_len_5)

    }


}

unsafe fn detect_data_type(__param_s: *mut internal_state) -> c_int {
    var __local_block_mask: c_ulong = ((4093624447 as c_ulong))

    var __local_n: c_int

    (__local_n = ((0 as c_int)))

    while ((if __local_n <= 31: 1 else: 0) != 0) {
        var __ci_expr_logic_0: c_int = 0

        if (((__local_block_mask as c_ulong) & (1 as c_ulong)) != 0) {
            (__ci_expr_logic_0 = (if (if (unsafe *__param_s).dyn_ltree[__local_n].fc.freq != 0: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_0 != 0) {
            return 0
        }


        (__local_n = __local_n + 1)

        (__local_block_mask = __local_block_mask >> (1 as c_uint))


    }


    var __ci_expr_logic_2: c_int

    var __ci_expr_logic_1: c_int

    if ((if (unsafe *__param_s).dyn_ltree[9].fc.freq != 0: 1 else: 0) != 0) {
        (__ci_expr_logic_1 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_1 = (if (if (unsafe *__param_s).dyn_ltree[10].fc.freq != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_1 != 0) {
        (__ci_expr_logic_2 = (if true: 1 else: 0))
    } else {
        (__ci_expr_logic_2 = (if (if (unsafe *__param_s).dyn_ltree[13].fc.freq != 0: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_2 != 0) {
        return 1
    }


    (__local_n = ((32 as c_int)))

    while ((if __local_n < 256: 1 else: 0) != 0) {
        if ((if (unsafe *__param_s).dyn_ltree[__local_n].fc.freq != 0: 1 else: 0) != 0) {
            return 1
        }

        (__local_n = __local_n + 1)

    }


    return 0

}

let extra_lbits: [29]c_int = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0]
let extra_dbits: [30]c_int = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13]
let extra_blbits: [19]c_int = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7]
let bl_order: [19]u8 = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]
let static_ltree: [288]ct_data_s = [ct_data_s { fc: ct_data_s_fc { freq: 12 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 140 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 76 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 204 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 44 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 172 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 108 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 236 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 28 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 156 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 92 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 220 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 60 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 188 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 124 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 252 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 2 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 130 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 66 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 194 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 34 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 162 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 98 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 226 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 18 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 146 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 82 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 210 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 50 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 178 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 114 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 242 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 10 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 138 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 74 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 202 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 42 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 170 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 106 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 234 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 26 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 154 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 90 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 218 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 58 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 186 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 122 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 250 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 6 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 134 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 70 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 198 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 38 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 166 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 102 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 230 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 22 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 150 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 86 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 214 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 54 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 182 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 118 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 246 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 14 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 142 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 78 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 206 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 46 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 174 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 110 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 238 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 30 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 158 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 94 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 222 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 62 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 190 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 126 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 254 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 1 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 129 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 65 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 193 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 33 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 161 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 97 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 225 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 17 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 145 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 81 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 209 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 49 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 177 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 113 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 241 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 9 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 137 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 73 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 201 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 41 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 169 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 105 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 233 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 25 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 153 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 89 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 217 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 57 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 185 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 121 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 249 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 5 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 133 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 69 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 197 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 37 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 165 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 101 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 229 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 21 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 149 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 85 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 213 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 53 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 181 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 117 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 245 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 13 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 141 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 77 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 205 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 45 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 173 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 109 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 237 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 29 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 157 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 93 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 221 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 61 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 189 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 125 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 253 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 19 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 275 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 147 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 403 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 83 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 339 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 211 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 467 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 51 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 307 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 179 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 435 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 115 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 371 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 243 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 499 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 11 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 267 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 139 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 395 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 75 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 331 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 203 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 459 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 43 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 299 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 171 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 427 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 107 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 363 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 235 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 491 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 27 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 283 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 155 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 411 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 91 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 347 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 219 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 475 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 59 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 315 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 187 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 443 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 123 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 379 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 251 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 507 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 7 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 263 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 135 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 391 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 71 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 327 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 199 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 455 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 39 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 295 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 167 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 423 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 103 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 359 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 231 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 487 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 23 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 279 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 151 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 407 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 87 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 343 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 215 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 471 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 55 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 311 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 183 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 439 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 119 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 375 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 247 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 503 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 15 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 271 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 143 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 399 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 79 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 335 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 207 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 463 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 47 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 303 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 175 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 431 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 111 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 367 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 239 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 495 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 31 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 287 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 159 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 415 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 95 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 351 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 223 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 479 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 63 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 319 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 191 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 447 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 127 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 383 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 255 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 511 }, dl: ct_data_s_dl { dad: 9 } }, ct_data_s { fc: ct_data_s_fc { freq: 0 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 64 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 32 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 96 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 16 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 80 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 48 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 112 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 8 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 72 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 40 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 104 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 24 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 88 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 56 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 120 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 4 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 68 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 36 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 100 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 20 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 84 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 52 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 116 }, dl: ct_data_s_dl { dad: 7 } }, ct_data_s { fc: ct_data_s_fc { freq: 3 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 131 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 67 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 195 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 35 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 163 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 99 }, dl: ct_data_s_dl { dad: 8 } }, ct_data_s { fc: ct_data_s_fc { freq: 227 }, dl: ct_data_s_dl { dad: 8 } }]
let static_dtree: [30]ct_data_s = [ct_data_s { fc: ct_data_s_fc { freq: 0 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 16 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 8 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 24 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 4 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 20 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 12 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 28 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 2 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 18 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 10 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 26 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 6 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 22 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 14 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 30 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 1 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 17 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 9 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 25 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 5 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 21 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 13 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 29 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 3 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 19 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 11 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 27 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 7 }, dl: ct_data_s_dl { dad: 5 } }, ct_data_s { fc: ct_data_s_fc { freq: 23 }, dl: ct_data_s_dl { dad: 5 } }]
let base_length: [29]c_int = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 0]
let base_dist: [30]c_int = [0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096, 6144, 8192, 12288, 16384, 24576]
let static_l_desc: static_tree_desc_s = static_tree_desc_s { static_tree: (&raw const static_ltree[0] as *const ct_data_s), extra_bits: (&raw const extra_lbits[0] as *const c_int), extra_base: (256 + 1), elems: ((256 + 1) + 29), max_length: 15 }
let static_d_desc: static_tree_desc_s = static_tree_desc_s { static_tree: (&raw const static_dtree[0] as *const ct_data_s), extra_bits: (&raw const extra_dbits[0] as *const c_int), extra_base: 0, elems: 30, max_length: 15 }
let static_bl_desc: static_tree_desc_s = static_tree_desc_s { static_tree: null, extra_bits: (&raw const extra_blbits[0] as *const c_int), extra_base: 0, elems: 19, max_length: 7 }
