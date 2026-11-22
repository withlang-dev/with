//! expect-stdout: 7
//! expect-stdout: 9
//! expect-stdout: 2

// #2379 (D93, D113): a bracket literal argument to a generic array
// parameter binds T from its elements and, for `[T; N]`, N from its count,
// then is typed as the array the parameter demands. Under no demand the
// literal is a List, and "cannot infer type parameter 'T'" was reported.
fn first[T](xs: [T; 3]) -> T: xs[0]
fn third[T](xs: [T; 3]) -> T: xs[2]
fn head[T, N](xs: [T; N]) -> T: xs[0]

fn main:
    print(first([7, 8, 9]))
    print(third([7, 8, 9]))
    print(head([2, 4]))
