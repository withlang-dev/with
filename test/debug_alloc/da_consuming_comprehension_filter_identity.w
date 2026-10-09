//! expect-debug-alloc: leak count=0
//! expect-stdout: iter 2 kept 5
//! expect-stdout: pattern 2 kept 5
//! expect-stdout: gen 2 kept 5
//! expect-stdout: ok

// §13.6 / D33 / #1501: a consuming comprehension with a filter moves each
// kept element into the output and drops each filtered-out element on its
// own iteration. The filter's pass branch moved the binding, and that move
// was left in the lowering's path-insensitive move state, so the join saw
// the binding moved on every path and skipped the drop of each
// filtered-out element: `[r for r in v.into_iter() if r.id != 2]` leaked
// R 2. Each W adds its id to `dropped`; the element with id 2 is the one
// filtered out, 1 + 4 the kept ones.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8)

type W { ptr: *mut u8, dropped: *mut i32, id: i32 }

impl Drop for W:
    move fn drop():
        unsafe:
            with_free(self.ptr)
            *self.dropped = *self.dropped + self.id

fn new_w(dropped: *mut i32, id: i32) -> W:
    unsafe { W { ptr: with_alloc(16), dropped, id } }

fn three(dropped: *mut i32) -> List[W]:
    var v: List[W] = List.new()
    v.push(new_w(dropped, 1))
    v.push(new_w(dropped, 2))
    v.push(new_w(dropped, 4))
    v

gen fn produce(dropped: *mut i32) -> W:
    yield new_w(dropped, 1)
    yield new_w(dropped, 2)
    yield new_w(dropped, 4)

fn main:
    var a = 0
    let kept_a = [w for w in three(&raw mut a).into_iter() if w.id != 2]
    let before_a = a
    drop(kept_a)
    print(f"iter {before_a} kept {a - before_a}")

    var b = 0
    var pairs: List[(i32, W)] = List.new()
    for w in three(&raw mut b).into_iter(): pairs.push((w.id, w))
    let kept_b = [w for (k, w) in pairs.into_iter() if k != 2]
    let before_b = b
    drop(kept_b)
    print(f"pattern {before_b} kept {b - before_b}")

    var d = 0
    let kept_d = [w for w in produce(&raw mut d) if w.id != 2]
    let before_d = d
    drop(kept_d)
    print(f"gen {before_d} kept {d - before_d}")
    print("ok")
