//! expect-error: embed_file: could not read

const DATA: str = embed_file("does_not_exist.txt")

fn main:
    assert(DATA.len() == 0)
