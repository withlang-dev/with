//! expect-stdout: ok

enum DType {  | Int32 }
    | Float32

enum E {  | ParseError(msg: str) }

fn parse_dtype(token: str) -> Result[DType, E]:
    if token == "i32":
        return Ok(.Int32)
    Err(.ParseError("unknown dtype"))

fn take_dtype(dtype: DType) -> i32:
    match dtype
        .Int32 => 1
        .Float32 => 2

fn main:
    let dtype = parse_dtype("i32").unwrap()
    assert(take_dtype(dtype) == 1)
    print("ok")
