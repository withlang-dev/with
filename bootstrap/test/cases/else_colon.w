// Test else: colon form (bare else block)
fn classify(x: i32) -> str:
    if x > 10:
        "big"
    else:
        "small"

fn multi_branch(x: i32) -> str:
    if x == 1:
        "one"
    else if x == 2:
        "two"
    else:
        "other"

fn else_colon_block(x: i32) -> i32:
    if x > 0:
        var a = x + 1
        a
    else:
        var b = x - 1
        b

fn main -> i32:
    println(classify(20))
    println(classify(5))
    println(multi_branch(1))
    println(multi_branch(2))
    println(multi_branch(3))
    assert(else_colon_block(10) == 11)
    assert(else_colon_block(-5) == -6)
