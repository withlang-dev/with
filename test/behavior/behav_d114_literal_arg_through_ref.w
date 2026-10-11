//! expect-stdout: 6 15 2 3

// §4.3c (D114): a literal at a `&` parameter takes the element type of the
// collection the parameter views; `total([1, 2, 3])` at `xs: &List[i32]`
// is a List[i32], never the isize default.
use std.collections.HashSet

fn total(xs: &List[i32]): xs.iter() |> sum()
fn wide(xs: &List[u8]):
    var sum: u32 = 0
    for x in xs: sum = sum + x as u32
    sum
fn pair(xs: &[i32; 2]): xs[0] + xs[1]
fn count(xs: &HashSet[i32]): xs.len()

fn main:
    print(f"{total([1, 2, 3])} {wide([4, 5, 6])} {pair([1, 1])} {count([1, 2, 3])}")
