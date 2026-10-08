//! expect-stdout: ok

fn test_self_append_loop:
    var s = ""
    for _ in 0..64:
        s = s ++ "x"
    assert(s.len() == 64)
    assert(s.starts_with("xxxx"))
    assert(s.ends_with("xxxx"))

fn test_alias_falls_back:
    var a = "base"
    let b = a
    a = a ++ "!"
    assert(a == "base!")
    assert(b == "base")

fn test_branch_path_starts_static:
    var s = ""
    for i in 0..8:
        if i % 2 == 1:
            s = s ++ "a"
        s = s ++ "b"
    assert(s.len() == 12)
    assert(s.starts_with("ba"))
    assert(s.ends_with("ab"))

fn main:
    test_self_append_loop()
    test_alias_falls_back()
    test_branch_path_starts_static()
    print("ok")
