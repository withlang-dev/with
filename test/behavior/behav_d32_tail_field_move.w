//! expect-stdout: ok

// Tail-position `move owned.field` must materialize the move BEFORE the
// block's scope-exit drops. Before the fix, lower_block_mode popped scope
// with the tail still a lazy OK_MOVE field operand: the base local was
// dropped in full and the captured return value read freed storage (the
// returned Vec came back blank).

type Body { xs: Vec[i32], tag: i32 }

fn mk() -> Body:
    var xs: Vec[i32] = Vec.new()
    xs.push(41)
    xs.push(42)
    Body { xs, tag: 7 }

fn take_tail() -> Vec[i32]:
    var owned = mk()
    move owned.xs

fn take_param(b: Body) -> Vec[i32]:
    var owned = b
    move owned.xs

fn main:
    let v1 = take_tail()
    assert(v1.len() == 2)
    assert(v1.get(1) == 42)
    let v2 = take_param(mk())
    assert(v2.len() == 2)
    assert(v2.get(0) == 41)
    print("ok")
