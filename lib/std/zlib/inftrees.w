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

pub unsafe fn inflate_table(__param_type_: i32, __param_lens: *mut c_ushort, __param_codes: c_uint, __param_table: *mut *mut code, __param_bits: *mut c_uint, __param_work: *mut c_ushort) -> c_int {
    var __local_len: c_uint

    var __local_sym: c_uint

    var __local_min: c_uint

    var __local_max: c_uint


    var __local_root: c_uint

    var __local_curr: c_uint

    var __local_drop: c_uint

    var __local_left: c_int

    var __local_used: c_uint

    var __local_huff: c_uint

    var __local_incr: c_uint

    var __local_fill: c_uint

    var __local_low: c_uint

    var __local_mask: c_uint

    var __local_here: code

    var __local_next: *mut code

    var __local_base: *const c_ushort = ((null as *const c_ushort))

    var __local_extra: *const c_ushort = ((null as *const c_ushort))

    var __local_match_: c_uint = ((0 as c_uint))

    var __local_count: [16]c_ushort

    var __local_offs: [16]c_ushort

    var __local_lbase: [31]c_ushort = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 0, 0]

    var __local_lext: [31]c_ushort = [16, 16, 16, 16, 16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 16, 199, 75]

    var __local_dbase: [32]c_ushort = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577, 0, 0]

    var __local_dext: [32]c_ushort = [16, 16, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24, 25, 25, 26, 26, 27, 27, 28, 28, 29, 29, 64, 64]

    (__local_len = ((0 as c_uint)))

    while ((if __local_len <= 15: 1 else: 0) != 0) {
        (__local_count[__local_len] = ((0 as c_ushort)))

        (__local_len = (__local_len +% 1))

    }


    (__local_sym = ((0 as c_uint)))

    while ((if __local_sym < __param_codes: 1 else: 0) != 0) {
        (__local_count[(unsafe __param_lens[__local_sym])] = (__local_count[(unsafe __param_lens[__local_sym])] +% 1))

        (__local_sym = (__local_sym +% 1))

    }


    (__local_root = (unsafe *__param_bits))

    (__local_max = ((15 as c_uint)))

    while ((if __local_max >= 1: 1 else: 0) != 0) {
        if ((if __local_count[__local_max] != 0: 1 else: 0) != 0) {
            break
        }

        (__local_max = (__local_max -% 1))

    }


    if ((if __local_root > __local_max: 1 else: 0) != 0) {
        (__local_root = __local_max)
    }

    if ((if __local_max == 0: 1 else: 0) != 0) {
        (__local_here.op = ((64 as u8)))

        (__local_here.bits = ((1 as u8)))

        (__local_here.val = ((0 as c_ushort)))

        var __ci_expr_old_0: *mut code = (unsafe *__param_table)

        ((unsafe *__param_table) = (unsafe *__param_table) + 1)

        with_memcpy((&raw mut (unsafe *__ci_expr_old_0) as *i8), (&raw const __local_here as *i8), sizeof[code]())


        var __ci_expr_old_1: *mut code = (unsafe *__param_table)

        ((unsafe *__param_table) = (unsafe *__param_table) + 1)

        with_memcpy((&raw mut (unsafe *__ci_expr_old_1) as *i8), (&raw const __local_here as *i8), sizeof[code]())


        ((unsafe *__param_bits) = ((1 as c_uint)))

        return 0

    }

    (__local_min = ((1 as c_uint)))

    while ((if __local_min < __local_max: 1 else: 0) != 0) {
        if ((if __local_count[__local_min] != 0: 1 else: 0) != 0) {
            break
        }

        (__local_min = (__local_min +% 1))

    }


    if ((if __local_root < __local_min: 1 else: 0) != 0) {
        (__local_root = __local_min)
    }

    (__local_left = ((1 as c_int)))

    (__local_len = ((1 as c_uint)))

    while ((if __local_len <= 15: 1 else: 0) != 0) {
        (__local_left = __local_left << (1 as c_uint))

        (__local_left = __local_left - (__local_count[__local_len] as c_int))

        if ((if __local_left < 0: 1 else: 0) != 0) {
            return -1
        }


        (__local_len = (__local_len +% 1))

    }


    var __ci_expr_logic_3: c_int = 0

    if ((if __local_left > 0: 1 else: 0) != 0) {
        var __ci_expr_logic_2: c_int

        if ((if __param_type_ == 0: 1 else: 0) != 0) {
            (__ci_expr_logic_2 = (if true: 1 else: 0))
        } else {
            (__ci_expr_logic_2 = (if (if __local_max != 1: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_3 = (if __ci_expr_logic_2 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_3 != 0) {
        return -1
    }


    (__local_offs[1] = ((0 as c_ushort)))

    (__local_len = ((1 as c_uint)))

    while ((if __local_len < 15: 1 else: 0) != 0) {
        (__local_offs[((__local_len as c_uint) +% (1 as c_uint))] = ((((__local_offs[__local_len] as c_int) + (__local_count[__local_len] as c_int)) as c_ushort)))

        (__local_len = (__local_len +% 1))

    }


    (__local_sym = ((0 as c_uint)))

    while ((if __local_sym < __param_codes: 1 else: 0) != 0) {
        if ((if (unsafe __param_lens[__local_sym]) != 0: 1 else: 0) != 0) {
            var __ci_expr_old_4: c_ushort = __local_offs[(unsafe __param_lens[__local_sym])]

            (__local_offs[(unsafe __param_lens[__local_sym])] = (__local_offs[(unsafe __param_lens[__local_sym])] +% 1))

            ((unsafe __param_work[__ci_expr_old_4]) = ((__local_sym as c_ushort)))

        }

        (__local_sym = (__local_sym +% 1))

    }


    while true {
        match __param_type_ {
            0 => {
                (__local_match_ = ((20 as c_uint)))
            },
            1 => {
                (__local_base = (&__local_lbase[0] as *const c_ushort))

                (__local_extra = (&__local_lext[0] as *const c_ushort))

                (__local_match_ = ((257 as c_uint)))

            },
            2 => {
                (__local_base = (&__local_dbase[0] as *const c_ushort))

                (__local_extra = (&__local_dext[0] as *const c_ushort))

            },
        }

        break

    }

    (__local_huff = ((0 as c_uint)))

    (__local_sym = ((0 as c_uint)))

    (__local_len = __local_min)

    (__local_next = (unsafe *__param_table))

    (__local_curr = __local_root)

    (__local_drop = ((0 as c_uint)))

    (__local_low = ((-1 as c_uint)))

    (__local_used = ((((1 as c_uint) << (__local_root as c_uint)) as c_uint)))

    (__local_mask = ((((__local_used as c_uint) -% (1 as c_uint)) as c_uint)))

    var __ci_expr_logic_8: c_int

    var __ci_expr_logic_6: c_int = 0

    if ((if __param_type_ == 1: 1 else: 0) != 0) {
        (__ci_expr_logic_6 = (if (if __local_used > 852: 1 else: 0) != 0: 1 else: 0))
    }

    if (__ci_expr_logic_6 != 0) {
        (__ci_expr_logic_8 = (if true: 1 else: 0))
    } else {
        var __ci_expr_logic_7: c_int = 0

        if ((if __param_type_ == 2: 1 else: 0) != 0) {
            (__ci_expr_logic_7 = (if (if __local_used > 592: 1 else: 0) != 0: 1 else: 0))
        }

        (__ci_expr_logic_8 = (if __ci_expr_logic_7 != 0: 1 else: 0))

    }

    if (__ci_expr_logic_8 != 0) {
        return 1
    }


    while true {
        (__local_here.bits = ((((__local_len as c_uint) -% (__local_drop as c_uint)) as u8)))

        if ((if ((((unsafe __param_work[__local_sym]) as c_int) as c_uint) +% (1 as c_uint)) < __local_match_: 1 else: 0) != 0) {
            (__local_here.op = ((0 as u8)))

            (__local_here.val = (((unsafe __param_work[__local_sym]) as c_ushort)))

        } else {
            if ((if (unsafe __param_work[__local_sym]) >= __local_match_: 1 else: 0) != 0) {
                (__local_here.op = (((unsafe __local_extra[((((unsafe __param_work[__local_sym]) as c_int) as c_uint) -% (__local_match_ as c_uint))]) as u8)))

                (__local_here.val = (((unsafe __local_base[((((unsafe __param_work[__local_sym]) as c_int) as c_uint) -% (__local_match_ as c_uint))]) as c_ushort)))

            } else {
                (__local_here.op = (((32 + 64) as u8)))

                (__local_here.val = ((0 as c_ushort)))

            }
        }

        (__local_incr = ((((1 as c_uint) << (((__local_len as c_uint) -% (__local_drop as c_uint)) as c_uint)) as c_uint)))

        (__local_fill = ((((1 as c_uint) << (__local_curr as c_uint)) as c_uint)))

        (__local_min = __local_fill)

        loop {
            (__local_fill = (__local_fill -% __local_incr))

            ((unsafe __local_next[((((__local_huff as c_uint) >> (__local_drop as c_uint)) as c_uint) +% (__local_fill as c_uint))]) = __local_here)

            if not (((if __local_fill != 0: 1 else: 0) != 0)) {
                break
            }
        }

        (__local_incr = ((((1 as c_uint) << (((__local_len as c_uint) -% (1 as c_uint)) as c_uint)) as c_uint)))

        while (((__local_huff as c_uint) & (__local_incr as c_uint)) != 0) {
            (__local_incr = __local_incr >> (1 as c_uint))
        }

        if ((if __local_incr != 0: 1 else: 0) != 0) {
            (__local_huff = (__local_huff as c_uint) & (((__local_incr as c_uint) -% (1 as c_uint)) as c_uint))

            (__local_huff = (__local_huff +% __local_incr))

        } else {
            (__local_huff = ((0 as c_uint)))
        }

        (__local_sym = (__local_sym +% 1))

        (__local_count[__local_len] = (__local_count[__local_len] -% 1))

        if ((if __local_count[__local_len] == 0: 1 else: 0) != 0) {
            if ((if __local_len == __local_max: 1 else: 0) != 0) {
                break
            }

            (__local_len = (((unsafe __param_lens[(unsafe __param_work[__local_sym])]) as c_uint)))

        }


        var __ci_expr_logic_9: c_int = 0

        if ((if __local_len > __local_root: 1 else: 0) != 0) {
            (__ci_expr_logic_9 = (if (if ((__local_huff as c_uint) & (__local_mask as c_uint)) != __local_low: 1 else: 0) != 0: 1 else: 0))
        }

        if (__ci_expr_logic_9 != 0) {
            if ((if __local_drop == 0: 1 else: 0) != 0) {
                (__local_drop = __local_root)
            }

            (__local_next = __local_next + (__local_min as usize))

            (__local_curr = ((((__local_len as c_uint) -% (__local_drop as c_uint)) as c_uint)))

            (__local_left = ((((1 as c_int) << (__local_curr as c_uint)) as c_int)))

            while ((if ((__local_curr as c_uint) +% (__local_drop as c_uint)) < __local_max: 1 else: 0) != 0) {
                (__local_left = __local_left - (__local_count[((__local_curr as c_uint) +% (__local_drop as c_uint))] as c_int))

                if ((if __local_left <= 0: 1 else: 0) != 0) {
                    break
                }

                (__local_curr = (__local_curr +% 1))

                (__local_left = __local_left << (1 as c_uint))

            }

            (__local_used = (__local_used +% ((1 as c_uint) << (__local_curr as c_uint))))

            var __ci_expr_logic_12: c_int

            var __ci_expr_logic_10: c_int = 0

            if ((if __param_type_ == 1: 1 else: 0) != 0) {
                (__ci_expr_logic_10 = (if (if __local_used > 852: 1 else: 0) != 0: 1 else: 0))
            }

            if (__ci_expr_logic_10 != 0) {
                (__ci_expr_logic_12 = (if true: 1 else: 0))
            } else {
                var __ci_expr_logic_11: c_int = 0

                if ((if __param_type_ == 2: 1 else: 0) != 0) {
                    (__ci_expr_logic_11 = (if (if __local_used > 592: 1 else: 0) != 0: 1 else: 0))
                }

                (__ci_expr_logic_12 = (if __ci_expr_logic_11 != 0: 1 else: 0))

            }

            if (__ci_expr_logic_12 != 0) {
                return 1
            }


            (__local_low = ((((__local_huff as c_uint) & (__local_mask as c_uint)) as c_uint)))

            ((unsafe (unsafe *__param_table)[__local_low]).op = ((__local_curr as u8)))

            ((unsafe (unsafe *__param_table)[__local_low]).bits = ((__local_root as u8)))

            ((unsafe (unsafe *__param_table)[__local_low]).val = (((((__local_next as usize) -% ((unsafe *__param_table) as usize)) / sizeof[code]()) as c_ushort)))

        }


    }

    if ((if __local_huff != 0: 1 else: 0) != 0) {
        (__local_here.op = ((64 as u8)))

        (__local_here.bits = ((((__local_len as c_uint) -% (__local_drop as c_uint)) as u8)))

        (__local_here.val = ((0 as c_ushort)))

        ((unsafe __local_next[__local_huff]) = __local_here)

    }

    ((unsafe *__param_table) = (unsafe *__param_table) + (__local_used as usize))

    ((unsafe *__param_bits) = __local_root)

    return 0

}

pub unsafe fn inflate_fixed(__param_state: *mut inflate_state) -> Unit {
    ((unsafe *__param_state).lencode = (&lenfix[0] as *const code))

    ((unsafe *__param_state).lenbits = ((9 as c_uint)))

    ((unsafe *__param_state).distcode = (&distfix[0] as *const code))

    ((unsafe *__param_state).distbits = ((5 as c_uint)))

}

let lenfix: [512]code = [code { op: 96, bits: 7, val: 0 }, code { op: 0, bits: 8, val: 80 }, code { op: 0, bits: 8, val: 16 }, code { op: 20, bits: 8, val: 115 }, code { op: 18, bits: 7, val: 31 }, code { op: 0, bits: 8, val: 112 }, code { op: 0, bits: 8, val: 48 }, code { op: 0, bits: 9, val: 192 }, code { op: 16, bits: 7, val: 10 }, code { op: 0, bits: 8, val: 96 }, code { op: 0, bits: 8, val: 32 }, code { op: 0, bits: 9, val: 160 }, code { op: 0, bits: 8, val: 0 }, code { op: 0, bits: 8, val: 128 }, code { op: 0, bits: 8, val: 64 }, code { op: 0, bits: 9, val: 224 }, code { op: 16, bits: 7, val: 6 }, code { op: 0, bits: 8, val: 88 }, code { op: 0, bits: 8, val: 24 }, code { op: 0, bits: 9, val: 144 }, code { op: 19, bits: 7, val: 59 }, code { op: 0, bits: 8, val: 120 }, code { op: 0, bits: 8, val: 56 }, code { op: 0, bits: 9, val: 208 }, code { op: 17, bits: 7, val: 17 }, code { op: 0, bits: 8, val: 104 }, code { op: 0, bits: 8, val: 40 }, code { op: 0, bits: 9, val: 176 }, code { op: 0, bits: 8, val: 8 }, code { op: 0, bits: 8, val: 136 }, code { op: 0, bits: 8, val: 72 }, code { op: 0, bits: 9, val: 240 }, code { op: 16, bits: 7, val: 4 }, code { op: 0, bits: 8, val: 84 }, code { op: 0, bits: 8, val: 20 }, code { op: 21, bits: 8, val: 227 }, code { op: 19, bits: 7, val: 43 }, code { op: 0, bits: 8, val: 116 }, code { op: 0, bits: 8, val: 52 }, code { op: 0, bits: 9, val: 200 }, code { op: 17, bits: 7, val: 13 }, code { op: 0, bits: 8, val: 100 }, code { op: 0, bits: 8, val: 36 }, code { op: 0, bits: 9, val: 168 }, code { op: 0, bits: 8, val: 4 }, code { op: 0, bits: 8, val: 132 }, code { op: 0, bits: 8, val: 68 }, code { op: 0, bits: 9, val: 232 }, code { op: 16, bits: 7, val: 8 }, code { op: 0, bits: 8, val: 92 }, code { op: 0, bits: 8, val: 28 }, code { op: 0, bits: 9, val: 152 }, code { op: 20, bits: 7, val: 83 }, code { op: 0, bits: 8, val: 124 }, code { op: 0, bits: 8, val: 60 }, code { op: 0, bits: 9, val: 216 }, code { op: 18, bits: 7, val: 23 }, code { op: 0, bits: 8, val: 108 }, code { op: 0, bits: 8, val: 44 }, code { op: 0, bits: 9, val: 184 }, code { op: 0, bits: 8, val: 12 }, code { op: 0, bits: 8, val: 140 }, code { op: 0, bits: 8, val: 76 }, code { op: 0, bits: 9, val: 248 }, code { op: 16, bits: 7, val: 3 }, code { op: 0, bits: 8, val: 82 }, code { op: 0, bits: 8, val: 18 }, code { op: 21, bits: 8, val: 163 }, code { op: 19, bits: 7, val: 35 }, code { op: 0, bits: 8, val: 114 }, code { op: 0, bits: 8, val: 50 }, code { op: 0, bits: 9, val: 196 }, code { op: 17, bits: 7, val: 11 }, code { op: 0, bits: 8, val: 98 }, code { op: 0, bits: 8, val: 34 }, code { op: 0, bits: 9, val: 164 }, code { op: 0, bits: 8, val: 2 }, code { op: 0, bits: 8, val: 130 }, code { op: 0, bits: 8, val: 66 }, code { op: 0, bits: 9, val: 228 }, code { op: 16, bits: 7, val: 7 }, code { op: 0, bits: 8, val: 90 }, code { op: 0, bits: 8, val: 26 }, code { op: 0, bits: 9, val: 148 }, code { op: 20, bits: 7, val: 67 }, code { op: 0, bits: 8, val: 122 }, code { op: 0, bits: 8, val: 58 }, code { op: 0, bits: 9, val: 212 }, code { op: 18, bits: 7, val: 19 }, code { op: 0, bits: 8, val: 106 }, code { op: 0, bits: 8, val: 42 }, code { op: 0, bits: 9, val: 180 }, code { op: 0, bits: 8, val: 10 }, code { op: 0, bits: 8, val: 138 }, code { op: 0, bits: 8, val: 74 }, code { op: 0, bits: 9, val: 244 }, code { op: 16, bits: 7, val: 5 }, code { op: 0, bits: 8, val: 86 }, code { op: 0, bits: 8, val: 22 }, code { op: 64, bits: 8, val: 0 }, code { op: 19, bits: 7, val: 51 }, code { op: 0, bits: 8, val: 118 }, code { op: 0, bits: 8, val: 54 }, code { op: 0, bits: 9, val: 204 }, code { op: 17, bits: 7, val: 15 }, code { op: 0, bits: 8, val: 102 }, code { op: 0, bits: 8, val: 38 }, code { op: 0, bits: 9, val: 172 }, code { op: 0, bits: 8, val: 6 }, code { op: 0, bits: 8, val: 134 }, code { op: 0, bits: 8, val: 70 }, code { op: 0, bits: 9, val: 236 }, code { op: 16, bits: 7, val: 9 }, code { op: 0, bits: 8, val: 94 }, code { op: 0, bits: 8, val: 30 }, code { op: 0, bits: 9, val: 156 }, code { op: 20, bits: 7, val: 99 }, code { op: 0, bits: 8, val: 126 }, code { op: 0, bits: 8, val: 62 }, code { op: 0, bits: 9, val: 220 }, code { op: 18, bits: 7, val: 27 }, code { op: 0, bits: 8, val: 110 }, code { op: 0, bits: 8, val: 46 }, code { op: 0, bits: 9, val: 188 }, code { op: 0, bits: 8, val: 14 }, code { op: 0, bits: 8, val: 142 }, code { op: 0, bits: 8, val: 78 }, code { op: 0, bits: 9, val: 252 }, code { op: 96, bits: 7, val: 0 }, code { op: 0, bits: 8, val: 81 }, code { op: 0, bits: 8, val: 17 }, code { op: 21, bits: 8, val: 131 }, code { op: 18, bits: 7, val: 31 }, code { op: 0, bits: 8, val: 113 }, code { op: 0, bits: 8, val: 49 }, code { op: 0, bits: 9, val: 194 }, code { op: 16, bits: 7, val: 10 }, code { op: 0, bits: 8, val: 97 }, code { op: 0, bits: 8, val: 33 }, code { op: 0, bits: 9, val: 162 }, code { op: 0, bits: 8, val: 1 }, code { op: 0, bits: 8, val: 129 }, code { op: 0, bits: 8, val: 65 }, code { op: 0, bits: 9, val: 226 }, code { op: 16, bits: 7, val: 6 }, code { op: 0, bits: 8, val: 89 }, code { op: 0, bits: 8, val: 25 }, code { op: 0, bits: 9, val: 146 }, code { op: 19, bits: 7, val: 59 }, code { op: 0, bits: 8, val: 121 }, code { op: 0, bits: 8, val: 57 }, code { op: 0, bits: 9, val: 210 }, code { op: 17, bits: 7, val: 17 }, code { op: 0, bits: 8, val: 105 }, code { op: 0, bits: 8, val: 41 }, code { op: 0, bits: 9, val: 178 }, code { op: 0, bits: 8, val: 9 }, code { op: 0, bits: 8, val: 137 }, code { op: 0, bits: 8, val: 73 }, code { op: 0, bits: 9, val: 242 }, code { op: 16, bits: 7, val: 4 }, code { op: 0, bits: 8, val: 85 }, code { op: 0, bits: 8, val: 21 }, code { op: 16, bits: 8, val: 258 }, code { op: 19, bits: 7, val: 43 }, code { op: 0, bits: 8, val: 117 }, code { op: 0, bits: 8, val: 53 }, code { op: 0, bits: 9, val: 202 }, code { op: 17, bits: 7, val: 13 }, code { op: 0, bits: 8, val: 101 }, code { op: 0, bits: 8, val: 37 }, code { op: 0, bits: 9, val: 170 }, code { op: 0, bits: 8, val: 5 }, code { op: 0, bits: 8, val: 133 }, code { op: 0, bits: 8, val: 69 }, code { op: 0, bits: 9, val: 234 }, code { op: 16, bits: 7, val: 8 }, code { op: 0, bits: 8, val: 93 }, code { op: 0, bits: 8, val: 29 }, code { op: 0, bits: 9, val: 154 }, code { op: 20, bits: 7, val: 83 }, code { op: 0, bits: 8, val: 125 }, code { op: 0, bits: 8, val: 61 }, code { op: 0, bits: 9, val: 218 }, code { op: 18, bits: 7, val: 23 }, code { op: 0, bits: 8, val: 109 }, code { op: 0, bits: 8, val: 45 }, code { op: 0, bits: 9, val: 186 }, code { op: 0, bits: 8, val: 13 }, code { op: 0, bits: 8, val: 141 }, code { op: 0, bits: 8, val: 77 }, code { op: 0, bits: 9, val: 250 }, code { op: 16, bits: 7, val: 3 }, code { op: 0, bits: 8, val: 83 }, code { op: 0, bits: 8, val: 19 }, code { op: 21, bits: 8, val: 195 }, code { op: 19, bits: 7, val: 35 }, code { op: 0, bits: 8, val: 115 }, code { op: 0, bits: 8, val: 51 }, code { op: 0, bits: 9, val: 198 }, code { op: 17, bits: 7, val: 11 }, code { op: 0, bits: 8, val: 99 }, code { op: 0, bits: 8, val: 35 }, code { op: 0, bits: 9, val: 166 }, code { op: 0, bits: 8, val: 3 }, code { op: 0, bits: 8, val: 131 }, code { op: 0, bits: 8, val: 67 }, code { op: 0, bits: 9, val: 230 }, code { op: 16, bits: 7, val: 7 }, code { op: 0, bits: 8, val: 91 }, code { op: 0, bits: 8, val: 27 }, code { op: 0, bits: 9, val: 150 }, code { op: 20, bits: 7, val: 67 }, code { op: 0, bits: 8, val: 123 }, code { op: 0, bits: 8, val: 59 }, code { op: 0, bits: 9, val: 214 }, code { op: 18, bits: 7, val: 19 }, code { op: 0, bits: 8, val: 107 }, code { op: 0, bits: 8, val: 43 }, code { op: 0, bits: 9, val: 182 }, code { op: 0, bits: 8, val: 11 }, code { op: 0, bits: 8, val: 139 }, code { op: 0, bits: 8, val: 75 }, code { op: 0, bits: 9, val: 246 }, code { op: 16, bits: 7, val: 5 }, code { op: 0, bits: 8, val: 87 }, code { op: 0, bits: 8, val: 23 }, code { op: 64, bits: 8, val: 0 }, code { op: 19, bits: 7, val: 51 }, code { op: 0, bits: 8, val: 119 }, code { op: 0, bits: 8, val: 55 }, code { op: 0, bits: 9, val: 206 }, code { op: 17, bits: 7, val: 15 }, code { op: 0, bits: 8, val: 103 }, code { op: 0, bits: 8, val: 39 }, code { op: 0, bits: 9, val: 174 }, code { op: 0, bits: 8, val: 7 }, code { op: 0, bits: 8, val: 135 }, code { op: 0, bits: 8, val: 71 }, code { op: 0, bits: 9, val: 238 }, code { op: 16, bits: 7, val: 9 }, code { op: 0, bits: 8, val: 95 }, code { op: 0, bits: 8, val: 31 }, code { op: 0, bits: 9, val: 158 }, code { op: 20, bits: 7, val: 99 }, code { op: 0, bits: 8, val: 127 }, code { op: 0, bits: 8, val: 63 }, code { op: 0, bits: 9, val: 222 }, code { op: 18, bits: 7, val: 27 }, code { op: 0, bits: 8, val: 111 }, code { op: 0, bits: 8, val: 47 }, code { op: 0, bits: 9, val: 190 }, code { op: 0, bits: 8, val: 15 }, code { op: 0, bits: 8, val: 143 }, code { op: 0, bits: 8, val: 79 }, code { op: 0, bits: 9, val: 254 }, code { op: 96, bits: 7, val: 0 }, code { op: 0, bits: 8, val: 80 }, code { op: 0, bits: 8, val: 16 }, code { op: 20, bits: 8, val: 115 }, code { op: 18, bits: 7, val: 31 }, code { op: 0, bits: 8, val: 112 }, code { op: 0, bits: 8, val: 48 }, code { op: 0, bits: 9, val: 193 }, code { op: 16, bits: 7, val: 10 }, code { op: 0, bits: 8, val: 96 }, code { op: 0, bits: 8, val: 32 }, code { op: 0, bits: 9, val: 161 }, code { op: 0, bits: 8, val: 0 }, code { op: 0, bits: 8, val: 128 }, code { op: 0, bits: 8, val: 64 }, code { op: 0, bits: 9, val: 225 }, code { op: 16, bits: 7, val: 6 }, code { op: 0, bits: 8, val: 88 }, code { op: 0, bits: 8, val: 24 }, code { op: 0, bits: 9, val: 145 }, code { op: 19, bits: 7, val: 59 }, code { op: 0, bits: 8, val: 120 }, code { op: 0, bits: 8, val: 56 }, code { op: 0, bits: 9, val: 209 }, code { op: 17, bits: 7, val: 17 }, code { op: 0, bits: 8, val: 104 }, code { op: 0, bits: 8, val: 40 }, code { op: 0, bits: 9, val: 177 }, code { op: 0, bits: 8, val: 8 }, code { op: 0, bits: 8, val: 136 }, code { op: 0, bits: 8, val: 72 }, code { op: 0, bits: 9, val: 241 }, code { op: 16, bits: 7, val: 4 }, code { op: 0, bits: 8, val: 84 }, code { op: 0, bits: 8, val: 20 }, code { op: 21, bits: 8, val: 227 }, code { op: 19, bits: 7, val: 43 }, code { op: 0, bits: 8, val: 116 }, code { op: 0, bits: 8, val: 52 }, code { op: 0, bits: 9, val: 201 }, code { op: 17, bits: 7, val: 13 }, code { op: 0, bits: 8, val: 100 }, code { op: 0, bits: 8, val: 36 }, code { op: 0, bits: 9, val: 169 }, code { op: 0, bits: 8, val: 4 }, code { op: 0, bits: 8, val: 132 }, code { op: 0, bits: 8, val: 68 }, code { op: 0, bits: 9, val: 233 }, code { op: 16, bits: 7, val: 8 }, code { op: 0, bits: 8, val: 92 }, code { op: 0, bits: 8, val: 28 }, code { op: 0, bits: 9, val: 153 }, code { op: 20, bits: 7, val: 83 }, code { op: 0, bits: 8, val: 124 }, code { op: 0, bits: 8, val: 60 }, code { op: 0, bits: 9, val: 217 }, code { op: 18, bits: 7, val: 23 }, code { op: 0, bits: 8, val: 108 }, code { op: 0, bits: 8, val: 44 }, code { op: 0, bits: 9, val: 185 }, code { op: 0, bits: 8, val: 12 }, code { op: 0, bits: 8, val: 140 }, code { op: 0, bits: 8, val: 76 }, code { op: 0, bits: 9, val: 249 }, code { op: 16, bits: 7, val: 3 }, code { op: 0, bits: 8, val: 82 }, code { op: 0, bits: 8, val: 18 }, code { op: 21, bits: 8, val: 163 }, code { op: 19, bits: 7, val: 35 }, code { op: 0, bits: 8, val: 114 }, code { op: 0, bits: 8, val: 50 }, code { op: 0, bits: 9, val: 197 }, code { op: 17, bits: 7, val: 11 }, code { op: 0, bits: 8, val: 98 }, code { op: 0, bits: 8, val: 34 }, code { op: 0, bits: 9, val: 165 }, code { op: 0, bits: 8, val: 2 }, code { op: 0, bits: 8, val: 130 }, code { op: 0, bits: 8, val: 66 }, code { op: 0, bits: 9, val: 229 }, code { op: 16, bits: 7, val: 7 }, code { op: 0, bits: 8, val: 90 }, code { op: 0, bits: 8, val: 26 }, code { op: 0, bits: 9, val: 149 }, code { op: 20, bits: 7, val: 67 }, code { op: 0, bits: 8, val: 122 }, code { op: 0, bits: 8, val: 58 }, code { op: 0, bits: 9, val: 213 }, code { op: 18, bits: 7, val: 19 }, code { op: 0, bits: 8, val: 106 }, code { op: 0, bits: 8, val: 42 }, code { op: 0, bits: 9, val: 181 }, code { op: 0, bits: 8, val: 10 }, code { op: 0, bits: 8, val: 138 }, code { op: 0, bits: 8, val: 74 }, code { op: 0, bits: 9, val: 245 }, code { op: 16, bits: 7, val: 5 }, code { op: 0, bits: 8, val: 86 }, code { op: 0, bits: 8, val: 22 }, code { op: 64, bits: 8, val: 0 }, code { op: 19, bits: 7, val: 51 }, code { op: 0, bits: 8, val: 118 }, code { op: 0, bits: 8, val: 54 }, code { op: 0, bits: 9, val: 205 }, code { op: 17, bits: 7, val: 15 }, code { op: 0, bits: 8, val: 102 }, code { op: 0, bits: 8, val: 38 }, code { op: 0, bits: 9, val: 173 }, code { op: 0, bits: 8, val: 6 }, code { op: 0, bits: 8, val: 134 }, code { op: 0, bits: 8, val: 70 }, code { op: 0, bits: 9, val: 237 }, code { op: 16, bits: 7, val: 9 }, code { op: 0, bits: 8, val: 94 }, code { op: 0, bits: 8, val: 30 }, code { op: 0, bits: 9, val: 157 }, code { op: 20, bits: 7, val: 99 }, code { op: 0, bits: 8, val: 126 }, code { op: 0, bits: 8, val: 62 }, code { op: 0, bits: 9, val: 221 }, code { op: 18, bits: 7, val: 27 }, code { op: 0, bits: 8, val: 110 }, code { op: 0, bits: 8, val: 46 }, code { op: 0, bits: 9, val: 189 }, code { op: 0, bits: 8, val: 14 }, code { op: 0, bits: 8, val: 142 }, code { op: 0, bits: 8, val: 78 }, code { op: 0, bits: 9, val: 253 }, code { op: 96, bits: 7, val: 0 }, code { op: 0, bits: 8, val: 81 }, code { op: 0, bits: 8, val: 17 }, code { op: 21, bits: 8, val: 131 }, code { op: 18, bits: 7, val: 31 }, code { op: 0, bits: 8, val: 113 }, code { op: 0, bits: 8, val: 49 }, code { op: 0, bits: 9, val: 195 }, code { op: 16, bits: 7, val: 10 }, code { op: 0, bits: 8, val: 97 }, code { op: 0, bits: 8, val: 33 }, code { op: 0, bits: 9, val: 163 }, code { op: 0, bits: 8, val: 1 }, code { op: 0, bits: 8, val: 129 }, code { op: 0, bits: 8, val: 65 }, code { op: 0, bits: 9, val: 227 }, code { op: 16, bits: 7, val: 6 }, code { op: 0, bits: 8, val: 89 }, code { op: 0, bits: 8, val: 25 }, code { op: 0, bits: 9, val: 147 }, code { op: 19, bits: 7, val: 59 }, code { op: 0, bits: 8, val: 121 }, code { op: 0, bits: 8, val: 57 }, code { op: 0, bits: 9, val: 211 }, code { op: 17, bits: 7, val: 17 }, code { op: 0, bits: 8, val: 105 }, code { op: 0, bits: 8, val: 41 }, code { op: 0, bits: 9, val: 179 }, code { op: 0, bits: 8, val: 9 }, code { op: 0, bits: 8, val: 137 }, code { op: 0, bits: 8, val: 73 }, code { op: 0, bits: 9, val: 243 }, code { op: 16, bits: 7, val: 4 }, code { op: 0, bits: 8, val: 85 }, code { op: 0, bits: 8, val: 21 }, code { op: 16, bits: 8, val: 258 }, code { op: 19, bits: 7, val: 43 }, code { op: 0, bits: 8, val: 117 }, code { op: 0, bits: 8, val: 53 }, code { op: 0, bits: 9, val: 203 }, code { op: 17, bits: 7, val: 13 }, code { op: 0, bits: 8, val: 101 }, code { op: 0, bits: 8, val: 37 }, code { op: 0, bits: 9, val: 171 }, code { op: 0, bits: 8, val: 5 }, code { op: 0, bits: 8, val: 133 }, code { op: 0, bits: 8, val: 69 }, code { op: 0, bits: 9, val: 235 }, code { op: 16, bits: 7, val: 8 }, code { op: 0, bits: 8, val: 93 }, code { op: 0, bits: 8, val: 29 }, code { op: 0, bits: 9, val: 155 }, code { op: 20, bits: 7, val: 83 }, code { op: 0, bits: 8, val: 125 }, code { op: 0, bits: 8, val: 61 }, code { op: 0, bits: 9, val: 219 }, code { op: 18, bits: 7, val: 23 }, code { op: 0, bits: 8, val: 109 }, code { op: 0, bits: 8, val: 45 }, code { op: 0, bits: 9, val: 187 }, code { op: 0, bits: 8, val: 13 }, code { op: 0, bits: 8, val: 141 }, code { op: 0, bits: 8, val: 77 }, code { op: 0, bits: 9, val: 251 }, code { op: 16, bits: 7, val: 3 }, code { op: 0, bits: 8, val: 83 }, code { op: 0, bits: 8, val: 19 }, code { op: 21, bits: 8, val: 195 }, code { op: 19, bits: 7, val: 35 }, code { op: 0, bits: 8, val: 115 }, code { op: 0, bits: 8, val: 51 }, code { op: 0, bits: 9, val: 199 }, code { op: 17, bits: 7, val: 11 }, code { op: 0, bits: 8, val: 99 }, code { op: 0, bits: 8, val: 35 }, code { op: 0, bits: 9, val: 167 }, code { op: 0, bits: 8, val: 3 }, code { op: 0, bits: 8, val: 131 }, code { op: 0, bits: 8, val: 67 }, code { op: 0, bits: 9, val: 231 }, code { op: 16, bits: 7, val: 7 }, code { op: 0, bits: 8, val: 91 }, code { op: 0, bits: 8, val: 27 }, code { op: 0, bits: 9, val: 151 }, code { op: 20, bits: 7, val: 67 }, code { op: 0, bits: 8, val: 123 }, code { op: 0, bits: 8, val: 59 }, code { op: 0, bits: 9, val: 215 }, code { op: 18, bits: 7, val: 19 }, code { op: 0, bits: 8, val: 107 }, code { op: 0, bits: 8, val: 43 }, code { op: 0, bits: 9, val: 183 }, code { op: 0, bits: 8, val: 11 }, code { op: 0, bits: 8, val: 139 }, code { op: 0, bits: 8, val: 75 }, code { op: 0, bits: 9, val: 247 }, code { op: 16, bits: 7, val: 5 }, code { op: 0, bits: 8, val: 87 }, code { op: 0, bits: 8, val: 23 }, code { op: 64, bits: 8, val: 0 }, code { op: 19, bits: 7, val: 51 }, code { op: 0, bits: 8, val: 119 }, code { op: 0, bits: 8, val: 55 }, code { op: 0, bits: 9, val: 207 }, code { op: 17, bits: 7, val: 15 }, code { op: 0, bits: 8, val: 103 }, code { op: 0, bits: 8, val: 39 }, code { op: 0, bits: 9, val: 175 }, code { op: 0, bits: 8, val: 7 }, code { op: 0, bits: 8, val: 135 }, code { op: 0, bits: 8, val: 71 }, code { op: 0, bits: 9, val: 239 }, code { op: 16, bits: 7, val: 9 }, code { op: 0, bits: 8, val: 95 }, code { op: 0, bits: 8, val: 31 }, code { op: 0, bits: 9, val: 159 }, code { op: 20, bits: 7, val: 99 }, code { op: 0, bits: 8, val: 127 }, code { op: 0, bits: 8, val: 63 }, code { op: 0, bits: 9, val: 223 }, code { op: 18, bits: 7, val: 27 }, code { op: 0, bits: 8, val: 111 }, code { op: 0, bits: 8, val: 47 }, code { op: 0, bits: 9, val: 191 }, code { op: 0, bits: 8, val: 15 }, code { op: 0, bits: 8, val: 143 }, code { op: 0, bits: 8, val: 79 }, code { op: 0, bits: 9, val: 255 }]
let distfix: [32]code = [code { op: 16, bits: 5, val: 1 }, code { op: 23, bits: 5, val: 257 }, code { op: 19, bits: 5, val: 17 }, code { op: 27, bits: 5, val: 4097 }, code { op: 17, bits: 5, val: 5 }, code { op: 25, bits: 5, val: 1025 }, code { op: 21, bits: 5, val: 65 }, code { op: 29, bits: 5, val: 16385 }, code { op: 16, bits: 5, val: 3 }, code { op: 24, bits: 5, val: 513 }, code { op: 20, bits: 5, val: 33 }, code { op: 28, bits: 5, val: 8193 }, code { op: 18, bits: 5, val: 9 }, code { op: 26, bits: 5, val: 2049 }, code { op: 22, bits: 5, val: 129 }, code { op: 64, bits: 5, val: 0 }, code { op: 16, bits: 5, val: 2 }, code { op: 23, bits: 5, val: 385 }, code { op: 19, bits: 5, val: 25 }, code { op: 27, bits: 5, val: 6145 }, code { op: 17, bits: 5, val: 7 }, code { op: 25, bits: 5, val: 1537 }, code { op: 21, bits: 5, val: 97 }, code { op: 29, bits: 5, val: 24577 }, code { op: 16, bits: 5, val: 4 }, code { op: 24, bits: 5, val: 769 }, code { op: 20, bits: 5, val: 49 }, code { op: 28, bits: 5, val: 12289 }, code { op: 18, bits: 5, val: 13 }, code { op: 26, bits: 5, val: 3073 }, code { op: 22, bits: 5, val: 193 }, code { op: 64, bits: 5, val: 0 }]
