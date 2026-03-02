//! run
//! expect: fatal code=42

type Status =
    | Ok
    | Warning(str)
    | Fatal(code: i32)

fn status_msg(s: Status) -> str:
    match s
        .Ok -> "ok"
        .Warning(w) -> w
        .Fatal(c) -> "fatal code={c}"

fn main:
    let s = Fatal(42)
    println(status_msg(s))
