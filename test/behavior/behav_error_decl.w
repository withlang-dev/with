//! expect-stdout: ok

// Behavior test: error declarations and `error ... from` conversion.

error ParseError =
    | Bad(pos: usize)

error IoError =
    | NotFound(path: str)

error AppError from IoError, ParseError

fn io_fail -> Result[i32, IoError]:
    Err(.NotFound("config"))

fn parse_fail -> Result[i32, ParseError]:
    Err(.Bad(9))

fn load_io -> Result[i32, AppError]:
    io_fail()?

fn load_parse -> Result[i32, AppError]:
    parse_fail()?

fn main:
    let io_code = match load_io():
        Err(AppError.Io(IoError.NotFound(path))) => if path == "config": 1 else: 0
        _ => 0
    let parse_code = match load_parse():
        Err(AppError.Parse(ParseError.Bad(pos))) => pos as i32
        _ => 0
    assert(io_code == 1)
    assert(parse_code == 9)
    print("ok")
