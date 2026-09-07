// T5/D32: explicit `move h.v` spelling declares the hole (NK_MOVE_ARG arm,
// mark_moved_if_consumed :23420). Expect check PASS.
type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.len() >= 0)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    var h = Holder { v: xs, n: 1 }
    consume(move h.v)
