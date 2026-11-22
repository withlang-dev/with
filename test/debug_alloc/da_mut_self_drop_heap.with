//! expect-debug-alloc: leak count=0
// §9.5/#641a: a Drop type owning heap memory, mutated through mut-self methods
// — the receiver is borrowed (not consumed) per call, the destructor runs
// exactly once at scope end, and every allocation is freed.
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type Buf { ptr: *mut u8, len: i64 }
impl Drop for Buf:
    fn drop(move self: Self):
        if self.ptr as i64 != 0:
            unsafe { with_free(self.ptr) }

fn Buf.grow(mut self: Self, n: i64):
    if self.ptr as i64 != 0:
        unsafe { with_free(self.ptr) }
    self.ptr = unsafe { with_alloc(n) }
    self.len = n

fn main:
    var b = Buf { ptr: unsafe { with_alloc(8) }, len: 8 }
    b.grow(16)
    b.grow(32)
    print("ok")
