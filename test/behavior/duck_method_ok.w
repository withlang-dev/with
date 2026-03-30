//! expect-stdout: 5

fn get_len[T](x: T) -> i32:
    x.len()

fn main:
    print(int_to_string(get_len("hello")))
