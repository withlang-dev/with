//! skip-windows: issue #801: embed_file path resolution fails on native Windows
//! expect-stdout: ok

use embed_file_phase8.helper

const IMPORTED_DATA: str = comptime load_text()

fn main:
    assert(IMPORTED_DATA == "relative helper data\n")
    print("ok")
