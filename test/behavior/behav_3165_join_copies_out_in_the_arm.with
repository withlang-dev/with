//! expect-stdout: ok

// #3165: a `let` of an `if` or `match` whose arm views its own statement
// temporary takes the `str` (D179, §21.1); the copy is made in the arm,
// before the arm's temporary is freed. Made at the join, it read the freed
// slice: the right length, blank bytes (WITH_ALLOC_NO_REUSE=1 showed the
// text). Every shape of the matrix in #3165, each compared to the text it
// must read, under the allocator's normal reuse.

use std.string

fn both_trim(why: &str, k: i32) -> str:
    let tail = if k < 0: why.trim() else: why.trim()
    tail.to_owned()

fn both_slice_trim(why: &str, k: i32) -> str:
    let tail = if k < 0: why.slice(0, why.len()).trim() else: why.slice(2, why.len()).trim()
    tail.to_owned()

fn trim_or_slice(why: &str, k: i32) -> str:
    let tail = if k < 0: why.trim() else: why.slice(2, why.len())
    tail.to_owned()

fn param_or_slice_trim(why: &str, k: i32) -> str:
    let tail = if k < 0: why else: why.slice(2, why.len()).trim()
    tail.to_owned()

fn trim_or_slice_trim(why: &str, k: i32) -> str:
    let tail = if k < 0: why.trim() else: why.slice(2, why.len()).trim()
    tail.to_owned()

// A block arm: the statement before the tail is the arm's own, the tail's
// temporary is the arm's own.
fn block_arm(why: &str, k: i32) -> str:
    let tail = if k < 0: why.trim() else:
        let from = k
        why.slice(from, why.len()).trim()
    tail.to_owned()

// A join inside a join: each level copies in its own arm.
fn nested(why: &str, k: i32) -> str:
    let tail = if k < 0: why.trim() else: (if k == 2: why.slice(2, why.len()).trim() else: why.slice(3, why.len()).trim())
    tail.to_owned()

fn by_match(why: &str, k: i32) -> str:
    let tail = match k:
        0 => why.trim()
        2 => why.slice(2, why.len()).trim()
        _ => why.slice(3, why.len()).trim()
    tail.to_owned()

// The binding read many times after the arm's temporary is gone, with
// allocation in between: a view into the freed slice would be overwritten.
fn churn(why: &str) -> str:
    let tail = if why.len() > 4: why.slice(2, why.len()).trim() else: why.trim()
    var noise = ""
    for i in 0..64: noise = noise ++ f"{i};"
    tail ++ "" ++ (if noise.len() > 0: "" else: "?")

fn main:
    assert(both_trim("x, stored", 1) == "x, stored" and both_trim("x, stored", -1) == "x, stored")
    assert(both_slice_trim("x, stored", 1) == "stored" and both_slice_trim("x, stored", -1) == "x, stored")
    assert(trim_or_slice("x, stored", 1) == " stored" and trim_or_slice("x, stored", -1) == "x, stored")
    assert(param_or_slice_trim("x, stored", 1) == "stored" and param_or_slice_trim("x, stored", -1) == "x, stored")
    assert(trim_or_slice_trim("x, stored", 1) == "stored" and trim_or_slice_trim("x, stored", -1) == "x, stored")
    assert(block_arm("x, stored", 2) == "stored" and block_arm("x, stored", -1) == "x, stored")
    assert(nested("x, stored", 2) == "stored" and nested("x, stored", 3) == "stored" and nested("x, stored", -1) == "x, stored")
    assert(by_match("x, stored", 0) == "x, stored" and by_match("x, stored", 2) == "stored" and by_match("x, stored", 3) == "stored")
    assert(churn("x, stored") == "stored" and churn("ab") == "ab")
    print("ok")
