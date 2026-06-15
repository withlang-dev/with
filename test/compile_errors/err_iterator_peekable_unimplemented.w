//! expect-error: iterator operation 'peekable' from §13.3 is not implemented yet

fn main:
    let xs: Vec[i32] = Vec.new()
    let _ = xs.iter().peekable()
