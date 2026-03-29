//! expect-stdout: ok
extern fn print(s: str) -> void

const EMPTY_FILE: str = embed_file("embed_file_empty.txt")

fn main:
    assert(EMPTY_FILE == "")
    print("ok")
