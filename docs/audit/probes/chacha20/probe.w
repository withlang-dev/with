use std.crypto.chacha20

extern fn with_print_int(v: i32) -> Unit
extern fn with_eprintln(s: str) -> Unit

fn main:
    // RFC 8439 section 2.3.2 vector: key 00..1f, nonce 000000090000004a00000000, counter 1
    var key: [u8; 32] = [0 as u8; 32]
    for i in 0..32:
        key[i] = i as u8
    var nonce: [u8; 12] = [0 as u8; 12]
    nonce[3] = 0x09 as u8
    nonce[7] = 0x4a as u8
    var block: [u8; 64] = [0 as u8; 64]
    unsafe:
        chacha20_block(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut block[0] as *mut u8)
    // print all 64 bytes as decimal ints, space-separated
    unsafe:
        for i in 0..64:
            with_print_int((block[i] as u32) as i32)
            with_eprintln(if i == 63: "\n" else: " ")
    // crypt roundtrip: encrypt 128 bytes then decrypt, check identity
    var data: [u8; 128] = [0 as u8; 128]
    for i in 0..128:
        data[i] = i as u8
    var orig0 = data[0]
    var orig127 = data[127]
    unsafe:
        chacha20_crypt(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut data[0] as *mut u8, 128)
    let c0 = (data[0] as u32) as i32
    unsafe:
        chacha20_crypt(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut data[0] as *mut u8, 128)
    unsafe { with_eprintln("roundtrip:") }
    unsafe:
        with_print_int((data[0] as u32) as i32)
        with_eprintln(" ")
        with_print_int((data[127] as u32) as i32)
        with_eprintln("\n")
    unsafe { with_eprintln(if (data[0] == orig0) && (data[127] == orig127): "ROUNDTRIP-OK" else: "ROUNDTRIP-FAIL") }
    unsafe { with_eprintln(if c0 != ((orig0 as u32) as i32): "ENCRYPT-CHANGED-OK" else: "ENCRYPT-NOOP-FAIL") }
