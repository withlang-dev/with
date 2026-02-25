// Phase 2 gap: chained if let not implemented
fn main() -> i32 =
    let a: ?i32 = Some(1)
    let b: ?i32 = Some(2)
    if let Some(x) = a, let Some(y) = b:
        if x + y == 3 then 0 else 1
    else
        1
