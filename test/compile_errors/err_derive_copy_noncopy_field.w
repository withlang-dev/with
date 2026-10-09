//! expect-error: cannot derive Copy for a type with non-Copy fields

@[derive(Copy)]
type BadCopy { data: List[u8] }

fn main:
    let _ = BadCopy { data: List[u8].new() }
