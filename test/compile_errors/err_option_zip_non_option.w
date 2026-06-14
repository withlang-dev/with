//! expect-error: Option.zip() expects an Option argument

fn main:
    let x: Option[i32] = Some(1)
    let _ = x.zip(2)
