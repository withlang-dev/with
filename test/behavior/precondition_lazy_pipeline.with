//! expect-stdout: ok

// D86 (§18.2, #1864): a condition piped into a precondition form is its
// condition; the message is still evaluated only on failure (here,
// evaluating it would index out of range and panic), and the form's
// location default is the call's.

fn main:
    let words = ["only"]
    let n = 3
    (n > 0) |> require(words[n])
    (n < 10) |> check(words[n + 1])
    true |> assert()
    print("ok")
