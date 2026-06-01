//! expect-error: ? cannot convert error type

error ParseError = Bad
error IoError = NotFound

fn read_value -> Result[i32, IoError]:
    Err(.NotFound)

fn load -> Result[i32, ParseError]:
    read_value()?

fn main:
    let _ = load()
