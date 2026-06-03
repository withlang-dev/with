//! expect-error: E0702

async fn ready(value: i32) -> i32:
    value

fn main:
    no_suspend:
        let left = ready(1)
        let right = ready(2)
        select await:
            x = left => assert(x == 1)
            y = right => assert(y == 2)
