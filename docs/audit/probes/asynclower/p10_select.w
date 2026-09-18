async fn ready(value: i32) -> i32:
    value

async fn m:
    let left = ready(1)
    let right = ready(2)
    select await:
        x = left => print(f"{x}")
        y = right => print(f"{y}")
