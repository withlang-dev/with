// Poly1305 MAC — RFC 8439
// Ported from BearSSL src/mac/poly1305_ctmul.c
// Uses 32-bit multiplies only (no 64-bit multiply needed).

// Poly1305 state
type Poly1305 = {
    r: [u32; 5],    // Clamped key r (5 × 26-bit limbs)
    h: [u32; 5],    // Accumulator (5 × 26-bit limbs)
    pad: [u32; 4],  // One-time pad s
}

fn load32le_poly(p: *const u8, off: i32) -> u32:
    let b0 = (unsafe: *(p + off as u64)) as u32
    let b1 = (unsafe: *(p + (off + 1) as u64)) as u32
    let b2 = (unsafe: *(p + (off + 2) as u64)) as u32
    let b3 = (unsafe: *(p + (off + 3) as u64)) as u32
    b0 | (b1 << 8 as u32) | (b2 << 16 as u32) | (b3 << 24 as u32)

fn Poly1305.new(key: *const u8) -> Poly1305:
    // First 16 bytes = r (clamped per RFC 8439)
    // Clamp: AND with 0x0ffffffc0ffffffc0ffffffc0fffffff
    var t0 = load32le_poly(key, 0) & 0x0FFFFFFF as u32
    var t1 = load32le_poly(key, 4) & 0x0FFFFFFC as u32
    var t2 = load32le_poly(key, 8) & 0x0FFFFFFC as u32
    var t3 = load32le_poly(key, 12) & 0x0FFFFFFC as u32
    // Convert to 26-bit limbs
    let r0 = t0 & 0x03FFFFFF as u32
    let r1 = ((t0 >> 26 as u32) | (t1 << 6 as u32)) & 0x03FFFFFF as u32
    let r2 = ((t1 >> 20 as u32) | (t2 << 12 as u32)) & 0x03FFFFFF as u32
    let r3 = ((t2 >> 14 as u32) | (t3 << 18 as u32)) & 0x03FFFFFF as u32
    let r4 = (t3 >> 8 as u32) & 0x03FFFFFF as u32
    // Last 16 bytes = pad s
    let s0 = load32le_poly(key, 16)
    let s1 = load32le_poly(key, 20)
    let s2 = load32le_poly(key, 24)
    let s3 = load32le_poly(key, 28)
    Poly1305 {
        r: [r0, r1, r2, r3, r4],
        h: [0 as u32; 5],
        pad: [s0, s1, s2, s3],
    }

// Process a 16-byte block
fn Poly1305.block(self: *mut Poly1305, data: *const u8, final_block: bool):
    // Load block as 5 × 26-bit limbs + hibit
    let t0 = load32le_poly(data, 0)
    let t1 = load32le_poly(data, 4)
    let t2 = load32le_poly(data, 8)
    let t3 = load32le_poly(data, 12)
    let hibit: u32 = if final_block: 0 as u32 else: 1 as u32 << 24 as u32

    // Copy state to locals
    var h0 = unsafe: (*self).h[0]
    var h1 = unsafe: (*self).h[1]
    var h2 = unsafe: (*self).h[2]
    var h3 = unsafe: (*self).h[3]
    var h4 = unsafe: (*self).h[4]

    // h += m
    h0 = h0 +% (t0 & 0x03FFFFFF as u32)
    h1 = h1 +% (((t0 >> 26 as u32) | (t1 << 6 as u32)) & 0x03FFFFFF as u32)
    h2 = h2 +% (((t1 >> 20 as u32) | (t2 << 12 as u32)) & 0x03FFFFFF as u32)
    h3 = h3 +% (((t2 >> 14 as u32) | (t3 << 18 as u32)) & 0x03FFFFFF as u32)
    h4 = h4 +% ((t3 >> 8 as u32) | hibit)

    let r0 = unsafe: (*self).r[0]
    let r1 = unsafe: (*self).r[1]
    let r2 = unsafe: (*self).r[2]
    let r3 = unsafe: (*self).r[3]
    let r4 = unsafe: (*self).r[4]

    // h *= r (mod 2^130 - 5)
    // Using 64-bit accumulators
    let s1 = r1 *% 5 as u32
    let s2 = r2 *% 5 as u32
    let s3 = r3 *% 5 as u32
    let s4 = r4 *% 5 as u32

    var d0: u64 = (h0 as u64) * (r0 as u64) + (h1 as u64) * (s4 as u64) + (h2 as u64) * (s3 as u64) + (h3 as u64) * (s2 as u64) + (h4 as u64) * (s1 as u64)
    var d1: u64 = (h0 as u64) * (r1 as u64) + (h1 as u64) * (r0 as u64) + (h2 as u64) * (s4 as u64) + (h3 as u64) * (s3 as u64) + (h4 as u64) * (s2 as u64)
    var d2: u64 = (h0 as u64) * (r2 as u64) + (h1 as u64) * (r1 as u64) + (h2 as u64) * (r0 as u64) + (h3 as u64) * (s4 as u64) + (h4 as u64) * (s3 as u64)
    var d3: u64 = (h0 as u64) * (r3 as u64) + (h1 as u64) * (r2 as u64) + (h2 as u64) * (r1 as u64) + (h3 as u64) * (r0 as u64) + (h4 as u64) * (s4 as u64)
    var d4: u64 = (h0 as u64) * (r4 as u64) + (h1 as u64) * (r3 as u64) + (h2 as u64) * (r2 as u64) + (h3 as u64) * (r1 as u64) + (h4 as u64) * (r0 as u64)

    // Carry propagation
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
    h0 = h0 +% (c *% 5 as u32)
    c = h0 >> 26 as u32
    h0 = h0 & 0x03FFFFFF as u32
    h1 = h1 +% c

    unsafe: (*self).h[0] = h0
    unsafe: (*self).h[1] = h1
    unsafe: (*self).h[2] = h2
    unsafe: (*self).h[3] = h3
    unsafe: (*self).h[4] = h4

