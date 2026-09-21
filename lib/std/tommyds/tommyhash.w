// Migrated from C
use std.tommyds.defs

fn tommy_ilog2_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).clz() as c_int) ^ (31 as c_int))

}

fn tommy_ilog2_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).clz() as c_int) ^ (63 as c_int))

}

fn tommy_ctz_u32(__param_value: c_uint) -> c_uint {
    return (((__param_value as u32).ctz() as c_uint))

}

fn tommy_ctz_u64(__param_value: c_ulonglong) -> c_uint {
    return (((__param_value as u64).ctz() as c_uint))

}

fn tommy_roundup_pow2_u32(__param_value: c_uint) -> c_uint {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (1 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (2 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (4 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (8 as c_uint)) as c_uint))

    (__local_value = (__local_value as c_uint) | (((__local_value as c_uint) >> (16 as c_uint)) as c_uint))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: c_ulonglong) -> c_ulonglong {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (1 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (2 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (4 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (8 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (16 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value as c_ulonglong) | (((__local_value as c_ulonglong) >> (32 as c_uint)) as c_ulonglong))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: c_uint) -> c_int {
    return (if ((((((__param_value as c_uint) -% (16843009 as c_uint)) as c_uint) & ((~__param_value) as c_uint)) as c_uint) & ((2155905152 as c_uint) as c_uint)) != 0: 1 else: 0)

}

pub unsafe fn tommy_hash_u32(__param_init_val: c_uint, __param_void_key: *const c_void, __param_key_len: c_ulonglong) -> c_uint {
    var __local_key_len = __param_key_len
    var __local_key: *const u8 = ((__param_void_key as *const u8))

    var __local_a: c_uint

    var __local_b: c_uint

    var __local_c: c_uint


    (__local_c = (((((((3735928559 as c_uint) as c_uint) +% ((__local_key_len as c_uint) as c_uint)) as c_uint) +% (__param_init_val as c_uint)) as c_uint)))

    (__local_b = __local_c)

    (__local_a = __local_b)


    while ((if __local_key_len > 12: 1 else: 0) != 0) {
        (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

        (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

        (__local_c = (__local_c +% tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void))))

        loop {
            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as c_uint) ^ (((((__local_c as c_uint) << (4 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 4) as c_uint)) as c_uint)) as c_uint))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as c_uint) ^ (((((__local_a as c_uint) << (6 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 6) as c_uint)) as c_uint)) as c_uint))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as c_uint) ^ (((((__local_b as c_uint) << (8 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 8) as c_uint)) as c_uint)) as c_uint))

            (__local_b = (__local_b +% __local_a))

            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as c_uint) ^ (((((__local_c as c_uint) << (16 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 16) as c_uint)) as c_uint)) as c_uint))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as c_uint) ^ (((((__local_a as c_uint) << (19 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 19) as c_uint)) as c_uint)) as c_uint))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as c_uint) ^ (((((__local_b as c_uint) << (4 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 4) as c_uint)) as c_uint)) as c_uint))

            (__local_b = (__local_b +% __local_a))

            if not ((0 != 0)) {
                break
            }
        }

        (__local_key_len = (__local_key_len -% 12))

        (__local_key = __local_key + ((12 as isize) as usize))

    }

    while true {
        match __local_key_len {
            0 => {
                return __local_c
            },
            12 => {
                (__local_c = (__local_c +% tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void))))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            11 => {
                (__local_c = (__local_c +% ((((__local_key[10]) as c_uint) as c_uint) << (16 as c_uint))))

                (__local_c = (__local_c +% ((((__local_key[9]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_c = (__local_c +% ((__local_key[8]) as c_int)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))




            },
            10 => {
                (__local_c = (__local_c +% ((((__local_key[9]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_c = (__local_c +% ((__local_key[8]) as c_int)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            9 => {
                (__local_c = (__local_c +% ((__local_key[8]) as c_int)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            8 => {
                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            7 => {
                (__local_b = (__local_b +% ((((__local_key[6]) as c_uint) as c_uint) << (16 as c_uint))))

                (__local_b = (__local_b +% ((((__local_key[5]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_b = (__local_b +% ((__local_key[4]) as c_int)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            6 => {
                (__local_b = (__local_b +% ((((__local_key[5]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_b = (__local_b +% ((__local_key[4]) as c_int)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            5 => {
                (__local_b = (__local_b +% ((__local_key[4]) as c_int)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            4 => {
                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))
            },
            3 => {
                (__local_a = (__local_a +% ((((__local_key[2]) as c_uint) as c_uint) << (16 as c_uint))))

                (__local_a = (__local_a +% ((((__local_key[1]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_a = (__local_a +% ((__local_key[0]) as c_int)))


            },
            2 => {
                (__local_a = (__local_a +% ((((__local_key[1]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_a = (__local_a +% ((__local_key[0]) as c_int)))

            },
            1 => {
                (__local_a = (__local_a +% ((__local_key[0]) as c_int)))
            },
        }

        break

    }

    loop {
        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (14 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 14) as c_uint)) as c_uint))))

        (__local_a = (__local_a as c_uint) ^ (__local_c as c_uint))

        (__local_a = (__local_a -% ((((__local_c as c_uint) << (11 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 11) as c_uint)) as c_uint))))

        (__local_b = (__local_b as c_uint) ^ (__local_a as c_uint))

        (__local_b = (__local_b -% ((((__local_a as c_uint) << (25 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 25) as c_uint)) as c_uint))))

        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (16 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 16) as c_uint)) as c_uint))))

        (__local_a = (__local_a as c_uint) ^ (__local_c as c_uint))

        (__local_a = (__local_a -% ((((__local_c as c_uint) << (4 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 4) as c_uint)) as c_uint))))

        (__local_b = (__local_b as c_uint) ^ (__local_a as c_uint))

        (__local_b = (__local_b -% ((((__local_a as c_uint) << (14 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 14) as c_uint)) as c_uint))))

        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (24 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 24) as c_uint)) as c_uint))))

        if not ((0 != 0)) {
            break
        }
    }

    return __local_c

}

pub unsafe fn tommy_hash_u64(__param_init_val: c_ulonglong, __param_void_key: *const c_void, __param_key_len: c_ulonglong) -> c_ulonglong {
    var __local_key_len = __param_key_len
    var __local_key: *const u8 = ((__param_void_key as *const u8))

    var __local_a: c_uint

    var __local_b: c_uint

    var __local_c: c_uint


    (__local_c = (((((((3735928559 as c_uint) as c_uint) +% ((__local_key_len as c_uint) as c_uint)) as c_ulonglong) +% (((__param_init_val as c_ulonglong) & ((4294967295 as c_ulonglong) as c_ulonglong)) as c_ulonglong)) as c_uint)))

    (__local_b = __local_c)

    (__local_a = __local_b)


    (__local_c = (__local_c +% (((__param_init_val as c_ulonglong) >> (32 as c_uint)) as c_uint)))

    while ((if __local_key_len > 12: 1 else: 0) != 0) {
        (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

        (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

        (__local_c = (__local_c +% tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void))))

        loop {
            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as c_uint) ^ (((((__local_c as c_uint) << (4 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 4) as c_uint)) as c_uint)) as c_uint))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as c_uint) ^ (((((__local_a as c_uint) << (6 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 6) as c_uint)) as c_uint)) as c_uint))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as c_uint) ^ (((((__local_b as c_uint) << (8 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 8) as c_uint)) as c_uint)) as c_uint))

            (__local_b = (__local_b +% __local_a))

            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as c_uint) ^ (((((__local_c as c_uint) << (16 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 16) as c_uint)) as c_uint)) as c_uint))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as c_uint) ^ (((((__local_a as c_uint) << (19 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 19) as c_uint)) as c_uint)) as c_uint))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as c_uint) ^ (((((__local_b as c_uint) << (4 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 4) as c_uint)) as c_uint)) as c_uint))

            (__local_b = (__local_b +% __local_a))

            if not ((0 != 0)) {
                break
            }
        }

        (__local_key_len = (__local_key_len -% 12))

        (__local_key = __local_key + ((12 as isize) as usize))

    }

    while true {
        match __local_key_len {
            0 => {
                return ((__local_c as c_ulonglong) +% ((((__local_b as c_ulonglong) as c_ulonglong) << (32 as c_uint)) as c_ulonglong))
            },
            12 => {
                (__local_c = (__local_c +% tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void))))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            11 => {
                (__local_c = (__local_c +% ((((__local_key[10]) as c_uint) as c_uint) << (16 as c_uint))))

                (__local_c = (__local_c +% ((((__local_key[9]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_c = (__local_c +% ((__local_key[8]) as c_int)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))




            },
            10 => {
                (__local_c = (__local_c +% ((((__local_key[9]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_c = (__local_c +% ((__local_key[8]) as c_int)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            9 => {
                (__local_c = (__local_c +% ((__local_key[8]) as c_int)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            8 => {
                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            7 => {
                (__local_b = (__local_b +% ((((__local_key[6]) as c_uint) as c_uint) << (16 as c_uint))))

                (__local_b = (__local_b +% ((((__local_key[5]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_b = (__local_b +% ((__local_key[4]) as c_int)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            6 => {
                (__local_b = (__local_b +% ((((__local_key[5]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_b = (__local_b +% ((__local_key[4]) as c_int)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            5 => {
                (__local_b = (__local_b +% ((__local_key[4]) as c_int)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            4 => {
                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))
            },
            3 => {
                (__local_a = (__local_a +% ((((__local_key[2]) as c_uint) as c_uint) << (16 as c_uint))))

                (__local_a = (__local_a +% ((((__local_key[1]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_a = (__local_a +% ((__local_key[0]) as c_int)))


            },
            2 => {
                (__local_a = (__local_a +% ((((__local_key[1]) as c_uint) as c_uint) << (8 as c_uint))))

                (__local_a = (__local_a +% ((__local_key[0]) as c_int)))

            },
            1 => {
                (__local_a = (__local_a +% ((__local_key[0]) as c_int)))
            },
        }

        break

    }

    loop {
        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (14 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 14) as c_uint)) as c_uint))))

        (__local_a = (__local_a as c_uint) ^ (__local_c as c_uint))

        (__local_a = (__local_a -% ((((__local_c as c_uint) << (11 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 11) as c_uint)) as c_uint))))

        (__local_b = (__local_b as c_uint) ^ (__local_a as c_uint))

        (__local_b = (__local_b -% ((((__local_a as c_uint) << (25 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 25) as c_uint)) as c_uint))))

        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (16 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 16) as c_uint)) as c_uint))))

        (__local_a = (__local_a as c_uint) ^ (__local_c as c_uint))

        (__local_a = (__local_a -% ((((__local_c as c_uint) << (4 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 4) as c_uint)) as c_uint))))

        (__local_b = (__local_b as c_uint) ^ (__local_a as c_uint))

        (__local_b = (__local_b -% ((((__local_a as c_uint) << (14 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 14) as c_uint)) as c_uint))))

        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (24 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 24) as c_uint)) as c_uint))))

        if not ((0 != 0)) {
            break
        }
    }

    return ((__local_c as c_ulonglong) +% ((((__local_b as c_ulonglong) as c_ulonglong) << (32 as c_uint)) as c_ulonglong))

}

pub unsafe fn tommy_strhash_u32(__param_init_val: c_uint, __param_void_key: *const c_void) -> c_uint {
    var __local_key: *const u8 = ((__param_void_key as *const u8))

    var __local_a: c_uint

    var __local_b: c_uint

    var __local_c: c_uint


    var __local_m: [3]c_uint = [(255 as c_uint), (65280 as c_uint), (16711680 as c_uint)]

    (__local_c = (((((3735928559 as c_uint) as c_uint) +% (__param_init_val as c_uint)) as c_uint)))

    (__local_b = __local_c)

    (__local_a = __local_b)


    while (1 != 0) {
        var __local_v: c_uint = ((tommy_le_uint32_read((__local_key as *const c_void)) as c_uint))

        if (tommy_haszero_u32(__local_v) != 0) {
            if (((__local_v as c_uint) & (__local_m[0] as c_uint)) != 0) {
                (__local_a = (__local_a +% ((__local_v as c_uint) & (__local_m[0] as c_uint))))

                if (((__local_v as c_uint) & (__local_m[1] as c_uint)) != 0) {
                    (__local_a = (__local_a +% ((__local_v as c_uint) & (__local_m[1] as c_uint))))

                    if (((__local_v as c_uint) & (__local_m[2] as c_uint)) != 0) {
                        (__local_a = (__local_a +% ((__local_v as c_uint) & (__local_m[2] as c_uint))))
                    }

                }

            }

            break

        }

        (__local_a = (__local_a +% __local_v))

        (__local_v = ((tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void)) as c_uint)))

        if (tommy_haszero_u32(__local_v) != 0) {
            if (((__local_v as c_uint) & (__local_m[0] as c_uint)) != 0) {
                (__local_b = (__local_b +% ((__local_v as c_uint) & (__local_m[0] as c_uint))))

                if (((__local_v as c_uint) & (__local_m[1] as c_uint)) != 0) {
                    (__local_b = (__local_b +% ((__local_v as c_uint) & (__local_m[1] as c_uint))))

                    if (((__local_v as c_uint) & (__local_m[2] as c_uint)) != 0) {
                        (__local_b = (__local_b +% ((__local_v as c_uint) & (__local_m[2] as c_uint))))
                    }

                }

            }

            break

        }

        (__local_b = (__local_b +% __local_v))

        (__local_v = ((tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void)) as c_uint)))

        if (tommy_haszero_u32(__local_v) != 0) {
            if (((__local_v as c_uint) & (__local_m[0] as c_uint)) != 0) {
                (__local_c = (__local_c +% ((__local_v as c_uint) & (__local_m[0] as c_uint))))

                if (((__local_v as c_uint) & (__local_m[1] as c_uint)) != 0) {
                    (__local_c = (__local_c +% ((__local_v as c_uint) & (__local_m[1] as c_uint))))

                    if (((__local_v as c_uint) & (__local_m[2] as c_uint)) != 0) {
                        (__local_c = (__local_c +% ((__local_v as c_uint) & (__local_m[2] as c_uint))))
                    }

                }

            }

            break

        }

        (__local_c = (__local_c +% __local_v))

        loop {
            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as c_uint) ^ (((((__local_c as c_uint) << (4 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 4) as c_uint)) as c_uint)) as c_uint))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as c_uint) ^ (((((__local_a as c_uint) << (6 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 6) as c_uint)) as c_uint)) as c_uint))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as c_uint) ^ (((((__local_b as c_uint) << (8 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 8) as c_uint)) as c_uint)) as c_uint))

            (__local_b = (__local_b +% __local_a))

            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as c_uint) ^ (((((__local_c as c_uint) << (16 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 16) as c_uint)) as c_uint)) as c_uint))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as c_uint) ^ (((((__local_a as c_uint) << (19 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 19) as c_uint)) as c_uint)) as c_uint))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as c_uint) ^ (((((__local_b as c_uint) << (4 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 4) as c_uint)) as c_uint)) as c_uint))

            (__local_b = (__local_b +% __local_a))

            if not ((0 != 0)) {
                break
            }
        }

        (__local_key = __local_key + ((12 as isize) as usize))

    }

    loop {
        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (14 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 14) as c_uint)) as c_uint))))

        (__local_a = (__local_a as c_uint) ^ (__local_c as c_uint))

        (__local_a = (__local_a -% ((((__local_c as c_uint) << (11 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 11) as c_uint)) as c_uint))))

        (__local_b = (__local_b as c_uint) ^ (__local_a as c_uint))

        (__local_b = (__local_b -% ((((__local_a as c_uint) << (25 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 25) as c_uint)) as c_uint))))

        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (16 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 16) as c_uint)) as c_uint))))

        (__local_a = (__local_a as c_uint) ^ (__local_c as c_uint))

        (__local_a = (__local_a -% ((((__local_c as c_uint) << (4 as c_uint)) as c_uint) | (((__local_c as c_uint) >> ((32 - 4) as c_uint)) as c_uint))))

        (__local_b = (__local_b as c_uint) ^ (__local_a as c_uint))

        (__local_b = (__local_b -% ((((__local_a as c_uint) << (14 as c_uint)) as c_uint) | (((__local_a as c_uint) >> ((32 - 14) as c_uint)) as c_uint))))

        (__local_c = (__local_c as c_uint) ^ (__local_b as c_uint))

        (__local_c = (__local_c -% ((((__local_b as c_uint) << (24 as c_uint)) as c_uint) | (((__local_b as c_uint) >> ((32 - 24) as c_uint)) as c_uint))))

        if not ((0 != 0)) {
            break
        }
    }

    return __local_c

}

