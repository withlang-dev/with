//! expect-debug-alloc: leak count=0

// The moved field has one owner after the remaining aggregate crosses another
// ownership boundary: no stale alias, double-free, or leak.
type Snapshot {
    items: Vec[i32],
    tag: i32,
}

type Root {
    active: Vec[i32],
    snapshot: Snapshot,
}

impl Root:
    mut fn sync(snapshot: Snapshot):
        // D32: field vacates need a mutable path — rebind the owned param.
        var owned = snapshot
        self.active = move owned.items
        self.snapshot = owned

fn main:
    var items: Vec[i32] = Vec.new()
    items.push(42)
    var root = Root {
        active: Vec.new(),
        snapshot: Snapshot { items: Vec.new(), tag: 0 },
    }
    let snapshot = Snapshot { items, tag: 7 }
    root.sync(move snapshot)
    assert(root.active.get(0) == 42)
    assert(root.snapshot.items.len() == 0)
