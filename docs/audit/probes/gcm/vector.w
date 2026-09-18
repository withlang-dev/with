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
    let rk = &raw mut ctx.round_keys[0] as *mut u8
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
    unsafe { aes128_init(&raw mut ctx as *mut Aes128, key) }
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
    let sp = &raw mut s[0] as *mut u8
    for i in 0..16:
        *(sp + i as u64) = *(block + i as u64)

    var rk: [u8; 176] = [0 as u8; 176]
    let rkp = &raw mut rk[0] as *mut u8
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
unsafe fn Aes128.encrypt_block(ctx: *const Aes128, block: *mut u8):
    unsafe { aes128_encrypt_block(ctx, block) }

// Byte-order encode/decode utilities for crypto and network code.
// These should eventually be compiler intrinsics on integer types
// (u32.from_be, etc.), but for now they are standalone functions.

fn u16_from_be(buf: *const u8, off: i32) -> u16:
    let b0 = (unsafe *(buf + off as u64)) as u16
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u16
    (b0 << 8 as u16) | b1

fn u16_from_le(buf: *const u8, off: i32) -> u16:
    let b0 = (unsafe *(buf + off as u64)) as u16
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u16
    b0 | (b1 << 8 as u16)

fn u32_from_be(buf: *const u8, off: i32) -> u32:
    let b0 = (unsafe *(buf + off as u64)) as u32
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u32
    let b2 = (unsafe *(buf + (off + 2) as u64)) as u32
    let b3 = (unsafe *(buf + (off + 3) as u64)) as u32
    (b0 << 24 as u32) | (b1 << 16 as u32) | (b2 << 8 as u32) | b3

fn u32_from_le(buf: *const u8, off: i32) -> u32:
    let b0 = (unsafe *(buf + off as u64)) as u32
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u32
    let b2 = (unsafe *(buf + (off + 2) as u64)) as u32
    let b3 = (unsafe *(buf + (off + 3) as u64)) as u32
    b0 | (b1 << 8 as u32) | (b2 << 16 as u32) | (b3 << 24 as u32)

fn u64_from_be(buf: *const u8, off: i32) -> u64:
    let hi = u32_from_be(buf, off) as u64
    let lo = u32_from_be(buf, off + 4) as u64
    (hi << 32 as u64) | lo

fn u64_from_le(buf: *const u8, off: i32) -> u64:
    let lo = u32_from_le(buf, off) as u64
    let hi = u32_from_le(buf, off + 4) as u64
    (hi << 32 as u64) | lo

fn u16_to_be(buf: *mut u8, off: i32, val: u16):
    unsafe *(buf + off as u64) = (val >> 8 as u16) as u8
    unsafe *(buf + (off + 1) as u64) = val as u8

fn u16_to_le(buf: *mut u8, off: i32, val: u16):
    unsafe *(buf + off as u64) = val as u8
    unsafe *(buf + (off + 1) as u64) = (val >> 8 as u16) as u8

fn u32_to_be(buf: *mut u8, off: i32, val: u32):
    unsafe *(buf + off as u64) = (val >> 24 as u32) as u8
    unsafe *(buf + (off + 1) as u64) = (val >> 16 as u32) as u8
    unsafe *(buf + (off + 2) as u64) = (val >> 8 as u32) as u8
    unsafe *(buf + (off + 3) as u64) = val as u8

fn u32_to_le(buf: *mut u8, off: i32, val: u32):
    unsafe *(buf + off as u64) = val as u8
    unsafe *(buf + (off + 1) as u64) = (val >> 8 as u32) as u8
    unsafe *(buf + (off + 2) as u64) = (val >> 16 as u32) as u8
    unsafe *(buf + (off + 3) as u64) = (val >> 24 as u32) as u8

fn u64_to_be(buf: *mut u8, off: i32, val: u64):
    u32_to_be(buf, off, (val >> 32 as u64) as u32)
    u32_to_be(buf, off + 4, val as u32)

fn u64_to_le(buf: *mut u8, off: i32, val: u64):
    u32_to_le(buf, off, val as u32)
    u32_to_le(buf, off + 4, (val >> 32 as u64) as u32)

// AES-128-GCM — Authenticated Encryption with Associated Data
// NIST SP 800-38D. AES-CTR encryption + GHASH authentication.


type AesGcm  {
    aes: Aes128,
    h: [u8; 16],
    j0: [u8; 16],
    counter: [u8; 16],
    ghash_state: [u8; 16],
    aad_len: u64,
    ct_len: u64,
}

