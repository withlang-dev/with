fn classify(n: i32) -> str =
    if n > 0:
        if n > 100: "large"
        else "small"
    else if n == 0: "zero"
    else "negative"

fn main() -> i32 =
    println(classify(200))
    println(classify(50))
    println(classify(0))
    println(classify(-5))
    0
