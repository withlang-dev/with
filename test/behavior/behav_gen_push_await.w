//! expect-stdout: 6
//! expect-stdout: 13

// D69 (§13.4): a generator's body is ordinary code, so `.await` in it
// suspends the consumer's fiber; `.await` in the consuming loop's body is
// the consumer's own.
async fn twice(x: i32) -> i32:
    x * 2

gen fn doubled(n: i32) -> i32:
    for i in 0..n:
        yield twice(i).await

gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

fn main:
    var s = 0
    for v in doubled(3):
        s += v
    print(s)
    var t = 1
    for v in upto(4):
        t += twice(v).await
    print(t)
