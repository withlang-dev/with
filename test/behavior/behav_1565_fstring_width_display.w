//! expect-stdout: [  true]
//! expect-stdout: [false ]
//! expect-stdout: [   Red]
//! expect-stdout: [Some(3)   ]

// #1565 (§15.4.6, §15.4.8): a width or alignment pads the value's display;
// a bool printed `1`/`0` and an enum was read as a str header.

enum Color:
    Red
    Blue

fn main:
    let flag = true
    print(f"[{flag:>6}]")
    let off = false
    print(f"[{off:<6}]")
    let c = Color.Red
    print(f"[{c:>6}]")
    let o: Option[i32] = Some(3)
    print(f"[{o:<10}]")
