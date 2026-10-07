//! expect-stdout: x__y
//! expect-stdout: 4 3 2
//! expect-stdout: a-b

// #2233: a regex literal is a primary expression, so a statement or a
// tail may begin with one — including when the previous line ended with
// `)`, which the lexer used to read as the left operand of a division.
// A division stays a division everywhere one can be written.
fn strip(s: &str) -> str:
    var out = /a/g.replace(s, "x")
    /_[0-9]+/g.replace(out, "_")

fn quotients(a: i32, b: i32) -> (i32, i32, i32):
    let q = a / b
    let r = (a / b) - 1
    let t = [a, b].len() as i32 / 1
    (q, r, t)

fn main:
    print(strip("a_12_y"))
    let (q, r, t) = quotients(8, 2)
    print(f"{q} {r} {t}")
    let joined = "a b"
    /\s+/.replace(joined, "-") |> print()
