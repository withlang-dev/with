use std.crypto.sha256
use std.builtins.int_to_string

extern fn with_eprintln(s: str) -> Unit

fn main:
    var empty: [u8; 1] = [0 as u8; 1]
    var hash: [u8; 32] = [0 as u8; 32]
    sha256_hash(&empty[0] as *const u8, 0, &raw mut hash[0] as *mut u8)
    unsafe { with_eprintln("POS:" ++ int_to_string((hash[0] as u32) as i32)) }
