//! expect-stdout: ok

fn value(Some(x): Option[i32]) -> i32:
    x

fn value(None: Option[i32]) -> i32:
    0

fn classify(0: i32) -> str:
    "zero"

fn classify(1: i32) -> str:
    "one"

fn classify(n: i32) -> str:
    if n < 0:
        "negative"
    else:
        "many"

fn main:
    assert(value(Some(41)) == 41)
    assert(value(None) == 0)
    assert(classify(0) == "zero")
    assert(classify(1) == "one")
    assert(classify(-5) == "negative")
    assert(classify(9) == "many")
    print("ok")
