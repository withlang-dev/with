// Spec test: Section 10 — Error Handling
// Covers `error ... from ...` wrapper generation and `?` error conversion.

error ParseError =
    | InvalidSyntax(pos: usize)
    | EmptyInput

error IoError =
    | NotFound(path: str)
    | PermissionDenied(path: str)

error AppError from IoError, ParseError

fn read_file(path: str) -> Result[str, IoError]:
    if path == "missing":
        return Err(.NotFound(path))
    if path == "denied":
        return Err(.PermissionDenied(path))
    Ok(path)

fn parse(text: str) -> Result[i32, ParseError]:
    if text == "":
        return Err(.EmptyInput)
    if text == "bad":
        return Err(.InvalidSyntax(3))
    Ok(42)

fn load(path: str) -> Result[i32, AppError]:
    let text = read_file(path)?
    parse(text)?

fn classify(r: Result[i32, AppError]) -> i32:
    match r:
        Ok(v) => v
        Err(AppError.Io(IoError.NotFound(path))) => if path == "missing": 10 else: 11
        Err(AppError.Io(IoError.PermissionDenied(path))) => if path == "denied": 20 else: 21
        Err(AppError.Parse(ParseError.InvalidSyntax(pos))) => pos as i32
        Err(AppError.Parse(ParseError.EmptyInput)) => 30

fn main:
    assert(classify(load("ok")) == 42)
    assert(classify(load("missing")) == 10)
    assert(classify(load("denied")) == 20)
    assert(classify(load("bad")) == 3)
    assert(classify(load("")) == 30)
