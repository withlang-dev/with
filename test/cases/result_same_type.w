// Test Result[i32, i32] where T==E — implicit Ok wrapping
fn check(x: i32) -> Result[i32, i32]:
    if x > 0
        x
    else
        Err(-1)

fn main -> i32:
    let r1 = check(42)
    let r2 = check(-5)
    println(r1.unwrap())
    println(r2.is_err())
