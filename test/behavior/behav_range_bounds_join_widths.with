//! expect-stdout: -3 -2
//! expect-stdout: 2147483647 2147483648 2147483649
//! expect-stdout: 1 2 3
//! expect-stdout: 2 3

// §4.2.6: a range's typed bounds meet where an operator's operands meet,
// at the type one widens into losslessly, whichever side is narrower.
// `n..a` (isize..i32) was accepted while `a..n` (i32..isize) was refused
// as a narrowing: the end was an owned demand of the start's type, so a
// loop to `xs.len()` from an `i32` start needed `as i32` on the length.

fn main:
    let a: i32 = -3
    let n: isize = -1
    var out = ""
    for i in a..n:
        out = out ++ f"{i} "
    print(out.trim())

    let start: i32 = 2147483647
    let wide: i64 = 2147483650
    out = ""
    for i in start..wide:
        out = out ++ f"{i} "
    print(out.trim())

    let one: i32 = 1
    let three: isize = 3
    out = ""
    for i in one..=three:
        out = out ++ f"{i} "
    print(out.trim())

    var xs: List[i32] = List.new()
    for v in [10, 20, 30, 40]: xs.push(v)
    let from: i32 = 2
    let r = from..xs.len()
    out = ""
    for i in r:
        out = out ++ f"{i} "
    print(out.trim())
