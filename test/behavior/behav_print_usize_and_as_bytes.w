//! expect-stdout: 5
//! expect-stdout: -3
//! expect-stdout: 3
//! expect-stdout: 101
//! expect-stdout: 3
//! expect-stdout: 104

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
    let owned = "hey".clone()
    let r: &str = &owned
    let through_ref = r as []u8
    print(through_ref.len())
    print(r.as_bytes()[0])
