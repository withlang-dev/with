//! expect-stdout: ok

// S0 differential oracle for #943.
//
// For an expression E of integer type T, all four terms must agree:
//
//     comptime E  ==  plain-const-fold E  ==  runtime E  ==  expected literal
//
// The fourth term is not redundant. Plain const folding runs through the same
// evaluator as an explicit `comptime` (its overflow diagnostic reads "integer
// overflow in comptime") and shares that evaluator's 64-bit ceiling, so a
// three-way agreement check can pass unanimously while every term is wrong.
// Runtime is the independent term; the expected literal guards against all of
// them drifting together.
//
// Every operation below is an identity — `+ 0`, `- 0`, `* 1`, `/ 1`, `<< 0` —
// so a correct evaluator cannot overflow at any width. That isolates the
// operand-truncation defect: the corruption is applied to the inputs before
// the overflow check runs, and an identity operation can never trip that check.

// ── comptime terms ───────────────────────────────────────────────────────
// Widths at or below 32 bits pass today; i64/u64 are the defect.

comptime fn ct_i8  -> i8:  100i8 + 0i8
comptime fn ct_i16 -> i16: 30000i16 + 0i16
comptime fn ct_i32 -> i32: 2000000000i32 + 0i32
comptime fn ct_i64 -> i64: 3000000001i64 + 0i64

comptime fn ct_u8  -> u8:  200u8 + 0u8
comptime fn ct_u16 -> u16: 60000u16 + 0u16
comptime fn ct_u32 -> u32: 4294967295u32 + 0u32
comptime fn ct_u64 -> u64: 4294967296u64 + 0u64

// Per-operator coverage at 64 bits. `/ 1` currently succeeds because the
// OP_DIV arm computes on raw operands and consults the width only for
// int_div_overflows — it is included so a fix cannot silently regress it.
comptime fn ct_i64_sub -> i64: 3000000001i64 - 0i64
comptime fn ct_i64_mul -> i64: 3000000001i64 * 1i64
comptime fn ct_i64_div -> i64: 3000000001i64 / 1i64
comptime fn ct_u64_sub -> u64: 4294967296u64 - 0u64
comptime fn ct_u64_mul -> u64: 4294967296u64 * 1u64

// Reaches the corruption through eval_shift_value rather than int_signed_add.
comptime fn ct_i64_shl -> i64: 1i64 << 40

// Promoted from test/compile_errors/ when #943 was fixed. Both used to be
// compile errors: the first a spurious "integer overflow in comptime" on an
// expression that never overflows i64, the second a misleading "integer
// literal does not fit expected type" naming a literal that fits u64 exactly
// (the truncated operand went negative and the unsigned fit check rejected it).
comptime fn ct_i64_edge -> i64: 2147483647i64 + 1i64
comptime fn ct_u64_fit  -> u64: 3000000001u64 + 0u64

const CT_I8:  i8  = comptime ct_i8()
const CT_I16: i16 = comptime ct_i16()
const CT_I32: i32 = comptime ct_i32()
const CT_I64: i64 = comptime ct_i64()
const CT_U8:  u8  = comptime ct_u8()
const CT_U16: u16 = comptime ct_u16()
const CT_U32: u32 = comptime ct_u32()
const CT_U64: u64 = comptime ct_u64()

const CT_I64_SUB: i64 = comptime ct_i64_sub()
const CT_I64_MUL: i64 = comptime ct_i64_mul()
const CT_I64_DIV: i64 = comptime ct_i64_div()
const CT_U64_SUB: u64 = comptime ct_u64_sub()
const CT_U64_MUL: u64 = comptime ct_u64_mul()
const CT_I64_SHL: i64 = comptime ct_i64_shl()
const CT_I64_EDGE: i64 = comptime ct_i64_edge()
const CT_U64_FIT: u64 = comptime ct_u64_fit()

// ── plain-const-fold terms (no `comptime` keyword) ───────────────────────

const FOLD_I32: i32 = 2000000000 + 0
const FOLD_I64: i64 = 3000000001 + 0
const FOLD_U32: u32 = 4294967295 + 0
const FOLD_U64: u64 = 4294967296 + 0
const FOLD_I64_SHL: i64 = 1 << 40

fn main:
    // ── runtime terms ────────────────────────────────────────────────────
    var r_i8: i8 = 100
    var r_i16: i16 = 30000
    var r_i32: i32 = 2000000000
    var r_i64: i64 = 3000000001
    var r_u8: u8 = 200
    var r_u16: u16 = 60000
    var r_u32: u32 = 4294967295
    var r_u64: u64 = 4294967296
    var r_shl: i64 = 1

    // ── comptime term == expected literal ────────────────────────────────
    assert(CT_I8 == 100)
    assert(CT_I16 == 30000)
    assert(CT_I32 == 2000000000)
    assert(CT_I64 == 3000000001)
    assert(CT_U8 == 200)
    assert(CT_U16 == 60000)
    assert(CT_U32 == 4294967295)
    assert(CT_U64 == 4294967296)

    assert(CT_I64_SUB == 3000000001)
    assert(CT_I64_MUL == 3000000001)
    assert(CT_I64_DIV == 3000000001)
    assert(CT_U64_SUB == 4294967296)
    assert(CT_U64_MUL == 4294967296)
    assert(CT_I64_SHL == 1099511627776)
    assert(CT_I64_EDGE == 2147483648)
    assert(CT_U64_FIT == 3000000001)

    // ── plain-const-fold term == expected literal ────────────────────────
    assert(FOLD_I32 == 2000000000)
    assert(FOLD_I64 == 3000000001)
    assert(FOLD_U32 == 4294967295)
    assert(FOLD_U64 == 4294967296)
    assert(FOLD_I64_SHL == 1099511627776)

    // ── runtime term == expected literal ─────────────────────────────────
    assert(r_i8 + 0 == 100)
    assert(r_i16 + 0 == 30000)
    assert(r_i32 + 0 == 2000000000)
    assert(r_i64 + 0 == 3000000001)
    assert(r_u8 + 0 == 200)
    assert(r_u16 + 0 == 60000)
    assert(r_u32 + 0 == 4294967295)
    assert(r_u64 + 0 == 4294967296)
    assert(r_shl << 40 == 1099511627776)

    // ── the terms agree with each other ──────────────────────────────────
    assert(CT_I64 == FOLD_I64)
    assert(CT_I64 == r_i64 + 0)
    assert(CT_U64 == FOLD_U64)
    assert(CT_U64 == r_u64 + 0)
    assert(CT_I64_SHL == FOLD_I64_SHL)
    assert(CT_I64_SHL == r_shl << 40)

    print("ok")
