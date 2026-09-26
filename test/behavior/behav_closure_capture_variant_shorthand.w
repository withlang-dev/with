//! expect-stdout: 5
//! expect-stdout: 5
//! expect-stdout: 5

// §12.4 (#1570): a local used inside a `.Variant(args)` shorthand is a
// capture like any other argument expression.
fn take(o: Option[i32]) -> i32: o.unwrap_or(0)
fn run(f: fn() -> Option[i32]) -> Option[i32]: f()
fn main:
    let n = 5
    print(take(run(() => .Some(n))))
    print(take(run(() => Some(n))))
    let g: fn() -> Option[i32] = () => .Some(n)
    print(take(g()))
