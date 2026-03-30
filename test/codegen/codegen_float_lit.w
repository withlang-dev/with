//! expect-stdout: 6
//! expect-stdout: 1
//! expect-stdout: 1
fn main:
    let pi = 3.14
    let two_pi = pi + pi
    let n = two_pi as i32
    print(int_to_string(n))
    let half = 0.5
    let one = half + half
    let m = one as i32
    print(int_to_string(m))
    let e = 2.718
    let floored = e as i32
    let check = floored - 1
    print(int_to_string(check))
