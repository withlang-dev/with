fn id(x: i32) -> i32 = x

fn main() -> i32 =
    let v = 2 |> id |> match
        1 -> 10
        2 -> 20
        _ -> 30
    if v == 20 then 0 else 1
