//! expect-stdout: ok

type Resource { id: i32, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn take(r: Resource): ()

fn run_implicit(cond: bool, slot: *mut i32):
    let r = Resource { id: 1, slot }
    match cond:
        true => take(r)
        false => ()

fn run_explicit(cond: bool, slot: *mut i32):
    let r = Resource { id: 1, slot }
    match cond:
        true => take(move r)
        false => ()

fn main:
    var drops = 0
    run_implicit(true, &raw mut drops)
    run_implicit(false, &raw mut drops)
    run_explicit(true, &raw mut drops)
    run_explicit(false, &raw mut drops)
    assert(drops == 4)
    print("ok")
