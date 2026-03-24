// AES-128 block cipher
// Standard byte-oriented with precomputed S-box.

type Aes128  {
    round_keys: [u8; 176],  // 11 round keys x 16 bytes
}

fn aes_sbox(i: i32) -> u8:
    let sbox = [
        0x63 as u8, 0x7c as u8, 0x77 as u8, 0x7b as u8, 0xf2 as u8, 0x6b as u8, 0x6f as u8, 0xc5 as u8,
        0x30 as u8, 0x01 as u8, 0x67 as u8, 0x2b as u8, 0xfe as u8, 0xd7 as u8, 0xab as u8, 0x76 as u8,
        0xca as u8, 0x82 as u8, 0xc9 as u8, 0x7d as u8, 0xfa as u8, 0x59 as u8, 0x47 as u8, 0xf0 as u8,
        0xad as u8, 0xd4 as u8, 0xa2 as u8, 0xaf as u8, 0x9c as u8, 0xa4 as u8, 0x72 as u8, 0xc0 as u8,
        0xb7 as u8, 0xfd as u8, 0x93 as u8, 0x26 as u8, 0x36 as u8, 0x3f as u8, 0xf7 as u8, 0xcc as u8,
        0x34 as u8, 0xa5 as u8, 0xe5 as u8, 0xf1 as u8, 0x71 as u8, 0xd8 as u8, 0x31 as u8, 0x15 as u8,
        0x04 as u8, 0xc7 as u8, 0x23 as u8, 0xc3 as u8, 0x18 as u8, 0x96 as u8, 0x05 as u8, 0x9a as u8,
        0x07 as u8, 0x12 as u8, 0x80 as u8, 0xe2 as u8, 0xeb as u8, 0x27 as u8, 0xb2 as u8, 0x75 as u8,
        0x09 as u8, 0x83 as u8, 0x2c as u8, 0x1a as u8, 0x1b as u8, 0x6e as u8, 0x5a as u8, 0xa0 as u8,
        0x52 as u8, 0x3b as u8, 0xd6 as u8, 0xb3 as u8, 0x29 as u8, 0xe3 as u8, 0x2f as u8, 0x84 as u8,
        0x53 as u8, 0xd1 as u8, 0x00 as u8, 0xed as u8, 0x20 as u8, 0xfc as u8, 0xb1 as u8, 0x5b as u8,
        0x6a as u8, 0xcb as u8, 0xbe as u8, 0x39 as u8, 0x4a as u8, 0x4c as u8, 0x58 as u8, 0xcf as u8,
        0xd0 as u8, 0xef as u8, 0xaa as u8, 0xfb as u8, 0x43 as u8, 0x4d as u8, 0x33 as u8, 0x85 as u8,
        0x45 as u8, 0xf9 as u8, 0x02 as u8, 0x7f as u8, 0x50 as u8, 0x3c as u8, 0x9f as u8, 0xa8 as u8,
        0x51 as u8, 0xa3 as u8, 0x40 as u8, 0x8f as u8, 0x92 as u8, 0x9d as u8, 0x38 as u8, 0xf5 as u8,
        0xbc as u8, 0xb6 as u8, 0xda as u8, 0x21 as u8, 0x10 as u8, 0xff as u8, 0xf3 as u8, 0xd2 as u8,
        0xcd as u8, 0x0c as u8, 0x13 as u8, 0xec as u8, 0x5f as u8, 0x97 as u8, 0x44 as u8, 0x17 as u8,
        0xc4 as u8, 0xa7 as u8, 0x7e as u8, 0x3d as u8, 0x64 as u8, 0x5d as u8, 0x19 as u8, 0x73 as u8,
        0x60 as u8, 0x81 as u8, 0x4f as u8, 0xdc as u8, 0x22 as u8, 0x2a as u8, 0x90 as u8, 0x88 as u8,
        0x46 as u8, 0xee as u8, 0xb8 as u8, 0x14 as u8, 0xde as u8, 0x5e as u8, 0x0b as u8, 0xdb as u8,
        0xe0 as u8, 0x32 as u8, 0x3a as u8, 0x0a as u8, 0x49 as u8, 0x06 as u8, 0x24 as u8, 0x5c as u8,
        0xc2 as u8, 0xd3 as u8, 0xac as u8, 0x62 as u8, 0x91 as u8, 0x95 as u8, 0xe4 as u8, 0x79 as u8,
        0xe7 as u8, 0xc8 as u8, 0x37 as u8, 0x6d as u8, 0x8d as u8, 0xd5 as u8, 0x4e as u8, 0xa9 as u8,
        0x6c as u8, 0x56 as u8, 0xf4 as u8, 0xea as u8, 0x65 as u8, 0x7a as u8, 0xae as u8, 0x08 as u8,
        0xba as u8, 0x78 as u8, 0x25 as u8, 0x2e as u8, 0x1c as u8, 0xa6 as u8, 0xb4 as u8, 0xc6 as u8,
        0xe8 as u8, 0xdd as u8, 0x74 as u8, 0x1f as u8, 0x4b as u8, 0xbd as u8, 0x8b as u8, 0x8a as u8,
        0x70 as u8, 0x3e as u8, 0xb5 as u8, 0x66 as u8, 0x48 as u8, 0x03 as u8, 0xf6 as u8, 0x0e as u8,
        0x61 as u8, 0x35 as u8, 0x57 as u8, 0xb9 as u8, 0x86 as u8, 0xc1 as u8, 0x1d as u8, 0x9e as u8,
        0xe1 as u8, 0xf8 as u8, 0x98 as u8, 0x11 as u8, 0x69 as u8, 0xd9 as u8, 0x8e as u8, 0x94 as u8,
        0x9b as u8, 0x1e as u8, 0x87 as u8, 0xe9 as u8, 0xce as u8, 0x55 as u8, 0x28 as u8, 0xdf as u8,
        0x8c as u8, 0xa1 as u8, 0x89 as u8, 0x0d as u8, 0xbf as u8, 0xe6 as u8, 0x42 as u8, 0x68 as u8,
        0x41 as u8, 0x99 as u8, 0x2d as u8, 0x0f as u8, 0xb0 as u8, 0x54 as u8, 0xbb as u8, 0x16 as u8,
    ]
    sbox[i]

