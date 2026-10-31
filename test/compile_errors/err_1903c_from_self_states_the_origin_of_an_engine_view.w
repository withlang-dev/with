//! expect-error: cannot mutate `h` while `view` is a live view into it
// §21.1 rule 6: the view reaches the caller through a local raw pointer
// (an engine's entry, as BTreeMap.get's), which no inference roots at
// `self`; the `from self` clause states the origin, and every caller
// reads it.
pub type Cell { v: i32 }
pub type Holder { p: *mut Cell }
impl Holder:
    unsafe fn entry() -> *mut Cell: self.p
    pub fn get() -> Option[&i32] from self:
        let e = unsafe { self.entry() }
        if e as i64 == 0: None else: Some(unsafe { &(*e).v })
    pub mut fn clear(): self.p = null
fn main:
    var c = Cell { v: 86 }
    var h = Holder { p: &raw mut c }
    let view: &i32 = h.get().unwrap()
    h.clear()
    print(*view)
