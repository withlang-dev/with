// T13/T18: large int literal in match pattern (Parser.w:6443-6461) and ranges.
fn classify(x: i64) -> i32:
    match x:
        0x80000000 => 1
        -5..5 => 2
        _ => 0

fn main:
    assert(classify(2147483648i64) == 1)
    assert(classify(0i64) == 2)
    assert(classify(99i64) == 0)
