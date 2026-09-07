// SemaDecl probe NEGATIVE: two distinct fns coexist
fn dup_ok_a() -> i32:
    1

fn dup_ok_b() -> i32:
    2

fn main:
    assert(dup_ok_a() == 1)
    assert(dup_ok_b() == 2)
