// Poly1305 MAC — RFC 8439
// Uses 26-bit limbs with 64-bit multiply accumulators.

use std.crypto.endian

type Poly1305 = {
    r: [u32; 5],
    h: [u32; 5],
    pad: [u32; 4],
}

fn Poly1305.new(key: *const u8) -> Poly1305:
    // First 16 bytes = r (clamped per RFC 8439)
    var t0 = u32_from_le(key, 0) & 0x0FFFFFFF as u32
    var t1 = u32_from_le(key, 4) & 0x0FFFFFFC as u32
    var t2 = u32_from_le(key, 8) & 0x0FFFFFFC as u32
    var t3 = u32_from_le(key, 12) & 0x0FFFFFFC as u32
    let r0 = t0 & 0x03FFFFFF as u32
    let r1 = ((t0 >> 26 as u32) | (t1 << 6 as u32)) & 0x03FFFFFF as u32
    let r2 = ((t1 >> 20 as u32) | (t2 << 12 as u32)) & 0x03FFFFFF as u32
    let r3 = ((t2 >> 14 as u32) | (t3 << 18 as u32)) & 0x03FFFFFF as u32
    let r4 = (t3 >> 8 as u32) & 0x03FFFFFF as u32
    // Last 16 bytes = pad s
    let s0 = u32_from_le(key, 16)
    let s1 = u32_from_le(key, 20)
    let s2 = u32_from_le(key, 24)
    let s3 = u32_from_le(key, 28)
    Poly1305 {
        r: [r0, r1, r2, r3, r4],
        h: [0 as u32; 5],
        pad: [s0, s1, s2, s3],
    }

// Process a 16-byte block. hibit = 1 for message blocks, 0 for final length block.
unsafe fn poly1305_block(ctx: *mut Poly1305, data: *const u8, hibit: u32):
    let t0 = u32_from_le(data, 0)
    let t1 = u32_from_le(data, 4)
    let t2 = u32_from_le(data, 8)
    let t3 = u32_from_le(data, 12)

    var h0 = ctx.h[0] +% (t0 & 0x03FFFFFF as u32)
    var h1 = ctx.h[1] +% (((t0 >> 26 as u32) | (t1 << 6 as u32)) & 0x03FFFFFF as u32)
    var h2 = ctx.h[2] +% (((t1 >> 20 as u32) | (t2 << 12 as u32)) & 0x03FFFFFF as u32)
    var h3 = ctx.h[3] +% (((t2 >> 14 as u32) | (t3 << 18 as u32)) & 0x03FFFFFF as u32)
    var h4 = ctx.h[4] +% ((t3 >> 8 as u32) | hibit)

    let r0 = ctx.r[0]
    let r1 = ctx.r[1]
    let r2 = ctx.r[2]
    let r3 = ctx.r[3]
    let r4 = ctx.r[4]
    let s1 = r1 *% 5 as u32
    let s2 = r2 *% 5 as u32
    let s3 = r3 *% 5 as u32
    let s4 = r4 *% 5 as u32

    var d0: u64 = (h0 as u64) * (r0 as u64) + (h1 as u64) * (s4 as u64) + (h2 as u64) * (s3 as u64) + (h3 as u64) * (s2 as u64) + (h4 as u64) * (s1 as u64)
    var d1: u64 = (h0 as u64) * (r1 as u64) + (h1 as u64) * (r0 as u64) + (h2 as u64) * (s4 as u64) + (h3 as u64) * (s3 as u64) + (h4 as u64) * (s2 as u64)
    var d2: u64 = (h0 as u64) * (r2 as u64) + (h1 as u64) * (r1 as u64) + (h2 as u64) * (r0 as u64) + (h3 as u64) * (s4 as u64) + (h4 as u64) * (s3 as u64)
    var d3: u64 = (h0 as u64) * (r3 as u64) + (h1 as u64) * (r2 as u64) + (h2 as u64) * (r1 as u64) + (h3 as u64) * (r0 as u64) + (h4 as u64) * (s4 as u64)
    var d4: u64 = (h0 as u64) * (r4 as u64) + (h1 as u64) * (r3 as u64) + (h2 as u64) * (r2 as u64) + (h3 as u64) * (r1 as u64) + (h4 as u64) * (r0 as u64)

    var c: u32 = (d0 >> 26 as u64) as u32
    h0 = d0 as u32 & 0x03FFFFFF as u32
    d1 = d1 + c as u64
    c = (d1 >> 26 as u64) as u32
    h1 = d1 as u32 & 0x03FFFFFF as u32
    d2 = d2 + c as u64
    c = (d2 >> 26 as u64) as u32
    h2 = d2 as u32 & 0x03FFFFFF as u32
    d3 = d3 + c as u64
    c = (d3 >> 26 as u64) as u32
    h3 = d3 as u32 & 0x03FFFFFF as u32
    d4 = d4 + c as u64
    c = (d4 >> 26 as u64) as u32
    h4 = d4 as u32 & 0x03FFFFFF as u32
    h0 +%= c *% 5 as u32
    c = h0 >> 26 as u32
    h0 = h0 & 0x03FFFFFF as u32
    h1 +%= c

    ctx.h[0] = h0
    ctx.h[1] = h1
    ctx.h[2] = h2
    ctx.h[3] = h3
    ctx.h[4] = h4

