// Migrated from C
use std.engines.tommyds.defs
use std.collections

fn tommy_ilog2_u32(__param_value: u32) -> u32 {
    return (((((__param_value as u32).clz() as i32) ^ (31 as i32)) as u32))

}

fn tommy_ilog2_u64(__param_value: u64) -> u32 {
    return (((((__param_value as u64).clz() as i32) ^ (63 as i32)) as u32))

}

fn tommy_ctz_u32(__param_value: u32) -> u32 {
    return (((__param_value as u32).ctz() as u32))

}

fn tommy_ctz_u64(__param_value: u64) -> u32 {
    return (((__param_value as u64).ctz() as u32))

}

fn tommy_roundup_pow2_u32(__param_value: u32) -> u32 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (1 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (2 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (4 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (8 as u32)) as u32))

    (__local_value = (__local_value as u32) | (((__local_value as u32) >> (16 as u32)) as u32))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_roundup_pow2_u64(__param_value: u64) -> u64 {
    var __local_value = __param_value
    (__local_value = (__local_value -% 1))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (1 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (2 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (4 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (8 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (16 as u32)) as u64))

    (__local_value = (__local_value as u64) | (((__local_value as u64) >> (32 as u32)) as u64))

    (__local_value = (__local_value +% 1))

    return __local_value

}

fn tommy_haszero_u32(__param_value: u32) -> i32 {
    return (if ((((((__param_value as u32) -% (16843009 as u32)) as u32) & ((~__param_value) as u32)) as u32) & (2155905152 as u32)) != 0: 1 else: 0)

}

// contract: unproved:1:read only
pub unsafe fn tommy_hash_u32(__param_init_val: u32, __param_void_key: *const c_void, __param_key_len: u64) -> u32 {
    var __local_key_len = __param_key_len
    var __local_key: *const u8 = ((__param_void_key as *const u8))

    var __local_a: u32

    var __local_b: u32

    var __local_c: u32


    (__local_c = ((((((3735928559 as u32) +% (__local_key_len as u32)) as u32) +% (__param_init_val as u32)) as u32)))

    (__local_b = __local_c)

    (__local_a = __local_b)


    while (__local_key_len > 12) {
        (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

        (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

        (__local_c = (__local_c +% tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void))))

        loop {
            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as u32) ^ (((((__local_c as u32) << (4 as u32)) as u32) | (((__local_c as u32) >> ((32 - 4) as u32)) as u32)) as u32))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as u32) ^ (((((__local_a as u32) << (6 as u32)) as u32) | (((__local_a as u32) >> ((32 - 6) as u32)) as u32)) as u32))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as u32) ^ (((((__local_b as u32) << (8 as u32)) as u32) | (((__local_b as u32) >> ((32 - 8) as u32)) as u32)) as u32))

            (__local_b = (__local_b +% __local_a))

            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as u32) ^ (((((__local_c as u32) << (16 as u32)) as u32) | (((__local_c as u32) >> ((32 - 16) as u32)) as u32)) as u32))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as u32) ^ (((((__local_a as u32) << (19 as u32)) as u32) | (((__local_a as u32) >> ((32 - 19) as u32)) as u32)) as u32))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as u32) ^ (((((__local_b as u32) << (4 as u32)) as u32) | (((__local_b as u32) >> ((32 - 4) as u32)) as u32)) as u32))

            (__local_b = (__local_b +% __local_a))

            if not (false) {
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
                (__local_c = (__local_c +% (((__local_key[10]) as u32) << (16 as u32))))

                (__local_c = (__local_c +% (((__local_key[9]) as u32) << (8 as u32))))

                (__local_c = (__local_c +% ((__local_key[8]) as u32)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))




            },
            10 => {
                (__local_c = (__local_c +% (((__local_key[9]) as u32) << (8 as u32))))

                (__local_c = (__local_c +% ((__local_key[8]) as u32)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            9 => {
                (__local_c = (__local_c +% ((__local_key[8]) as u32)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            8 => {
                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            7 => {
                (__local_b = (__local_b +% (((__local_key[6]) as u32) << (16 as u32))))

                (__local_b = (__local_b +% (((__local_key[5]) as u32) << (8 as u32))))

                (__local_b = (__local_b +% ((__local_key[4]) as u32)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            6 => {
                (__local_b = (__local_b +% (((__local_key[5]) as u32) << (8 as u32))))

                (__local_b = (__local_b +% ((__local_key[4]) as u32)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            5 => {
                (__local_b = (__local_b +% ((__local_key[4]) as u32)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            4 => {
                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))
            },
            3 => {
                (__local_a = (__local_a +% (((__local_key[2]) as u32) << (16 as u32))))

                (__local_a = (__local_a +% (((__local_key[1]) as u32) << (8 as u32))))

                (__local_a = (__local_a +% ((__local_key[0]) as u32)))


            },
            2 => {
                (__local_a = (__local_a +% (((__local_key[1]) as u32) << (8 as u32))))

                (__local_a = (__local_a +% ((__local_key[0]) as u32)))

            },
            1 => {
                (__local_a = (__local_a +% ((__local_key[0]) as u32)))
            },
        }

        break

    }

    loop {
        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (14 as u32)) as u32) | (((__local_b as u32) >> ((32 - 14) as u32)) as u32))))

        (__local_a = (__local_a as u32) ^ (__local_c as u32))

        (__local_a = (__local_a -% ((((__local_c as u32) << (11 as u32)) as u32) | (((__local_c as u32) >> ((32 - 11) as u32)) as u32))))

        (__local_b = (__local_b as u32) ^ (__local_a as u32))

        (__local_b = (__local_b -% ((((__local_a as u32) << (25 as u32)) as u32) | (((__local_a as u32) >> ((32 - 25) as u32)) as u32))))

        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (16 as u32)) as u32) | (((__local_b as u32) >> ((32 - 16) as u32)) as u32))))

        (__local_a = (__local_a as u32) ^ (__local_c as u32))

        (__local_a = (__local_a -% ((((__local_c as u32) << (4 as u32)) as u32) | (((__local_c as u32) >> ((32 - 4) as u32)) as u32))))

        (__local_b = (__local_b as u32) ^ (__local_a as u32))

        (__local_b = (__local_b -% ((((__local_a as u32) << (14 as u32)) as u32) | (((__local_a as u32) >> ((32 - 14) as u32)) as u32))))

        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (24 as u32)) as u32) | (((__local_b as u32) >> ((32 - 24) as u32)) as u32))))

        if not (false) {
            break
        }
    }

    return __local_c

}

