// Test implicit Ok(()) for Result[Unit, E] — fallthrough without explicit Ok
fn validate(x: i32) -> Result[Unit, str]:
    if x < 0
        Err("negative")

fn main -> i32:
    let r = validate(5)
    println(r.is_ok())
    let r2 = validate(-1)
    println(r2.is_err())
