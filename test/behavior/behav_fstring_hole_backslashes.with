//! expect-stdout: ok

// #656: f-string hole normalization must not strip source-level
// backslashes. Nested raw strings keep their escapes (\t, \x41, \",
// \\), regex literals keep theirs (\d, \\), and the legacy escaped
// spelling {id(\"x\")} still has its outer layer stripped.

fn id(s: str) -> str: s

fn main:
    let t = "\t"
    assert(f"{"\t" == t}" == "true")
    assert(f"{"\x41"}" == "A")
    assert(f"{"a\"b"}" == "a\"b")
    assert(f"{"a\\b"}" == "a\\b")

    let s = "1 2 3"
    assert(f"{/\d/g.find_all(s).len32()}" == "3")
    assert(f"{/\s/g.find_all(s).len32()}" == "2")
    assert(f"{/\\/g.find_all("a\\b").len32()}" == "1")

    assert(f"{'\t' as i32}" == "9")

    assert(f"{id(\"call\")}" == "call")
    assert(f"{id(\"a\\\"b\")}" == "a\"b")
    print("ok")
