// FLAGS: --no-std --expect-error
// NEGATIVE: println rejected in no_std mode (Section 18.7)
fn main -> i32:
    println("hello")
    0
