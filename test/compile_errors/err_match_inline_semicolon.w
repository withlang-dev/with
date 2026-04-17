//! expect-check-fail: expected '}'

fn main:
    let x = match 1 { 0 => "zero"; _ => "other" }
    print(x)
