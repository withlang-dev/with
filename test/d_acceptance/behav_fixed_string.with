//! expect-stdout: ok

fn main:
    var s = FixedString[4].new()
    assert(s.is_empty())
    assert(s.capacity() == 4)
    assert(s.push_byte(65 as u8))
    assert(s.push_str("BC"))
    assert(s.len() == 3)
    assert(s.len_i32() == 3)
    assert(s.len_i64() == 3)
    assert(s.as_view() == "ABC")
    assert(not s.push_str("DE"))
    assert(s.as_view() == "ABC")
    s.clear()
    assert(s.is_empty())
    assert(s.push_str("xy"))
    assert(s.equals("xy"))

    let t: FixedString[4] = FixedString[4].new()
    let _ = t
    print("ok")