fn aes_rcon(i: i32) -> u8:
    let rc = [0x01 as u8, 0x02 as u8, 0x04 as u8, 0x08 as u8, 0x10 as u8,
              0x20 as u8, 0x40 as u8, 0x80 as u8, 0x1b as u8, 0x36 as u8]
    rc[i]

fn xtime(x: u8) -> u8:
    let shifted = ((x as u32) << 1 as u32) as u8
    let mask = if (x & (0x80 as u8)) != (0 as u8): 0x1b as u8 else: 0x00 as u8
    shifted ^ mask

// Key schedule
unsafe fn aes128_init(ctx: *mut Aes128, key: *const u8):
    let rk = &mut ctx.round_keys[0] as *mut u8
    for i in 0..16:
        *(rk + i as u64) = *(key + i as u64)
    for i in 1..11:
        let prev_off = (i - 1) * 16
        let cur_off = i * 16
        let r0 = aes_sbox((*(rk + (prev_off + 13) as u64)) as i32) ^ aes_rcon(i - 1)
        let r1 = aes_sbox((*(rk + (prev_off + 14) as u64)) as i32)
        let r2 = aes_sbox((*(rk + (prev_off + 15) as u64)) as i32)
        let r3 = aes_sbox((*(rk + (prev_off + 12) as u64)) as i32)
        *(rk + (cur_off + 0) as u64) = *(rk + (prev_off + 0) as u64) ^ r0
        *(rk + (cur_off + 1) as u64) = *(rk + (prev_off + 1) as u64) ^ r1
        *(rk + (cur_off + 2) as u64) = *(rk + (prev_off + 2) as u64) ^ r2
        *(rk + (cur_off + 3) as u64) = *(rk + (prev_off + 3) as u64) ^ r3
        for j in 4..16:
            *(rk + (cur_off + j) as u64) = *(rk + (prev_off + j) as u64) ^ *(rk + (cur_off + j - 4) as u64)

