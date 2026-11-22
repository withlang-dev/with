//! expect-error: E0702

// D69 (§13.4, §14.3): a generator whose body may suspend makes its consuming
// loop may-suspend — the loop runs the generator's body.
async fn twice(x: i32) -> i32:
    x * 2

gen fn doubled(n: i32) -> i32:
    for i in 0..n:
        yield twice(i).await

fn main:
    var s = 0
    no_suspend:
        for v in doubled(3):
            s += v
    print(s)
