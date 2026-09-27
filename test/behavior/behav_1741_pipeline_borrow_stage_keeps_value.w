//! expect-stdout: 3 3
// #1741: a pipeline stage moves its left-hand side exactly as the direct
// call does, and no more: a stage whose first parameter is `&T` borrows, so
// the value stays usable after `xs |> total()`.

fn total[T](xs: &Vec[T]) -> i64: xs.len()

fn main:
    let xs: Vec[str] = ["a".clone(), "b".clone(), "c".clone()]
    let n = xs |> total()
    print(f"{n} {xs.len()}")
