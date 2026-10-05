//! expect-check-fail: this use demands `HashSet[i32]` of a binding another use demands `Vec[i32]` of

// D93 (§4.3c rule 1): uses that demand two different types are an error at
// the second, naming both.
use std.collections.HashSet

fn total(xs: &Vec[i32]): xs.iter() |> sum()

fn distinct(xs: &HashSet[i32]): xs.len()

fn main:
    let xs = [1, 2, 3]
    print(total(xs))
    print(distinct(xs))
