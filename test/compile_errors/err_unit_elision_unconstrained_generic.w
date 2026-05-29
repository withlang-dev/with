//! expect-check-fail: wrong argument count

fn id[T](val: T) -> T: val

fn main:
    let x = id()
