// Integration test: option chaining with match and functions
fn lookup_price(id: i32) -> ?i32 =
    match id
        1 -> Some(100)
        2 -> Some(50)
        3 -> Some(75)
        _ -> None

fn discount(price: i32) -> ?i32 =
    if price >= 75: Some(price - 10)
    else None

fn get_final_price(id: i32) -> i32 =
    let base = lookup_price(id) ?? 0
    discount(base) ?? base

fn main() -> i32 =
    println(get_final_price(1))
    println(get_final_price(2))
    println(get_final_price(3))
    println(get_final_price(99))
    0
