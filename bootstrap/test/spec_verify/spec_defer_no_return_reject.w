// NEGATIVE: defer with return should be rejected (§2.4)
// Control flow (return/break/continue) not allowed in defer
// EXPECT: check fails with "non-local control flow in defer"
fn main -> i32:
    defer return 1
    0
