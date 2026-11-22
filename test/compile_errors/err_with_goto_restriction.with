//! expect-check-fail: goto would enter a block from outside
// §13.5b: `goto` inside a `with` block is subject to the normal goto
// restrictions — it may exit scopes but not enter one. Entering a loop body
// from a `with` block is rejected with the same diagnostic as outside `with`.
type Guard {}
impl Scoped[i32] for Guard:
    fn with_enter(self: &Self) -> i32: 0
    fn with_exit(self: &Self) -> Unit: return

fn f(j: bool) -> i32:
    let g = Guard {}
    with g as d:
        if j:
            goto 'inside
    for i in 0..3:
        'inside:
            return i
    return -1

fn main:
    let _ = f(true)
