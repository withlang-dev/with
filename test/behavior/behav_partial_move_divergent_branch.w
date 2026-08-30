//! expect-stdout: ok

// #695: a partial (field) move on a divergent (returning) branch must not
// poison the field on the fall-through — the move can't reach the join. The
// whole-value case already worked; this pins the field/partial case and its
// whole-value control together (they share the divergence-merge path).

type D { id: i32 }
impl Drop for D:
    fn drop(move self: Self): ()

type Holder { d: D, tag: i32 }

// Field move on the returning branch; fall-through still owns d.
fn pick_field(cond: bool) -> D:
    var h = Holder { d: D { id: 7 }, tag: 0 }
    if cond:
        return move h.d
    move h.d

// Whole-value control (already-correct path).
fn pick_whole(cond: bool) -> D:
    var d = D { id: 9 }
    if cond:
        return d
    d

// Vec field variant (the exact shape the #691 flip needs).
fn pick_vec(cond: bool) -> Vec[i32]:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    if cond:
        return v
    v

fn main:
    assert(pick_field(false).id == 7)
    assert(pick_field(true).id == 7)
    assert(pick_whole(false).id == 9)
    assert(pick_vec(false).get(1) == 2)
    assert(pick_vec(true).get(0) == 1)
    print("ok")
