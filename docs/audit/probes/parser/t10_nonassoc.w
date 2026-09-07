// T10: non-associative == must be a compile error (Parser.w:3499-3505).
fn main:
    let r = 1 == 1 == true
    assert(r == true)
