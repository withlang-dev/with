// T10: dangling-else. Inner if/else on one line inside outer if without else.
fn classify(x: i32) -> i32:
    if x > 0:
        if x > 10: 100 else: 10
    else:
        -1

fn main:
    assert(classify(20) == 100)
    assert(classify(5) == 10)
    assert(classify(-3) == -1)
