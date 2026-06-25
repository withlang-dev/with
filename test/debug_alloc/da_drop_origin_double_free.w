//! expect-debug-alloc: first_drop=drop#
// Duplicate a Vec[Drop] header so two compiler-emitted Drop statements free
// the same Vec buffer. The debug allocator should report both drop origins.
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn main:
    var c = 0
    let a: Vec[W] = Vec.new()
    a.push(W { slot: &raw mut c })
    var b: Vec[W] = Vec.new()
    unsafe:
        let _ = with_memcpy(&raw mut b as *mut u8, &raw const a as *const u8, sizeof[Vec[W]]())
    drop(a)
    drop(b)
