//! expect-stdout: ok

// D12: bare-self assignment in a `mut fn` writes the caller's place for
// EVERY owner — including aggregates with heap contents (mode decides,
// not the owner's type). This fixture pins the VALUE semantics through
// branch/loop/early-return control flow; drop-exactly-once for user-Drop
// owners is pinned in test/debug_alloc/da_self_replace_user_drop.w. The
// POD List buffers here follow local-reassignment parity: not freed under
// the provisional A5/#608 ruling until the #691 wide flip.

type Buf { data: List[i32], tag: i32 }

extend Buf:
    mut fn reset(new_tag: i32):
        var d: List[i32] = List.new()
        d.push(new_tag)
        self = Buf { data: d, tag: new_tag }
    mut fn reset_if(new_tag: i32, go: bool):
        if not go:
            return
        self.reset(new_tag)
    move fn consume() -> i32: self.tag

fn make(tag: i32) -> Buf:
    var d: List[i32] = List.new()
    d.push(tag)
    Buf { data: d, tag: tag }

fn main:
    // Straight line: old heap contents dropped, new owned by caller.
    var b = make(1)
    b.reset(2)
    assert(b.tag == 2)
    assert(b.data[0] == 2)

    // Branch: replaced only on the taken path.
    b.reset_if(3, false)
    assert(b.tag == 2)
    b.reset_if(3, true)
    assert(b.tag == 3)

    // Loop: repeated replacement drops each predecessor exactly once.
    var c = make(10)
    for i in 0..4:
        c.reset(20 + i)
    assert(c.tag == 23)

    // move fn still consumes.
    let t = c.consume()
    assert(t == 23)

    print("ok")
