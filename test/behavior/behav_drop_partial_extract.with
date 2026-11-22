//! expect-stdout: ok

// Tuple fields retain their partial-move behavior. D27 supersedes #606's array
// index extraction: array reads are views, and the array drops both elements at
// scope exit. Distinct ids make the exact count detect leaks and double drops.

type W { id: i32, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn new_w(id: i32, s: *mut i32) -> W:
    W { id: id, slot: s }

fn run_tuple_extract_one(s: *mut i32):
    var t = (new_w(1, s), new_w(2, s))
    let a = move t.0

fn run_array_observe_one(s: *mut i32):
    let arr = [new_w(1, s), new_w(2, s)]
    let first = arr[0]
    assert(first.id == 1)

fn run_array_observe_all(s: *mut i32):
    let arr = [new_w(1, s), new_w(2, s)]
    let first = arr[0]
    let second = arr[1]
    assert(first.id == 1)
    assert(second.id == 2)

fn main:
    var c = 0
    run_tuple_extract_one(&raw mut c)
    assert(c == 3)
    c = 0
    run_array_observe_one(&raw mut c)
    assert(c == 3)
    c = 0
    run_array_observe_all(&raw mut c)
    assert(c == 3)
    print("ok")
