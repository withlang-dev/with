// T22 probe: i31 modpow against python3 pow() oracle:
// 3^7 mod 13 = 3; 100^3 mod 997 = 9; 17^65537 mod 3233 = 908 (0x038C).
use std.crypto.bigint
use std.builtins.print
use std.builtins.assert

fn main:
    var m_bytes: [u8; 1] = [13u8]
    var m: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut m[0] as *mut u32, &m_bytes[0] as *const u8, 1) }
    let m0i = i31_ninv31(m[1])
    var x_bytes: [u8; 1] = [3u8]
    var x: [u32; 4] = [0u32; 4]
    unsafe { i31_decode_reduce(&raw mut x[0] as *mut u32, &x_bytes[0] as *const u8, 1, &m[0] as *const u32) }
    var e: [u8; 1] = [7u8]
    var t1: [u32; 4] = [0u32; 4]
    var t2: [u32; 4] = [0u32; 4]
    unsafe { i31_modpow(&raw mut x[0] as *mut u32, &e[0] as *const u8, 1, &m[0] as *const u32, m0i, &raw mut t1[0] as *mut u32, &raw mut t2[0] as *mut u32) }
    var result: [u8; 1] = [0u8]
    unsafe { i31_encode(&raw mut result[0] as *mut u8, 1, &x[0] as *const u32) }
    assert(result[0] == 3u8, "3^7 mod 13 = 3")

    var m2_bytes: [u8; 2] = [0x03u8, 0xE5u8]
    var m2: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut m2[0] as *mut u32, &m2_bytes[0] as *const u8, 2) }
    let m20i = i31_ninv31(m2[1])
    var x2_bytes: [u8; 1] = [0x64u8]
    var x2: [u32; 4] = [0u32; 4]
    unsafe { i31_decode_reduce(&raw mut x2[0] as *mut u32, &x2_bytes[0] as *const u8, 1, &m2[0] as *const u32) }
    var e2: [u8; 1] = [3u8]
    var t12: [u32; 4] = [0u32; 4]
    var t22: [u32; 4] = [0u32; 4]
    unsafe { i31_modpow(&raw mut x2[0] as *mut u32, &e2[0] as *const u8, 1, &m2[0] as *const u32, m20i, &raw mut t12[0] as *mut u32, &raw mut t22[0] as *mut u32) }
    var result2: [u8; 2] = [0u8; 2]
    unsafe { i31_encode(&raw mut result2[0] as *mut u8, 2, &x2[0] as *const u32) }
    assert(result2[0] == 0u8, "100^3 mod 997 hi")
    assert(result2[1] == 9u8, "100^3 mod 997 lo")

    var m3_bytes: [u8; 2] = [0x0Cu8, 0xA1u8]
    var m3: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut m3[0] as *mut u32, &m3_bytes[0] as *const u8, 2) }
    let m30i = i31_ninv31(m3[1])
    var x3_bytes: [u8; 1] = [0x11u8]
    var x3: [u32; 4] = [0u32; 4]
    unsafe { i31_decode_reduce(&raw mut x3[0] as *mut u32, &x3_bytes[0] as *const u8, 1, &m3[0] as *const u32) }
    var e3: [u8; 3] = [0x01u8, 0x00u8, 0x01u8]
    var t13: [u32; 4] = [0u32; 4]
    var t23: [u32; 4] = [0u32; 4]
    unsafe { i31_modpow(&raw mut x3[0] as *mut u32, &e3[0] as *const u8, 3, &m3[0] as *const u32, m30i, &raw mut t13[0] as *mut u32, &raw mut t23[0] as *mut u32) }
    var result3: [u8; 2] = [0u8; 2]
    unsafe { i31_encode(&raw mut result3[0] as *mut u8, 2, &x3[0] as *const u32) }
    assert(result3[0] == 0x03u8, "17^65537 mod 3233 hi")
    assert(result3[1] == 0x8Cu8, "17^65537 mod 3233 lo")
    print("bigint-modpow-ok")
