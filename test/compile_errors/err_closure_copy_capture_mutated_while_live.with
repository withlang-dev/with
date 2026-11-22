//! expect-check-fail: while `f` is a live view

// §12.4: captures are by place regardless of whether the type is Copy, so
// a non-move closure that reads `n` is a live view of `n`; assigning `n`
// while the closure is still used is the ordinary view-liveness error
// (exactly what fires for a non-Copy `xs`). `move () => n + 1` snapshots.
fn main:
    var n = 1
    let f = () => n + 1
    n = 5
    print(f())
