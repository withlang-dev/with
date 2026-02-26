// Test: match with wildcard and or-patterns

type Day = Mon | Tue | Wed | Thu | Fri | Sat | Sun

fn is_weekend(d: Day) -> bool =
    match d
        Sat | Sun -> true
        _ -> false

fn day_type(d: Day) -> i32 =
    match d
        Mon | Tue | Wed | Thu | Fri -> 1
        Sat | Sun -> 2

fn main() -> i32 =
    assert(not is_weekend(Mon))
    assert(not is_weekend(Wed))
    assert(is_weekend(Sat))
    assert(is_weekend(Sun))

    assert(day_type(Mon) == 1)
    assert(day_type(Fri) == 1)
    assert(day_type(Sat) == 2)
    assert(day_type(Sun) == 2)

    println("ok")
    0
