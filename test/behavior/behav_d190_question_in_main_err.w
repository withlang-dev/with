//! expect-exit: 1
//! expect-stderr: error: "bad"
// §10.2 (D190, #2935): an Err that `?` meets in main is the program's
// outcome: its Debug form after `error: ` on stderr, exit status 1, and
// nothing after it runs.
fn parse(s: str) -> Result[i32, str]:
    if s == "x": return Err("bad")
    7
fn main:
    let v = parse("x")?
    print(v)
