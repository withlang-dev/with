//! args: --dump-ast
//! expect-check-stdout: Err(.Span(start, end)) -> (start + end)

error ParseErr =
    Span(start: i32, end: i32)

fn parse() -> Result[i32, ParseErr]:
    Err(.Span(3, 8))

fn classify() -> i32:
    match parse():
        Err(.Span(start, end)) => start + end
        Ok(v) => v
