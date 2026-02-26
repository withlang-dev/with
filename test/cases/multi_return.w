// Test multiple return paths
fn classify(x: i32) -> str =
    if x > 0:
        return "positive"
    if x < 0:
        return "negative"
    "zero"

fn main() -> i32 =
    println(classify(5))
    println(classify(-3))
    println(classify(0))
    0
