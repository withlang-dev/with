//! expect-check-fail: cannot move out of global `items`

// §9.1 / D60 with D52: the block spelling over a Vec global.

var items: Vec[i32] = Vec.new()
fn f -> Vec[i32]:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    items = v

fn main: print(f().len())
