//! expect-stdout: ok
extern fn print(s: str) -> void

fn main:
    let content = embed_file("embed_file_data.txt")
    assert(content == "embedded content here")
    print("ok")
