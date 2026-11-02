//! expect-stdout: 3
//! expect-stdout: done
// §10.2 (D190, #2935): `?` in a script's top-level statements (the implicit main, §29.15).
fn parse(s: str) -> Result[i32, str]:
    if s == "x": return Err("bad")
    3
let v = parse("3")?
print(v)
print("done")
