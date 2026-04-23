//! expect-stdout: ok

// Tests: const declarations, compile-time arithmetic, const references,
//        const in expressions, const propagation

const PI_APPROX: i32 = 3
const ANSWER: i32 = 42
const DOUBLED: i32 = ANSWER * 2
const TRIPLED: i32 = ANSWER * 3
const SUM: i32 = ANSWER + DOUBLED

fn test_const_basic:
    assert(ANSWER == 42)
    assert(DOUBLED == 84)
    assert(TRIPLED == 126)

fn test_const_chain:
    // Constants can reference other constants
    assert(SUM == 42 + 84)
    assert(SUM == 126)

const BITS_PER_BYTE: i32 = 8
const BYTES_PER_WORD: i32 = 4
const BITS_PER_WORD: i32 = BITS_PER_BYTE * BYTES_PER_WORD

fn test_const_multiplication:
    assert(BITS_PER_WORD == 32)

const ZERO: i32 = 0
const ONE: i32 = 1
const NEG_ONE: i32 = -1

fn test_const_edge_values:
    assert(ZERO == 0)
    assert(ONE == 1)
    assert(NEG_ONE == -1)
    assert(ZERO + ONE == ONE)

fn test_const_in_expression:
    let x = ANSWER + 8
    assert(x == 50)
    let y = ANSWER * 2 + 1
    assert(y == 85)

const MAX_SIZE: i32 = 1024

fn test_const_in_comparison:
    let x = 500
    assert(x < MAX_SIZE)
    let y = 2000
    assert(y > MAX_SIZE)

const SHIFT_AMOUNT: u32 = 4

fn test_const_in_shift:
    let x = 1 << SHIFT_AMOUNT
    assert(x == 16)

fn test_const_in_array_size:
    let arr: [i32; 5] = [0; 5]
    assert(arr.len() == 5)

fn main:
    test_const_basic()
    test_const_chain()
    test_const_multiplication()
    test_const_edge_values()
    test_const_in_expression()
    test_const_in_comparison()
    test_const_in_shift()
    test_const_in_array_size()
    print("ok")
