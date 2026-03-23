//! expect-error: where clause references unknown trait 'Nonexistent'
fn process[T](x: T) -> i32 where T: Nonexistent:
    42

fn main:
    let r = process(10)
