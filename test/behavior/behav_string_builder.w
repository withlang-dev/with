//! expect-stdout: ok

fn test_basic_builder:
    var sb = StringBuilder.new()
    assert(sb.is_empty())
    sb.push_str("ab")
    sb.push_byte(99 as u8)
    sb.push_char(100)
    assert(sb.len() == 4)
    assert(sb.to_str() == "abcd")

fn test_builder_growth:
    var sb = StringBuilder.with_capacity(1)
    for i in 0..100:
        sb.push_str("x")
    assert(sb.len() == 100)
    assert(sb.to_str() == "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")

fn test_builder_empty:
    var sb = StringBuilder.with_capacity(0)
    assert(sb.to_str() == "")

fn main:
    test_basic_builder()
    test_builder_growth()
    test_builder_empty()
    print("ok")