// GHASH: multiply in GF(2^128)
unsafe fn ghash_mult(x: *const u8, y: *const u8, out: *mut u8):
    var z: [u8; 16] = [0 as u8; 16]
    var v: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        v[i] = *(y + i as u64)

    for i in 0..128:
        let byte_idx = i / 8
        let bit_idx = 7 - (i % 8)
        if ((*(x + byte_idx as u64)) as u32 >> bit_idx as u32) & 1 as u32 != 0 as u32:
            for j in 0..16:
                z[j] = z[j] ^ v[j]
        let lsb = (v[15] as u32) & 1 as u32
        var carry: u32 = 0 as u32
        for j in 0..16:
            // `old` must be the value as an owned u32: binding the bare
            // element `v[j]` yields a live view, so a later read after the
            // write below would observe the NEW byte and corrupt the carry.
            let old = v[j] as u32
            v[j] = (carry | (old >> 1 as u32)) as u8
            carry = if (old & 1 as u32) != 0 as u32: 0x80 as u32 else: 0 as u32
        if lsb != 0 as u32:
            v[0] = v[0] ^ (0xe1 as u8)

    for i in 0..16:
        *(out + i as u64) = z[i]

unsafe fn ghash_update(state: *mut u8, h: *const u8, block: *const u8):
    for i in 0..16:
        *(state + i as u64) = *(state + i as u64) ^ *(block + i as u64)
    var tmp: [u8; 16] = [0 as u8; 16]
    let tp = &raw mut tmp[0] as *mut u8
    ghash_mult(state as *const u8, h, tp)
    for i in 0..16:
        *(state + i as u64) = tmp[i]

unsafe fn increment_counter(ctr: *mut u8):
    var i = 15
    while i >= 12:
        let val = ((*(ctr + i as u64) as u32) +% 1 as u32) & 0xff as u32
        *(ctr + i as u64) = val as u8
        if val != 0 as u32:
            return
        i = i - 1

fn AesGcm.new(key: *const u8, iv: *const u8, iv_len: i32) -> AesGcm:
    let aes_ctx = Aes128.new(key)
    var h: [u8; 16] = [0 as u8; 16]
    let hp = &raw mut h[0] as *mut u8
    unsafe { Aes128.encrypt_block(&aes_ctx as *const Aes128, hp) }

    var j0: [u8; 16] = [0 as u8; 16]
    if iv_len == 12:
        for i in 0..12:
            j0[i] = unsafe *(iv + i as u64)
        j0[15] = 1 as u8

    var counter: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        counter[i] = j0[i]
    unsafe { increment_counter(&raw mut counter[0] as *mut u8) }

    AesGcm {
        aes: aes_ctx, h, j0, counter,
        ghash_state: [0 as u8; 16],
        aad_len: 0 as u64, ct_len: 0 as u64,
    }

unsafe fn aesgcm_aad(ctx: *mut AesGcm, data: *const u8, len: i32):
    ctx.aad_len = ctx.aad_len + len as u64
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        gs[i] = ctx.ghash_state[i]
        hh[i] = ctx.h[i]
    let gsp = &raw mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8
    var off = 0
    while off + 16 <= len:
        ghash_update(gsp, hhp, (data + off as u64) as *const u8)
        off = off + 16
    if off < len:
        var pad: [u8; 16] = [0 as u8; 16]
        let pp = &raw mut pad[0] as *mut u8
        for i in 0..(len - off):
            *(pp + i as u64) = *(data + (off + i) as u64)
        ghash_update(gsp, hhp, pp as *const u8)
    for i in 0..16:
        ctx.ghash_state[i] = gs[i]

unsafe fn AesGcm.aad(ctx: *mut AesGcm, data: *const u8, len: i32):
    unsafe { aesgcm_aad(ctx, data, len) }

unsafe fn aesgcm_encrypt(ctx: *mut AesGcm, pt: *const u8, ct: *mut u8, len: i32):
    ctx.ct_len = ctx.ct_len + len as u64
    var ctr: [u8; 16] = [0 as u8; 16]
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        ctr[i] = ctx.counter[i]
        gs[i] = ctx.ghash_state[i]
        hh[i] = ctx.h[i]
    let ctrp = &raw mut ctr[0] as *mut u8
    let gsp = &raw mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8
    var aes_copy = ctx.aes

    var off = 0
    while off < len:
        var ks: [u8; 16] = [0 as u8; 16]
        let ksp = &raw mut ks[0] as *mut u8
        for i in 0..16:
            *(ksp + i as u64) = ctr[i]
        Aes128.encrypt_block(&aes_copy as *const Aes128, ksp)
        increment_counter(ctrp)
        let remaining = len - off
        let chunk = if remaining < 16: remaining else: 16
        var ct_block: [u8; 16] = [0 as u8; 16]
        for i in 0..chunk:
            let ct_byte = *(pt + (off + i) as u64) ^ ks[i]
            *(ct + (off + i) as u64) = ct_byte
            ct_block[i] = ct_byte
        ghash_update(gsp, hhp, &ct_block[0] as *const u8)
        off = off + 16

    for i in 0..16:
        ctx.counter[i] = ctr[i]
        ctx.ghash_state[i] = gs[i]

