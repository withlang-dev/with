// Test match with guards on integer patterns
fn classify(n: i32) -> str:
    match n
        0 -> "zero"
        n if n > 0 -> "positive"
        _ -> "negative"

fn main -> i32:
    println(classify(0))
    println(classify(5))
    println(classify(-3))
