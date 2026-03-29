//! expect-stdout: ok
extern fn print(s: str) -> void

use embed_file_phase8.helper

const IMPORTED_DATA: str = comptime load_text()

fn main:
    assert(IMPORTED_DATA == "relative helper data\n")
    print("ok")
