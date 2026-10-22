//! expect-check-fail: a path that calls `grow` itself disagrees with the return type the other paths gave it
// D143: after the other paths decide the type (an integer here), a path
// through the self-call that produces something else is named.
fn grow(n: i32):
    if n == 0: 1 else: "x" ++ grow(n - 1)
fn main:
    print(f"{grow(2)}")
