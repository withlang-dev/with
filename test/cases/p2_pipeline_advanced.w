// Phase 2 gap: advanced pipeline forms (<|, >>, <<, placeholder _) not implemented
fn inc(x: i32) -> i32 = x + 1
fn main() -> i32 =
    let f = inc >> inc
    let v = f <| 40
    if v == 42 then 0 else 1
