//! expect-stdout: ok

// §2.5.1: moving a Drop-bearing field must blank its physical source even when
// the partially moved aggregate is immediately moved whole. Static partial-drop
// state does not cross that second ownership boundary.
type Snapshot {
    items: List[i32],
    tag: i32,
}

type Root {
    active: List[i32],
    snapshot: Snapshot,
}

impl Root:
    mut fn sync(new_snapshot: Snapshot):
        // D32: field vacates need a mutable path — rebind the owned param.
        var owned = new_snapshot
        self.active = move owned.items
        self.snapshot = owned

fn main:
    var items: List[i32] = List.new()
    items.push(42)
    var root = Root {
        active: List.new(),
        snapshot: Snapshot { items: List.new(), tag: 0 },
    }
    let snapshot = Snapshot { items, tag: 7 }
    root.sync(move snapshot)
    assert(root.active[0] == 42)
    assert(root.snapshot.items.len() == 0)
    assert(root.snapshot.tag == 7)
    print("ok")
