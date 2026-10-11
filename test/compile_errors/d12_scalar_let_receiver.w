//! expect-error: cannot mutate immutable binding `y`

// D12 (§9.5): on a scalar owner every mut-fn write replaces the whole
// value — on a `let` binding that is exactly the forbidden rebinding.

extend i32:
    mut fn bump(): self += 1

fn main:
    let y: i32 = 5
    y.bump()
