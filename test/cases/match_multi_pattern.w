// Test or-patterns in match
type Weekday = Mon | Tue | Wed | Thu | Fri | Sat | Sun

fn is_weekend(d: Weekday) -> bool =
    match d
        Sat | Sun -> true
        _ -> false

fn day_type(d: Weekday) -> str =
    match d
        Mon | Tue | Wed | Thu | Fri -> "weekday"
        Sat | Sun -> "weekend"

fn main() -> i32 =
    println(is_weekend(Sat))
    println(is_weekend(Mon))
    println(day_type(Wed))
    println(day_type(Sun))
    0