// Process message bytes — handles full and partial blocks correctly.
unsafe fn poly1305_update(ctx: *mut Poly1305, data: *const u8, len: i32):
    var off = 0
    while off + 16 <= len:
        poly1305_block(ctx, (data + off as u64) as *const u8, 1 as u32 << 24 as u32)
        off = off + 16
    if off < len:
        // Partial block: copy bytes + append 0x01 sentinel + zero-pad to 16
        var pad: [u8; 16] = [0 as u8; 16]
        let pp = &mut pad[0] as *mut u8
        let remaining = len - off
        for i in 0..remaining:
            *(pp + i as u64) = *(data + (off + i) as u64)
        *(pp + remaining as u64) = 0x01 as u8
        // Process with hibit = 0 (the sentinel replaces the hibit)
        poly1305_block(ctx, pp as *const u8, 0 as u32)

unsafe fn poly1305_finish(ctx: *mut Poly1305, out: *mut u8):
    var h0 = ctx.h[0]
    var h1 = ctx.h[1]
    var h2 = ctx.h[2]
    var h3 = ctx.h[3]
    var h4 = ctx.h[4]

    var c: u32 = h1 >> 26 as u32
    h1 = h1 & 0x03FFFFFF as u32
    h2 +%= c
    c = h2 >> 26 as u32
    h2 = h2 & 0x03FFFFFF as u32
    h3 +%= c
    c = h3 >> 26 as u32
    h3 = h3 & 0x03FFFFFF as u32
    h4 +%= c
    c = h4 >> 26 as u32
    h4 = h4 & 0x03FFFFFF as u32
    h0 +%= c *% 5 as u32
    c = h0 >> 26 as u32
    h0 = h0 & 0x03FFFFFF as u32
    h1 +%= c

    var g0 = h0 +% 5 as u32
    c = g0 >> 26 as u32
    g0 = g0 & 0x03FFFFFF as u32
    var g1 = h1 +% c
    c = g1 >> 26 as u32
    g1 = g1 & 0x03FFFFFF as u32
    var g2 = h2 +% c
    c = g2 >> 26 as u32
    g2 = g2 & 0x03FFFFFF as u32
    var g3 = h3 +% c
    c = g3 >> 26 as u32
    g3 = g3 & 0x03FFFFFF as u32
    var g4 = h4 +% c
    g4 = g4 -% (1 as u32 << 26 as u32)

    let mask = (g4 >> 31 as u32) -% 1 as u32
    let nmask = ~mask
    h0 = (h0 & nmask) | (g0 & mask)
    h1 = (h1 & nmask) | (g1 & mask)
    h2 = (h2 & nmask) | (g2 & mask)
    h3 = (h3 & nmask) | (g3 & mask)
    h4 = (h4 & nmask) | (g4 & mask)

    // Reassemble 26-bit limbs into 32-bit words.
    // Truncate to u32 first — the u64 OR results have overlapping bits
    // from adjacent limbs that would corrupt carry propagation.
    let w0: u32 = ((h0 as u64) | ((h1 as u64) << 26 as u64)) as u32
    let w1: u32 = (((h1 >> 6 as u32) as u64) | ((h2 as u64) << 20 as u64)) as u32
    let w2: u32 = (((h2 >> 12 as u32) as u64) | ((h3 as u64) << 14 as u64)) as u32
    let w3: u32 = (((h3 >> 18 as u32) as u64) | ((h4 as u64) << 8 as u64)) as u32

    // Add pad with carry chain
    var f0: u64 = w0 as u64 + ctx.pad[0] as u64
    var f1: u64 = w1 as u64 + ctx.pad[1] as u64 + (f0 >> 32 as u64)
    var f2: u64 = w2 as u64 + ctx.pad[2] as u64 + (f1 >> 32 as u64)
    var f3: u64 = w3 as u64 + ctx.pad[3] as u64 + (f2 >> 32 as u64)

    u32_to_le(out, 0, f0 as u32)
    u32_to_le(out, 4, f1 as u32)
    u32_to_le(out, 8, f2 as u32)
    u32_to_le(out, 12, f3 as u32)
