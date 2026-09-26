//! expect-check-fail: generator `doubled` may suspend, and its body runs inside this loop

// D69 (§13.4, §14.3, #1724): a specialization of a generic generator whose
// body may suspend makes its consuming loop may-suspend, like a plain one;
// the note names the generator as declared.
async fn twice(x: i32) -> i32:
    x * 2

gen fn doubled[T](tag: T, n: i32) -> i32:
    for i in 0..n:
        yield twice(i).await

fn main:
    var s = 0
    no_suspend:
        for v in doubled("t".clone(), 3):
            s += v
    print(s)