pub fn tommy_inthash_u32(__param_key: c_uint) -> c_uint {
    var __local_key = __param_key
    (__local_key = (__local_key -% ((__local_key as c_uint) << (6 as c_uint))))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) >> (17 as c_uint)) as c_uint))

    (__local_key = (__local_key -% ((__local_key as c_uint) << (9 as c_uint))))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) << (4 as c_uint)) as c_uint))

    (__local_key = (__local_key -% ((__local_key as c_uint) << (3 as c_uint))))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) << (10 as c_uint)) as c_uint))

    (__local_key = (__local_key as c_uint) ^ (((__local_key as c_uint) >> (15 as c_uint)) as c_uint))

    return __local_key

}

pub fn tommy_inthash_u64(__param_key: c_ulonglong) -> c_ulonglong {
    var __local_key = __param_key
    (__local_key = (((((~__local_key) as c_ulonglong) +% (((__local_key as c_ulonglong) << (21 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) ^ (((__local_key as c_ulonglong) >> (24 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((((__local_key as c_ulonglong) +% (((__local_key as c_ulonglong) << (3 as c_uint)) as c_ulonglong)) as c_ulonglong) +% (((__local_key as c_ulonglong) << (8 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) ^ (((__local_key as c_ulonglong) >> (14 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((((__local_key as c_ulonglong) +% (((__local_key as c_ulonglong) << (2 as c_uint)) as c_ulonglong)) as c_ulonglong) +% (((__local_key as c_ulonglong) << (4 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) ^ (((__local_key as c_ulonglong) >> (28 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    (__local_key = ((((__local_key as c_ulonglong) +% (((__local_key as c_ulonglong) << (31 as c_uint)) as c_ulonglong)) as c_ulonglong)))

    return __local_key

}

unsafe fn tommy_le_uint32_read(__param_ptr: *const c_void) -> c_uint {
    var __local_v: c_uint

    with_memcpy((((&raw mut __local_v as *mut c_uint) as *mut c_void) as *mut u8), (__param_ptr as *const u8), ((sizeof[c_uint]() as c_ulong) as i64))

    return __local_v

}
