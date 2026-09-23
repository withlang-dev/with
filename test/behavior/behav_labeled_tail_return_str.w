//! expect-stdout: [v=hello]
// §29.13 (#640): same for str tail after a labeled statement.
fn g() -> str:
    let s = "hello"
    'done:
        "v=" ++ s
fn main:
    print(f"[{g()}]")
