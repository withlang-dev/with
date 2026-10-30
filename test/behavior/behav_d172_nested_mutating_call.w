//! expect-stdout: 2 1 2
// D172 (§3.2a): exclusive access begins when the call does. The argument
// `xs.pop().unwrap()` runs first and its result retains nothing of `xs`,
// so the push that follows is legal (§5.4 had refused every nested
// mutating call on the same place; Rust's two-phase borrows refuse this).

fn main:
    var xs: List[i32] = []
    xs.push(1)
    xs.push(2)
    xs.push(xs.pop().unwrap())
    print(f"{xs.len()} {xs[0]} {xs[1]}")
