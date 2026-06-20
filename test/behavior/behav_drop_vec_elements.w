//! expect-stdout: ok

// #606 A5: Vec owns its buffer and its elements. Dropping a Vec, clearing it,
// removing an element, popping an element, or storing it inside a struct must
// drop each live Drop element exactly once.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type Holder { items: Vec[W] }

fn scope_drop(slot: *mut i32):
    let xs: Vec[W] = Vec.new()
    xs.push(W { slot: slot })
    xs.push(W { slot: slot })

fn clear_drop(slot: *mut i32):
    let xs: Vec[W] = Vec.new()
    xs.push(W { slot: slot })
    xs.push(W { slot: slot })
    xs.clear()

fn remove_drop(slot: *mut i32):
    let xs: Vec[W] = Vec.new()
    xs.push(W { slot: slot })
    xs.push(W { slot: slot })
    let removed = xs.remove(0)

fn pop_moves(slot: *mut i32):
    let xs: Vec[W] = Vec.new()
    xs.push(W { slot: slot })
    let popped = xs.pop()

fn moved_into_struct(slot: *mut i32):
    let xs: Vec[W] = Vec.new()
    xs.push(W { slot: slot })
    let holder = Holder { items: xs }

fn main:
    var count = 0
    scope_drop(&raw mut count)
    clear_drop(&raw mut count)
    remove_drop(&raw mut count)
    pop_moves(&raw mut count)
    moved_into_struct(&raw mut count)
    if count == 8:
        print("ok")
    else:
        print_i32(count)
