//! expect-check-fail: is a live view

// #1317 / §21.1 rule 1, D44: the loop binding's borrow is keyed on the
// iterated place's field path (`self.items`), so pushing onto that field
// inside the loop is rejected. A disjoint field (`self.count`) stays
// writable: see behav_for_binding_disjoint_mutation.

type KV { key: str, n: i32 }
type Bag { items: Vec[KV], count: i32 }

impl Bag:
    mut fn grow():
        for e in self.items:
            self.items.push(KV { key: "b".clone(), n: 2 })
            print(e.key)

fn main:
    var b = Bag { items: Vec.new(), count: 0 }
    b.items.push(KV { key: "a".clone(), n: 1 })
    b.grow()
