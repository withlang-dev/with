//! expect-stdout: ok

// Regression control: early `return <call>` already inferred correctly and
// must keep working after the recording fix.
fn base(): true

fn wrap(v: i32):
    if v == 0:
        return base()
    false

fn main:
    assert(wrap(0))
    assert(not wrap(1))
    print("ok")
