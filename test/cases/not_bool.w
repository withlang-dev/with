fn main() -> i32 =
    let a: bool = false
    let b: bool = true
    let result = if not a and b then 42 else 0
    assert(result == 42)
    0
