// Test: Variable scoping in if/else blocks
fn main() -> i32 =
    var x = 10
    if true:
        x = 20
    if x == 20:
        x = x + 22
    if x == 42 then 0 else 1
