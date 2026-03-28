//! expect-stdout: ok

fn select_then() -> i32:
    comptime if 1 == 1:
        42
    else:
        missing_then_branch_symbol

fn select_else() -> i32:
    comptime if 1 == 2:
        missing_else_branch_symbol
    else:
        7

fn sum_unrolled() -> i32:
    var total = 0
    comptime for i in [1, 2, 3, 4, 5]:
        total = total + i
    total

fn main:
    assert(select_then() == 42)
    assert(select_else() == 7)
    assert(sum_unrolled() == 15)
    println("ok")
