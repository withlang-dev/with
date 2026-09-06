use std.crypto.aes

extern fn with_eprintln(s: str) -> Unit

fn main:
    var key: [u8; 16] = [0x2b as u8, 0x7e as u8, 0x15 as u8, 0x16 as u8, 0x28 as u8, 0xae as u8, 0xd2 as u8, 0xa6 as u8, 0xab as u8, 0xf7 as u8, 0x15 as u8, 0x88 as u8, 0x09 as u8, 0xcf as u8, 0x4f as u8, 0x3c as u8]
    let ctx = Aes128.new(&key[0] as *const u8)
    var block: [u8; 16] = [0x32 as u8, 0x43 as u8, 0xf6 as u8, 0xa8 as u8, 0x88 as u8, 0x5a as u8, 0x30 as u8, 0x8d as u8, 0x31 as u8, 0x31 as u8, 0x98 as u8, 0xa2 as u8, 0xe0 as u8, 0x37 as u8, 0x07 as u8, 0x34 as u8]
    Aes128.encrypt_block(&ctx as *const Aes128, &raw mut block[0] as *mut u8)
    var exp: [u8; 16] = [0x39 as u8, 0x25 as u8, 0x84 as u8, 0x1d as u8, 0x02 as u8, 0xdc as u8, 0x09 as u8, 0xfb as u8, 0xdc as u8, 0x11 as u8, 0x85 as u8, 0x97 as u8, 0x19 as u8, 0x6a as u8, 0x0b as u8, 0x32 as u8]
    var bad = 0
    for i in 0..16:
        if (block[i] as i32) != (exp[i] as i32):
            bad = bad + 1
    unsafe { with_eprintln("VEC1 bad=" ++ int_to_string(bad)) }
    var k0: [u8; 16] = [0 as u8; 16]
    let c0 = Aes128.new(&k0[0] as *const u8)
    var b0: [u8; 16] = [0 as u8; 16]
    Aes128.encrypt_block(&c0 as *const Aes128, &raw mut b0[0] as *mut u8)
    var exp0: [u8; 16] = [0x66 as u8, 0xe9 as u8, 0x4b as u8, 0xd4 as u8, 0xef as u8, 0x8a as u8, 0x2c as u8, 0x3b as u8, 0x88 as u8, 0x4c as u8, 0xfa as u8, 0x59 as u8, 0xca as u8, 0x34 as u8, 0x2b as u8, 0x2e as u8]
    var bad0 = 0
    for i in 0..16:
        if (b0[i] as i32) != (exp0[i] as i32):
            bad0 = bad0 + 1
    unsafe { with_eprintln("VEC0 bad=" ++ int_to_string(bad0)) }
