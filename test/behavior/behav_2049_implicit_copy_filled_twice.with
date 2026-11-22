//! expect-stdout: 5 7 12
// D87 (§7.3a): an `implicit T` parameter is filled when T is Copy — every
// fill is a copy of the binding, which stays usable.
type Scale: Copy { k: i32 }

fn scaled(x: i32, s: implicit Scale) -> i32: x * s.k

fn main:
    with by(Scale { k: 1 }):
        let a = scaled(5)
        let b = scaled(7)
        print(f"{a} {b} {a + b}")
