//! expect-check-fail: cannot move out of global `items`

// §9.1 / D60 with D52: the block spelling over a List global.

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
var items: List[Tok] = List.new()
fn f -> List[Tok]:
    var v: List[Tok] = List.new()
    v.push(Tok { id: 1 })
    items = v

fn main: print(f().len())
