//! expect-stdout: ok

// Exercise all six relations through borrowed function parameters, at
// compile time and runtime. Bits: ==, !=, <, >, <=, >=.
comptime fn relations(a: &str, b: &str):
    var bits = 0
    if a == b: bits = bits + 1
    if a != b: bits = bits + 2
    if a < b: bits = bits + 4
    if a > b: bits = bits + 8
    if a <= b: bits = bits + 16
    if a >= b: bits = bits + 32
    bits

const LESS = relations("alpha", "beta")
const GREATER = relations("beta", "alpha")
const EQUAL = relations("alpha", "alpha")
const EMPTY = relations("", "")
const EMPTY_PREFIX = relations("", "a")
const PREFIX = relations("ab", "abc")
const LONGER = relations("abc", "ab")
const NUL = relations("a\0b", "a\0c")
const UTF8 = relations("z", "é")

fn main:
    assert(LESS == 22 and GREATER == 42 and EQUAL == 49)
    assert(EMPTY == 49 and EMPTY_PREFIX == 22)
    assert(PREFIX == 22 and LONGER == 42)
    assert(NUL == 22 and UTF8 == 22)
    assert(relations("alpha", "beta") == LESS)
    assert(relations("beta", "alpha") == GREATER)
    assert(relations("alpha", "alpha") == EQUAL)
    assert(relations("", "") == EMPTY)
    assert(relations("", "a") == EMPTY_PREFIX)
    assert(relations("ab", "abc") == PREFIX)
    assert(relations("abc", "ab") == LONGER)
    assert(relations("a\0b", "a\0c") == NUL)
    assert(relations("z", "é") == UTF8)
    print("ok")
