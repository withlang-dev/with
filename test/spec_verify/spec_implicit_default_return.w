// POSITIVE: fn returning i32 with no explicit return gives 0 (§4.10)
fn compute() -> i32:
    let x = 42
    println(x)

fn main -> i32:
    compute()
    println("default return ok")
