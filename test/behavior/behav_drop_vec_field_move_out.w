//! expect-stdout: ok

// #607/D32: vacating a transitive-Drop field (Vec[W]) with the explicit
// `move` — via let, bare tail, explicit return, and whole destructuring. The
// binding takes sole ownership of the moved field; the owner's partial drop
// still frees the sibling field exactly once (§2.2, §2.5.1).

type W { id: i32, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

type Holder { a: Vec[W], b: W }

fn mk(s: *mut i32) -> Holder:
    let v: Vec[W] = Vec.new()
    v.push(W { id: 1, slot: s })
    v.push(W { id: 2, slot: s })
    Holder { a: v, b: W { id: 4, slot: s } }

fn take_tail(h: Holder) -> Vec[W]:
    var owned = h
    move owned.a

fn take_return(h: Holder) -> Vec[W]:
    var owned = h
    return move owned.a

fn run_let(s: *mut i32):
    var h = mk(s)
    let m = move h.a
    let n = m.len()

fn run_tail(s: *mut i32):
    let v = take_tail(mk(s))

fn run_return(s: *mut i32):
    let v = take_return(mk(s))

fn run_destructure(s: *mut i32):
    let { a, b } = mk(s)
    let n = a.len()

fn main:
    var c = 0
    run_let(&raw mut c)
    assert(c == 7)
    c = 0
    run_tail(&raw mut c)
    assert(c == 7)
    c = 0
    run_return(&raw mut c)
    assert(c == 7)
    c = 0
    run_destructure(&raw mut c)
    assert(c == 7)
    print("ok")
