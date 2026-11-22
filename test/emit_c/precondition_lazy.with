//! expect-stdout: ok
//! expect-stdout: kept

// D86 (§18.2, #1864): the C backend lowers `assert`/`require`/`check` as
// the compiler-known forms the LLVM backend does: the message runs only on
// failure, and a move inside it leaves the value owned on the passing path.
fn side_effect() -> str:
    print("SHOULD NOT PRINT")
    "message"

fn consume(s: str) -> str:
    print("SHOULD NOT PRINT")
    s

fn main:
    require(true, side_effect())
    check(1 < 2, side_effect())
    assert(true, side_effect())
    print("ok")
    let s = "ke" ++ "pt"
    require(true, consume(s))
    print(s)
