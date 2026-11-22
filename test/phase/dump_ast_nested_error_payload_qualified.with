//! args: --dump-ast
//! expect-check-stdout: Err(ParseErr.Bad(msg)) -> Err(msg)

error ParseErr =
    Bad(msg: str)

fn parse() -> Result[i32, ParseErr]:
    Err(.Bad("nope"))

fn lift() -> Result[i32, str]:
    match parse():
        Err(ParseErr.Bad(msg)) => Err(msg)
        Ok(v) => Ok(v)
