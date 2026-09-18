// Negative controls: zero decode, is_zero, same-size gte, add/sub ctl=0 no-op.
// Oracle: BearSSL i31 contract (zero has bitlen 0; ctl=0 leaves a untouched).
// NOTE: gte/add/sub require equal-sized operands (callers always use the
// modulus size); the zero value's limbs are untouched by decode, so gte is
// only probed on equal-size nonzero values.
use std.crypto.bigint
use std.builtins.print
use std.builtins.assert

fn main:
    var zsrc: [u8; 2] = [0u8, 0u8]
    var z: [u32; 4] = [0xDEADBEEFu32, 0xDEADBEEFu32, 0xDEADBEEFu32, 0xDEADBEEFu32]
    unsafe { i31_decode(&raw mut z[0] as *mut u32, &zsrc[0] as *const u8, 2) }
    assert(z[0] == 0u32, "zero decode bitlen")
    unsafe { assert(i31_is_zero(&z[0] as *const u32) == 1u32, "zero is_zero") }
    var osrc: [u8; 1] = [1u8]
    var o: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut o[0] as *mut u32, &osrc[0] as *const u8, 1) }
    unsafe { assert(i31_is_zero(&o[0] as *const u32) == 0u32, "one not zero") }
    var asrc: [u8; 1] = [5u8]
    var bsrc: [u8; 1] = [3u8]
    var a: [u32; 4] = [0u32; 4]
    var b: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut a[0] as *mut u32, &asrc[0] as *const u8, 1) }
    unsafe { i31_decode(&raw mut b[0] as *mut u32, &bsrc[0] as *const u8, 1) }
    unsafe { assert(i31_gte(&a[0] as *const u32, &b[0] as *const u32) == 1u32, "5 >= 3") }
    unsafe { assert(i31_gte(&b[0] as *const u32, &a[0] as *const u32) == 0u32, "3 < 5") }
    var acc: [u32; 4] = [0u32; 4]
    unsafe { i31_decode(&raw mut acc[0] as *mut u32, &osrc[0] as *const u8, 1) }
    let snap0 = acc[1]
    unsafe { i31_add(&raw mut acc[0] as *mut u32, &o[0] as *const u32, 0u32) }
    assert(acc[1] == snap0, "add ctl=0 no-op")
    unsafe { i31_sub(&raw mut acc[0] as *mut u32, &o[0] as *const u32, 0u32) }
    assert(acc[1] == snap0, "sub ctl=0 no-op")
    print("bigint-edge-ok")
