//! expect-stdout: ok

error ParseErr =
    Span(start: i32, end: i32)

fn parse(ok: bool) -> Result[i32, ParseErr]:
    if ok:
        return Ok(7)
    Err(.Span(3, 8))

fn classify(ok: bool) -> i32:
    match parse(ok):
        Err(.Span(start, end)) => start + end
        Ok(v) => v

fn main:
    assert(classify(false) == 11)
    assert(classify(true) == 7)
    print("ok")
