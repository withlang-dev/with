//! expect-stdout: ok

error LocalErr =
    Bad(msg: str)
    Missing(path: str, line: i32)
    Empty

enum Token { Text(str) | End }

fn main:
    let err = LocalErr.Bad("dbg")
    let missing = LocalErr.Missing("dbg.w", 5)
    let label = "dbg"
    let tok = Token.Text(label)

    assert(f"{err:?}" == "Bad(dbg)")
    assert(f"{missing:?}" == "Missing(dbg.w, 5)")
    assert(f"{tok:?}" == "Text(dbg)")

    let match_err = match false
        true => LocalErr.Empty
        false => LocalErr.Bad("match-dbg")
    assert(f"{match_err:?}" == "Bad(match-dbg)")

    print("ok")