unsafe fn AesGcm.encrypt(ctx: *mut AesGcm, pt: *const u8, ct: *mut u8, len: i32):
    unsafe { aesgcm_encrypt(ctx, pt, ct, len) }

// Decrypt: XOR with keystream (same as encrypt) but GHASH the INPUT (ciphertext)
unsafe fn aesgcm_decrypt(ctx: *mut AesGcm, ct_in: *const u8, pt_out: *mut u8, len: i32):
    ctx.ct_len = ctx.ct_len + len as u64
    var ctr: [u8; 16] = [0 as u8; 16]
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        ctr[i] = ctx.counter[i]
        gs[i] = ctx.ghash_state[i]
        hh[i] = ctx.h[i]
    let ctrp = &raw mut ctr[0] as *mut u8
    let gsp = &raw mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8
    var aes_copy = ctx.aes

    var off = 0
    while off < len:
        // GHASH the ciphertext BEFORE decryption
        var ct_block: [u8; 16] = [0 as u8; 16]
        let remaining = len - off
        let chunk = if remaining < 16: remaining else: 16
        for i in 0..chunk:
            let cv = *(ct_in + (off + i) as u64)
            ct_block[i] = cv
        ghash_update(gsp, hhp, &ct_block[0] as *const u8)

        // XOR with keystream to decrypt
        var ks: [u8; 16] = [0 as u8; 16]
        let ksp = &raw mut ks[0] as *mut u8
        for i in 0..16:
            *(ksp + i as u64) = ctr[i]
        Aes128.encrypt_block(&aes_copy as *const Aes128, ksp)
        increment_counter(ctrp)
        for i in 0..chunk:
            let cv = *(ct_in + (off + i) as u64)
            *(pt_out + (off + i) as u64) = cv ^ ks[i]
        off = off + 16

    for i in 0..16:
        ctx.counter[i] = ctr[i]
        ctx.ghash_state[i] = gs[i]

unsafe fn AesGcm.decrypt(ctx: *mut AesGcm, ct_in: *const u8, pt_out: *mut u8, len: i32):
    unsafe { aesgcm_decrypt(ctx, ct_in, pt_out, len) }

unsafe fn aesgcm_tag(ctx: *mut AesGcm, out: *mut u8):
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    var j0: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        gs[i] = ctx.ghash_state[i]
        hh[i] = ctx.h[i]
        j0[i] = ctx.j0[i]
    let gsp = &raw mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8

    var len_block: [u8; 16] = [0 as u8; 16]
    let lbp = &raw mut len_block[0] as *mut u8
    u64_to_be(lbp, 0, ctx.aad_len * 8 as u64)
    u64_to_be(lbp, 8, ctx.ct_len * 8 as u64)
    ghash_update(gsp, hhp, lbp as *const u8)

    var aes_copy = ctx.aes
    var j0_enc: [u8; 16] = [0 as u8; 16]
    let jp = &raw mut j0_enc[0] as *mut u8
    for i in 0..16:
        *(jp + i as u64) = j0[i]
    Aes128.encrypt_block(&aes_copy as *const Aes128, jp)

    for i in 0..16:
        *(out + i as u64) = gs[i] ^ j0_enc[i]

unsafe fn AesGcm.tag(ctx: *mut AesGcm, out: *mut u8):
    unsafe { aesgcm_tag(ctx, out) }

