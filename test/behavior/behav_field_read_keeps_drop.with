//! expect-stdout: ok
// Regression: reading a Copy field of a Drop struct must not suppress its drop.

type Resource { id: i32, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn discard_field(slot: *mut i32):
    let r = Resource { id: 1, slot }
    let _ = r.id

fn bind_field(slot: *mut i32):
    let r = Resource { id: 1, slot }
    let p = r.slot
    let _ = p

fn main:
    var drops = 0
    discard_field(&raw mut drops)
    bind_field(&raw mut drops)
    assert(drops == 2)
    print("ok")
