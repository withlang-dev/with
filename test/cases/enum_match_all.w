// Test: exhaustive enum matching (all variants)
type Season = Spring | Summer | Autumn | Winter

fn temp(s: Season) -> i32 =
    match s
        Spring -> 15
        Summer -> 30
        Autumn -> 10
        Winter -> 0

fn is_warm(s: Season) -> bool =
    match s
        Spring -> true
        Summer -> true
        Autumn -> false
        Winter -> false

fn main() -> i32 =
    assert(temp(Spring) == 15)
    assert(temp(Summer) == 30)
    assert(temp(Autumn) == 10)
    assert(temp(Winter) == 0)
    assert(is_warm(Spring))
    assert(is_warm(Summer))
    assert(not is_warm(Autumn))
    assert(not is_warm(Winter))
    assert(temp(Spring) + temp(Summer) + temp(Autumn) + temp(Winter) - 13 == 42)
    0
