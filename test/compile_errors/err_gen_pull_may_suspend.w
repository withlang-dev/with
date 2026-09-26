//! expect-check-fail: g.pull() of generator 'doubled': its body may suspend here

// D69 (§13.4 Pulling, §14.3): a pulled generator runs on its own fiber,
// resumed by next(); a body that may suspend cannot be pulled, and the error
// names the suspension point.
async fn twice(x: i32) -> i32:
    x * 2

gen fn doubled(n: i32) -> i32:
    for i in 0..n:
        yield twice(i).await

fn main:
    var steps = doubled(3).pull()
    print(steps.next().unwrap())
