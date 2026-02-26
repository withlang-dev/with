// Test that defer doesn't contain return (should compile with warning but work)
// This test validates that valid defer patterns still work

fn main() -> i32 =
    var x = 0
    defer x = 42
    assert(x == 0)
    0
