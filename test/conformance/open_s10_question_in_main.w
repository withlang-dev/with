//! expect-stdout: 7
// §10 / §18.5: ? in fn main: with no return type. #2935
fn parse(s: str) -> Result[i32, str]:
    if s == "x": return Err("bad")
    7
fn main:
    let v = parse("3")?
    print(v)
