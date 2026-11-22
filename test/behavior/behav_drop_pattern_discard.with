//! expect-stdout: ok

// A7 (#606): pattern discards own what they discard. A `_` element in a tuple
// destructure, a `_` or `..` in a struct pattern, a `_` payload/element in a
// match arm, and a whole-subject `_` arm must each drop the discarded Drop
// value exactly once (drop runs at scope exit of the destructure's scope).
// Distinct ids summed per shape: exact count = no leak AND no double-free.

type W { id: i32, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn new_w(id: i32, s: *mut i32) -> W:
    W { id: id, slot: s }

type P { x: W, y: W, z: W }

fn run_tuple_wildcard(s: *mut i32):
    let (a, _) = (new_w(1, s), new_w(2, s))

fn run_tuple_all_wildcards(s: *mut i32):
    let (_, _) = (new_w(1, s), new_w(2, s))

fn run_nested_wildcard(s: *mut i32):
    let ((a, _), b) = ((new_w(1, s), new_w(2, s)), new_w(4, s))

fn run_match_elem(s: *mut i32):
    match (new_w(1, s), new_w(2, s)):
        (a, _) => ()

fn run_match_whole(s: *mut i32):
    match (new_w(1, s), new_w(2, s)):
        _ => ()

fn run_struct_wildcard(s: *mut i32):
    let { x, y: _, z } = P { x: new_w(1, s), y: new_w(2, s), z: new_w(4, s) }

fn run_struct_rest(s: *mut i32):
    let { x, .. } = P { x: new_w(1, s), y: new_w(2, s), z: new_w(4, s) }

fn main:
    var c = 0
    run_tuple_wildcard(&raw mut c)
    assert(c == 3)
    c = 0
    run_tuple_all_wildcards(&raw mut c)
    assert(c == 3)
    c = 0
    run_nested_wildcard(&raw mut c)
    assert(c == 7)
    c = 0
    run_match_elem(&raw mut c)
    assert(c == 3)
    c = 0
    run_match_whole(&raw mut c)
    assert(c == 3)
    c = 0
    run_struct_wildcard(&raw mut c)
    assert(c == 7)
    c = 0
    run_struct_rest(&raw mut c)
    assert(c == 7)
    print("ok")
