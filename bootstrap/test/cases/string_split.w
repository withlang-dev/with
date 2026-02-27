// Test: string split and join
fn main -> i32:
    // Split
    let csv = "a,b,c,d"
    let parts = csv.split(",")
    assert(parts.len() == 4)
    assert(parts.get(0) == "a")
    assert(parts.get(1) == "b")
    assert(parts.get(2) == "c")
    assert(parts.get(3) == "d")

    // Join
    let joined = parts.join("-")
    assert(joined == "a-b-c-d")

    // Replace
    let text = "hello world hello"
    let replaced = text.replace("hello", "hi")
    assert(replaced == "hi world hi")

    // Split with multi-char delimiter
    let path = "usr::local::bin"
    let segs = path.split("::")
    assert(segs.len() == 3)
    assert(segs.get(0) == "usr")
    assert(segs.get(2) == "bin")

