//! expect-error: type '[i32; 2, 3]' does not implement trait 'Display'

// D119 Amendment 1: the compiler prints a nested array in index order,
// however it was written.
fn f(m: [[i32; 3]; 2]): m

fn main:
    let m: [i32; 2, 3] = [0; 2, 3]
    print(f(m))
