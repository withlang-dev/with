//! expect-stdout: [0, 1, 2, 3]
//! expect-stdout: [w0|w1] [w0|w1|w2|w3|w4]
//! expect-stdout: ok

// #1491: `out = out ++ x` after an `if` appends in place when neither arm
// made `out` alias another string (test/phase/
// mir_str_append_after_if_in_place.w checks the lowering). The values are
// the same either way; this keeps the in-place append's output honest.

fn elem(i: i32): f"{i}"

fn lit(n: i32) -> str:
    var out = "["
    for i in 0..n:
        if i > 0:
            out = out ++ ", "
        out = out ++ elem(i)
    out ++ "]"

fn joined(n: i32) -> str:
    var out = "["
    for i in 0..n:
        if i == 0:
            out = out ++ "w0"
        else:
            out = out ++ f"|w{i}"
    out ++ "]"

fn main:
    print(lit(4))
    print(f"{joined(2)} {joined(5)}")
    let big = lit(20000)
    assert(big.len() == 128890)
    print("ok")
