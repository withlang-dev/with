fn main() -> i32 =
    let x: Option[i32] = Some(42)
    assert(x ?? 0 == 42)
    0
