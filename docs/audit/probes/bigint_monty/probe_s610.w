// Big integer arithmetic — i31 format (31-bit limbs)
// Ported from BearSSL src/int/i31_*.c
//
// Format: x is a *mut u32 array where:
//   x[0] = announced bit length
//   x[1..] = 31-bit limbs, least significant first
//   Each limb value is in [0, 2^31 - 1]
//   Word count = (x[0] + 30) / 31

fn i31_word_count(bitlen: u32) -> i32:
    let r = (bitlen + 30u32) / 31u32
    r as i32

unsafe fn i31_zero(x: *mut u32, bitlen: u32):
    *(x + 0u64) = bitlen
    let n = i31_word_count(bitlen)
    var i = 0
    while i < n:
        *(x + (1 + i) as u64) = 0u32
        i = i + 1

unsafe fn i31_decode(x: *mut u32, src: *const u8, len: i32):
    var bitlen: u32 = 0u32
    var found = 0
    var si = 0
    while si < len:
        let b_raw = *(src + si as u64)
        let b = b_raw as u32
        if found == 0 and b != 0u32:
            found = 1
            var top = b
            var bits: u32 = 0u32
            while top != 0u32:
                bits +%= 1u32
                top = top >> 1u32
            bitlen = ((len - si - 1) as u32) * 8u32 + bits
            si = len
        si = si + 1

    if found == 0:
        *(x + 0u64) = 0u32
        return

    *(x + 0u64) = bitlen
    let n = i31_word_count(bitlen)
    var zi = 0
    while zi < n:
        *(x + (1 + zi) as u64) = 0u32
        zi = zi + 1

    var acc: u64 = 0u64
    var acc_len: u32 = 0u32
    var word_idx = 1
    var byte_idx = len - 1
    while byte_idx >= 0:
        let raw = *(src + byte_idx as u64)
        let b = raw as u64
        acc = acc | (b << acc_len as u64)
        acc_len +%= 8u32
        while acc_len >= 31u32:
            let w = acc as u32
            *(x + word_idx as u64) = w & 0x7FFFFFFFu32
            acc = acc >> 31u64
            acc_len -%= 31u32
            word_idx = word_idx + 1
        byte_idx = byte_idx - 1
    if acc_len > 0u32 and word_idx <= n:
        let w = acc as u32
        *(x + word_idx as u64) = w & 0x7FFFFFFFu32

unsafe fn i31_decode_reduce(x: *mut u32, src: *const u8, len: i32, m: *const u32):
    let m_bitlen = *(m + 0u64)
    let mlen = i31_word_count(m_bitlen)
    i31_zero(x, m_bitlen)
    var si = 0
    while si < len:
        let raw = *(src + si as u64)
        var acc: u64 = raw as u64
        var j = 1
        while j <= mlen:
            let cur = *(x + j as u64)
            acc = acc | ((cur as u64) << 8u64)
            let w = acc as u32
            *(x + j as u64) = w & 0x7FFFFFFFu32
            acc = acc >> 31u64
            j = j + 1
        i31_reduce_once(x, m, mlen)
        si = si + 1

unsafe fn i31_reduce_once(x: *mut u32, m: *const u32, mlen: i32):
    var borrow: u32 = 0u32
    var i = 1
    while i <= mlen:
        let xi = *(x + i as u64)
        let mi = *(m + i as u64)
        let diff = (xi as u64) -% (mi as u64) -% (borrow as u64)
        let db = diff >> 63u64
        borrow = db as u32
        i = i + 1
    let not_borrow = 1u32 -% borrow
    let ctl = 0u32 -% not_borrow
    i31_sub(x, m, ctl)

unsafe fn i31_encode(dst: *mut u8, len: i32, x: *const u32):
    var di = 0
    while di < len:
        *(dst + di as u64) = 0u8
        di = di + 1
    let n = i31_word_count(*(x + 0u64))
    var acc: u64 = 0u64
    var acc_len: u32 = 0u32
    var byte_idx = len - 1
    var word_idx = 1
    while byte_idx >= 0:
        if acc_len < 8u32 and word_idx <= n:
            let w = *(x + word_idx as u64)
            acc = acc | ((w as u64) << acc_len as u64)
            acc_len +%= 31u32
            word_idx = word_idx + 1
        let lo = acc as u32
        *(dst + byte_idx as u64) = (lo & 0xFFu32) as u8
        acc = acc >> 8u64
        if acc_len >= 8u32:
            acc_len -%= 8u32
        else:
            acc_len = 0u32
        byte_idx = byte_idx - 1

