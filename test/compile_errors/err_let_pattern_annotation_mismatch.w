//! expect-error: type mismatch in binding

// §30.4 / #1354: a pattern let's annotation demands the subject's type.

fn names -> (str, str): ("a", "b")

fn main:
    let (a, b): (i64, i64) = names()
    print(f"{a} {b}")
