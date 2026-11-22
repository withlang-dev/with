//! expect-stdout: ok

// Slice E: a Drop-bearing field moved conditionally out of a non-Drop struct,
// through `if` and through `match`, via the explicit `move` vacate (D32 §2.2).
// The field-place niche blanks the moved field
// on the moving path; the owner's guarded per-field drop skips it, so each value
// drops exactly once.

type Resource { id: i32, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

type Holder { r: Resource }

fn take(r: Resource): ()

fn run_if(cond: bool, slot: *mut i32):
    var h = Holder { r: Resource { id: 1, slot } }
    if cond:
        take(move h.r)

fn run_match(cond: bool, slot: *mut i32):
    var h = Holder { r: Resource { id: 1, slot } }
    match cond:
        true => take(move h.r)
        false => ()

fn main:
    var drops = 0
    run_if(true, &raw mut drops)      // moved path: take drops h.r once
    run_if(false, &raw mut drops)     // not-moved path: scope-exit drops h.r once
    run_match(true, &raw mut drops)
    run_match(false, &raw mut drops)
    assert(drops == 4)
    print("ok")