unsafe fn i31_add(a: *mut u32, b: *const u32, ctl: u32) -> u32:
    let n = i31_word_count(*(a + 0u64))
    var carry: u32 = 0u32
    var i = 1
    while i <= n:
        let ai = *(a + i as u64)
        let bi = *(b + i as u64)
        let sum = ai +% bi +% carry
        carry = sum >> 31u32
        let new_val = sum & 0x7FFFFFFFu32
        *(a + i as u64) = ai ^ (ctl & (ai ^ new_val))
        i = i + 1
    carry & ctl

unsafe fn i31_sub(a: *mut u32, b: *const u32, ctl: u32) -> u32:
    let n = i31_word_count(*(a + 0u64))
    var borrow: u32 = 0u32
    var i = 1
    while i <= n:
        let ai = *(a + i as u64)
        let bi = *(b + i as u64)
        let diff = ai -% bi -% borrow
        borrow = diff >> 31u32
        let new_val = diff & 0x7FFFFFFFu32
        *(a + i as u64) = ai ^ (ctl & (ai ^ new_val))
        i = i + 1
    borrow & ctl

fn i31_ninv31(x: u32) -> u32:
    var y: u32 = 2u32 -% x
    y = y *% (2u32 -% (y *% x))
    y = y *% (2u32 -% (y *% x))
    y = y *% (2u32 -% (y *% x))
    y = y *% (2u32 -% (y *% x))
    (0u32 -% y) & 0x7FFFFFFFu32

unsafe fn i31_montmul(d: *mut u32, x: *const u32, y: *const u32, m: *const u32, m0i: u32):
    let mlen = i31_word_count(*(m + 0u64))
    *(d + 0u64) = *(m + 0u64)
    var ci = 0
    while ci < mlen:
        *(d + (1 + ci) as u64) = 0u32
        ci = ci + 1
    var i = 1
    while i <= mlen:
        let xi = *(x + i as u64)
        let d1 = *(d + 1u64)
        let y1 = *(y + 1u64)
        let m1 = *(m + 1u64)
        let dy1: u64 = (d1 as u64) + (xi as u64) * (y1 as u64)
        let dy1_lo = dy1 as u32
        let u = (dy1_lo *% m0i) & 0x7FFFFFFFu32
        var carry: u64 = (d1 as u64) + (xi as u64) * (y1 as u64) + (u as u64) * (m1 as u64)
        carry = carry >> 31u64
        var j = 2
        while j <= mlen:
            let dj = *(d + j as u64)
            let yj = *(y + j as u64)
            let mj = *(m + j as u64)
            carry = carry + (dj as u64) + (xi as u64) * (yj as u64) + (u as u64) * (mj as u64)
            let cw = carry as u32
            *(d + (j - 1) as u64) = cw & 0x7FFFFFFFu32
            carry = carry >> 31u64
            j = j + 1
        let cw = carry as u32
        *(d + mlen as u64) = cw
        i = i + 1
    i31_reduce_once(d, m, mlen)

unsafe fn i31_to_monty(x: *mut u32, m: *const u32):
    let mlen = i31_word_count(*(m + 0u64))
    let total_bits = mlen * 31
    var bi = 0
    while bi < total_bits:
        var carry: u32 = 0u32
        var j = 1
        while j <= mlen:
            let w = *(x + j as u64)
            *(x + j as u64) = ((w << 1u32) | carry) & 0x7FFFFFFFu32
            carry = w >> 30u32
            j = j + 1
        i31_reduce_once(x, m as *const u32, mlen)
        bi = bi + 1

