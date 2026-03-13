//! expect-build-fail: no method 'len'

fn get_len[T](x: T) -> i32:
    x.len()

fn main:
    let n = get_len(42)
