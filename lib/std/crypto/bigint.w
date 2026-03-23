// Big integer arithmetic — i31 format (31-bit limbs)
// Ported from BearSSL src/int/i31_*.c
//
// Format: x is a *mut u32 array where:
//   x[0] = announced bit length
//   x[1..] = 31-bit limbs, least significant first
//   Each limb value is in [0, 2^31 - 1]
//   Word count = (x[0] + 30) / 31

// Number of 31-bit words needed for a given bit length.
fn i31_word_count(bitlen: u32) -> i32:
    let r = (bitlen + 30 as u32) / 31 as u32
    r as i32

// Set x to zero with the given announced bit length.
unsafe fn i31_zero(x: *mut u32, bitlen: u32):
    *(x + 0 as u64) = bitlen
    let n = i31_word_count(bitlen)
    var i = 0
    while i < n:
        *(x + (1 + i) as u64) = 0 as u32
        i = i + 1

// Decode a big-endian byte array into i31 format.
unsafe fn i31_decode(x: *mut u32, src: *const u8, len: i32):
    // Compute actual bit length from leading zeros
    var bitlen: u32 = 0 as u32
    var found = 0
    var si = 0
    while si < len:
        let b_raw = *(src + si as u64)
        let b = b_raw as u32
        if found == 0 and b != 0 as u32:
            found = 1
            var top = b
            var bits: u32 = 0 as u32
            while top != 0 as u32:
                bits +%= 1 as u32
                top = top >> 1 as u32
            bitlen = ((len - si - 1) as u32) * 8 as u32 + bits
            si = len
        si = si + 1

    if found == 0:
        *(x + 0 as u64) = 0 as u32
        return

    *(x + 0 as u64) = bitlen
    let n = i31_word_count(bitlen)
    var zi = 0
    while zi < n:
        *(x + (1 + zi) as u64) = 0 as u32
        zi = zi + 1

    // Fill limbs from least significant byte
    var acc: u64 = 0 as u64
    var acc_len: u32 = 0 as u32
    var word_idx = 1
    var byte_idx = len - 1
    while byte_idx >= 0:
        let raw = *(src + byte_idx as u64)
        let b = raw as u64
        acc = acc | (b << acc_len as u64)
        acc_len +%= 8 as u32
        while acc_len >= 31 as u32:
            let w = acc as u32
            *(x + word_idx as u64) = w & 0x7FFFFFFF as u32
            acc = acc >> 31 as u64
            acc_len -%= 31 as u32
            word_idx = word_idx + 1
        byte_idx = byte_idx - 1
    if acc_len > 0 as u32 and word_idx <= n:
        let w = acc as u32
        *(x + word_idx as u64) = w & 0x7FFFFFFF as u32

// Decode and reduce modulo m. Result is in [0, m-1].
unsafe fn i31_decode_reduce(x: *mut u32, src: *const u8, len: i32, m: *const u32):
    let m_bitlen = *(m + 0 as u64)
    let mlen = i31_word_count(m_bitlen)

    i31_zero(x, m_bitlen)

    // Process source bytes from MSB to LSB.
    // For each byte: x = (x << 8) + byte, then reduce mod m.
    var si = 0
    while si < len:
        let raw = *(src + si as u64)
        var acc: u64 = raw as u64
        var j = 1
        while j <= mlen:
            let cur = *(x + j as u64)
            acc = acc | ((cur as u64) << 8 as u64)
            let w = acc as u32
            *(x + j as u64) = w & 0x7FFFFFFF as u32
            acc = acc >> 31 as u64
            j = j + 1
        i31_reduce_once(x, m, mlen)
        si = si + 1

// Single conditional reduction: if x >= m, subtract m.
unsafe fn i31_reduce_once(x: *mut u32, m: *const u32, mlen: i32):
    var borrow: u32 = 0 as u32
    var i = 1
    while i <= mlen:
        let xi = *(x + i as u64)
        let mi = *(m + i as u64)
        let diff = (xi as u64) -% (mi as u64) -% (borrow as u64)
        let db = diff >> 63 as u64
        borrow = db as u32
        i = i + 1
    let ctl = 1 as u32 -% borrow
    i31_sub(x, m, ctl)

