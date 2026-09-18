use std.regex
fn main:
    let text = "a1 b2"
    assert(/([a-z])(\\d)/.is_match(text))
    with_write("ok\n")
