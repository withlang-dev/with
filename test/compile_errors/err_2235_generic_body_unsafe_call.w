//! expect-check-fail: unsafe function call requires unsafe context

// #2235: whether a call needs an unsafe context is a property of the
// spelling, not of T. A generic impl body that calls an `unsafe fn` bare
// is refused at its declaration, with no instantiation anywhere.
unsafe fn raw_peek(p: *const i32) -> i32: unsafe { *p }

type Cell[T] { v: T }
impl[T] Cell[T]:
    unsafe fn slot(self: &Self, p: *const i32) -> i32: unsafe { *p }
    fn peek(self: &Self, p: *const i32) -> i32: raw_peek(p)
    fn peek_slot(self: &Self, p: *const i32) -> i32: self.slot(p)
    fn fine(self: &Self, p: *const i32) -> i32: unsafe { raw_peek(p) + self.slot(p) }

fn main: 0
