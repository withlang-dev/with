//! expect-error: cannot mutate immutable binding `n`

// #1354 × D12 (§9.5): a `mut fn` on a scalar owner replaces the whole value,
// which a `let` pattern binding forbids exactly as a named `let` does.

extend i32:
    mut fn bump(): self += 1

fn main:
    let (n, s) = (5, "hello")
    n.bump()
    print(f"{n} {s}")
