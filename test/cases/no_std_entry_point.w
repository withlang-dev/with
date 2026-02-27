// FLAGS: --no-std
// POSITIVE: @[entry] works as alternative entry point (Section 18.7)
@[entry]
fn start -> i32:
    let x = 42
    assert(x == 42)
    0