fn Aes128.new(key: *const u8) -> Aes128:
    var ctx = Aes128 { round_keys: [0 as u8; 176] }
    unsafe: aes128_init(&mut ctx as *mut Aes128, key)
    ctx

// Block cipher operations
unsafe fn aes_add_round_key(s: *mut u8, rk: *const u8, off: i32):
    for i in 0..16:
        *(s + i as u64) = *(s + i as u64) ^ *(rk + (off + i) as u64)

unsafe fn aes_sub_bytes(s: *mut u8):
    for i in 0..16:
        *(s + i as u64) = aes_sbox((*(s + i as u64)) as i32)

unsafe fn aes_shift_rows(s: *mut u8):
    let t = *(s + 1 as u64)
    *(s + 1 as u64) = *(s + 5 as u64)
    *(s + 5 as u64) = *(s + 9 as u64)
    *(s + 9 as u64) = *(s + 13 as u64)
    *(s + 13 as u64) = t
    let t0 = *(s + 2 as u64)
    let t1 = *(s + 6 as u64)
    *(s + 2 as u64) = *(s + 10 as u64)
    *(s + 6 as u64) = *(s + 14 as u64)
    *(s + 10 as u64) = t0
    *(s + 14 as u64) = t1
    let t2 = *(s + 15 as u64)
    *(s + 15 as u64) = *(s + 11 as u64)
    *(s + 11 as u64) = *(s + 7 as u64)
    *(s + 7 as u64) = *(s + 3 as u64)
    *(s + 3 as u64) = t2

unsafe fn aes_mix_columns(s: *mut u8):
    for c in 0..4:
        let off = c * 4
        let a0 = *(s + (off + 0) as u64)
        let a1 = *(s + (off + 1) as u64)
        let a2 = *(s + (off + 2) as u64)
        let a3 = *(s + (off + 3) as u64)
        let r = a0 ^ a1 ^ a2 ^ a3
        *(s + (off + 0) as u64) = a0 ^ r ^ xtime(a0 ^ a1)
        *(s + (off + 1) as u64) = a1 ^ r ^ xtime(a1 ^ a2)
        *(s + (off + 2) as u64) = a2 ^ r ^ xtime(a2 ^ a3)
        *(s + (off + 3) as u64) = a3 ^ r ^ xtime(a3 ^ a0)

// Encrypt a single 16-byte block in-place
unsafe fn aes128_encrypt_block(ctx: *const Aes128, block: *mut u8):
    var s: [u8; 16] = [0 as u8; 16]
    let sp = &mut s[0] as *mut u8
    for i in 0..16:
        *(sp + i as u64) = *(block + i as u64)

    var rk: [u8; 176] = [0 as u8; 176]
    let rkp = &mut rk[0] as *mut u8
    for i in 0..176:
        *(rkp + i as u64) = ctx.round_keys[i]

    aes_add_round_key(sp, rkp as *const u8, 0)
    for r in 1..10:
        aes_sub_bytes(sp)
        aes_shift_rows(sp)
        aes_mix_columns(sp)
        aes_add_round_key(sp, rkp as *const u8, r * 16)
    aes_sub_bytes(sp)
    aes_shift_rows(sp)
    aes_add_round_key(sp, rkp as *const u8, 160)

    for i in 0..16:
        *(block + i as u64) = *(sp + i as u64)

// Public wrapper
fn Aes128.encrypt_block(self: *const Aes128, block: *mut u8):
    unsafe: aes128_encrypt_block(self, block)
