// Byte-order encode/decode utilities for crypto and network code.
// These should eventually be compiler intrinsics on integer types
// (u32.from_be, etc.), but for now they are standalone functions.

fn u16_from_be(buf: *const u8, off: i32) -> u16:
    let b0 = (unsafe: *(buf + off as u64)) as u16
    let b1 = (unsafe: *(buf + (off + 1) as u64)) as u16
    (b0 << 8 as u16) | b1

fn u16_from_le(buf: *const u8, off: i32) -> u16:
    let b0 = (unsafe: *(buf + off as u64)) as u16
    let b1 = (unsafe: *(buf + (off + 1) as u64)) as u16
    b0 | (b1 << 8 as u16)

fn u32_from_be(buf: *const u8, off: i32) -> u32:
    let b0 = (unsafe: *(buf + off as u64)) as u32
    let b1 = (unsafe: *(buf + (off + 1) as u64)) as u32
    let b2 = (unsafe: *(buf + (off + 2) as u64)) as u32
    let b3 = (unsafe: *(buf + (off + 3) as u64)) as u32
    (b0 << 24 as u32) | (b1 << 16 as u32) | (b2 << 8 as u32) | b3

fn u32_from_le(buf: *const u8, off: i32) -> u32:
    let b0 = (unsafe: *(buf + off as u64)) as u32
    let b1 = (unsafe: *(buf + (off + 1) as u64)) as u32
    let b2 = (unsafe: *(buf + (off + 2) as u64)) as u32
    let b3 = (unsafe: *(buf + (off + 3) as u64)) as u32
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
    unsafe: *(buf + off as u64) = (val >> 8 as u16) as u8
    unsafe: *(buf + (off + 1) as u64) = val as u8

fn u16_to_le(buf: *mut u8, off: i32, val: u16):
    unsafe: *(buf + off as u64) = val as u8
    unsafe: *(buf + (off + 1) as u64) = (val >> 8 as u16) as u8

fn u32_to_be(buf: *mut u8, off: i32, val: u32):
    unsafe: *(buf + off as u64) = (val >> 24 as u32) as u8
    unsafe: *(buf + (off + 1) as u64) = (val >> 16 as u32) as u8
    unsafe: *(buf + (off + 2) as u64) = (val >> 8 as u32) as u8
    unsafe: *(buf + (off + 3) as u64) = val as u8

fn u32_to_le(buf: *mut u8, off: i32, val: u32):
    unsafe: *(buf + off as u64) = val as u8
    unsafe: *(buf + (off + 1) as u64) = (val >> 8 as u32) as u8
    unsafe: *(buf + (off + 2) as u64) = (val >> 16 as u32) as u8
    unsafe: *(buf + (off + 3) as u64) = (val >> 24 as u32) as u8

fn u64_to_be(buf: *mut u8, off: i32, val: u64):
    u32_to_be(buf, off, (val >> 32 as u64) as u32)
    u32_to_be(buf, off + 4, val as u32)

fn u64_to_le(buf: *mut u8, off: i32, val: u64):
    u32_to_le(buf, off, val as u32)
    u32_to_le(buf, off + 4, (val >> 32 as u64) as u32)
