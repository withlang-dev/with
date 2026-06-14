//! expect-error: Option.flatten() requires Option[Option[T]]

fn main:
    let x: Option[i32] = Some(1)
    let _ = x.flatten()
