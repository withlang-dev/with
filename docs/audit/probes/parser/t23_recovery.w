// T23: broken decl followed by good decl — recovery must keep going and the
// error span must point at the real problem.
fn broken(:
fn good() -> i32: 42

fn main:
    assert(good() == 42)
