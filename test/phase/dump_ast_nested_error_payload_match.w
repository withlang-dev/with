//! args: --dump-ast
//! expect-check-stdout: Err(.Bad(msg)) -> msg

error ParseErr =
    Bad(msg: str)

fn parse() -> Result[i32, ParseErr]:
    Err(.Bad("nope"))

fn lift() -> str:
    match parse()
        Err(.Bad(msg)) => msg
        Ok(_) => "ok"
