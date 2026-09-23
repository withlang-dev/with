//! expect-stdout: 2
//! expect-stdout: 5
//! expect-stdout: 6

// §12.4: "`move ||` transfers ownership, which for a Copy value is a copy."
// The move closure keeps the value `n` had at creation; the outer `n` may
// be reassigned afterwards and the closure still returns its snapshot. A
// non-move closure is a view of `n` and sees the current value.
fn main:
    var n = 1
    let snap = move () => n + 1
    n = 5
    print(snap())
    print(n)
    let live = () => n + 1
    print(live())
