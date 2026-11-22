//! expect-error: a pipeline stage is one call, and this stage is an operator expression
// §9.9 (D95): `xs |> sum() * 2` is `xs |> (sum() * 2)`; the error says
// where the parentheses go.
fn main:
    let xs = [1, 2, 3]
    let doubled = xs.iter() |> sum() * 2
    print(doubled)
