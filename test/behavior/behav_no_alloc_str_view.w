//! expect-stdout: ok

@[no_alloc]
fn view_len(value: &str) -> i32:
    value.len()

fn main:
    assert(view_len("hello") == 5)
    let view: &str = "world"
    assert(view_len(view) == 5)
    print("ok")

