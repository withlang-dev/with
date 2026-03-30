//! expect-stdout: ok

// Test: VecIter_i32 — manual iterator over Vec[i32] using raw data pointer.

type VecIter_i32 { data_ptr: i64, len: i64, idx: i64 }

extern fn with_ptr_get_i32(ptr: i64, index: i64) -> i32

fn VecIter_i32.next(self: VecIter_i32) -> Option[i32]:
    if self.idx >= self.len:
        return .None
    let val = with_ptr_get_i32(self.data_ptr, self.idx)
    self.idx = self.idx + 1
    .Some(val)

fn vec_iter(v: Vec[i32]) -> VecIter_i32:
    // Extract data pointer (field 0 of Vec struct is the raw pointer)
    // Vec layout: { ptr: *const T, len: i64, cap: i64, elem_size: i64 }
    VecIter_i32{ data_ptr: v.ptr as i64, len: v.len(), idx: 0 }

fn iter_sum(iter: VecIter_i32) -> i32:
    var total = 0
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            total = total + item.unwrap()
        else:
            done = true
    total

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)

    let iter = vec_iter(v)
    let total = iter_sum(iter)
    assert(total == 60)
    print("ok")
