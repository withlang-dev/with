type Number = i32

fn add(a: i32, b: i32) -> i32:
    a + b

let seed: i32 = 7

extern fn puts(msg: str) -> i32

fn main:
    let total: i32 = add(seed, 5)
    total