unsafe fn i31_from_monty(x: *mut u32, m: *const u32, m0i: u32):
    let mlen = i31_word_count(*(m + 0u64))
    var one: [u32; 80] = [0u32; 80]
    let op = &raw mut one[0] as *mut u32
    *(op + 0u64) = *(m + 0u64)
    *(op + 1u64) = 1u32
    var d: [u32; 80] = [0u32; 80]
    let dp = &raw mut d[0] as *mut u32
    i31_montmul(dp, x as *const u32, op as *const u32, m, m0i)
    var ci = 0
    while ci <= mlen:
        *(x + ci as u64) = d[ci]
        ci = ci + 1

unsafe fn i31_modpow(x: *mut u32, e: *const u8, elen: i32, m: *const u32, m0i: u32, t1: *mut u32, t2: *mut u32):
    let mlen = i31_word_count(*(m + 0u64))
    i31_to_monty(x, m)
    *(t1 + 0u64) = *(m + 0u64)
    var zi = 1
    while zi <= mlen:
        *(t1 + zi as u64) = 0u32
        zi = zi + 1
    *(t1 + 1u64) = 1u32
    i31_to_monty(t1, m)
    var ei = 0
    while ei < elen:
        let raw = *(e + ei as u64)
        let byte = raw as u32
        var bj = 0
        while bj < 8:
            let bit = (byte >> (7 - bj) as u32) & 1u32
            i31_montmul(t2, t1 as *const u32, t1 as *const u32, m, m0i)
            var ck = 0
            while ck <= mlen:
                *(t1 + ck as u64) = *(t2 + ck as u64)
                ck = ck + 1
            if bit != 0u32:
                i31_montmul(t2, t1 as *const u32, x as *const u32, m, m0i)
                ck = 0
                while ck <= mlen:
                    *(t1 + ck as u64) = *(t2 + ck as u64)
                    ck = ck + 1
            bj = bj + 1
        ei = ei + 1
    i31_from_monty(t1, m, m0i)
    var fi = 0
    while fi <= mlen:
        *(x + fi as u64) = *(t1 + fi as u64)
        fi = fi + 1

unsafe fn i31_gte(a: *const u32, b: *const u32) -> u32:
    let n = i31_word_count(*(a + 0u64))
    var borrow: u32 = 0u32
    var i = 1
    while i <= n:
        let ai = *(a + i as u64)
        let bi = *(b + i as u64)
        let diff = (ai as u64) -% (bi as u64) -% (borrow as u64)
        let db = diff >> 63u64
        borrow = db as u32
        i = i + 1
    1u32 -% borrow

unsafe fn i31_is_zero(x: *const u32) -> u32:
    let n = i31_word_count(*(x + 0u64))
    var acc: u32 = 0u32
    var i = 1
    while i <= n:
        acc = acc | *(x + i as u64)
        i = i + 1
    let z = acc | (0u32 -% acc)
    1u32 -% (z >> 31u32)

