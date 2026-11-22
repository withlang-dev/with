//! expect-error: `n` is `isize` from its use here, and `i32` is demanded at this use

// D184 (§29.15): a helper's read settles an integer-literal binding where
// main has not; a later use in main that would narrow it names both sites.

var n = 0
fn bump(): n = n + 1
bump()
let narrow: i32 = n
print(narrow)