// Encode i31 number to big-endian byte array.
unsafe fn i31_encode(dst: *mut u8, len: i32, x: *const u32):
    var di = 0
    while di < len:
        *(dst + di as u64) = 0 as u8
        di = di + 1

    let n = i31_word_count(*(x + 0 as u64))
    var acc: u64 = 0 as u64
    var acc_len: u32 = 0 as u32
    var byte_idx = len - 1
    var word_idx = 1
    while byte_idx >= 0:
        if acc_len < 8 as u32 and word_idx <= n:
            let w = *(x + word_idx as u64)
            acc = acc | ((w as u64) << acc_len as u64)
            acc_len +%= 31 as u32
            word_idx = word_idx + 1
        let lo = acc as u32
        *(dst + byte_idx as u64) = (lo & 0xFF as u32) as u8
        acc = acc >> 8 as u64
        if acc_len >= 8 as u32:
            acc_len -%= 8 as u32
        else:
            acc_len = 0 as u32
        byte_idx = byte_idx - 1

// Conditional addition: if ctl == 1, a += b. Returns carry.
unsafe fn i31_add(a: *mut u32, b: *const u32, ctl: u32) -> u32:
    let n = i31_word_count(*(a + 0 as u64))
    var carry: u32 = 0 as u32
    var i = 1
    while i <= n:
        let ai = *(a + i as u64)
        let bi = *(b + i as u64)
        let sum = ai +% bi +% carry
        carry = sum >> 31 as u32
        let new_val = sum & 0x7FFFFFFF as u32
        *(a + i as u64) = ai ^ (ctl & (ai ^ new_val))
        i = i + 1
    carry & ctl

// Conditional subtraction: if ctl == 1, a -= b. Returns borrow.
unsafe fn i31_sub(a: *mut u32, b: *const u32, ctl: u32) -> u32:
    let n = i31_word_count(*(a + 0 as u64))
    var borrow: u32 = 0 as u32
    var i = 1
    while i <= n:
        let ai = *(a + i as u64)
        let bi = *(b + i as u64)
        let diff = ai -% bi -% borrow
        borrow = diff >> 31 as u32
        let new_val = diff & 0x7FFFFFFF as u32
        *(a + i as u64) = ai ^ (ctl & (ai ^ new_val))
        i = i + 1
    borrow & ctl

// Compute -1/x mod 2^31. x must be odd.
fn i31_ninv31(x: u32) -> u32:
    var y: u32 = 2 as u32 -% x
    y = y *% (2 as u32 -% (y *% x))
    y = y *% (2 as u32 -% (y *% x))
    y = y *% (2 as u32 -% (y *% x))
    y = y *% (2 as u32 -% (y *% x))
    (0 as u32 -% y) & 0x7FFFFFFF as u32

// Montgomery multiplication: d = (x * y * R^-1) mod m
// where R = 2^(31*mlen). m0i = -1/m[1] mod 2^31.
unsafe fn i31_montmul(d: *mut u32, x: *const u32, y: *const u32, m: *const u32, m0i: u32):
    let mlen = i31_word_count(*(m + 0 as u64))

    *(d + 0 as u64) = *(m + 0 as u64)
    var ci = 0
    while ci < mlen:
        *(d + (1 + ci) as u64) = 0 as u32
        ci = ci + 1

    var i = 1
    while i <= mlen:
        let xi = *(x + i as u64)

        // u = (d[1] + xi*y[1]) * m0i mod 2^31
        let d1 = *(d + 1 as u64)
        let y1 = *(y + 1 as u64)
        let m1 = *(m + 1 as u64)
        let dy1: u64 = (d1 as u64) + (xi as u64) * (y1 as u64)
        let dy1_lo = dy1 as u32
        let u = (dy1_lo *% m0i) & 0x7FFFFFFF as u32

        // d = (d + xi*y + u*m) / 2^31
        var carry: u64 = (d1 as u64) + (xi as u64) * (y1 as u64) + (u as u64) * (m1 as u64)
        carry = carry >> 31 as u64

        var j = 2
        while j <= mlen:
            let dj = *(d + j as u64)
            let yj = *(y + j as u64)
            let mj = *(m + j as u64)
            carry = carry + (dj as u64) + (xi as u64) * (yj as u64) + (u as u64) * (mj as u64)
            let cw = carry as u32
            *(d + (j - 1) as u64) = cw & 0x7FFFFFFF as u32
            carry = carry >> 31 as u64
            j = j + 1

        let cw = carry as u32
        *(d + mlen as u64) = cw
        i = i + 1

    i31_reduce_once(d, m, mlen)

