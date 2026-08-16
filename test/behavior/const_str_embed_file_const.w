//! skip-windows: issue #801: embed_file path resolution fails on native Windows
//! expect-stdout: ok

const EMPTY: str = ""
const GREETING: str = "hello\n"
const PATH: str = "const_str_embed_file_const.txt"
const DATA: str = embed_file(PATH)

fn main:
    assert(EMPTY == "")
    assert(GREETING == "hello\n")
    assert(DATA == "embedded const data\n")
    assert((comptime embed_file(PATH)) == "embedded const data\n")
    print("ok")
