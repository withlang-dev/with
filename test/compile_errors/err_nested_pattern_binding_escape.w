//! expect-error: undefined variable

error ParseErr =
    Bad(msg: str)

fn parse() -> Result[i32, ParseErr]:
    Err(.Bad("nope"))

fn main:
    let _ = match parse()
        Err(.Bad(msg)) => msg
        _ => "ok"
    print(msg)
