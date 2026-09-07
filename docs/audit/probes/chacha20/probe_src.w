use std.crypto.chacha20
use std.io

// Probe P1: RFC 8439 section 2.3.2 keystream vector.
var key: [u8; 32] = [0 as u8; 32]
for i in 0..32:
    key[i] = i as u8
var nonce: [u8; 12] = [0 as u8; 12]
nonce[3] = 0x09 as u8
nonce[7] = 0x4a as u8
var block: [u8; 64] = [0 as u8; 64]
unsafe:
    chacha20_block(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut block[0] as *mut u8)
print_line("P1-BLOCK-CTR1:")
for i in 0..64:
    print_int((block[i] as u32) as i32)

// Probe P2: counter 0 must differ from counter 1 (counter feeds state[12]).
var block0: [u8; 64] = [0 as u8; 64]
unsafe:
    chacha20_block(&key[0] as *const u8, &nonce[0] as *const u8, 0 as u32, &raw mut block0[0] as *mut u8)
print_line(if block0[0] != block[0]: "P2-CTR-DIFF-OK" else: "P2-CTR-DIFF-FAIL")

// Probe P3: multi-block + partial-block crypt roundtrip (128 and 100 bytes).
var data: [u8; 128] = [0 as u8; 128]
for i in 0..128:
    data[i] = i as u8
unsafe:
    chacha20_crypt(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut data[0] as *mut u8, 128)
let c0 = (data[0] as u32) as i32
let c127 = (data[127] as u32) as i32
unsafe:
    chacha20_crypt(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut data[0] as *mut u8, 128)
print_line(if data[0] == 0 as u8 and data[127] == 127 as u8: "P3-ROUNDTRIP128-OK" else: "P3-ROUNDTRIP128-FAIL")
print_line(if c0 != 0 and c127 != 127: "P3-ENCRYPT-CHANGED-OK" else: "P3-ENCRYPT-NOOP-FAIL")
var short: [u8; 100] = [0 as u8; 100]
for i in 0..100:
    short[i] = (i + 7) as u8
unsafe:
    chacha20_crypt(&key[0] as *const u8, &nonce[0] as *const u8, 5 as u32, &raw mut short[0] as *mut u8, 100)
unsafe:
    chacha20_crypt(&key[0] as *const u8, &nonce[0] as *const u8, 5 as u32, &raw mut short[0] as *mut u8, 100)
print_line(if short[0] == 7 as u8 and short[99] == 106 as u8: "P3-ROUNDTRIP100-OK" else: "P3-ROUNDTRIP100-FAIL")

// Probe P4 (negative control): flipped key bit must change keystream.
var badkey: [u8; 32] = [0 as u8; 32]
for i in 0..32:
    badkey[i] = i as u8
badkey[0] = 0xff as u8
var badblock: [u8; 64] = [0 as u8; 64]
unsafe:
    chacha20_block(&badkey[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut badblock[0] as *mut u8)
print_line(if badblock[0] != block[0]: "P4-NEG-OK" else: "P4-NEG-FAIL")
