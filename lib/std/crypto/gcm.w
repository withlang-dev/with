// AES-128-GCM — Authenticated Encryption with Associated Data
// NIST SP 800-38D. AES-CTR encryption + GHASH authentication.

use std.crypto.aes
use std.crypto.endian

type AesGcm = {
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
        var carry: u8 = 0 as u8
        for j in 0..16:
            let cur = v[j]
            v[j] = carry | ((cur as u32 >> 1 as u32) as u8)
            carry = if (cur as u32 & 1 as u32) != 0 as u32: 0x80 as u8 else: 0 as u8
        if lsb != 0 as u32:
            v[0] = v[0] ^ (0xe1 as u8)

    for i in 0..16:
        *(out + i as u64) = z[i]

unsafe fn ghash_update(state: *mut u8, h: *const u8, block: *const u8):
    for i in 0..16:
        *(state + i as u64) = *(state + i as u64) ^ *(block + i as u64)
    var tmp: [u8; 16] = [0 as u8; 16]
    let tp = &mut tmp[0] as *mut u8
    ghash_mult(state as *const u8, h, tp)
    for i in 0..16:
        *(state + i as u64) = tmp[i]

unsafe fn increment_counter(ctr: *mut u8):
    var i = 15
    while i >= 12:
        let val = (*(ctr + i as u64) as u32) +% 1 as u32
        *(ctr + i as u64) = val as u8
        if val != 0 as u32:
            return
        i = i - 1

fn AesGcm.new(key: *const u8, iv: *const u8, iv_len: i32) -> AesGcm:
    let aes_ctx = Aes128.new(key)
    var h: [u8; 16] = [0 as u8; 16]
    let hp = &mut h[0] as *mut u8
    Aes128.encrypt_block(&aes_ctx as *const Aes128, hp)

    var j0: [u8; 16] = [0 as u8; 16]
    if iv_len == 12:
        for i in 0..12:
            j0[i] = unsafe: *(iv + i as u64)
        j0[15] = 1 as u8

    var counter: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        counter[i] = j0[i]
    unsafe: increment_counter(&mut counter[0] as *mut u8)

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
    let gsp = &mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8
    var off = 0
    while off + 16 <= len:
        ghash_update(gsp, hhp, (data + off as u64) as *const u8)
        off = off + 16
    if off < len:
        var pad: [u8; 16] = [0 as u8; 16]
        let pp = &mut pad[0] as *mut u8
        for i in 0..(len - off):
            *(pp + i as u64) = *(data + (off + i) as u64)
        ghash_update(gsp, hhp, pp as *const u8)
    for i in 0..16:
        ctx.ghash_state[i] = gs[i]

fn AesGcm.aad(self: *mut AesGcm, data: *const u8, len: i32):
    unsafe: aesgcm_aad(self, data, len)

unsafe fn aesgcm_encrypt(ctx: *mut AesGcm, pt: *const u8, ct: *mut u8, len: i32):
    ctx.ct_len = ctx.ct_len + len as u64
    var ctr: [u8; 16] = [0 as u8; 16]
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        ctr[i] = ctx.counter[i]
        gs[i] = ctx.ghash_state[i]
        hh[i] = ctx.h[i]
    let ctrp = &mut ctr[0] as *mut u8
    let gsp = &mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8
    var aes_copy = ctx.aes

    var off = 0
    while off < len:
        var ks: [u8; 16] = [0 as u8; 16]
        let ksp = &mut ks[0] as *mut u8
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

fn AesGcm.encrypt(self: *mut AesGcm, pt: *const u8, ct: *mut u8, len: i32):
    unsafe: aesgcm_encrypt(self, pt, ct, len)

unsafe fn aesgcm_tag(ctx: *mut AesGcm, out: *mut u8):
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    var j0: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        gs[i] = ctx.ghash_state[i]
        hh[i] = ctx.h[i]
        j0[i] = ctx.j0[i]
    let gsp = &mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8

    var len_block: [u8; 16] = [0 as u8; 16]
    let lbp = &mut len_block[0] as *mut u8
    u64_to_be(lbp, 0, ctx.aad_len * 8 as u64)
    u64_to_be(lbp, 8, ctx.ct_len * 8 as u64)
    ghash_update(gsp, hhp, lbp as *const u8)

    var aes_copy = ctx.aes
    var j0_enc: [u8; 16] = [0 as u8; 16]
    let jp = &mut j0_enc[0] as *mut u8
    for i in 0..16:
        *(jp + i as u64) = j0[i]
    Aes128.encrypt_block(&aes_copy as *const Aes128, jp)

    for i in 0..16:
        *(out + i as u64) = gs[i] ^ j0_enc[i]

fn AesGcm.tag(self: *mut AesGcm, out: *mut u8):
    unsafe: aesgcm_tag(self, out)
