// Ephemeral type qualifier on struct declarations
type StrView = ephemeral { ptr: i32, len: i32 }

type TokenView = ephemeral { start: i32, end: i32, kind: i32 }

fn main -> i32:
    let sv = StrView { ptr: 100, len: 5 }
    println(sv.len)
    let tv = TokenView { start: 0, end: 10, kind: 1 }
    println(tv.end)
    if sv.len == 5 and tv.end == 10 then 0 else 1
