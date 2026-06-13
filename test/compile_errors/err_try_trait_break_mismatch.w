//! expect-check-fail: ? cannot propagate break type 'str' through enclosing return type 'OtherResult'

enum TextResult:
    TextOk(i32)
    TextErr(str)

impl Try[i32, str] for TextResult:
    fn branch(move self: Self) -> ControlFlow[str, i32]:
        match self:
            TextOk(v) => ControlFlow.Continue(v)
            TextErr(msg) => ControlFlow.Break(msg)

    fn from_break(msg: str) -> Self:
        TextErr(msg)

enum OtherResult:
    OtherOk(i32)
    OtherErr(i32)

impl Try[i32, i32] for OtherResult:
    fn branch(move self: Self) -> ControlFlow[i32, i32]:
        match self:
            OtherOk(v) => ControlFlow.Continue(v)
            OtherErr(code) => ControlFlow.Break(code)

    fn from_break(code: i32) -> Self:
        OtherErr(code)

fn text_value() -> TextResult:
    TextErr("bad")

fn main -> OtherResult:
    let value = text_value()?
    OtherOk(value)
