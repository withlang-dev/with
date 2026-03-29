//! expect-stdout: ok
extern fn print(s: str) -> void

const CONTENT: str = embed_file("embed_file_data.txt")

fn main:
    assert(CONTENT == "embedded content here")
    print("ok")
