//! expect-stdout: ok

error ParseErr =
    Bad(msg: str)

fn parse(ok: bool) -> Result[i32, ParseErr]:
    if ok:
        return Ok(7)
    Err(.Bad("empty"))

fn classify(ok: bool) -> i32:
    match parse(ok)
        Err(.Bad(msg)) if msg == "empty" => 1
        Ok(v) => v
        _ => 0

fn main:
    assert(classify(false) == 1)
    assert(classify(true) == 7)
    print("ok")
