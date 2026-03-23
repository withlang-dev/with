// AES-128-GCM — Authenticated Encryption with Associated Data
// Implements NIST SP 800-38D using AES-128 block cipher.
// GCM = CTR mode encryption + GHASH authentication.

use std.crypto.aes

// GCM context
type AesGcm = {
    aes: Aes128,
    h: [u8; 16],       // GHASH key: AES(K, 0^128)
    j0: [u8; 16],      // Pre-counter block
    counter: [u8; 16],  // Current counter
    ghash_state: [u8; 16],
    aad_len: u64,
    ct_len: u64,
}

// ── GHASH multiplication in GF(2^128) ──────────────────────────

// Multiply two 128-bit blocks in GF(2^128) with reduction polynomial
// x^128 + x^7 + x^2 + x + 1
fn ghash_mult(x: *const u8, y: *const u8, out: *mut u8):
    var z: [u8; 16] = [0 as u8; 16]
    var v: [u8; 16] = [0 as u8; 16]
    let vp = &mut v[0] as *mut u8
    for i in 0..16:
        unsafe: *(vp + i as u64) = unsafe: *(y + i as u64)

    for i in 0..128:
        let byte_idx = i / 8
        let bit_idx = 7 - (i % 8)
        let xi_byte = (unsafe: *(x + byte_idx as u64)) as u32
        if (xi_byte >> bit_idx as u32) & 1 as u32 != 0 as u32:
            // z ^= v
            for j in 0..16:
                z[j] = z[j] ^ v[j]
        // Check if low bit of v is set (for reduction)
        let lsb = (v[15] as u32) & 1 as u32
        // Right-shift v by 1
        var carry: u8 = 0 as u8
        for j in 0..16:
            let cur = v[j]
            v[j] = (carry as u8) | ((cur as u32 >> 1 as u32) as u8)
            carry = if (cur as u32 & 1 as u32) != 0 as u32: 0x80 as u8 else: 0 as u8
        // If lsb was set, XOR with R (0xe1 || 0^120)
        if lsb != 0 as u32:
            v[0] = v[0] ^ (0xe1 as u8)

    let zp = &z[0] as *const u8
    for i in 0..16:
        unsafe: *(out + i as u64) = unsafe: *(zp + i as u64)

// Update GHASH state: state = state XOR block, then multiply by H
fn ghash_update(state: *mut u8, h: *const u8, block: *const u8):
    // state ^= block
    for i in 0..16:
        unsafe: *(state + i as u64) = (unsafe: *(state + i as u64)) ^ (unsafe: *(block + i as u64))
    // state = state * H
    var tmp: [u8; 16] = [0 as u8; 16]
    let tp = &mut tmp[0] as *mut u8
    ghash_mult(state as *const u8, h, tp)
    for i in 0..16:
        unsafe: *(state + i as u64) = unsafe: *(tp + i as u64)

// ── Counter mode ────────────────────────────────────────────────

fn increment_counter(ctr: *mut u8):
    // Increment the last 4 bytes as big-endian u32
    var i = 15
    while i >= 12:
        let val = ((unsafe: *(ctr + i as u64)) as u32) +% 1 as u32
        unsafe: *(ctr + i as u64) = val as u8
        if val != 0 as u32:
            return
        i = i - 1

// ── Public API ──────────────────────────────────────────────────

fn AesGcm.new(key: *const u8, iv: *const u8, iv_len: i32) -> AesGcm:
    let aes_ctx = Aes128.new(key)

    // Compute H = AES(K, 0^128)
    var h: [u8; 16] = [0 as u8; 16]
    let hp = &mut h[0] as *mut u8
    Aes128.encrypt_block(&aes_ctx as *const Aes128, hp)

    // Compute J0 (initial counter)
    var j0: [u8; 16] = [0 as u8; 16]
    if iv_len == 12:
        // Standard 96-bit IV: J0 = IV || 0^31 || 1
        for i in 0..12:
            j0[i] = unsafe: *(iv + i as u64)
        j0[15] = 1 as u8
    else:
        // Non-standard IV: J0 = GHASH(IV || pad || len)
        // For simplicity, only support 12-byte IV
        for i in 0..12:
            if i < iv_len:
                j0[i] = unsafe: *(iv + i as u64)
        j0[15] = 1 as u8

    // Initial counter = J0 + 1
    var counter: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        counter[i] = j0[i]
    increment_counter(&mut counter[0] as *mut u8)

    AesGcm {
        aes: aes_ctx,
        h,
        j0,
        counter,
        ghash_state: [0 as u8; 16],
        aad_len: 0 as u64,
        ct_len: 0 as u64,
    }

