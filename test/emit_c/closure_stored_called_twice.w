//! expect-stdout: 3
//! expect-stdout: 7
//! expect-stdout: 10

// #1766: a closure held in a local is called through the pair each time;
// the pair stays valid across calls and a capture is read each time.
fn main:
    let add = (a: i32, b: i32) => a + b
    print(add(1, 2))
    print(add(3, 4))
    var total = 0
    let acc = (x: i32) => total += x
    acc(3)
    acc(7)
    print(total)
