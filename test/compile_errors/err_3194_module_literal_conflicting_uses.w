//! expect-check-fail: this use demands `List[str]` of a binding another use demands `List[i64]` of (§4.3c); the other use is at
// #3194: every use in the module is heard; two that disagree are an error
// naming both, whatever order their functions are written in.
var xs = []

fn a(): xs.push(1 as i64)

fn b(): xs.push("s".to_owned())

fn main:
    a()
    b()
