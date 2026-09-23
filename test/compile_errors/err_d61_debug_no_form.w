//! expect-error: cannot format a value of type 'fn(i32) -> i32' with :? — §15.4.7 gives it no Debug form

fn twice(n: i32) -> i32: n * 2

fn main:
    let f = twice
    print(f"{f:?}")
