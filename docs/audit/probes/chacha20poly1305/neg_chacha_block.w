use std.crypto.chacha20
use std.builtins.int_to_string

extern fn with_eprintln(s: str) -> Unit

fn main:
    var key: [u8; 32] = [0 as u8; 32]
    var nonce: [u8; 12] = [0 as u8; 12]
    var block: [u8; 64] = [0 as u8; 64]
    unsafe { chacha20_block(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut block[0] as *mut u8) }
    unsafe { with_eprintln("NEG:" ++ int_to_string((block[0] as u32) as i32)) }