// contract: unproved:1:read only
pub unsafe fn tommy_hash_u64(__param_init_val: u64, __param_void_key: *const c_void, __param_key_len: u64) -> u64 {
    var __local_key_len = __param_key_len
    var __local_key: *const u8 = ((__param_void_key as *const u8))

    var __local_a: u32

    var __local_b: u32

    var __local_c: u32


    (__local_c = ((((((3735928559 as u32) +% (__local_key_len as u32)) as u64) +% (((__param_init_val as u64) & (4294967295 as u64)) as u64)) as u32)))

    (__local_b = __local_c)

    (__local_a = __local_b)


    (__local_c = (((__local_c +% (((__param_init_val as u64) >> (32 as u32)) as u32)) as u32)))

    while (__local_key_len > 12) {
        (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

        (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

        (__local_c = (__local_c +% tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void))))

        loop {
            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as u32) ^ (((((__local_c as u32) << (4 as u32)) as u32) | (((__local_c as u32) >> ((32 - 4) as u32)) as u32)) as u32))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as u32) ^ (((((__local_a as u32) << (6 as u32)) as u32) | (((__local_a as u32) >> ((32 - 6) as u32)) as u32)) as u32))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as u32) ^ (((((__local_b as u32) << (8 as u32)) as u32) | (((__local_b as u32) >> ((32 - 8) as u32)) as u32)) as u32))

            (__local_b = (__local_b +% __local_a))

            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as u32) ^ (((((__local_c as u32) << (16 as u32)) as u32) | (((__local_c as u32) >> ((32 - 16) as u32)) as u32)) as u32))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as u32) ^ (((((__local_a as u32) << (19 as u32)) as u32) | (((__local_a as u32) >> ((32 - 19) as u32)) as u32)) as u32))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as u32) ^ (((((__local_b as u32) << (4 as u32)) as u32) | (((__local_b as u32) >> ((32 - 4) as u32)) as u32)) as u32))

            (__local_b = (__local_b +% __local_a))

            if not (false) {
                break
            }
        }

        (__local_key_len = (__local_key_len -% 12))

        (__local_key = __local_key + ((12 as isize) as usize))

    }

    while true {
        match __local_key_len {
            0 => {
                return ((__local_c as u64) +% (((__local_b as u64) << (32 as u32)) as u64))
            },
            12 => {
                (__local_c = (__local_c +% tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void))))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            11 => {
                (__local_c = (__local_c +% (((__local_key[10]) as u32) << (16 as u32))))

                (__local_c = (__local_c +% (((__local_key[9]) as u32) << (8 as u32))))

                (__local_c = (__local_c +% ((__local_key[8]) as u32)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))




            },
            10 => {
                (__local_c = (__local_c +% (((__local_key[9]) as u32) << (8 as u32))))

                (__local_c = (__local_c +% ((__local_key[8]) as u32)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            9 => {
                (__local_c = (__local_c +% ((__local_key[8]) as u32)))

                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            8 => {
                (__local_b = (__local_b +% tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void))))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            7 => {
                (__local_b = (__local_b +% (((__local_key[6]) as u32) << (16 as u32))))

                (__local_b = (__local_b +% (((__local_key[5]) as u32) << (8 as u32))))

                (__local_b = (__local_b +% ((__local_key[4]) as u32)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))



            },
            6 => {
                (__local_b = (__local_b +% (((__local_key[5]) as u32) << (8 as u32))))

                (__local_b = (__local_b +% ((__local_key[4]) as u32)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))


            },
            5 => {
                (__local_b = (__local_b +% ((__local_key[4]) as u32)))

                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))

            },
            4 => {
                (__local_a = (__local_a +% tommy_le_uint32_read(((__local_key + ((0 as isize) as usize)) as *const c_void))))
            },
            3 => {
                (__local_a = (__local_a +% (((__local_key[2]) as u32) << (16 as u32))))

                (__local_a = (__local_a +% (((__local_key[1]) as u32) << (8 as u32))))

                (__local_a = (__local_a +% ((__local_key[0]) as u32)))


            },
            2 => {
                (__local_a = (__local_a +% (((__local_key[1]) as u32) << (8 as u32))))

                (__local_a = (__local_a +% ((__local_key[0]) as u32)))

            },
            1 => {
                (__local_a = (__local_a +% ((__local_key[0]) as u32)))
            },
        }

        break

    }

    loop {
        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (14 as u32)) as u32) | (((__local_b as u32) >> ((32 - 14) as u32)) as u32))))

        (__local_a = (__local_a as u32) ^ (__local_c as u32))

        (__local_a = (__local_a -% ((((__local_c as u32) << (11 as u32)) as u32) | (((__local_c as u32) >> ((32 - 11) as u32)) as u32))))

        (__local_b = (__local_b as u32) ^ (__local_a as u32))

        (__local_b = (__local_b -% ((((__local_a as u32) << (25 as u32)) as u32) | (((__local_a as u32) >> ((32 - 25) as u32)) as u32))))

        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (16 as u32)) as u32) | (((__local_b as u32) >> ((32 - 16) as u32)) as u32))))

        (__local_a = (__local_a as u32) ^ (__local_c as u32))

        (__local_a = (__local_a -% ((((__local_c as u32) << (4 as u32)) as u32) | (((__local_c as u32) >> ((32 - 4) as u32)) as u32))))

        (__local_b = (__local_b as u32) ^ (__local_a as u32))

        (__local_b = (__local_b -% ((((__local_a as u32) << (14 as u32)) as u32) | (((__local_a as u32) >> ((32 - 14) as u32)) as u32))))

        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (24 as u32)) as u32) | (((__local_b as u32) >> ((32 - 24) as u32)) as u32))))

        if not (false) {
            break
        }
    }

    return ((__local_c as u64) +% (((__local_b as u64) << (32 as u32)) as u64))

}

