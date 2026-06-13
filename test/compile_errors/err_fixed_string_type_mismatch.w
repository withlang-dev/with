//! expect-check-fail: wrong argument type in call to 'takes_four'

fn takes_four(s: FixedString[4]):
    let _ = s

fn main:
    let s: FixedString[8] = FixedString[8].new()
    takes_four(s)
