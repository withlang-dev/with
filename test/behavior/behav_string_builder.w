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

comptime fn make_comptime_builder_text() -> str:
    var sb = StringBuilder.with_capacity(2)
    sb.push_str("co")
    sb.push_str("mp")
    sb.push_byte(116 as u8)
    sb.push_char(105)
    sb.push_str("me")
    sb.to_str()

comptime fn make_comptime_builder_len() -> i64:
    var sb = StringBuilder.new()
    sb.push_str("length")
    sb.len()

comptime fn make_comptime_builder_empty() -> bool:
    var sb = StringBuilder.new()
    sb.is_empty()

const COMPTIME_BUILDER_TEXT: str = comptime make_comptime_builder_text()
const COMPTIME_BUILDER_LEN: i64 = comptime make_comptime_builder_len()
const COMPTIME_BUILDER_EMPTY: bool = comptime make_comptime_builder_empty()

fn test_comptime_builder:
    assert(COMPTIME_BUILDER_TEXT == "comptime")
    assert(COMPTIME_BUILDER_LEN == 6)
    assert(COMPTIME_BUILDER_EMPTY)

fn main:
    test_basic_builder()
    test_builder_growth()
    test_builder_empty()
    test_comptime_builder()
    print("ok")
