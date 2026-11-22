//! expect-check-fail: cannot mutate `xs` while `v` is a live view into it

// #615: a view of the enclosing function is live across a call whose
// closure argument writes the viewed place. Checking the closure's body
// used to delete the view's borrow, because the view has no later use
// inside the body.
fn run(body: fn() -> i32) -> i32: body()

fn main:
    var xs: List[i64] = [7]
    let v = &xs[0]
    let r = run(() => {
        xs.push(1)
        1
    })
    print(*v + r as i64)
