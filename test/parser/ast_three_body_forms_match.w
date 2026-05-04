//! expect-check-pass

fn classify(x: i32) -> str:
    match x:
        1 => "one"
        2 => {
            "two"
        }
        _ => "other"

fn main:
    let a = classify(1)
    let b = classify(2)
    let c = classify(3)
