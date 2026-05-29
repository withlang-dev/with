//! expect-error: cannot derive Copy for a type with non-Copy fields

@[derive(Copy)]
type BadCopy { data: Vec[u8] }

fn main:
    let _ = BadCopy { data: Vec[u8].new() }
