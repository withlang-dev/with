fn to_str(b: bool) -> str =
    match b
        true -> "yes"
        false -> "no"

fn main() -> i32 =
    println(to_str(true))
    println(to_str(false))
    println(to_str(3 > 2))
    println(to_str(1 > 5))
    0