fn main -> i32:
    var m_bytes: [u8; 77] = [0u8; 77]
    var x_bytes: [u8; 77] = [0u8; 77]
    var e_bytes: [u8; 3] = [0u8; 3]
    var want: [u8; 77] = [0u8; 77]
    m_bytes[0] = 2u8
    m_bytes[1] = 0u8
    m_bytes[2] = 0u8
    m_bytes[3] = 0u8
    m_bytes[4] = 0u8
    m_bytes[5] = 0u8
    m_bytes[6] = 0u8
    m_bytes[7] = 0u8
    m_bytes[8] = 0u8
    m_bytes[9] = 0u8
    m_bytes[10] = 0u8
    m_bytes[11] = 0u8
    m_bytes[12] = 0u8
    m_bytes[13] = 0u8
    m_bytes[14] = 0u8
    m_bytes[15] = 0u8
    m_bytes[16] = 0u8
    m_bytes[17] = 0u8
    m_bytes[18] = 0u8
    m_bytes[19] = 0u8
    m_bytes[20] = 0u8
    m_bytes[21] = 0u8
    m_bytes[22] = 0u8
    m_bytes[23] = 0u8
    m_bytes[24] = 0u8
    m_bytes[25] = 0u8
    m_bytes[26] = 0u8
    m_bytes[27] = 0u8
    m_bytes[28] = 0u8
    m_bytes[29] = 0u8
    m_bytes[30] = 0u8
    m_bytes[31] = 0u8
    m_bytes[32] = 0u8
    m_bytes[33] = 0u8
    m_bytes[34] = 0u8
    m_bytes[35] = 0u8
    m_bytes[36] = 0u8
    m_bytes[37] = 0u8
    m_bytes[38] = 2u8
    m_bytes[39] = 0u8
    m_bytes[40] = 0u8
    m_bytes[41] = 0u8
    m_bytes[42] = 0u8
    m_bytes[43] = 0u8
    m_bytes[44] = 0u8
    m_bytes[45] = 0u8
    m_bytes[46] = 0u8
    m_bytes[47] = 0u8
    m_bytes[48] = 0u8
    m_bytes[49] = 0u8
    m_bytes[50] = 0u8
    m_bytes[51] = 0u8
    m_bytes[52] = 0u8
    m_bytes[53] = 0u8
    m_bytes[54] = 0u8
    m_bytes[55] = 0u8
    m_bytes[56] = 0u8
    m_bytes[57] = 0u8
    m_bytes[58] = 0u8
    m_bytes[59] = 0u8
    m_bytes[60] = 0u8
    m_bytes[61] = 0u8
    m_bytes[62] = 0u8
    m_bytes[63] = 0u8
    m_bytes[64] = 0u8
    m_bytes[65] = 0u8
    m_bytes[66] = 0u8
    m_bytes[67] = 0u8
    m_bytes[68] = 0u8
    m_bytes[69] = 0u8
    m_bytes[70] = 0u8
    m_bytes[71] = 0u8
    m_bytes[72] = 0u8
    m_bytes[73] = 0u8
    m_bytes[74] = 0u8
    m_bytes[75] = 0u8
    m_bytes[76] = 1u8
    x_bytes[0] = 0u8
    x_bytes[1] = 0u8
    x_bytes[2] = 0u8
    x_bytes[3] = 0u8
    x_bytes[4] = 0u8
    x_bytes[5] = 0u8
    x_bytes[6] = 0u8
    x_bytes[7] = 0u8
    x_bytes[8] = 0u8
    x_bytes[9] = 0u8
    x_bytes[10] = 0u8
    x_bytes[11] = 0u8
    x_bytes[12] = 0u8
    x_bytes[13] = 0u8
    x_bytes[14] = 0u8
    x_bytes[15] = 0u8
    x_bytes[16] = 0u8
    x_bytes[17] = 0u8
    x_bytes[18] = 0u8
    x_bytes[19] = 0u8
    x_bytes[20] = 0u8
    x_bytes[21] = 0u8
    x_bytes[22] = 0u8
    x_bytes[23] = 0u8
    x_bytes[24] = 0u8
    x_bytes[25] = 0u8
    x_bytes[26] = 0u8
    x_bytes[27] = 0u8
    x_bytes[28] = 0u8
    x_bytes[29] = 0u8
    x_bytes[30] = 0u8
    x_bytes[31] = 0u8
    x_bytes[32] = 0u8
    x_bytes[33] = 0u8
    x_bytes[34] = 0u8
    x_bytes[35] = 0u8
    x_bytes[36] = 0u8
    x_bytes[37] = 0u8
    x_bytes[38] = 0u8
    x_bytes[39] = 0u8
    x_bytes[40] = 0u8
    x_bytes[41] = 0u8
    x_bytes[42] = 0u8
    x_bytes[43] = 0u8
    x_bytes[44] = 0u8
    x_bytes[45] = 0u8
    x_bytes[46] = 0u8
    x_bytes[47] = 0u8
    x_bytes[48] = 0u8
    x_bytes[49] = 0u8
    x_bytes[50] = 0u8
    x_bytes[51] = 0u8
    x_bytes[52] = 0u8
    x_bytes[53] = 0u8
    x_bytes[54] = 0u8
    x_bytes[55] = 0u8
    x_bytes[56] = 0u8
    x_bytes[57] = 0u8
    x_bytes[58] = 0u8
    x_bytes[59] = 0u8
    x_bytes[60] = 0u8
    x_bytes[61] = 0u8
    x_bytes[62] = 0u8
    x_bytes[63] = 0u8
    x_bytes[64] = 0u8
    x_bytes[65] = 0u8
    x_bytes[66] = 0u8
    x_bytes[67] = 0u8
    x_bytes[68] = 0u8
    x_bytes[69] = 0u8
    x_bytes[70] = 0u8
    x_bytes[71] = 0u8
    x_bytes[72] = 0u8
    x_bytes[73] = 0u8
    x_bytes[74] = 0u8
    x_bytes[75] = 0u8
    x_bytes[76] = 2u8
    e_bytes[0] = 1u8
    e_bytes[1] = 0u8
    e_bytes[2] = 1u8
    want[0] = 1u8
    want[1] = 255u8
    want[2] = 255u8
    want[3] = 255u8
    want[4] = 255u8
    want[5] = 255u8
    want[6] = 255u8
    want[7] = 255u8
    want[8] = 255u8
    want[9] = 255u8
    want[10] = 255u8
    want[11] = 255u8
    want[12] = 255u8
    want[13] = 255u8
    want[14] = 255u8
    want[15] = 255u8
    want[16] = 255u8
    want[17] = 255u8
    want[18] = 255u8
    want[19] = 255u8
    want[20] = 255u8
    want[21] = 255u8
    want[22] = 255u8
    want[23] = 255u8
    want[24] = 255u8
    want[25] = 255u8
    want[26] = 255u8
    want[27] = 255u8
    want[28] = 255u8
    want[29] = 255u8
    want[30] = 192u8
    want[31] = 0u8
    want[32] = 0u8
    want[33] = 0u8
    want[34] = 0u8
    want[35] = 0u8
    want[36] = 0u8
    want[37] = 0u8
    want[38] = 1u8
    want[39] = 255u8
    want[40] = 255u8
    want[41] = 255u8
    want[42] = 255u8
    want[43] = 255u8
    want[44] = 255u8
    want[45] = 255u8
    want[46] = 255u8
    want[47] = 255u8
    want[48] = 255u8
    want[49] = 255u8
    want[50] = 255u8
    want[51] = 255u8
    want[52] = 255u8
    want[53] = 255u8
    want[54] = 255u8
    want[55] = 255u8
    want[56] = 255u8
    want[57] = 255u8
    want[58] = 255u8
    want[59] = 255u8
    want[60] = 255u8
    want[61] = 255u8
    want[62] = 255u8
    want[63] = 255u8
    want[64] = 255u8
    want[65] = 255u8
    want[66] = 255u8
    want[67] = 255u8
    want[68] = 192u8
    want[69] = 0u8
    want[70] = 0u8
    want[71] = 0u8
    want[72] = 0u8
    want[73] = 0u8
    want[74] = 0u8
    want[75] = 0u8
    want[76] = 1u8
    var m: [u32; 140] = [0u32; 140]
    var xv: [u32; 140] = [0u32; 140]
    var t1: [u32; 140] = [0u32; 140]
    var t2: [u32; 140] = [0u32; 140]
    var got: [u8; 77] = [0u8; 77]
    unsafe {
        i31_decode(&raw mut m[0] as *mut u32, &m_bytes[0] as *const u8, 77)
        let m0i = i31_ninv31(m[1])
        i31_decode_reduce(&raw mut xv[0] as *mut u32, &x_bytes[0] as *const u8, 77, &m[0] as *const u32)
        i31_modpow(&raw mut xv[0] as *mut u32, &e_bytes[0] as *const u8, 3, &m[0] as *const u32, m0i, &raw mut t1[0] as *mut u32, &raw mut t2[0] as *mut u32)
        i31_encode(&raw mut got[0] as *mut u8, 77, &xv[0] as *const u32)
    }
    var bad = 0
    var i = 0
    while i < 77:
        if got[i] != want[i]:
            bad = bad + 1
        i = i + 1
    if bad == 0:
        print("s610-PASS")
    else:
        print("s610-FAIL")
    0
