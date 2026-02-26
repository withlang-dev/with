// Test chained if-else expressions
fn classify(x: i32) -> str:
    if x > 100 then "big"
    else if x > 50 then "medium"
    else if x > 10 then "small"
    else "tiny"

fn main -> i32:
    println(classify(200))
    println(classify(75))
    println(classify(25))
    println(classify(5))
