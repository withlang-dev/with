//! expect-stdout: ok
// §10.4: `??` is lazy (RHS unevaluated when LHS is Some) and its RHS may be a
// control-flow expression (break).
fn boom -> i32:
    assert(false, "?? RHS must not evaluate when LHS is Some")
    0
fn mk(i: i32) -> Option[i32]:
    if i < 3: Some(i) else: None
fn use_break -> i32:
    var total = 0
    var i = 0
    while i < 5:
        total = total + (mk(i) ?? break)
        i = i + 1
    total
fn main:
    let five: Option[i32] = Some(5)
    assert((five ?? boom()) == 5)
    assert(use_break() == 3)
    print("ok")
