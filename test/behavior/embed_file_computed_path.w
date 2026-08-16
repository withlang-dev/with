//! skip-windows: issue #801: embed_file path resolution fails on native Windows
//! expect-stdout: ok

const DIR: str = "lib/embed_file_computed"
const NAME: str = "payload"
const DATA: str = embed_file(DIR ++ "/" ++ NAME ++ ".txt")

fn main:
    assert(DATA == "computed payload\n")
    print("ok")
