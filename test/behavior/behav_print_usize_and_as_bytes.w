//! expect-stdout: 5
//! expect-stdout: -3
//! expect-stdout: 3
//! expect-stdout: 101

// #1673: usize/isize satisfy Display like every other integer;
// #1633: str.as_bytes() is the §16.5 byte view.
fn main:
    let n: usize = 5
    print(n)
    let m: isize = -3
    print(m)
    let b = "hey".as_bytes()
    print(b.len())
    print(b[1])
