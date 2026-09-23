//! expect-debug-alloc: leak count=0

// #1403 (§13.5, §13.6): over consuming iteration a comprehension clause owns
// each element it takes from the iterator. One its refutable pattern skips is
// dropped at the skip, exactly once; one it matches moves into the bindings.
// Before the fix nothing was skipped: `None` bound its absent payload (a drop
// of garbage) and a non-matching tuple's str moved into the result.
use std.builtins.print_i32
use std.mem.alloc
use std.mem.free_mem

type W { ptr: *i8, drops: *mut i32, n: i32 }

impl Drop for W:
    move fn drop():
        unsafe:
            *self.drops = *self.drops + self.n
        free_mem(self.ptr)

fn w(drops: *mut i32, n: i32): W { ptr: alloc(24), drops, n }

enum Slot:
    Full(W)
    Empty
    Held(str)

fn main:
    var drops = 0
    var opts: Vec[Option[W]] = Vec.new()
    opts.push(Some(w(&raw mut drops, 1)))
    opts.push(None)
    opts.push(Some(w(&raw mut drops, 2)))
    let kept = [x for Some(x) in opts.into_iter()]
    assert(kept.len() == 2)
    assert(drops == 0)

    var drops2 = 0
    var pairs: Vec[(i32, W)] = Vec.new()
    pairs.push((0, w(&raw mut drops2, 1)))
    pairs.push((1, w(&raw mut drops2, 2)))
    pairs.push((0, w(&raw mut drops2, 4)))
    let zeros = [x for (0, x) in pairs.into_iter()]
    assert(zeros.len() == 2)
    assert(drops2 == 2)

    var drops3 = 0
    var slots: Vec[Slot] = Vec.new()
    slots.push(Slot.Full(w(&raw mut drops3, 1)))
    slots.push(Slot.Held("h".clone()))
    slots.push(Slot.Empty)
    slots.push(Slot.Full(w(&raw mut drops3, 2)))
    let full = [x.n for .Full(x) in slots.into_iter()]
    assert(full.len() == 2)
    assert(drops3 == 3)

    var names: Vec[(i32, str)] = Vec.new()
    names.push((0, "a".clone()))
    names.push((1, "b".clone()))
    let named = [s for (0, s) in names.into_iter()]
    assert(named.len() == 1)
    print_i32(kept.len() as i32 + zeros.len() as i32 + full.len() as i32 + named.len() as i32)
