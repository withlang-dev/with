//! expect-stdout: 8 9 3
//! expect-stdout: 16 hi b -5 true
//! expect-stdout: 3 -2 3 7

// #1484: a global whose initializer is not a literal C can state (a shift,
// an array literal, a variant constructor, a call, a concatenation, a
// negated global) is initialized before `main`, in declaration order
// (§9.1c). The C backend declared all of them zero-initialized and never
// assigned them, so the program printed zeros.
fn double(x: i32) -> i32: x * 2

let SHIFTED: i32 = 1 << 3
let TABLE = [7u16, 9u16]
let MAYBE = Some(3)
let TWICE = double(SHIFTED)
let NAMES = ["a", "b"]
let GREETING = "hi " ++ NAMES[1]
let FIVE = 5
let MINUS_FIVE = -FIVE
let READY = not false

// Tables of constants are C constant initializers, fields named in
// declaration order whatever order the literal spells them in (pcre2's
// ucd records; lowered at startup they cost clang minutes).
type Rec { a: u8, b: i16 }
let RECS: [3]Rec = [Rec { a: 1, b: -2 }, Rec { b: 4, a: 3 }, Rec { a: 5, b: 6 }]
let GRID: [2][2]i32 = [[1, 2], [3, 4]]
let ONE = Rec { a: 7, b: 0 }

fn main:
    print(f"{SHIFTED} {TABLE[1]} {MAYBE.unwrap()}")
    print(f"{TWICE} {GREETING} {MINUS_FIVE} {READY}")
    print(f"{RECS[1].a} {RECS[0].b} {GRID[1][0]} {ONE.a}")
