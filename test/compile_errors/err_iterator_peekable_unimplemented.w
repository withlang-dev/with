//! expect-error: iterator operation 'peekable' from §13.3 is not implemented yet

fn main:
    let xs: List[i32] = List.new()
    let _ = xs.iter().peekable()
