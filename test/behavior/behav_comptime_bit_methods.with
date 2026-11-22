//! expect-stdout: ok

const ROT_R: u32 = comptime (0x12345678 as u32).rotate_right(8)
const ROT_L: u32 = comptime (0x12345678 as u32).rotate_left(4)
const ROT_BIG: u8 = comptime (0b10000001 as u8).rotate_left(9)
const ROT_NEG: u8 = comptime (0b00000011 as u8).rotate_right(-1)

const SWAP_U8: u8 = comptime (0xAB as u8).swap_bytes()
const SWAP_U16: u16 = comptime (0x1234 as u16).swap_bytes()
const SWAP_U32: u32 = comptime (0x12345678 as u32).swap_bytes()

const POP_U8: i32 = comptime (0xFF as u8).popcount()
const POP_SIGNED: i32 = comptime ((-1) as i8).popcount()
const CLZ_ZERO: i32 = comptime (0 as u32).clz()
const CTZ_ZERO: i32 = comptime (0 as u32).ctz()
const CLZ_X: i32 = comptime (0b00010000 as u32).clz()
const CTZ_X: i32 = comptime (0b00010000 as u32).ctz()

const BR_U8: u8 = comptime (0b10110000 as u8).bitreverse()
const BR_U32: u32 = comptime (0x80000000 as u32).bitreverse()
const BR_SIGNED: i8 = comptime (1 as i8).bitreverse()

fn main:
    assert(ROT_R == 0x78123456 as u32)
    assert(ROT_L == 0x23456781 as u32)
    assert(ROT_BIG == 0b00000011 as u8)
    assert(ROT_NEG == 0b00000110 as u8)

    assert(SWAP_U8 == 0xAB as u8)
    assert(SWAP_U16 == 0x3412 as u16)
    assert(SWAP_U32 == 0x78563412 as u32)

    assert(POP_U8 == 8)
    assert(POP_SIGNED == 8)
    assert(CLZ_ZERO == 32)
    assert(CTZ_ZERO == 32)
    assert(CLZ_X == 27)
    assert(CTZ_X == 4)

    assert(BR_U8 == 0b00001101 as u8)
    assert(BR_U32 == 1 as u32)
    assert(BR_SIGNED == -128 as i8)
    print("ok")
