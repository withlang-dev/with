//! expect-stdout: ok

comptime fn neg_add() -> i32:
    -10 + 3

comptime fn neg_sub() -> i32:
    -10 - 5

comptime fn neg_mul() -> i32:
    -3 * 7

comptime fn neg_div() -> i32:
    -21 / 7

comptime fn neg_mod() -> i32:
    -10 % 3

comptime fn neg_negate() -> i32:
    let x = 42
    -x

comptime fn neg_double_negate() -> i32:
    let x = -99
    -x

comptime fn i16_basic() -> i16:
    let a: i16 = 100
    let b: i16 = 50
    a + b

comptime fn i16_negative() -> i16:
    let a: i16 = -100
    let b: i16 = 50
    a + b

comptime fn logical_not_true() -> bool:
    not true

comptime fn logical_not_false() -> bool:
    not false

comptime fn logical_and() -> bool:
    true and true

comptime fn logical_or() -> bool:
    false or true

comptime fn logical_short_circuit() -> bool:
    false and true

const NEG_ADD: i32 = comptime neg_add()
const NEG_SUB: i32 = comptime neg_sub()
const NEG_MUL: i32 = comptime neg_mul()
const NEG_DIV: i32 = comptime neg_div()
const NEG_MOD: i32 = comptime neg_mod()
const NEG_NEG: i32 = comptime neg_negate()
const NEG_DBL: i32 = comptime neg_double_negate()
const I16_B: i16 = comptime i16_basic()
const I16_N: i16 = comptime i16_negative()
const NOT_T: bool = comptime logical_not_true()
const NOT_F: bool = comptime logical_not_false()
const L_AND: bool = comptime logical_and()
const L_OR: bool = comptime logical_or()
const L_SC: bool = comptime logical_short_circuit()

fn main:
    assert(NEG_ADD == -7)
    assert(NEG_SUB == -15)
    assert(NEG_MUL == -21)
    assert(NEG_DIV == -3)
    assert(NEG_MOD == -1)
    assert(NEG_NEG == -42)
    assert(NEG_DBL == 99)
    assert(I16_B == 150)
    assert(I16_N == -50)
    assert(NOT_T == false)
    assert(NOT_F == true)
    assert(L_AND == true)
    assert(L_OR == true)
    assert(L_SC == false)
    print("ok")
