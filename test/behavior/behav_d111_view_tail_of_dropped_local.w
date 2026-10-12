//! expect-stdout: [ab cd]
//! expect-stdout: [ab cd]
//! expect-stdout: [x-y]

// D111: a function whose tail is a view into one of its own locals, where
// the return demands the owned value, copies the text out before the local
// dies. `out` grew past its literal, so its buffer is heap memory the
// scope-exit drop frees: before, the copy ran after that drop and the
// returned str was NULs where the text had been (`[^@^@^@^@^@]`).

fn grown() -> str:
    var out = ""
    for x in ["ab", "cd"]:
        out = out ++ x ++ " "
    out.trim()

fn literal() -> str:
    var out = "ab cd "
    out.trim()

fn joined(a: &str, b: &str) -> str:
    var text = a ++ "-"
    text = text ++ b ++ "   "
    text.trim()

fn main:
    print("[" ++ grown() ++ "]")
    print("[" ++ literal() ++ "]")
    print("[" ++ joined("x", "y") ++ "]")
