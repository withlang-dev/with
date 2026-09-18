// T6: dead shared borrow expires at last use (expire_dead_borrows_in_block
// :23165, driven per-statement from check_block :9004). The view's last use
// precedes the mutation, so the mutation is legal. Expect check PASS.
fn main:
    var p = 1
    let v = &p
    let a = *v
    p = 2
    assert(a + p == 3)
