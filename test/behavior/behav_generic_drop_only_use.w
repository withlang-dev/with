//! expect-stdout: ok

// A generic type whose only use is being dropped: the Drop body is the
// first and only thing that mentions `*mut Slot[T]`, so the type exists
// only after the drop specialization is registered. The eager caches
// must be refreshed after that registration, or the frozen reads phase-bug
// on it (the c-algorithms facades' empty drop-audit cells).


pub type Slot[T] { value: T }
pub type Holder[T] { p: i64 }

pub fn Holder.new[T]() -> Holder[T]: Holder { p: 0 }

impl[T] Drop for Holder[T]:
    move fn drop():
        let s = self.p as *mut Slot[T]
        if s as i64 != 0:
            let v: T = unsafe { (*s).value }
            drop(v)

type R { id: i32 }
impl Drop for R:
    fn drop(move self: Self): ()

fn main:
    var h = Holder[R].new()
    print("ok")
