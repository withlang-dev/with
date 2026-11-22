//! expect-error: 'Vec' names no type: the growable sequence is 'List' (D118)

// D118: `Vec` stays unbound, so old code learns the new name in type
// position.
fn total(xs: &Vec[i32]) -> i32: xs.len() as i32

fn main:
    print(total(&[1, 2]))
