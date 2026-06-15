use std.process

extern fn with_eprint(s: str) -> Unit
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str

fn sha256_k(i: i32) -> u32:
    let k = [
        0x428a2f98 as u32, 0x71374491 as u32, 0xb5c0fbcf as u32, 0xe9b5dba5 as u32,
        0x3956c25b as u32, 0x59f111f1 as u32, 0x923f82a4 as u32, 0xab1c5ed5 as u32,
        0xd807aa98 as u32, 0x12835b01 as u32, 0x243185be as u32, 0x550c7dc3 as u32,
        0x72be5d74 as u32, 0x80deb1fe as u32, 0x9bdc06a7 as u32, 0xc19bf174 as u32,
        0xe49b69c1 as u32, 0xefbe4786 as u32, 0x0fc19dc6 as u32, 0x240ca1cc as u32,
        0x2de92c6f as u32, 0x4a7484aa as u32, 0x5cb0a9dc as u32, 0x76f988da as u32,
        0x983e5152 as u32, 0xa831c66d as u32, 0xb00327c8 as u32, 0xbf597fc7 as u32,
        0xc6e00bf3 as u32, 0xd5a79147 as u32, 0x06ca6351 as u32, 0x14292967 as u32,
        0x27b70a85 as u32, 0x2e1b2138 as u32, 0x4d2c6dfc as u32, 0x53380d13 as u32,
        0x650a7354 as u32, 0x766a0abb as u32, 0x81c2c92e as u32, 0x92722c85 as u32,
        0xa2bfe8a1 as u32, 0xa81a664b as u32, 0xc24b8b70 as u32, 0xc76c51a3 as u32,
        0xd192e819 as u32, 0xd6990624 as u32, 0xf40e3585 as u32, 0x106aa070 as u32,
        0x19a4c116 as u32, 0x1e376c08 as u32, 0x2748774c as u32, 0x34b0bcb5 as u32,
        0x391c0cb3 as u32, 0x4ed8aa4a as u32, 0x5b9cca4f as u32, 0x682e6ff3 as u32,
        0x748f82ee as u32, 0x78a5636f as u32, 0x84c87814 as u32, 0x8cc70208 as u32,
        0x90befffa as u32, 0xa4506ceb as u32, 0xbef9a3f7 as u32, 0xc67178f2 as u32,
    ]
    k[i]

fn ch(x: u32, y: u32, z: u32) -> u32:
    (x & y) ^ ((~x) & z)

fn maj(x: u32, y: u32, z: u32) -> u32:
    (x & y) ^ (x & z) ^ (y & z)

fn big_sigma0(x: u32) -> u32:
    x.rotate_right(2) ^ x.rotate_right(13) ^ x.rotate_right(22)

fn big_sigma1(x: u32) -> u32:
    x.rotate_right(6) ^ x.rotate_right(11) ^ x.rotate_right(25)

fn small_sigma0(x: u32) -> u32:
    x.rotate_right(7) ^ x.rotate_right(18) ^ (x >> 3 as u32)

fn small_sigma1(x: u32) -> u32:
    x.rotate_right(17) ^ x.rotate_right(19) ^ (x >> 10 as u32)

fn hex_byte(value: u32) -> str:
    let hex = "0123456789abcdef"
    let hi = ((value >> 4 as u32) & 0x0f as u32) as i64
    let lo = (value & 0x0f as u32) as i64
    hex.slice(hi, hi + 1) ++ hex.slice(lo, lo + 1)

