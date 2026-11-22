//! expect-stdout: ok
// §9: `return f(...)` inside a while IS a tail call — accepted.
@[tailrec]
fn down(n: i32) -> i32:
    while n > 0:
        return down(n - 1)
    n
fn main:
    assert(down(5) == 0)
    print("ok")
