//! expect-stdout: 2 2 5 7
//! expect-stdout: 1.5 4
//! expect-stdout: 1 1

// #1450 (§4.8): a tuple index after `.` is an integer, never the start of a
// float literal, so it can be followed by another `.`: `t.0.len()` calls
// `len` on element 0 and `n.0.1` is a nested index. Float literals, a range
// after an index, and indices inside f-string holes keep working.
fn main:
    let t = ("ab".clone(), 3)
    let n = ((1, 2), 3)
    let deep = (((4, 5), 6), 7)
    let tl = t.0.len()
    print(f"{tl} {n.0.1} {deep.0.0.1} {deep.1}")
    let p = (1.5, 2.5)
    print(f"{p.0} {p.0 + p.1}")
    var count = 0
    for i in n.0.0..n.0.1:
        count += i
    print(f"{count} {n.0.0}")