// Self-check against NIST SP 800-38D AES-128-GCM test case 2
// (K=0, IV=0[12], P=0[16]): ciphertext 0388dace…fe78, tag ab6e47d4…bddf.
// Returns 0 on pass, 1 if ciphertext diverges, 2 if the tag diverges.
// Guards #883 (the GHASH GF(2^128) multiply): a regression there fails here
// long before it reaches the TLS record layer.
pub fn aes128_gcm_kat() -> i32:
    var key: [u8; 16] = [0u8; 16]
    var iv: [u8; 12] = [0u8; 12]
    var pt: [u8; 16] = [0u8; 16]
    var ct: [u8; 16] = [0u8; 16]
    var tag: [u8; 16] = [0u8; 16]
    var g = AesGcm.new(&key[0] as *const u8, &iv[0] as *const u8, 12)
    unsafe:
        aesgcm_encrypt(&raw mut g as *mut AesGcm, &pt[0] as *const u8, &raw mut ct[0] as *mut u8, 16)
        aesgcm_tag(&raw mut g as *mut AesGcm, &raw mut tag[0] as *mut u8)
    let ct_exp: [u8; 16] = [0x03u8, 0x88u8, 0xdau8, 0xceu8, 0x60u8, 0xb6u8, 0xa3u8, 0x92u8, 0xf3u8, 0x28u8, 0xc2u8, 0xb9u8, 0x71u8, 0xb2u8, 0xfeu8, 0x78u8]
    let tag_exp: [u8; 16] = [0xabu8, 0x6eu8, 0x47u8, 0xd4u8, 0x2cu8, 0xecu8, 0x13u8, 0xbdu8, 0xf5u8, 0x3au8, 0x67u8, 0xb2u8, 0x12u8, 0x57u8, 0xbdu8, 0xdfu8]
    var i = 0
    while i < 16:
        if ct[i] != ct_exp[i]:
            return 1
        if tag[i] != tag_exp[i]:
            return 2
        i = i + 1
    0

