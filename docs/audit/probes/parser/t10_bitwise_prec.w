// T10: bitwise precedence probe. Spec §9.9: `|`=L6 loosest, `^`=L7, `&`=L8
// tightest (C-like), so 2 | 3 & 5 == 2 | (3 & 5) == 3.
fn main:
    let spec_val = 2 | 3 & 5
    assert(spec_val == 3)