// Convert x to Montgomery form: x = x * R mod m
unsafe fn i31_to_monty(x: *mut u32, m: *const u32):
    let mlen = i31_word_count(*(m + 0 as u64))
    let total_bits = mlen * 31
    var bi = 0
    while bi < total_bits:
        var carry: u32 = 0 as u32
        var j = 1
        while j <= mlen:
            let w = *(x + j as u64)
            *(x + j as u64) = ((w << 1 as u32) | carry) & 0x7FFFFFFF as u32
            carry = w >> 30 as u32
            j = j + 1
        i31_reduce_once(x, m as *const u32, mlen)
        bi = bi + 1

// Convert x from Montgomery form: x = x * R^-1 mod m
unsafe fn i31_from_monty(x: *mut u32, m: *const u32, m0i: u32):
    let mlen = i31_word_count(*(m + 0 as u64))
    var one: [u32; 80] = [0 as u32; 80]
    let op = &mut one[0] as *mut u32
    *(op + 0 as u64) = *(m + 0 as u64)
    *(op + 1 as u64) = 1 as u32
    var d: [u32; 80] = [0 as u32; 80]
    let dp = &mut d[0] as *mut u32
    i31_montmul(dp, x as *const u32, op as *const u32, m, m0i)
    var ci = 0
    while ci <= mlen:
        *(x + ci as u64) = d[ci]
        ci = ci + 1

// Modular exponentiation: x = x^e mod m
// e is big-endian byte array of length elen.
// t1, t2 are temporary buffers (same size as x).
unsafe fn i31_modpow(x: *mut u32, e: *const u8, elen: i32, m: *const u32, m0i: u32, t1: *mut u32, t2: *mut u32):
    let mlen = i31_word_count(*(m + 0 as u64))

    // Convert x to Montgomery form
    i31_to_monty(x, m)

    // t1 = R mod m (Montgomery form of 1)
    *(t1 + 0 as u64) = *(m + 0 as u64)
    var zi = 1
    while zi <= mlen:
        *(t1 + zi as u64) = 0 as u32
        zi = zi + 1
    *(t1 + 1 as u64) = 1 as u32
    i31_to_monty(t1, m)

    // Square-and-multiply, MSB first
    var ei = 0
    while ei < elen:
        let raw = *(e + ei as u64)
        let byte = raw as u32
        var bj = 0
        while bj < 8:
            let bit = (byte >> (7 - bj) as u32) & 1 as u32

            // t1 = t1^2 mod m
            i31_montmul(t2, t1 as *const u32, t1 as *const u32, m, m0i)
            var ck = 0
            while ck <= mlen:
                *(t1 + ck as u64) = *(t2 + ck as u64)
                ck = ck + 1

            // If bit == 1: t1 = t1 * x mod m
            if bit != 0 as u32:
                i31_montmul(t2, t1 as *const u32, x as *const u32, m, m0i)
                ck = 0
                while ck <= mlen:
                    *(t1 + ck as u64) = *(t2 + ck as u64)
                    ck = ck + 1

            bj = bj + 1
        ei = ei + 1

    // Convert from Montgomery and copy to x
    i31_from_monty(t1, m, m0i)
    var fi = 0
    while fi <= mlen:
        *(x + fi as u64) = *(t1 + fi as u64)
        fi = fi + 1

// Compare: returns 1 if a >= b, 0 otherwise.
unsafe fn i31_gte(a: *const u32, b: *const u32) -> u32:
    let n = i31_word_count(*(a + 0 as u64))
    var borrow: u32 = 0 as u32
    var i = 1
    while i <= n:
        let ai = *(a + i as u64)
        let bi = *(b + i as u64)
        let diff = (ai as u64) -% (bi as u64) -% (borrow as u64)
        let db = diff >> 63 as u64
        borrow = db as u32
        i = i + 1
    1 as u32 -% borrow

// Check if x is zero.
unsafe fn i31_is_zero(x: *const u32) -> u32:
    let n = i31_word_count(*(x + 0 as u64))
    var acc: u32 = 0 as u32
    var i = 1
    while i <= n:
        acc = acc | *(x + i as u64)
        i = i + 1
    let z = acc | (0 as u32 -% acc)
    1 as u32 -% (z >> 31 as u32)
