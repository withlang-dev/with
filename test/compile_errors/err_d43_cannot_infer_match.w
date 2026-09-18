//! expect-check-fail: cannot infer return type: match arms have types i32 and Unit; add `-> i32` or `-> Unit`

// D43 / #1180: this was invalid MIR (a Unit arm stored into an i32 place).

var seen: i32
fn f(p: bool):
    seen = 0
    match p:
        true => seen = 1
        false => assert(p)

fn main: f(true)
