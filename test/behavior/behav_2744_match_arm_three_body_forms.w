//! expect-stdout: ok
// #2744 (§9.7, D163): a match arm is `pattern [if guard] => body`, and the
// body takes the same three forms as any other body: inline on the same
// line, an indented block on the lines below, or a braced block.

fn inline_form(value: Option[i32]) -> i32:
    match value:
        Some(v) => v + 1
        None => 0

fn indented_form(value: Option[i32]) -> i32:
    match value:
        Some(v) =>
            let doubled = v * 2
            doubled + 1
        None =>
            0

fn braced_form(value: Option[i32]) -> i32:
    match value:
        Some(v) => {
            let tripled = v * 3
            tripled + 1
        }
        None => {
            0
        }

fn main:
    assert(inline_form(Some(4)) == 5)
    assert(inline_form(None) == 0)
    assert(indented_form(Some(4)) == 9)
    assert(indented_form(None) == 0)
    assert(braced_form(Some(4)) == 13)
    assert(braced_form(None) == 0)
    print("ok")
