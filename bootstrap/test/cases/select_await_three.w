// Test: select await across three tasks
async fn a -> i32: 1
async fn b -> i32: 2
async fn c -> i32: 3

fn main -> i32:
    let r = select await:
        x = a() -> x + 10
        y = b() -> y + 20
        z = c() -> z + 30

    assert(r == 11 or r == 22 or r == 33)
