//! expect-debug-alloc: leak count=0
// #1036/#1098: compiled code and tables die with their final owner;
// clones and named captures remain valid after the original Regex dies.
use std.regex

fn cloned_pattern() -> Regex:
    let original = Regex.compile("(?<word>abc)").unwrap()
    original.clone()

fn escaped_captures() -> Captures:
    let original = Regex.compile("(?<word>abc)").unwrap()
    original.captures("abc").unwrap()

fn main:
    assert(Regex.compile("(").is_err())
    assert(Regex.compile_flags("abc", "q").is_err())
    for i in 0..3:
        let re = cloned_pattern()
        assert(re.is_match("abc"))
        assert(not re.is_match("xyz"))
        let caps = escaped_captures()
        assert(caps.name_text("word") == "abc")
        assert(caps.text(0) == "abc")
        assert(caps.name("absent").is_none())
    print("ok")
