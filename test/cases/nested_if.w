// Test nested if/else expressions
fn classify(n: i32) -> str:
    if n > 100: "big"
    else if n > 10: "medium"
    else if n > 0: "small"
    else "non-positive"

fn main -> i32:
    println(classify(200))
    println(classify(50))
    println(classify(5))
    println(classify(-1))
