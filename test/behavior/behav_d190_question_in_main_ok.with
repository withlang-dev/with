//! expect-stdout: 7
// §10.2 (D190, #2935): `?` in `fn main:` with no return type; the Ok path.
fn parse(s: str) -> Result[i32, str]:
    if s == "x": return Err("bad")
    7
fn main:
    let v = parse("3")?
    print(v)