// contract: unproved:1:read only
pub unsafe fn tommy_strhash_u32(__param_init_val: u32, __param_void_key: *const c_void) -> u32 {
    var __local_key: *const u8 = ((__param_void_key as *const u8))

    var __local_a: u32

    var __local_b: u32

    var __local_c: u32


    var __local_m: List[u32] = [255, 65280, 16711680]

    (__local_c = ((((3735928559 as u32) +% (__param_init_val as u32)) as u32)))

    (__local_b = __local_c)

    (__local_a = __local_b)


    while true {
        var __local_v: u32 = ((tommy_le_uint32_read((__local_key as *const c_void)) as u32))

        if tommy_haszero_u32(__local_v) {
            if ((__local_v as u32) & (__local_m[0] as u32)) {
                (__local_a = (__local_a +% ((__local_v as u32) & (__local_m[0] as u32))))

                if ((__local_v as u32) & (__local_m[1] as u32)) {
                    (__local_a = (__local_a +% ((__local_v as u32) & (__local_m[1] as u32))))

                    if ((__local_v as u32) & (__local_m[2] as u32)) {
                        (__local_a = (__local_a +% ((__local_v as u32) & (__local_m[2] as u32))))
                    }

                }

            }

            break

        }

        (__local_a = (__local_a +% __local_v))

        (__local_v = ((tommy_le_uint32_read(((__local_key + ((4 as isize) as usize)) as *const c_void)) as u32)))

        if tommy_haszero_u32(__local_v) {
            if ((__local_v as u32) & (__local_m[0] as u32)) {
                (__local_b = (__local_b +% ((__local_v as u32) & (__local_m[0] as u32))))

                if ((__local_v as u32) & (__local_m[1] as u32)) {
                    (__local_b = (__local_b +% ((__local_v as u32) & (__local_m[1] as u32))))

                    if ((__local_v as u32) & (__local_m[2] as u32)) {
                        (__local_b = (__local_b +% ((__local_v as u32) & (__local_m[2] as u32))))
                    }

                }

            }

            break

        }

        (__local_b = (__local_b +% __local_v))

        (__local_v = ((tommy_le_uint32_read(((__local_key + ((8 as isize) as usize)) as *const c_void)) as u32)))

        if tommy_haszero_u32(__local_v) {
            if ((__local_v as u32) & (__local_m[0] as u32)) {
                (__local_c = (__local_c +% ((__local_v as u32) & (__local_m[0] as u32))))

                if ((__local_v as u32) & (__local_m[1] as u32)) {
                    (__local_c = (__local_c +% ((__local_v as u32) & (__local_m[1] as u32))))

                    if ((__local_v as u32) & (__local_m[2] as u32)) {
                        (__local_c = (__local_c +% ((__local_v as u32) & (__local_m[2] as u32))))
                    }

                }

            }

            break

        }

        (__local_c = (__local_c +% __local_v))

        loop {
            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as u32) ^ (((((__local_c as u32) << (4 as u32)) as u32) | (((__local_c as u32) >> ((32 - 4) as u32)) as u32)) as u32))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as u32) ^ (((((__local_a as u32) << (6 as u32)) as u32) | (((__local_a as u32) >> ((32 - 6) as u32)) as u32)) as u32))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as u32) ^ (((((__local_b as u32) << (8 as u32)) as u32) | (((__local_b as u32) >> ((32 - 8) as u32)) as u32)) as u32))

            (__local_b = (__local_b +% __local_a))

            (__local_a = (__local_a -% __local_c))

            (__local_a = (__local_a as u32) ^ (((((__local_c as u32) << (16 as u32)) as u32) | (((__local_c as u32) >> ((32 - 16) as u32)) as u32)) as u32))

            (__local_c = (__local_c +% __local_b))

            (__local_b = (__local_b -% __local_a))

            (__local_b = (__local_b as u32) ^ (((((__local_a as u32) << (19 as u32)) as u32) | (((__local_a as u32) >> ((32 - 19) as u32)) as u32)) as u32))

            (__local_a = (__local_a +% __local_c))

            (__local_c = (__local_c -% __local_b))

            (__local_c = (__local_c as u32) ^ (((((__local_b as u32) << (4 as u32)) as u32) | (((__local_b as u32) >> ((32 - 4) as u32)) as u32)) as u32))

            (__local_b = (__local_b +% __local_a))

            if not (false) {
                break
            }
        }

        (__local_key = __local_key + ((12 as isize) as usize))

    }

    loop {
        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (14 as u32)) as u32) | (((__local_b as u32) >> ((32 - 14) as u32)) as u32))))

        (__local_a = (__local_a as u32) ^ (__local_c as u32))

        (__local_a = (__local_a -% ((((__local_c as u32) << (11 as u32)) as u32) | (((__local_c as u32) >> ((32 - 11) as u32)) as u32))))

        (__local_b = (__local_b as u32) ^ (__local_a as u32))

        (__local_b = (__local_b -% ((((__local_a as u32) << (25 as u32)) as u32) | (((__local_a as u32) >> ((32 - 25) as u32)) as u32))))

        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (16 as u32)) as u32) | (((__local_b as u32) >> ((32 - 16) as u32)) as u32))))

        (__local_a = (__local_a as u32) ^ (__local_c as u32))

        (__local_a = (__local_a -% ((((__local_c as u32) << (4 as u32)) as u32) | (((__local_c as u32) >> ((32 - 4) as u32)) as u32))))

        (__local_b = (__local_b as u32) ^ (__local_a as u32))

        (__local_b = (__local_b -% ((((__local_a as u32) << (14 as u32)) as u32) | (((__local_a as u32) >> ((32 - 14) as u32)) as u32))))

        (__local_c = (__local_c as u32) ^ (__local_b as u32))

        (__local_c = (__local_c -% ((((__local_b as u32) << (24 as u32)) as u32) | (((__local_b as u32) >> ((32 - 24) as u32)) as u32))))

        if not (false) {
            break
        }
    }

    return __local_c

}

