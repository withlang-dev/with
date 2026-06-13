//! expect-stdout: ok

type ParseError { msg: str, pos: usize }
type ParseValue { value: i32, remaining: str }

enum ParseResult[T]:
    ParseOk(T)
    ParseErr(ParseError)

impl[T] Try[T, ParseError] for ParseResult[T]:
    fn branch(move self: Self) -> ControlFlow[ParseError, T]:
        match self:
            ParseOk(v) => ControlFlow.Continue(v)
            ParseErr(e) => ControlFlow.Break(e)

    fn from_break(err: ParseError) -> Self:
        ParseErr(err)

fn parse_digit(input: str) -> ParseResult[ParseValue]:
    if input == "12":
        return ParseOk(ParseValue { value: 1, remaining: "2" })
    if input == "2":
        return ParseOk(ParseValue { value: 2, remaining: "" })
    ParseErr(ParseError { msg: "digit", pos: 0 })

fn parse_pair(input: str) -> ParseResult[(i32, i32)]:
    let left = parse_digit(input)?
    let right = parse_digit(left.remaining)?
    ParseOk((left.value, right.value))

enum Validation:
    Valid(i32)
    Invalid(str)

impl Try[i32, str] for Validation:
    fn branch(move self: Self) -> ControlFlow[str, i32]:
        match self:
            Valid(v) => ControlFlow.Continue(v)
            Invalid(msg) => ControlFlow.Break(msg)

    fn from_break(msg: str) -> Self:
        Invalid(msg)

fn checked_value(value: i32) -> Validation:
    if value > 0:
        return Valid(value)
    Invalid("negative")

fn add_checked(a: i32, b: i32) -> Validation:
    let x = checked_value(a)?
    let y = checked_value(b)?
    Valid(x + y)

fn main:
    match parse_pair("12"):
        ParseOk(pair) => assert(pair.0 == 1 and pair.1 == 2)
        ParseErr(_) => assert(false)

    match parse_pair("x"):
        ParseOk(_) => assert(false)
        ParseErr(err) => assert(err.msg == "digit" and err.pos == 0)

    match add_checked(5, 7):
        Valid(v) => assert(v == 12)
        Invalid(_) => assert(false)

    match add_checked(5, -1):
        Valid(_) => assert(false)
        Invalid(msg) => assert(msg == "negative")

    print("ok")
