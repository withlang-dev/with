//! expect-check-fail: unknown method 'len' for type 'i32'

fn get_len[T](x: T) -> i32:
    x.len()

fn main:
    let n = get_len(42)
