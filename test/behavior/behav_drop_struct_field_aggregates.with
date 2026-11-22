//! expect-stdout: ok

// A6: nested aggregate-in-struct-field drop. A Drop value embedded in an
// aggregate that is itself a struct field drops exactly once when the owner
// goes out of scope — across plain, tuple, array, Option, List, and two-level
// nested shapes. Distinct ids summed per shape: an exact count means no leak
// AND no double-free.

type W { id: i32, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn new_w(id: i32, s: *mut i32) -> W:
    W { id: id, slot: s }

type HPlain { w: W }
type HTuple { pair: (W, W) }
type HArray { items: [W; 2] }
type HOption { opt: Option[W] }
type HVec { items: List[W] }
type Inner { pair: (W, W) }
type Outer { inner: Inner }

fn run_plain(s: *mut i32):
    let h = HPlain { w: new_w(1, s) }

fn run_tuple(s: *mut i32):
    let h = HTuple { pair: (new_w(1, s), new_w(2, s)) }

fn run_array(s: *mut i32):
    let h = HArray { items: [new_w(1, s), new_w(2, s)] }

fn run_option(s: *mut i32):
    let h = HOption { opt: Some(new_w(1, s)) }

fn run_list(s: *mut i32):
    let v: List[W] = List.new()
    v.push(new_w(1, s))
    v.push(new_w(2, s))
    let h = HVec { items: v }

fn run_two_level(s: *mut i32):
    let outer = Outer { inner: Inner { pair: (new_w(1, s), new_w(2, s)) } }

fn main:
    var c = 0
    run_plain(&raw mut c)
    assert(c == 1)
    c = 0
    run_tuple(&raw mut c)
    assert(c == 3)
    c = 0
    run_array(&raw mut c)
    assert(c == 3)
    c = 0
    run_option(&raw mut c)
    assert(c == 1)
    c = 0
    run_list(&raw mut c)
    assert(c == 3)
    c = 0
    run_two_level(&raw mut c)
    assert(c == 3)
    print("ok")