// Finalize and produce 16-byte tag
fn Poly1305.finish(self: *mut Poly1305, out: *mut u8):
    var h0 = unsafe: (*self).h[0]
    var h1 = unsafe: (*self).h[1]
    var h2 = unsafe: (*self).h[2]
    var h3 = unsafe: (*self).h[3]
    var h4 = unsafe: (*self).h[4]

    // Final carry propagation
    var c: u32 = h1 >> 26 as u32
    h1 = h1 & 0x03FFFFFF as u32
    h2 = h2 +% c
    c = h2 >> 26 as u32
    h2 = h2 & 0x03FFFFFF as u32
    h3 = h3 +% c
    c = h3 >> 26 as u32
    h3 = h3 & 0x03FFFFFF as u32
    h4 = h4 +% c
    c = h4 >> 26 as u32
    h4 = h4 & 0x03FFFFFF as u32
    h0 = h0 +% (c *% 5 as u32)
    c = h0 >> 26 as u32
    h0 = h0 & 0x03FFFFFF as u32
    h1 = h1 +% c

    // Compute h - p = h - (2^130 - 5)
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

    // Select h if g overflowed, g otherwise (constant-time)
    let mask = (g4 >> 31 as u32) -% 1 as u32  // 0 if g >= 0, 0xFFFFFFFF if g < 0
    let nmask = ~mask
    h0 = (h0 & nmask) | (g0 & mask)
    h1 = (h1 & nmask) | (g1 & mask)
    h2 = (h2 & nmask) | (g2 & mask)
    h3 = (h3 & nmask) | (g3 & mask)
    h4 = (h4 & nmask) | (g4 & mask)

    // Reassemble into 4 × 32-bit words
    var f0: u64 = (h0 as u64) | ((h1 as u64) << 26 as u64)
    var f1: u64 = ((h1 >> 6 as u32) as u64) | ((h2 as u64) << 20 as u64)
    var f2: u64 = ((h2 >> 12 as u32) as u64) | ((h3 as u64) << 14 as u64)
    var f3: u64 = ((h3 >> 18 as u32) as u64) | ((h4 as u64) << 8 as u64)

    // Add pad s
    let p0 = unsafe: (*self).pad[0]
    let p1 = unsafe: (*self).pad[1]
    let p2 = unsafe: (*self).pad[2]
    let p3 = unsafe: (*self).pad[3]
    f0 = f0 + p0 as u64
    f1 = f1 + p1 as u64 + (f0 >> 32 as u64)
    f2 = f2 + p2 as u64 + (f1 >> 32 as u64)
    f3 = f3 + p3 as u64 + (f2 >> 32 as u64)

    // Store little-endian
    store32le_poly(out, 0, f0 as u32)
    store32le_poly(out, 4, f1 as u32)
    store32le_poly(out, 8, f2 as u32)
    store32le_poly(out, 12, f3 as u32)

fn store32le_poly(p: *mut u8, off: i32, val: u32):
    unsafe: *(p + off as u64) = val as u8
    unsafe: *(p + (off + 1) as u64) = (val >> 8 as u32) as u8
    unsafe: *(p + (off + 2) as u64) = (val >> 16 as u32) as u8
    unsafe: *(p + (off + 3) as u64) = (val >> 24 as u32) as u8
