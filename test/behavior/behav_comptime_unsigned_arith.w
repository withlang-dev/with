//! expect-stdout: ok

comptime fn u32_add() -> u32:
    100 + 50

comptime fn u32_sub() -> u32:
    200 - 75

comptime fn u32_mul() -> u32:
    15 * 20

comptime fn u32_div() -> u32:
    200 / 8

comptime fn u32_mod() -> u32:
    200 % 7

comptime fn u32_shl() -> u32:
    1 << 8

comptime fn u32_shr() -> u32:
    256 >> 4

comptime fn u32_bitand() -> u32:
    0xFF & 0x0F

comptime fn u32_bitor() -> u32:
    0xA0 | 0x0F

comptime fn u32_bitxor() -> u32:
    0xFF ^ 0x0F

comptime fn u32_bitnot() -> u32:
    ~0

comptime fn u32_chain() -> u32:
    (10 + 5) * 2 - 4

comptime fn u32_precedence() -> u32:
    2 + 3 * 4

const ADD: u32 = comptime u32_add()
const SUB: u32 = comptime u32_sub()
const MUL: u32 = comptime u32_mul()
const DIV: u32 = comptime u32_div()
const MOD: u32 = comptime u32_mod()
const SHL: u32 = comptime u32_shl()
const SHR: u32 = comptime u32_shr()
const BAND: u32 = comptime u32_bitand()
const BOR: u32 = comptime u32_bitor()
const BXOR: u32 = comptime u32_bitxor()
const BNOT: u32 = comptime u32_bitnot()
const CHAIN: u32 = comptime u32_chain()
const PREC: u32 = comptime u32_precedence()

fn main:
    assert(ADD == 150)
    assert(SUB == 125)
    assert(MUL == 300)
    assert(DIV == 25)
    assert(MOD == 4)
    assert(SHL == 256)
    assert(SHR == 16)
    assert(BAND == 15)
    assert(BOR == 175)
    assert(BXOR == 240)
    assert(CHAIN == 26)
    assert(PREC == 14)
    print("ok")
