//! expect-stdout: ok

error ParseErr =
    Bad(msg: str)

fn parse(ok: bool) -> Result[i32, ParseErr]:
    if ok:
        return Ok(7)
    Err(.Bad("nope"))

fn lift(ok: bool) -> Result[i32, str]:
    match parse(ok):
        Ok(v) => Ok(v)
        Err(ParseErr.Bad(msg)) => Err(msg)

fn main:
    let err_text = match lift(false):
        Ok(_) => "unexpected"
        Err(msg) => msg
    assert(err_text == "nope")

    let ok_value = match lift(true):
        Ok(v) => v
        Err(_) => 0
    assert(ok_value == 7)

    print("ok")