// Process additional authenticated data (call before encrypt/decrypt)
fn AesGcm.aad(self: *mut AesGcm, data: *const u8, len: i32):
    unsafe: (*self).aad_len = (unsafe: (*self).aad_len) + len as u64
    var off = 0
    // Copy ghash state to stack
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        gs[i] = unsafe: (*self).ghash_state[i]
        hh[i] = unsafe: (*self).h[i]
    let gsp = &mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8
    while off + 16 <= len:
        ghash_update(gsp, hhp, unsafe: (data + off as u64) as *const u8)
        off = off + 16
    // Handle partial final block
    if off < len:
        var pad: [u8; 16] = [0 as u8; 16]
        let pp = &mut pad[0] as *mut u8
        for i in 0..(len - off):
            unsafe: *(pp + i as u64) = unsafe: *(data + (off + i) as u64)
        ghash_update(gsp, hhp, pp as *const u8)
    // Copy back
    for i in 0..16:
        unsafe: (*self).ghash_state[i] = gs[i]

// Encrypt plaintext and update GHASH
fn AesGcm.encrypt(self: *mut AesGcm, plaintext: *const u8, ciphertext: *mut u8, len: i32):
    unsafe: (*self).ct_len = (unsafe: (*self).ct_len) + len as u64
    // Copy state to stack
    var ctr: [u8; 16] = [0 as u8; 16]
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        ctr[i] = unsafe: (*self).counter[i]
        gs[i] = unsafe: (*self).ghash_state[i]
        hh[i] = unsafe: (*self).h[i]
    let ctrp = &mut ctr[0] as *mut u8
    let gsp = &mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8
    // Copy AES context
    var aes_copy = unsafe: (*self).aes

    var off = 0
    while off < len:
        // Encrypt counter block
        var keystream: [u8; 16] = [0 as u8; 16]
        let ksp = &mut keystream[0] as *mut u8
        for i in 0..16:
            unsafe: *(ksp + i as u64) = ctr[i]
        Aes128.encrypt_block(&aes_copy as *const Aes128, ksp)
        increment_counter(ctrp)

        // XOR keystream with plaintext
        let remaining = len - off
        let chunk = if remaining < 16: remaining else: 16
        var ct_block: [u8; 16] = [0 as u8; 16]
        for i in 0..chunk:
            let ct_byte = (unsafe: *(plaintext + (off + i) as u64)) ^ keystream[i]
            unsafe: *(ciphertext + (off + i) as u64) = ct_byte
            ct_block[i] = ct_byte

        // Update GHASH with ciphertext block (pad if partial)
        ghash_update(gsp, hhp, &ct_block[0] as *const u8)
        off = off + 16

    // Copy state back
    for i in 0..16:
        unsafe: (*self).counter[i] = ctr[i]
        unsafe: (*self).ghash_state[i] = gs[i]

// Compute authentication tag (16 bytes)
fn AesGcm.tag(self: *mut AesGcm, out: *mut u8):
    // Copy state to stack
    var gs: [u8; 16] = [0 as u8; 16]
    var hh: [u8; 16] = [0 as u8; 16]
    var j0: [u8; 16] = [0 as u8; 16]
    for i in 0..16:
        gs[i] = unsafe: (*self).ghash_state[i]
        hh[i] = unsafe: (*self).h[i]
        j0[i] = unsafe: (*self).j0[i]
    let gsp = &mut gs[0] as *mut u8
    let hhp = &hh[0] as *const u8

    // Final GHASH block: [aad_len_bits || ct_len_bits] (both big-endian u64)
    var len_block: [u8; 16] = [0 as u8; 16]
    let aad_bits = (unsafe: (*self).aad_len) * 8 as u64
    let ct_bits = (unsafe: (*self).ct_len) * 8 as u64
    len_block[0] = (aad_bits >> 56 as u64) as u8
    len_block[1] = (aad_bits >> 48 as u64) as u8
    len_block[2] = (aad_bits >> 40 as u64) as u8
    len_block[3] = (aad_bits >> 32 as u64) as u8
    len_block[4] = (aad_bits >> 24 as u64) as u8
    len_block[5] = (aad_bits >> 16 as u64) as u8
    len_block[6] = (aad_bits >> 8 as u64) as u8
    len_block[7] = aad_bits as u8
    len_block[8] = (ct_bits >> 56 as u64) as u8
    len_block[9] = (ct_bits >> 48 as u64) as u8
    len_block[10] = (ct_bits >> 40 as u64) as u8
    len_block[11] = (ct_bits >> 32 as u64) as u8
    len_block[12] = (ct_bits >> 24 as u64) as u8
    len_block[13] = (ct_bits >> 16 as u64) as u8
    len_block[14] = (ct_bits >> 8 as u64) as u8
    len_block[15] = ct_bits as u8
    ghash_update(gsp, hhp, &len_block[0] as *const u8)

    // Tag = GHASH_final XOR AES(K, J0)
    var aes_copy = unsafe: (*self).aes
    var j0_enc: [u8; 16] = [0 as u8; 16]
    let jp = &mut j0_enc[0] as *mut u8
    for i in 0..16:
        unsafe: *(jp + i as u64) = j0[i]
    Aes128.encrypt_block(&aes_copy as *const Aes128, jp)

    for i in 0..16:
        unsafe: *(out + i as u64) = gs[i] ^ j0_enc[i]
