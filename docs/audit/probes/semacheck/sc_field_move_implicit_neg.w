//! T5/D32 negative control: bare non-Copy field in a consuming position
//! (mark_moved_if_consumed :23416 -> d32_emit_implicit_field_move_error
//! :23403). Expect check FAIL: "a field never moves out implicitly".
type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.len() >= 0)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let h = Holder { v: xs, n: 1 }
    consume(h.v)