pub fn tommy_inthash_u32(__param_key: u32) -> u32 {
    var __local_key = __param_key
    (__local_key = (__local_key -% ((__local_key as u32) << (6 as u32))))

    (__local_key = (__local_key as u32) ^ (((__local_key as u32) >> (17 as u32)) as u32))

    (__local_key = (__local_key -% ((__local_key as u32) << (9 as u32))))

    (__local_key = (__local_key as u32) ^ (((__local_key as u32) << (4 as u32)) as u32))

    (__local_key = (__local_key -% ((__local_key as u32) << (3 as u32))))

    (__local_key = (__local_key as u32) ^ (((__local_key as u32) << (10 as u32)) as u32))

    (__local_key = (__local_key as u32) ^ (((__local_key as u32) >> (15 as u32)) as u32))

    return __local_key

}

pub fn tommy_inthash_u64(__param_key: u64) -> u64 {
    var __local_key = __param_key
    (__local_key = (((((~__local_key) as u64) +% (((__local_key as u64) << (21 as u32)) as u64)) as u64)))

    (__local_key = ((((__local_key as u64) ^ (((__local_key as u64) >> (24 as u32)) as u64)) as u64)))

    (__local_key = ((((((__local_key as u64) +% (((__local_key as u64) << (3 as u32)) as u64)) as u64) +% (((__local_key as u64) << (8 as u32)) as u64)) as u64)))

    (__local_key = ((((__local_key as u64) ^ (((__local_key as u64) >> (14 as u32)) as u64)) as u64)))

    (__local_key = ((((((__local_key as u64) +% (((__local_key as u64) << (2 as u32)) as u64)) as u64) +% (((__local_key as u64) << (4 as u32)) as u64)) as u64)))

    (__local_key = ((((__local_key as u64) ^ (((__local_key as u64) >> (28 as u32)) as u64)) as u64)))

    (__local_key = ((((__local_key as u64) +% (((__local_key as u64) << (31 as u32)) as u64)) as u64)))

    return __local_key

}

// contract: unproved:0:read only
unsafe fn tommy_le_uint32_read(__param_ptr: *const c_void) -> u32 {
    var __local_v: u32

    with_memcpy((((&raw mut __local_v as *mut u32) as *mut c_void) as *mut u8), (__param_ptr as *const u8), ((sizeof[u32]() as u64) as i64))

    return __local_v

}
