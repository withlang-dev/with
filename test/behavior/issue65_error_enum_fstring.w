//! expect-stdout: ok

error E =
    Bad(msg: str)
    Missing(path: str, line: i32)
    Empty

enum Token { Int(i32) | Text(str) | End }

fn main:
    let err1 = E.Bad("nope")
    let err2 = E.Missing("config.w", 7)
    let err3 = E.Empty
    assert(f"{err1}" == "Bad(nope)")
    assert(f"{err2}" == "Missing(config.w, 7)")
    assert(f"{err3}" == "Empty")
    assert(f"err {err1}" == "err Bad(nope)")

    let tok1 = Token.Int(42)
    let tok2 = Token.Text("hi")
    let tok3 = Token.End
    assert(f"{tok1}" == "Int(42)")
    assert(f"{tok2}" == "Text(hi)")
    assert(f"{tok3}" == "End")

    print("ok")
