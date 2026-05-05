// copy x on a Clone-only type invokes .clone(); original remains valid.

@[derive(Clone)]
type Widget { id: i32 }
impl Widget:
    fn drop(move self: Self): ()

fn consume(w: Widget) -> i32:
    return w.id

fn main:
    let w = Widget { id: 42 }
    let id = consume(copy w)   // copy invokes Widget.clone(); w remains valid
    assert(id == 42)
    assert(w.id == 42)         // original unchanged
    let _ = move w             // explicitly clean up
    print("ok\n")
