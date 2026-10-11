//! expect-stdout: ok

// Test: ListIter_i32 — manual iterator over List[i32] using raw data pointer.

type ListIter_i32 { data_ptr: i64, len: i64, idx: i64 }

extern fn with_ptr_get_i32(ptr: *const u8, index: i64) -> i32

fn ListIter_i32.next(mut self: ListIter_i32) -> Option[i32]:
    if self.idx >= self.len:
        return .None
    let val = unsafe { with_ptr_get_i32(self.data_ptr as *const u8, self.idx) }
    self.idx = self.idx + 1
    .Some(val)

fn list_iter(v: List[i32]) -> ListIter_i32:
    // Extract data pointer (field 0 of List struct is the raw pointer)
    // List layout: { ptr: *const T, len: i64, cap: i64, elem_size: i64 }
    ListIter_i32{ data_ptr: v.as_ptr() as i64, len: v.len(), idx: 0 }

fn iter_sum(iter: ListIter_i32) -> i32:
    var total: i32 = 0
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            total = total + item.unwrap()
        else:
            done = true
    total

fn main:
    let v: List[i32] = List.new()
    v.push(10)
    v.push(20)
    v.push(30)

    let iter = list_iter(v)
    let total = iter_sum(iter)
    assert(total == 60)
    print("ok")
