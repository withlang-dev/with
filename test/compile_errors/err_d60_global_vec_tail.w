//! expect-check-fail: cannot move out of global `items`

// §9.1 / D60 with D52: the block spelling over a List global.

var items: List[i32] = List.new()
fn f -> List[i32]:
    var v: List[i32] = List.new()
    v.push(1)
    items = v

fn main: print(f().len())
