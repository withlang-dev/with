//! expect-error: cannot derive Copy for a type with non-Copy fields

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
@[derive(Copy)]
type BadCopy { data: List[Tok] }

fn main:
    let _ = BadCopy { data: List[Tok].new() }
