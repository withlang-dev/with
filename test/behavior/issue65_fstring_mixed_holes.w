//! expect-stdout: ok

error LocalErr =
    Bad(msg: str)
    Missing(path: str, line: i32)
    Empty

enum Token { Text(str) | End }

fn main:
    let label = "inline"
    let tok = Token.Text(label)
    let err = LocalErr.Bad(label)

    let mixed = f"tok={tok} err={err} num={42}"
    assert(mixed == "tok=Text(inline) err=Bad(inline) num=42")

    assert(f"[{LocalErr.Empty}] {Token.End}" == "[Empty] End")

    let err1 = LocalErr.Bad("a")
    let err2 = LocalErr.Missing("b.w", 2)
    var out = ""
    var i = 0
    while i < 2:
        out = if i == 0:
            out ++ f"{err1};"
        else:
            out ++ f"{err2};"
        i = i + 1
    assert(out == "Bad(a);Missing(b.w, 2);")

    print("ok")
