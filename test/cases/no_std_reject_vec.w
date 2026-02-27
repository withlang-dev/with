// FLAGS: --no-std --expect-error
// NEGATIVE: Vec rejected in no_std mode (Section 18.7)
fn main -> i32:
    let v = Vec.new()
    0
