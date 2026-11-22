//! expect-stdout: if 1 6
//! expect-stdout: match 100 200 199
//! expect-stdout: block arm 7 7
//! expect-stdout: nested 30 31
//! expect-stdout: unannotated 10 20
//! expect-stdout: unit 0 5
//! expect-stdout: hits 3

// §9.1 / D60 with D43: the arms of a tail `if`/`match` keep their value
// (#1337), and under a declared non-`Unit` return the body's own tail and an
// arm's tail are one rule — each yields a read of its place after the
// store, bare or as the tail of an arm block, at any depth. An unannotated
// body's arms join as values (D43); its own tail assignment is a statement.

var g: i32 = 0
var hits: i32 = 0

fn if_arms(p: bool) -> i32:
    if p: g = 1 else: g += 5

fn match_arms(n: i32) -> i32:
    match n:
        0 => g = 100
        1 => { hits += 1; g = 200 }
        _ =>
            hits += 1
            g -= 1

fn block_arm(p: bool) -> i32:
    if p:
        hits += 1
        g = 7
    else:
        g

fn nested(n: i32) -> i32:
    if n > 0:
        match n:
            1 => g = 30
            _ => { g += 1 }
    else:
        g = -1

fn unannotated(p: bool):
    if p: g = 10 else: g = 20

// `-> Unit`: every tail is a statement.
fn unit_tail(p: bool) -> Unit:
    if p: g = 5 else: g = 6

fn main:
    let a = if_arms(true)
    print(f"if {a} {if_arms(false)}")
    let m0 = match_arms(0)
    let m1 = match_arms(1)
    print(f"match {m0} {m1} {match_arms(2)}")
    print(f"block arm {block_arm(true)} {block_arm(false)}")
    let n1 = nested(1)
    print(f"nested {n1} {nested(2)}")
    let u: i32 = unannotated(true)
    print(f"unannotated {u} {unannotated(false)}")
    g = 0
    let before = g
    unit_tail(true)
    print(f"unit {before} {g}")
    print(f"hits {hits}")
