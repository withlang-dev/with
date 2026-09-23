//! expect-exit: 134
//! expect-stderr: called unwrap on Err: Parse { line: 3, text: "a\"b\n" }

// D61: an unwrap on Err panics with the error's `:?` form — the same
// recursive, quoted and escaped text an f-string gives it.

type Parse { line: i32, text: str }

fn parse() -> Result[i32, Parse]: Err(Parse { line: 3, text: "a\"b\n" })

fn main:
    let _ = parse().unwrap()
