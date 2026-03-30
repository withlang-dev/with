//! expect-stdout: ok

error ParseErr =
    Bad(msg: str)

fn parse() -> Result[i32, ParseErr]:
    Err(.Bad("nope"))

fn code(err: ParseErr) -> i32:
    match err
        .Bad(_) => 10

fn extract() -> i32:
    match parse()
        Err(err @ .Bad(msg)) if msg == "nope" => code(err)
        _ => 0

fn main:
    assert(extract() == 10)
    print("ok")
