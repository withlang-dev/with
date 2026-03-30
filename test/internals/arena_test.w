//! expect-stdout: ok

use compiler.foundation.Ids
use compiler.foundation.Arena

fn main:
    var a = Arena.init()
    assert(a.len() == 1) // sentinel

    let id0 = a.alloc_i32(42)
    let id1 = a.alloc_str("hello")
    assert(a.contains(id0))
    assert(a.contains(id1))
    assert(a.kind(id0) == ARENA_SLOT_I32())
    assert(a.kind(id1) == ARENA_SLOT_STR())
    assert(a.get_i32(id0) == 42)
    assert(a.get_str(id1) == "hello")

    let bad = arena_id_invalid()
    assert(not a.contains(bad))
    assert(a.kind(bad) == ARENA_SLOT_EMPTY())
    assert(a.get_i32(bad) == 0)
    assert(a.get_str(bad) == "")

    a.reset()
    assert(a.len() == 1)
    assert(not a.contains(id0))
    assert(not a.contains(id1))

    let id2 = a.alloc_i32(7)
    assert(a.contains(id2))
    assert(a.get_i32(id2) == 7)

    print("ok")
