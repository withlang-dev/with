//! expect-stdout: 5
fn main:
    let x: Option[i32] = Some(5)
    let val = match x
        .Some(n) => n
        .None => -1
    println(int_to_string(val))
