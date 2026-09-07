// T22 probe: i31 decode/encode round-trip.
// Oracle: python3 (0xDEADBEEF & 0x7FFFFFFF == 1588444911, >> 31 == 1).
use std.crypto.bigint
use std.builtins.print
use std.builtins.assert

fn main:
    var src: [u8; 4] = [0xDEu8, 0xADu8, 0xBEu8, 0xEFu8]
    var x: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut x[0] as *mut u32, &src[0] as *const u8, 4) }
    assert(x[0] == 32u32, "decode bitlen")
    assert(x[1] == 1588444911u32, "decode limb 0")
    assert(x[2] == 1u32, "decode limb 1")
    var dst: [u8; 4] = [0u8; 4]
    unsafe { i31_encode(&raw mut dst[0] as *mut u8, 4, &x[0] as *const u32) }
    assert(dst[0] == 0xDEu8, "encode byte 0")
    assert(dst[1] == 0xADu8, "encode byte 1")
    assert(dst[2] == 0xBEu8, "encode byte 2")
    assert(dst[3] == 0xEFu8, "encode byte 3")
    var src2: [u8; 1] = [42u8]
    var x2: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut x2[0] as *mut u32, &src2[0] as *const u8, 1) }
    assert(x2[0] == 6u32, "decode single bitlen")
    assert(x2[1] == 42u32, "decode single limb")
    var dst2: [u8; 1] = [0u8]
    unsafe { i31_encode(&raw mut dst2[0] as *mut u8, 1, &x2[0] as *const u32) }
    assert(dst2[0] == 42u8, "encode single byte")
    print("bigint-codec-ok")