use std.builtins.print_i32
fn main -> i32:
    var key: [u8; 16] = [0u8; 16]
    key[0] = 148u8
    key[1] = 136u8
    key[2] = 53u8
    key[3] = 2u8
    key[4] = 208u8
    key[5] = 156u8
    key[6] = 5u8
    key[7] = 223u8
    key[8] = 181u8
    key[9] = 109u8
    key[10] = 236u8
    key[11] = 224u8
    key[12] = 49u8
    key[13] = 123u8
    key[14] = 174u8
    key[15] = 30u8
    var iv: [u8; 12] = [0u8; 12]
    iv[0] = 67u8
    iv[1] = 163u8
    iv[2] = 61u8
    iv[3] = 37u8
    iv[4] = 213u8
    iv[5] = 74u8
    iv[6] = 223u8
    iv[7] = 53u8
    iv[8] = 132u8
    iv[9] = 58u8
    iv[10] = 6u8
    iv[11] = 237u8
    var aad: [u8; 20] = [0u8; 20]
    aad[0] = 205u8
    aad[1] = 34u8
    aad[2] = 174u8
    aad[3] = 190u8
    aad[4] = 18u8
    aad[5] = 177u8
    aad[6] = 4u8
    aad[7] = 229u8
    aad[8] = 12u8
    aad[9] = 144u8
    aad[10] = 243u8
    aad[11] = 239u8
    aad[12] = 204u8
    aad[13] = 209u8
    aad[14] = 197u8
    aad[15] = 214u8
    aad[16] = 108u8
    aad[17] = 246u8
    aad[18] = 31u8
    aad[19] = 72u8
    var ct: [u8; 48] = [0u8; 48]
    ct[0] = 172u8
    ct[1] = 136u8
    ct[2] = 158u8
    ct[3] = 228u8
    ct[4] = 221u8
    ct[5] = 176u8
    ct[6] = 31u8
    ct[7] = 118u8
    ct[8] = 30u8
    ct[9] = 3u8
    ct[10] = 102u8
    ct[11] = 110u8
    ct[12] = 39u8
    ct[13] = 183u8
    ct[14] = 83u8
    ct[15] = 0u8
    ct[16] = 40u8
    ct[17] = 141u8
    ct[18] = 120u8
    ct[19] = 243u8
    ct[20] = 204u8
    ct[21] = 101u8
    ct[22] = 14u8
    ct[23] = 63u8
    ct[24] = 61u8
    ct[25] = 1u8
    ct[26] = 234u8
    ct[27] = 154u8
    ct[28] = 94u8
    ct[29] = 160u8
    ct[30] = 111u8
    ct[31] = 14u8
    ct[32] = 45u8
    ct[33] = 198u8
    ct[34] = 145u8
    ct[35] = 255u8
    ct[36] = 120u8
    ct[37] = 210u8
    ct[38] = 161u8
    ct[39] = 63u8
    ct[40] = 97u8
    ct[41] = 223u8
    ct[42] = 30u8
    ct[43] = 53u8
    ct[44] = 109u8
    ct[45] = 150u8
    ct[46] = 86u8
    ct[47] = 241u8
    var pt: [u8; 48] = [0u8; 48]
    pt[0] = 172u8
    pt[1] = 136u8
    pt[2] = 158u8
    pt[3] = 228u8
    pt[4] = 221u8
    pt[5] = 176u8
    pt[6] = 31u8
    pt[7] = 118u8
    pt[8] = 30u8
    pt[9] = 3u8
    pt[10] = 102u8
    pt[11] = 110u8
    pt[12] = 39u8
    pt[13] = 183u8
    pt[14] = 83u8
    pt[15] = 0u8
    pt[16] = 40u8
    pt[17] = 141u8
    pt[18] = 120u8
    pt[19] = 243u8
    pt[20] = 204u8
    pt[21] = 101u8
    pt[22] = 14u8
    pt[23] = 63u8
    pt[24] = 61u8
    pt[25] = 1u8
    pt[26] = 234u8
    pt[27] = 154u8
    pt[28] = 94u8
    pt[29] = 160u8
    pt[30] = 111u8
    pt[31] = 14u8
    pt[32] = 45u8
    pt[33] = 198u8
    pt[34] = 145u8
    pt[35] = 255u8
    pt[36] = 120u8
    pt[37] = 210u8
    pt[38] = 161u8
    pt[39] = 63u8
    pt[40] = 97u8
    pt[41] = 223u8
    pt[42] = 30u8
    pt[43] = 53u8
    pt[44] = 109u8
    pt[45] = 150u8
    pt[46] = 86u8
    pt[47] = 241u8
    var exp_pt: [u8; 48] = [0u8; 48]
    exp_pt[0] = 112u8
    exp_pt[1] = 38u8
    exp_pt[2] = 24u8
    exp_pt[3] = 11u8
    exp_pt[4] = 56u8
    exp_pt[5] = 174u8
    exp_pt[6] = 215u8
    exp_pt[7] = 95u8
    exp_pt[8] = 199u8
    exp_pt[9] = 78u8
    exp_pt[10] = 45u8
    exp_pt[11] = 252u8
    exp_pt[12] = 86u8
    exp_pt[13] = 144u8
    exp_pt[14] = 229u8
    exp_pt[15] = 33u8
    exp_pt[16] = 86u8
    exp_pt[17] = 207u8
    exp_pt[18] = 105u8
    exp_pt[19] = 7u8
    exp_pt[20] = 11u8
    exp_pt[21] = 127u8
    exp_pt[22] = 182u8
    exp_pt[23] = 191u8
    exp_pt[24] = 246u8
    exp_pt[25] = 4u8
    exp_pt[26] = 186u8
    exp_pt[27] = 211u8
    exp_pt[28] = 97u8
    exp_pt[29] = 2u8
    exp_pt[30] = 130u8
    exp_pt[31] = 154u8
    exp_pt[32] = 103u8
    exp_pt[33] = 239u8
    exp_pt[34] = 71u8
    exp_pt[35] = 245u8
    exp_pt[36] = 1u8
    exp_pt[37] = 182u8
    exp_pt[38] = 182u8
    exp_pt[39] = 46u8
    exp_pt[40] = 41u8
    exp_pt[41] = 249u8
    exp_pt[42] = 252u8
    exp_pt[43] = 202u8
    exp_pt[44] = 82u8
    exp_pt[45] = 117u8
    exp_pt[46] = 138u8
    exp_pt[47] = 70u8
    var g = AesGcm.new(&key[0] as *const u8, &iv[0] as *const u8, 12)
    var gp = &raw mut g as *mut AesGcm
    unsafe {
        AesGcm.aad(gp, &aad[0] as *const u8, 20)
        AesGcm.decrypt(gp, &ct[0] as *const u8, &raw mut pt[0] as *mut u8, 48)
    }
    var q1 = 0
    while q1 < 48:
        print_i32(pt[q1] as i32)
        q1 = q1 + 1
    var g2 = AesGcm.new(&key[0] as *const u8, &iv[0] as *const u8, 12)
    var gp2 = &raw mut g2 as *mut AesGcm
    var ct2: [u8; 48] = [0u8; 48]
    var tag2: [u8; 16] = [0u8; 16]
    unsafe {
        AesGcm.aad(gp2, &aad[0] as *const u8, 20)
        AesGcm.encrypt(gp2, &exp_pt[0] as *const u8, &raw mut ct2[0] as *mut u8, 48)
        AesGcm.tag(gp2, &raw mut tag2[0] as *mut u8)
    }
    var q2 = 0
    while q2 < 48:
        print_i32(ct2[q2] as i32)
        q2 = q2 + 1
    var q3 = 0
    while q3 < 16:
        print_i32(tag2[q3] as i32)
        q3 = q3 + 1
    0
