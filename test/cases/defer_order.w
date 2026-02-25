// Test: Defer LIFO execution order
fn main() -> i32 =
    var x = 0
    defer x = x + 1
    defer x = x * 10
    // After body: x=0, defer reversal:
    // first: x = 0 * 10 = 0
    // then: x = 0 + 1 = 1
    x
