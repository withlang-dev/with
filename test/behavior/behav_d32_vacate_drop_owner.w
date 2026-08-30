//! expect-stdout: ok

// D32 (§2.2): the vacate rule is uniform over every type — the Drop/non-Drop
// owner condition is retired (§2.4's example vacates a Drop owner's field).
// The owner's custom drop still runs exactly once and observes the vacated
// field as its valid empty value.

type Holder { v: Vec[i32], n: i32 }

var drop_count = 0

impl Drop for Holder:
    fn drop(move self: Self):
        drop_count = drop_count + 1
        assert(self.v.len() == 0)

fn consume(v: Vec[i32]): assert(v.get(0) == 7)

fn scope_it:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    var h = Holder { v: xs, n: 1 }
    consume(move h.v)

fn main:
    scope_it()
    assert(drop_count == 1)
    print("ok")