fn sha256_text(text: str) -> str:
    let msg: Vec[u8] = Vec.new()
    for i in 0..text.len() as i32:
        msg.push(text.byte_at(i as i64))
    let bit_len = (text.len() as u64) * 8 as u64
    msg.push(0x80 as u8)
    while msg.len() % 64 != 56:
        msg.push(0 as u8)
    msg.push(((bit_len >> 56 as u64) & 0xff as u64) as u8)
    msg.push(((bit_len >> 48 as u64) & 0xff as u64) as u8)
    msg.push(((bit_len >> 40 as u64) & 0xff as u64) as u8)
    msg.push(((bit_len >> 32 as u64) & 0xff as u64) as u8)
    msg.push(((bit_len >> 24 as u64) & 0xff as u64) as u8)
    msg.push(((bit_len >> 16 as u64) & 0xff as u64) as u8)
    msg.push(((bit_len >> 8 as u64) & 0xff as u64) as u8)
    msg.push((bit_len & 0xff as u64) as u8)

    var h0 = 0x6a09e667 as u32
    var h1 = 0xbb67ae85 as u32
    var h2 = 0x3c6ef372 as u32
    var h3 = 0xa54ff53a as u32
    var h4 = 0x510e527f as u32
    var h5 = 0x9b05688c as u32
    var h6 = 0x1f83d9ab as u32
    var h7 = 0x5be0cd19 as u32

    var block = 0
    while block < msg.len() as i32:
        var w: [u32; 64] = [0 as u32; 64]
        for i in 0..16:
            let word_offset = (block + i * 4) as i64
            w[i] = ((msg.get(word_offset) as u32) << 24 as u32) |
                ((msg.get(word_offset + 1) as u32) << 16 as u32) |
                ((msg.get(word_offset + 2) as u32) << 8 as u32) |
                (msg.get(word_offset + 3) as u32)
        for i in 16..64:
            w[i] = small_sigma1(w[i - 2]) +% w[i - 7] +% small_sigma0(w[i - 15]) +% w[i - 16]

        var a = h0
        var b = h1
        var c = h2
        var d = h3
        var e = h4
        var f = h5
        var g = h6
        var h = h7

        for i in 0..64:
            let t1 = h +% big_sigma1(e) +% ch(e, f, g) +% sha256_k(i) +% w[i]
            let t2 = big_sigma0(a) +% maj(a, b, c)
            h = g
            g = f
            f = e
            e = d +% t1
            d = c
            c = b
            b = a
            a = t1 +% t2

        h0 +%= a
        h1 +%= b
        h2 +%= c
        h3 +%= d
        h4 +%= e
        h5 +%= f
        h6 +%= g
        h7 +%= h
        block = block + 64

    hex_byte((h0 >> 24 as u32) & 0xff as u32) ++ hex_byte((h0 >> 16 as u32) & 0xff as u32) ++ hex_byte((h0 >> 8 as u32) & 0xff as u32) ++ hex_byte(h0 & 0xff as u32) ++
        hex_byte((h1 >> 24 as u32) & 0xff as u32) ++ hex_byte((h1 >> 16 as u32) & 0xff as u32) ++ hex_byte((h1 >> 8 as u32) & 0xff as u32) ++ hex_byte(h1 & 0xff as u32) ++
        hex_byte((h2 >> 24 as u32) & 0xff as u32) ++ hex_byte((h2 >> 16 as u32) & 0xff as u32) ++ hex_byte((h2 >> 8 as u32) & 0xff as u32) ++ hex_byte(h2 & 0xff as u32) ++
        hex_byte((h3 >> 24 as u32) & 0xff as u32) ++ hex_byte((h3 >> 16 as u32) & 0xff as u32) ++ hex_byte((h3 >> 8 as u32) & 0xff as u32) ++ hex_byte(h3 & 0xff as u32) ++
        hex_byte((h4 >> 24 as u32) & 0xff as u32) ++ hex_byte((h4 >> 16 as u32) & 0xff as u32) ++ hex_byte((h4 >> 8 as u32) & 0xff as u32) ++ hex_byte(h4 & 0xff as u32) ++
        hex_byte((h5 >> 24 as u32) & 0xff as u32) ++ hex_byte((h5 >> 16 as u32) & 0xff as u32) ++ hex_byte((h5 >> 8 as u32) & 0xff as u32) ++ hex_byte(h5 & 0xff as u32) ++
        hex_byte((h6 >> 24 as u32) & 0xff as u32) ++ hex_byte((h6 >> 16 as u32) & 0xff as u32) ++ hex_byte((h6 >> 8 as u32) & 0xff as u32) ++ hex_byte(h6 & 0xff as u32) ++
        hex_byte((h7 >> 24 as u32) & 0xff as u32) ++ hex_byte((h7 >> 16 as u32) & 0xff as u32) ++ hex_byte((h7 >> 8 as u32) & 0xff as u32) ++ hex_byte(h7 & 0xff as u32)

fn main:
    let argv = args()
    if argv.len() < 2:
        unsafe { with_eprint("usage: with-sha256 <file>...\n") }
        exit_code(1)
    for i in 1..argv.len() as i32:
        let path = argv.get(i as i64)
        if unsafe { with_fs_file_exists(path) } == 0:
            unsafe { with_eprint("with-sha256: missing file: " ++ path ++ "\n") }
            exit_code(1)
        print(sha256_text(unsafe { with_fs_read_file(path) }) ++ "  " ++ path)
