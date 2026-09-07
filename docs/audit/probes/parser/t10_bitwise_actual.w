// T10: confirm actual grouping. If parser binds `|` tightest (inverted vs
// spec §9.9), then 2 | 3 & 5 == (2 | 3) & 5 == 1, and 6 ^ 3 & 5 == (6 ^ 3) & 5 == 5.
fn main:
    assert((2 | 3 & 5) == 1)
    assert((6 ^ 3 & 5) == 5)
