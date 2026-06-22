//! expect-check-fail: not yet supported

// [A5] #607: consuming (by-value) iteration of a Vec whose elements need drop is
// unsound — the loop variable copies each Drop element, so it is dropped twice (the
// copy and the Vec's own element-drop). Rejected pending real move semantics; the
// sound form is borrow-iteration `for w in &xs` (see behav_drop_field_borrow_iter).

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.tag)

fn main:
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 1 })
    xs.push(W { tag: 2 })
    for w in xs:
        let _ = w.tag
