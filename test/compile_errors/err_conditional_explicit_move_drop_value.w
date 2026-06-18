//! expect-check-fail: conditional move of Drop value requires drop-state tracking

// An explicit `move` arg must follow the same conditional-move rule as an
// implicit consume: without drop-state tracking, MirLower's drop cancel is
// path-insensitive and the not-taken path would leak the value.

type Resource { id: i32 }
impl Drop for Resource:
    fn drop(move self: Self): ()

fn take(r: Resource) -> i32:
    r.id

fn main:
    let a = Resource { id: 9 }
    var c = false
    if c:
        let n = take(move a)
        print(f"n={n}")
    print("end")
