// Test or-patterns with enum variants

type Color = Red | Green | Blue | Yellow

fn is_warm(c: Color) -> i32:
    match c
        Red | Yellow -> 1
        Green | Blue -> 0

fn main -> i32:
    assert(is_warm(Red) == 1)
    assert(is_warm(Yellow) == 1)
    assert(is_warm(Green) == 0)
    assert(is_warm(Blue) == 0)
