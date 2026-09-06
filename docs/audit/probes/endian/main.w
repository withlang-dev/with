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

fn main:
    var b4: [u8; 4] = [0x12 as u8, 0x34 as u8, 0x56 as u8, 0x78 as u8]
    var b8: [u8; 8] = [0x01 as u8, 0x02 as u8, 0x03 as u8, 0x04 as u8, 0x05 as u8, 0x06 as u8, 0x07 as u8, 0x08 as u8]
    var wb: [u8; 8] = [0 as u8; 8]
    let t01 = (u32_from_be(&b4[0] as *const u8, 0) == (0x12345678 as u32))
    if t01:
        print("PASS u32_from_be")
    else:
        print("FAIL u32_from_be")
    let t02 = (u32_from_le(&b4[0] as *const u8, 0) == (0x78563412 as u32))
    if t02:
        print("PASS u32_from_le")
    else:
        print("FAIL u32_from_le")
    let t03 = (u16_from_be(&b4[0] as *const u8, 0) == (0x1234 as u16))
    if t03:
        print("PASS u16_from_be")
    else:
        print("FAIL u16_from_be")
    let t04 = (u16_from_le(&b4[0] as *const u8, 0) == (0x3412 as u16))
    if t04:
        print("PASS u16_from_le")
    else:
        print("FAIL u16_from_le")
    let t05 = (u64_from_be(&b8[0] as *const u8, 0) == (0x0102030405060708 as u64))
    if t05:
        print("PASS u64_from_be")
    else:
        print("FAIL u64_from_be")
    let t06 = (u64_from_le(&b8[0] as *const u8, 0) == (0x0807060504030201 as u64))
    if t06:
        print("PASS u64_from_le")
    else:
        print("FAIL u64_from_le")
    u32_to_be(&raw mut wb[0] as *mut u8, 0, 0xDEADBEEF as u32)
    let t07 = (u32_from_be(&wb[0] as *const u8, 0) == (0xDEADBEEF as u32))
    if t07:
        print("PASS u32 be roundtrip")
    else:
        print("FAIL u32 be roundtrip")
    u32_to_le(&raw mut wb[0] as *mut u8, 0, 0xDEADBEEF as u32)
    let t08 = (u32_from_le(&wb[0] as *const u8, 0) == (0xDEADBEEF as u32))
    if t08:
        print("PASS u32 le roundtrip")
    else:
        print("FAIL u32 le roundtrip")
    u64_to_be(&raw mut wb[0] as *mut u8, 0, 0x0123456789ABCDEF as u64)
    let t09 = (u64_from_be(&wb[0] as *const u8, 0) == (0x0123456789ABCDEF as u64))
    if t09:
        print("PASS u64 be roundtrip")
    else:
        print("FAIL u64 be roundtrip")
    u64_to_le(&raw mut wb[0] as *mut u8, 0, 0x0123456789ABCDEF as u64)
    let t10 = (u64_from_le(&wb[0] as *const u8, 0) == (0x0123456789ABCDEF as u64))
    if t10:
        print("PASS u64 le roundtrip")
    else:
        print("FAIL u64 le roundtrip")
    u16_to_be(&raw mut wb[0] as *mut u8, 6, 0xABCD as u16)
    let t11 = (u16_from_be(&wb[0] as *const u8, 6) == (0xABCD as u16))
    if t11:
        print("PASS u16 be roundtrip off6")
    else:
        print("FAIL u16 be roundtrip off6")
    u16_to_le(&raw mut wb[0] as *mut u8, 6, 0xABCD as u16)
    let t12 = (u16_from_le(&wb[0] as *const u8, 6) == (0xABCD as u16))
    if t12:
        print("PASS u16 le roundtrip off6")
    else:
        print("FAIL u16 le roundtrip off6")
    let t13 = (u32_from_be(&b8[0] as *const u8, 1) == (0x02030405 as u32))
    if t13:
        print("PASS u32_from_be off1")
    else:
        print("FAIL u32_from_be off1")
    let t14 = (u16_from_le(&b8[0] as *const u8, 2) == (0x0403 as u16))
    if t14:
        print("PASS u16_from_le off2")
    else:
        print("FAIL u16_from_le off2")
