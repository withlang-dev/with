// T10: chained comparison desugar: 1 < 2 < 3 -> (1 < 2) and (2 < 3).
fn main:
    assert((1 < 2 < 3) == true)
    assert((1 < 5 < 3) == false)
