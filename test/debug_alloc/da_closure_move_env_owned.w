//! expect-debug-alloc: leak count=0
//! expect-stdout: 20
//! expect-stdout: 5
//! expect-stdout: 5
//! expect-stdout: dropped 7
//! expect-stdout: after
//! expect-stdout: 3
//! expect-stdout: 4999950000

// D63 (§12.4 "The callable type"): a `move ||` closure owns its environment
// — never the caller's frame. A Copy-only environment rides inline in the
// context word (no allocation); a non-Copy environment is a heap cell the
// closure value owns, freed when the value drops, its Drop captures
// destroyed exactly once then. A returned closure is called after the
// frame that made it is gone; one stored in a struct is dropped once with
// the struct.

type R { id: i32 }
impl Drop for R:
    move fn drop(): print(f"dropped {self.id}")

type Holder { f: fn() -> i32, tag: i32 }

fn mk_copy(x: i32) -> fn() -> i32: move () => x * 10

fn mk_str(s: str) -> fn() -> i32: move () => s.len() as i32

fn mk_drop(r: R) -> fn() -> i32: move () => r.id

fn main:
    let ten = mk_copy(2)
    print(ten())
    let len = mk_str("hello".clone())
    print(len())
    let h = Holder { f: mk_str("world".clone()), tag: 1 }
    print(h.f())
    let seven = mk_drop(R { id: 7 })
    let _ = seven()
    drop(seven)
    print("after")
    var count = 0
    let bump = mk_copy(0)
    for _ in 0..3:
        count = count + 1 + bump()
    print(count)
    // Inline environments allocate nothing: a hundred thousand Copy-only
    // move closures created and dropped leave the allocator at leak 0 and
    // never touch the heap (an owned cell that leaked would show here).
    var acc: i64 = 0
    for i in 0..100000:
        let g = mk_copy(i)
        acc = acc + g() / 10
    print(acc)
